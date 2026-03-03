const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'flutterflex_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Initialisierung des Datenbankschemas
async function initializeDatabase() {
  const connection = await pool.getConnection();
  try {
    // Datenbank erstellen
    await connection.query('CREATE DATABASE IF NOT EXISTS flutterflex_db');
    await connection.query('USE flutterflex_db');

    // Tabellen erstellen
    await connection.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(100),
        email VARCHAR(255) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        profile_image MEDIUMBLOB,
        preferred_unit ENUM('kg', 'lbs') DEFAULT 'kg',
        preferred_theme INT DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS exercises (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        muscle_group VARCHAR(50) NOT NULL,
        description TEXT,
        image MEDIUMBLOB
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS workouts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        name VARCHAR(100),
        workout_type VARCHAR(50),
        start_time DATETIME NOT NULL,
        end_time DATETIME,
        total_volume INT DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS workout_sets (
        id INT AUTO_INCREMENT PRIMARY KEY,
        workout_id INT NOT NULL,
        exercise_id INT NOT NULL,
        set_number INT NOT NULL,
        weight DECIMAL(6,2) DEFAULT 0,
        reps INT DEFAULT 0,
        duration_seconds INT DEFAULT 0,
        FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    `);

    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Error initializing database:', error);
  } finally {
    connection.release();
  }
}

module.exports = {
  pool,
  initializeDatabase
};
