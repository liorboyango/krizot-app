import { defineSecret } from 'firebase-functions/params';

/**
 * Only the secret matching config/llm.provider must actually be set:
 *   firebase functions:secrets:set ANTHROPIC_API_KEY
 * The AI SDK providers read these env names natively.
 */
export const anthropicApiKey = defineSecret('ANTHROPIC_API_KEY');
export const googleApiKey = defineSecret('GOOGLE_GENERATIVE_AI_API_KEY');
export const xaiApiKey = defineSecret('XAI_API_KEY');

export const llmSecrets = [anthropicApiKey, googleApiKey, xaiApiKey];
