import { Hono } from 'hono';
import { CloudflareD1Repository } from './data/d1_repository';
import { InMemoryArcanaRepository } from './data/in_memory_repository';
import type { IArcanaRepository } from './data/interfaces';
import {
  auditDmsSuperadminUseCase,
  generateSystemCreationKeyUseCase,
  getAdminOverviewUseCase,
  moderateReportUseCase,
  unbanDeviceAdminUseCase,
  updateUserRoleAdminUseCase,
} from './domain/usecases/admin_governance';
import { authenticateGoogleOAuth } from './domain/usecases/authenticate_google_oauth';
import {
  triggerAccountLockout,
  verifyAccountLockoutUnlock,
} from './domain/usecases/manage_account_lockout';
import {
  acceptCampaignInviteUseCase,
  applyToCampaignUseCase,
  createCampaignUseCase,
  deleteCampaignSceneUseCase,
  invitePlayerToCampaignUseCase,
  leaveCampaignUseCase,
  listCampaignCharactersUseCase,
  listCampaignMembersUseCase,
  listCampaignScenesUseCase,
  listCampaignsUseCase,
  listGmBannedPlayersUseCase,
  lookupCampaignByCodeUseCase,
  manageCampaignMemberUseCase,
  quickJoinCampaignUseCase,
  triggerSceneActionUseCase,
  unbanPlayerFromGmUseCase,
  updateCampaignSettingsUseCase,
  upsertCampaignSceneUseCase,
} from './domain/usecases/manage_campaigns';
import {
  boostGuildUseCase,
  clearChatChannelUseCase,
  createAnnouncementUseCase,
  createForumCommentUseCase,
  createForumTopicUseCase,
  createGuildUseCase,
  deleteChatMessageUseCase,
  getCommunitiesOverviewUseCase,
  getForumTopicDetailUseCase,
  moderateChatActionCardUseCase,
  sendChatMessageUseCase,
  updateGuildWorldUseCase,
  upvoteForumTopicUseCase,
} from './domain/usecases/manage_communities';
import {
  addFriendUseCase,
  getSocialOverviewUseCase,
  getSocialProfileUseCase,
  listDmMessagesUseCase,
  markNotificationsReadUseCase,
  respondFriendUseCase,
  sendDmMessageUseCase,
  upsertCharacterUseCase,
} from './domain/usecases/manage_social';
import {
  createSystemUseCase,
  listSystemsUseCase,
  queryCompendiumUseCase,
  toggleFavoriteSystemUseCase,
  upsertCompendiumItemUseCase,
} from './domain/usecases/manage_systems';
import {
  forwardP2pSignalUseCase,
  registerP2pPresenceUseCase,
} from './domain/usecases/p2p_signaling';
import { setupUserProfile } from './domain/usecases/setup_user_profile';
import { submitUniversalReportUseCase } from './domain/usecases/submit_universal_report';
import { executeUniversalRoll, resolveOpposedRoll } from './domain/usecases/universal_rpg_engine';
import {
  createAuthMiddleware,
  resolveJwtSecret,
} from './middlewares/auth_middleware';
import { AppError, handleGlobalError } from './middlewares/error_handler';
import { createRateLimiter } from './middlewares/rate_limiter';
import { securityHeadersMiddleware } from './middlewares/security_headers';
import { authPayloadSchema } from './schemas/auth_schemas';
import { syncPayloadSchema } from './schemas/sync_schemas';
import type { Env, HonoVariables } from './types/env';
import { verifyJwt } from './utils/crypto_jwt';

const fallbackInMemoryRepo = new InMemoryArcanaRepository();

/**
 * Cria a instância da aplicação Hono permitindo injeção de repositório para testes.
 */
