const express = require('express');
const workoutController = require('../controllers/workoutController');

const router = express.Router();

// ==================== WORKOUT ROUTES ====================

// Benutzer-Workouts
router.get('/user/:userId', workoutController.getUserWorkouts);

// Workout-Statistiken
router.get('/stats/:userId', workoutController.getWorkoutStats);

// Einzelnes Workout
router.get('/:id', workoutController.getWorkoutById);

// Neues Workout erstellen
router.post('/', workoutController.createWorkout);

// Workout aktualisieren
router.put('/:id', workoutController.updateWorkout);

// Workout löschen
router.delete('/:id', workoutController.deleteWorkout);

// ==================== WORKOUT SETS ROUTES ====================

// Alle Sets eines Workouts
router.get('/:workoutId/sets', workoutController.getWorkoutSets);

// Einzelnes Set
router.get('/:workoutId/sets/:setId', workoutController.getSetById);

// Neues Set hinzufügen
router.post('/:workoutId/sets', workoutController.createSet);

// Set aktualisieren
router.put('/:workoutId/sets/:setId', workoutController.updateSet);

// Set löschen
router.delete('/:workoutId/sets/:setId', workoutController.deleteSet);

module.exports = router;
