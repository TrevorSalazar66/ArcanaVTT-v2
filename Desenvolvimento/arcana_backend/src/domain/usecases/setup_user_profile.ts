import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { AppError } from '../../middlewares/error_handler';
import type { profileSetupSchema } from '../../schemas/sync_schemas';

type ProfileSetupInput = z.infer<typeof profileSetupSchema>;

/**
 * Configura perfil social (@username único, nome, bio, tema e escala tipográfica).
 */
export async function setupUserProfile(
  userId: string,
  input: ProfileSetupInput,
  repo: IArcanaRepository,
) {
  const existingProfile = await repo.findProfileByUserId(userId);
  if (!existingProfile) {
    throw new AppError(404, 'PROFILE_NOT_FOUND', 'Perfil do usuario nao localizado.');
  }

  const collision = await repo.findProfileByUsername(input.username);
  if (collision && collision.user_id !== userId) {
    throw new AppError(
      409,
      'USERNAME_TAKEN',
      `O identificador @${input.username} ja esta em uso na Taverna.`,
    );
  }

  const updated = {
    ...existingProfile,
    username: input.username,
    display_name: input.display_name,
    bio: input.bio,
    preferred_role: input.preferred_role,
    theme_preference: input.theme_preference ?? existingProfile.theme_preference,
    font_scale: input.font_scale ?? existingProfile.font_scale,
    onboarding_completed: 1,
    updated_at: new Date().toISOString(),
  };

  await repo.updateProfile(updated);
  return { ok: true, profile: updated };
}

