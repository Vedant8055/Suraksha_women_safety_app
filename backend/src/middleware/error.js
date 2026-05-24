const { ZodError } = require('zod');

const errorHandler = (err, req, res, next) => {
  const status = err.statusCode || 500;
  if (err instanceof ZodError) {
    return res.status(400).json({ message: 'Validation failed', details: err.flatten() });
  }
  return res.status(status).json({ message: err.message || 'Internal Server Error', details: err.details || undefined });
};

module.exports = { errorHandler };
