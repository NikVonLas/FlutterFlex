const { pool } = require('../config/db');

exports.getSummary = async (req, res) => {
  try {
    const connection = await pool.getConnection();

    try {
      const [users] = await connection.query(
        'SELECT id, username FROM users WHERE id = ?',
        [req.userId]
      );

      if (users.length === 0) {
        return res.status(404).json({ error: 'Benutzer nicht gefunden' });
      }

      const [weeklyStats] = await connection.query(
        `SELECT COALESCE(SUM(TIMESTAMPDIFF(MINUTE, start_time, COALESCE(end_time, start_time))), 0) AS weekly_minutes,
                COUNT(*) AS weekly_workouts
         FROM workouts
         WHERE user_id = ?
           AND start_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)`,
        [req.userId]
      );

      const [activityRows] = await connection.query(
        `SELECT DATE(start_time) AS day,
                COALESCE(SUM(TIMESTAMPDIFF(MINUTE, start_time, COALESCE(end_time, start_time))), 0) AS total_minutes
         FROM workouts
         WHERE user_id = ?
           AND start_time >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
         GROUP BY DATE(start_time)
         ORDER BY day ASC`,
        [req.userId]
      );

      const [recentWorkouts] = await connection.query(
        `SELECT w.id, w.name, w.workout_type, w.start_time, w.end_time, w.total_volume,
                COUNT(ws.id) AS total_sets
         FROM workouts w
         LEFT JOIN workout_sets ws ON ws.workout_id = w.id
         WHERE w.user_id = ?
         GROUP BY w.id
         ORDER BY w.start_time DESC
         LIMIT 5`,
        [req.userId]
      );

      const activityMap = new Map(
        activityRows.map((row) => [new Date(row.day).toISOString().slice(0, 10), Number(row.total_minutes)])
      );

      const activitySeries = [];
      for (let offset = 6; offset >= 0; offset -= 1) {
        const date = new Date();
        date.setHours(0, 0, 0, 0);
        date.setDate(date.getDate() - offset);
        const key = date.toISOString().slice(0, 10);

        activitySeries.push({
          label: date.toLocaleDateString('de-DE', { weekday: 'short' }),
          totalMinutes: activityMap.get(key) || 0
        });
      }

      res.json({
        greetingName: users[0].username || 'Athlete',
        weeklyMinutes: Number(weeklyStats[0].weekly_minutes) || 0,
        weeklyWorkouts: weeklyStats[0].weekly_workouts || 0,
        activitySeries,
        recentWorkouts: recentWorkouts.map((workout) => ({
          ...workout,
          duration_seconds: workout.end_time
            ? Math.max(
                0,
                Math.round((new Date(workout.end_time).getTime() - new Date(workout.start_time).getTime()) / 1000)
              )
            : 0
        }))
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};