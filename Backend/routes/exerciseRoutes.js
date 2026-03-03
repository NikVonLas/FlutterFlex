const express = require('express');
const multer = require('multer');
const exerciseController = require('../controllers/exerciseController');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

// Alle Übungen
router.get('/', exerciseController.getAllExercises);

// Übungen nach Muskelgruppe
router.get('/muscle-group/:muscleGroup', exerciseController.getExercisesByMuscleGroup);

// Einzelne Übung
router.get('/:id', exerciseController.getExerciseById);

// Neue Übung erstellen (mit optionalem Bild)
router.post('/', upload.single('image'), exerciseController.createExercise);

// Übung aktualisieren
router.put('/:id', exerciseController.updateExercise);

// Übungsbild hochladen
router.post('/:id/image', upload.single('image'), exerciseController.uploadExerciseImage);

// Übungsbild abrufen
router.get('/:id/image', exerciseController.getExerciseImage);

// Übung löschen
router.delete('/:id', exerciseController.deleteExercise);

module.exports = router;
