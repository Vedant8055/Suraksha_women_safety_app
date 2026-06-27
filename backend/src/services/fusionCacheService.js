const { fusionIntelligenceConfig } = require('../config/fusionIntelligenceConfig');

const store = new Map();

function get(key) {
  const entry = store.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    store.delete(key);
    return null;
  }
  return entry.value;
}

function set(key, value, ttlSeconds = fusionIntelligenceConfig.cacheTtlSeconds) {
  store.set(key, {
    value,
    expiresAt: Date.now() + ttlSeconds * 1000,
  });
}

function buildFusionCacheKey(lat, lng, at = new Date()) {
  const { encodeGeohash, hourBucket } = require('../utils/safetyGeoUtils');
  return `fusion:nashik:${encodeGeohash(lat, lng, 6)}:${hourBucket(at)}`;
}

function stats() {
  return { entries: store.size };
}

module.exports = { get, set, buildFusionCacheKey, stats };
