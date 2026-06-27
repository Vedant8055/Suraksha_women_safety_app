const { fusionIntelligenceConfig } = require('../config/fusionIntelligenceConfig');
const { safetyIntelligenceConfig } = require('../config/safetyIntelligenceConfig');
const { scoreVisibility } = require('./visibilityService');
const { buildFusionNearbyResources } = require('./nearbyResourceService');
const { clamp, haversineMeters, toDisplayDistance } = require('../utils/safetyGeoUtils');

function ageHours(date) {
  return Math.max(0, (Date.now() - new Date(date).getTime()) / (1000 * 60 * 60));
}

function incidentSeverity(category = '', description = '') {
  const text = `${category} ${description}`.toLowerCase();
  if (/(assault|kidnap|rape|weapon|stalk|abduct|violence)/.test(text)) return 1.0;
  if (/(harass|molest|attack|robbery|snatch|threat)/.test(text)) return 0.82;
  if (/(theft|fraud|scam|suspicious|break)/.test(text)) return 0.62;
  return 0.48;
}

function incidentWeight(incident) {
  const hours = ageHours(incident.occurredAt || incident.createdAt);
  if (hours > safetyIntelligenceConfig.decay.staleIncidentCutoffHours) return 0;
  const decayBase = Math.pow(0.5, hours / safetyIntelligenceConfig.decay.incidentHalfLifeHours);
  const category = incident.category || '';
  const description = incident.description || '';
  const trust = fusionIntelligenceConfig.sourceTrust[incident.source] || 0.7;
  return decayBase * incidentSeverity(category, description) * trust;
}

function dimensionLabel(score) {
  if (score >= 81) return 'Very Safe';
  if (score >= 61) return 'Safe';
  if (score >= 41) return 'Moderate';
  if (score >= 21) return 'High Risk';
  return 'Critical';
}

function buildDimension(key, score, confidence, sources, disclaimer) {
  return {
    key,
    score: clamp(Math.round(score), 0, 100),
    label: dimensionLabel(score),
    confidence: clamp(Math.round(confidence), 18, 98),
    sources,
    ...(disclaimer ? { disclaimer } : {}),
  };
}

function scoreCrimeDimension({ lat, lng, context, externalIncidents, gridRisk, areaCrime }) {
  const localIncidents = context.incidents || [];
  const merged = [
    ...localIncidents.map((item) => ({ ...item, source: 'suraksha_reports', occurredAt: item.createdAt })),
    ...(externalIncidents || []).filter((item) => item.source !== 'suraksha_reports'),
  ];

  let proximityPressure = merged.reduce((sum, incident) => {
    const coords = incident.location?.coordinates || [];
    if (coords.length < 2) return sum;
    const distance = haversineMeters(lat, lng, coords[1], coords[0]);
    if (distance > 1500) return sum;
    return sum + incidentWeight(incident) * ((1500 - distance) / 1500);
  }, 0);

  const recentCount = merged.filter((item) => ageHours(item.occurredAt || item.createdAt) <= 72).length;
  let score = 82;
  score -= clamp(proximityPressure * 22, 0, 45);
  score -= clamp(recentCount * 4, 0, 16);

  if (gridRisk) {
    score = Math.round(score * 0.55 + gridRisk.score * 0.45);
  }

  if (areaCrime?.ratePer100k) {
    if (areaCrime.ratePer100k >= 150) score -= 8;
    else if (areaCrime.ratePer100k >= 120) score -= 5;
    else if (areaCrime.ratePer100k <= 90) score += 3;
  }

  const sources = ['suraksha_reports'];
  if ((externalIncidents || []).some((item) => item.source !== 'suraksha_reports')) {
    sources.push('open_data_point');
  }
  if (gridRisk?.count90d > 0) sources.push('grid_model');
  if (areaCrime) sources.push('open_data_district');

  const confidence =
    40 +
    Math.min(25, merged.length * 6) +
    (gridRisk?.confidence || 0) * 0.25 +
    (areaCrime ? 8 : 0);

  return {
    dimension: buildDimension(
      'crime',
      score,
      confidence,
      [...new Set(sources)],
      areaCrime?.disclaimer ||
        'Crime dimension combines nearby reports, grid history, and district-level open data context.',
    ),
    recentIncidentCount: recentCount,
    proximityPressure,
  };
}

