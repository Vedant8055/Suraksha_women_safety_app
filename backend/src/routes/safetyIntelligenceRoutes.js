const express = require('express');
const { validate } = require('../middleware/validate');
const {
  liveAssessmentSchema,
  routeAssessmentSchema,
  getLiveAssessment,
  postRouteAssessment,
} = require('../controllers/safetyIntelligenceController');

const router = express.Router();

router.get('/live', validate(liveAssessmentSchema), getLiveAssessment);
router.post('/routes', validate(routeAssessmentSchema), postRouteAssessment);

module.exports = router;
