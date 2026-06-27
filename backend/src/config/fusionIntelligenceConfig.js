const fusionIntelligenceConfig = {
  modelVersion: 'grid-stat-v1',
  dimensionWeights: {
    crime: 0.3,
    infrastructure: 0.2,
    support: 0.2,
    visibility: 0.15,
    temporal: 0.15,
  },
  gridPrecision: 2,
  cacheTtlSeconds: 300,
  routeSampleIntervalMeters: 120,
  minIncidentsForGridElevation: 3,
  nashikBaselineIncidentsPerCell30d: 0.8,
  sourceTrust: {
    suraksha_reports: 0.95,
    openstreetmap: 0.82,
    crowd_aggregate: 0.7,
    sunset_api: 0.88,
    open_data_district: 0.55,
    open_data_point: 0.72,
  },
};

module.exports = { fusionIntelligenceConfig };
