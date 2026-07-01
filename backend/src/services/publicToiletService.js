const env = require('../config/env');
const { ApiError } = require('../utils/ApiError');
const { haversineMeters } = require('./safetyContextLoader');

const DEFAULT_RADIUS_METERS = 3000;
const DEFAULT_LIMIT = 50;
const DEFAULT_CLEANLINESS_MIN = 70;
const DEFAULT_INCLUDE_CLOSED = false;
const CACHE_TTL_MS = 90000;
const FETCH_TIMEOUT_MS = 5000;
const cache = new Map();

function normalizeRoundedLocation(value) {
  return Number(value).toFixed(3);
}

function toFiniteNumber(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function toBoolean(value, fallback = DEFAULT_INCLUDE_CLOSED) {
  if (value === undefined || value === null || value === '') return fallback;
  if (typeof value === 'boolean') return value;
  const normalized = String(value).trim().toLowerCase();
  if (['true', '1', 'yes', 'on'].includes(normalized)) return true;
  if (['false', '0', 'no', 'off'].includes(normalized)) return false;
  return fallback;
}

function clampInteger(value, min, max, fallback) {
  const number = Math.trunc(Number(value));
  if (!Number.isFinite(number)) return fallback;
  return Math.min(Math.max(number, min), max);
}

function makeCacheKey({ lat, lng, radius, cleanlinessMin, includeClosed }) {
  return [
    'nearby_toilets',
    normalizeRoundedLocation(lat),
    normalizeRoundedLocation(lng),
    radius,
    cleanlinessMin,
    includeClosed ? 1 : 0,
  ].join(':');
}

function getCachedResult(key) {
  const entry = cache.get(key);
  if (!entry) return null;
  if (entry.expiresAt <= Date.now()) {
    cache.delete(key);
    return null;
  }
  return entry.value;
}

function setCachedResult(key, value) {
  cache.set(key, {
    value,
    expiresAt: Date.now() + CACHE_TTL_MS,
  });
}

function normalizeAvailabilityStatus(value) {
  const text = String(value || '').trim().toLowerCase();
  if (!text) return 'Status Unknown';
  if (['open', 'operational', 'available', 'usable'].includes(text)) return 'Open';
  if (['closed', 'shut'].includes(text)) return 'Closed';
  if (['maintenance', 'under maintenance', 'repair'].includes(text)) return 'Under Maintenance';
  if (['busy', 'limited'].includes(text)) return 'Limited';
  return text
    .split(/[_-]/)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

function normalizeCleanlinessStatus(score, statusText) {
  const text = String(statusText || '').trim().toLowerCase();
  if (text) {
    if (text.includes('clean')) return 'Clean';
    if (text.includes('usable')) return 'Usable';
    if (text.includes('good')) return 'Clean';
    if (text.includes('needs')) return 'Needs Cleaning';
    if (text.includes('unknown')) return 'Status Unknown';
  }

  if (typeof score !== 'number' || Number.isNaN(score)) return 'Status Unknown';
  if (score >= 85) return 'Clean';
  if (score >= 70) return 'Usable';
  if (score >= 50) return 'Needs Cleaning';
  return 'Needs Cleaning';
}

function normalizeSafetyDisplayStatus(cleanlinessStatus, availabilityStatus, score) {
  const availability = availabilityStatus.toLowerCase();
  if (availability === 'under maintenance' || availability === 'closed') {
    return 'Not recommended';
  }
  if (cleanlinessStatus === 'Status Unknown' || score == null) {
    return 'Status not verified';
  }
  if (cleanlinessStatus === 'Clean' && availability === 'open') {
    return 'Recommended';
  }
  if (cleanlinessStatus === 'Usable' && availability === 'open') {
    return 'Usable';
  }
  if (cleanlinessStatus === 'Needs Cleaning') {
    return 'Use with caution';
  }
  return 'Status not verified';
}

function normalizeFacilities(source = {}) {
  const raw = source.facilities || source.amenities || source.features || {};
  const has = (keys) => keys.some((key) => Boolean(raw[key]));
  return {
    male: has(['male', 'men', 'gents', 'maleFacility', 'male_available']),
    female: has(['female', 'women', 'ladies', 'femaleFacility', 'female_available']),
    accessible: has(['accessible', 'wheelchair', 'pwd', 'barrierFree', 'accessibleFacility']),
    waterAvailable: has(['water', 'waterAvailable', 'runningWater']),
  };
}

function normalizeToilet(raw, lat, lng) {
  const latitude = toFiniteNumber(
    raw.latitude ?? raw.lat ?? raw.location?.latitude ?? raw.location?.lat,
  );
  const longitude = toFiniteNumber(
    raw.longitude ?? raw.lng ?? raw.location?.longitude ?? raw.location?.lng,
  );
  const distanceMeters = toFiniteNumber(
    raw.distanceMeters ?? raw.distance_meters ?? raw.distance ?? raw.distance_m ?? raw.distanceMetersFromUser,
  );
  const cleanlinessScore = toFiniteNumber(
    raw.cleanlinessScore ?? raw.cleanliness_score ?? raw.score ?? raw.cleanliness,
  );
  const distanceValue =
    distanceMeters != null
      ? Math.round(distanceMeters)
      : latitude != null && longitude != null
      ? Math.round(haversineMeters(lat, lng, latitude, longitude))
      : 0;
  const availabilityStatus = normalizeAvailabilityStatus(
    raw.availabilityStatus ?? raw.status ?? raw.operationalStatus,
  );
  const cleanlinessStatus = normalizeCleanlinessStatus(cleanlinessScore, raw.cleanlinessStatus);
  const safetyDisplayStatus = normalizeSafetyDisplayStatus(
    cleanlinessStatus,
    availabilityStatus,
    cleanlinessScore,
  );
  const lastUpdatedAt =
    raw.lastUpdatedAt ??
    raw.updatedAt ??
    raw.last_updated_at ??
    raw.lastInspectionAt ??
    raw.inspectedAt ??
    null;

  return {
    id: String(raw.id ?? raw.toiletId ?? raw.publicId ?? raw.code ?? raw.name ?? `toilet-${distanceValue}`),
    name: String(raw.name ?? raw.toilet_name ?? raw.label ?? 'Public Toilet'),
    address: String(raw.address ?? raw.locationName ?? raw.vicinity ?? ''),
    distanceMeters: distanceValue,
    distanceLabel: distanceValue >= 1000
      ? `${(distanceValue / 1000).toFixed(1)} km away`
      : `${distanceValue} m away`,
    latitude,
    longitude,
    cleanlinessScore: cleanlinessScore != null ? Math.round(cleanlinessScore) : null,
    cleanlinessStatus,
    availabilityStatus,
    lastUpdatedAt: lastUpdatedAt ? new Date(lastUpdatedAt).toISOString() : null,
    facilities: normalizeFacilities(raw),
    safetyDisplayStatus,
  };
}

function extractToiletList(payload) {
  if (Array.isArray(payload)) return payload;
  if (!payload || typeof payload !== 'object') return [];
  return payload.toilets || payload.results || payload.data || payload.items || [];
}

async function fetchWithRetry(url, options) {
  let lastError = null;
  for (let attempt = 0; attempt < 2; attempt += 1) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
    try {
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
      });
      clearTimeout(timeout);
      if ([401, 403, 429].includes(response.status) || response.ok) {
        return response;
      }
      if (response.status >= 500 && attempt === 0) {
        lastError = new Error(`Upstream server error: ${response.status}`);
        continue;
      }
      return response;
    } catch (error) {
      clearTimeout(timeout);
      lastError = error;
      if (attempt === 0) continue;
      throw error;
    }
  }
  throw lastError || new Error('Unable to reach Sanitation Platform');
}

