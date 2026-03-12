const { pool } = require('../config/db');

function mapUser(user) {
  return {
    id: user.id,
    username: user.username,
    email: user.email,
    preferredUnit: user.preferred_unit,
    preferredTheme: user.preferred_theme,
    preferredMode: user.preferred_mode,
    createdAt: user.created_at
  };
}

exports.getCurrentUser = async (req, res) => {
  try {
    const connection = await pool.getConnection();

    try {
      const [users] = await connection.query(
        `SELECT id, username, email, preferred_unit, preferred_theme, preferred_mode, created_at
         FROM users
         WHERE id = ?`,
        [req.userId]
      );

      if (users.length === 0) {
        return res.status(404).json({ error: 'Benutzer nicht gefunden' });
      }

      res.json(mapUser(users[0]));
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateSettings = async (req, res) => {
  try {
    const { preferredUnit, preferredTheme, preferredMode } = req.body;

    if (!['kg', 'lbs'].includes(preferredUnit)) {
      return res.status(400).json({ error: 'preferredUnit muss kg oder lbs sein' });
    }

    if (!['light', 'dark'].includes(preferredMode)) {
      return res.status(400).json({ error: 'preferredMode muss light oder dark sein' });
    }

    const themeValue = Number(preferredTheme);
    if (Number.isNaN(themeValue) || themeValue < 0 || themeValue > 4) {
      return res.status(400).json({ error: 'preferredTheme muss zwischen 0 und 4 liegen' });
    }

    const connection = await pool.getConnection();

    try {
      await connection.query(
        `UPDATE users
         SET preferred_unit = ?, preferred_theme = ?, preferred_mode = ?
         WHERE id = ?`,
        [preferredUnit, themeValue, preferredMode, req.userId]
      );

      const [users] = await connection.query(
        `SELECT id, username, email, preferred_unit, preferred_theme, preferred_mode, created_at
         FROM users
         WHERE id = ?`,
        [req.userId]
      );

      res.json({
        message: 'Einstellungen aktualisiert',
        user: mapUser(users[0])
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};