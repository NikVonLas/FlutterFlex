const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key';

// Registrieren
exports.register = async (req, res) => {
  try {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ error: 'Username, email und password sind erforderlich' });
    }

    const connection = await pool.getConnection();
    try {
      // Prüfe ob Email bereits existiert
      const [existing] = await connection.query('SELECT id FROM users WHERE email = ?', [email]);
      if (existing.length > 0) {
        return res.status(400).json({ error: 'Email existiert bereits' });
      }

      // Passwort hashen
      const passwordHash = await bcrypt.hash(password, 10);

      // Benutzer erstellen
      await connection.query(
        'INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)',
        [username, email, passwordHash]
      );

      res.status(201).json({ message: 'Benutzer erfolgreich registriert' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email und Password sind erforderlich' });
    }

    const connection = await pool.getConnection();
    try {
      const [users] = await connection.query('SELECT id, username, password_hash FROM users WHERE email = ?', [email]);

      if (users.length === 0) {
        return res.status(401).json({ error: 'Ungültige Anmeldedaten' });
      }

      const user = users[0];
      const passwordMatch = await bcrypt.compare(password, user.password_hash);

      if (!passwordMatch) {
        return res.status(401).json({ error: 'Ungültige Anmeldedaten' });
      }

      const token = jwt.sign(
        { userId: user.id, email: email, username: user.username },
        JWT_SECRET,
        { expiresIn: '7d' }
      );

      res.json({
        message: 'Login erfolgreich',
        token: token,
        userId: user.id,
        username: user.username
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Profil abrufen
exports.getProfile = async (req, res) => {
  try {
    const { userId } = req.params;
    const connection = await pool.getConnection();

    try {
      const [users] = await connection.query(
        'SELECT id, username, email, preferred_unit, preferred_theme, created_at FROM users WHERE id = ?',
        [userId]
      );

      if (users.length === 0) {
        return res.status(404).json({ error: 'Benutzer nicht gefunden' });
      }

      res.json(users[0]);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Profil aktualisieren
exports.updateProfile = async (req, res) => {
  try {
    const { userId } = req.params;
    const { username } = req.body;

    if (!username) {
      return res.status(400).json({ error: 'Username ist erforderlich' });
    }

    const connection = await pool.getConnection();
    try {
      await connection.query('UPDATE users SET username = ? WHERE id = ?', [username, userId]);
      res.json({ message: 'Profil aktualisiert' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Profilbild hochladen
exports.uploadProfileImage = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!req.file) {
      return res.status(400).json({ error: 'Keine Datei hochgeladen' });
    }

    const connection = await pool.getConnection();
    try {
      await connection.query(
        'UPDATE users SET profile_image = ? WHERE id = ?',
        [req.file.buffer, userId]
      );
      res.json({ message: 'Profilbild aktualisiert' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Profilbild abrufen
exports.getProfileImage = async (req, res) => {
  try {
    const { userId } = req.params;
    const connection = await pool.getConnection();

    try {
      const [users] = await connection.query(
        'SELECT profile_image FROM users WHERE id = ?',
        [userId]
      );

      if (users.length === 0 || !users[0].profile_image) {
        return res.status(404).json({ error: 'Profilbild nicht gefunden' });
      }

      res.type('image/jpeg');
      res.send(users[0].profile_image);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Benutzer-Präferenzen aktualisieren
exports.updatePreferences = async (req, res) => {
  try {
    const { userId } = req.params;
    const { preferred_unit, preferred_theme } = req.body;

    const connection = await pool.getConnection();
    try {
      await connection.query(
        'UPDATE users SET preferred_unit = ?, preferred_theme = ? WHERE id = ?',
        [preferred_unit, preferred_theme, userId]
      );
      res.json({ message: 'Einstellungen aktualisiert' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
