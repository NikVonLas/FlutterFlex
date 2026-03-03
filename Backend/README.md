# 🏋️ FlutterFlex Backend API

Vollständige REST API für eine moderne Fitness-Tracking-Anwendung, gebaut mit Express.js und MySQL.

![Node.js](https://img.shields.io/badge/Node.js-v14+-green)
![Express](https://img.shields.io/badge/Express-4.18-blue)
![MySQL](https://img.shields.io/badge/MySQL-5.7+-orange)

---

## ✨ Features

- ✅ **User Authentication** mit JWT Tokens
- ✅ **Profile Management** mit Bild-Upload (BLOB Storage)
- ✅ **Exercise Library** mit Muskelgruppen-Filterung
- ✅ **Workout Tracking** mit Echtzeit-Updates
- ✅ **Set Management** pro Workout
- ✅ **User Statistics** & Analytics
- ✅ **BLOB Image Storage** für Profile und Übungen
- ✅ **Password Hashing** mit BCrypt

---

## 📋 Prerequisites

```
- Node.js >= 14.0
- MySQL Server >= 5.7
- npm oder yarn
```

---

## 🚀 Quick Start

### 1. Installation
```bash
cd Backend
npm install
```

### 2. Umgebungsvariablen konfigurieren
```bash
# Erstelle .env Datei
touch .env
```

Inhalt der `.env`:
```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=yourpassword
DB_NAME=flutterflex_db
PORT=3000
JWT_SECRET=your_super_secret_jwt_key
```

### 3. Server starten
```bash
# Development (mit Auto-reload)
npm run dev

# Production
npm start
```

### 4. Health Check
```bash
curl http://localhost:3000/api/health
# Response: { "status": "Server is running" }
```

---

## 📚 API Documentation

### BASE URL
```
http://localhost:3000/api
```

### Authentication Endpoints
- `POST /auth/register` - Benutzer registrieren
- `POST /auth/login` - Anmelden
- `GET /auth/profile/:userId` - Profil abrufen
- `PUT /auth/profile/:userId` - Profil aktualisieren
- `POST /auth/profile/:userId/image` - Profilbild hochladen
- `GET /auth/profile/:userId/image` - Profilbild abrufen
- `PUT /auth/preferences/:userId` - Einstellungen ändern

### Exercise Endpoints
- `GET /exercises` - Alle Übungen
- `GET /exercises/:id` - Einzelne Übung
- `GET /exercises/muscle-group/:muscleGroup` - Nach Muskelgruppe filtern
- `POST /exercises` - Neue Übung erstellen
- `PUT /exercises/:id` - Übung aktualisieren
- `DELETE /exercises/:id` - Übung löschen
- `POST /exercises/:id/image` - Übungsbild hochladen
- `GET /exercises/:id/image` - Übungsbild abrufen

### Workout Endpoints
- `GET /workouts/user/:userId` - Alle Workouts eines Benutzers
- `GET /workouts/:id` - Einzelnes Workout
- `POST /workouts` - Workout starten
- `PUT /workouts/:id` - Workout aktualisieren
- `DELETE /workouts/:id` - Workout löschen
- `GET /workouts/stats/:userId` - Statistiken

### Workout Sets Endpoints
- `GET /workouts/:workoutId/sets` - Alle Sets
- `GET /workouts/:workoutId/sets/:setId` - Einzelnes Set
- `POST /workouts/:workoutId/sets` - Set hinzufügen
- `PUT /workouts/:workoutId/sets/:setId` - Set aktualisieren
- `DELETE /workouts/:workoutId/sets/:setId` - Set löschen

---

## 📄 Beispiel Requests

### User registrieren
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "secure123"
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "secure123"
  }'
```

### Workout erstellen
```bash
curl -X POST http://localhost:3000/api/workouts \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "name": "Chest Day",
    "workout_type": "Strength",
    "start_time": "2024-03-03T10:00:00Z"
  }'
```

### Set zu Workout hinzufügen
```bash
curl -X POST http://localhost:3000/api/workouts/1/sets \
  -H "Content-Type: application/json" \
  -d '{
    "exercise_id": 1,
    "set_number": 1,
    "weight": 100,
    "reps": 8,
    "duration_seconds": 45
  }'
