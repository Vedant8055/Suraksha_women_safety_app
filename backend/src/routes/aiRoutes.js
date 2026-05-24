const express = require('express');
const { authGuard } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { chat, aiChatSchema } = require('../controllers/aiController');
const router = express.Router();
router.post('/chat', authGuard, validate(aiChatSchema), chat);
module.exports = router;
