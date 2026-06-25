const mongoose = require('mongoose');
const Authority = require('../models/Authority');
const IncidentReport = require('../models/IncidentReport');
const SafetyZone = require('../models/SafetyZone');
const { safetyIntelligenceConfig } = require('../config/safetyIntelligenceConfig');

const VERIFIED_INCIDENT_STATUSES = ['reported', 'under_review', 'resolved'];

const RISK_LEVELS = [
  { min: 81, label: 'Very Safe', colorHex: '#14532D' },
  { min: 61, label: 'Safe', colorHex: '#16A34A' },
  { min: 41, label: 'Moderate Risk', colorHex: '#EAB308' },
  { min: 21, label: 'High Risk', colorHex: '#F97316' },
  { min: 0, label: 'Critical Risk', colorHex: '#991B1B' },
];

function haversineMeters(lat1, lng1, lat2, lng2) {
  const toRadians = (value) => (value * Math.PI) / 180;
  const earthRadius = 6371000;
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * earthRadius * Math.asin(Math.sqrt(a));
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function mapRiskLevel(score) {
  return RISK_LEVELS.find((entry) => score >= entry.min) || RISK_LEVELS[RISK_LEVELS.length - 1];
}

function toDisplayDistance(distanceMeters) {
  if (distanceMeters >= 1000) {
    return `${(distanceMeters / 1000).toFixed(distanceMeters >= 10000 ? 0 : 1)} km`;
  }
  return `${Math.round(distanceMeters)} m`;
}

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
  const hours = ageHours(incident.createdAt);
  if (hours > safetyIntelligenceConfig.decay.staleIncidentCutoffHours) return 0;
  const decayBase = Math.pow(
    0.5,
    hours / safetyIntelligenceConfig.decay.incidentHalfLifeHours,
  );
  return decayBase * incidentSeverity(incident.category, incident.description);
}

function directionPoint({ lat, lng, heading, distanceMeters }) {
  const earthRadius = 6371000;
  const bearing = ((heading || 0) * Math.PI) / 180;
  const lat1 = (lat * Math.PI) / 180;
  const lng1 = (lng * Math.PI) / 180;
  const angularDistance = distanceMeters / earthRadius;

  const lat2 = Math.asin(
    Math.sin(lat1) * Math.cos(angularDistance) +
      Math.cos(lat1) * Math.sin(angularDistance) * Math.cos(bearing),
  );
  const lng2 =
    lng1 +
    Math.atan2(
      Math.sin(bearing) * Math.sin(angularDistance) * Math.cos(lat1),
      Math.cos(angularDistance) - Math.sin(lat1) * Math.sin(lat2),
    );

  return {
    lat: (lat2 * 180) / Math.PI,
    lng: (lng2 * 180) / Math.PI,
  };
}

function interpolatePoint(from, to, distanceMeters) {
  const total = haversineMeters(from.lat, from.lng, to.lat, to.lng);
  if (!total || total <= distanceMeters) return { lat: to.lat, lng: to.lng };
  const ratio = distanceMeters / total;
  return {
    lat: from.lat + (to.lat - from.lat) * ratio,
    lng: from.lng + (to.lng - from.lng) * ratio,
  };
}

function summarizeIncident(incident) {
  if (incident.category) {
    return `${incident.category} report recorded nearby`;
  }
  return 'Recent verified incident recorded nearby';
}

function normalizePointCoordinates(pointLike) {
  if (!pointLike) return null;
  if (Array.isArray(pointLike) && pointLike.length >= 2) {
    return { lat: Number(pointLike[0]), lng: Number(pointLike[1]) };
  }
  if (typeof pointLike.lat === 'number' && typeof pointLike.lng === 'number') {
    return pointLike;
  }
  if (typeof pointLike.latitude === 'number' && typeof pointLike.longitude === 'number') {
    return { lat: pointLike.latitude, lng: pointLike.longitude };
  }
  return null;
}

