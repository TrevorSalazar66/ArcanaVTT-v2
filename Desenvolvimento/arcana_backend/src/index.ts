import { Hono } from 'hono';
import { CloudflareD1Repository } from './data/d1_repository';
import { InMemoryArcanaRepository } from './data/in_memory_repository';
import type { IArcanaRepository } from './data/interfaces';
import {
  getAdminOverviewUseCase,
  moderateReportUseCase,
} from './domain/usecases/admin_governance';
import { authenticateGoogleOAuth } from './domain/usecases/authenticate_google_oauth';
import {
  triggerAccountLockout,
  verifyAccountLockoutUnlock,
} from './domain/usecases/manage_account_lockout';
import {
  applyToCampaignUseCase,
  createCampaignUseCase,
  listCampaignsUseCase,
  quickJoinCampaignUseCase,
} from './domain/usecases/manage_campaigns';
import {
  boostGuildUseCase,
  createForumTopicUseCase,
  createGuildUseCase,
  getCommunitiesOverviewUseCase,
  sendChatMessageUseCase,
  upvoteForumTopicUseCase,
} from './domain/usecases/manage_communities';
import {
  addFriendUseCase,
  getSocialOverviewUseCase,
  markNotificationsReadUseCase,
  upsertCharacterUseCase,
} from './domain/usecases/manage_social';
import {
  createSystemUseCase,
  listSystemsUseCase,
  queryCompendiumUseCase,
} from './domain/usecases/manage_systems';
import {
  forwardP2pSignalUseCase,
  registerP2pPresenceUseCase,
} from './domain/usecases/p2p_signaling';
import { setupUserProfile } from './domain/usecases/setup_user_profile';
import { submitUniversalReportUseCase } from './domain/usecases/submit_universal_report';
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
      version: '0.1.0-fase-1',
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

    switch (parsed.action) {
      case 'profile.setup':
        return c.json(await setupUserProfile(authUser.userId, parsed, repo));
      case 'campaigns.list':
        return c.json(await listCampaignsUseCase(authUser.userId, parsed, repo));
      case 'campaigns.quick_join':
        return c.json(await quickJoinCampaignUseCase(authUser.userId, parsed.code, repo));
      case 'campaigns.create':
        return c.json(await createCampaignUseCase(authUser, parsed, repo), 201);
      case 'campaigns.apply':
        return c.json(await applyToCampaignUseCase(authUser.userId, parsed, repo));
      case 'systems.list':
        return c.json(await listSystemsUseCase(parsed, repo));
      case 'systems.create':
        return c.json(await createSystemUseCase(authUser.userId, parsed, repo), 201);
      case 'compendium.query':
        return c.json(await queryCompendiumUseCase(parsed, repo));
      case 'communities.overview':
        return c.json(await getCommunitiesOverviewUseCase(parsed, repo));
      case 'guilds.create':
        return c.json(await createGuildUseCase(authUser, parsed, repo), 201);
      case 'guilds.boost':
        return c.json(await boostGuildUseCase(parsed, repo));
      case 'forum.create_topic':
        return c.json(await createForumTopicUseCase(authUser, parsed, repo), 201);
      case 'forum.upvote':
        return c.json(await upvoteForumTopicUseCase(parsed.topic_id, repo));
      case 'chat.send_message':
        return c.json(await sendChatMessageUseCase(authUser, parsed, repo), 201);
      case 'social.overview':
        return c.json(await getSocialOverviewUseCase(authUser.userId, repo));
      case 'social.add_friend':
        return c.json(await addFriendUseCase(authUser.userId, parsed, repo), 201);
      case 'characters.upsert':
        return c.json(await upsertCharacterUseCase(authUser.userId, parsed, repo), 201);
      case 'notifications.mark_read':
        return c.json(
          await markNotificationsReadUseCase(
            authUser.userId,
            parsed.notification_id,
            repo,
          ),
        );
      case 'report.submit':
        return c.json(
          await submitUniversalReportUseCase(authUser, parsed, repo),
          201,
        );
      case 'admin.overview':
        return c.json(await getAdminOverviewUseCase(authUser, repo));
      case 'admin.moderate':
        return c.json(await moderateReportUseCase(authUser, parsed, repo));
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

