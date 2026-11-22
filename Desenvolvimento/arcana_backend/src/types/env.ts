import type { D1Database } from '@cloudflare/workers-types';

export type UserRole =
  | 'jogador'
  | 'assistente_mestre'
  | 'mestre'
  | 'admin'
  | 'superadmin';

export type AccountStatus = 'active' | 'locked' | 'banned';

export type ThemePreference =
  | 'escuro_heraldico'
  | 'oled'
  | 'alto_contraste_solar';

export type CompendiumCategory =
  | 'itens'
  | 'equipamentos'
  | 'seres'
  | 'poderes'
  | 'pistas';

export type SceneModelType =
  | 'grid_2d'
  | 'mahjong'
  | 'password'
  | 'dialogue'
  | 'jrpg_combat'
  | 'terminal';

export interface Env {
  DB?: D1Database;
  ENVIRONMENT?: string;
  MIN_AGE_YEARS?: string;
  SESSION_TTL_DAYS?: string;
  ALLOWED_ORIGINS?: string;
  JWT_SECRET?: string;
  GOOGLE_CLIENT_ID?: string;
  RESEND_API_KEY?: string;
  EMAIL_FROM?: string;
}

export interface AuthenticatedUser {
  userId: string;
  email: string;
  role: UserRole;
  jti: string;
  deviceFingerprint: string;
  onboardingCompleted?: number;
}

export interface HonoVariables {
  authUser?: AuthenticatedUser;
}
