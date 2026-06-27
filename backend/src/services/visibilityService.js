const { clamp } = require('../utils/safetyGeoUtils');

function scoreVisibility({ crowd, osm, poiDensity = 0 }) {
  let score = 58;
  const sources = [];

  const level = crowd?.activityLevel;
  if (level === 'high') {
    score += 18;
    sources.push('crowd_aggregate');
  } else if (level === 'moderate') {
    score += 10;
    sources.push('crowd_aggregate');
  } else if (level === 'low') {
    score += 4;
    sources.push('crowd_aggregate');
  } else if (level === 'very_low') {
    score -= 8;
    sources.push('crowd_aggregate');
  }

  const supportPois = (osm?.policeCount || 0) + (osm?.hospitalCount || 0) + poiDensity;
  if (supportPois >= 8) {
    score += 12;
    sources.push('openstreetmap');
  } else if (supportPois >= 3) {
    score += 6;
    sources.push('openstreetmap');
  }

  score = clamp(Math.round(score), 20, 95);
  const confidence = crowd?.available ? crowd.confidence || 60 : 42;

  return {
    score,
    label:
      score >= 75
        ? 'High visibility'
        : score >= 55
        ? 'Moderate visibility'
        : 'Low visibility',
    confidence,
    sources: [...new Set(sources)],
    disclaimer:
      'Visibility estimated from anonymous crowd pings and OSM POI density—not live footfall sensors.',
  };
}

module.exports = { scoreVisibility };
