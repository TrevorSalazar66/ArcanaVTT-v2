import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { AppError } from '../../middlewares/error_handler';
import type { profileSetupSchema } from '../../schemas/sync_schemas';
import type { Env, UserRole } from '../../types/env';
import { calculateAgeUtc } from '../../utils/crypto_jwt';

type ProfileSetupInput = z.infer<typeof profileSetupSchema>;

/**
 * Configura perfil social (@username único, nome, data de nascimento LGPD, bio, avatar e 7+ contatos sociais).
 * NUNCA altera `users.role`: promoção de cargo é exclusiva do Painel Admin / Superadmin.
 */
export async function setupUserProfile(
  userId: string,
  input: ProfileSetupInput,
  repo: IArcanaRepository,
  env?: Env,
) {
  const [existingProfile, user] = await Promise.all([
    repo.findProfileByUserId(userId),
    repo.findUserById(userId),
  ]);
  if (!existingProfile || !user) {
    throw new AppError(404, 'PROFILE_NOT_FOUND', 'Perfil do usuario nao localizado.');
  }

  const minAge = Number.parseInt(env?.MIN_AGE_YEARS ?? '16', 10) || 16;
  const effectiveBirthDate = input.birth_date ?? user.birth_date;
  const age = calculateAgeUtc(effectiveBirthDate);
  if (age < 0) {
    throw new AppError(400, 'INVALID_BIRTH_DATE', 'Data de nascimento invalida.');
  }
  if (age < minAge) {
    throw new AppError(
      403,
      'AGE_RESTRICTED',
      `Acesso bloqueado: e obrigatorio ter no minimo ${minAge} anos conforme diretrizes LGPD.`,
    );
  }
  if (input.birth_date) {
    await repo.updateUserBirthDate(userId, input.birth_date);
  }

  const collision = await repo.findProfileByUsername(input.username);
  if (collision && collision.user_id !== userId) {
    throw new AppError(
      409,
      'USERNAME_TAKEN',
      `O identificador @${input.username} ja esta em uso na Taverna.`,
    );
  }

  let prevContacts: Record<string, string> = {};
  try {
    prevContacts = JSON.parse(existingProfile.contacts_json ?? '{}') as Record<string, string>;
  } catch {
    prevContacts = {};
  }

  const allowedKeys = [
    'discord',
    'twitch',
    'youtube',
    'steam',
    'instagram',
    'x_twitter',
    'reddit',
    'whatsapp',
  ] as const;

  let nextContacts = prevContacts;
  if (input.contacts) {
    nextContacts = {};
    for (const k of allowedKeys) {
      const val = input.contacts[k]?.trim() ?? '';
      if (val) nextContacts[k] = val;
    }
  }

  const updated = {
    ...existingProfile,
    username: input.username,
    display_name: input.display_name,
    bio: input.bio,
    avatar_icon: input.avatar_icon ?? existingProfile.avatar_icon,
    contacts_json: JSON.stringify(nextContacts),
    theme_preference: input.theme_preference ?? existingProfile.theme_preference,
    font_scale: input.font_scale ?? existingProfile.font_scale,
    onboarding_completed: 1,
    updated_at: new Date().toISOString(),
  };

  await repo.updateProfile(updated);
  const currentRole: UserRole = user.role;
  return { ok: true, profile: updated, role: currentRole };
}
