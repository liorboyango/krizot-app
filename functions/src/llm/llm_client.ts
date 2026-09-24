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
  /** Bounds the call — callers running inside a request deadline must not
   * let one generation eat the whole budget. */
  abortSignal?: AbortSignal;
}): Promise<z.infer<SCHEMA>> {
  const { config, schema, system, prompt, abortSignal } = options;
  const provider = registry[config.provider] ?? registry.anthropic;
  const isAnthropic = !(config.provider in registry) ||
    config.provider === 'anthropic';
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
    ...(abortSignal ? { abortSignal } : {}),
    ...(isAnthropic
      ? {
          // Left unbounded, Claude's reasoning can consume the whole output
          // budget on a big planning day and leave zero text (finishReason
          // 'length', empty JSON). Claude 5 models only accept adaptive
          // thinking, bounded via effort — low: this is throughput-bound
          // JSON planning and the validator/repair loop owns correctness.
          // Extended thinking also rejects custom temperature, so that is
          // only forwarded to other providers.
          providerOptions: {
            anthropic: {
              thinking: { type: 'adaptive' as const },
              effort: 'low' as const,
            },
          },
        }
      : config.temperature !== undefined
        ? { temperature: config.temperature }
        : {}),
  });
  return (await result.object) as z.infer<SCHEMA>;
}
