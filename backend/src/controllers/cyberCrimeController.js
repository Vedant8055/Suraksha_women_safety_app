const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { z } = require('zod');
const { asyncHandler } = require('../utils/asyncHandler');
const CyberCrimeReport = require('../models/CyberCrimeReport');
const CyberEvidence = require('../models/CyberEvidence');
const CyberLearningProgress = require('../models/CyberLearningProgress');
const env = require('../config/env');

const reportCategories = [
  'Financial Fraud',
  'Cyber Stalking',
  'Online Bullying',
  'Identity Theft',
  'Social Media Harassment',
  'Harassment',
  'Blackmail',
  'Fake Profile',
  'Deepfake Threat',
  'Deepfake Scam',
  'Fake Job Scam',
  'UPI Fraud',
];

const learningTopics = [
  {
    id: 'phishing',
    title: 'Phishing Awareness',
    summary: 'Spot fake links, urgent messages and login traps before you click.',
    tips: ['Check the domain carefully.', 'Do not share OTPs.', 'Use official apps or websites.'],
    quiz: [
      { question: 'Should you share an OTP with support staff?', options: ['No', 'Yes'], answerIndex: 0 },
    ],
  },
  {
    id: 'upi',
    title: 'Safe UPI Usage',
    summary: 'Protect UPI PINs, collect requests and payment confirmations.',
    tips: ['Entering UPI PIN means money may leave your account.', 'Verify payee names.', 'Reject unknown collect requests.'],
    quiz: [
      { question: 'A collect request from an unknown person is safe by default?', options: ['No', 'Yes'], answerIndex: 0 },
    ],
  },
  {
    id: 'privacy',
    title: 'Social Media Privacy',
    summary: 'Reduce stalking, impersonation and fake profile risks.',
    tips: ['Limit public profile data.', 'Review tagged photos.', 'Block and report impersonators.'],
    quiz: [
      { question: 'Public personal details can aid impersonation?', options: ['Yes', 'No'], answerIndex: 0 },
    ],
  },
  {
    id: 'deepfake',
    title: 'Deepfake Awareness',
    summary: 'Understand morphed media threats and immediate response steps.',
    tips: ['Do not panic or negotiate.', 'Preserve URLs and screenshots.', 'Report quickly through cybercrime channels.'],
    quiz: [
      { question: 'Should threatening morphed content be deleted before evidence capture?', options: ['No', 'Yes'], answerIndex: 0 },
    ],
  },
];

const deepfakeResources = {
  title: 'Deepfake & Morphed Image Emergency Support',
  sections: [
    {
      title: 'What are deepfakes?',
      body: 'AI-generated or manipulated media that can falsely show a person saying or doing something.',
    },
    {
      title: 'Warning signs',
      body: 'Unnatural facial edges, mismatched lighting, odd lip movement, pressure to pay money, or anonymous threats.',
    },
    {
      title: 'What to do immediately',
      body: 'Do not engage with the attacker. Save screenshots, URLs, timestamps and account handles. Call 1930 for cyber fraud support.',
    },
    {
      title: 'Evidence preservation',
      body: 'Keep original files, message headers, transaction IDs and platform links. Avoid forwarding sensitive media widely.',
    },
    {
      title: 'Legal rights',
      body: 'Victims can report online abuse, impersonation, stalking and non-consensual intimate imagery through cybercrime.gov.in.',
    },
  ],
  helplines: [
    { label: 'Cyber Crime Helpline', value: '1930' },
    { label: 'Police Emergency', value: '100' },
    { label: 'Women Helpline', value: '1091' },
  ],
};

const reportSchema = z.object({
  body: z.object({
    category: z.enum(reportCategories),
    description: z.string().min(5).max(5000),
    suspectContact: z.string().max(160).optional().default(''),
    transactionId: z.string().max(120).optional().default(''),
    incidentAt: z.string().datetime().optional(),
    evidenceUrls: z.array(z.string().url()).optional().default([]),
    isDraft: z.boolean().optional().default(false),
  }),
});

const analyzeSchema = z.object({
  body: z.object({
    text: z.string().max(8000).optional().default(''),
    question: z.string().max(1000).optional().default(''),
    links: z.array(z.string().max(500)).optional().default([]),
    extractedText: z.string().max(8000).optional().default(''),
  }),
});

