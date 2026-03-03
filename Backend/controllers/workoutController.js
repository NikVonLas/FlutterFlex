const { pool } = require('../config/db');

// ==================== WORKOUT ENDPOINTS ====================

// Alle Workouts eines Benutzers abrufen
exports.getUserWorkouts = async (req, res) => {
  try {
    const { userId } = req.params;
    const connection = await pool.getConnection();

    try {
      const [workouts] = await connection.query(
        'SELECT id, user_id, name, workout_type, start_time, end_time, total_volume FROM workouts WHERE user_id = ? ORDER BY start_time DESC',
        [userId]
      );
      res.json(workouts);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Einzelnes Workout abrufen
exports.getWorkoutById = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    try {
      const [workouts] = await connection.query(
        'SELECT id, user_id, name, workout_type, start_time, end_time, total_volume FROM workouts WHERE id = ?',
        [id]
      );

      if (workouts.length === 0) {
        return res.status(404).json({ error: 'Workout nicht gefunden' });
      }

      res.json(workouts[0]);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Neues Workout starten
exports.createWorkout = async (req, res) => {
  try {
    const { user_id, name, workout_type, start_time } = req.body;

    if (!user_id || !start_time) {
      return res.status(400).json({ error: 'user_id und start_time sind erforderlich' });
    }

    const connection = await pool.getConnection();
    try {
      const [result] = await connection.query(
        'INSERT INTO workouts (user_id, name, workout_type, start_time, total_volume) VALUES (?, ?, ?, ?, 0)',
        [user_id, name || null, workout_type || null, start_time]
      );

      res.status(201).json({
        message: 'Workout erstellt',
        workoutId: result.insertId
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Workout aktualisieren
exports.updateWorkout = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, workout_type, end_time, total_volume } = req.body;

    const connection = await pool.getConnection();
    try {
      await connection.query(
        'UPDATE workouts SET name = ?, workout_type = ?, end_time = ?, total_volume = ? WHERE id = ?',
        [name, workout_type, end_time, total_volume || 0, id]
      );

      res.json({ message: 'Workout aktualisiert' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Workout löschen
exports.deleteWorkout = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    try {
      await connection.query('DELETE FROM workouts WHERE id = ?', [id]);
      res.json({ message: 'Workout gelöscht' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ==================== WORKOUT SETS ENDPOINTS ====================

// Alle Sets eines Workouts abrufen
exports.getWorkoutSets = async (req, res) => {
  try {
    const { workoutId } = req.params;
    const connection = await pool.getConnection();

    try {
      const [sets] = await connection.query(
        `SELECT ws.id, ws.workout_id, ws.exercise_id, ws.set_number, ws.weight, ws.reps, ws.duration_seconds, e.name as exercise_name
         FROM workout_sets ws
         JOIN exercises e ON ws.exercise_id = e.id
         WHERE ws.workout_id = ?
         ORDER BY ws.set_number`,
        [workoutId]
      );
      res.json(sets);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Einzelnes Set abrufen
exports.getSetById = async (req, res) => {
  try {
    const { workoutId, setId } = req.params;
    const connection = await pool.getConnection();

    try {
      const [sets] = await connection.query(
        `SELECT ws.id, ws.workout_id, ws.exercise_id, ws.set_number, ws.weight, ws.reps, ws.duration_seconds, e.name as exercise_name
         FROM workout_sets ws
         JOIN exercises e ON ws.exercise_id = e.id
         WHERE ws.id = ? AND ws.workout_id = ?`,
        [setId, workoutId]
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

// Neues Set zu Workout hinzufügen
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

// Set aktualisieren
exports.updateSet = async (req, res) => {
  try {
    const { workoutId, setId } = req.params;
    const { weight, reps, duration_seconds } = req.body;

    const connection = await pool.getConnection();
    try {
      await connection.query(
        'UPDATE workout_sets SET weight = ?, reps = ?, duration_seconds = ? WHERE id = ? AND workout_id = ?',
        [weight, reps, duration_seconds, setId, workoutId]
      );

      res.json({ message: 'Set aktualisiert' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Set löschen
exports.deleteSet = async (req, res) => {
  try {
    const { workoutId, setId } = req.params;
    const connection = await pool.getConnection();

    try {
      await connection.query(
        'DELETE FROM workout_sets WHERE id = ? AND workout_id = ?',
        [setId, workoutId]
      );
      res.json({ message: 'Set gelöscht' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Workout-Statistiken abrufen
exports.getWorkoutStats = async (req, res) => {
  try {
    const { userId } = req.params;
    const connection = await pool.getConnection();

    try {
      // Gesamt Workouts
      const [totalWorkouts] = await connection.query(
        'SELECT COUNT(*) as count FROM workouts WHERE user_id = ?',
        [userId]
      );

      // Gesamt Volumen
      const [totalVolume] = await connection.query(
        'SELECT SUM(total_volume) as volume FROM workouts WHERE user_id = ?',
        [userId]
      );

      // Letztes Workout
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
