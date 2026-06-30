const mongoose = require('mongoose');
const Authority = require('../models/Authority');
const IncidentReport = require('../models/IncidentReport');
const SafetyZone = require('../models/SafetyZone');
const { safetyIntelligenceConfig } = require('../config/safetyIntelligenceConfig');
const { nashikSafetyConfig } = require('../config/nashikSafetyConfig');
const { fusionIntelligenceConfig } = require('../config/fusionIntelligenceConfig');
const { loadExternalSignals } = require('./safetyContextLoader');
const { buildCommunityAlerts } = require('./safetyAlertBuilder');
const { getOsmSyncStatus } = require('./osmIngestionService');
const { getCrowdStats } = require('./crowdHeatmapService');
const { getCrimeSyncStatus } = require('./crimeDataIngestionService');
const { generateSafetySummary } = require('./safetySummaryService');
const { fuseSafetyIntelligence, incidentWeight } = require('./fusionEngineService');
const { get, set, buildFusionCacheKey, stats: cacheStats } = require('./fusionCacheService');
const { scoreRouteCandidate, loadOsmForRoutes } = require('./routeFusionService');
const {
  clamp,
  haversineMeters,
  toDisplayDistance,
  directionPoint,
  interpolatePoint,
} = require('../utils/safetyGeoUtils');

const VERIFIED_INCIDENT_STATUSES = ['reported', 'under_review', 'resolved'];

const RISK_LEVELS = [
  { min: 81, label: 'Very Safe', colorHex: '#14532D' },
  { min: 61, label: 'Safe', colorHex: '#16A34A' },
  { min: 41, label: 'Moderate Risk', colorHex: '#EAB308' },
  { min: 21, label: 'High Risk', colorHex: '#F97316' },
  { min: 0, label: 'Critical Risk', colorHex: '#991B1B' },
];

function mapRiskLevel(score) {
  return RISK_LEVELS.find((entry) => score >= entry.min) || RISK_LEVELS[RISK_LEVELS.length - 1];
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

async function runFusionAnalysis({ lat, lng, at, accuracy, context, useCache = true }) {
  const cacheKey = buildFusionCacheKey(lat, lng, at);
  if (useCache) {
    const cached = get(cacheKey);
    if (cached) {
      return {
        ...cached,
        fusionMeta: { ...(cached.fusionMeta || {}), cacheHit: true },
      };
    }
  }

  const external = await loadExternalSignals(lat, lng, at);
  const analysis = fuseSafetyIntelligence({
    lat,
    lng,
    at,
    accuracy,
    context,
    external,
    gridRisk: external.gridRisk,
    areaCrime: external.areaCrime,
    externalIncidents: external.externalIncidents,
  });

  const payload = {
    ...analysis,
    external,
    fusionMeta: { ...(analysis.fusionMeta || {}), cacheHit: false },
  };
  if (useCache) set(cacheKey, payload);
  return payload;
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
          return (
            sum -
            clamp(((1200 - distance) / 1200) * 10 * incidentWeight({
              ...incident,
              source: 'suraksha_reports',
              occurredAt: incident.createdAt,
            }), 0, 10)
          );
        }, 0) +
        context.authorities.reduce((sum, authority) => {
          const [authorityLng, authorityLat] = authority.location?.coordinates || [];
          const distance = haversineMeters(tile.lat, tile.lng, authorityLat, authorityLng);
          if (distance > 1200) return sum;
          return sum + clamp(((1200 - distance) / 1200) * 5, 0, 5);
        }, 0);

      const gridAdj = baseAnalysis.gridRisk
        ? (baseAnalysis.gridRisk.score - 70) * 0.15
        : 0;
      const tileScore = clamp(Math.round(baseAnalysis.safetyScore + adjustment + gridAdj), 0, 100);
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

