const express = require('express');
const router = express.Router();
const CyberCrimeReport = require('../models/CyberCrimeReport');
const { protect } = require('../middleware/authMiddleware');
const {
  validateCyberCrimeReport,
} = require('../middleware/validationMiddleware');

router.post('/report', protect, validateCyberCrimeReport, async (req, res, next) => {
  try {
    const { category, description, evidenceUrls } = req.body;
    const report = await CyberCrimeReport.create({
      userId: req.user._id,
      category,
      description,
      evidenceUrls
    });
    res.status(201).json(report);
  } catch (error) {
    next(error);
  }
});

router.get('/my-reports', protect, async (req, res, next) => {
  try {
    const reports = await CyberCrimeReport.find({ userId: req.user._id });
    res.json(reports);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
