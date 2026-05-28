const crypto = require('crypto');
const express = require('express');
const SOSEvent = require('../models/SOSEvent');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

const isValidCoordinate = (value, min, max) =>
  typeof value === 'number' && Number.isFinite(value) && value >= min && value <= max;

const toTrackingUrl = (req, shareToken) =>
  `${req.protocol}://${req.get('host')}/live-sos/${shareToken}`;

router.post('/api/sos/create', protect, async (req, res, next) => {
  try {
    const lat = Number(req.body.lat);
    const lng = Number(req.body.lng);
    if (!isValidCoordinate(lat, -90, 90) || !isValidCoordinate(lng, -180, 180)) {
      return res.status(400).json({ message: 'Invalid SOS location.' });
    }

    const sos = await SOSEvent.create({
      userId: req.user._id,
      shareToken: crypto.randomBytes(18).toString('hex'),
      location: { lat, lng },
      liveTracking: [{ lat, lng }],
      emergencyType: req.body.mode || 'normal',
    });

    return res.status(201).json({
      ...sos.toObject(),
      trackingUrl: toTrackingUrl(req, sos.shareToken),
    });
  } catch (error) {
    return next(error);
  }
});

router.post('/api/location/update', protect, async (req, res, next) => {
  try {
    const lat = Number(req.body.lat);
    const lng = Number(req.body.lng);
    if (!isValidCoordinate(lat, -90, 90) || !isValidCoordinate(lng, -180, 180)) {
      return res.status(400).json({ message: 'Invalid live location.' });
    }

    const query = req.body.sosEventId
      ? { _id: req.body.sosEventId, userId: req.user._id }
      : { userId: req.user._id, status: 'active' };
    const sos = await SOSEvent.findOneAndUpdate(
      query,
      { $push: { liveTracking: { lat, lng, timestamp: new Date() } } },
      { sort: { createdAt: -1 }, new: true },
    );

    if (!sos) {
      return res.status(404).json({ message: 'Active SOS not found.' });
    }

    return res.status(201).json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

router.get('/api/live-sos/:shareToken', async (req, res, next) => {
  try {
    const sos = await SOSEvent.findOne({ shareToken: req.params.shareToken });
    if (!sos) {
      return res.status(404).json({ message: 'Live SOS link not found.' });
    }

    const path = sos.liveTracking.slice(-60).map((location) => ({
      lat: location.lat,
      lng: location.lng,
      updatedAt: location.timestamp,
    }));
    const latest = path[path.length - 1] || {
      lat: sos.location.lat,
      lng: sos.location.lng,
      updatedAt: sos.createdAt,
    };

    return res.json({
      status: sos.status,
      startedAt: sos.createdAt,
      latest,
      path,
    });
  } catch (error) {
    return next(error);
  }
});

router.get('/live-sos/:shareToken', async (req, res, next) => {
  try {
    const sos = await SOSEvent.findOne({ shareToken: req.params.shareToken });
    if (!sos) {
      return res.status(404).send('Live SOS link not found.');
    }

    res.setHeader('Content-Security-Policy', "default-src 'self' https://www.google.com https://maps.google.com; frame-src https://www.google.com https://maps.google.com; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'");
    return res.type('html').send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Suraksha Live SOS</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f6f8fc; color: #172235; }
    header { padding: 16px; background: #ffffff; border-bottom: 1px solid #dce5f6; }
    h1 { margin: 0; font-size: 18px; }
    p { margin: 6px 0 0; color: #60708a; font-size: 13px; }
    iframe { width: 100%; height: calc(100vh - 86px); border: 0; display: block; }
    .badge { color: #b42318; font-weight: 700; }
  </style>
</head>
<body>
  <header>
    <h1>Suraksha Live SOS <span class="badge" id="status">ACTIVE</span></h1>
    <p id="meta">Loading latest location...</p>
  </header>
  <iframe id="map" loading="eager" referrerpolicy="no-referrer-when-downgrade"></iframe>
  <script>
    const token = ${JSON.stringify(req.params.shareToken)};
    const map = document.getElementById('map');
    const meta = document.getElementById('meta');
    const status = document.getElementById('status');
    let lastLocationKey = '';

    async function refreshLocation() {
      try {
        const response = await fetch('/api/live-sos/' + token, { cache: 'no-store' });
        const data = await response.json();
        if (!data.latest) return;

        const lat = Number(data.latest.lat).toFixed(6);
        const lng = Number(data.latest.lng).toFixed(6);
        const key = lat + ',' + lng;
        status.textContent = String(data.status || 'active').toUpperCase();
        meta.textContent = 'Latest location: ' + key + ' | Updated: ' + new Date(data.latest.updatedAt).toLocaleString();

        if (key !== lastLocationKey) {
          lastLocationKey = key;
          map.src = 'https://www.google.com/maps?q=' + encodeURIComponent(key) + '&z=17&output=embed';
        }
      } catch (error) {
        meta.textContent = 'Trying to reconnect to live location...';
      }
    }

    refreshLocation();
    setInterval(refreshLocation, 5000);
  </script>
</body>
</html>`);
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
