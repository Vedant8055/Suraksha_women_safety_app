const request = require('supertest');
const { app } = require('../src/app');

describe('Cyber Crime Protection API', () => {
  it('returns learning content without authentication', async () => {
    const res = await request(app).get('/api/cybercrime/learning/content');

    if (res.status !== 200) {
      throw new Error(`Expected 200, received ${res.status}: ${JSON.stringify(res.body)}`);
    }
    if (!Array.isArray(res.body) || res.body.length === 0) {
      throw new Error('Expected learning content list');
    }
  });

  it('returns deepfake resources without authentication', async () => {
    const res = await request(app).get('/api/cybercrime/deepfake/resources');

    if (res.status !== 200) {
      throw new Error(`Expected 200, received ${res.status}: ${JSON.stringify(res.body)}`);
    }
    if (!res.body.title || !Array.isArray(res.body.sections)) {
      throw new Error('Expected deepfake resource payload');
    }
  });

  it('protects scam analysis behind authentication', async () => {
    const res = await request(app)
      .post('/api/cybercrime/assistant/analyze')
      .send({ text: 'share otp urgently', links: [] });

    if (res.status !== 401) {
      throw new Error(`Expected 401, received ${res.status}: ${JSON.stringify(res.body)}`);
    }
  });
});
