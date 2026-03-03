CREATE DATABASE IF NOT EXISTS flutterflex_db;
USE flutterflex_db;

-- 1. Nutzer-Tabelle (mit Username und Bild als BLOB)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    profile_image MEDIUMBLOB,  -- GEÄNDERT: Bild wird direkt in der DB gespeichert
    preferred_unit ENUM('kg', 'lbs') DEFAULT 'kg',
    preferred_theme INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Übungs-Bibliothek (mit Bild als BLOB)
CREATE TABLE exercises (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    muscle_group VARCHAR(50) NOT NULL,
    description TEXT,
    image MEDIUMBLOB -- GEÄNDERT: Bild wird direkt in der DB gespeichert
);

-- 3. Workout-Kopfdaten 
CREATE TABLE workouts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(100), 
    workout_type VARCHAR(50), 
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    total_volume INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 4. Einzelne Sätze/Sets 
CREATE TABLE workout_sets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    workout_id INT NOT NULL,
    exercise_id INT NOT NULL,
    set_number INT NOT NULL,
    weight DECIMAL(6,2) DEFAULT 0, 
    reps INT DEFAULT 0, 
    duration_seconds INT DEFAULT 0,
    FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
);