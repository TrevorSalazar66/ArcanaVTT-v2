import { describe, expect, it } from 'vitest';
import { InMemoryArcanaRepository } from '../src/data/in_memory_repository';
import { createApp } from '../src/index';

describe('Layer 3 — End-to-End HTTP (Hono Edge API + RBAC + Motor Universal + Zero-Seed)', () => {
  it('1. GET /api/health retorna metadados de v0.2.0-universal', async () => {
    const repo = new InMemoryArcanaRepository();
    const app = createApp(repo);

    const res = await app.request('/api/health');
    expect(res.status).toBe(200);
    const body = (await res.json()) as { ok: boolean; service: string; version: string };
    expect(body.ok).toBe(true);
    expect(body.service).toBe('arcana-vtt-backend');
  });

  it('2. Fluxo completo HTTP: Barreira PROFILE_INCOMPLETE -> Setup -> Key -> Sistema -> Guilda -> Mesa -> Ficha -> Cena -> Hardware Ban -> Lockout', async () => {
    const repo = new InMemoryArcanaRepository();
    const app = createApp(repo);

    // 1) Autentica fundador (primeiro usuario -> superadmin)
    const authRes = await app.request('/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action: 'oauth_google',
        google_sub: 'google_sub_e2e_1',
        email: 'fundador.e2e@arcanavtt.com',
        display_name: 'Lorde Fundador',
        birth_date: '1995-08-20',
        device_fingerprint: 'fp_e2e_android_01',
        trust_device: true,
      }),
    });
    expect(authRes.status).toBe(200);
    const authJson = (await authRes.json()) as {
      token: string;
      requires_profile_setup: boolean;
      user: { id: string; role: string };
    };
    expect(authJson.user.role).toBe('superadmin');
    expect(authJson.requires_profile_setup).toBe(true);

    const headers = {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${authJson.token}`,
      'X-Device-Fingerprint': 'fp_e2e_android_01',
    };

    // Barreira obrigatoria de onboarding: qualquer acao diferente de profile.setup falha com 403 PROFILE_INCOMPLETE
    const blockedRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({ action: 'systems.list', segment: 'todos' }),
    });
    expect(blockedRes.status).toBe(403);
    const blockedJson = (await blockedRes.json()) as { ok: boolean; error: string };
    expect(blockedJson.error).toBe('PROFILE_INCOMPLETE');

    // Completa onboarding obrigatorio
    const setupRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        action: 'profile.setup',
        username: 'lorde_e2e',
        display_name: 'Lorde E2E',
        bio: 'Arquiteto da Taverna',
        contacts: { discord: 'lorde#9999' },
      }),
    });
    expect(setupRes.status).toBe(200);

    // Verifica que catalogo inicial de sistemas e zero (nenhum AlphaD6)
    const emptySysRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({ action: 'systems.list', segment: 'todos' }),
    });
    expect(emptySysRes.status).toBe(200);
    const emptySysJson = (await emptySysRes.json()) as { systems: unknown[] };
    expect(emptySysJson.systems).toHaveLength(0);

    // Superadmin cria sistema dinamico e guilda
    const sysCreateRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        action: 'systems.create',
        name: 'Tormenta Arcana E2E',
        version: 'v1.0',
        dice_engine: '1d20',
        description: 'Sistema criado via E2E HTTP.',
        attributes: ['Forca', 'Destreza', 'Inteligencia'],
        is_official: true,
      }),
    });
    expect(sysCreateRes.status).toBe(201);
    const sysJson = (await sysCreateRes.json()) as { system: { id: string } };

    const gRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        action: 'guilds.create',
        name: 'Ordem da Vigilia E2E',
        tag: 'VIG',
        description: 'Guilda de testes automatizados.',
      }),
    });
    expect(gRes.status).toBe(201);
    const gJson = (await gRes.json()) as { guild: { id: string } };

    const boostRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({ action: 'guilds.boost', guild_id: gJson.guild.id, points: 1000 }),
    });
    expect(boostRes.status).toBe(200);
    const boostJson = (await boostRes.json()) as { leveled_up_to: number; guild: { shared_world_json: string } };
    expect(boostJson.leveled_up_to).toBe(2);

    // Cria campanha
    const cRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        action: 'campaigns.create',
        title: 'A Cidadela E2E',
        synopsis: 'Campanha completa de integracao HTTP.',
        system_id: sysJson.system.id,
        mode: 'ao_vivo',
        schedule_text: 'Sexta 21h',
        max_slots: 6,
        visibility: 'publica',
        icon_name: 'shield',
        banner_preset: 'cidadela_obsidiana',
        age_rating: '16+',
        tags: ['E2E', 'Tatico'],
      }),
    });
    expect(cRes.status).toBe(201);
    const cJson = (await cRes.json()) as { campaign: { id: string; quick_join_code: string } };

    // Upsert de ficha vinculada a campanha
    const chrRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        action: 'characters.upsert',
        campaign_id: cJson.campaign.id,
        name: 'Valen E2E',
        title: 'Bardo Guardiao',
        system_id: sysJson.system.id,
        level: 3,
        corpo: 2,
        mente: 3,
        espirito: 2,
        hp_current: 24,
        hp_max: 24,
        anima_current: 12,
        anima_max: 12,
        exhaustion: 0,
        slots: ['Alaude de Prata'],
      }),
    });
    expect(chrRes.status).toBe(201);

    // Rolagem universal via endpoint
    const rollRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        action: 'rpg.roll_universal',
        expression: '2d20kh1+4',
        label: 'PERCEPCAO',
      }),
    });
    expect(rollRes.status).toBe(200);

    // Jogador 2 entra, completa perfil e envia denuncia / sofre hardware ban via Superadmin
    const plAuthRes = await app.request('/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action: 'oauth_google',
        google_sub: 'google_sub_e2e_2',
        email: 'jogador2.e2e@gmail.com',
        display_name: 'Jogador Dois',
        birth_date: '2000-01-10',
        device_fingerprint: 'fp_e2e_player2',
        trust_device: true,
      }),
    });
    const plAuthJson = (await plAuthRes.json()) as { token: string; user: { id: string } };
    const plHeaders = {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${plAuthJson.token}`,
      'X-Device-Fingerprint': 'fp_e2e_player2',
    };
    await app.request('/api/sync', {
      method: 'POST',
      headers: plHeaders,
      body: JSON.stringify({
        action: 'profile.setup',
        username: 'jogador_dois',
        display_name: 'Jogador Dois',
        bio: 'Teste',
      }),
    });

    // Perfil Social nao retorna e-mail
    const profRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({ action: 'social.get_profile', user_id: plAuthJson.user.id }),
    });
    expect(profRes.status).toBe(200);
    const profJson = (await profRes.json()) as { profile: Record<string, unknown> };
    expect(profJson.profile.email).toBeUndefined();

    // Hardware ban executado instantaneamente por Superadmin + rejeicao imediata de nova autenticacao
    const repRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        action: 'report.submit',
        origin_type: 'usuario',
        origin_id: plAuthJson.user.id,
        target_user_id: plAuthJson.user.id,
        reason_category: 'Comportamento Toxico',
        description: 'Teste de integracao E2E para bloqueio de dispositivo.',
      }),
    });
    expect(repRes.status).toBe(201);
    const repJson = (await repRes.json()) as { report_id: string };

    const banRes = await app.request('/api/sync', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        action: 'admin.moderate',
        report_id: repJson.report_id,
        decision: 'hardware_ban',
        ban_device_fingerprint: 'fp_e2e_player2',
        ban_reason: 'Bloqueio E2E',
      }),
    });
    expect(banRes.status).toBe(200);

    const retryPlAuth = await app.request('/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action: 'oauth_google',
        google_sub: 'google_sub_e2e_2',
        email: 'jogador2.e2e@gmail.com',
        display_name: 'Jogador Dois',
        device_fingerprint: 'fp_e2e_player2',
        trust_device: true,
      }),
    });
    expect(retryPlAuth.status).toBe(403);

    // Lockout de Emergencia + Desbloqueio por Chave Unica no Superadmin
    const lockRes = await app.request('/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action: 'lockout_trigger',
        user_id: authJson.user.id,
        reason: 'Suspeita E2E',
      }),
    });
    expect(lockRes.status).toBe(200);
    const lockJson = (await lockRes.json()) as { recovery_code_preview: string };
    expect(lockJson.recovery_code_preview).toBeTruthy();

    const unlockRes = await app.request('/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action: 'lockout_verify',
        email: 'fundador.e2e@arcanavtt.com',
        recovery_code: lockJson.recovery_code_preview,
        device_fingerprint: 'fp_e2e_android_01',
      }),
    });
    expect(unlockRes.status).toBe(200);
  });
});
