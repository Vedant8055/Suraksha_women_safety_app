const env = require('../config/env');

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

function parseGoogleMapsCoordinates(input) {
  if (!input) return null;
  const url = String(input).trim();
  const patterns = [
    { regex: /@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/, latIndex: 1, lngIndex: 2 },
    { regex: /[?&]q=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/, latIndex: 1, lngIndex: 2 },
    { regex: /[?&]query=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/, latIndex: 1, lngIndex: 2 },
    { regex: /\/place\/[^/]+\/@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/, latIndex: 1, lngIndex: 2 },
    { regex: /!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)/, latIndex: 1, lngIndex: 2 },
    { regex: /!4d(-?\d+(?:\.\d+)?)!3d(-?\d+(?:\.\d+)?)/, latIndex: 2, lngIndex: 1 },
  ];

  for (const pattern of patterns) {
    const match = url.match(pattern.regex);
    if (!match) continue;
    const lat = Number(match[pattern.latIndex]);
    const lng = Number(match[pattern.lngIndex]);
    if (Number.isFinite(lat) && Number.isFinite(lng)) {
      return { lat, lng };
    }
  }
  return null;
}

function normalizePlaceType(type, name = '') {
  const lowerName = String(name).toLowerCase();
  if (type === 'police' || lowerName.includes('police')) return 'police';
  if (type === 'hospital' || type === 'clinic' || lowerName.includes('hospital') || lowerName.includes('clinic')) {
    return 'hospital';
  }
  if (type === 'gas_station' || lowerName.includes('petrol') || lowerName.includes('fuel')) return 'fuel_station';
  return null;
}

function parsePlacesResults(data) {
  const results = Array.isArray(data?.results) ? data.results : [];
  return results
    .map((item) => {
      if (item && typeof item === 'object') return item;
      return null;
    })
    .filter(Boolean);
}

async function fetchNearbyPlaces({
  lat,
  lng,
  apiKey,
  type,
  keyword,
  radius = 2200,
}) {
  if (!apiKey) return [];

  const params = new URLSearchParams({
    location: `${lat},${lng}`,
    radius: String(radius),
    key: apiKey,
  });
  if (type) params.set('type', type);
  if (keyword) params.set('keyword', keyword);

  const response = await fetch(
    `https://maps.googleapis.com/maps/api/place/nearbysearch/json?${params.toString()}`,
  );
  if (!response.ok) {
    throw new Error(`Google Places nearby search failed with ${response.status}`);
  }

  const data = await response.json();
  const status = data?.status?.toString() || 'UNKNOWN';
  if (status !== 'OK' && status !== 'ZERO_RESULTS') {
    throw new Error(`Google Places API status ${status}`);
  }

  return parsePlacesResults(data).map((item) => {
    const geometry = item.geometry;
    const location = geometry && typeof geometry === 'object' ? geometry.location : null;
    const placeLat = location?.lat != null ? Number(location.lat) : null;
    const placeLng = location?.lng != null ? Number(location.lng) : null;
    if (!Number.isFinite(placeLat) || !Number.isFinite(placeLng)) {
      return null;
    }

    const placeType =
      normalizePlaceType(type || item.types?.[0], item.name) ||
      normalizePlaceType(item.types?.[0], item.name);
    if (!placeType) return null;

    return {
      id: item.place_id || `${item.name}:${placeLat.toFixed(5)}:${placeLng.toFixed(5)}`,
      type: placeType,
      name: item.name || 'Unnamed place',
      address: item.vicinity || item.formatted_address || '',
      phone: '',
      distanceMeters: Math.round(haversineMeters(lat, lng, placeLat, placeLng)),
      source: 'google_places',
      latitude: placeLat,
      longitude: placeLng,
      rating: item.rating != null ? Number(item.rating) : null,
      isOpenNow: item.opening_hours?.open_now ?? null,
    };
  })
    .filter(Boolean)
    .sort((left, right) => left.distanceMeters - right.distanceMeters);
}

async function findNearbySupportPlaces(lat, lng) {
  const apiKey = env.googleMapsApiKey;
  if (!apiKey) return [];

  const searches = await Promise.all([
    fetchNearbyPlaces({ lat, lng, apiKey, type: 'police', radius: 2400 }),
    fetchNearbyPlaces({ lat, lng, apiKey, type: 'hospital', radius: 2600 }),
    fetchNearbyPlaces({ lat, lng, apiKey, type: 'gas_station', keyword: 'petrol pump', radius: 2600 }),
  ]);

  const byId = new Map();
  for (const list of searches) {
    for (const item of list) {
      if (!item) continue;
      const key = `${item.type}:${item.id}`;
      if (!byId.has(key) || byId.get(key).distanceMeters > item.distanceMeters) {
        byId.set(key, item);
      }
    }
  }

  return [...byId.values()].sort((left, right) => left.distanceMeters - right.distanceMeters);
}

module.exports = {
  findNearbySupportPlaces,
  parseGoogleMapsCoordinates,
};
