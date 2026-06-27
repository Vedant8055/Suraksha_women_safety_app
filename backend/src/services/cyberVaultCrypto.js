const crypto = require('crypto');
const fs = require('fs');
const env = require('../config/env');

function vaultKey() {
  return crypto.createHash('sha256').update(env.jwtSecret).digest();
}

function encryptBuffer(input) {
  const key = vaultKey();
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(input), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return Buffer.concat([iv, authTag, encrypted]);
}

function decryptFile(encryptedPath) {
  const payload = fs.readFileSync(encryptedPath);
  const iv = payload.subarray(0, 12);
  const authTag = payload.subarray(12, 28);
  const encrypted = payload.subarray(28);
  const decipher = crypto.createDecipheriv('aes-256-gcm', vaultKey(), iv);
  decipher.setAuthTag(authTag);
  return Buffer.concat([decipher.update(encrypted), decipher.final()]);
}

module.exports = {
  encryptBuffer,
  decryptFile,
};
