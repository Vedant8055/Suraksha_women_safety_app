const notFound = (req, res, next) => {
  const error = new Error(`Route not found: ${req.originalUrl}`);
  error.statusCode = 404;
  next(error);
};

const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || res.statusCode || 500;
  const safeStatusCode = statusCode >= 400 ? statusCode : 500;

  if (safeStatusCode >= 500) {
    console.error(err);
  }

  const response = {
    message:
      safeStatusCode >= 500 && process.env.NODE_ENV === 'production'
        ? 'Internal server error'
        : err.message || 'Internal server error',
  };

  if (err.details) {
    response.details = err.details;
  }

  res.status(safeStatusCode).json(response);
};

module.exports = {
  notFound,
  errorHandler,
};
