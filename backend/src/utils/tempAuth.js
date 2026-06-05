const env = require('../config/env');

const TEMP_USER_ID = 'temp-local-user';
let refreshTokenHash = null;

const isTempAuthActive = () =>
  env.tempAuthEnabled &&
  Boolean(env.tempAuthPassword && env.tempAuthPassword.trim());

const buildTempUser = () => ({
  _id: TEMP_USER_ID,
  fullName: env.tempAuthName,
  name: env.tempAuthName,
  email: env.tempAuthEmail,
  phone: env.tempAuthPhone,
  role: 'citizen',
});

const matchesTempIdentifier = (identifier) =>
  identifier === env.tempAuthEmail || identifier === env.tempAuthPhone;

module.exports = {
  TEMP_USER_ID,
  isTempAuthActive,
  buildTempUser,
  matchesTempIdentifier,
  getRefreshTokenHash: () => refreshTokenHash,
  setRefreshTokenHash: (value) => {
    refreshTokenHash = value;
  },
};
