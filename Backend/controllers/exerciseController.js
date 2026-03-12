const { pool } = require('../config/db');

// Alle Übungen abrufen
exports.getAllExercises = async (req, res) => {
  try {
    const { muscleGroup, search } = req.query;
    const connection = await pool.getConnection();

    try {
      const conditions = [];
      const params = [];

      if (muscleGroup) {
        conditions.push('muscle_group = ?');
        params.push(muscleGroup);
      }

      if (search) {
        conditions.push('(name LIKE ? OR description LIKE ?)');
        params.push(`%${search}%`, `%${search}%`);
      }

      const whereClause = conditions.length === 0 ? '' : `WHERE ${conditions.join(' AND ')}`;
      const [exercises] = await connection.query(
        `SELECT id, name, muscle_group, description
         FROM exercises
         ${whereClause}
         ORDER BY name ASC`,
        params
      );

      res.json(exercises);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getMuscleGroups = async (req, res) => {
  try {
    const connection = await pool.getConnection();

    try {
      const [rows] = await connection.query(
        'SELECT DISTINCT muscle_group FROM exercises ORDER BY muscle_group ASC'
      );

      res.json(rows.map((row) => row.muscle_group));
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Einzelne Übung abrufen
exports.getExerciseById = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    try {
      const [exercises] = await connection.query(
        'SELECT id, name, muscle_group, description FROM exercises WHERE id = ?',
        [id]
      );

      if (exercises.length === 0) {
        return res.status(404).json({ error: 'Übung nicht gefunden' });
      }

      res.json(exercises[0]);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Übungen nach Muskelgruppe filtern
exports.getExercisesByMuscleGroup = async (req, res) => {
  try {
    const { muscleGroup } = req.params;
    const connection = await pool.getConnection();

    try {
      const [exercises] = await connection.query(
        'SELECT id, name, muscle_group, description FROM exercises WHERE muscle_group = ?',
        [muscleGroup]
      );
      res.json(exercises);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Neue Übung erstellen
exports.createExercise = async (req, res) => {
  try {
    const { name, muscle_group, description } = req.body;

    if (!name || !muscle_group) {
      return res.status(400).json({ error: 'Name und Muskelgruppe sind erforderlich' });
    }

    const connection = await pool.getConnection();
    try {
      const image = req.file ? req.file.buffer : null;

      const [result] = await connection.query(
        'INSERT INTO exercises (name, muscle_group, description, image) VALUES (?, ?, ?, ?)',
        [name, muscle_group, description, image]
      );

      res.status(201).json({
        message: 'Übung erstellt',
        exerciseId: result.insertId
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Übung aktualisieren
exports.updateExercise = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, muscle_group, description } = req.body;

    const connection = await pool.getConnection();
    try {
      // Prüfe ob Übung existiert
      const [exercises] = await connection.query(
        'SELECT id FROM exercises WHERE id = ?',
        [id]
      );

      if (exercises.length === 0) {
        return res.status(404).json({ error: 'Übung nicht gefunden' });
      }

      await connection.query(
        'UPDATE exercises SET name = ?, muscle_group = ?, description = ? WHERE id = ?',
        [name, muscle_group, description, id]
      );

      res.json({ message: 'Übung aktualisiert' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Übungsbild hochladen
exports.uploadExerciseImage = async (req, res) => {
  try {
    const { id } = req.params;

    if (!req.file) {
      return res.status(400).json({ error: 'Keine Datei hochgeladen' });
    }

    const connection = await pool.getConnection();
    try {
      await connection.query(
        'UPDATE exercises SET image = ? WHERE id = ?',
        [req.file.buffer, id]
      );
      res.json({ message: 'Übungsbild aktualisiert' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Übungsbild abrufen
exports.getExerciseImage = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    try {
      const [exercises] = await connection.query(
        'SELECT image FROM exercises WHERE id = ?',
        [id]
      );

      if (exercises.length === 0 || !exercises[0].image) {
        return res.status(404).json({ error: 'Bild nicht gefunden' });
      }

      res.type('image/jpeg');
      res.send(exercises[0].image);
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Übung löschen
exports.deleteExercise = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    try {
      await connection.query('DELETE FROM exercises WHERE id = ?', [id]);
      res.json({ message: 'Übung gelöscht' });
    } finally {
      connection.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
