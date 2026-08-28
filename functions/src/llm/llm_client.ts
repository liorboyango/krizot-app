/**
 * Provider-agnostic LLM access. The provider/model come from the
 * `config/llm` Firestore doc at call time, so switching between Anthropic,
 * Google and xAI needs no redeploy — only the matching API-key secret must
 * be set (ANTHROPIC_API_KEY / GOOGLE_GENERATIVE_AI_API_KEY / XAI_API_KEY,
 * which the AI SDK providers read natively).
 */

import { generateObject } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';
import { google } from '@ai-sdk/google';
import { xai } from '@ai-sdk/xai';
import { z } from 'zod';

import { LlmConfig } from '../domain/firestore';

const registry = {
  anthropic: (model: string) => anthropic(model),
  google: (model: string) => google(model),
  xai: (model: string) => xai(model),
} as const;

export async function generateStructured<SCHEMA extends z.ZodType>(options: {
  config: LlmConfig;
  schema: SCHEMA;
  system: string;
  prompt: string;
}): Promise<z.infer<SCHEMA>> {
  const { config, schema, system, prompt } = options;
  const provider = registry[config.provider] ?? registry.anthropic;
  const { object } = await generateObject({
    model: provider(config.model),
    schema,
    system,
    prompt,
    ...(config.temperature !== undefined
      ? { temperature: config.temperature }
      : {}),
  });
  return object as z.infer<SCHEMA>;
}
