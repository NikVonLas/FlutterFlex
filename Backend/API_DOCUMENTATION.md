# FlutterFlex Backend API

Eine komplette REST API für eine Fitness-Tracking-Anwendung mit Express.js und MySQL.

## Vorbereitung

### Installation
```bash
npm install
```

### Umgebungsvariablen
Erstelle eine `.env` Datei basierend auf `.env.example`:
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=flutterflex_db
PORT=3000
JWT_SECRET=your_secret_key
```

### Server starten
```bash
npm start        # Production
npm run dev      # Development mit Nodemon
```

Server läuft auf: `http://localhost:3000`

---

## API Endpoints

### BASE URL: `http://localhost:3000/api`

---

## 1. AUTHENTICATION & USER MANAGEMENT

### POST /auth/register
Neue Benutzer registrieren

**Request Body:**
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "message": "Benutzer erfolgreich registriert"
}
```

---

### POST /auth/login
Benutzer anmelden und JWT Token erhalten

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "message": "Login erfolgreich",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "userId": 1,
  "username": "john_doe"
}
```

---

### GET /auth/profile/:userId
Benutzerprofil abrufen

**Response:**
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "preferred_unit": "kg",
  "preferred_theme": 1,
  "created_at": "2024-03-03T10:00:00.000Z"
}
```

---

### PUT /auth/profile/:userId
Benutzerprofil aktualisieren

**Request Body:**
```json
{
  "username": "john_doe_updated"
}
```

**Response:**
```json
{
  "message": "Profil aktualisiert"
}
```

---

### POST /auth/profile/:userId/image
Profilbild hochladen (BLOB in Datenbank)

**Form Data:**
- `image`: File (JPEG/PNG)

**Response:**
```json
{
  "message": "Profilbild aktualisiert"
}
```

---

### GET /auth/profile/:userId/image
Profilbild abrufen (Binary Image Stream)

**Response:** Image Binary Data

---

### PUT /auth/preferences/:userId
Benutzer-Einstellungen aktualisieren

**Request Body:**
```json
{
  "preferred_unit": "lbs",
  "preferred_theme": 2
}
```

**Response:**
```json
{
  "message": "Einstellungen aktualisiert"
}
```

---

## 2. EXERCISES

### GET /exercises
Alle Übungen abrufen

**Query Parameters:**
- Keine

**Response:**
```json
[
  {
    "id": 1,
    "name": "Bench Press",
    "muscle_group": "Chest",
    "description": "Barbell bench press"
  },
  {
    "id": 2,
    "name": "Squats",
    "muscle_group": "Legs",
    "description": "Barbell squats"
  }
]
```

---

### GET /exercises/:id
Einzelne Übung abrufen

**Response:**
```json
{
  "id": 1,
  "name": "Bench Press",
  "muscle_group": "Chest",
  "description": "Barbell bench press"
}
```

---

### GET /exercises/muscle-group/:muscleGroup
Übungen nach Muskelgruppe filtern

**Example:** `/exercises/muscle-group/Chest`

**Response:**
```json
[
  {
    "id": 1,
    "name": "Bench Press",
    "muscle_group": "Chest",
    "description": "Barbell bench press"
  }
]
```

---

### POST /exercises
Neue Übung erstellen (mit optionalem Bild)

**Form Data:**
- `name`: string (required)
- `muscle_group`: string (required)
- `description`: string (optional)
- `image`: File (optional, JPEG/PNG)

**Response:**
```json
{
  "message": "Übung erstellt",
  "exerciseId": 3
}
```

---

### PUT /exercises/:id
Übung aktualisieren

**Request Body:**
```json
{
  "name": "Bench Press - Updated",
  "muscle_group": "Chest",
  "description": "Updated description"
}
```

**Response:**
```json
{
  "message": "Übung aktualisiert"
}
```

---

### POST /exercises/:id/image
Übungsbild hochladen

**Form Data:**
- `image`: File (JPEG/PNG)

**Response:**
```json
{
  "message": "Übungsbild aktualisiert"
}
```

---

### GET /exercises/:id/image
Übungsbild abrufen (Binary Image Stream)

**Response:** Image Binary Data

---

### DELETE /exercises/:id
Übung löschen

**Response:**
```json
{
  "message": "Übung gelöscht"
}
```

---

## 3. WORKOUTS

### GET /workouts/user/:userId
Alle Workouts eines Benutzers abrufen

**Response:**
```json
[
  {
    "id": 1,
    "user_id": 1,
    "name": "Chest Day",
    "workout_type": "Strength",
    "start_time": "2024-03-03T10:00:00.000Z",
    "end_time": "2024-03-03T11:30:00.000Z",
    "total_volume": 2500
  }
]
```

---

### GET /workouts/:id
Einzelnes Workout abrufen

**Response:**
```json
{
  "id": 1,
  "user_id": 1,
  "name": "Chest Day",
  "workout_type": "Strength",
  "start_time": "2024-03-03T10:00:00.000Z",
  "end_time": "2024-03-03T11:30:00.000Z",
  "total_volume": 2500
}
```

---

### POST /workouts
Neues Workout starten

**Request Body:**
```json
{
  "user_id": 1,
  "name": "Chest Day",
  "workout_type": "Strength",
  "start_time": "2024-03-03T10:00:00Z"
}
```

**Response:**
```json
{
  "message": "Workout erstellt",
  "workoutId": 1
}
```

---

### PUT /workouts/:id
Workout aktualisieren (z.B. Enddatum setzen)

**Request Body:**
```json
{
  "name": "Chest Day - Updated",
  "workout_type": "Strength",
  "end_time": "2024-03-03T11:30:00Z",
  "total_volume": 2500
}
```

**Response:**
```json
{
  "message": "Workout aktualisiert"
}
```

---

### DELETE /workouts/:id
Workout löschen (löscht auch alle zugehörigen Sets)

**Response:**
```json
{
  "message": "Workout gelöscht"
}
```

---

### GET /workouts/stats/:userId
Workout-Statistiken für einen Benutzer

**Response:**
```json
{
  "totalWorkouts": 15,
  "totalVolume": 37500,
  "lastWorkout": "2024-03-03T11:30:00.000Z"
}
```

---

## 4. WORKOUT SETS

### GET /workouts/:workoutId/sets
Alle Sets eines Workouts abrufen

**Response:**
```json
[
  {
    "id": 1,
    "workout_id": 1,
    "exercise_id": 1,
    "set_number": 1,
    "weight": 100.00,
    "reps": 8,
    "duration_seconds": 45,
    "exercise_name": "Bench Press"
  },
  {
    "id": 2,
    "workout_id": 1,
    "exercise_id": 1,
    "set_number": 2,
    "weight": 100.00,
    "reps": 8,
    "duration_seconds": 45,
    "exercise_name": "Bench Press"
  }
]
```

---

### GET /workouts/:workoutId/sets/:setId
Einzelnes Set abrufen

**Response:**
```json
{
  "id": 1,
  "workout_id": 1,
  "exercise_id": 1,
  "set_number": 1,
  "weight": 100.00,
  "reps": 8,
  "duration_seconds": 45,
  "exercise_name": "Bench Press"
}
```

---

### POST /workouts/:workoutId/sets
Neues Set zu Workout hinzufügen

**Request Body:**
```json
{
  "exercise_id": 1,
  "set_number": 1,
  "weight": 100.00,
  "reps": 8,
  "duration_seconds": 45
}
```

**Response:**
```json
{
  "message": "Set erstellt",
  "setId": 1
}
```

---

### PUT /workouts/:workoutId/sets/:setId
Set aktualisieren

**Request Body:**
```json
{
  "weight": 105.00,
  "reps": 10,
  "duration_seconds": 50
}
```

**Response:**
```json
{
  "message": "Set aktualisiert"
}
```

---

### DELETE /workouts/:workoutId/sets/:setId
Set löschen

**Response:**
```json
{
  "message": "Set gelöscht"
}
```

---

## Data Types

### preferred_unit
- `kg` - Kilogramm (Standard)
- `lbs` - Pound

### preferred_theme
- `1` - Light Theme (Standard)
- `2` - Dark Theme

### workout_type
Beispiele:
- `Strength` - Kraft-Training
- `Cardio` - Ausdauer
- `Hypertrophy` - Muskelaufbau
- `Endurance` - Ausdauer-Training
- etc.

### muscle_group
Beispiele:
- `Chest`
- `Back`
- `Legs`
- `Shoulders`
- `Biceps`
- `Triceps`
- `Abs`
- etc.

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Username, email und password sind erforderlich"
}
```

### 401 Unauthorized
```json
{
  "error": "Ungültige Anmeldedaten"
}
```

### 404 Not Found
```json
{
  "error": "Benutzer nicht gefunden"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "message": "Error details"
}
```

---

## Beispiel-Requests mit cURL

### Registrierung
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

### Profilbild hochladen
```bash
curl -X POST http://localhost:3000/api/auth/profile/1/image \
  -F "image=@/path/to/image.jpg"
```

---

## Database Schema

Die Datenbank wird automatisch beim Starten des Servers initialisiert.

### Tabellen:
- `users` - Benutzer und Profile
- `exercises` - Übungsbibliothek
- `workouts` - Workout-Sessions
- `workout_sets` - Einzelne Sets innerhalb von Workouts

---

## Notizen

- Bilder (Profile Images, Exercise Images) werden als `MEDIUMBLOB` direkt in der Datenbank gespeichert
- JWT Tokens laufen nach 7 Tagen ab
- Passwörter werden mit bcrypt gehasht
- Foreign Keys gewährleisten Datenbankintegrität