export function createApp(customRepo?: IArcanaRepository) {
  const app = new Hono<{ Bindings: Env; Variables: HonoVariables }>();

  const resolveRepo = (env?: Env): IArcanaRepository => {
    if (customRepo) return customRepo;
    if (env?.DB) return new CloudflareD1Repository(env.DB);
    return fallbackInMemoryRepo;
  };

  app.onError((err, c) => handleGlobalError(err, c));
  app.use('*', securityHeadersMiddleware);
  app.use('/api/*', createRateLimiter(120, 60_000));

  app.get('/api/health', (c) => {
    return c.json({
      ok: true,
      service: 'arcana-vtt-backend',
      version: '0.2.0-universal',
      d1_bound: Boolean(c.env?.DB),
      timestamp_utc: new Date().toISOString(),
    });
  });

  app.post('/api/auth', async (c) => {
    const rawBody = await c.req.json().catch(() => {
      throw new AppError(400, 'INVALID_JSON', 'Corpo JSON ausente ou invalido.');
    });
    const parsed = authPayloadSchema.parse(rawBody);
    const repo = resolveRepo(c.env);
    const clientIp =
      c.req.header('CF-Connecting-IP') ?? c.req.header('x-forwarded-for') ?? '0.0.0.0';

    switch (parsed.action) {
      case 'oauth_google': {
        const result = await authenticateGoogleOAuth(parsed, repo, c.env, clientIp);
        return c.json(result, 200);
      }
      case 'lockout_trigger': {
        const result = await triggerAccountLockout(
          parsed.user_id,
          parsed.reason,
          repo,
          c.env,
        );
        return c.json(result, 200);
      }
      case 'lockout_verify': {
        const result = await verifyAccountLockoutUnlock(
          parsed.email,
          parsed.recovery_code,
          parsed.device_fingerprint,
          repo,
        );
        return c.json(result, 200);
      }
      case 'logout': {
        const authHeader = c.req.header('Authorization') ?? '';
        if (!authHeader.startsWith('Bearer ')) {
          throw new AppError(401, 'UNAUTHORIZED', 'Token ausente para logout.');
        }
        const payload = await verifyJwt(
          authHeader.slice(7).trim(),
          resolveJwtSecret(c.env),
        );
        if (!payload) {
          throw new AppError(401, 'INVALID_TOKEN', 'Token invalido.');
        }
        if (parsed.scope === 'global') {
          await repo.revokeAllUserSessions(payload.sub);
        } else {
          await repo.revokeSessionByJti(payload.jti);
        }
        return c.json({ ok: true, scope: parsed.scope });
      }
    }
  });

  app.use('/api/sync', createAuthMiddleware(resolveRepo));

  app.post('/api/sync', async (c) => {
    const authUser = c.get('authUser');
    if (!authUser) {
      throw new AppError(401, 'UNAUTHORIZED', 'Usuario nao autenticado.');
    }

    const rawBody = await c.req.json().catch(() => {
      throw new AppError(400, 'INVALID_JSON', 'Corpo JSON ausente ou invalido.');
    });
    const parsed = syncPayloadSchema.parse(rawBody);
    const repo = resolveRepo(c.env);

    // Barreira obrigatória de Onboarding (06_Planejamento Tópico 1):
    // enquanto onboarding_completed === 0, apenas profile.setup é liberado em /api/sync
    if (authUser.onboardingCompleted === 0 && parsed.action !== 'profile.setup') {
      throw new AppError(
        403,
        'PROFILE_INCOMPLETE',
        'Conclua o cadastro do perfil de aventureiro antes de acessar a Taverna.',
      );
    }

    switch (parsed.action) {
      case 'profile.setup':
        return c.json(await setupUserProfile(authUser.userId, parsed, repo, c.env));
      case 'campaigns.list':
        return c.json(await listCampaignsUseCase(authUser.userId, parsed, repo));
      case 'campaigns.lookup_code':
        return c.json(await lookupCampaignByCodeUseCase(authUser.userId, parsed.code, repo));
      case 'campaigns.quick_join':
        return c.json(await quickJoinCampaignUseCase(authUser.userId, parsed.code, repo));
      case 'campaigns.create':
        return c.json(await createCampaignUseCase(authUser, parsed, repo), 201);
      case 'campaigns.apply':
        return c.json(await applyToCampaignUseCase(authUser.userId, parsed, repo));
      case 'campaigns.invite_player':
        return c.json(await invitePlayerToCampaignUseCase(authUser, parsed, repo), 201);
      case 'campaigns.accept_invite':
        return c.json(await acceptCampaignInviteUseCase(authUser.userId, parsed, repo));
      case 'campaigns.leave':
        return c.json(await leaveCampaignUseCase(authUser.userId, parsed.campaign_id, repo));
      case 'campaigns.list_members':
        return c.json(await listCampaignMembersUseCase(authUser, parsed.campaign_id, repo));
      case 'campaigns.manage_member':
        return c.json(await manageCampaignMemberUseCase(authUser, parsed, repo));
      case 'campaigns.list_banned':
        return c.json(await listGmBannedPlayersUseCase(authUser, repo));
      case 'campaigns.unban_player':
        return c.json(await unbanPlayerFromGmUseCase(authUser, parsed.player_id, repo));
      case 'campaigns.update_settings':
        return c.json(await updateCampaignSettingsUseCase(authUser, parsed, repo));
      case 'campaigns.list_characters':
        return c.json(await listCampaignCharactersUseCase(authUser, parsed.campaign_id, repo));
      case 'scenes.list':
        return c.json(await listCampaignScenesUseCase(authUser, parsed.campaign_id, repo));
      case 'scenes.upsert':
        return c.json(await upsertCampaignSceneUseCase(authUser, parsed, repo), 201);
      case 'scenes.delete':
        return c.json(
          await deleteCampaignSceneUseCase(authUser, parsed.campaign_id, parsed.scene_id, repo),
        );
      case 'scenes.trigger':
        return c.json(await triggerSceneActionUseCase(authUser, parsed, repo));
      case 'systems.list':
        return c.json(await listSystemsUseCase(authUser.userId, parsed, repo));
      case 'systems.create':
        return c.json(await createSystemUseCase(authUser, parsed, repo), 201);
      case 'systems.toggle_favorite':
        return c.json(await toggleFavoriteSystemUseCase(authUser.userId, parsed.system_id, repo));
      case 'compendium.query':
        return c.json(await queryCompendiumUseCase(parsed, repo));
      case 'compendium.upsert':
        return c.json(await upsertCompendiumItemUseCase(authUser, parsed, repo), 201);
      case 'communities.overview':
        return c.json(await getCommunitiesOverviewUseCase(authUser, parsed, repo));
      case 'announcements.create':
        return c.json(await createAnnouncementUseCase(authUser, parsed, repo), 201);
      case 'forum.create_topic':
        return c.json(await createForumTopicUseCase(authUser, parsed, repo), 201);
      case 'forum.upvote':
        return c.json(await upvoteForumTopicUseCase(parsed.topic_id, parsed.delta, repo));
      case 'forum.get_topic':
        return c.json(await getForumTopicDetailUseCase(parsed.topic_id, repo));
      case 'forum.comment':
        return c.json(await createForumCommentUseCase(authUser, parsed, repo), 201);
      case 'chat.send_message':
        return c.json(await sendChatMessageUseCase(authUser, parsed, repo), 201);
      case 'chat.moderate_action_card':
        return c.json(await moderateChatActionCardUseCase(authUser, parsed, repo));
      case 'chat.delete_message':
        return c.json(
          await deleteChatMessageUseCase(authUser, parsed.message_id, parsed.campaign_id, repo),
        );
      case 'chat.clear_channel':
        return c.json(
          await clearChatChannelUseCase(authUser, parsed.channel_id, parsed.campaign_id, repo),
        );
      case 'rpg.roll_universal': {
        const rollA = executeUniversalRoll({
          expression: parsed.expression,
          label: parsed.label,
          difficulty: parsed.difficulty,
        });
        if (parsed.opposed_expression) {
          const rollB = executeUniversalRoll({
            expression: parsed.opposed_expression,
            label: 'OPONENTE',
          });
          return c.json({ ok: true, roll: rollA, opposed: rollB, resolution: resolveOpposedRoll(rollA, rollB) });
        }
        return c.json({ ok: true, roll: rollA });
      }
      case 'guilds.create':
        return c.json(await createGuildUseCase(authUser, parsed, repo), 201);
      case 'guilds.boost':
        return c.json(await boostGuildUseCase(parsed, repo));
      case 'guilds.update_world':
        return c.json(await updateGuildWorldUseCase(authUser, parsed, repo));
      case 'social.overview':
        return c.json(await getSocialOverviewUseCase(authUser.userId, repo));
      case 'social.get_profile':
        return c.json(await getSocialProfileUseCase(authUser.userId, parsed, repo));
      case 'social.add_friend':
        return c.json(await addFriendUseCase(authUser.userId, parsed, repo), 201);
      case 'social.respond_friend':
        return c.json(await respondFriendUseCase(authUser.userId, parsed, repo));
      case 'dm.list_messages':
        return c.json(await listDmMessagesUseCase(authUser.userId, parsed, repo));
      case 'dm.send_message':
        return c.json(await sendDmMessageUseCase(authUser.userId, authUser.role, parsed, repo), 201);
      case 'characters.upsert':
        return c.json(await upsertCharacterUseCase(authUser.userId, parsed, repo), 201);
      case 'notifications.mark_read':
        return c.json(await markNotificationsReadUseCase(authUser.userId, parsed.notification_id, repo));
      case 'report.submit':
        return c.json(await submitUniversalReportUseCase(authUser, parsed, repo), 201);
      case 'admin.overview':
        return c.json(await getAdminOverviewUseCase(authUser, repo));
      case 'admin.update_role':
        return c.json(await updateUserRoleAdminUseCase(authUser, parsed, repo));
      case 'admin.moderate':
        return c.json(await moderateReportUseCase(authUser, parsed, repo));
      case 'admin.unban_device':
        return c.json(await unbanDeviceAdminUseCase(authUser, parsed.device_fingerprint, repo));
      case 'admin.generate_creation_key':
        return c.json(await generateSystemCreationKeyUseCase(authUser, parsed.assigned_to_user_id, repo), 201);
      case 'admin.audit_dms':
        return c.json(await auditDmsSuperadminUseCase(authUser, parsed.user_a, parsed.user_b, repo));
      case 'sync.presence':
        return c.json(await registerP2pPresenceUseCase(authUser, parsed, repo));
      case 'sync.signal':
        return c.json(await forwardP2pSignalUseCase(authUser, parsed, repo));
    }
  });

  return app;
}

const defaultApp = createApp();
export default defaultApp;
