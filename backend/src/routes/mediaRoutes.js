const express = require('express');
const { authGuard } = require('../middleware/auth');
const { upload, uploadMedia } = require('../controllers/mediaController');
const router = express.Router();
router.post('/upload', authGuard, upload.single('file'), uploadMedia);
module.exports = router;
