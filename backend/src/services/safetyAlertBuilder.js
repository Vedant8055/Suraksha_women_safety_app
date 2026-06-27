const { nashikSafetyConfig } = require('../config/nashikSafetyConfig');

function makeAlert({
  category,
  priority,
  distanceMeters,
  timestamp,
  summary,
  recommendedAction,
  dataSource,
  confidence,
  disclaimer,
  riskReasons,
  verdictHeadline,
}) {
  return {
    category,
    priority,
    distanceMeters,
    timestamp: timestamp instanceof Date ? timestamp.toISOString() : timestamp,
    summary,
    recommendedAction,
    dataSource,
    ...(confidence != null ? { confidence: Math.round(confidence) } : {}),
    ...(disclaimer ? { disclaimer } : {}),
    ...(Array.isArray(riskReasons) && riskReasons.length
      ? { riskReasons }
      : {}),
    ...(verdictHeadline ? { verdictHeadline } : {}),
  };
}

function humanizeRiskReasons(analysis) {
  const cautionFactors = analysis?.signalSnapshot?.cautionFactors || [];
  const reasons = [];
  const seen = new Set();

  const add = (reason) => {
    const trimmed = String(reason || '').trim();
    if (!trimmed || seen.has(trimmed)) return;
    seen.add(trimmed);
    reasons.push(trimmed);
  };

  for (const factor of cautionFactors) {
    const text = String(factor).toLowerCase();
    if (/(drug|narcotic)/.test(text)) add('Recent drug-related activity reported in this area.');
    else if (/(snatch|chain)/.test(text)) add('Chain-snatching cases have been reported nearby.');
    else if (/(theft|robbery|steal)/.test(text)) add('This stretch is known for theft-related incidents.');
    else if (/(harass|molest|assault)/.test(text)) add('Harassment or assault reports have been recorded nearby.');
    else if (/(lighting|lit|dark|visibility after sunset)/.test(text)) add('Poor street lighting may reduce visibility here.');
    else if (/(pedestrian|footfall|crowd|poi visibility)/.test(text)) add('Low pedestrian activity makes this area feel isolated.');
    else if (/(incident|crime|grid model|elevated risk)/.test(text)) add('Incident activity remains elevated in the surrounding area.');
    else if (/(emergency support|police|hospital)/.test(text)) add('Limited nearby emergency support points may slow rapid assistance.');
    else if (/(late-night|night|after sunset)/.test(text)) add('Night-time conditions reduce visibility and public activity.');
    else add(factor);
  }

  for (const dimension of analysis?.dimensions || []) {
    if ((dimension.score ?? 100) >= 55) continue;
    if (dimension.key === 'crime') add('Crime-related signals are elevated near this location.');
    else if (dimension.key === 'infrastructure') add('Poor street lighting may reduce visibility here.');
    else if (dimension.key === 'support') add('Limited nearby emergency support points may slow rapid assistance.');
    else if (dimension.key === 'visibility') add('Low pedestrian activity makes this area feel isolated.');
    else if (dimension.key === 'temporal') add('Night-time conditions reduce visibility and public activity.');
  }

  return reasons.slice(0, 6);
}

function areaVerdictCopy(score) {
  if (score >= 75) {
    return {
      headline: 'Generally safe',
      summary:
        'This area feels generally safe right now based on your live location.',
    };
  }
  if (score >= 55) {
    return {
      headline: 'Use caution',
      summary:
        'Use extra caution here—some risk signals were detected nearby.',
    };
  }
  return {
    headline: 'Higher concern',
    summary:
      'This area may not feel safe right now, especially for women and elderly users.',
  };
}

function summarizeIncident(incident) {
  if (incident.category) {
    return `${incident.category} report recorded nearby`;
  }
  return 'Recent verified incident recorded nearby';
}

