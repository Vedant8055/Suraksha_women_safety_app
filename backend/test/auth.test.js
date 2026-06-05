const request = require('supertest');
const express = require('express');
const mongoose = require('mongoose');
const { app } = require('../src/app');
const User = require('../src/models/User');

describe('Auth API', () => {
  before(async function setupDatabase() {
    const mongoUri = process.env.TEST_MONGO_URI || 'mongodb://127.0.0.1/suraksha_test';
    try {
      await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 2000 });
    } catch (error) {
      this.skip();
    }
  });

  after(async () => {
    if (mongoose.connection.readyState !== 1) {
      return;
    }

    await User.deleteMany({});
    await mongoose.connection.close();
  });

  it('registers a new user', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '1234567890',
        password: 'password123',
      });

    if (res.status !== 201) {
      throw new Error(`Expected 201, received ${res.status}: ${JSON.stringify(res.body)}`);
    }
  });

  it('does not register user with duplicate phone', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        fullName: 'Test User',
        email: 'another@example.com',
        phone: '1234567890',
        password: 'password123',
      });

    if (res.status !== 409) {
      throw new Error(`Expected 409, received ${res.status}: ${JSON.stringify(res.body)}`);
    }
  });
});
