const nashikSafetyConfig = {
  regionId: 'nashik',
  regionLabel: 'Nashik',
  center: { lat: 19.9975, lng: 73.7898 },
  bbox: {
    south: 19.9,
    west: 73.65,
    north: 20.12,
    east: 73.95,
  },
  crowdGridPrecision: 3,
  crowdWindowHours: 2,
  osmSyncIntervalHours: 6,
  sunsetCacheMinutes: 60,
  queryRadii: {
    osmFeaturesMeters: 1500,
    crowdActivityMeters: 800,
    unlitRoadMeters: 600,
  },
  journeyPollSeconds: 45,
  quietHoursStart: 22,
  quietHoursEnd: 7,
  dataDisclaimer:
    'Safety signals combine Suraksha app reports, OpenStreetMap infrastructure data, sunset times, and anonymous aggregated movement patterns for Nashik. This is guidance only—not a guarantee of safety. Always use personal judgment.',
};

function isWithinNashik(lat, lng) {
  const { south, west, north, east } = nashikSafetyConfig.bbox;
  return lat >= south && lat <= north && lng >= west && lng <= east;
}

module.exports = { nashikSafetyConfig, isWithinNashik };
