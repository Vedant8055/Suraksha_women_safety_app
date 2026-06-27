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

async function extractImageInsights(imageBuffer, mimeType) {
  if (!env.geminiApiKey || !imageBuffer?.length) return '';

  const model = env.geminiModel || 'gemini-1.5-flash';
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(env.geminiApiKey)}`;

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {
                text:
                  'You are a cybercrime evidence assistant. Extract all readable text from this screenshot. Then list any scam, phishing, blackmail, payment, OTP, or suspicious-link indicators you see. Return plain text only.',
              },
              {
                inline_data: {
                  mime_type: mimeType || 'image/jpeg',
                  data: imageBuffer.toString('base64'),
                },
              },
            ],
          },
        ],
      }),
    });

    if (!response.ok) return '';
    const data = await response.json();
    return extractGeminiText(data);
  } catch (_) {
    return '';
  }
}

async function refineThreatAssessment({
  text,
  question,
  links,
  extractedText,
  heuristic,
}) {
  const prompt = [
    'You are a cyber fraud analyst for an Indian women safety app.',
    'Review the user submission and improve the scam assessment.',
    'Return strict JSON with keys: riskLevel (LOW|MEDIUM|HIGH), threatSummary (string), recommendedActions (string array max 5), safetyTips (string array max 4).',
    `User text: ${text || 'N/A'}`,
    `User question: ${question || 'N/A'}`,
    `Links: ${(links || []).join(', ') || 'N/A'}`,
    `Extracted screenshot text: ${extractedText || 'N/A'}`,
    `Current heuristic summary: ${heuristic.threatSummary}`,
    `Current heuristic risk: ${heuristic.riskLevel}`,
  ].join('\n');

  if (env.geminiApiKey) {
    try {
      const model = env.geminiModel || 'gemini-1.5-flash';
      const url =
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(env.geminiApiKey)}`;
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.2,
            responseMimeType: 'application/json',
          },
        }),
      });
      if (response.ok) {
        const data = await response.json();
        const raw = extractGeminiText(data);
        const parsed = JSON.parse(raw);
        if (parsed?.riskLevel && parsed?.threatSummary) {
          return {
            riskLevel: parsed.riskLevel,
            threatSummary: parsed.threatSummary,
            recommendedActions: Array.isArray(parsed.recommendedActions)
              ? parsed.recommendedActions.slice(0, 5)
              : heuristic.recommendedActions,
            safetyTips: Array.isArray(parsed.safetyTips)
              ? parsed.safetyTips.slice(0, 4)
              : heuristic.safetyTips,
            analysisSource: 'heuristic+gemini',
          };
        }
      }
    } catch (_) {}
  }

  if (env.openAiApiKey) {
    try {
      const response = await fetch('https://api.openai.com/v1/responses', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${env.openAiApiKey}`,
        },
        body: JSON.stringify({
          model: env.openAiModel,
          input: [{ role: 'user', content: prompt }],
          temperature: 0.2,
        }),
      });
      if (response.ok) {
        const data = await response.json();
        const outputText =
          data?.output_text ||
          data?.output?.flatMap((item) => item.content || [])
            .map((part) => part?.text)
            .filter(Boolean)
            .join('\n');
        if (outputText) {
          const parsed = JSON.parse(outputText);
          if (parsed?.riskLevel && parsed?.threatSummary) {
            return {
              riskLevel: parsed.riskLevel,
              threatSummary: parsed.threatSummary,
              recommendedActions: Array.isArray(parsed.recommendedActions)
                ? parsed.recommendedActions.slice(0, 5)
                : heuristic.recommendedActions,
              safetyTips: Array.isArray(parsed.safetyTips)
                ? parsed.safetyTips.slice(0, 4)
                : heuristic.safetyTips,
              analysisSource: 'heuristic+openai',
            };
          }
        }
      }
    } catch (_) {}
  }

  return {
    ...heuristic,
    analysisSource: extractedText ? 'heuristic+vision' : 'heuristic',
  };
}

module.exports = {
  extractImageInsights,
  refineThreatAssessment,
};
