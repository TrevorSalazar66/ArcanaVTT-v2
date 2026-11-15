import { beforeEach, describe, expect, it } from 'vitest';
import { InMemoryArcanaRepository } from '../src/data/in_memory_repository';
import { createApp } from '../src/index';
import { resetRateLimiterForTests } from '../src/middlewares/rate_limiter';

describe('Camada 3 — Testes E2E HTTP do Worker Cloudflare (/api/health, /api/auth, /api/sync)', () => {
  let app: ReturnType<typeof createApp>;

  beforeEach(() => {
    resetRateLimiterForTests();
    app = createApp(new InMemoryArcanaRepository());
  });

  it('GET /api/health deve retornar 200 OK com cabecalhos de seguranca', async () => {
    const res = await app.request('/api/health');
    expect(res.status).toBe(200);
    expect(res.headers.get('X-Frame-Options')).toBe('DENY');
    expect(res.headers.get('X-Content-Type-Options')).toBe('nosniff');

    const body = (await res.json()) as { ok: boolean; version: string };
    expect(body.ok).toBe(true);
    expect(body.version).toBe('0.1.0-fase-1');
  });

  it('POST /api/auth + /api/sync devem completar jornada OAuth -> Onboarding -> Chat 3d6 -> RBAC Admin', async () => {
    // 1. Login invalido Fail-Fast (Zod)
    const badRes = await app.request('/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'oauth_google', email: 'nao-e-email' }),
    });
    expect(badRes.status).toBe(400);

    // 2. Autenticacao valida Google OAuth 2.0 (papel mestre em teste)
    const authRes = await app.request(
      '/api/auth',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'oauth_google',
          google_sub: 'sub_e2e_mestre',
          email: 'e2e.mestre@gmail.com',
          display_name: 'Mestre E2E',
          birth_date: '1994-11-22',
          device_fingerprint: 'fp_e2e_android_14',
          trust_device: true,
          requested_role: 'mestre',
        }),
      },
      { ENVIRONMENT: 'test', JWT_SECRET: 'segredo-e2e-arcanavtt-test' },
    );
    expect(authRes.status).toBe(200);
    const authBody = (await authRes.json()) as { token: string; user: { role: string } };
    expect(authBody.token).toBeTruthy();
    expect(authBody.user.role).toBe('mestre');

    // 3. Setup de perfil (@username)
    const setupRes = await app.request(
      '/api/sync',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authBody.token}`,
        },
        body: JSON.stringify({
          action: 'profile.setup',
          username: 'mestre_e2e',
          display_name: 'Kronos E2E',
          bio: 'Mestrando campanhas taticas no celular.',
          theme_preference: 'oled',
          font_scale: 1.15,
        }),
      },
      { ENVIRONMENT: 'test', JWT_SECRET: 'segredo-e2e-arcanavtt-test' },
    );
    expect(setupRes.status).toBe(200);

    // 4. Criar campanha + enviar mensagem com rolagem 3d6 no chat comunitario
    const cmpRes = await app.request(
      '/api/sync',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authBody.token}`,
        },
        body: JSON.stringify({
          action: 'campaigns.create',
          title: 'A Torre de Obsidiana',
          synopsis: 'Uma expedicao noturna pelos saloes esquecidos da fortaleza.',
          max_slots: 5,
        }),
      },
      { ENVIRONMENT: 'test', JWT_SECRET: 'segredo-e2e-arcanavtt-test' },
    );
    expect(cmpRes.status).toBe(201);

    const chatRes = await app.request(
      '/api/sync',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authBody.token}`,
        },
        body: JSON.stringify({
          action: 'chat.send_message',
          channel_id: 'taverna-dos-mestres',
          content: 'Rolei o desafio inicial da torre!',
          with_3d6_roll: true,
          roll_label: 'TESTE DE MENTE (3D6)',
        }),
      },
      { ENVIRONMENT: 'test', JWT_SECRET: 'segredo-e2e-arcanavtt-test' },
    );
    expect(chatRes.status).toBe(201);
    const chatBody = (await chatRes.json()) as {
      dice_roll: { dice: number[]; successes: number };
    };
    expect(chatBody.dice_roll.dice).toHaveLength(3);

    // 5. Tentativa de acessar rota Admin com papel Mestre -> 403 Zero-Trust
    const adminRes = await app.request(
      '/api/sync',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authBody.token}`,
        },
        body: JSON.stringify({ action: 'admin.overview' }),
      },
      { ENVIRONMENT: 'test', JWT_SECRET: 'segredo-e2e-arcanavtt-test' },
    );
    expect(adminRes.status).toBe(403);
  });
});

