const express = require('express');
const { authGuard } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const {
  cancel,
  create,
  active,
  createSosSchema,
  cancelSosSchema,
} = require('../controllers/sosController');

const router = express.Router();
router.post('/create', authGuard, validate(createSosSchema), create);
router.post('/cancel', authGuard, validate(cancelSosSchema), cancel);
router.get('/active', authGuard, active);
module.exports = router;
