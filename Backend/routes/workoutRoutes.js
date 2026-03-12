const express = require('express');
const workoutController = require('../controllers/workoutController');

const router = express.Router();

router.get('/', workoutController.getUserWorkouts);
router.get('/user/:userId', workoutController.getUserWorkouts);
router.get('/stats/:userId', workoutController.getWorkoutStats);
router.get('/:id', workoutController.getWorkoutById);
router.post('/', workoutController.createWorkout);
router.put('/:id', workoutController.updateWorkout);
router.delete('/:id', workoutController.deleteWorkout);

router.get('/:workoutId/sets', workoutController.getWorkoutSets);
router.get('/:workoutId/sets/:setId', workoutController.getSetById);
router.post('/:workoutId/sets', workoutController.createSet);
router.put('/:workoutId/sets/:setId', workoutController.updateSet);
router.delete('/:workoutId/sets/:setId', workoutController.deleteSet);

module.exports = router;