const mongoose = require('mongoose');
const OsmFeature = require('../models/OsmFeature');
const Authority = require('../models/Authority');
const DataSourceSync = require('../models/DataSourceSync');
const { nashikSafetyConfig } = require('../config/nashikSafetyConfig');

function elementCenter(element) {
  if (element.type === 'node') {
    return { lat: element.lat, lng: element.lon };
  }
  if (element.center) {
    return { lat: element.center.lat, lng: element.center.lon };
  }
  return null;
}

function buildOverpassQuery() {
  const { south, west, north, east } = nashikSafetyConfig.bbox;
  return `[out:json][timeout:120];
(
  node["amenity"="police"](${south},${west},${north},${east});
  way["amenity"="police"](${south},${west},${north},${east});
  node["amenity"="hospital"](${south},${west},${north},${east});
  way["amenity"="hospital"](${south},${west},${north},${east});
  node["amenity"="clinic"](${south},${west},${north},${east});
  node["amenity"="fuel"](${south},${west},${north},${east});
  way["amenity"="fuel"](${south},${west},${north},${east});
  way["highway"]["lit"="no"](${south},${west},${north},${east});
  way["highway"]["lit"="yes"](${south},${west},${north},${east});
);
out center tags;`;
}

async function upsertSyncStatus(sourceKey, patch) {
  if (mongoose.connection.readyState !== 1) return;
  await DataSourceSync.findOneAndUpdate(
    { sourceKey },
    { region: nashikSafetyConfig.regionId, ...patch },
    { upsert: true, new: true },
  );
}

async function syncNashikOsmData() {
  if (mongoose.connection.readyState !== 1) {
    return { ok: false, message: 'Database unavailable' };
  }

  await upsertSyncStatus('openstreetmap', { status: 'running', message: 'Sync in progress' });

  try {
    const response = await fetch('https://overpass-api.de/api/interpreter', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ data: buildOverpassQuery() }),
    });

    if (!response.ok) {
      throw new Error(`Overpass API ${response.status}`);
    }

    const payload = await response.json();
    const elements = Array.isArray(payload.elements) ? payload.elements : [];
    let upserted = 0;

    for (const element of elements) {
      const center = elementCenter(element);
      if (!center) continue;

      const tags = element.tags || {};
      let featureType = null;
      if (tags.amenity === 'police') featureType = 'police';
      else if (tags.amenity === 'hospital') featureType = 'hospital';
      else if (tags.amenity === 'clinic') featureType = 'clinic';
      else if (tags.amenity === 'fuel') featureType = 'fuel_station';
      else if (tags.lit === 'no') featureType = 'unlit_road';
      else if (tags.lit === 'yes') featureType = 'lit_road';
      if (!featureType) continue;

      const externalId = `${element.type}/${element.id}`;
      const name =
        tags.name ||
        tags['name:en'] ||
        (featureType === 'unlit_road' ? 'Unlit road segment' : featureType === 'lit_road' ? 'Lit road segment' : featureType);

      await OsmFeature.findOneAndUpdate(
        { region: nashikSafetyConfig.regionId, externalId },
        {
          region: nashikSafetyConfig.regionId,
          source: 'openstreetmap',
          featureType,
          externalId,
          name,
          location: { type: 'Point', coordinates: [center.lng, center.lat] },
          tags,
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      );
      upserted += 1;

      if (featureType === 'police' || featureType === 'hospital') {
        await Authority.findOneAndUpdate(
          { name, authorityType: featureType, 'location.coordinates': [center.lng, center.lat] },
          {
            name,
            authorityType: featureType,
            address: tags['addr:full'] || tags['addr:street'] || 'Nashik (OpenStreetMap)',
            phone: tags.phone || tags['contact:phone'] || '',
            location: { type: 'Point', coordinates: [center.lng, center.lat] },
          },
          { upsert: true, new: true, setDefaultsOnInsert: true },
        );
      }
    }

    const now = new Date();
    await upsertSyncStatus('openstreetmap', {
      status: 'ok',
      lastSyncAt: now,
      lastSuccessAt: now,
      featureCount: upserted,
      message: `Synced ${upserted} OSM features for Nashik`,
    });

    return { ok: true, featureCount: upserted };
  } catch (error) {
    await upsertSyncStatus('openstreetmap', {
      status: 'error',
      lastSyncAt: new Date(),
      message: error.message,
    });
    return { ok: false, message: error.message };
  }
}

async function queryOsmFeaturesNear(lat, lng, maxDistanceMeters) {
  if (mongoose.connection.readyState !== 1) return [];
  return OsmFeature.find({
    region: nashikSafetyConfig.regionId,
    location: {
      $near: {
        $geometry: { type: 'Point', coordinates: [Number(lng), Number(lat)] },
        $maxDistance: maxDistanceMeters,
      },
    },
  })
    .limit(80)
    .lean();
}

async function queryOsmFeaturesInBbox(bbox) {
  if (mongoose.connection.readyState !== 1 || !bbox) return [];
  const { south, west, north, east } = bbox;
  return OsmFeature.find({
    region: nashikSafetyConfig.regionId,
    location: {
      $geoWithin: {
        $box: [
          [Number(west), Number(south)],
          [Number(east), Number(north)],
        ],
      },
    },
  })
    .limit(400)
    .lean();
}

async function getOsmSyncStatus() {
  if (mongoose.connection.readyState !== 1) {
    return { status: 'error', featureCount: 0, lastSuccessAt: null, message: 'Database unavailable' };
  }
  const doc = await DataSourceSync.findOne({ sourceKey: 'openstreetmap' }).lean();
  if (!doc) {
    return { status: 'pending', featureCount: 0, lastSuccessAt: null, message: 'Not synced yet' };
  }
  return {
    status: doc.status,
    featureCount: doc.featureCount || 0,
    lastSuccessAt: doc.lastSuccessAt ? doc.lastSuccessAt.toISOString() : null,
    lastSyncAt: doc.lastSyncAt ? doc.lastSyncAt.toISOString() : null,
    message: doc.message || '',
  };
}

module.exports = {
  syncNashikOsmData,
  queryOsmFeaturesNear,
  queryOsmFeaturesInBbox,
  getOsmSyncStatus,
};
