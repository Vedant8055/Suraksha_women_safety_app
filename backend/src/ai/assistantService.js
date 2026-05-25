const AIConversation = require('../models/AIConversation');
const env = require('../config/env');

const POSH_SYSTEM_PROMPT = `You are Suraksha POSH Legal Assistant for India.
Give practical, concise, and respectful guidance about workplace harassment prevention and reporting.
Prioritize user safety.
When relevant, mention:
- Internal Committee (IC) and complaint process under POSH
- preserving evidence (messages, emails, screenshots, dates, witnesses)
- emergency help if immediate danger (call 112)
Do not invent laws or case outcomes. If unsure, clearly say uncertainty and suggest professional legal help.`;

const _containsAny = (text, words) =>
  words.some((word) => text.toLowerCase().includes(word));

const fallbackGuidance = (text) => {
  const query = text.toLowerCase();

  if (_containsAny(query, ['immediate danger', 'unsafe now', 'threat', 'attack', 'assault'])) {
    return [
      'If you are in immediate danger, call 112 right now and move to a safe public place.',
      'Share your live location with trusted contacts and your workplace emergency contact.',
      'Preserve evidence (messages, emails, screenshots, call logs, dates, witness names).',
      'You can file a formal complaint with your organization Internal Committee (IC) under POSH.',
    ].join(' ');
  }

  if (_containsAny(query, ['complaint', 'report', 'ic', 'internal committee', 'posh'])) {
    return [
      'To file a POSH complaint, prepare a written incident summary with date, time, place, and details.',
      'Attach available evidence and witness names.',
      'Submit it to your organization Internal Committee (IC) and keep an acknowledged copy for records.',
      'If your organization does not respond, seek support from a legal aid service or women helpline.',
    ].join(' ');
  }

  if (_containsAny(query, ['evidence', 'proof', 'screenshot', 'recording'])) {
    return [
      'Collect and organize evidence in chronological order: chats, emails, screenshots, call logs, and witness details.',
      'Do not edit original files; keep backups with timestamps.',
      'Write a timeline note while details are fresh; it helps during IC inquiry or legal consultation.',
    ].join(' ');
  }

  return [
    'I can help with POSH guidance, complaint steps, evidence preparation, and escalation options.',
    'If you share your exact situation, I will give step-by-step action you can take now.',
    'If there is immediate danger, call 112 first.',
  ].join(' ');
};

const extractReplyText = (data) => {
  if (data?.output_text && data.output_text.toString().trim().length > 0) {
    return data.output_text.toString().trim();
  }

  const output = data?.output;
  if (Array.isArray(output)) {
    const texts = [];
    for (const item of output) {
      if (!item || !Array.isArray(item.content)) continue;
      for (const contentItem of item.content) {
        const text = contentItem?.text;
        if (typeof text === 'string' && text.trim()) {
          texts.push(text.trim());
        }
      }
    }
    if (texts.length) return texts.join('\n\n');
  }

  return '';
};

const askAssistant = async ({ userId, message }) => {
  let reply = fallbackGuidance(message);

  if (env.openAiApiKey) {
    try {
      const response = await fetch('https://api.openai.com/v1/responses', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${env.openAiApiKey}` },
        body: JSON.stringify({
          model: env.openAiModel,
          input: [
            { role: 'system', content: POSH_SYSTEM_PROMPT },
            { role: 'user', content: message },
          ],
          temperature: 0.2,
        }),
      });

      if (!response.ok) {
        throw new Error(`OpenAI API request failed with status ${response.status}`);
      }

      const data = await response.json();
      const extracted = extractReplyText(data);
      if (extracted) {
        reply = extracted;
      }
    } catch (_) {}
  }

  const convo = await AIConversation.findOneAndUpdate(
    { userId },
    { $push: { messages: [{ role: 'user', content: message }, { role: 'assistant', content: reply }] } },
    { new: true, upsert: true }
  );

  return { reply, conversationId: convo._id };
};

module.exports = { askAssistant };
