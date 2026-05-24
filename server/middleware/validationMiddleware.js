const createValidationError = (message, details) => {
  const error = new Error(message);
  error.statusCode = 400;
  error.details = details;
  return error;
};

const requireFields = (fields) => (req, res, next) => {
  const missingFields = fields.filter((field) => {
    const value = req.body[field];
    return value === undefined || value === null || `${value}`.trim() === '';
  });

  if (missingFields.length > 0) {
    return next(
      createValidationError('Missing required fields', { missingFields })
    );
  }

  next();
};

const validateRegister = (req, res, next) => {
  const { name, email, phone, password } = req.body;

  if (!name || !email || !phone || !password) {
    return next(
      createValidationError('Name, email, phone, and password are required.')
    );
  }

  if (!email.includes('@')) {
    return next(createValidationError('Please provide a valid email address.'));
  }

  if (`${password}`.length < 8) {
    return next(
      createValidationError('Password must be at least 8 characters long.')
    );
  }

  next();
};

const validateLogin = (req, res, next) => {
  const { identifier, password } = req.body;

  if (!identifier || !password) {
    return next(
      createValidationError('Identifier and password are required.')
    );
  }

  next();
};

const validateRefreshToken = (req, res, next) => {
  const { refreshToken } = req.body;

  if (!refreshToken || `${refreshToken}`.trim() === '') {
    return next(createValidationError('Refresh token is required.'));
  }

  next();
};

const validateCyberCrimeReport = (req, res, next) => {
  const { category, description, evidenceUrls } = req.body;
  const allowedCategories = [
    'Financial Fraud',
    'Cyber Stalking',
    'Online Bullying',
    'Identity Theft',
    'Social Media Harassment',
  ];

  if (!category || !description) {
    return next(
      createValidationError('Category and description are required.')
    );
  }

  if (!allowedCategories.includes(category)) {
    return next(
      createValidationError('Invalid cybercrime category provided.')
    );
  }

  if (evidenceUrls && !Array.isArray(evidenceUrls)) {
    return next(
      createValidationError('Evidence URLs must be provided as an array.')
    );
  }

  next();
};

module.exports = {
  requireFields,
  validateRegister,
  validateLogin,
  validateRefreshToken,
  validateCyberCrimeReport,
};
