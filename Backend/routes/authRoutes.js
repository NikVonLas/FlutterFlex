const express = require('express');
const multer = require('multer');
const authController = require('../controllers/authController');
const verifyToken = require('../middleware/auth');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

// Auth Endpoints
router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/me', verifyToken, authController.getCurrentUser);

// Profil Endpoints
router.get('/profile/:userId', verifyToken, authController.getProfile);
router.put('/profile/:userId', verifyToken, authController.updateProfile);

// Profilbild Endpoints
router.get('/profile/:userId/image', verifyToken, authController.getProfileImage);
router.post('/profile/:userId/image', verifyToken, upload.single('image'), authController.uploadProfileImage);

// Einstellungen
router.put('/preferences/:userId', verifyToken, authController.updatePreferences);

module.exports = router;
