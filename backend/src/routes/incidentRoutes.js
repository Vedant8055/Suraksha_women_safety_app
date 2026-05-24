const express = require('express');
const { authGuard } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { reportIncident, reportSchema } = require('../controllers/incidentController');

const router = express.Router();
router.post('/report', authGuard, validate(reportSchema), reportIncident);
module.exports = router;
