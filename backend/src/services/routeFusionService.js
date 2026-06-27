const { fusionIntelligenceConfig } = require('../config/fusionIntelligenceConfig');
const { safetyIntelligenceConfig } = require('../config/safetyIntelligenceConfig');
const { fuseSafetyIntelligence, incidentWeight } = require('./fusionEngineService');
const { queryOsmFeaturesInBbox } = require('./osmIngestionService');
const {
  clamp,
  haversineMeters,
  samplePolyline,
  bboxFromPoints,
} = require('../utils/safetyGeoUtils');

function mapRiskLevel(score) {
  const levels = [
    { min: 81, label: 'Very Safe' },
    { min: 61, label: 'Safe' },
    { min: 41, label: 'Moderate Risk' },
    { min: 21, label: 'High Risk' },
    { min: 0, label: 'Critical Risk' },
  ];
  return levels.find((entry) => score >= entry.min) || levels[levels.length - 1];
}

function unlitProximityScore(point, osmFeatures) {
  const unlit = (osmFeatures || []).filter((item) => item.featureType === 'unlit_road');
  if (unlit.length === 0) return 0;
  let nearest = Infinity;
  for (const item of unlit) {
    const [lng, lat] = item.location?.coordinates || [];
    nearest = Math.min(nearest, haversineMeters(point.lat, point.lng, lat, lng));
  }
  if (nearest <= 80) return 1;
  if (nearest <= 200) return 0.6;
  if (nearest <= 400) return 0.3;
  return 0;
}

async function scoreRouteCandidate(route, context, at, external, osmFeatures) {
  const path = Array.isArray(route.path)
    ? route.path
        .map((point) => {
          if (typeof point.lat === 'number' && typeof point.lng === 'number') return point;
          return null;
        })
        .filter(Boolean)
    : [];
  if (path.length === 0) return null;

  const samples = samplePolyline(path, fusionIntelligenceConfig.routeSampleIntervalMeters);
  const isNight =
    typeof external?.sunset?.isDark === 'boolean'
      ? external.sunset.isDark
      : at.getHours() >= 20 || at.getHours() < 6;

  let incidentPressure = 0;
  let supportCoverage = 0;
  let unlitHits = 0;

  for (const point of samples) {
    unlitHits += unlitProximityScore(point, osmFeatures);

    for (const incident of context.incidents || []) {
      const [incidentLng, incidentLat] = incident.location?.coordinates || [];
      const distance = haversineMeters(point.lat, point.lng, incidentLat, incidentLng);
      if (distance <= 550) {
        incidentPressure +=
          incidentWeight({ ...incident, source: 'suraksha_reports', occurredAt: incident.createdAt }) *
          ((550 - distance) / 550);
      }
    }

    for (const authority of context.authorities || []) {
      const [authorityLng, authorityLat] = authority.location?.coordinates || [];
      const distance = haversineMeters(point.lat, point.lng, authorityLat, authorityLng);
      if (distance <= 650) {
        supportCoverage += (650 - distance) / 650;
      }
    }
  }

  const unlitPercent = samples.length > 0 ? Math.round((unlitHits / samples.length) * 100) : 0;
  const safeZoneTouches = (context.safetyZones || []).reduce((count, zone) => {
    const [zoneLng, zoneLat] = zone.location?.coordinates || [];
    const hits = samples.some(
      (point) => haversineMeters(point.lat, point.lng, zoneLat, zoneLng) <= (zone.radiusMeters || 400),
    );
    return count + (hits ? 1 : 0);
  }, 0);

  const profile =
    safetyIntelligenceConfig.routeProfiles.find((item) => item.id === route.profileId) ||
    safetyIntelligenceConfig.routeProfiles[0];
  const durationMinutes = Math.max(1, Math.round((route.durationSeconds || 0) / 60));
  const distanceKm = Math.max(0.1, (route.distanceMeters || 0) / 1000);

  let score = 78;
  score -= clamp(incidentPressure * 14, 0, 30);
  score += clamp(supportCoverage * profile.supportBonusFactor * 2.8, 0, 18);
  score += clamp(safeZoneTouches * 3.5 * profile.bufferFactor, 0, 12);
  score -= clamp(durationMinutes * profile.pacePenaltyFactor, 0, 10);
  score -= clamp(distanceKm * 1.6, 0, 8);
  if (isNight) score -= 8;
  if (isNight && unlitPercent >= 35) score -= clamp(unlitPercent * 0.18, 0, 18);
  else if (unlitPercent >= 20) score -= 6;

  score = clamp(Math.round(score), 0, 100);
  const riskLevel = mapRiskLevel(score);

  const factors = [];
  if (incidentPressure > 0.8) factors.push('passes closer to recent verified incident activity');
  if (unlitPercent >= 25) factors.push(`includes ~${unlitPercent}% unlit segments (OSM)`);
  if (supportCoverage > 1.4) factors.push('stays closer to mapped emergency support');
  if (safeZoneTouches > 0) factors.push('aligns with community-supported safer stretches');
  if (isNight) factors.push('requires extra caution after sunset');
  if (factors.length === 0) factors.push('balances travel time with available support coverage');

  return {
    id: route.id,
    label: profile.label,
    badge: profile.badge || null,
    recommended: false,
    averageSafetyScore: score,
    maxRiskLevel: riskLevel.label,
    travelTimeMinutes: durationMinutes,
    distanceMeters: Math.round(route.distanceMeters || 0),
    unlitPercent,
    routeDimensions: {
      crime: clamp(Math.round(100 - incidentPressure * 20), 0, 100),
      infrastructure: clamp(Math.round(100 - unlitPercent * 0.7), 0, 100),
      support: clamp(Math.round(50 + supportCoverage * 10), 0, 100),
    },
    summary: `This route ${factors[0]}.`,
    recommendations: [
      unlitPercent >= 25 && isNight ? 'Prefer a route with more mapped lit segments after dark.' : null,
      incidentPressure > 0.4 ? 'Remain alert along segments near recent incident reports.' : null,
      'Share live location with a trusted contact while traveling.',
    ]
      .filter(Boolean)
      .slice(0, 3),
  };
}

async function loadOsmForRoutes(candidates) {
  const allPoints = candidates.flatMap((route) =>
    (route.path || [])
      .map((point) =>
        typeof point.lat === 'number' && typeof point.lng === 'number' ? point : null,
      )
      .filter(Boolean),
  );
  const bbox = bboxFromPoints(allPoints, 500);
  if (!bbox) return [];
  return queryOsmFeaturesInBbox(bbox);
}

module.exports = {
  scoreRouteCandidate,
  loadOsmForRoutes,
};
