const safetyIntelligenceConfig = {
  aiConfidenceDisplayThreshold: 70,
  scoring: {
    baseSafetyScore: 76,
    timeOfDayPenalty: 16,
    weekendNightPenalty: 6,
    lowAccuracyPenalty: 8,
    incidentDensityPenalty: 28,
    recentVerifiedIncidentPenalty: 24,
    sparseEmergencySupportPenalty: 12,
    safeSupportBonus: 14,
    communitySafeRouteBonus: 8,
    isolationPenalty: 12,
  },
  radii: {
    authorityMeters: 3000,
    incidentMeters: 2500,
    safetyZoneMeters: 2200,
    resourceMeters: 5000,
  },
  decay: {
    incidentHalfLifeHours: 72,
    staleIncidentCutoffHours: 24 * 30,
  },
  upcomingRisk: {
    minIncreaseForAlert: 14,
    lookaheadMeters: 450,
  },
  heatmap: {
    tileSpacingMeters: 180,
    radius: 1,
  },
  routeProfiles: [
    {
      id: 'fastest',
      label: 'Fastest Route',
      pacePenaltyFactor: 0.0,
      supportBonusFactor: 0.75,
      bufferFactor: 0.85,
    },
    {
      id: 'safest',
      label: 'Safest Route',
      badge: 'Recommended',
      pacePenaltyFactor: 0.25,
      supportBonusFactor: 1.15,
      bufferFactor: 1.2,
    },
    {
      id: 'balanced',
      label: 'Balanced Route',
      pacePenaltyFactor: 0.12,
      supportBonusFactor: 1.0,
      bufferFactor: 1.0,
    },
  ],
};

module.exports = { safetyIntelligenceConfig };
