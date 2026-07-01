const express = require('express');
const { validate } = require('../middleware/validate');
const {
  nearbyToiletsRequestSchema,
  getNearbyToilets,
} = require('../controllers/toiletController');

const router = express.Router();

router.get('/toilets/nearby', validate(nearbyToiletsRequestSchema), getNearbyToilets);

module.exports = router;
