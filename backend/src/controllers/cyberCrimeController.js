const { z } = require('zod');
const { asyncHandler } = require('../utils/asyncHandler');
const CyberCrimeReport = require('../models/CyberCrimeReport');

const reportSchema = z.object({
  body: z.object({
    category: z.enum([
      'Financial Fraud',
      'Cyber Stalking',
      'Online Bullying',
      'Identity Theft',
      'Social Media Harassment',
    ]),
    description: z.string().min(5),
    evidenceUrls: z.array(z.string().url()).optional().default([]),
  }),
});

const reportCyberCrime = asyncHandler(async (req, res) => {
  const report = await CyberCrimeReport.create({
    userId: req.user._id,
    ...req.validated.body,
  });

  res.status(201).json(report);
});

const listMyCyberCrimeReports = asyncHandler(async (req, res) => {
  const reports = await CyberCrimeReport.find({ userId: req.user._id }).sort({ createdAt: -1 });
  res.json(reports);
});

module.exports = {
  reportCyberCrime,
  listMyCyberCrimeReports,
  reportSchema,
};