const evidenceSchema = z.object({
  body: z.object({
    title: z.string().min(2).max(120),
    category: z.enum(['Screenshot', 'Audio', 'Threat Message', 'Image', 'Transaction Proof', 'Document', 'Other']).optional().default('Other'),
    tags: z.array(z.string().max(40)).optional().default([]),
    incidentReference: z.string().max(160).optional().default(''),
    reportId: z.string().optional(),
    privateMode: z.boolean().optional().default(false),
  }),
});

const progressSchema = z.object({
  body: z.object({
    topicId: z.string().min(1).max(80),
    score: z.number().min(0).max(100),
  }),
});

const evidenceStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    const dir = path.join(__dirname, '..', 'uploads', 'cyber-vault');
    fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `${Date.now()}-${crypto.randomBytes(8).toString('hex')}${ext}`);
  },
});

const uploadEvidence = multer({
  storage: evidenceStorage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = [
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/heic',
      'audio/mpeg',
      'audio/wav',
      'application/pdf',
      'text/plain',
    ];
    cb(null, allowed.includes(file.mimetype));
  },
});

function analyzeCyberThreat({ text, question, links, extractedText }) {
  const input = `${text || ''} ${question || ''} ${extractedText || ''} ${links.join(' ')}`.toLowerCase();
  const signals = [
    { pattern: /otp|one time password|password|pin|cvv|netbanking/, weight: 25, label: 'Requests for OTP/password/PIN detected.' },
    { pattern: /urgent|immediately|account.*block|kyc.*expire|verify.*account/, weight: 18, label: 'Urgent account verification pressure detected.' },
    { pattern: /upi|paytm|phonepe|gpay|collect request|refund|transaction fee/, weight: 16, label: 'UPI/payment fraud indicators detected.' },
    { pattern: /job|work from home|registration fee|interview fee|easy money/, weight: 14, label: 'Fake job or advance-fee scam indicators detected.' },
    { pattern: /blackmail|morphed|viral|leak|private photo|video call recording/, weight: 28, label: 'Blackmail/extortion language detected.' },
    { pattern: /bit\.ly|tinyurl|login|free gift|lottery|prize|crypto/, weight: 14, label: 'Suspicious link or prize lure detected.' },
  ];

  let score = links.some((link) => !/^https?:\/\//i.test(link)) ? 10 : 0;
  const summary = [];
  for (const signal of signals) {
    if (signal.pattern.test(input)) {
      score += signal.weight;
      summary.push(signal.label);
    }
  }

  const riskLevel = score >= 45 ? 'HIGH' : score >= 20 ? 'MEDIUM' : 'LOW';
  const recommendedActions = riskLevel === 'HIGH'
    ? ['Block sender', 'Do not click links', 'Save evidence', 'Report Cyber Crime', 'Call 1930 if money is involved']
    : riskLevel === 'MEDIUM'
      ? ['Verify from official source', 'Do not share sensitive data', 'Save screenshots']
      : ['Stay cautious', 'Use official websites/apps', 'Enable two-factor authentication'];

  return {
    riskLevel,
    threatSummary: summary.length ? summary.join(' ') : 'No strong scam indicators found in the submitted text.',
    recommendedActions,
    safetyTips: ['Never share OTP, PIN or passwords.', 'Do not pay to stop blackmail.', 'Preserve screenshots, links and sender IDs.'],
  };
}

function buildComplaint(payload, user) {
  const incidentDate = payload.incidentAt ? new Date(payload.incidentAt) : new Date();
  const summary = `${payload.category} complaint by ${user.fullName || 'user'} regarding: ${payload.description}`;
  const fir = [
    'CYBER CRIME COMPLAINT SUMMARY',
    `Complainant: ${user.fullName || 'Registered Suraksha user'}`,
    `Phone: ${user.phone || 'Not provided'}`,
    `Category: ${payload.category}`,
    `Incident Date/Time: ${incidentDate.toISOString()}`,
    `Suspect Contact: ${payload.suspectContact || 'Not provided'}`,
    `Transaction ID: ${payload.transactionId || 'Not provided'}`,
    '',
    'Incident Description:',
    payload.description,
    '',
    'Requested Action:',
    'Kindly register this cyber crime complaint, preserve digital evidence, investigate suspect accounts/contact details, and provide further legal guidance.',
  ].join('\n');
  return { summary, fir, pdfBase64: buildSimplePdfBase64(fir) };
}

function buildSimplePdfBase64(text) {
  const safeText = text.replace(/[()\\]/g, ' ');
  const stream = `BT /F1 11 Tf 50 780 Td (${safeText.slice(0, 2500).replace(/\n/g, ') Tj T* (')}) Tj ET`;
  const pdf = `%PDF-1.4\n1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n3 0 obj << /Type /Page /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> /MediaBox [0 0 612 792] /Contents 5 0 R >> endobj\n4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n5 0 obj << /Length ${stream.length} >> stream\n${stream}\nendstream endobj\ntrailer << /Root 1 0 R >>\n%%EOF`;
  return Buffer.from(pdf).toString('base64');
}

const analyzeScam = asyncHandler(async (req, res) => {
  res.json(analyzeCyberThreat(req.validated.body));
});

const reportCyberCrime = asyncHandler(async (req, res) => {
  const generated = buildComplaint(req.validated.body, req.user);
  const report = await CyberCrimeReport.create({
    userId: req.user._id,
    ...req.validated.body,
    incidentAt: req.validated.body.incidentAt ? new Date(req.validated.body.incidentAt) : undefined,
    complaintSummary: generated.summary,
    firStyleReport: generated.fir,
    pdfBase64: generated.pdfBase64,
  });

  res.status(201).json(report);
});

const listMyCyberCrimeReports = asyncHandler(async (req, res) => {
  const reports = await CyberCrimeReport.find({ userId: req.user._id }).sort({ createdAt: -1 });
  res.json(reports);
});

const uploadVaultEvidence = asyncHandler(async (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'No valid file uploaded' });

  const input = fs.readFileSync(req.file.path);
  const key = crypto.createHash('sha256').update(env.jwtSecret).digest();
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(input), cipher.final()]);
  const authTag = cipher.getAuthTag();
  const encryptedPath = `${req.file.path}.enc`;
  fs.writeFileSync(encryptedPath, Buffer.concat([iv, authTag, encrypted]));
  fs.unlinkSync(req.file.path);

  const evidence = await CyberEvidence.create({
    userId: req.user._id,
    reportId: req.body.reportId || undefined,
    title: req.body.title || req.file.originalname,
    category: req.body.category || 'Other',
    tags: typeof req.body.tags === 'string' ? req.body.tags.split(',').map((tag) => tag.trim()).filter(Boolean) : [],
    incidentReference: req.body.incidentReference || '',
    privateMode: req.body.privateMode === 'true',
    filePath: encryptedPath,
    fileType: req.file.mimetype,
    fileSize: req.file.size,
    encrypted: true,
    checksum: crypto.createHash('sha256').update(input).digest('hex'),
  });

  res.status(201).json(evidence);
});

