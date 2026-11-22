import { describe, expect, it } from 'vitest';
import { InMemoryArcanaRepository } from '../src/data/in_memory_repository';
import {
  auditDmsSuperadminUseCase,
  generateSystemCreationKeyUseCase,
  moderateReportUseCase,
  unbanDeviceAdminUseCase,
  updateUserRoleAdminUseCase,
} from '../src/domain/usecases/admin_governance';
import { authenticateGoogleOAuth } from '../src/domain/usecases/authenticate_google_oauth';
import {
  applyToCampaignUseCase,
  createCampaignUseCase,
  manageCampaignMemberUseCase,
  triggerSceneActionUseCase,
  unbanPlayerFromGmUseCase,
  upsertCampaignSceneUseCase,
} from '../src/domain/usecases/manage_campaigns';
import {
  addFriendUseCase,
  getSocialProfileUseCase,
  respondFriendUseCase,
  sendDmMessageUseCase,
  upsertCharacterUseCase,
} from '../src/domain/usecases/manage_social';
import { createSystemUseCase, listSystemsUseCase, upsertCompendiumItemUseCase } from '../src/domain/usecases/manage_systems';
import { setupUserProfile } from '../src/domain/usecases/setup_user_profile';
import { submitUniversalReportUseCase } from '../src/domain/usecases/submit_universal_report';

