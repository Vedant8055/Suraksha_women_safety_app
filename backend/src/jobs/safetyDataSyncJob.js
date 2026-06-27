const { syncNashikOsmData } = require('../services/osmIngestionService');
const { syncNashikCrimeData } = require('../services/crimeDataIngestionService');
const { nashikSafetyConfig } = require('../config/nashikSafetyConfig');

let intervalHandle = null;
let bootTimeout = null;

function startSafetyDataSyncJob() {
  if (intervalHandle) return;

  const runSync = async () => {
    const [osmResult, crimeResult] = await Promise.all([
      syncNashikOsmData(),
      syncNashikCrimeData(),
    ]);
    if (!osmResult.ok) {
      console.warn('[safety-sync] OSM sync failed:', osmResult.message);
    } else {
      console.log(`[safety-sync] OSM sync ok (${osmResult.featureCount} features)`);
    }
    if (!crimeResult.ok) {
      console.warn('[safety-sync] Crime sync failed');
    } else {
      console.log('[safety-sync] Crime/open-data sync ok');
    }
  };

  bootTimeout = setTimeout(() => {
    void runSync();
  }, 2000);
  intervalHandle = setInterval(
    runSync,
    nashikSafetyConfig.osmSyncIntervalHours * 60 * 60 * 1000,
  );
}

function stopSafetyDataSyncJob() {
  if (bootTimeout) clearTimeout(bootTimeout);
  if (intervalHandle) clearInterval(intervalHandle);
  bootTimeout = null;
  intervalHandle = null;
}

module.exports = { startSafetyDataSyncJob, stopSafetyDataSyncJob };