function buildCommunityAlerts({ analysis, context, at, upcomingRisk, external }) {
  const alerts = [];
  const sunset = external?.sunset || {};
  const osm = external?.osm || {};
  const crowd = external?.crowd || {};
  const { signalSnapshot } = analysis;
  const topIncident = context.incidents?.[0];
  const isDark = sunset.isDark === true;
  const hour = at.getHours();
  const isLateNight = hour >= 23 || hour < 5;

  if (upcomingRisk) {
    alerts.push(
      makeAlert({
        category: 'Upcoming Risk Zone',
        priority: 'critical',
        distanceMeters: upcomingRisk.distanceMeters,
        timestamp: at,
        summary: upcomingRisk.summary,
        recommendedAction: upcomingRisk.recommendedAction,
        dataSource: 'suraksha_engine',
        confidence: analysis.aiConfidence,
        disclaimer: nashikSafetyConfig.dataDisclaimer,
      }),
    );
  }

  if (topIncident) {
    alerts.push(
      makeAlert({
        category: 'Verified Incident Report',
        priority: signalSnapshot.recentIncidentCount > 1 ? 'critical' : 'caution',
        distanceMeters: 700,
        timestamp: topIncident.createdAt,
        summary: `${summarizeIncident(topIncident)} Reported within the last 72 hours near your location in ${nashikSafetyConfig.regionLabel}.`,
        recommendedAction:
          'Keep belongings close, avoid phone use in isolated spots, and stay aware.',
        dataSource: 'suraksha_reports',
        confidence: Math.min(92, 55 + signalSnapshot.recentIncidentCount * 12),
        disclaimer: 'Based on verified Suraksha user incident reports. Not official police records.',
      }),
    );
  } else {
    alerts.push(
      makeAlert({
        category: 'Area Incident Status',
        priority: 'information',
        distanceMeters: 500,
        timestamp: at,
        summary: `No verified Suraksha incident reports in the last 72 hours near this location in ${nashikSafetyConfig.regionLabel}.`,
        recommendedAction:
          'No recent app-reported incidents nearby. Continue monitoring and stay alert in low-traffic zones.',
        dataSource: 'suraksha_reports',
        confidence: 62,
        disclaimer: 'Absence of app reports does not guarantee zero crime. Official data may differ.',
      }),
    );
  }

  if (isDark) {
    const unlitNearby = osm.nearestUnlitDistanceMeters;
    const hasOsmLighting = osm.unlitRoadCount > 0 || osm.litRoadCount > 0;
    const sunsetLabel = sunset.source === 'sunset_api' ? 'after civil twilight' : 'during night hours';

    alerts.push(
      makeAlert({
        category: 'Road Lighting',
        priority:
          hasOsmLighting && unlitNearby != null && unlitNearby < 350
            ? 'critical'
            : isLateNight
            ? 'critical'
            : 'caution',
        distanceMeters: unlitNearby ?? 300,
        timestamp: at,
        summary: hasOsmLighting
          ? unlitNearby != null && unlitNearby < 600
            ? `OpenStreetMap shows unlit road segments within ${unlitNearby} m. Conditions are ${sunsetLabel}.`
            : `OpenStreetMap lighting tags suggest mostly lit corridors nearby. Reduced visibility still applies ${sunsetLabel}.`
          : `It is dark ${sunsetLabel} in ${nashikSafetyConfig.regionLabel}. Street lighting data is limited for this stretch.`,
        recommendedAction:
          'Stay on well-lit main roads. Use torch if needed and avoid shadowed paths.',
        dataSource: hasOsmLighting ? 'openstreetmap' : 'sunset_api',
        confidence: hasOsmLighting ? 78 : sunset.source === 'sunset_api' ? 70 : 45,
        disclaimer:
          osm.disclaimer ||
          'Lighting inferred from sunset times. OSM road lighting tags may be incomplete.',
      }),
    );
  }

  if (crowd.available || crowd.totalPings2h > 0) {
    const level = crowd.activityLevel || 'unknown';
    alerts.push(
      makeAlert({
        category: 'Crowd Activity',
        priority:
            level === 'very_low' && isDark
            ? 'caution'
            : level === 'high'
            ? 'information'
            : 'information',
        distanceMeters: 250,
        timestamp: at,
        summary:
          level === 'high'
            ? `Elevated anonymous app activity nearby (${crowd.totalPings2h} pings in 2 h across ${crowd.nearbyCells} cells).`
            : level === 'moderate'
            ? `Moderate anonymous app activity nearby (${crowd.totalPings2h} pings in 2 h).`
            : level === 'very_low'
            ? 'Very low anonymous app activity detected nearby in the last 2 hours.'
            : `Low anonymous app activity nearby (${crowd.totalPings2h} pings in 2 h).`,
        recommendedAction:
          level === 'very_low' && isDark
            ? 'Fewer people may be around. Prefer populated, well-lit routes.'
            : 'Crowd patterns are one signal among many—stay situationally aware.',
        dataSource: 'crowd_aggregate',
        confidence: crowd.confidence || 50,
        disclaimer: crowd.disclaimer,
      }),
    );
  }

  const gridRisk = analysis.gridRisk || external?.gridRisk;
  if (gridRisk && (gridRisk.elevationFactor >= 0.35 || gridRisk.count7d > 0)) {
    alerts.push(
      makeAlert({
        category: 'Grid Risk Model',
        priority: gridRisk.score < 45 ? 'critical' : gridRisk.score < 60 ? 'caution' : 'information',
        distanceMeters: 0,
        timestamp: at,
        summary: `${gridRisk.label} for this ~1 km grid (${gridRisk.count30d} incident(s) in 30d, ${gridRisk.count7d} in 7d).`,
        recommendedAction:
          gridRisk.score < 55
            ? 'Historical incident patterns in this grid are elevated—stay alert and prefer main roads.'
            : 'Grid history is moderate. Continue monitoring live alerts.',
        dataSource: 'grid_model',
        confidence: gridRisk.confidence || 50,
        disclaimer: gridRisk.disclaimer,
      }),
    );
  }

  const areaCrime = external?.areaCrime;
  if (areaCrime?.ratePer100k) {
    alerts.push(
      makeAlert({
        category: 'District Crime Context',
        priority: 'information',
        distanceMeters: 0,
        timestamp: at,
        summary: `Nashik district open-data reference (${areaCrime.periodLabel}): ~${areaCrime.ratePer100k} reported incidents per 100k population. Area-level context only.`,
        recommendedAction:
          'Use this as regional background—not a live pinpoint crime alert for your exact location.',
        dataSource: 'open_data_district',
        confidence: 55,
        disclaimer: areaCrime.disclaimer,
      }),
    );
  }

  const osmPolice = osm.policeCount ?? 0;
  const osmHospitals = osm.hospitalCount ?? 0;
  if (osmPolice > 0 || osmHospitals > 0) {
    alerts.push(
      makeAlert({
        category: 'Emergency Infrastructure',
        priority: signalSnapshot.sparsePublicSupport ? 'caution' : 'information',
        distanceMeters: 600,
        timestamp: at,
        summary: `OpenStreetMap lists ${osmPolice} police and ${osmHospitals} hospital/clinic features within ${Math.round(nashikSafetyConfig.queryRadii.osmFeaturesMeters / 100) / 10} km of you.`,
        recommendedAction: signalSnapshot.sparsePublicSupport
          ? 'Emergency support is sparse here. Keep SOS armed and share live location.'
          : 'Mapped emergency infrastructure is available nearby if needed.',
        dataSource: 'openstreetmap',
        confidence: 75,
        disclaimer: osm.disclaimer,
      }),
    );
  } else if (signalSnapshot.sparsePublicSupport) {
    alerts.push(
      makeAlert({
        category: 'Emergency Infrastructure',
        priority: 'caution',
        distanceMeters: 1000,
        timestamp: at,
        summary:
          'Limited mapped police, hospital, or responder coverage near this location in Nashik.',
        recommendedAction:
          'Keep SOS armed. Inform an emergency contact of your location before moving further.',
        dataSource: 'suraksha_engine',
        confidence: 58,
        disclaimer: 'Derived from Suraksha + OpenStreetMap coverage. May not list all facilities.',
      }),
    );
  }

  if (signalSnapshot.safeZoneCount > 0) {
    alerts.push(
      makeAlert({
        category: 'Community Safe Route',
        priority: 'information',
        distanceMeters: 400,
        timestamp: at,
        summary: `${signalSnapshot.safeZoneCount} community-verified safe corridor${signalSnapshot.safeZoneCount > 1 ? 's are' : ' is'} identified near your route.`,
        recommendedAction: 'Open the Safety Map to follow the highlighted community-verified path.',
        dataSource: 'suraksha_community',
        confidence: 72,
      }),
    );
  }

  const areaVerdict = areaVerdictCopy(analysis.safetyScore);
  const areaRiskReasons = humanizeRiskReasons(analysis);

  alerts.push(
    makeAlert({
      category: 'Area Safety',
      priority:
        analysis.safetyScore >= 75
          ? 'information'
          : analysis.safetyScore >= 50
          ? 'caution'
          : 'critical',
      distanceMeters: 0,
      timestamp: at,
      summary: areaVerdict.summary,
      recommendedAction:
        analysis.safetyScore < 50
            ? 'Arm SOS, share live location with a trusted contact, and consider an alternate route.'
            : 'Review the reasons below and follow recommended actions.',
      dataSource: 'suraksha_engine',
      disclaimer: nashikSafetyConfig.dataDisclaimer,
      verdictHeadline: areaVerdict.headline,
      riskReasons: areaRiskReasons,
    }),
  );

  alerts.push(
    makeAlert({
      category: 'Public Transport',
      priority: 'information',
      distanceMeters: 400,
      timestamp: at,
      summary:
        'Auto rickshaws, MSRTC buses, and taxis typically serve main Nashik corridors. Availability varies by time and route.',
      recommendedAction:
        'Use main roads and busy junctions for quicker access to autos, buses, or taxis.',
      dataSource: 'regional_guidance',
      confidence: 48,
      disclaimer:
        'General Nashik transport guidance—not live transit API data. Check locally for current service.',
    }),
  );

  if (!external?.inRegion) {
    alerts.unshift(
      makeAlert({
        category: 'Region Notice',
        priority: 'information',
        distanceMeters: 0,
        timestamp: at,
        summary: `Phase 1 safety intelligence is optimized for ${nashikSafetyConfig.regionLabel}. You appear outside the mapped region—some signals may be limited.`,
        recommendedAction:
          'Move within Nashik for full OSM, crowd, and incident fusion coverage.',
        dataSource: 'suraksha_engine',
        confidence: 90,
      }),
    );
  }

  return alerts.slice(0, 10);
}

module.exports = { buildCommunityAlerts, makeAlert };
