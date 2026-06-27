const mongoose = require('mongoose');
const IncidentReport = require('../models/IncidentReport');
const ExternalIncident = require('../models/ExternalIncident');
const AreaCrimeStats = require('../models/AreaCrimeStats');
const DataSourceSync = require('../models/DataSourceSync');
const { nashikCrimeBaseline } = require('../data/nashikCrimeBaseline');
const { nashikSafetyConfig } = require('../config/nashikSafetyConfig');

const VERIFIED_STATUSES = ['reported', 'under_review', 'resolved'];

async function upsertSync(sourceKey, patch) {
  if (mongoose.connection.readyState !== 1) return;
  await DataSourceSync.findOneAndUpdate(
    { sourceKey },
    { region: nashikSafetyConfig.regionId, ...patch },
    { upsert: true, new: true },
  );
}

async function syncAreaCrimeStats() {
  if (mongoose.connection.readyState !== 1) {
    return { ok: false, message: 'Database unavailable' };
  }

  const now = new Date();
  const doc = await AreaCrimeStats.findOneAndUpdate(
    {
      region: nashikSafetyConfig.regionId,
      district: nashikCrimeBaseline.district,
      periodLabel: nashikCrimeBaseline.periodLabel,
    },
    {
      region: nashikSafetyConfig.regionId,
      ...nashikCrimeBaseline,
      categoryBreakdown: nashikCrimeBaseline.categoryBreakdown,
      lastSyncAt: now,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );

  await upsertSync('open_data_district', {
    status: 'ok',
    lastSyncAt: now,
    lastSuccessAt: now,
    featureCount: 1,
    message: `Nashik district stats (${doc.periodLabel}) synced`,
  });

  return { ok: true, statsId: String(doc._id) };
}

async function syncExternalIncidentsFromAppReports() {
  if (mongoose.connection.readyState !== 1) {
    return { ok: false, message: 'Database unavailable' };
  }

  const since = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
  const reports = await IncidentReport.find({
    status: { $in: VERIFIED_STATUSES },
    createdAt: { $gte: since },
    location: { $exists: true },
  })
    .sort({ createdAt: -1 })
    .limit(500)
    .lean();

  let upserted = 0;
  for (const report of reports) {
    const coords = report.location?.coordinates;
    if (!Array.isArray(coords) || coords.length < 2) continue;
    const sourceId = String(report._id);
    await ExternalIncident.findOneAndUpdate(
      { region: nashikSafetyConfig.regionId, source: 'suraksha_reports', sourceId },
      {
        region: nashikSafetyConfig.regionId,
        source: 'suraksha_reports',
        sourceId,
        category: report.category || 'incident',
        description: report.description || '',
        location: { type: 'Point', coordinates: coords },
        occurredAt: report.createdAt,
        confidence: 0.95,
        spatialPrecision: 'point',
        disclaimer: 'Verified Suraksha user incident report.',
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
    upserted += 1;
  }

  const now = new Date();
  await upsertSync('suraksha_reports_mirror', {
    status: 'ok',
    lastSyncAt: now,
    lastSuccessAt: now,
    featureCount: upserted,
    message: `Mirrored ${upserted} app incident reports`,
  });

  return { ok: true, featureCount: upserted };
}

async function syncNashikCrimeData() {
  const [statsResult, mirrorResult] = await Promise.all([
    syncAreaCrimeStats(),
    syncExternalIncidentsFromAppReports(),
  ]);
  return {
    ok: statsResult.ok && mirrorResult.ok,
    areaStats: statsResult,
    incidentMirror: mirrorResult,
  };
}

async function getAreaCrimeContext(regionId = nashikSafetyConfig.regionId) {
  if (mongoose.connection.readyState !== 1) {
    return null;
  }
  return AreaCrimeStats.findOne({ region: regionId }).sort({ lastSyncAt: -1 }).lean();
}

async function queryExternalIncidentsNear(lat, lng, maxDistanceMeters = 2500) {
  if (mongoose.connection.readyState !== 1) return [];
  return ExternalIncident.find({
    region: nashikSafetyConfig.regionId,
    spatialPrecision: 'point',
    location: {
      $near: {
        $geometry: { type: 'Point', coordinates: [Number(lng), Number(lat)] },
        $maxDistance: maxDistanceMeters,
      },
    },
  })
    .limit(40)
    .lean();
}

async function getCrimeSyncStatus() {
  if (mongoose.connection.readyState !== 1) {
    return { status: 'error', message: 'Database unavailable' };
  }
  const [districtSync, mirrorSync, externalCount, areaStats] = await Promise.all([
    DataSourceSync.findOne({ sourceKey: 'open_data_district' }).lean(),
    DataSourceSync.findOne({ sourceKey: 'suraksha_reports_mirror' }).lean(),
    ExternalIncident.countDocuments({ region: nashikSafetyConfig.regionId }),
    AreaCrimeStats.findOne({ region: nashikSafetyConfig.regionId }).lean(),
  ]);

  return {
    status: districtSync?.status === 'ok' ? 'ok' : 'pending',
    externalIncidentCount: externalCount,
    districtStats: areaStats
      ? {
          periodLabel: areaStats.periodLabel,
          ratePer100k: areaStats.ratePer100k,
          totalIncidents: areaStats.totalIncidents,
          lastSyncAt: areaStats.lastSyncAt?.toISOString?.() || null,
        }
      : null,
    lastMirrorAt: mirrorSync?.lastSuccessAt?.toISOString?.() || null,
    message: districtSync?.message || 'Crime data sync pending',
  };
}

module.exports = {
  syncNashikCrimeData,
  syncAreaCrimeStats,
  syncExternalIncidentsFromAppReports,
  getAreaCrimeContext,
  queryExternalIncidentsNear,
  getCrimeSyncStatus,
};
