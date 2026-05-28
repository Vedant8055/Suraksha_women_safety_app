const { asyncHandler } = require('../utils/asyncHandler');
const LiveLocation = require('../models/LiveLocation');
const SOSEvent = require('../models/SOSEvent');

const toPublicLocation = (record) => {
  if (!record) return null;
  const [lng, lat] = record.location.coordinates;
  return {
    lat,
    lng,
    accuracy: record.accuracy,
    speed: record.speed,
    heading: record.heading,
    updatedAt: record.createdAt,
  };
};

const getLiveSos = asyncHandler(async (req, res) => {
  const event = await SOSEvent.findOne({ shareToken: req.params.shareToken });
  if (!event) {
    return res.status(404).json({ message: 'Live SOS link not found.' });
  }

  const locations = await LiveLocation.find({ sosEventId: event._id })
    .sort({ createdAt: -1 })
    .limit(60);
  const [initialLng, initialLat] = event.location.coordinates;
  const latest = locations[0];

  return res.json({
    status: event.status,
    startedAt: event.createdAt,
    latest: toPublicLocation(latest) || {
      lat: initialLat,
      lng: initialLng,
      updatedAt: event.createdAt,
    },
    path: locations.reverse().map(toPublicLocation),
  });
});

const renderLiveSosPage = asyncHandler(async (req, res) => {
  const event = await SOSEvent.findOne({ shareToken: req.params.shareToken });
  if (!event) {
    return res.status(404).send('Live SOS link not found.');
  }

  res.setHeader('Content-Security-Policy', "default-src 'self' https://www.google.com https://maps.google.com; frame-src https://www.google.com https://maps.google.com; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'");
  res.type('html').send(`<!doctype html>
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
});

module.exports = { getLiveSos, renderLiveSosPage };
