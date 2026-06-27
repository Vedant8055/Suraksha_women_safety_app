const env = require('../config/env');

function extractGeminiText(data) {
  const parts = data?.candidates?.[0]?.content?.parts;
  if (!Array.isArray(parts)) return '';
  return parts
    .map((part) => part?.text)
    .filter(Boolean)
    .join('\n')
    .trim();
}

function parseJsonFromText(text) {
  if (!text) return null;
  const fenced = text.match(/```json\s*([\s\S]*?)```/i);
  const candidate = fenced ? fenced[1] : text;
  try {
    return JSON.parse(candidate.trim());
  } catch (_) {
    const start = candidate.indexOf('{');
    const end = candidate.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        return JSON.parse(candidate.slice(start, end + 1));
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

function buildFactsPayload({ analysis, external, at }) {
  const dimensions = (analysis.dimensions || []).map((item) => ({
    key: item.key,
    score: item.score,
    label: item.label,
  }));
  return {
    safetyScore: analysis.safetyScore,
    riskLevel: analysis.riskLevel?.label || analysis.riskLevel,
    aiConfidence: analysis.aiConfidence,
    dimensions,
    contributingFactors: analysis.contributingFactors?.slice(0, 5) || [],
    gridRisk: analysis.gridRisk
      ? {
          label: analysis.gridRisk.label,
          count7d: analysis.gridRisk.count7d,
          count30d: analysis.gridRisk.count30d,
        }
      : null,
    crowd: external?.crowd?.activityLevel || null,
    isDark: external?.sunset?.isDark ?? null,
    region: external?.regionLabel || 'Nashik',
    time: at.toISOString(),
  };
}

function buildTemplateSummary(facts, lang = 'en') {
  const score = facts.safetyScore;
  const region = facts.region;
  const intro =
    lang === 'hi'
      ? `${region} में आपका सुरक्षा स्कोर ${score}/100 है।`
      : lang === 'mr'
      ? `${region} मध्ये तुमचा सुरक्षा स्कोर ${score}/100 आहे.`
      : `Your safety score in ${region} is ${score}/100.`;

  const factor =
    facts.contributingFactors?.[0] ||
    (lang === 'hi'
      ? 'सीमित स्थानीय डेटा—सतर्क रहें।'
      : lang === 'mr'
      ? 'मर्यादित स्थानिक डेटा—सजग राहा.'
      : 'Limited local data—stay alert.');

  const action =
    score < 50
      ? lang === 'hi'
        ? 'मुख्य सड़कों पर रहें और SOS तैयार रखें।'
        : lang === 'mr'
        ? 'मुख्य रस्त्यांवर राहा आणि SOS तयार ठेवा.'
        : 'Stay on main roads and keep SOS ready.'
      : lang === 'hi'
      ? 'आसपास के हालात पर नज़र रखें।'
      : lang === 'mr'
      ? 'सद्य परिस्थितीवर लक्ष ठेवा.'
      : 'Continue monitoring conditions around you.';

  return {
    summary: `${intro} ${factor}`,
    actionLine: action,
    source: 'template',
    language: lang,
  };
}

async function callGeminiSummary(facts, lang) {
  const langLabel = lang === 'hi' ? 'Hindi' : lang === 'mr' ? 'Marathi' : 'English';
  const prompt = [
    'You summarize women\'s safety intelligence for a mobile app in India.',
    `Write in ${langLabel}.`,
    'Use ONLY the JSON facts below. Do not invent incidents, lighting, crowd, or crime events.',
    'If data is missing, say insufficient local data.',
    'Return strict JSON: {"summary":"2 sentences max","actionLine":"1 short actionable sentence"}',
    JSON.stringify(facts),
  ].join('\n');

  const model = env.geminiModel || 'gemini-1.5-flash';
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(env.geminiApiKey)}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.2, maxOutputTokens: 256 },
    }),
  });

  if (!response.ok) throw new Error(`Gemini ${response.status}`);
  const data = await response.json();
  const parsed = parseJsonFromText(extractGeminiText(data));
  if (!parsed?.summary) throw new Error('Gemini invalid summary JSON');
  return {
    summary: String(parsed.summary).trim(),
    actionLine: String(parsed.actionLine || '').trim(),
    source: 'gemini',
    language: lang,
  };
}

const summaryCache = new Map();

function summaryCacheKey(facts, lang) {
  const bucket = Math.round(facts.safetyScore / 5) * 5;
  return `${lang}:${facts.region}:${bucket}:${facts.isDark}:${facts.crowd}`;
}

async function generateSafetySummary({ analysis, external, at = new Date(), lang = 'en' }) {
  const facts = buildFactsPayload({ analysis, external, at });
  const key = summaryCacheKey(facts, lang);
  const cached = summaryCache.get(key);
  if (cached && Date.now() - cached.at < 8 * 60 * 1000) {
    return { ...cached.value, cached: true };
  }

  let result = buildTemplateSummary(facts, lang);
  if (env.geminiApiKey) {
    try {
      result = await callGeminiSummary(facts, lang);
    } catch (_) {
      result = buildTemplateSummary(facts, lang);
    }
  }

  summaryCache.set(key, { at: Date.now(), value: result });
  return { ...result, cached: false, factsUsed: Object.keys(facts).length };
}

module.exports = {
  generateSafetySummary,
  buildTemplateSummary,
  buildFactsPayload,
};
