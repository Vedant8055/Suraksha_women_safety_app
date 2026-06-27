const nashikCrimeBaseline = {
  district: 'Nashik',
  state: 'Maharashtra',
  periodType: 'yearly',
  periodLabel: '2023',
  totalIncidents: 8420,
  populationEstimate: 6100000,
  ratePer100k: 138,
  categoryBreakdown: {
    theft: 2840,
    assault: 920,
    harassment: 760,
    robbery: 540,
    fraud: 680,
    other: 2680,
  },
  sources: ['data.gov.in (Maharashtra crime statistics aggregate)', 'NCRB district-level reference'],
  disclaimer:
    'District-level crime statistics for Nashik. Used for area context only—not precise GPS alerts. Official police records may differ.',
};

module.exports = { nashikCrimeBaseline };
