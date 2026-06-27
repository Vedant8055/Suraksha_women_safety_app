const mongoose = require('mongoose');
const Authority = require('../models/Authority');
const { queryOsmFeaturesNear } = require('./osmIngestionService');
const { haversineMeters } = require('./safetyContextLoader');
const { nashikAuthorityBaseline } = require('../data/nashikAuthorityBaseline');
const { nashikSafetyConfig, isWithinNashik } = require('../config/nashikSafetyConfig');

const MAX_DISTANCE_METERS = 10000;

function mapAuthorityDoc(doc, lat, lng) {
  const [lngValue, latValue] = doc.location?.coordinates || [];
  return {
    _id: doc._id,
    name: doc.name,
    authorityType: doc.authorityType,
    phone: doc.phone || '',
    address: doc.address || '',
    location: doc.location,
    distanceMeters: Math.round(haversineMeters(lat, lng, latValue, lngValue)),
    source: 'suraksha_authority',
  };
}

function mapOsmFeature(feature, lat, lng) {
  const type =
    feature.featureType === 'clinic' ? 'hospital' : feature.featureType;
  const [lngValue, latValue] = feature.location?.coordinates || [];
  const tags = feature.tags || {};
  return {
    _id: feature.externalId || String(feature._id),
    name: feature.name || type,
    authorityType: type,
    phone: tags.phone || tags['contact:phone'] || '',
    address: tags['addr:full'] || tags['addr:street'] || 'Nashik (OpenStreetMap)',
    location: feature.location,
    distanceMeters: Math.round(haversineMeters(lat, lng, latValue, lngValue)),
    source: 'openstreetmap',
  };
}

function mapBaseline(entry, lat, lng) {
  const [lngValue, latValue] = entry.coordinates;
  return {
    _id: `baseline:${entry.name}`,
    name: entry.name,
    authorityType: entry.authorityType,
    phone: entry.phone,
    address: entry.address,
    location: { type: 'Point', coordinates: [lngValue, latValue] },
    distanceMeters: Math.round(haversineMeters(lat, lng, latValue, lngValue)),
    source: 'regional_guidance',
  };
}

function dedupeResources(resources) {
  const seen = new Set();
  return resources.filter((item) => {
    const kind = item.authorityType || item.type;
    const key = `${kind}:${item.name}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

async function queryAuthoritiesFromDb(lat, lng, type) {
  if (mongoose.connection.readyState !== 1) return [];
  return Authority.find({
    authorityType: type,
    location: {
      $near: {
        $geometry: { type: 'Point', coordinates: [Number(lng), Number(lat)] },
        $maxDistance: MAX_DISTANCE_METERS,
      },
    },
  })
    .limit(20)
    .lean();
}

async function queryOsmSupportFeatures(lat, lng) {
  if (!isWithinNashik(lat, lng) || mongoose.connection.readyState !== 1) {
    return [];
  }
  const features = await queryOsmFeaturesNear(
    lat,
    lng,
    nashikSafetyConfig.queryRadii.osmFeaturesMeters * 4,
  );
  return features.filter(
    (item) =>
      item.featureType === 'police' ||
      item.featureType === 'hospital' ||
      item.featureType === 'clinic',
  );
}

async function findNearbySupportPoints(lat, lng, type = null) {
  const numericLat = Number(lat);
  const numericLng = Number(lng);
  if (!Number.isFinite(numericLat) || !Number.isFinite(numericLng)) {
    return [];
  }

  const types = type ? [type] : ['police', 'hospital'];
  const combined = [];

  for (const authorityType of types) {
    const dbDocs = await queryAuthoritiesFromDb(numericLat, numericLng, authorityType);
    combined.push(...dbDocs.map((doc) => mapAuthorityDoc(doc, numericLat, numericLng)));
  }

  const osmFeatures = await queryOsmSupportFeatures(numericLat, numericLng);
  for (const feature of osmFeatures) {
    const mapped = mapOsmFeature(feature, numericLat, numericLng);
    if (!type || mapped.authorityType === type) {
      combined.push(mapped);
    }
  }

  if (isWithinNashik(numericLat, numericLng)) {
    for (const entry of nashikAuthorityBaseline) {
      if (type && entry.authorityType !== type) continue;
      combined.push(mapBaseline(entry, numericLat, numericLng));
    }
  }

  return dedupeResources(combined)
    .filter((item) => item.distanceMeters <= MAX_DISTANCE_METERS)
    .sort((left, right) => left.distanceMeters - right.distanceMeters)
    .slice(0, 20);
}

function buildFusionNearbyResources(lat, lng, authorities, external) {
  const numericLat = Number(lat);
  const numericLng = Number(lng);
  const fromAuthorities = (authorities || []).map((item) => ({
    id: String(item._id),
    type: item.authorityType,
    name: item.name,
    address: item.address || '',
    phone: item.phone || '',
    distanceMeters: Math.round(
      haversineMeters(
        numericLat,
        numericLng,
        item.location?.coordinates?.[1],
        item.location?.coordinates?.[0],
      ),
    ),
    source: 'suraksha_authority',
  }));

  const osmFeatures = external?.osm?.features || [];
  const fromOsm = osmFeatures
    .filter(
      (item) =>
        item.featureType === 'police' ||
        item.featureType === 'hospital' ||
        item.featureType === 'clinic',
    )
    .map((item) => {
      const mapped = mapOsmFeature(item, numericLat, numericLng);
      return {
        id: String(mapped._id),
        type: mapped.authorityType,
        name: mapped.name,
        address: mapped.address,
        phone: mapped.phone,
        distanceMeters: mapped.distanceMeters,
        source: 'openstreetmap',
      };
    });

  const fromBaseline = isWithinNashik(numericLat, numericLng)
    ? nashikAuthorityBaseline.map((entry) => {
        const mapped = mapBaseline(entry, numericLat, numericLng);
        return {
          id: String(mapped._id),
          type: mapped.authorityType,
          name: mapped.name,
          address: mapped.address,
          phone: mapped.phone,
          distanceMeters: mapped.distanceMeters,
          source: 'regional_guidance',
        };
      })
    : [];

  const merged = dedupeResources([...fromAuthorities, ...fromOsm, ...fromBaseline]);

  return merged
    .sort((left, right) => left.distanceMeters - right.distanceMeters)
    .slice(0, 12);
}

module.exports = {
  findNearbySupportPoints,
  buildFusionNearbyResources,
};
