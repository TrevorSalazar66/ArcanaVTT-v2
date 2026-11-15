import { describe, expect, it } from 'vitest';
import { InMemoryArcanaRepository } from '../src/data/in_memory_repository';
import { getAdminOverviewUseCase, moderateReportUseCase } from '../src/domain/usecases/admin_governance';
import { authenticateGoogleOAuth } from '../src/domain/usecases/authenticate_google_oauth';
import { triggerAccountLockout, verifyAccountLockoutUnlock } from '../src/domain/usecases/manage_account_lockout';
import { createCampaignUseCase, quickJoinCampaignUseCase } from '../src/domain/usecases/manage_campaigns';
import { queryCompendiumUseCase } from '../src/domain/usecases/manage_systems';
import { submitUniversalReportUseCase } from '../src/domain/usecases/submit_universal_report';
import { AppError } from '../src/middlewares/error_handler';

describe('Camada 2 — Testes de Integração de Casos de Uso & Segurança Zero-Trust', () => {
  it('deve bloquear usuario menor de 16 anos no login Google OAuth', async () => {
    const repo = new InMemoryArcanaRepository();
    await expect(
      authenticateGoogleOAuth(
        {
          action: 'oauth_google',
          google_sub: 'sub_menor',
          email: 'menor@gmail.com',
          display_name: 'Aprendiz Jovem',
          birth_date: '2014-05-10',
          device_fingerprint: 'fp_pixel_menor',
          trust_device: true,
        },
        repo,
        { MIN_AGE_YEARS: '16', ENVIRONMENT: 'test' },
      ),
    ).rejects.toMatchObject({ code: 'AGE_RESTRICTED', statusCode: 403 });
  });

  it('deve bloquear dispositivo sob Hardware Ban e permitir Lockout Total com codigo de recuperacao', async () => {
    const repo = new InMemoryArcanaRepository();

    const authRes = await authenticateGoogleOAuth(
      {
        action: 'oauth_google',
        google_sub: 'sub_teste_lockout',
        email: 'heroi.seguro@gmail.com',
        display_name: 'Heroi Seguro',
        birth_date: '1999-02-20',
        device_fingerprint: 'fp_device_ok',
        trust_device: true,
        requested_role: 'admin',
      },
      repo,
      { ENVIRONMENT: 'test' },
    );

    const lockoutRes = await triggerAccountLockout(
      authRes.user.id,
      'Suspeita de roubo de aparelho',
      repo,
      { ENVIRONMENT: 'test' },
    );
    expect(lockoutRes.account_status).toBe('locked');
    expect(lockoutRes.recovery_code_preview).toMatch(/^\d{6}$/);

    await expect(
      authenticateGoogleOAuth(
        {
          action: 'oauth_google',
          google_sub: 'sub_teste_lockout',
          email: 'heroi.seguro@gmail.com',
          display_name: 'Heroi Seguro',
          birth_date: '1999-02-20',
          device_fingerprint: 'fp_device_ok',
          trust_device: true,
        },
        repo,
        { ENVIRONMENT: 'test' },
      ),
    ).rejects.toMatchObject({ code: 'ACCOUNT_LOCKED', statusCode: 423 });

    const unlockRes = await verifyAccountLockoutUnlock(
      'heroi.seguro@gmail.com',
      lockoutRes.recovery_code_preview!,
      'fp_device_ok',
      repo,
    );
    expect(unlockRes.account_status).toBe('active');
  });

  it('deve ocultar categorias vazias do compendio automaticamente', async () => {
    const repo = new InMemoryArcanaRepository({ withTestFixtures: true });
    const res = await queryCompendiumUseCase(
      { action: 'compendium.query', system_id: 'sys_lamina_carmesim' },
      repo,
    );
    expect(res.visible_categories).toEqual(['poderes']);
    expect(res.visible_categories).not.toContain('seres');
    expect(res.visible_categories).not.toContain('pistas');
  });

  it('deve aplicar RBAC estrito, gerar autotags em denuncias e efetuar Hardware Ban pelo Admin', async () => {
    const repo = new InMemoryArcanaRepository({ withTestFixtures: true });
    const jogador = {
      userId: 'usr_valen_bard',
      email: 'valen@arcanavtt.app',
      role: 'jogador' as const,
      jti: 'jti_1',
      deviceFingerprint: 'fp_infrator_999',
    };

    await expect(
      createCampaignUseCase(
        jogador,
        {
          action: 'campaigns.create',
          title: 'Tentativa Ilegal',
          synopsis: 'Jogador comum nao pode forjar mesa sem cargo de mestre.',
          system_id: 'sys_alphad6_v24',
          mode: 'ao_vivo',
          schedule_text: 'Hoje',
          max_slots: 4,
          visibility: 'publica',
        },
        repo,
      ),
    ).rejects.toBeInstanceOf(AppError);

    const joined = await quickJoinCampaignUseCase('usr_valen_bard', 'arc-774', repo);
    expect(joined.campaign.quick_join_code).toBe('ARC774');

    const report = await submitUniversalReportUseCase(
      jogador,
      {
        action: 'report.submit',
        origin_type: 'chat',
        origin_id: 'msg_01',
        reason_category: 'Ofensa grave',
        description: 'Comportamento toxico no canal da taverna.',
        context_session: 'taverna-dos-mestres',
      },
      repo,
    );
    expect(report.auto_tags.some((t) => t.startsWith('#origem:chat'))).toBe(true);

    const admin = {
      userId: 'usr_admin_thorin',
      email: 'thorin@arcanavtt.app',
      role: 'superadmin' as const,
      jti: 'jti_admin',
      deviceFingerprint: 'fp_admin',
    };
    const overview = await getAdminOverviewUseCase(admin, repo);
    expect(overview.reports.length).toBeGreaterThanOrEqual(1);

    await moderateReportUseCase(
      admin,
      {
        action: 'admin.moderate',
        report_id: report.report_id,
        decision: 'hardware_ban',
        ban_device_fingerprint: 'fp_infrator_999',
        ban_reason: 'Banimento de teste',
      },
      repo,
    );

    const bannedDevice = await repo.findDeviceSecurity('fp_infrator_999');
    expect(bannedDevice?.is_hardware_banned).toBe(1);
  });
});

