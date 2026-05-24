const { asyncHandler } = require('../utils/asyncHandler');
const Notification = require('../models/Notification');

const listNotifications = asyncHandler(async (req, res) => {
  const items = await Notification.find({ userId: req.user._id }).sort({ createdAt: -1 }).limit(50);
  res.json(items);
});

module.exports = { listNotifications };