function scoreInfrastructureDimension({ external, isNight }) {
  const osm = external?.osm || {};
  let score = 72;
  const sources = ['openstreetmap'];

  if (osm.lightingRatio != null) {
    score = Math.round(40 + osm.lightingRatio * 55);
  } else if (osm.litRoadCount > 0 || osm.unlitRoadCount > 0) {
    const total = osm.litRoadCount + osm.unlitRoadCount;
    score = Math.round(40 + (osm.litRoadCount / total) * 55);
  }

  if (isNight && osm.nearestUnlitDistanceMeters != null && osm.nearestUnlitDistanceMeters < 400) {
    score -= 15;
  }

  const confidence = osm.litRoadCount + osm.unlitRoadCount > 0 ? 78 : 48;
  return buildDimension(
    'infrastructure',
    score,
    confidence,
    sources,
    osm.disclaimer || 'Infrastructure from OpenStreetMap lighting tags.',
  );
}

function scoreSupportDimension({ context, external }) {
  const authorities = context.authorities || [];
  const osm = external?.osm || {};
  const police = authorities.filter((item) => item.authorityType === 'police').length + (osm.policeCount || 0);
  const hospitals =
    authorities.filter((item) => item.authorityType === 'hospital').length + (osm.hospitalCount || 0);
  const responders = authorities.filter((item) => item.authorityType === 'responder').length;
  const supportCount = police + hospitals + responders;

  let score = 50;
  if (supportCount === 0) score = 35;
  else score = clamp(50 + supportCount * 8, 45, 95);

  const sources = ['suraksha_engine'];
  if (osm.policeCount > 0 || osm.hospitalCount > 0) sources.push('openstreetmap');

  return {
    dimension: buildDimension('support', score, supportCount > 0 ? 76 : 52, sources),
    supportCount,
    sparsePublicSupport: supportCount < 2,
  };
}

function scoreTemporalDimension({ external, at }) {
  const sunset = external?.sunset || {};
  const hour = at.getHours();
  const isNight = typeof sunset.isDark === 'boolean' ? sunset.isDark : hour >= 20 || hour < 6;
  const isLateNight = hour >= 23 || hour < 5;
  const isWeekend = at.getDay() === 0 || at.getDay() === 6;

  let score = 78;
  if (isNight) score -= 18;
  if (isLateNight) score -= 10;
  if (isLateNight && isWeekend) score -= 6;
  if (!isNight) score += 6;

  const sources = sunset.source === 'sunset_api' ? ['sunset_api'] : ['heuristic_fallback'];
  return {
    dimension: buildDimension('temporal', score, sunset.source === 'sunset_api' ? 84 : 55, sources),
    isNight,
    isLateNight,
  };
}

function calibrateConfidence({ dimensions, accuracy, sourceCount }) {
  const avgDimConfidence =
    dimensions.reduce((sum, item) => sum + item.confidence, 0) / Math.max(dimensions.length, 1);
  const agreementSpread =
    Math.max(...dimensions.map((item) => item.score)) -
    Math.min(...dimensions.map((item) => item.score));
  let confidence = avgDimConfidence;
  confidence += Math.min(12, sourceCount * 2);
  confidence -= agreementSpread > 35 ? 8 : agreementSpread > 20 ? 4 : 0;
  if ((accuracy || 0) > 40) confidence -= 10;
  else confidence += 4;
  return clamp(Math.round(confidence), 18, 98);
}

