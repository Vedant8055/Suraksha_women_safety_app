const mongoose = require('mongoose');
const ExternalIncident = require('../models/ExternalIncident');
const DataSourceSync = require('../models/DataSourceSync');
const env = require('../config/env');
const { nashikSafetyConfig } = require('../config/nashikSafetyConfig');

const DEFAULT_SOURCE_KEY = 'safety_news_feeds';

let refreshPromise = null;
let lastRefreshAt = 0;
let lastSnapshot = {
  ok: true,
  enabled: false,
  feeds: 0,
  ingested: 0,
  skipped: 0,
  errors: [],
  lastSyncAt: null,
};

function hashString(value) {
  let hash = 0;
  for (let index = 0; index < value.length; index += 1) {
    hash = (hash << 5) - hash + value.charCodeAt(index);
    hash |= 0;
  }
  return Math.abs(hash);
}

function toRadians(value) {
  return (value * Math.PI) / 180;
}

function projectPoint(lat, lng, bearingDegrees, distanceMeters) {
  const earthRadius = 6371000;
  const bearing = toRadians(bearingDegrees);
  const lat1 = toRadians(lat);
  const lng1 = toRadians(lng);
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

  return {
    lat: (lat2 * 180) / Math.PI,
    lng: (lng2 * 180) / Math.PI,
  };
}

function stripTags(text = '') {
  return String(text)
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/\s+/g, ' ')
    .trim();
}

function extractTag(body, tagNames) {
  for (const tagName of tagNames) {
    const pattern = new RegExp(`<${tagName}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/${tagName}>`, 'i');
    const match = body.match(pattern);
    if (match) return stripTags(match[1]);

    const selfClosing = new RegExp(`<${tagName}[^>]*href=["']([^"']+)["'][^>]*/?>`, 'i');
    const hrefMatch = body.match(selfClosing);
    if (hrefMatch) return stripTags(hrefMatch[1]);
  }
  return '';
}

function extractAttr(body, tagName, attrName) {
  const pattern = new RegExp(`<${tagName}[^>]*${attrName}=["']([^"']+)["'][^>]*\/?>`, 'i');
  const match = body.match(pattern);
  return match ? stripTags(match[1]) : '';
}

function parseGeo(body) {
  const pointMatch = body.match(/<georss:point>([-\d.]+)\s+([-\d.]+)<\/georss:point>/i);
  if (pointMatch) {
    const lat = Number(pointMatch[1]);
    const lng = Number(pointMatch[2]);
    if (Number.isFinite(lat) && Number.isFinite(lng)) return { lat, lng };
  }

  const latText =
    extractTag(body, ['geo:lat', 'lat']) || extractAttr(body, 'geo:lat', 'value') || '';
  const lngText =
    extractTag(body, ['geo:long', 'geo:lon', 'long', 'lon']) ||
    extractAttr(body, 'geo:long', 'value') ||
    '';

  const lat = Number(latText);
  const lng = Number(lngText);
  if (Number.isFinite(lat) && Number.isFinite(lng)) return { lat, lng };
  return null;
}

function parsePublishedAt(body) {
  const value =
    extractTag(body, ['pubDate', 'updated', 'published', 'dc:date']) ||
    extractAttr(body, 'time', 'datetime');
  const parsed = value ? new Date(value) : null;
  return parsed && !Number.isNaN(parsed.getTime()) ? parsed : new Date();
}

function parseFeedItems(raw) {
  const text = String(raw || '');
  const items = [];
  const bodyPattern = /<(item|entry)\b[^>]*>([\s\S]*?)<\/\1>/gi;
  let match;
  while ((match = bodyPattern.exec(text))) {
    const body = match[2];
    const title = extractTag(body, ['title']);
    const link =
      extractTag(body, ['link']) ||
      extractAttr(body, 'link', 'href') ||
      extractTag(body, ['guid']);
    const description =
      extractTag(body, ['description', 'summary', 'content:encoded', 'content']) || '';
    const sourceId = link || extractTag(body, ['guid', 'id']) || title;
    const geo = parseGeo(body);
    items.push({
      title,
      link,
      description,
      sourceId,
      occurredAt: parsePublishedAt(body),
      geo,
    });
  }
  return items;
}

