const mongoose = require('mongoose');
const CrowdHeatCell = require('../models/CrowdHeatCell');
const { nashikSafetyConfig, isWithinNashik } = require('../config/nashikSafetyConfig');

function buildCellId(lat, lng) {
  const factor = 10 ** nashikSafetyConfig.crowdGridPrecision;
  return `nashik:${Math.round(lat * factor)}:${Math.round(lng * factor)}`;
}

function cellCenter(lat, lng) {
  const factor = 10 ** nashikSafetyConfig.crowdGridPrecision;
  return {
    lat: Math.round(lat * factor) / factor,
    lng: Math.round(lng * factor) / factor,
  };
}

async function recordAnonymousPing(lat, lng) {
  if (!isWithinNashik(lat, lng)) {
    return { accepted: false, reason: 'outside_nashik_region' };
  }
  if (mongoose.connection.readyState !== 1) {
    return { accepted: false, reason: 'database_unavailable' };
  }

  const center = cellCenter(lat, lng);
  const cellId = buildCellId(lat, lng);
  const now = new Date();
  const windowMs = nashikSafetyConfig.crowdWindowHours * 60 * 60 * 1000;

  let cell = await CrowdHeatCell.findOne({ cellId });
  if (!cell) {
    cell = await CrowdHeatCell.create({
      cellId,
      region: nashikSafetyConfig.regionId,
      location: { type: 'Point', coordinates: [center.lng, center.lat] },
      pingCount2h: 1,
      windowStartedAt: now,
      lastPingAt: now,
    });
    return { accepted: true, cellId, pingCount2h: cell.pingCount2h };
  }

  if (now - cell.windowStartedAt > windowMs) {
    cell.pingCount2h = 1;
    cell.windowStartedAt = now;
  } else {
    cell.pingCount2h += 1;
  }
  cell.lastPingAt = now;
  await cell.save();
  return { accepted: true, cellId, pingCount2h: cell.pingCount2h };
}

async function getCrowdActivityNear(lat, lng) {
  if (mongoose.connection.readyState !== 1) {
    return {
      source: 'crowd_aggregate',
      available: false,
      activityLevel: 'unknown',
      totalPings2h: 0,
      nearbyCells: 0,
      confidence: 20,
    };
  }

  const radius = nashikSafetyConfig.queryRadii.crowdActivityMeters;
  const cells = await CrowdHeatCell.find({
    location: {
      $near: {
        $geometry: { type: 'Point', coordinates: [Number(lng), Number(lat)] },
        $maxDistance: radius,
      },
    },
  }).limit(20);

  const windowMs = nashikSafetyConfig.crowdWindowHours * 60 * 60 * 1000;
  const now = Date.now();
  let totalPings2h = 0;
  let activeCells = 0;

  for (const cell of cells) {
    if (now - new Date(cell.windowStartedAt).getTime() > windowMs) continue;
    activeCells += 1;
    totalPings2h += cell.pingCount2h || 0;
  }

  let activityLevel = 'low';
  let confidence = 35;
  if (totalPings2h >= 25) {
    activityLevel = 'high';
    confidence = 82;
  } else if (totalPings2h >= 8) {
    activityLevel = 'moderate';
    confidence = 68;
  } else if (totalPings2h >= 1) {
    activityLevel = 'low';
    confidence = 55;
  } else {
    activityLevel = 'very_low';
    confidence = 40;
  }

  return {
    source: 'crowd_aggregate',
    available: activeCells > 0,
    activityLevel,
    totalPings2h,
    nearbyCells: activeCells,
    confidence,
    disclaimer:
      'Based on anonymous Suraksha app movement patterns in the last 2 hours. Not live footfall sensors.',
  };
}

async function getCrowdStats() {
  if (mongoose.connection.readyState !== 1) {
    return { activeCells: 0, totalPings2h: 0, lastPingAt: null };
  }
  const windowStart = new Date(Date.now() - nashikSafetyConfig.crowdWindowHours * 60 * 60 * 1000);
  const cells = await CrowdHeatCell.find({ windowStartedAt: { $gte: windowStart } }).limit(500);
  const totalPings2h = cells.reduce((sum, cell) => sum + (cell.pingCount2h || 0), 0);
  const lastPingAt = cells.reduce(
    (latest, cell) => (cell.lastPingAt > latest ? cell.lastPingAt : latest),
    new Date(0),
  );
  return {
    activeCells: cells.length,
    totalPings2h,
    lastPingAt: lastPingAt.getTime() > 0 ? lastPingAt.toISOString() : null,
  };
}

module.exports = {
  recordAnonymousPing,
  getCrowdActivityNear,
  getCrowdStats,
  buildCellId,
};
