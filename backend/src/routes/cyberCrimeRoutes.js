const express = require('express');
const { authGuard } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const {
  reportCyberCrime,
  listMyCyberCrimeReports,
  reportSchema,
} = require('../controllers/cyberCrimeController');

const router = express.Router();

router.post('/report', authGuard, validate(reportSchema), reportCyberCrime);
router.get('/my-reports', authGuard, listMyCyberCrimeReports);

module.exports = router;
