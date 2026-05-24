const Notification = require('../models/Notification');

const createNotification = ({ userId, title, body, type = 'general', metadata = {} }) =>
  Notification.create({ userId, title, body, type, metadata });

module.exports = { createNotification };
