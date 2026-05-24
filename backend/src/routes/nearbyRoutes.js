const express = require('express');
const { nearbyPolice, nearbyHospitals } = require('../controllers/nearbyController');
const router = express.Router();
router.get('/police', nearbyPolice);
router.get('/hospitals', nearbyHospitals);
module.exports = router;
