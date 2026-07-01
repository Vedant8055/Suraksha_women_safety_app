const assert = require('assert/strict');
const request = require('supertest');

function loadApp() {
  [
    '../src/config/env',
    '../src/services/publicToiletService',
    '../src/controllers/toiletController',
    '../src/routes/safetyRoutes',
    '../src/app',
  ].forEach((modulePath) => {
    try {
      delete require.cache[require.resolve(modulePath)];
    } catch (error) {
      void error;
    }
  });
  return require('../src/app').app;
}

describe('Public toilets API', () => {
  const originalFetch = global.fetch;
  const baseUrl = 'https://sanitation.example.com';
  const apiKey = 'sanitation-test-key';

  beforeEach(() => {
    process.env.SANITATION_API_BASE_URL = baseUrl;
    process.env.SANITATION_PUBLIC_API_KEY = apiKey;
  });

  afterEach(() => {
    global.fetch = originalFetch;
    delete process.env.SANITATION_API_BASE_URL;
    delete process.env.SANITATION_PUBLIC_API_KEY;
  });

  it('returns nearby toilets sorted by distance', async () => {
    const seenRequests = [];
    global.fetch = async (url, options) => {
      seenRequests.push({ url, options });
      return {
        ok: true,
        status: 200,
        json: async () => ({
          toilets: [
            {
              id: 'PUB-TLT-2',
              name: 'Far Toilet',
              address: 'Far Lane',
              latitude: 19.999,
              longitude: 73.799,
              cleanlinessScore: 82,
              availabilityStatus: 'Open',
              facilities: { female: true, waterAvailable: true },
              lastUpdatedAt: '2026-06-30T11:20:00+05:30',
            },
            {
              id: 'PUB-TLT-1',
              name: 'Near Toilet',
              address: 'Near Lane',
              latitude: 19.9976,
              longitude: 73.7899,
              cleanlinessScore: 91,
              availabilityStatus: 'Open',
              facilities: { female: true, accessible: true, waterAvailable: true },
              lastUpdatedAt: '2026-06-30T11:10:00+05:30',
            },
          ],
        }),
      };
    };

    const res = await request(loadApp()).get('/api/safety/toilets/nearby').query({
      lat: 19.9975,
      lng: 73.7898,
    });

    assert.equal(res.status, 200);
    assert.equal(seenRequests.length, 1);
    assert.match(seenRequests[0].url, /\/api\/public\/v1\/toilets\/nearby\?/);
    assert.equal(seenRequests[0].options.headers['x-api-key'], apiKey);
    assert.ok(!seenRequests[0].url.includes('tenant_id='));
    assert.equal(res.body.toilets[0].id, 'PUB-TLT-1');
    assert.equal(res.body.toilets[0].safetyDisplayStatus, 'Recommended');
    assert.equal(res.body.meta.source, 'sanitation_platform_public_api');
  });

  it('rejects missing lat and lng', async () => {
    const res = await request(loadApp()).get('/api/safety/toilets/nearby').query({});
    assert.equal(res.status, 400);
  });

  it('rejects invalid lat and lng', async () => {
    const invalidLat = await request(loadApp()).get('/api/safety/toilets/nearby').query({
      lat: 120,
      lng: 73.7898,
    });
    assert.equal(invalidLat.status, 400);

    const invalidLng = await request(loadApp()).get('/api/safety/toilets/nearby').query({
      lat: 19.9975,
      lng: 'invalid',
    });
    assert.equal(invalidLng.status, 400);
  });

  it('rejects tenant_id from the frontend', async () => {
    const res = await request(loadApp()).get('/api/safety/toilets/nearby').query({
      lat: 19.9975,
      lng: 73.7898,
      tenant_id: 'tenant-123',
    });
    assert.equal(res.status, 400);
  });

  it('handles 401 and 403 safely', async () => {
    global.fetch = async () => ({
      ok: false,
      status: 401,
      json: async () => ({ message: 'unauthorized' }),
    });

    const res = await request(loadApp()).get('/api/safety/toilets/nearby').query({
      lat: 19.9975,
      lng: 73.7898,
    });

    assert.equal(res.status, 401);
    assert.match(res.body.message, /unavailable/i);
  });

  it('handles 429 safely', async () => {
    global.fetch = async () => ({
      ok: false,
      status: 429,
      json: async () => ({ message: 'rate limited' }),
    });

    const res = await request(loadApp()).get('/api/safety/toilets/nearby').query({
      lat: 19.9975,
      lng: 73.7898,
    });

    assert.equal(res.status, 429);
    assert.match(res.body.message, /busy/i);
  });

  it('does not expose the sanitation API key in the response', async () => {
    global.fetch = async () => ({
      ok: true,
      status: 200,
      json: async () => ({ toilets: [] }),
    });

    const res = await request(loadApp()).get('/api/safety/toilets/nearby').query({
      lat: 19.9975,
      lng: 73.7898,
    });

    assert.equal(res.status, 200);
    assert.equal(Object.prototype.hasOwnProperty.call(res.body, 'apiKey'), false);
    assert.equal(JSON.stringify(res.body).includes(apiKey), false);
  });
});
