const request = require('supertest');
const { expect } = require('chai');
const express = require('express');
const mongoose = require('mongoose');
const authRoutes = require('../routes/authRoutes');
const User = require('../models/User');

const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);

describe('Auth API', () => {
  before(async () => {
    const url = 'mongodb://127.0.0.1/suraksha_test';
    await mongoose.connect(url);
  });

  after(async () => {
    await User.deleteMany({});
    await mongoose.connection.close();
  });

  it('should register a new user', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Test User',
        email: 'test@example.com',
        phone: '1234567890',
        password: 'password123'
      });

    expect(res.status).to.equal(201);
    expect(res.body).to.have.property('token');
  });

  it('should not register user with existing email', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Test User',
        email: 'test@example.com',
        phone: '0987654321',
        password: 'password123'
      });

    expect(res.status).to.equal(400);
  });
});
