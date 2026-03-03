const express = require('express');
const multer = require('multer');
const authController = require('../controllers/authController');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

// Auth Endpoints
router.post('/register', authController.register);
router.post('/login', authController.login);

// Profil Endpoints
router.get('/profile/:userId', authController.getProfile);
router.put('/profile/:userId', authController.updateProfile);

// Profilbild Endpoints
router.get('/profile/:userId/image', authController.getProfileImage);
router.post('/profile/:userId/image', upload.single('image'), authController.uploadProfileImage);

// Einstellungen
router.put('/preferences/:userId', authController.updatePreferences);

module.exports = router;