async function buildUpcomingRisk({
  lat,
  lng,
  heading,
  destination,
  baseAnalysis,
  context,
  at,
  accuracy,
}) {
  const lookaheadMeters = safetyIntelligenceConfig.upcomingRisk.lookaheadMeters;
  let point = null;
  if (destination && typeof destination.lat === 'number' && typeof destination.lng === 'number') {
    point = interpolatePoint({ lat, lng }, destination, lookaheadMeters);
  } else if (typeof heading === 'number') {
    point = directionPoint({ lat, lng, heading, distanceMeters: lookaheadMeters });
  }
  if (!point) return null;

  const futureAnalysis = await runFusionAnalysis({
    lat: point.lat,
    lng: point.lng,
    at,
    accuracy,
    context,
    useCache: true,
  });

  if (
    futureAnalysis.safetyScore >= baseAnalysis.safetyScore ||
    baseAnalysis.safetyScore - futureAnalysis.safetyScore <
      safetyIntelligenceConfig.upcomingRisk.minIncreaseForAlert
  ) {
    return null;
  }

  return {
    distanceMeters: lookaheadMeters,
    safetyScore: futureAnalysis.safetyScore,
    riskLevel: futureAnalysis.riskLevel.label,
    reasons: futureAnalysis.contributingFactors.slice(0, 4),
    summary: `Elevated safety risk detected about ${toDisplayDistance(lookaheadMeters)} ahead.`,
    recommendedAction: 'Remain alert or switch to the suggested safer route.',
  };
}

async function getLiveSafetyAssessment({
  lat,
  lng,
  heading,
  accuracy,
  destination,
  includeSummary = false,
  lang = 'en',
  journeyMode = false,
}) {
  const at = new Date();
  const context = await loadContext(lat, lng);
  const analysis = await runFusionAnalysis({
    lat,
    lng,
    at,
    accuracy,
    context,
    useCache: !journeyMode,
  });
  const external = analysis.external || (await loadExternalSignals(lat, lng, at));
  const upcomingRisk = await buildUpcomingRisk({
    lat,
    lng,
    heading,
    destination,
    baseAnalysis: analysis,
    context,
    at,
    accuracy,
  });

  let aiSummary = null;
  if (includeSummary) {
    aiSummary = await generateSafetySummary({ analysis, external, at, lang });
  }

  const [osmSync, crowdStats, crimeSync] = await Promise.all([
    getOsmSyncStatus(),
    getCrowdStats(),
    getCrimeSyncStatus(),
  ]);

  const narrativeSummary = aiSummary?.summary ||
    (analysis.safetyScore < 45
      ? 'Conditions currently suggest elevated caution.'
      : analysis.safetyScore < 70
      ? 'Conditions are mixed, so staying alert is recommended.'
      : 'Current conditions are comparatively steadier right now.');

  return {
    current: {
      safetyScore: analysis.safetyScore,
      riskLevel: analysis.riskLevel.label,
      riskColorHex: analysis.riskLevel.colorHex,
      aiConfidenceVisible:
        analysis.aiConfidence >= safetyIntelligenceConfig.aiConfidenceDisplayThreshold,
      aiConfidence:
        analysis.aiConfidence >= safetyIntelligenceConfig.aiConfidenceDisplayThreshold
          ? analysis.aiConfidence
          : null,
      limitedAssessmentMessage:
        analysis.aiConfidence >= safetyIntelligenceConfig.aiConfidenceDisplayThreshold
          ? null
          : 'We currently have limited verified information for this area. Please stay alert and follow general safety precautions.',
      contributingFactors: analysis.contributingFactors,
      recommendations: analysis.recommendations,
      dimensions: analysis.dimensions,
      gridRisk: analysis.gridRisk,
      summary: narrativeSummary,
      aiSummary,
      updatedAt: at.toISOString(),
    },
    upcomingRisk,
    communityAlerts: buildCommunityAlerts({
      analysis,
      context,
      lat,
      lng,
      at,
      upcomingRisk,
      external,
    }),
    nearbyResources: analysis.nearbyResources,
    heatmapTiles: buildHeatmap({ lat, lng, baseAnalysis: analysis, context, at }),
    meta: {
      region: nashikSafetyConfig.regionLabel,
      regionId: nashikSafetyConfig.regionId,
      inRegion: external.inRegion,
      dataDisclaimer: nashikSafetyConfig.dataDisclaimer,
      nearbyPoliceCount: analysis.nearbyResources.filter((item) => item.type === 'police').length,
      nearbyHospitalCount: analysis.nearbyResources.filter((item) => item.type === 'hospital')
        .length,
      nearbySupportCount: analysis.signalSnapshot?.supportCount ?? 0,
      fusion: {
        modelVersion: fusionIntelligenceConfig.modelVersion,
        cacheHit: analysis.fusionMeta?.cacheHit ?? false,
        sourceCount: analysis.fusionMeta?.sourceCount ?? 0,
        districtContext: analysis.fusionMeta?.districtContext ?? null,
      },
      journey: {
        recommendedPollSeconds: journeyMode
          ? nashikSafetyConfig.journeyPollSeconds
          : 120,
      },
      sourceHealth: {
        openstreetmap: osmSync,
        crowd_aggregate: {
          status: 'ok',
          activeCells: crowdStats.activeCells,
          totalPings2h: crowdStats.totalPings2h,
          lastPingAt: crowdStats.lastPingAt,
        },
        sunset_api: {
          status: external.sunset?.source === 'sunset_api' ? 'ok' : 'fallback',
          isDark: external.sunset?.isDark ?? null,
        },
        crime_open_data: crimeSync,
        news_feeds: external.newsSync || { status: 'pending', enabled: false },
        fusion_cache: cacheStats(),
      },
    },
  };
}

