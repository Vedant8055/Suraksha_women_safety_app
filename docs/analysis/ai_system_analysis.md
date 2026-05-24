# AI System Analysis

## Executive Summary

The AI system is currently a single mobile-side service that sends user prompts directly to Google's Gemini API and returns free-form text to the UI. This is adequate for early prototyping of conversational UX, but it is not a production-safe AI architecture for legal, safety, or emergency guidance.

## Current Implementation

### Implemented component

- `lib/features/ai_assistant/ai_service.dart`

### Current flow

1. User types a message in `POSHChatScreen`
2. Screen sends raw text to `AIService`
3. `AIService` issues direct HTTP request to Gemini endpoint
4. Response text is inserted into local in-memory chat list

### Current prompt pattern

The model is instructed in one inline prompt to behave as a women's safety and legal advisor and to answer concisely/helpfully.

## Architectural Assessment

### What is good

- the AI feature is isolated to a dedicated service file
- the UI contract is simple and understandable
- failure fallback avoids a total crash

### What is weak

- no backend mediation layer
- no prompt versioning
- no conversation memory model beyond UI list
- no moderation stage
- no legal/safety source grounding
- no analytics or abuse visibility

## Security and Secret Management

### Current state

- the service expects a Gemini API key directly inside client code

### Risks

- easy extraction of API credentials from mobile builds
- unmetered abuse and billing exposure
- no policy enforcement on prompt types or rate
- no jurisdiction-aware handling for legal content

## Prompt Handling Review

### Current pattern

- a single inline role instruction
- raw user text appended directly into prompt content

### Risks

- prompt injection is unmitigated
- no topic routing
- no safe fallback for self-harm, imminent violence, or legal liability cases
- no output structuring or confidence score

## Hallucination and Safety Risk

This is the most important AI-quality issue.

The assistant is positioned as:

- safety advisor
- legal advisor
- workplace rights guide

Yet the current system has:

- no grounding on verified legal resources
- no locale-specific policy context
- no disclaimer strategy
- no escalation to emergency or human support

For a women-safety product, hallucinated or overconfident advice can cause real-world harm.

## Moderation Assessment

No moderation controls were found for:

- sexually explicit content
- violent content
- coercion or blackmail reports
- suicide/self-harm signals
- false legal certainty
- emergency escalation detection

## Reliability and UX Assessment

### Current fallback

On any exception, the service returns:

- a generic "trouble connecting" message

### Gaps

- no retry policy
- no timeout-specific user messaging
- no partial degraded mode
- no persisted transcripts
- no incident handoff path from AI to SOS or helpline

## API Abstraction Quality

The AI call is not abstracted enough for long-term evolution.

Missing layers:

- AI gateway / backend proxy
- prompt templates registry
- safety classifier
- response normalizer
- observability pipeline

## Production-Ready Target Design

### Minimum safe architecture

- mobile client talks to backend AI endpoint
- backend stores Gemini key securely
- backend applies prompt templates server-side
- backend runs moderation / safety classification
- backend returns structured result types, not raw model output only

### Recommended response contract

The AI system should eventually distinguish:

- general guidance
- legal information
- emergency instruction
- insufficient confidence
- escalation required

## Recommended Guardrails

### Product guardrails

- clearly label AI as assistive, not authoritative
- block definitive legal claims without grounding
- escalate imminent-danger intent to emergency action suggestions
- provide country/region disclaimers when laws may vary

### Technical guardrails

- server-side secret storage
- per-user rate limits
- prompt and response logging with redaction
- moderation pass before model output reaches UI
- cached/system prompt versioning

## Current AI Readiness Verdict

The AI system is a prototype chat integration, not a production AI safety subsystem. It demonstrates interface direction, but it lacks the governance, control plane, and domain grounding required for a sensitive legal and emergency context.

## AI Scorecard

| Category | Score | Notes |
| --- | --- | --- |
| Feature prototyping value | 6/10 | enough to demo chat UX |
| Secret management | 1/10 | client-side key pattern |
| Safety governance | 1/10 | no moderation or escalation logic |
| Domain grounding | 1/10 | free-form model output only |
| Enterprise AI readiness | 1/10 | no backend AI architecture |