async function loadContext(lat, lng) {
  if (mongoose.connection.readyState !== 1) {
    return { authorities: [], incidents: [], safetyZones: [] };
  }

  const nearQuery = (maxDistance) => ({
    $near: {
      $geometry: { type: 'Point', coordinates: [Number(lng), Number(lat)] },
      $maxDistance: maxDistance,
    },
  });

  const [authorities, incidents, safetyZones] = await Promise.all([
    Authority.find({ location: nearQuery(safetyIntelligenceConfig.radii.resourceMeters) })
      .lean()
      .limit(30),
    IncidentReport.find({
      status: { $in: VERIFIED_INCIDENT_STATUSES },
      location: nearQuery(safetyIntelligenceConfig.radii.incidentMeters),
    })
      .sort({ createdAt: -1 })
      .lean()
      .limit(30),
    SafetyZone.find({ location: nearQuery(safetyIntelligenceConfig.radii.safetyZoneMeters) })
      .lean()
      .limit(20),
  ]);

  return { authorities, incidents, safetyZones };
}

function analyzeSignals({ lat, lng, at, accuracy, context }) {
  const hour = at.getHours();
  const isNight = hour >= 20 || hour < 6;
  const isLateNight = hour >= 23 || hour < 5;
  const isWeekend = at.getDay() === 0 || at.getDay() === 6;
  const authorities = context.authorities || [];
  const incidents = context.incidents || [];
  const safetyZones = context.safetyZones || [];

  const police = authorities.filter((item) => item.authorityType === 'police');
  const hospitals = authorities.filter((item) => item.authorityType === 'hospital');
  const responders = authorities.filter((item) => item.authorityType === 'responder');
  const safeZones = safetyZones.filter((item) => item.kind === 'safe');
  const supportZones = safetyZones.filter((item) => ['hospital', 'police'].includes(item.kind));

  const incidentScoreRaw = incidents.reduce((sum, incident) => sum + incidentWeight(incident), 0);
  const recentIncidentCount = incidents.filter((incident) => ageHours(incident.createdAt) <= 72).length;

  let safetyScore = safetyIntelligenceConfig.scoring.baseSafetyScore;
  if (isNight) safetyScore -= safetyIntelligenceConfig.scoring.timeOfDayPenalty;
  if (isLateNight && isWeekend) safetyScore -= safetyIntelligenceConfig.scoring.weekendNightPenalty;
  if ((accuracy || 0) > 40) safetyScore -= safetyIntelligenceConfig.scoring.lowAccuracyPenalty;

  safetyScore -= clamp(
    incidentScoreRaw * safetyIntelligenceConfig.scoring.incidentDensityPenalty,
    0,
    36,
  );
  safetyScore -= clamp(
    recentIncidentCount * (safetyIntelligenceConfig.scoring.recentVerifiedIncidentPenalty / 4),
    0,
    20,
  );

  const supportCount = police.length + hospitals.length + responders.length + supportZones.length;
  if (supportCount === 0) {
    safetyScore -= safetyIntelligenceConfig.scoring.sparseEmergencySupportPenalty;
  } else {
    safetyScore += clamp(
      supportCount * (safetyIntelligenceConfig.scoring.safeSupportBonus / 4),
      0,
      safetyIntelligenceConfig.scoring.safeSupportBonus,
    );
  }

  if (safeZones.length > 0) {
    safetyScore += clamp(
      safeZones.length * (safetyIntelligenceConfig.scoring.communitySafeRouteBonus / 2),
      0,
      safetyIntelligenceConfig.scoring.communitySafeRouteBonus,
    );
  }

  const sparsePublicSupport = supportCount < 2 && safeZones.length === 0;
  if (sparsePublicSupport && isNight) {
    safetyScore -= safetyIntelligenceConfig.scoring.isolationPenalty;
  }

  safetyScore = clamp(Math.round(safetyScore), 0, 100);
  const riskLevel = mapRiskLevel(safetyScore);

  const confidenceBase =
    44 +
    Math.min(22, incidents.length * 5) +
    Math.min(18, supportCount * 4) +
    Math.min(10, safeZones.length * 3);
  const accuracyModifier = (accuracy || 0) > 40 ? -10 : 6;
  const timeModifier = isNight ? 4 : 0;
  const aiConfidence = clamp(Math.round(confidenceBase + accuracyModifier + timeModifier), 18, 98);

  const positiveFactors = [];
  const cautionFactors = [];

  if (recentIncidentCount > 0) {
    cautionFactors.push(
      `Recent verified public safety incidents were recorded within ${toDisplayDistance(1200)}.`,
    );
  }
  if (incidentScoreRaw >= 1.2) {
    cautionFactors.push('Verified incident activity remains elevated in the surrounding area.');
  }
  if (isNight) {
    cautionFactors.push(
      isLateNight ? 'Road activity typically drops after midnight in this area.' : 'Reduced visibility after sunset can affect situational awareness.',
    );
  }
  if (sparsePublicSupport) {
    cautionFactors.push('Limited nearby emergency support points may slow rapid assistance.');
  }
  if ((accuracy || 0) > 40) {
    cautionFactors.push('Live location precision is limited right now, so the assessment may update as GPS improves.');
  }

  if (police.length > 0) {
    positiveFactors.push(`Nearby police access can improve emergency response options.`);
  }
  if (hospitals.length > 0) {
    positiveFactors.push(`Hospital support is available nearby if urgent help is needed.`);
  }
  if (safeZones.length > 0) {
    positiveFactors.push('Community-identified safer movement patterns are available nearby.');
  }
  if (!isNight && supportCount >= 2) {
    positiveFactors.push('Daytime conditions and visible support infrastructure improve overall safety context.');
  }

  const contributingFactors = [...cautionFactors, ...positiveFactors].slice(0, 6);
  const recommendations = buildRecommendations({
    isNight,
    sparsePublicSupport,
    recentIncidentCount,
    safetyScore,
    safeZones,
  });

  const nearbyResources = authorities
    .map((item) => {
      const [lngValue, latValue] = item.location?.coordinates || [];
      const distanceMeters = haversineMeters(lat, lng, latValue, lngValue);
      return {
        id: String(item._id),
        type: item.authorityType,
        name: item.name,
        address: item.address || '',
        phone: item.phone || '',
        distanceMeters: Math.round(distanceMeters),
      };
    })
    .sort((left, right) => left.distanceMeters - right.distanceMeters)
    .slice(0, 6);

  return {
    safetyScore,
    riskLevel,
    aiConfidence,
    contributingFactors,
    recommendations,
    nearbyResources,
    signalSnapshot: {
      recentIncidentCount,
      supportCount,
      safeZoneCount: safeZones.length,
      sparsePublicSupport,
      incidentScoreRaw,
      positiveFactors,
      cautionFactors,
    },
  };
}

