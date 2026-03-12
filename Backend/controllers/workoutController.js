const { pool } = require('../config/db');

function calculateTotalVolume(exercises) {
  return exercises.reduce((totalVolume, exercise) => {
    const exerciseVolume = (exercise.sets || []).reduce((setVolume, workoutSet) => {
      if (workoutSet.isCompleted == null || workoutSet.isCompleted) {
        return setVolume + (Number(workoutSet.weight) || 0) * (Number(workoutSet.reps) || 0);
      }

      return setVolume;
    }, 0);

    return totalVolume + exerciseVolume;
  }, 0);
}

function calculateDurationSeconds(startTime, endTime) {
  const start = new Date(startTime);
  const end = new Date(endTime);

  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
    return 0;
  }

  return Math.max(0, Math.round((end.getTime() - start.getTime()) / 1000));
}

function mapWorkout(workout) {
  return {
    ...workout,
    duration_seconds: workout.end_time
      ? calculateDurationSeconds(workout.start_time, workout.end_time)
      : 0
  };
}

exports.getUserWorkouts = async (req, res) => {
  try {
    const userId = req.params.userId || req.userId;
    const connection = await pool.getConnection();

    try {
      const [workouts] = await connection.query(
        `SELECT w.id, w.user_id, w.name, w.workout_type, w.start_time, w.end_time, w.total_volume,
                COUNT(ws.id) AS total_sets
         FROM workouts w
         LEFT JOIN workout_sets ws ON ws.workout_id = w.id
         WHERE w.user_id = ?
         GROUP BY w.id
         ORDER BY w.start_time DESC`,
        [userId]
      );

      res.json(workouts.map(mapWorkout));
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getWorkoutById = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    try {
      const [workouts] = await connection.query(
        `SELECT id, user_id, name, workout_type, start_time, end_time, total_volume
         FROM workouts
         WHERE id = ? AND user_id = ?`,
        [id, req.userId]
      );

      if (workouts.length === 0) {
        return res.status(404).json({ error: 'Workout nicht gefunden' });
      }

      const [sets] = await connection.query(
        `SELECT ws.id, ws.exercise_id, ws.set_number, ws.weight, ws.reps, ws.duration_seconds, e.name AS exercise_name
         FROM workout_sets ws
         JOIN exercises e ON e.id = ws.exercise_id
         WHERE ws.workout_id = ?
         ORDER BY e.name ASC, ws.set_number ASC`,
        [id]
      );

      res.json({
        ...mapWorkout(workouts[0]),
        sets
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.createWorkout = async (req, res) => {
  try {
    const {
      name,
      workoutType,
      workout_type,
      startTime,
      start_time,
      endTime,
      end_time,
      exercises = []
    } = req.body;

    const normalizedStartTime = startTime || start_time || new Date().toISOString();
    const normalizedEndTime = endTime || end_time || new Date().toISOString();

    if (!Array.isArray(exercises) || exercises.length === 0) {
      return res.status(400).json({ error: 'Mindestens eine Uebung ist erforderlich' });
    }

    const connection = await pool.getConnection();

    try {
      await connection.beginTransaction();

      const totalVolume = calculateTotalVolume(exercises);
      const [result] = await connection.query(
        `INSERT INTO workouts (user_id, name, workout_type, start_time, end_time, total_volume)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [
          req.userId,
          name || 'Workout Session',
          workoutType || workout_type || 'Strength',
          normalizedStartTime,
          normalizedEndTime,
          totalVolume
        ]
      );

      const workoutId = result.insertId;

      for (const exercise of exercises) {
        let setNumber = 1;

        for (const workoutSet of exercise.sets || []) {
          await connection.query(
            `INSERT INTO workout_sets (workout_id, exercise_id, set_number, weight, reps, duration_seconds)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [
              workoutId,
              exercise.exerciseId,
              setNumber,
              Number(workoutSet.weight) || 0,
              Number(workoutSet.reps) || 0,
              Number(workoutSet.durationSeconds) || 0
            ]
          );

          setNumber += 1;
        }
      }

      await connection.commit();

      res.status(201).json({
        message: 'Workout gespeichert',
        workoutId,
        totalVolume
      });
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateWorkout = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      workoutType,
      workout_type,
      startTime,
      start_time,
      endTime,
      end_time,
      totalVolume,
      total_volume,
      exercises
    } = req.body;

    const connection = await pool.getConnection();

    try {
      await connection.beginTransaction();

      const [existingWorkouts] = await connection.query(
        `SELECT id, start_time, end_time
         FROM workouts
         WHERE id = ? AND user_id = ?`,
        [id, req.userId]
      );

      if (existingWorkouts.length === 0) {
        await connection.rollback();
        return res.status(404).json({ error: 'Workout nicht gefunden' });
      }

      const normalizedExercises = Array.isArray(exercises) ? exercises : null;
      const nextTotalVolume = normalizedExercises
        ? calculateTotalVolume(normalizedExercises)
        : Number(totalVolume ?? total_volume) || 0;

      await connection.query(
        `UPDATE workouts
         SET name = ?, workout_type = ?, start_time = ?, end_time = ?, total_volume = ?
         WHERE id = ? AND user_id = ?`,
        [
          name,
          workoutType || workout_type,
          startTime || start_time || existingWorkouts[0].start_time,
          endTime || end_time || existingWorkouts[0].end_time,
          nextTotalVolume,
          id,
          req.userId
        ]
      );

      if (normalizedExercises) {
        await connection.query('DELETE FROM workout_sets WHERE workout_id = ?', [id]);

        for (const exercise of normalizedExercises) {
          let setNumber = 1;

          for (const workoutSet of exercise.sets || []) {
            await connection.query(
              `INSERT INTO workout_sets (workout_id, exercise_id, set_number, weight, reps, duration_seconds)
               VALUES (?, ?, ?, ?, ?, ?)`,
              [
                id,
                exercise.exerciseId,
                setNumber,
                Number(workoutSet.weight) || 0,
                Number(workoutSet.reps) || 0,
                Number(workoutSet.durationSeconds) || 0
              ]
            );

            setNumber += 1;
          }
        }
      }

      await connection.commit();

      res.json({ message: 'Workout aktualisiert' });
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteWorkout = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    try {
      await connection.query(
        'DELETE FROM workouts WHERE id = ? AND user_id = ?',
        [id, req.userId]
      );
      res.json({ message: 'Workout geloescht' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getWorkoutSets = async (req, res) => {
  try {
    const { workoutId } = req.params;
    const connection = await pool.getConnection();

    try {
      const [sets] = await connection.query(
        `SELECT ws.id, ws.workout_id, ws.exercise_id, ws.set_number, ws.weight, ws.reps, ws.duration_seconds, e.name AS exercise_name
         FROM workout_sets ws
         JOIN exercises e ON ws.exercise_id = e.id
         JOIN workouts w ON w.id = ws.workout_id
         WHERE ws.workout_id = ? AND w.user_id = ?
         ORDER BY ws.set_number ASC`,
        [workoutId, req.userId]
      );

      res.json(sets);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getSetById = async (req, res) => {
  try {
    const { workoutId, setId } = req.params;
    const connection = await pool.getConnection();

    try {
      const [sets] = await connection.query(
        `SELECT ws.id, ws.workout_id, ws.exercise_id, ws.set_number, ws.weight, ws.reps, ws.duration_seconds, e.name AS exercise_name
         FROM workout_sets ws
         JOIN exercises e ON ws.exercise_id = e.id
         JOIN workouts w ON w.id = ws.workout_id
         WHERE ws.id = ? AND ws.workout_id = ? AND w.user_id = ?`,
        [setId, workoutId, req.userId]
      );

      if (sets.length === 0) {
        return res.status(404).json({ error: 'Set nicht gefunden' });
      }

      res.json(sets[0]);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.createSet = async (req, res) => {
  try {
    const { workoutId } = req.params;
    const { exercise_id, set_number, weight, reps, duration_seconds } = req.body;

    if (!exercise_id || !set_number) {
      return res.status(400).json({ error: 'exercise_id und set_number sind erforderlich' });
    }

    const connection = await pool.getConnection();

    try {
      const [result] = await connection.query(
        `INSERT INTO workout_sets (workout_id, exercise_id, set_number, weight, reps, duration_seconds)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [workoutId, exercise_id, set_number, weight || 0, reps || 0, duration_seconds || 0]
      );

      res.status(201).json({
        message: 'Set erstellt',
        setId: result.insertId
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateSet = async (req, res) => {
  try {
    const { workoutId, setId } = req.params;
    const { weight, reps, duration_seconds } = req.body;
    const connection = await pool.getConnection();

    try {
      await connection.query(
        `UPDATE workout_sets ws
         JOIN workouts w ON w.id = ws.workout_id
         SET ws.weight = ?, ws.reps = ?, ws.duration_seconds = ?
         WHERE ws.id = ? AND ws.workout_id = ? AND w.user_id = ?`,
        [weight, reps, duration_seconds, setId, workoutId, req.userId]
      );

      res.json({ message: 'Set aktualisiert' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteSet = async (req, res) => {
  try {
    const { workoutId, setId } = req.params;
    const connection = await pool.getConnection();

    try {
      await connection.query(
        `DELETE ws FROM workout_sets ws
         JOIN workouts w ON w.id = ws.workout_id
         WHERE ws.id = ? AND ws.workout_id = ? AND w.user_id = ?`,
        [setId, workoutId, req.userId]
      );

      res.json({ message: 'Set geloescht' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getMuscleGroupStats = async (req, res) => {
  try {
    const { days } = req.query;
    const params = [req.userId];
    let dateFilter = '';

    const daysInt = parseInt(days, 10);
    if (!isNaN(daysInt) && daysInt > 0) {
      dateFilter = 'AND w.start_time >= DATE_SUB(NOW(), INTERVAL ? DAY)';
      params.push(daysInt);
    }

    const connection = await pool.getConnection();
    try {
      const [rows] = await connection.query(
        `SELECT e.muscle_group,
                COUNT(DISTINCT ws.workout_id) AS workout_count,
                COUNT(*) AS set_count
         FROM workout_sets ws
         JOIN exercises e ON ws.exercise_id = e.id
         JOIN workouts w ON ws.workout_id = w.id
         WHERE w.user_id = ? ${dateFilter}
         GROUP BY e.muscle_group
         ORDER BY workout_count DESC`,
        params
      );
      res.json(rows);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getWorkoutStats = async (req, res) => {
  try {
    const userId = req.params.userId || req.userId;
    const connection = await pool.getConnection();

    try {
      const [totalWorkouts] = await connection.query(
        'SELECT COUNT(*) AS count FROM workouts WHERE user_id = ?',
        [userId]
      );

      const [totalVolume] = await connection.query(
        'SELECT COALESCE(SUM(total_volume), 0) AS volume FROM workouts WHERE user_id = ?',
        [userId]
      );

      const [lastWorkout] = await connection.query(
        'SELECT start_time FROM workouts WHERE user_id = ? ORDER BY start_time DESC LIMIT 1',
        [userId]
      );

      res.json({
        totalWorkouts: totalWorkouts[0].count,
        totalVolume: totalVolume[0].volume || 0,
        lastWorkout: lastWorkout.length > 0 ? lastWorkout[0].start_time : null
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};