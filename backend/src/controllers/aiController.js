const { z } = require('zod');
const { asyncHandler } = require('../utils/asyncHandler');
const { askAssistant } = require('../ai/assistantService');

const aiChatSchema = z.object({ body: z.object({ message: z.string().min(2) }) });

const chat = asyncHandler(async (req, res) => {
  const out = await askAssistant({ userId: req.user._id, message: req.validated.body.message });
  res.json(out);
});

module.exports = { chat, aiChatSchema };