```

---

## 📊 Database Schema

### Users Table
```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255),
    profile_image MEDIUMBLOB,
    preferred_unit ENUM('kg', 'lbs'),
    preferred_theme INT,
    created_at TIMESTAMP
);
```

### Exercises Table
```sql
CREATE TABLE exercises (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    muscle_group VARCHAR(50),
    description TEXT,
    image MEDIUMBLOB
);
```

### Workouts Table
```sql
CREATE TABLE workouts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    name VARCHAR(100),
    workout_type VARCHAR(50),
    start_time DATETIME,
    end_time DATETIME,
    total_volume INT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### Workout Sets Table
```sql
CREATE TABLE workout_sets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    workout_id INT,
    exercise_id INT,
    set_number INT,
    weight DECIMAL(6,2),
    reps INT,
    duration_seconds INT,
    FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
);
```

---

## 🔐 Security Features

- **JWT Authentication** - Sichere Token-basierte Auth
- **Password Hashing** - bcrypt mit 10 Salt Rounds
- **CORS Protection** - Cross-Origin Request Handling
- **SQL Injection Prevention** - Prepared Statements
- **Environment Variables** - Sensitive Data Management

---

## 📁 Project Structure

```
Backend/
├── server.js                    # Express App Setup
├── package.json                 # Dependencies
├── .env                         # Environment Configuration
├── .gitignore                   # Git Ignore Rules
│
├── config/
│   └── db.js                   # Database Connection & Schema Init
│
├── controllers/
│   ├── authController.js       # Authentication Logic
│   ├── exerciseController.js   # Exercise Management
│   └── workoutController.js    # Workout & Sets Management
│
├── routes/
│   ├── authRoutes.js          # Auth Endpoints
│   ├── exerciseRoutes.js      # Exercise Endpoints
│   └── workoutRoutes.js       # Workout Endpoints
│
├── middleware/
│   └── auth.js                # JWT Verification Middleware
│
├── API_DOCUMENTATION.md       # Detailed API Reference
├── SETUP_GUIDE.md            # Installation Instructions
└── QUICK_REFERENCE.md        # Quick API Overview
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| express | ^4.18.2 | Web Framework |
| mysql2 | ^3.6.0 | MySQL Driver |
| bcryptjs | ^2.4.3 | Password Hashing |
| jsonwebtoken | ^9.1.0 | JWT Generation/Verification |
| multer | ^1.4.5 | File Upload |
| cors | ^2.8.5 | CORS Middleware |
| dotenv | ^16.3.1 | Environment Variables |

Dev Dependencies:
- nodemon ^3.0.1 - Auto-reload during development

---

## 🛠️ Available Scripts

```bash
# Start server in development mode
npm run dev

# Start server in production mode
npm start

# View npm scripts
npm run
```

---

## 🐛 Troubleshooting

### MySQL Connection Error
```
Lösung: Stelle sicher, dass MySQL läuft und .env Credentials korrekt sind
mysql -u root -p
```

### Port already in use
```bash
# MacOS/Linux
lsof -i :3000 | grep LISTEN | awk '{print $2}' | xargs kill -9

# Windows PowerShell
Get-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess | Stop-Process -Force
```

### Module not found
```bash
npm install
```

---

## 📊 Response Format

### Success Response (200/201)
```json
{
  "message": "Operation successful",
  "data": { ... }
}
```

### Error Response (4xx/5xx)
```json
{
  "error": "Error message",
  "message": "Detailed error description"
}
```

---

## 🚀 Deployment

### Docker Deployment
```bash
docker build -t flutterflex-backend .
docker run -p 3000:3000 --env-file .env flutterflex-backend
```

### Heroku Deployment
```bash
heroku create flutterflex-backend
git push heroku main
```

### Self-Hosted (Ubuntu)
```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone & Setup
git clone <repo>
cd Backend
npm install

# Create .env file
nano .env

# Run with PM2
npm install -g pm2
pm2 start server.js --name flutterflex
```

---

## 📞 Support

Für detaillierte Dokumentation siehe:
- [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
- [SETUP_GUIDE.md](./SETUP_GUIDE.md)
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)

---

## 📄 Lizenz

Copyright © 2024 FlutterFlex. Alle Rechte vorbehalten.

---

## 🎉 Viel Spaß beim Entwickeln!

Happy Coding! 🚀💪

