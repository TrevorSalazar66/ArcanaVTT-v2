import { z } from 'zod';

const roleSchema = z.enum([
  'jogador',
  'assistente_mestre',
  'mestre',
  'admin',
  'superadmin',
]);

export const authOAuthGoogleSchema = z.object({
  action: z.literal('oauth_google'),
  id_token: z.string().min(10).optional(),
  google_sub: z.string().min(4).max(128),
  email: z.string().email().max(180),
  display_name: z.string().min(2).max(80),
  birth_date: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Data deve ser YYYY-MM-DD')
    .optional(),
  device_fingerprint: z.string().min(6).max(128),
  android_id_hash: z.string().min(6).max(128).optional(),
  trust_device: z.boolean().default(true),
  requested_role: roleSchema.optional(),
});

export const authLockoutTriggerSchema = z.object({
  action: z.literal('lockout_trigger'),
  user_id: z.string().min(3).max(80),
  reason: z.string().min(3).max(240).default('Bloqueio preventivo solicitado pelo usuario'),
});

export const authLockoutVerifySchema = z.object({
  action: z.literal('lockout_verify'),
  email: z.string().email().max(180),
  recovery_code: z.string().regex(/^\d{6}$/, 'Codigo deve ter 6 digitos numericos'),
  device_fingerprint: z.string().min(6).max(128),
});

export const authLogoutSchema = z.object({
  action: z.literal('logout'),
  scope: z.enum(['current', 'global']).default('current'),
});

export const authPayloadSchema = z.discriminatedUnion('action', [
  authOAuthGoogleSchema,
  authLockoutTriggerSchema,
  authLockoutVerifySchema,
  authLogoutSchema,
]);

export type AuthPayload = z.infer<typeof authPayloadSchema>;