const createVaultEvidenceMetadata = asyncHandler(async (req, res) => {
  const evidence = await CyberEvidence.create({
    userId: req.user._id,
    ...req.validated.body,
    encrypted: true,
  });
  res.status(201).json(evidence);
});

const listVaultEvidence = asyncHandler(async (req, res) => {
  const query = { userId: req.user._id };
  if (req.query.category) query.category = req.query.category;
  if (req.query.search) query.title = { $regex: req.query.search, $options: 'i' };
  const evidence = await CyberEvidence.find(query).sort({ createdAt: -1 }).limit(100);
  res.json(evidence);
});

const exportVaultPackage = asyncHandler(async (req, res) => {
  const evidence = await CyberEvidence.find({ userId: req.user._id }).sort({ createdAt: -1 });
  res.json({
    generatedAt: new Date().toISOString(),
    count: evidence.length,
    encrypted: true,
    evidence,
  });
});

const getLearningContent = asyncHandler(async (_req, res) => {
  res.json(learningTopics);
});

const getLearningProgress = asyncHandler(async (req, res) => {
  const progress = await CyberLearningProgress.findOne({ userId: req.user._id });
  res.json(progress || { completedTopicIds: [], quizScores: [], badges: [], safetyScore: 0 });
});

const saveLearningProgress = asyncHandler(async (req, res) => {
  const { topicId, score } = req.validated.body;
  const progress = await CyberLearningProgress.findOneAndUpdate(
    { userId: req.user._id },
    {
      $addToSet: {
        completedTopicIds: topicId,
        badges: score >= 80 ? 'Cyber Defender' : 'Cyber Learner',
      },
      $push: { quizScores: { topicId, score } },
      $set: { safetyScore: Math.min(100, score) },
    },
    { upsert: true, new: true },
  );
  res.json(progress);
});

const getDeepfakeResources = asyncHandler(async (_req, res) => {
  res.json(deepfakeResources);
});

module.exports = {
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
};
