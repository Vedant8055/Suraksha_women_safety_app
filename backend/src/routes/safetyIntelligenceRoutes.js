const express = require('express');
const { validate } = require('../middleware/validate');
const { authGuard } = require('../middleware/auth');
const {
  liveAssessmentSchema,
  routeAssessmentSchema,
  pingSchema,
  journeyUpdateSchema,
  preferencesPatchSchema,
  summarySchema,
  getLiveAssessment,
  postRouteAssessment,
  postAnonymousPing,
  getHealth,
  postJourneyUpdate,
  getPreferences,
  patchPreferences,
  postSummary,
} = require('../controllers/safetyIntelligenceController');

const router = express.Router();

router.get('/health', getHealth);
router.get('/live', validate(liveAssessmentSchema), getLiveAssessment);
router.post('/routes', validate(routeAssessmentSchema), postRouteAssessment);
router.post('/pings', validate(pingSchema), postAnonymousPing);
router.post('/summary', validate(summarySchema), postSummary);
router.get('/preferences', authGuard, getPreferences);
router.patch('/preferences', authGuard, validate(preferencesPatchSchema), patchPreferences);
router.post('/journey/update', authGuard, validate(journeyUpdateSchema), postJourneyUpdate);

module.exports = router;