describe('Layer 2 — Integration Tests: Banco, Zero-Seed, Privacidade, Colegiado Admin & Motor Universal', () => {
  it('inicia com catalogo de sistemas zero (sem AlphaD6 hardcoded) e bloqueia < 16 anos', async () => {
    const repo = new InMemoryArcanaRepository();

    await expect(
      authenticateGoogleOAuth(
        {
          action: 'oauth_google',
          google_sub: 'sub_minor',
          email: 'minor@example.com',
          display_name: 'Menor',
          birth_date: '2016-01-01',
          device_fingerprint: 'fp_minor',
          trust_device: true,
        },
        repo,
      ),
    ).rejects.toThrowError(/minimo 16 anos/i);

    const first = await authenticateGoogleOAuth(
      {
        action: 'oauth_google',
        google_sub: 'sub_super',
        email: 'fundador@arcanavtt.com',
        display_name: 'Fundador',
        birth_date: '1994-05-10',
        device_fingerprint: 'fp_super',
        trust_device: true,
      },
      repo,
    );
    expect(first.user.role).toBe('superadmin');
    expect(first.trusted_device_days).toBe(15);

    const sysList = await listSystemsUseCase(
      first.user.id,
      { action: 'systems.list', segment: 'todos' },
      repo,
    );
    expect(sysList.systems).toHaveLength(0);
  });

  it('exige Key de Criacao para jogador criar sistema, aplica heranca delta, limite 1 ficha/mesa e Ban por Mestre', async () => {
    const repo = new InMemoryArcanaRepository();

    const superAuth = await authenticateGoogleOAuth(
      {
        action: 'oauth_google',
        google_sub: 'sub_sa',
        email: 'sa@arcana.gg',
        display_name: 'Superadmin',
        birth_date: '1992-01-01',
        device_fingerprint: 'fp_sa',
        trust_device: true,
      },
      repo,
    );

    const gmAuth = await authenticateGoogleOAuth(
      {
        action: 'oauth_google',
        google_sub: 'sub_gm',
        email: 'mestre@arcana.gg',
        display_name: 'Mestre',
        birth_date: '1995-02-02',
        device_fingerprint: 'fp_gm',
        trust_device: true,
      },
      repo,
    );
    expect(gmAuth.user.role).toBe('jogador');

    await updateUserRoleAdminUseCase(
      {
        userId: superAuth.user.id,
        email: superAuth.user.email,
        role: 'superadmin',
        jti: 'jti_sa',
        deviceFingerprint: 'fp_sa',
        onboardingCompleted: 1,
      },
      { action: 'admin.update_role', target_user_id: gmAuth.user.id, role: 'mestre' },
      repo,
    );

    const playerAuth = await authenticateGoogleOAuth(
      {
        action: 'oauth_google',
        google_sub: 'sub_pl',
        email: 'jogador.privado@gmail.com',
        display_name: 'Jogador',
        birth_date: '1998-03-03',
        device_fingerprint: 'fp_pl',
        trust_device: true,
      },
      repo,
    );

    await setupUserProfile(
      gmAuth.user.id,
      {
        action: 'profile.setup',
        username: 'mestre_guia',
        display_name: 'Mestre Guia',
        bio: 'Narrador',
        contacts: { discord: 'mestre#0001', youtube: '@mestretaverna' },
      },
      repo,
    );
    await setupUserProfile(
      playerAuth.user.id,
      {
        action: 'profile.setup',
        username: 'kael_arqueiro',
        display_name: 'Kael',
        bio: 'Explorador',
      },
      repo,
    );

    // O Perfil Social nunca deve expor o e-mail Google privado do usuario
    const socialView = await getSocialProfileUseCase(
      gmAuth.user.id,
      { action: 'social.get_profile', user_id: playerAuth.user.id },
      repo,
    );
    expect((socialView.profile as Record<string, unknown>).email).toBeUndefined();
    expect(socialView.profile.oauth_verified).toBe(true);

    // Bloqueia forja de sistema sem Key para nao-Admin
    await expect(
      createSystemUseCase(
        {
          userId: gmAuth.user.id,
          email: gmAuth.user.email,
          role: 'mestre',
          jti: 'jti_gm',
          deviceFingerprint: 'fp_gm',
          onboardingCompleted: 1,
        },
        {
          action: 'systems.create',
          name: 'Daggerheart Custom',
          version: 'v1.0',
          dice_engine: '2d12',
          description: 'Sistema dual hope and fear customizado.',
          attributes: ['Agilidade', 'Forca', 'Instinto'],
          is_official: false,
        },
        repo,
      ),
    ).rejects.toThrowError(/Key de Criacao/i);

    const issuedKey = await generateSystemCreationKeyUseCase(
      {
        userId: superAuth.user.id,
        email: superAuth.user.email,
        role: 'superadmin',
        jti: 'jti_sa',
        deviceFingerprint: 'fp_sa',
        onboardingCompleted: 1,
      },
      gmAuth.user.id,
      repo,
    );

    const sysRes = await createSystemUseCase(
      {
        userId: gmAuth.user.id,
        email: gmAuth.user.email,
        role: 'mestre',
        jti: 'jti_gm',
        deviceFingerprint: 'fp_gm',
        onboardingCompleted: 1,
      },
      {
        action: 'systems.create',
        name: 'Motor Arcano 2d12',
        version: 'v1.0',
        dice_engine: '2d12',
        description: 'Sistema dinamico com Hope & Fear.',
        attributes: ['Coragem', 'Astucia'],
        creation_key: issuedKey.key.code,
        is_official: false,
      },
      repo,
    );
    expect(sysRes.system.name).toBe('Motor Arcano 2d12');

    // Compendio Delta + RoleGate
    const swordBase = await upsertCompendiumItemUseCase(
      {
        userId: gmAuth.user.id,
        email: gmAuth.user.email,
        role: 'mestre',
        jti: 'jti_gm',
        deviceFingerprint: 'fp_gm',
        onboardingCompleted: 1,
      },
      {
        action: 'compendium.upsert',
        system_id: sysRes.system.id,
        category: 'equipamentos',
        name: 'Espada Longa',
        rarity: 'Comum',
        slots_weight: 2,
        description: 'Lamina padrao de aco.',
        is_all_hidden: false,
        base_asset_id: 'swords',
        blocks: {
          ataque: { label: 'Corte', dice_formula: '1d8+2', is_visible: true },
        },
      },
      repo,
    );
    const props = JSON.parse(swordBase.item.properties_json) as Record<string, Record<string, unknown>>;
    expect((props.blocks!.ataque as Record<string, unknown>).parsed_range).toEqual({ min: 3, max: 10 });

    // Campanha + Entrada + 1 Ficha por Jogador + Cenas/Gatilhos + Banimento pelo Mestre
    const cmpRes = await createCampaignUseCase(
      {
        userId: gmAuth.user.id,
        email: gmAuth.user.email,
        role: 'mestre',
        jti: 'jti_gm',
        deviceFingerprint: 'fp_gm',
        onboardingCompleted: 1,
      },
      {
        action: 'campaigns.create',
        title: 'Vales de Cinza',
        synopsis: 'Exploracao tatica e investigacao em ruinas.',
        system_id: sysRes.system.id,
        mode: 'ao_vivo',
        schedule_text: 'Sabado 20h',
        max_slots: 5,
        visibility: 'publica',
        icon_name: 'swords',
        banner_preset: 'cidadela_obsidiana',
        age_rating: '16+',
        tags: ['Investigacao', 'Fantasia'],
      },
      repo,
    );

    await applyToCampaignUseCase(
      playerAuth.user.id,
      {
        action: 'campaigns.apply',
        campaign_id: cmpRes.campaign.id,
        pitch: 'Sou explorador assiduo e pontual.',
      },
      repo,
    );

    await manageCampaignMemberUseCase(
      {
        userId: gmAuth.user.id,
        email: gmAuth.user.email,
        role: 'mestre',
        jti: 'jti_gm',
        deviceFingerprint: 'fp_gm',
        onboardingCompleted: 1,
      },
      {
        action: 'campaigns.manage_member',
        campaign_id: cmpRes.campaign.id,
        target_user_id: playerAuth.user.id,
        status: 'active',
      },
      repo,
    );

    const firstChar = await upsertCharacterUseCase(
      playerAuth.user.id,
      {
        action: 'characters.upsert',
        campaign_id: cmpRes.campaign.id,
        name: 'Kaelen',
        title: 'Rastreador',
        system_id: sysRes.system.id,
        level: 2,
        corpo: 3,
        mente: 2,
        espirito: 2,
        hp_current: 22,
        hp_max: 22,
        anima_current: 10,
        anima_max: 10,
        exhaustion: 0,
        slots: ['Arco Longo'],
      },
      repo,
    );

    await expect(
      upsertCharacterUseCase(
        playerAuth.user.id,
        {
          action: 'characters.upsert',
          id: 'chr_tentativa_extra',
          campaign_id: cmpRes.campaign.id,
          name: 'Segundo Heroi',
          title: 'Clerigo',
          system_id: sysRes.system.id,
          level: 1,
          corpo: 1,
          mente: 3,
          espirito: 3,
          hp_current: 16,
          hp_max: 16,
          anima_current: 12,
          anima_max: 12,
          exhaustion: 0,
          slots: [],
        },
        repo,
      ),
    ).rejects.toThrowError(/maximo 1 personagem por mesa/i);
    expect(firstChar.character.id).toBeTruthy();

    // Gatilho No-Code [QUANDO]->[SE]->[ENTÃO] concedendo item na ficha do jogador
    const scnRes = await upsertCampaignSceneUseCase(
      {
        userId: gmAuth.user.id,
        email: gmAuth.user.email,
        role: 'mestre',
        jti: 'jti_gm',
        deviceFingerprint: 'fp_gm',
        onboardingCompleted: 1,
      },
      {
        action: 'scenes.upsert',
        campaign_id: cmpRes.campaign.id,
        name: 'Portao do Cofre',
        description: 'Entrada secreta',
        model_type: 'password',
        is_active: true,
        max_players: 5,
        model_data: { digits: 4 },
        rules_data: [
          {
            trigger: { type: 'password_solved' },
            conditions: [{ type: 'attribute_gte', attribute: 'mente', value: 2 }],
            effects: [
              { type: 'show_toast', params: { message: 'Cofre aberto!' } },
              { type: 'award_item', params: { item_name: 'Chave de Obsidiana' } },
            ],
          },
        ],
        state_data: {},
      },
      repo,
    );

    const trigRes = await triggerSceneActionUseCase(
      {
        userId: playerAuth.user.id,
        email: playerAuth.user.email,
        role: 'jogador',
        jti: 'jti_pl',
        deviceFingerprint: 'fp_pl',
        onboardingCompleted: 1,
      },
      {
        action: 'scenes.trigger',
        campaign_id: cmpRes.campaign.id,
        scene_id: scnRes.scene.id,
        trigger_type: 'password_solved',
        params: {},
      },
      repo,
    );
    expect(trigRes.toasts).toContain('Cofre aberto!');
    const updatedChar = await repo.findCharacterByUserAndCampaign(
      playerAuth.user.id,
      cmpRes.campaign.id,
    );
    expect(JSON.parse(updatedChar!.slots_json)).toContain('Chave de Obsidiana');

    // Master-Level Ban: bane jogador do Mestre em todas as suas campanhas e depois desbane
    await manageCampaignMemberUseCase(
      {
        userId: gmAuth.user.id,
        email: gmAuth.user.email,
        role: 'mestre',
        jti: 'jti_gm',
        deviceFingerprint: 'fp_gm',
        onboardingCompleted: 1,
      },
      {
        action: 'campaigns.manage_member',
        campaign_id: cmpRes.campaign.id,
        target_user_id: playerAuth.user.id,
        status: 'banned',
        ban_reason: 'Metagame abusivo',
      },
      repo,
    );

    await expect(
      applyToCampaignUseCase(
        playerAuth.user.id,
        { action: 'campaigns.apply', campaign_id: cmpRes.campaign.id, pitch: 'Desculpa!' },
        repo,
      ),
    ).rejects.toThrowError(/banido pelo Mestre/i);

    await unbanPlayerFromGmUseCase(
      {
        userId: gmAuth.user.id,
        email: gmAuth.user.email,
        role: 'mestre',
        jti: 'jti_gm',
        deviceFingerprint: 'fp_gm',
        onboardingCompleted: 1,
      },
      playerAuth.user.id,
      repo,
    );
    expect(await repo.isPlayerBannedByGM(gmAuth.user.id, playerAuth.user.id)).toBe(false);
  });

  it('executa DM privada 1-a-1 com bloqueio, auditoria Superadmin e Votacao Colegiada de 3 Admins', async () => {
    const repo = new InMemoryArcanaRepository();
    const superAuth = await authenticateGoogleOAuth(
      {
        action: 'oauth_google',
        google_sub: 'sa2',
        email: 'sa2@arcana.gg',
        display_name: 'Super',
        birth_date: '1990-01-01',
        device_fingerprint: 'fp_sa2',
        trust_device: true,
      },
      repo,
    );
    const saUser = {
      userId: superAuth.user.id,
      email: superAuth.user.email,
      role: 'superadmin' as const,
      jti: 'jti_sa2',
      deviceFingerprint: 'fp_sa2',
      onboardingCompleted: 1,
    };

    const admins: Array<{ userId: string; email: string; role: 'admin'; jti: string; deviceFingerprint: string; onboardingCompleted: number }> = [];
    for (let i = 1; i <= 3; i += 1) {
      const a = await authenticateGoogleOAuth(
        {
          action: 'oauth_google',
          google_sub: `adm_${i}`,
          email: `adm${i}@arcana.gg`,
          display_name: `Admin ${i}`,
          birth_date: '1991-01-01',
          device_fingerprint: `fp_adm_${i}`,
          trust_device: true,
        },
        repo,
      );
      await updateUserRoleAdminUseCase(
        saUser,
        { action: 'admin.update_role', target_user_id: a.user.id, role: 'admin' },
        repo,
      );
      admins.push({
        userId: a.user.id,
        email: a.user.email,
        role: 'admin',
        jti: `jti_adm_${i}`,
        deviceFingerprint: `fp_adm_${i}`,
        onboardingCompleted: 1,
      });
    }

    const trollAuth = await authenticateGoogleOAuth(
      {
        action: 'oauth_google',
        google_sub: 'troll_1',
        email: 'troll@arcana.gg',
        display_name: 'Troll',
        birth_date: '1999-01-01',
        device_fingerprint: 'fp_troll_dev',
        trust_device: true,
      },
      repo,
    );
    await setupUserProfile(
      trollAuth.user.id,
      { action: 'profile.setup', username: 'troll_x', display_name: 'Troll X', bio: '' },
      repo,
    );
    await setupUserProfile(
      admins[0]!.userId,
      { action: 'profile.setup', username: 'adm_um', display_name: 'Adm Um', bio: '' },
      repo,
    );

    // Amizade + DM 1-a-1
    await addFriendUseCase(admins[0]!.userId, { action: 'social.add_friend', username: 'troll_x' }, repo);
    await sendDmMessageUseCase(
      admins[0]!.userId,
      'admin',
      {
        action: 'dm.send_message',
        peer_user_id: trollAuth.user.id,
        content: 'Aviso oficial em privado',
        roll_expression: '1d20',
      },
      repo,
    );

    const audited = await auditDmsSuperadminUseCase(saUser, admins[0]!.userId, trollAuth.user.id, repo);
    expect(audited.messages).toHaveLength(1);
    expect(audited.messages[0]!.content).toBe('Aviso oficial em privado');

    // Bloqueio em DM
    await respondFriendUseCase(
      trollAuth.user.id,
      { action: 'social.respond_friend', friend_user_id: admins[0]!.userId, decision: 'block' },
      repo,
    );
    await expect(
      sendDmMessageUseCase(
        admins[0]!.userId,
        'admin',
        { action: 'dm.send_message', peer_user_id: trollAuth.user.id, content: 'Oi' },
        repo,
      ),
    ).rejects.toThrowError(/bloqueou mensagens diretas/i);

    // Denuncia e Votacao Colegiada de 3 Admins para hardware_ban
    const rep = await submitUniversalReportUseCase(
      admins[0]!,
      {
        action: 'report.submit',
        origin_type: 'dm',
        origin_id: audited.channel_id,
        target_user_id: trollAuth.user.id,
        reason_category: 'Ofensa Grave',
        description: 'Discurso de odio persistente em DM.',
        context_session: 'sess_1',
      },
      repo,
    );

    const vote1 = await moderateReportUseCase(
      admins[0]!,
      { action: 'admin.moderate', report_id: rep.report_id, decision: 'hardware_ban' },
      repo,
    );
    expect(vote1.status).toBe('pending');
    expect(vote1.votes_count).toBe(1);

    const vote2 = await moderateReportUseCase(
      admins[1]!,
      { action: 'admin.moderate', report_id: rep.report_id, decision: 'hardware_ban' },
      repo,
    );
    expect(vote2.status).toBe('pending');
    expect(vote2.votes_count).toBe(2);

    const vote3 = await moderateReportUseCase(
      admins[2]!,
      { action: 'admin.moderate', report_id: rep.report_id, decision: 'hardware_ban' },
      repo,
    );
    expect(vote3.status).toBe('resolved');
    expect(vote3.votes_count).toBe(3);

    const devAfterBan = await repo.findDeviceSecurity('fp_troll_dev');
    expect(devAfterBan?.is_hardware_banned).toBe(1);

    await unbanDeviceAdminUseCase(saUser, 'fp_troll_dev', repo);
    const devAfterUnban = await repo.findDeviceSecurity('fp_troll_dev');
    expect(devAfterUnban?.is_hardware_banned).toBe(0);
  });
});