function fuseSafetyIntelligence({
  lat,
  lng,
  at,
  accuracy,
  context,
  external,
  gridRisk,
  areaCrime,
  externalIncidents,
}) {
  const crimeResult = scoreCrimeDimension({
    lat,
    lng,
    context,
    externalIncidents,
    gridRisk,
    areaCrime,
  });
  const temporalResult = scoreTemporalDimension({ external, at });
  const supportResult = scoreSupportDimension({ context, external });
  const infrastructure = scoreInfrastructureDimension({
    external,
    isNight: temporalResult.isNight,
  });
  const visibility = scoreVisibility({ crowd: external?.crowd, osm: external?.osm });

  const dimensions = [
    crimeResult.dimension,
    infrastructure,
    supportResult.dimension,
    visibility,
    temporalResult.dimension,
  ];

  const weights = fusionIntelligenceConfig.dimensionWeights;
  const safetyScore = clamp(
    Math.round(
      crimeResult.dimension.score * weights.crime +
        infrastructure.score * weights.infrastructure +
        supportResult.dimension.score * weights.support +
        visibility.score * weights.visibility +
        temporalResult.dimension.score * weights.temporal,
    ),
    0,
    100,
  );

  const sourceCount =
    dimensions.reduce((sum, item) => sum + (item.sources?.length || 0), 0) +
    (gridRisk?.count90d > 0 ? 1 : 0);
  const aiConfidence = calibrateConfidence({ dimensions, accuracy, sourceCount });

  const safeZones = (context.safetyZones || []).filter((item) => item.kind === 'safe');
  const positiveFactors = [];
  const cautionFactors = [];

  if (crimeResult.recentIncidentCount > 0) {
    cautionFactors.push(
      `Recent verified incidents recorded within ${toDisplayDistance(1200)}.`,
    );
  }
  if (crimeResult.proximityPressure >= 1.2) {
    cautionFactors.push('Incident activity remains elevated in the surrounding area.');
  }
  if (gridRisk?.elevationFactor >= 0.45) {
    cautionFactors.push(
      `Grid model flags elevated risk for this ${gridRisk.count30d}-incident cell (30d).`,
    );
  }
  if (temporalResult.isNight) {
    cautionFactors.push(
      temporalResult.isLateNight
        ? 'Late-night conditions reduce visibility and public activity.'
        : 'Reduced visibility after sunset can affect situational awareness.',
    );
  }
  if (supportResult.sparsePublicSupport) {
    cautionFactors.push('Limited nearby emergency support points may slow rapid assistance.');
  }
  if (infrastructure.score < 50 && temporalResult.isNight) {
    cautionFactors.push('Mapped street lighting is sparse near this location.');
  }
  if (visibility.score < 45) {
    cautionFactors.push('Crowd and POI visibility signals are low nearby.');
  }
  if ((accuracy || 0) > 40) {
    cautionFactors.push('Live location precision is limited; assessment may update as GPS improves.');
  }
  if (supportResult.supportCount > 0) {
    positiveFactors.push('Emergency support infrastructure is mapped nearby.');
  }
  if (safeZones.length > 0) {
    positiveFactors.push('Community-identified safer movement patterns are available nearby.');
  }
  if (!temporalResult.isNight && visibility.score >= 65) {
    positiveFactors.push('Daytime visibility and activity signals are favorable.');
  }

  const riskLevel = dimensionLabel(safetyScore);
  const riskColors = {
    'Very Safe': '#14532D',
    Safe: '#16A34A',
    Moderate: '#EAB308',
    'High Risk': '#F97316',
    Critical: '#991B1B',
  };

  const nearbyResources = buildFusionNearbyResources(lat, lng, context.authorities, external);

  return {
    safetyScore,
    riskLevel: { label: riskLevel, colorHex: riskColors[riskLevel] || '#EAB308' },
    aiConfidence,
    dimensions,
    gridRisk,
    contributingFactors: [...cautionFactors, ...positiveFactors].slice(0, 6),
    recommendations: buildRecommendations({
      isNight: temporalResult.isNight,
      sparsePublicSupport: supportResult.sparsePublicSupport,
      recentIncidentCount: crimeResult.recentIncidentCount,
      safetyScore,
      safeZones,
    }),
    nearbyResources,
    signalSnapshot: {
      recentIncidentCount: crimeResult.recentIncidentCount,
      supportCount: supportResult.supportCount,
      safeZoneCount: safeZones.length,
      sparsePublicSupport: supportResult.sparsePublicSupport,
      incidentScoreRaw: crimeResult.proximityPressure,
      positiveFactors,
      cautionFactors,
    },
    fusionMeta: {
      modelVersion: fusionIntelligenceConfig.modelVersion,
      sourceCount,
      districtContext: areaCrime
        ? {
            periodLabel: areaCrime.periodLabel,
            ratePer100k: areaCrime.ratePer100k,
            disclaimer: areaCrime.disclaimer,
          }
        : null,
    },
  };
}

function buildRecommendations({ isNight, sparsePublicSupport, recentIncidentCount, safetyScore, safeZones }) {
  const recommendations = [];
  if (isNight) recommendations.push('Stay on well-lit main roads and avoid isolated shortcuts.');
  if (recentIncidentCount > 0) {
    recommendations.push('Remain alert and share your live location if you continue through this area.');
  }
  if (sparsePublicSupport) {
    recommendations.push('Prefer routes with nearby police, hospital, or active public access points.');
  }
  if (safeZones.length > 0) {
    recommendations.push('Use the suggested safer route that stays closer to community-supported corridors.');
  }
  if (safetyScore < 45) {
    recommendations.push('Keep SOS ready and inform an emergency contact before moving further.');
  } else {
    recommendations.push('Keep emergency contacts informed and stay aware of your surroundings.');
  }
  recommendations.push('Avoid accepting rides, food, or drinks from unknown persons.');
  return [...new Set(recommendations)].slice(0, 5);
}

module.exports = {
  fuseSafetyIntelligence,
  incidentWeight,
  buildRecommendations,
};