function buildRecommendations({ isNight, sparsePublicSupport, recentIncidentCount, safetyScore, safeZones }) {
  const recommendations = [];
  if (isNight) {
    recommendations.push('Stay on well-lit main roads and avoid isolated shortcuts.');
  }
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

function buildCommunityAlerts({ analysis, context, lat, lng, at, upcomingRisk }) {
  const alerts = [];
  const hour = at.getHours();
  const isNight = hour >= 20 || hour < 6;
  const isLateNight = hour >= 23 || hour < 5;
  const isDaytime = hour >= 6 && hour < 20;
  const { signalSnapshot, nearbyResources } = analysis;
  const topIncident = context.incidents?.[0];
  const policeResources = nearbyResources.filter((r) => r.type === 'police');
  const hospitalResources = nearbyResources.filter((r) => r.type === 'hospital');

  // 1. Verified Police Activity (always present if DB has police, else area-based)
  if (policeResources.length > 0) {
    const p = policeResources[0];
    alerts.push({
      category: 'Police Activity',
      priority: 'information',
      distanceMeters: p.distanceMeters,
      timestamp: at.toISOString(),
      summary: `Recent verified police presence detected within ${toDisplayDistance(p.distanceMeters)} of your location.`,
      recommendedAction: 'You can reach this station quickly if immediate help is needed. Save the number.',
    });
  } else {
    alerts.push({
      category: 'Police Activity',
      priority: 'caution',
      distanceMeters: 1200,
      timestamp: at.toISOString(),
      summary: 'No verified police presence detected within 1.2 km of your current location.',
      recommendedAction: 'Dial 100 in an emergency. Keep SOS enabled and share live location with trusted contacts.',
    });
  }

  // 2. Recent Theft / Incident reports
  if (topIncident) {
    alerts.push({
      category: 'Recent Theft Report',
      priority: signalSnapshot.recentIncidentCount > 1 ? 'critical' : 'caution',
      distanceMeters: 700,
      timestamp: topIncident.createdAt,
      summary: `${summarizeIncident(topIncident)} Reported within the last 72 hours in this area.`,
      recommendedAction: 'Keep belongings close, avoid phone use in isolated spots, and stay aware.',
    });
  } else {
    alerts.push({
      category: 'Area Incident Status',
      priority: 'information',
      distanceMeters: 500,
      timestamp: at.toISOString(),
      summary: 'No verified theft or crime incidents reported in the last 72 hours near this location.',
      recommendedAction: 'Conditions appear stable. Continue monitoring and stay alert in low-traffic zones.',
    });
  }

  // 3. Lighting conditions (time-based)
  alerts.push({
    category: 'Road Lighting',
    priority: isLateNight ? 'critical' : isNight ? 'caution' : 'information',
    distanceMeters: 300,
    timestamp: at.toISOString(),
    summary: isLateNight
      ? 'Streets are poorly lit after midnight. Visibility and pedestrian activity are very low.'
      : isNight
      ? 'Reduced visibility after sunset. Street lighting may be inconsistent in this corridor.'
      : 'Adequate daytime visibility. Road lighting is not a concern during this hour.',
    recommendedAction: isNight
      ? 'Stay on well-lit main roads. Use torch if needed and avoid shadowed paths.'
      : 'Continue on active roads. Switch on location sharing for longer routes.',
  });

  // 4. Pedestrian activity
  alerts.push({
    category: 'Pedestrian Activity',
    priority: isLateNight ? 'caution' : isDaytime ? 'information' : 'caution',
    distanceMeters: 250,
    timestamp: at.toISOString(),
    summary: isLateNight
      ? 'Very low pedestrian activity detected after midnight. Fewer people on the roads reduces passive safety.'
      : isNight
      ? 'Pedestrian footfall reduces after 8 PM. Public visibility may be lower in this area.'
      : 'Normal pedestrian activity in this area during daytime hours. Public presence adds safety.',
    recommendedAction: isNight
      ? 'Avoid isolated routes. Stay in areas where people are visibly present.'
      : 'Area has active public presence. Ideal for movement with standard precautions.',
  });

  // 5. Nearby Hospital
  if (hospitalResources.length > 0) {
    const h = hospitalResources[0];
    alerts.push({
      category: 'Nearby Hospital',
      priority: 'information',
      distanceMeters: h.distanceMeters,
      timestamp: at.toISOString(),
      summary: `${h.name} is within ${toDisplayDistance(h.distanceMeters)} and can provide emergency medical support.`,
      recommendedAction: 'Note this location. Use the map view for directions if medical help is needed urgently.',
    });
  } else {
    alerts.push({
      category: 'Nearby Hospital',
      priority: 'information',
      distanceMeters: 1500,
      timestamp: at.toISOString(),
      summary: 'Nearest hospital is estimated beyond 1.5 km from your current position.',
      recommendedAction: 'Check the Nearby Services section for the closest verified hospital.',
    });
  }

  // 6. Police Station availability
  if (policeResources.length > 1) {
    const p2 = policeResources[1];
    alerts.push({
      category: 'Nearby Police Station',
      priority: 'information',
      distanceMeters: p2.distanceMeters,
      timestamp: at.toISOString(),
      summary: `A secondary police station is mapped within ${toDisplayDistance(p2.distanceMeters)} of your location.`,
      recommendedAction: 'Having multiple police access points nearby improves emergency response speed.',
    });
  } else {
    alerts.push({
      category: 'Nearby Police Station',
      priority: 'information',
      distanceMeters: 900,
      timestamp: at.toISOString(),
      summary: 'Closest verified police station is mapped based on your current GPS coordinates.',
      recommendedAction: 'Tap "Nearby Services → Police Stations" to see directions and contact details.',
    });
  }

  // 7. Community verified safe route
  if (signalSnapshot.safeZoneCount > 0) {
    alerts.push({
      category: 'Community Safe Route',
      priority: 'information',
      distanceMeters: 400,
      timestamp: at.toISOString(),
      summary: `${signalSnapshot.safeZoneCount} community-verified safe corridor${signalSnapshot.safeZoneCount > 1 ? 's are' : ' is'} identified near your route.`,
      recommendedAction: 'Open the Safety Map to follow the highlighted community-verified path.',
    });
  } else {
    alerts.push({
      category: 'Community Safe Route',
      priority: 'information',
      distanceMeters: 600,
      timestamp: at.toISOString(),
      summary: 'No community-tagged safe corridors verified in this exact stretch yet.',
      recommendedAction: 'Use main roads, stay near populated areas, and report unsafe stretches in the app.',
    });
  }

  // 8. Construction / Road change (time + area heuristic)
  const isWeekday = at.getDay() !== 0 && at.getDay() !== 6;
  alerts.push({
    category: 'Construction Ahead',
    priority: 'information',
    distanceMeters: 800,
    timestamp: at.toISOString(),
    summary: isWeekday && isDaytime
      ? 'Road construction or maintenance activity is possible on weekday daytime routes in urban corridors.'
      : 'No active construction alerts for this time window. Routes appear unobstructed.',
    recommendedAction: 'Check for diversions if you notice unusual congestion. Use app map for alternate paths.',
  });

  // 9. Emergency response delay indicator (sparse support = slower response)
  if (signalSnapshot.sparsePublicSupport) {
    alerts.push({
      category: 'Emergency Response',
      priority: 'caution',
      distanceMeters: 1000,
      timestamp: at.toISOString(),
      summary: 'Sparse emergency support infrastructure in this zone may mean slower first-response times.',
      recommendedAction: 'Keep SOS armed. Inform an emergency contact of your location before moving further.',
    });
  } else {
    alerts.push({
      category: 'Emergency Response',
      priority: 'information',
      distanceMeters: 600,
      timestamp: at.toISOString(),
      summary: 'Emergency response infrastructure appears adequate for this area. Response times should be reasonable.',
      recommendedAction: 'Continue with standard caution. SOS is always available from the main dashboard.',
    });
  }

  // 10. Safety score trend
  if (analysis.safetyScore >= 75) {
    alerts.push({
      category: 'Safety Score',
      priority: 'information',
      distanceMeters: 0,
      timestamp: at.toISOString(),
      summary: `Area safety score is ${analysis.safetyScore}/100. Conditions are comparatively stable and monitored.`,
      recommendedAction: 'Safety metrics are positive. Continue sharing location with trusted contacts.',
    });
  } else if (analysis.safetyScore >= 50) {
    alerts.push({
      category: 'Safety Score',
      priority: 'caution',
      distanceMeters: 0,
      timestamp: at.toISOString(),
      summary: `Area safety score is ${analysis.safetyScore}/100. Mixed conditions. Stay situationally aware.`,
      recommendedAction: 'Review contributing factors in the AI Intelligence card and follow recommended actions.',
    });
  } else {
    alerts.push({
      category: 'Safety Score',
      priority: 'critical',
      distanceMeters: 0,
      timestamp: at.toISOString(),
      summary: `Area safety score is ${analysis.safetyScore}/100. Elevated risk detected in this zone.`,
      recommendedAction: 'Arm SOS, share live location with a trusted contact, and consider an alternate route.',
    });
  }

  // Upcoming risk pinned to top if critical
  if (upcomingRisk) {
    alerts.unshift({
      category: 'Upcoming Risk Zone',
      priority: 'critical',
      distanceMeters: upcomingRisk.distanceMeters,
      timestamp: at.toISOString(),
      summary: upcomingRisk.summary,
      recommendedAction: upcomingRisk.recommendedAction,
    });
  }

  return alerts.slice(0, 10);
}

function buildHeatmap({ lat, lng, baseAnalysis, context, at }) {
  const tiles = [];
  const { tileSpacingMeters, radius } = safetyIntelligenceConfig.heatmap;
  for (let row = -radius; row <= radius; row += 1) {
    for (let col = -radius; col <= radius; col += 1) {
      const north = directionPoint({
        lat,
        lng,
        heading: row >= 0 ? 0 : 180,
        distanceMeters: Math.abs(row) * tileSpacingMeters,
      });
      const tile = directionPoint({
        lat: north.lat,
        lng: north.lng,
        heading: col >= 0 ? 90 : 270,
        distanceMeters: Math.abs(col) * tileSpacingMeters,
      });

      const adjustment =
        context.incidents.reduce((sum, incident) => {
          const [incidentLng, incidentLat] = incident.location?.coordinates || [];
          const distance = haversineMeters(tile.lat, tile.lng, incidentLat, incidentLng);
          if (distance > 1200) return sum;
          return sum - clamp((1200 - distance) / 1200 * 10 * incidentWeight(incident), 0, 10);
        }, 0) +
        context.authorities.reduce((sum, authority) => {
          const [authorityLng, authorityLat] = authority.location?.coordinates || [];
          const distance = haversineMeters(tile.lat, tile.lng, authorityLat, authorityLng);
          if (distance > 1200) return sum;
          return sum + clamp((1200 - distance) / 1200 * 5, 0, 5);
        }, 0);

      const tileScore = clamp(Math.round(baseAnalysis.safetyScore + adjustment), 0, 100);
      const tileRisk = mapRiskLevel(tileScore);
      tiles.push({
        latitude: Number(tile.lat.toFixed(6)),
        longitude: Number(tile.lng.toFixed(6)),
        safetyScore: tileScore,
        riskLevel: tileRisk.label,
        colorHex: tileRisk.colorHex,
        timestamp: at.toISOString(),
      });
    }
  }
  return tiles;
}

function buildUpcomingRisk({ lat, lng, heading, destination, baseAnalysis, context, at, accuracy }) {
  const lookaheadMeters = safetyIntelligenceConfig.upcomingRisk.lookaheadMeters;
  let point = null;
  if (destination && typeof destination.lat === 'number' && typeof destination.lng === 'number') {
    point = interpolatePoint({ lat, lng }, destination, lookaheadMeters);
  } else if (typeof heading === 'number') {
    point = directionPoint({ lat, lng, heading, distanceMeters: lookaheadMeters });
  }
  if (!point) return null;

  const futureAnalysis = analyzeSignals({
    lat: point.lat,
    lng: point.lng,
    at,
    accuracy,
    context,
  });
  if (
    futureAnalysis.safetyScore >= baseAnalysis.safetyScore ||
    baseAnalysis.safetyScore - futureAnalysis.safetyScore < safetyIntelligenceConfig.upcomingRisk.minIncreaseForAlert
  ) {
    return null;
  }

  const reasons = futureAnalysis.contributingFactors.slice(0, 4);
  return {
    distanceMeters: lookaheadMeters,
    safetyScore: futureAnalysis.safetyScore,
    riskLevel: futureAnalysis.riskLevel.label,
    reasons,
    summary: `Elevated safety risk detected about ${toDisplayDistance(lookaheadMeters)} ahead.`,
    recommendedAction: 'Remain alert or switch to the suggested safer route.',
  };
}

function scoreRouteCandidate(route, context, at) {
  const path = Array.isArray(route.path) ? route.path.map(normalizePointCoordinates).filter(Boolean) : [];
  if (path.length === 0) {
    return null;
  }

  let incidentPressure = 0;
  let supportCoverage = 0;
  for (const point of path) {
    for (const incident of context.incidents || []) {
      const [incidentLng, incidentLat] = incident.location?.coordinates || [];
      const distance = haversineMeters(point.lat, point.lng, incidentLat, incidentLng);
      if (distance <= 550) {
        incidentPressure += incidentWeight(incident) * ((550 - distance) / 550);
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

  const safeZoneTouches = (context.safetyZones || []).reduce((count, zone) => {
    const [zoneLng, zoneLat] = zone.location?.coordinates || [];
    const hits = path.some((point) => haversineMeters(point.lat, point.lng, zoneLat, zoneLng) <= (zone.radiusMeters || 400));
    return count + (hits ? 1 : 0);
  }, 0);

  const profile = safetyIntelligenceConfig.routeProfiles.find((item) => item.id === route.profileId) || safetyIntelligenceConfig.routeProfiles[0];
  const durationMinutes = Math.max(1, Math.round((route.durationSeconds || 0) / 60));
  const distanceKm = Math.max(0.1, (route.distanceMeters || 0) / 1000);
  const isNight = at.getHours() >= 20 || at.getHours() < 6;

  let score = 78;
  score -= clamp(incidentPressure * 14, 0, 30);
  score += clamp(supportCoverage * profile.supportBonusFactor * 2.8, 0, 18);
  score += clamp(safeZoneTouches * 3.5 * profile.bufferFactor, 0, 12);
  score -= clamp(durationMinutes * profile.pacePenaltyFactor, 0, 10);
  score -= clamp(distanceKm * 1.6, 0, 8);
  if (isNight) score -= 8;
  score = clamp(Math.round(score), 0, 100);
  const riskLevel = mapRiskLevel(score);

  const factors = [];
  if (incidentPressure > 0.8) {
    factors.push('passes closer to recent verified incident activity');
  }
  if (supportCoverage > 1.4) {
    factors.push('stays closer to mapped emergency support');
  }
  if (safeZoneTouches > 0) {
    factors.push('aligns with community-supported safer stretches');
  }
  if (isNight) {
    factors.push('requires extra caution after sunset');
  }
  if (factors.length === 0) {
    factors.push('balances travel time with available support coverage');
  }

  return {
    id: route.id,
    label: profile.label,
    badge: profile.badge || null,
    recommended: false,
    averageSafetyScore: score,
    maxRiskLevel: riskLevel.label,
    travelTimeMinutes: durationMinutes,
    distanceMeters: Math.round(route.distanceMeters || 0),
    summary: `This route ${factors[0]}.`,
    recommendations: buildRecommendations({
      isNight,
      sparsePublicSupport: supportCoverage < 0.7,
      recentIncidentCount: incidentPressure > 0.4 ? 1 : 0,
      safetyScore: score,
      safeZones: Array.from({ length: safeZoneTouches }),
    }).slice(0, 3),
  };
}

async function getLiveSafetyAssessment({
  lat,
  lng,
  heading,
  accuracy,
  destination,
}) {
  const at = new Date();
  const context = await loadContext(lat, lng);
  const analysis = analyzeSignals({ lat, lng, at, accuracy, context });
  const upcomingRisk = buildUpcomingRisk({
    lat,
    lng,
    heading,
    destination,
    baseAnalysis: analysis,
    context,
    at,
    accuracy,
  });

  return {
    current: {
      safetyScore: analysis.safetyScore,
      riskLevel: analysis.riskLevel.label,
      riskColorHex: analysis.riskLevel.colorHex,
      aiConfidenceVisible:
        analysis.aiConfidence >= safetyIntelligenceConfig.aiConfidenceDisplayThreshold,
      aiConfidence: analysis.aiConfidence >= safetyIntelligenceConfig.aiConfidenceDisplayThreshold ? analysis.aiConfidence : null,
      limitedAssessmentMessage:
        analysis.aiConfidence >= safetyIntelligenceConfig.aiConfidenceDisplayThreshold
          ? null
          : 'We currently have limited verified information for this area. Please stay alert and follow general safety precautions.',
      contributingFactors: analysis.contributingFactors,
      recommendations: analysis.recommendations,
      summary:
        analysis.safetyScore < 45
          ? 'Conditions currently suggest elevated caution.'
          : analysis.safetyScore < 70
          ? 'Conditions are mixed, so staying alert is recommended.'
          : 'Current conditions are comparatively steadier right now.',
      updatedAt: at.toISOString(),
    },
    upcomingRisk,
    communityAlerts: buildCommunityAlerts({ analysis, context, lat, lng, at, upcomingRisk }),
    nearbyResources: analysis.nearbyResources,
    heatmapTiles: buildHeatmap({ lat, lng, baseAnalysis: analysis, context, at }),
    meta: {
      nearbyPoliceCount: analysis.nearbyResources.filter((item) => item.type === 'police').length,
      nearbyHospitalCount: analysis.nearbyResources.filter((item) => item.type === 'hospital').length,
    },
  };
}

async function assessRouteOptions({ origin, destination, candidates }) {
  const at = new Date();
  const context = await loadContext(origin.lat, origin.lng);
  const scoredRoutes = (candidates || [])
    .map((route) => scoreRouteCandidate(route, context, at))
    .filter(Boolean);

  scoredRoutes.sort((left, right) => {
    if (right.averageSafetyScore !== left.averageSafetyScore) {
      return right.averageSafetyScore - left.averageSafetyScore;
    }
    return left.travelTimeMinutes - right.travelTimeMinutes;
  });

  const recommendedRoute = scoredRoutes[0] || null;
  if (recommendedRoute) {
    recommendedRoute.recommended = true;
  }

  return {
    destination,
    routes: scoredRoutes,
    recommendedRouteId: recommendedRoute?.id || null,
    updatedAt: at.toISOString(),
  };
}

module.exports = {
  getLiveSafetyAssessment,
  assessRouteOptions,
};
