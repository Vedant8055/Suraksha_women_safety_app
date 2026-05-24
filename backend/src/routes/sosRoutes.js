const express = require('express');
const { authGuard } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { create, active, createSosSchema } = require('../controllers/sosController');

const router = express.Router();
router.post('/create', authGuard, validate(createSosSchema), create);
router.get('/active', authGuard, active);
module.exports = router;
