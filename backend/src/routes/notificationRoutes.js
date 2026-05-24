const express = require('express');
const { authGuard } = require('../middleware/auth');
const { listNotifications } = require('../controllers/notificationController');
const router = express.Router();
router.get('/', authGuard, listNotifications);
module.exports = router;
