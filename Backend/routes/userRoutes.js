const express = require('express');
const userController = require('../controllers/userController');

const router = express.Router();

router.get('/me', userController.getCurrentUser);
router.put('/settings', userController.updateSettings);

module.exports = router;