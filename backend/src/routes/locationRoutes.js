const express = require('express');
const { authGuard } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { updateLocation, updateLocationSchema } = require('../controllers/locationController');

const router = express.Router();
router.post('/update', authGuard, validate(updateLocationSchema), updateLocation);
module.exports = router;
