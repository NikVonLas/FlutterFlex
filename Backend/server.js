const express = require('express');
const cors = require('cors');
require('dotenv').config();
const { initializeDatabase } = require('./config/db');
const verifyToken = require('./middleware/auth');

// Routes importieren
const authController = require('./controllers/authController');
const authRoutes = require('./routes/authRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const exerciseRoutes = require('./routes/exerciseRoutes');
const userRoutes = require('./routes/userRoutes');
const workoutRoutes = require('./routes/workoutRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Routes
app.post('/api/login', authController.login);
app.post('/api/register', authController.register);
app.use('/api/auth', authRoutes);
app.use('/api/dashboard', verifyToken, dashboardRoutes);
app.use('/api/exercises', exerciseRoutes);
app.use('/api/users', verifyToken, userRoutes);
app.use('/api/workouts', verifyToken, workoutRoutes);

// Health Check
app.get('/api/health', (req, res) => {
  res.json({ status: 'Server is running' });
});

// Error Handling Middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error', message: err.message });
});

// Server starten
async function startServer() {
  try {
    await initializeDatabase();
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;
