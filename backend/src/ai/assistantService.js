const AIConversation = require('../models/AIConversation');
const env = require('../config/env');

const fallbackGuidance = (text) => `Emergency guidance: Stay in a safe public place, call 112, and share live location. Query received: ${text}`;

const askAssistant = async ({ userId, message }) => {
  let reply = fallbackGuidance(message);

  if (env.openAiApiKey) {
    try {
      const response = await fetch('https://api.openai.com/v1/responses', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${env.openAiApiKey}` },
        body: JSON.stringify({ model: env.openAiModel, input: `You are a women safety emergency assistant. User: ${message}` }),
      });
      const data = await response.json();
      reply = data.output_text || reply;
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
