const path = require('path');

const backendRoot = path.resolve(__dirname, '..', '..');
const srcRoot = path.join(backendRoot, 'src');
const uploadsRoot = path.join(backendRoot, 'uploads');
const tempUploadsRoot = path.join(uploadsRoot, 'tmp');
const cyberVaultRoot = path.join(uploadsRoot, 'cyber-vault');

module.exports = {
  backendRoot,
  srcRoot,
  uploadsRoot,
  tempUploadsRoot,
  cyberVaultRoot,
};
