const express = require('express');
const router = express.Router();
const {
  register,
  login,
  refresh,
  logout,
  getProfile,
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');
const {
  validateRegister,
  validateLogin,
  validateRefreshToken,
} = require('../middleware/validationMiddleware');

router.post('/register', validateRegister, register);
router.post('/login', validateLogin, login);
router.post('/refresh', validateRefreshToken, refresh);
router.post('/logout', validateRefreshToken, logout);
router.get('/profile', protect, getProfile);

module.exports = router;
