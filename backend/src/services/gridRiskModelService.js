const mongoose = require('mongoose');
const ExternalIncident = require('../models/ExternalIncident');
const IncidentReport = require('../models/IncidentReport');
const { fusionIntelligenceConfig } = require('../config/fusionIntelligenceConfig');
const { nashikSafetyConfig } = require('../config/nashikSafetyConfig');
const { buildGridCellId, clamp } = require('../utils/safetyGeoUtils');

const VERIFIED_STATUSES = ['reported', 'under_review', 'resolved'];

function ageDays(date) {
  return Math.max(0, (Date.now() - new Date(date).getTime()) / (1000 * 60 * 60 * 24));
}

function decayWeight(days, halfLifeDays) {
  return Math.pow(0.5, days / halfLifeDays);
}

async function countIncidentsInCell(cellId, precision) {
  if (mongoose.connection.readyState !== 1) {
    return { count7d: 0, count30d: 0, count90d: 0, totalWeight30d: 0 };
  }

  const parts = cellId.split(':');
  const latKey = Number(parts[1]);
  const lngKey = Number(parts[2]);
  const factor = 10 ** precision;
  const centerLat = latKey / factor;
  const centerLng = lngKey / factor;
  const delta = 1 / factor;

  const south = centerLat - delta / 2;
  const north = centerLat + delta / 2;
  const west = centerLng - delta / 2;
  const east = centerLng + delta / 2;

  const since90 = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);

  const [external, appReports] = await Promise.all([
    ExternalIncident.find({
      region: nashikSafetyConfig.regionId,
      spatialPrecision: 'point',
      occurredAt: { $gte: since90 },
      location: {
        $geoWithin: {
          $box: [[west, south], [east, north]],
        },
      },
    }).lean(),
    IncidentReport.find({
      status: { $in: VERIFIED_STATUSES },
      createdAt: { $gte: since90 },
      location: {
        $geoWithin: {
          $box: [[west, south], [east, north]],
        },
      },
    }).lean(),
  ]);

  const all = [
    ...external.map((item) => ({ at: item.occurredAt, confidence: item.confidence || 0.7 })),
    ...appReports.map((item) => ({ at: item.createdAt, confidence: 0.95 })),
  ];

  let count7d = 0;
  let count30d = 0;
  let count90d = all.length;
  let totalWeight30d = 0;

  for (const item of all) {
    const days = ageDays(item.at);
    if (days <= 7) count7d += 1;
    if (days <= 30) {
      count30d += 1;
      totalWeight30d += decayWeight(days, 15) * item.confidence;
    }
  }

  return { count7d, count30d, count90d, totalWeight30d };
}

async function getGridRiskForPoint(lat, lng) {
  const precision = fusionIntelligenceConfig.gridPrecision;
  const cellId = buildGridCellId(lat, lng, precision);
  const counts = await countIncidentsInCell(cellId, precision);
  const baseline = fusionIntelligenceConfig.nashikBaselineIncidentsPerCell30d;
  const elevationRatio = baseline > 0 ? counts.totalWeight30d / baseline : counts.totalWeight30d;

  let elevationFactor = clamp(elevationRatio / 2.5, 0, 1);
  if (counts.count30d < fusionIntelligenceConfig.minIncidentsForGridElevation) {
    elevationFactor *= counts.count30d / fusionIntelligenceConfig.minIncidentsForGridElevation;
  }

  const score = clamp(Math.round(100 - elevationFactor * 55 - counts.count7d * 8), 15, 95);
  const confidence =
    counts.count90d >= 5 ? 82 : counts.count90d >= 2 ? 68 : counts.count90d >= 1 ? 52 : 38;

  const contributors = [];
  if (counts.count7d > 0) contributors.push(`${counts.count7d} incident(s) in grid (7d)`);
  if (counts.count30d > 0) contributors.push(`${counts.count30d} incident(s) in grid (30d)`);
  if (counts.count90d === 0) contributors.push('No historical incidents in this grid cell');

  return {
    cellId,
    count7d: counts.count7d,
    count30d: counts.count30d,
    count90d: counts.count90d,
    elevationFactor: Number(elevationFactor.toFixed(3)),
    score,
    label:
      score >= 75 ? 'Low grid risk' : score >= 55 ? 'Moderate grid risk' : 'Elevated grid risk',
    modelVersion: fusionIntelligenceConfig.modelVersion,
    confidence,
    topContributors: contributors.slice(0, 3),
    disclaimer:
      counts.count90d < fusionIntelligenceConfig.minIncidentsForGridElevation
        ? 'Limited incident history in this grid—statistical elevation may be unreliable.'
        : 'Grid risk from Suraksha + mirrored incident history with time decay.',
  };
}

module.exports = { getGridRiskForPoint, countIncidentsInCell, buildGridCellId };
