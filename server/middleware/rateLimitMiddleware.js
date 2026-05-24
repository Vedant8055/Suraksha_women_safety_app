const createRateLimiter = ({ windowMs, max, message }) => {
  const requests = new Map();

  return (req, res, next) => {
    const now = Date.now();
    const key = req.ip || req.socket.remoteAddress || 'unknown';
    const entry = requests.get(key);

    if (!entry || now > entry.resetAt) {
      requests.set(key, { count: 1, resetAt: now + windowMs });
      return next();
    }

    if (entry.count >= max) {
      const retryAfterSeconds = Math.ceil((entry.resetAt - now) / 1000);
      res.set('Retry-After', `${retryAfterSeconds}`);
      return res.status(429).json({ message });
    }

    entry.count += 1;
    return next();
  };
};

module.exports = {
  createRateLimiter,
};
