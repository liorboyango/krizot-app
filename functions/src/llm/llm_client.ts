/**
 * Provider-agnostic LLM access. The provider/model come from the
 * `config/llm` Firestore doc at call time, so switching between Anthropic,
 * Google and xAI needs no redeploy — only the matching API-key secret must
 * be set (ANTHROPIC_API_KEY / GOOGLE_GENERATIVE_AI_API_KEY / XAI_API_KEY,
 * which the AI SDK providers read natively).
 */

import { streamObject } from 'ai';
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
  // Streamed on purpose: a non-streaming call gets no response headers until
  // the whole plan is generated, and multi-minute generations then trip the
  // runtime's fetch headers-timeout ("Headers Timeout Error"). Streaming
  // keeps bytes flowing; the awaited object is still schema-validated.
  const result = streamObject({
    model: provider(config.model),
    schema,
    system,
    prompt,
    // A plan is a few thousand tokens — don't let the provider default to
    // an enormous max_tokens that schedules a very long generation window.
    maxOutputTokens: 32_000,
    ...(config.temperature !== undefined
      ? { temperature: config.temperature }
      : {}),
  });
  return (await result.object) as z.infer<SCHEMA>;
}
