const express = require('express');
const { authGuard } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const {
  analyzeScam,
  analyzeScamWithImage,
  reportCyberCrime,
  listMyCyberCrimeReports,
  getCyberCrimeReportDetail,
  linkEvidenceToReport,
  uploadVaultEvidence,
  createVaultEvidenceMetadata,
  listVaultEvidence,
  exportVaultPackage,
  downloadVaultEvidence,
  deleteVaultEvidence,
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
router.post(
  '/assistant/analyze-image',
  authGuard,
  uploadEvidence.single('screenshot'),
  analyzeScamWithImage,
);
router.post('/report', authGuard, validate(reportSchema), reportCyberCrime);
router.get('/my-reports', authGuard, listMyCyberCrimeReports);
router.get('/my-reports/:id', authGuard, getCyberCrimeReportDetail);
router.post('/evidence', authGuard, validate(evidenceSchema), createVaultEvidenceMetadata);
router.post('/evidence/upload', authGuard, uploadEvidence.single('file'), uploadVaultEvidence);
router.get('/evidence/export', authGuard, exportVaultPackage);
router.get('/evidence/:id/download', authGuard, downloadVaultEvidence);
router.patch('/evidence/:id/link', authGuard, linkEvidenceToReport);
router.delete('/evidence/:id', authGuard, deleteVaultEvidence);
router.get('/evidence', authGuard, listVaultEvidence);
router.get('/learning/content', getLearningContent);
router.get('/learning/progress', authGuard, getLearningProgress);
router.post('/learning/progress', authGuard, validate(progressSchema), saveLearningProgress);
router.get('/deepfake/resources', getDeepfakeResources);

module.exports = router;