function loadFeedDefinitions() {
  if (env.safetyNewsFeedsJson.trim()) {
    try {
      const parsed = JSON.parse(env.safetyNewsFeedsJson);
      if (Array.isArray(parsed)) {
        return parsed
          .map((item, index) => normalizeFeedDefinition(item, index))
          .filter(Boolean);
      }
    } catch (_) {}
  }

  return env.safetyNewsFeeds
    .split(',')
    .map((item, index) => normalizeFeedDefinition(item, index))
    .filter(Boolean);
}

function normalizeFeedDefinition(value, index) {
  if (!value) return null;
  if (typeof value === 'string') {
    const url = value.trim();
    if (!url) return null;
    return {
      url,
      sourceKey: `news_feed_${index + 1}`,
      label: `Public feed ${index + 1}`,
      center: nashikSafetyConfig.center,
      radiusMeters: 18000,
      kind: 'rss',
    };
  }

  if (typeof value !== 'object') return null;
  const url = String(value.url || '').trim();
  if (!url) return null;
  const centerLat = Number(value.centerLat ?? value.lat ?? nashikSafetyConfig.center.lat);
  const centerLng = Number(value.centerLng ?? value.lng ?? nashikSafetyConfig.center.lng);
  return {
    url,
    sourceKey: String(value.sourceKey || value.key || `news_feed_${index + 1}`),
    label: String(value.label || value.name || `Public feed ${index + 1}`),
    kind: String(value.kind || 'rss').toLowerCase(),
    center: {
      lat: Number.isFinite(centerLat) ? centerLat : nashikSafetyConfig.center.lat,
      lng: Number.isFinite(centerLng) ? centerLng : nashikSafetyConfig.center.lng,
    },
    radiusMeters: Number(value.radiusMeters || value.radius || 18000),
  };
}

function classifySignal(text) {
  const normalized = String(text || '').toLowerCase();
  if (!normalized.trim()) {
    return { category: 'incident', label: 'General incident', severity: 0.45 };
  }

  if (/(murder|homicide|attempt to murder|attempt murder|half murder|body found|killed)/.test(normalized)) {
    return { category: 'murder', label: 'Violent crime', severity: 1 };
  }
  if (/(chain snatch|chain-snatch|chainsnatch|snatching)/.test(normalized)) {
    return { category: 'chain_snatching', label: 'Chain snatching', severity: 0.88 };
  }
  if (/(drug|narcotic|smuggling|contraband)/.test(normalized)) {
    return { category: 'drug_case', label: 'Drug-related crime', severity: 0.82 };
  }
  if (/(theft|robbery|burglary|loot|steal|snatch)/.test(normalized)) {
    return { category: 'theft', label: 'Property crime', severity: 0.72 };
  }
  if (/(assault|rape|molest|harass|kidnap|abduct|stalking|attack)/.test(normalized)) {
    return { category: 'violent_crime', label: 'Violent crime', severity: 0.94 };
  }
  if (/(lighting|street light|streetlight|dark|unlit|footfall|isolated)/.test(normalized)) {
    return { category: 'infrastructure', label: 'Lighting or footfall concern', severity: 0.58 };
  }
  if (/(police|station|hospital|clinic|petrol|fuel)/.test(normalized)) {
    return { category: 'support', label: 'Nearby support point', severity: 0.5 };
  }
  return { category: 'incident', label: 'General incident', severity: 0.45 };
}

function selectLocation(feed, item, index) {
  if (item.geo) return item.geo;
  const seed = `${feed.sourceKey}:${item.sourceId}:${index}`;
  const hash = hashString(seed);
  const bearing = hash % 360;
  const distanceMeters = 1200 + (hash % Math.max(1, feed.radiusMeters || 18000));
  return projectPoint(feed.center.lat, feed.center.lng, bearing, Math.min(distanceMeters, feed.radiusMeters || 18000));
}

