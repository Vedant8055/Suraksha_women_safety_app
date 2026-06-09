const multer = require('multer');
const fs = require('fs');
const MediaEvidence = require('../models/MediaEvidence');
const { asyncHandler } = require('../utils/asyncHandler');
const { uploadToCloudinary } = require('../services/mediaService');
const { tempUploadsRoot } = require('../config/paths');

fs.mkdirSync(tempUploadsRoot, { recursive: true });
const upload = multer({ dest: tempUploadsRoot });

const uploadMedia = asyncHandler(async (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'No file uploaded' });
  const result = await uploadToCloudinary(req.file.path, 'suraksha/evidence');
  const media = await MediaEvidence.create({
    userId: req.user._id,
    incidentId: req.body.incidentId,
    sosEventId: req.body.sosEventId,
    mediaType: req.body.mediaType || 'image',
    storageUrl: result.secure_url,
    mimeType: req.file.mimetype,
    size: req.file.size,
  });
  res.status(201).json(media);
});

module.exports = { upload, uploadMedia };