async function getSafetyIntelligenceHealth() {
  const [osmSync, crowdStats, crimeSync] = await Promise.all([
    getOsmSyncStatus(),
    getCrowdStats(),
    getCrimeSyncStatus(),
  ]);
  return {
    region: nashikSafetyConfig.regionLabel,
    regionId: nashikSafetyConfig.regionId,
    dataDisclaimer: nashikSafetyConfig.dataDisclaimer,
    bbox: nashikSafetyConfig.bbox,
    fusion: {
      modelVersion: fusionIntelligenceConfig.modelVersion,
      dimensionWeights: fusionIntelligenceConfig.dimensionWeights,
      cache: cacheStats(),
    },
    sources: {
      openstreetmap: osmSync,
      crowd_aggregate: {
        status: 'ok',
        activeCells: crowdStats.activeCells,
        totalPings2h: crowdStats.totalPings2h,
        lastPingAt: crowdStats.lastPingAt,
      },
      sunset_api: { status: 'ok', provider: 'sunrise-sunset.org' },
      suraksha_reports: { status: 'ok', message: 'Verified incident reports from app users' },
      crime_open_data: crimeSync,
      news_feeds: { status: 'pending', enabled: false },
      gemini_summary: { status: process.env.GEMINI_API_KEY ? 'ok' : 'fallback_template' },
    },
    updatedAt: new Date().toISOString(),
  };
}

async function assessRouteOptions({ origin, destination, candidates }) {
  const at = new Date();
  const context = await loadContext(origin.lat, origin.lng);
  const external = await loadExternalSignals(origin.lat, origin.lng, at);
  const osmFeatures = await loadOsmForRoutes(candidates || []);

  const scoredRoutes = await Promise.all(
    (candidates || []).map((route) =>
      scoreRouteCandidate(route, context, at, external, osmFeatures),
    ),
  );
  const filtered = scoredRoutes.filter(Boolean);

  filtered.sort((left, right) => {
    if (right.averageSafetyScore !== left.averageSafetyScore) {
      return right.averageSafetyScore - left.averageSafetyScore;
    }
    return left.travelTimeMinutes - right.travelTimeMinutes;
  });

  const recommendedRoute = filtered[0] || null;
  if (recommendedRoute) recommendedRoute.recommended = true;

  return {
    destination,
    routes: filtered,
    recommendedRouteId: recommendedRoute?.id || null,
    fusionModelVersion: fusionIntelligenceConfig.modelVersion,
    updatedAt: at.toISOString(),
  };
}

module.exports = {
  getLiveSafetyAssessment,
  assessRouteOptions,
  getSafetyIntelligenceHealth,
  runFusionAnalysis,
  loadContext,
  buildUpcomingRisk,
};
