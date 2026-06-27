function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function toDisplayDistance(distanceMeters) {
  if (distanceMeters >= 1000) {
    return `${(distanceMeters / 1000).toFixed(distanceMeters >= 10000 ? 0 : 1)} km`;
  }
  return `${Math.round(distanceMeters)} m`;
}

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

function buildGridCellId(lat, lng, precision = 2) {
  const factor = 10 ** precision;
  return `nashik:${Math.round(lat * factor)}:${Math.round(lng * factor)}`;
}

function cellCenterFromId(cellId) {
  const parts = cellId.split(':');
  if (parts.length !== 3) return null;
  const factor = 10 ** Number(parts[1].length > 3 ? 3 : 2);
  const latKey = Number(parts[1]);
  const lngKey = Number(parts[2]);
  const precision = String(Math.abs(latKey)).length <= 2 ? 2 : 3;
  const f = 10 ** precision;
  return { lat: latKey / f, lng: lngKey / f };
}

function encodeGeohash(lat, lng, precision = 6) {
  const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  let idx = 0;
  let bit = 0;
  let evenBit = true;
  let geohash = '';
  let latMin = -90;
  let latMax = 90;
  let lngMin = -180;
  let lngMax = 180;

  while (geohash.length < precision) {
    if (evenBit) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        idx = idx * 2 + 1;
        lngMin = mid;
      } else {
        idx *= 2;
        lngMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        idx = idx * 2 + 1;
        latMin = mid;
      } else {
        idx *= 2;
        latMax = mid;
      }
    }
    evenBit = !evenBit;
    if (++bit === 5) {
      geohash += base32.charAt(idx);
      bit = 0;
      idx = 0;
    }
  }
  return geohash;
}

function hourBucket(date = new Date()) {
  return `${date.toISOString().slice(0, 13)}`;
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

  return { lat: (lat2 * 180) / Math.PI, lng: (lng2 * 180) / Math.PI };
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

function samplePolyline(path, intervalMeters = 120) {
  if (!Array.isArray(path) || path.length === 0) return [];
  if (path.length === 1) return [path[0]];

  const samples = [path[0]];
  let carry = 0;
  for (let i = 1; i < path.length; i += 1) {
    const from = path[i - 1];
    const to = path[i];
    const segment = haversineMeters(from.lat, from.lng, to.lat, to.lng);
    if (segment <= 0) continue;
    let traveled = intervalMeters - carry;
    while (traveled <= segment) {
      const ratio = traveled / segment;
      samples.push({
        lat: from.lat + (to.lat - from.lat) * ratio,
        lng: from.lng + (to.lng - from.lng) * ratio,
      });
      traveled += intervalMeters;
    }
    carry = segment - (traveled - intervalMeters);
  }
  samples.push(path[path.length - 1]);
  return samples;
}

function bboxFromPoints(points, paddingMeters = 400) {
  if (!points.length) return null;
  const padDeg = paddingMeters / 111000;
  let south = points[0].lat;
  let north = points[0].lat;
  let west = points[0].lng;
  let east = points[0].lng;
  for (const point of points) {
    south = Math.min(south, point.lat);
    north = Math.max(north, point.lat);
    west = Math.min(west, point.lng);
    east = Math.max(east, point.lng);
  }
  return {
    south: south - padDeg,
    north: north + padDeg,
    west: west - padDeg,
    east: east + padDeg,
  };
}

module.exports = {
  clamp,
  haversineMeters,
  toDisplayDistance,
  buildGridCellId,
  cellCenterFromId,
  encodeGeohash,
  hourBucket,
  directionPoint,
  interpolatePoint,
  samplePolyline,
  bboxFromPoints,
};