async function upsertFeedItem(feed, item, index) {
  const text = `${item.title} ${item.description}`.trim();
  const classification = classifySignal(text);
  const location = selectLocation(feed, item, index);
  const sourceId = `${feed.sourceKey}:${item.sourceId || item.title || index}`;
  const confidence = item.geo ? 0.88 : Math.min(0.82, 0.52 + classification.severity * 0.25);

  await ExternalIncident.findOneAndUpdate(
    { region: nashikSafetyConfig.regionId, source: feed.sourceKey, sourceId },
    {
      region: nashikSafetyConfig.regionId,
      source: feed.sourceKey,
      sourceId,
      category: classification.category,
      description: [item.title, item.description].filter(Boolean).join(' - ').slice(0, 500),
      location: { type: 'Point', coordinates: [location.lng, location.lat] },
      occurredAt: item.occurredAt,
      confidence,
      spatialPrecision: item.geo ? 'point' : 'approximate',
      disclaimer: `Auto-ingested from ${feed.label}. Verify with the original source before acting on it.`,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
}

async function fetchFeedPayload(feed) {
  const response = await fetch(feed.url, {
    headers: {
      Accept: feed.kind === 'json' ? 'application/json' : 'application/rss+xml, application/xml, text/xml, text/html;q=0.9',
    },
  });
  if (!response.ok) {
    throw new Error(`Feed ${feed.sourceKey} returned ${response.status}`);
  }

  const contentType = response.headers.get('content-type') || '';
  if (feed.kind === 'json' || contentType.includes('application/json')) {
    return response.json();
  }
  return response.text();
}

function parseJsonFeed(payload) {
  const items = Array.isArray(payload?.items)
    ? payload.items
    : Array.isArray(payload?.articles)
    ? payload.articles
    : Array.isArray(payload?.results)
    ? payload.results
    : [];
  return items.map((item) => ({
    title: stripTags(item.title || item.headline || ''),
    link: stripTags(item.url || item.link || ''),
    description: stripTags(item.summary || item.description || item.content || ''),
    sourceId: stripTags(item.id || item.guid || item.url || item.link || item.title || ''),
    occurredAt: item.publishedAt || item.updatedAt || item.date || new Date(),
    geo: item.geo && Number.isFinite(Number(item.geo.lat)) && Number.isFinite(Number(item.geo.lng))
      ? { lat: Number(item.geo.lat), lng: Number(item.geo.lng) }
      : null,
  }));
}

async function syncSafetyNewsSignals({ force = false } = {}) {
  const feeds = loadFeedDefinitions();
  if (feeds.length === 0) {
    lastSnapshot = {
      ok: true,
      enabled: false,
      feeds: 0,
      ingested: 0,
      skipped: 0,
      errors: [],
      lastSyncAt: lastRefreshAt ? new Date(lastRefreshAt).toISOString() : null,
    };
    return lastSnapshot;
  }

  const now = Date.now();
  if (!force && now - lastRefreshAt < env.safetyNewsRefreshMs) {
    return lastSnapshot;
  }

  if (refreshPromise) {
    return refreshPromise;
  }

  refreshPromise = (async () => {
    const errors = [];
    let ingested = 0;
    let skipped = 0;

    for (const feed of feeds) {
      try {
      const payload = await fetchFeedPayload(feed);
      const entries = Array.isArray(payload)
        ? parseJsonFeed({ items: payload })
        : typeof payload === 'string'
        ? parseFeedItems(payload)
        : parseJsonFeed(payload);

        const limitedEntries = entries.slice(0, env.safetyNewsMaxItems);
        for (let index = 0; index < limitedEntries.length; index += 1) {
          const item = limitedEntries[index];
          if (!item.title && !item.description) {
            skipped += 1;
            continue;
          }
          await upsertFeedItem(feed, item, index);
          ingested += 1;
        }
      } catch (error) {
        errors.push(`${feed.sourceKey}: ${error.message}`);
      }
    }

    const snapshot = {
      ok: errors.length === 0,
      enabled: true,
      feeds: feeds.length,
      ingested,
      skipped,
      errors,
      lastSyncAt: new Date().toISOString(),
    };
    lastRefreshAt = Date.now();
    lastSnapshot = snapshot;

    if (mongoose.connection.readyState === 1) {
      await DataSourceSync.findOneAndUpdate(
        { sourceKey: DEFAULT_SOURCE_KEY },
        {
          region: nashikSafetyConfig.regionId,
          status: snapshot.ok ? 'ok' : 'error',
          lastSyncAt: new Date(snapshot.lastSyncAt),
          lastSuccessAt: snapshot.ok ? new Date(snapshot.lastSyncAt) : undefined,
          featureCount: ingested,
          message: snapshot.ok
            ? `Synced ${ingested} news feed signals from ${feeds.length} source(s)`
            : errors[0] || 'News feed sync error',
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      );
    }

    return snapshot;
  })()
    .finally(() => {
      refreshPromise = null;
    });

  return refreshPromise;
}

async function getSafetyNewsSyncStatus() {
  const current = lastSnapshot;
  return current;
}

module.exports = {
  syncSafetyNewsSignals,
  getSafetyNewsSyncStatus,
  loadFeedDefinitions,
  parseFeedItems,
  classifySignal,
  parseJsonFeed,
  parsePublishedAt,
  parseGeo,
};
