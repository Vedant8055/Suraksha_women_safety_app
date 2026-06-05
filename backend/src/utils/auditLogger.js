const safeStringify = (value) => {
  try {
    return JSON.stringify(value);
  } catch (error) {
    return '"[unserializable]"';
  }
};

const auditLog = ({ action, userId = null, ip = null, status = 'success', metadata = {} }) => {
  const payload = {
    timestamp: new Date().toISOString(),
    action,
    userId,
    ip,
    status,
    metadata,
  };

  console.info(`[AUDIT] ${safeStringify(payload)}`);
};

module.exports = {
  auditLog,
};
