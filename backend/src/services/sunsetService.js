const { nashikSafetyConfig } = require('../config/nashikSafetyConfig');

const cache = new Map();

function cacheKey(lat, lng) {
  return `${lat.toFixed(2)}:${lng.toFixed(2)}`;
}

async function fetchSunTimes(lat, lng, date = new Date()) {
  const key = cacheKey(lat, lng);
  const cached = cache.get(key);
  if (cached && Date.now() - cached.fetchedAt < nashikSafetyConfig.sunsetCacheMinutes * 60 * 1000) {
    return cached.data;
  }

  const dateStr = date.toISOString().slice(0, 10);
  const url =
    `https://api.sunrise-sunset.org/json?lat=${encodeURIComponent(lat)}&lng=${encodeURIComponent(lng)}&date=${dateStr}&formatted=0`;

  try {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Sunset API ${response.status}`);
    const payload = await response.json();
    if (payload.status !== 'OK') throw new Error('Sunset API invalid status');

    const results = payload.results || {};
    const sunrise = new Date(results.sunrise);
    const sunset = new Date(results.sunset);
    const civilTwilightEnd = new Date(results.civil_twilight_end);
    const now = date;
    const isDark = now >= civilTwilightEnd || now < sunrise;

    const data = {
      source: 'sunset_api',
      sunrise: sunrise.toISOString(),
      sunset: sunset.toISOString(),
      civilTwilightEnd: civilTwilightEnd.toISOString(),
      isDark,
      fetchedAt: now.toISOString(),
    };
    cache.set(key, { fetchedAt: Date.now(), data });
    return data;
  } catch (error) {
    const hour = date.getHours();
    return {
      source: 'heuristic_fallback',
      sunrise: null,
      sunset: null,
      civilTwilightEnd: null,
      isDark: hour >= 19 || hour < 6,
      fetchedAt: date.toISOString(),
      error: error.message,
    };
  }
}

module.exports = { fetchSunTimes };
