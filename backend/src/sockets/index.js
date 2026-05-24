const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const env = require('../config/env');
const { createSos } = require('../services/sosService');
const { addLiveLocation } = require('../services/locationService');

const setupSockets = (httpServer) => {
  const io = new Server(httpServer, { cors: { origin: env.clientOrigins.length ? env.clientOrigins : '*', methods: ['GET', 'POST'] } });

  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      const payload = jwt.verify(token, env.jwtSecret);
      socket.user = { id: payload.sub, role: payload.role };
      next();
    } catch {
      next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    socket.on('trigger_sos', async (payload) => {
      const sos = await createSos({ userId: socket.user.id, lat: payload.lat, lng: payload.lng, mode: payload.mode || 'normal' });
      io.emit('emergency_alert', { eventId: sos._id, userId: socket.user.id, lat: payload.lat, lng: payload.lng });
    });

    socket.on('update_location', async (payload) => {
      await addLiveLocation({ userId: socket.user.id, lat: payload.lat, lng: payload.lng, sosEventId: payload.sosEventId });
      io.emit('live_location_update', { userId: socket.user.id, lat: payload.lat, lng: payload.lng });
    });

    socket.on('cancel_sos', (payload) => {
      io.emit('sos_resolved', { userId: socket.user.id, sosEventId: payload?.sosEventId || null });
    });
  });

  return io;
};

module.exports = { setupSockets };
