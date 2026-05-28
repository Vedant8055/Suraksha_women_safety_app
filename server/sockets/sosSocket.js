const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const SOSEvent = require('../models/SOSEvent');
const User = require('../models/User');
const env = require('../config/env');

const extractSocketToken = (socket) => {
  const authToken = socket.handshake.auth?.token;
  if (authToken) {
    return authToken;
  }

  const authorizationHeader = socket.handshake.headers?.authorization;
  if (authorizationHeader?.startsWith('Bearer ')) {
    return authorizationHeader.split(' ')[1];
  }

  return null;
};

module.exports = (io) => {
  const isValidCoordinate = (value, min, max) =>
    typeof value === 'number' && Number.isFinite(value) && value >= min && value <= max;

  const parseLocationPayload = (payload = {}) => {
    const lat = Number(payload.lat);
    const lng = Number(payload.lng);

    if (!isValidCoordinate(lat, -90, 90) || !isValidCoordinate(lng, -180, 180)) {
      return null;
    }

    return { lat, lng };
  };

  io.use(async (socket, next) => {
    try {
      const token = extractSocketToken(socket);
      if (!token) {
        return next(new Error('Authentication required'));
      }

      const decoded = jwt.verify(token, env.jwtSecret);
      const user = await User.findById(decoded.id).select('_id');
      if (!user) {
        return next(new Error('User not found'));
      }

      socket.user = { id: user._id.toString() };
      return next();
    } catch (error) {
      return next(new Error('Authentication failed'));
    }
  });

  io.on('connection', (socket) => {
    socket.join(`user:${socket.user.id}`);

    socket.on('join_sos', () => {
      socket.join(`sos:${socket.user.id}`);
    });

    socket.on('trigger_sos', async (data) => {
      const location = parseLocationPayload(data);
      if (!location) {
        socket.emit('sos_error', { message: 'Invalid SOS location payload.' });
        return;
      }

      const { lat, lng } = location;
      const userId = socket.user.id;

      try {
        const sosEvent = data?.sosEventId
          ? await SOSEvent.findOne({ _id: data.sosEventId, userId })
          : await SOSEvent.create({
              userId,
              shareToken: crypto.randomBytes(18).toString('hex'),
              location: { lat, lng },
              liveTracking: [{ lat, lng }],
            });

        // Broadcast to emergency contacts/responders
        socket.broadcast.emit('emergency_alert', {
          eventId: sosEvent?._id || data?.sosEventId,
          userId,
          lat,
          lng
        });
      } catch (err) {
        console.error('Error creating SOS event:', err);
        socket.emit('sos_error', { message: 'Failed to trigger SOS alert.' });
      }
    });

    socket.on('update_location', async (data) => {
      const location = parseLocationPayload(data);
      if (!location) {
        socket.emit('sos_error', { message: 'Invalid location update payload.' });
        return;
      }

      const { lat, lng } = location;
      const userId = socket.user.id;

      try {
        const query = data?.sosEventId
          ? { _id: data.sosEventId, userId }
          : { userId, status: 'active' };
        await SOSEvent.findOneAndUpdate(
          query,
          {
            $push: {
              liveTracking: {
                lat,
                lng,
                timestamp: new Date(),
              },
            },
          },
          { sort: { createdAt: -1 } }
        );
      } catch (err) {
        console.error('Error updating live location:', err);
      }

      socket.broadcast.emit('live_location_update', { userId, lat, lng });
    });

    socket.on('cancel_sos', async () => {
      const userId = socket.user.id;

      try {
        await SOSEvent.findOneAndUpdate(
          { userId, status: 'active' },
          {
            status: 'cancelled',
            resolvedAt: new Date(),
          },
          { sort: { createdAt: -1 } }
        );
      } catch (err) {
        console.error('Error cancelling SOS event:', err);
      }

      socket.broadcast.emit('sos_resolved', { userId });
    });
  });
};
