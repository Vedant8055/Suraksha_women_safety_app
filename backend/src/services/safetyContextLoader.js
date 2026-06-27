const { queryOsmFeaturesNear } = require('./osmIngestionService');
const { getCrowdActivityNear } = require('./crowdHeatmapService');
const { fetchSunTimes } = require('./sunsetService');
const { getAreaCrimeContext, queryExternalIncidentsNear } = require('./crimeDataIngestionService');
const { getGridRiskForPoint } = require('./gridRiskModelService');
const { nashikSafetyConfig, isWithinNashik } = require('../config/nashikSafetyConfig');

function haversineMeters(lat1, lng1, lat2, lng2) {
  const toRadians = (value) => (value * Math.PI) / 180;
  const earthRadius = 6371000;
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * earthRadius * Math.asin(Math.sqrt(a));
}

async function loadExternalSignals(lat, lng, at = new Date()) {
  const inRegion = isWithinNashik(lat, lng);
  const [sunset, crowd, osmFeatures] = await Promise.all([
    fetchSunTimes(lat, lng, at),
    getCrowdActivityNear(lat, lng),
    inRegion
      ? queryOsmFeaturesNear(lat, lng, nashikSafetyConfig.queryRadii.osmFeaturesMeters * 4)
      : Promise.resolve([]),
  ]);

  const police = osmFeatures.filter((item) => item.featureType === 'police');
  const hospitals = osmFeatures.filter(
    (item) => item.featureType === 'hospital' || item.featureType === 'clinic',
  );
  const unlitRoads = osmFeatures.filter((item) => item.featureType === 'unlit_road');
  const litRoads = osmFeatures.filter((item) => item.featureType === 'lit_road');

  const nearestUnlit = unlitRoads
    .map((item) => {
      const [lngValue, latValue] = item.location?.coordinates || [];
      return {
        ...item,
        distanceMeters: haversineMeters(lat, lng, latValue, lngValue),
      };
    })
    .sort((a, b) => a.distanceMeters - b.distanceMeters)[0];

  const lightingRatio =
    litRoads.length + unlitRoads.length > 0
      ? litRoads.length / (litRoads.length + unlitRoads.length)
      : null;

  return {
    region: nashikSafetyConfig.regionId,
    regionLabel: nashikSafetyConfig.regionLabel,
    inRegion,
    sunset,
    crowd,
    osm: {
      source: 'openstreetmap',
      policeCount: police.length,
      hospitalCount: hospitals.length,
      unlitRoadCount: unlitRoads.length,
      litRoadCount: litRoads.length,
      nearestUnlitDistanceMeters: nearestUnlit ? Math.round(nearestUnlit.distanceMeters) : null,
      lightingRatio,
      features: osmFeatures,
      disclaimer: 'Infrastructure data from OpenStreetMap contributors. May be incomplete.',
    },
    gridRisk: await getGridRiskForPoint(lat, lng),
    areaCrime: await getAreaCrimeContext(),
    externalIncidents: inRegion ? await queryExternalIncidentsNear(lat, lng) : [],
  };
}

module.exports = { loadExternalSignals, haversineMeters };
