const express = require('express');
const { getLiveSos, renderLiveSosPage } = require('../controllers/liveSosController');

const router = express.Router();

router.get('/api/live-sos/:shareToken', getLiveSos);
router.get('/live-sos/:shareToken', renderLiveSosPage);

module.exports = router;
