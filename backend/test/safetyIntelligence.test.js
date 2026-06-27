const request = require('supertest');
const { app } = require('../src/app');

describe('Safety Intelligence API — Phase 1 Nashik', () => {
  const nashikLat = 19.9975;
  const nashikLng = 73.7898;

  it('returns health payload with Nashik region metadata', async () => {
    const res = await request(app).get('/api/safety-intelligence/health');

    if (res.status !== 200) {
      throw new Error(`Expected 200, received ${res.status}: ${JSON.stringify(res.body)}`);
    }
    if (res.body.region !== 'Nashik' || res.body.regionId !== 'nashik') {
      throw new Error('Expected Nashik region metadata');
    }
    if (!res.body.dataDisclaimer || !res.body.sources) {
      throw new Error('Expected disclaimer and source health');
    }
  });

  it('returns live assessment with sourced community alerts', async () => {
    const res = await request(app).get('/api/safety-intelligence/live').query({
      lat: nashikLat,
      lng: nashikLng,
      accuracy: 12,
    });

    if (res.status !== 200) {
      throw new Error(`Expected 200, received ${res.status}: ${JSON.stringify(res.body)}`);
    }
    if (!Array.isArray(res.body.communityAlerts) || res.body.communityAlerts.length === 0) {
      throw new Error('Expected community alerts array');
    }
    const first = res.body.communityAlerts[0];
    if (!first.dataSource || typeof first.confidence !== 'number') {
      throw new Error('Expected dataSource and confidence on alerts');
    }
    if (!res.body.meta?.dataDisclaimer || res.body.meta?.region !== 'Nashik') {
      throw new Error('Expected Nashik meta disclaimer');
    }
    const dimensions = res.body.current?.dimensions;
    if (!Array.isArray(dimensions) || dimensions.length < 5) {
      throw new Error('Expected fusion dimension breakdown');
    }
    if (!res.body.meta?.fusion?.modelVersion) {
      throw new Error('Expected fusion model version in meta');
    }
  });

  it('accepts anonymous location pings inside Nashik', async () => {
    const res = await request(app)
      .post('/api/safety-intelligence/pings')
      .send({ lat: nashikLat, lng: nashikLng });

    if (res.status !== 200) {
      throw new Error(`Expected 200, received ${res.status}: ${JSON.stringify(res.body)}`);
    }
    if (res.body.accepted === true) {
      return;
    }
    if (res.body.accepted === false && res.body.reason === 'database_unavailable') {
      return;
    }
    throw new Error(`Expected accepted ping, got ${JSON.stringify(res.body)}`);
  });

  it('rejects anonymous pings outside Nashik bbox', async () => {
    const res = await request(app)
      .post('/api/safety-intelligence/pings')
      .send({ lat: 28.6139, lng: 77.209 });

    if (res.status !== 200) {
      throw new Error(`Expected 200, received ${res.status}: ${JSON.stringify(res.body)}`);
    }
    if (res.body.accepted !== false || res.body.reason !== 'outside_nashik_region') {
      throw new Error('Expected outside region rejection');
    }
  });
});

describe('Safety Intelligence API — Phase 3 Live Experience', () => {
  const nashikLat = 19.9975;
  const nashikLng = 73.7898;

  it('returns AI summary when includeSummary=true on live assessment', async () => {
    const res = await request(app).get('/api/safety-intelligence/live').query({
      lat: nashikLat,
      lng: nashikLng,
      includeSummary: true,
      lang: 'en',
    });

    if (res.status !== 200) {
      throw new Error(`Expected 200, received ${res.status}: ${JSON.stringify(res.body)}`);
    }
    const summary = res.body.current?.aiSummary;
    if (!summary || typeof summary.summary !== 'string' || !summary.source) {
      throw new Error('Expected aiSummary with summary text and source');
    }
  });

  it('returns grounded summary from POST /summary', async () => {
    const res = await request(app)
      .post('/api/safety-intelligence/summary')
      .send({ lat: nashikLat, lng: nashikLng, lang: 'en' });

    if (res.status !== 200) {
      throw new Error(`Expected 200, received ${res.status}: ${JSON.stringify(res.body)}`);
    }
    if (!res.body.aiSummary?.summary || !res.body.safetyScore) {
      throw new Error('Expected aiSummary and safetyScore in summary response');
    }
  });

  it('requires auth for journey update and preferences', async () => {
    const journeyRes = await request(app)
      .post('/api/safety-intelligence/journey/update')
      .send({ lat: nashikLat, lng: nashikLng });

    if (journeyRes.status !== 401) {
      throw new Error(`Expected 401 for journey update, got ${journeyRes.status}`);
    }

    const prefsRes = await request(app).get('/api/safety-intelligence/preferences');
    if (prefsRes.status !== 401) {
      throw new Error(`Expected 401 for preferences, got ${prefsRes.status}`);
    }
  });
});
