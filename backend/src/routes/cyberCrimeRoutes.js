const express = require('express');
const { authGuard } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const {
  analyzeScam,
  reportCyberCrime,
  listMyCyberCrimeReports,
  uploadVaultEvidence,
  createVaultEvidenceMetadata,
  listVaultEvidence,
  exportVaultPackage,
  getLearningContent,
  getLearningProgress,
  saveLearningProgress,
  getDeepfakeResources,
  uploadEvidence,
  analyzeSchema,
  reportSchema,
  evidenceSchema,
  progressSchema,
} = require('../controllers/cyberCrimeController');

const router = express.Router();

router.post('/assistant/analyze', authGuard, validate(analyzeSchema), analyzeScam);
router.post('/report', authGuard, validate(reportSchema), reportCyberCrime);
router.get('/my-reports', authGuard, listMyCyberCrimeReports);
router.post('/evidence', authGuard, validate(evidenceSchema), createVaultEvidenceMetadata);
router.post('/evidence/upload', authGuard, uploadEvidence.single('file'), uploadVaultEvidence);
router.get('/evidence', authGuard, listVaultEvidence);
router.get('/evidence/export', authGuard, exportVaultPackage);
router.get('/learning/content', getLearningContent);
router.get('/learning/progress', authGuard, getLearningProgress);
router.post('/learning/progress', authGuard, validate(progressSchema), saveLearningProgress);
router.get('/deepfake/resources', getDeepfakeResources);

module.exports = router;