async function fetchNearbyPublicToilets({
  lat,
  lng,
  radius = DEFAULT_RADIUS_METERS,
  limit = DEFAULT_LIMIT,
  cleanlinessMin = DEFAULT_CLEANLINESS_MIN,
  includeClosed = DEFAULT_INCLUDE_CLOSED,
}) {
  const numericLat = Number(lat);
  const numericLng = Number(lng);
  if (!Number.isFinite(numericLat) || !Number.isFinite(numericLng)) {
    throw new ApiError(400, 'Latitude and longitude are required.');
  }

  const sanitizedRadius = clampInteger(radius, 100, 10000, DEFAULT_RADIUS_METERS);
  const sanitizedLimit = clampInteger(limit, 1, 100, DEFAULT_LIMIT);
  const sanitizedCleanlinessMin = clampInteger(
    cleanlinessMin,
    0,
    100,
    DEFAULT_CLEANLINESS_MIN,
  );
  const sanitizedIncludeClosed = toBoolean(includeClosed, DEFAULT_INCLUDE_CLOSED);

  const cacheKey = makeCacheKey({
    lat: numericLat,
    lng: numericLng,
    radius: sanitizedRadius,
    cleanlinessMin: sanitizedCleanlinessMin,
    includeClosed: sanitizedIncludeClosed,
  });
  const cached = getCachedResult(cacheKey);
  if (cached) return cached;

  if (!env.sanitationApiBaseUrl || !env.sanitationPublicApiKey) {
    throw new ApiError(503, 'Toilet service is currently unavailable.');
  }

  const url = new URL('/api/public/v1/toilets/nearby', env.sanitationApiBaseUrl);
  url.searchParams.set('lat', String(numericLat));
  url.searchParams.set('lng', String(numericLng));
  url.searchParams.set('radius', String(sanitizedRadius));
  url.searchParams.set('limit', String(sanitizedLimit));
  url.searchParams.set('cleanliness_min', String(sanitizedCleanlinessMin));
  url.searchParams.set('include_closed', String(sanitizedIncludeClosed));

  const response = await fetchWithRetry(url.toString(), {
    method: 'GET',
    headers: {
      'x-api-key': env.sanitationPublicApiKey,
      accept: 'application/json',
    },
  });

  if (response.status === 401 || response.status === 403) {
    console.warn(
      `[toilets] Sanitation API denied access for rounded location ${normalizeRoundedLocation(numericLat)},${normalizeRoundedLocation(numericLng)}.`,
    );
    throw new ApiError(response.status, 'Toilet service is currently unavailable.');
  }
  if (response.status === 429) {
    throw new ApiError(429, 'Toilet service is busy. Please try again shortly.');
  }
  if (!response.ok) {
    throw new ApiError(503, 'Toilet service is currently unavailable.');
  }

  let payload;
  try {
    payload = await response.json();
  } catch (error) {
    throw new ApiError(502, 'Toilet service returned an invalid response.');
  }

  const toilets = extractToiletList(payload)
    .map((item) => normalizeToilet(item, numericLat, numericLng))
    .filter((item) => Number.isFinite(item.distanceMeters))
    .sort((a, b) => a.distanceMeters - b.distanceMeters);

  const result = {
    toilets,
    meta: {
      radius: sanitizedRadius,
      limit: sanitizedLimit,
      cleanlinessMin: sanitizedCleanlinessMin,
      includeClosed: sanitizedIncludeClosed,
      count: toilets.length,
      source: 'sanitation_platform_public_api',
    },
  };

  setCachedResult(cacheKey, result);
  return result;
}

module.exports = {
  fetchNearbyPublicToilets,
  normalizeAvailabilityStatus,
  normalizeCleanlinessStatus,
  normalizeSafetyDisplayStatus,
  normalizeToilet,
};
