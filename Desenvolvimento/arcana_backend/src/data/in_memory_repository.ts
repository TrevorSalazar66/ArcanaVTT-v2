import type {
  AdminUserSummaryRecord,
  CampaignMemberDetailRecord,
  CampaignMemberRecord,
  CampaignRecord,
  CharacterRecord,
  ChatMessageRecord,
  CompendiumItemRecord,
  DeviceSecurityRecord,
  ForumTopicRecord,
  FriendshipRecord,
  GuildRecord,
  IArcanaRepository,
  NotificationRecord,
  P2pSignalRecord,
  SessionRecord,
  SystemRecord,
  UniversalReportRecord,
  UserProfileRecord,
  UserRecord,
} from './interfaces';
import type { AccountStatus, UserRole } from '../types/env';

/**
 * Repositório em memória espelhando fielmente o schema D1 (usado nos testes automatizados e dev sem DB).
 */
export class InMemoryArcanaRepository implements IArcanaRepository {
  public users = new Map<string, UserRecord>();
  public profiles = new Map<string, UserProfileRecord>();
  public devices = new Map<string, DeviceSecurityRecord>();
  public sessions = new Map<string, SessionRecord>();
  public systems = new Map<string, SystemRecord>();
  public campaigns = new Map<string, CampaignRecord>();
  public memberships: CampaignMemberRecord[] = [];
  public compendium: CompendiumItemRecord[] = [];
  public guilds: GuildRecord[] = [];
  public topics: ForumTopicRecord[] = [];
  public messages: ChatMessageRecord[] = [];
  public friendships: FriendshipRecord[] = [];
  public notifications: NotificationRecord[] = [];
  public characters = new Map<string, CharacterRecord>();
  public reports: UniversalReportRecord[] = [];
  public p2pSignals: P2pSignalRecord[] = [];

  constructor(options?: { withTestFixtures?: boolean }) {
    this.seedCanonicalSystem();
    if (options?.withTestFixtures) {
      this.seedTestFixtures();
    }
  }

  private seedCanonicalSystem(): void {
    const baseTime = '2026-01-01T00:00:00.000Z';
    this.users.set('usr_system_official', {
      id: 'usr_system_official',
      google_sub: 'sub_system_official',
      email: 'system@arcanavtt.app',
      birth_date: '1990-01-01',
      role: 'superadmin',
      account_status: 'active',
      lockout_token_hash: null,
      created_at: baseTime,
      updated_at: baseTime,
    });

    this.profiles.set('usr_system_official', {
      user_id: 'usr_system_official',
      username: 'arcanavtt_oficial',
      display_name: 'ArcanaVTT Oficial',
      bio: 'Mantenedor técnico do sistema oficial AlphaD6 Core.',
      avatar_icon: 'crown',
      preferred_role: 'superadmin',
      reputation_points: 0,
      theme_preference: 'escuro_heraldico',
      font_scale: 1.0,
      onboarding_completed: 1,
      updated_at: baseTime,
    });

    this.systems.set('sys_alphad6_v24', {
      id: 'sys_alphad6_v24',
      author_id: 'usr_system_official',
      name: 'AlphaD6 Core',
      version: 'v2.4',
      category_type: 'oficiais',
      dice_engine: '3d6',
      description: 'Sistema oficial Dark Fantasy baseado em rolagem de 3d6 e 12 slots.',
      rules_json: '{"attributes":["Corpo","Mente","Espirito"],"inventory_slots":12}',
      downloads_count: 0,
      rating: 5.0,
      is_official: 1,
      created_at: baseTime,
    });

    this.compendium.push(
      {
        id: 'item_espada_runica',
        system_id: 'sys_alphad6_v24',
        campaign_id: null,
        category: 'equipamentos',
        name: 'Espada Runica de Ferro Negro',
        rarity: 'Raro',
        slots_weight: 2,
        description: 'Lamina runica contra espectros.',
        properties_json: '{}',
        created_at: baseTime,
      },
      {
        id: 'item_elixir_anima',
        system_id: 'sys_alphad6_v24',
        campaign_id: null,
        category: 'itens',
        name: 'Elixir de Anima Concentrada',
        rarity: 'Incomum',
        slots_weight: 1,
        description: 'Restaura 4 pontos de Anima.',
        properties_json: '{}',
        created_at: baseTime,
      },
      {
        id: 'item_sentinela_cinza',
        system_id: 'sys_alphad6_v24',
        campaign_id: null,
        category: 'seres',
        name: 'Sentinela das Cinzas',
        rarity: 'Epico',
        slots_weight: 0,
        description: 'Automato de armadura oca movido por brasas arcanas.',
        properties_json: '{}',
        created_at: baseTime,
      },
      {
        id: 'item_selo_chama',
        system_id: 'sys_alphad6_v24',
        campaign_id: null,
        category: 'poderes',
        name: 'Selo da Chama Eterna',
        rarity: 'Raro',
        slots_weight: 0,
        description: 'Conjura um escudo circular dourado que reduz dano em 2.',
        properties_json: '{}',
        created_at: baseTime,
      },
      {
        id: 'item_pergaminho_valen',
        system_id: 'sys_alphad6_v24',
        campaign_id: null,
        category: 'pistas',
        name: 'Pergaminho do Pacto de Valen',
        rarity: 'Unico',
        slots_weight: 1,
        description: 'Documento rasgado revelando o nome verdadeiro do arquimago.',
        properties_json: '{}',
        created_at: baseTime,
      },
    );
  }

  private seedTestFixtures(): void {
    const baseTime = '2026-01-01T00:00:00.000Z';
    const seedUsers: UserRecord[] = [
      {
        id: 'usr_admin_thorin',
        google_sub: 'sub_admin_thorin',
        email: 'thorin@arcanavtt.app',
        birth_date: '1992-05-14',
        role: 'superadmin',
        account_status: 'active',
        lockout_token_hash: null,
        created_at: baseTime,
        updated_at: baseTime,
      },
      {
        id: 'usr_mestre_cypher',
        google_sub: 'sub_mestre_cypher',
        email: 'cypher@arcanavtt.app',
        birth_date: '1995-08-21',
        role: 'mestre',
        account_status: 'active',
        lockout_token_hash: null,
        created_at: baseTime,
        updated_at: baseTime,
      },
      {
        id: 'usr_valen_bard',
        google_sub: 'sub_valen_bard',
        email: 'valen@arcanavtt.app',
        birth_date: '2001-03-10',
        role: 'jogador',
        account_status: 'active',
        lockout_token_hash: null,
        created_at: baseTime,
        updated_at: baseTime,
      },
    ];
    for (const u of seedUsers) this.users.set(u.id, u);

    const seedProfiles: UserProfileRecord[] = [
      {
        user_id: 'usr_admin_thorin',
        username: 'admin_thorin',
        display_name: 'Thorin Guardiao',
        bio: 'Arquiteto do Sistema Oficial AlphaD6.',
        avatar_icon: 'crown',
        preferred_role: 'superadmin',
        reputation_points: 990,
        theme_preference: 'escuro_heraldico',
        font_scale: 1.0,
        onboarding_completed: 1,
        updated_at: baseTime,
      },
      {
        user_id: 'usr_mestre_cypher',
        username: 'mestre_cypher',
        display_name: 'Mestre Cypher',
        bio: 'Cronista de masmorras taticas.',
        avatar_icon: 'scroll',
        preferred_role: 'mestre',
        reputation_points: 640,
        theme_preference: 'escuro_heraldico',
        font_scale: 1.0,
        onboarding_completed: 1,
        updated_at: baseTime,
      },
      {
        user_id: 'usr_valen_bard',
        username: 'valen_bard',
        display_name: 'Valen Voss',
        bio: 'Explorador das Terras Cinzentas.',
        avatar_icon: 'swords',
        preferred_role: 'jogador',
        reputation_points: 320,
        theme_preference: 'escuro_heraldico',
        font_scale: 1.0,
        onboarding_completed: 1,
        updated_at: baseTime,
      },
    ];
    for (const p of seedProfiles) this.profiles.set(p.user_id, p);

    this.systems.set('sys_lamina_carmesim', {
      id: 'sys_lamina_carmesim',
      author_id: 'usr_mestre_cypher',
      name: 'Lamina Carmesim',
      version: 'v1.2',
      category_type: 'comunidade',
      dice_engine: '3d6',
      description: 'Adaptacao minimalista focada em esgrima.',
      rules_json: '{"attributes":["Acuidade","Engenho","Vontade"]}',
      downloads_count: 3120,
      rating: 4.7,
      is_official: 0,
      created_at: baseTime,
    });

    this.campaigns.set('cmp_valen_01', {
      id: 'cmp_valen_01',
      owner_id: 'usr_mestre_cypher',
      title: 'A Maldicao de Valen',
      synopsis: 'Os sinos da Capela Submersa voltaram a tocar.',
      system_id: 'sys_alphad6_v24',
      quick_join_code: 'ARC774',
      mode: 'ao_vivo',
      schedule_text: 'Sab 20h',
      max_slots: 5,
      occupied_slots: 4,
      visibility: 'publica',
      state_json: '{}',
      created_at: baseTime,
    });

    this.compendium.push({
      id: 'item_golpe_carmesim',
      system_id: 'sys_lamina_carmesim',
      campaign_id: null,
      category: 'poderes',
      name: 'Golpe Carmesim',
      rarity: 'Raro',
      slots_weight: 0,
      description: 'Tecnica exclusiva de duelo.',
      properties_json: '{}',
      created_at: baseTime,
    });

    this.guilds.push({
      id: 'gld_chama_cinzenta',
      leader_id: 'usr_mestre_cypher',
      name: 'Ordem da Chama Cinzenta',
      tag: 'CHAMA',
      description: 'Guilda de mundo compartilhado em Valen.',
      member_count: 42,
      active_tables_count: 6,
      boost_points: 780,
      boost_goal: 1000,
      shared_world_json: '{}',
      created_at: baseTime,
    });

    this.topics.push({
      id: 'top_balanceamento_3d6',
      author_id: 'usr_mestre_cypher',
      author_handle: '@mestre_cypher',
      category: 'Regras & Oficina',
      title: 'Guia de balanceamento de encontros 3d6',
      content: 'Mantenha o limiar de sucesso em 5 ou 6 para combates taticos.',
      upvotes: 29,
      replies_count: 8,
      pinned: 1,
      created_at: baseTime,
    });

    this.messages.push({
      id: 'msg_01',
      channel_id: 'taverna-dos-mestres',
      sender_id: 'usr_mestre_cypher',
      sender_handle: '@mestre_cypher',
      sender_role: 'mestre',
      content: 'Alguem ja testou o encontro na cripta com nevoa densa?',
      reply_to_id: null,
      reply_preview: null,
      dice_roll_json: null,
      created_at: baseTime,
    });
  }

  async findUserByGoogleSubOrEmail(
    googleSub: string,
    email: string,
  ): Promise<UserRecord | null> {
    for (const user of this.users.values()) {
      if (user.google_sub === googleSub || user.email === email) {
        return user;
      }
    }
    return null;
  }

  async findUserById(userId: string): Promise<UserRecord | null> {
    return this.users.get(userId) ?? null;
  }

  async countRealUsers(): Promise<number> {
    let count = 0;
    for (const id of this.users.keys()) {
      if (id !== 'usr_system_official') count += 1;
    }
    return count;
  }

  async updateUserRole(userId: string, role: UserRole): Promise<void> {
    const user = this.users.get(userId);
    if (user) {
      this.users.set(userId, {
        ...user,
        role,
        updated_at: new Date().toISOString(),
      });
    }
  }

  async updateUserBirthDate(userId: string, birthDate: string): Promise<void> {
    const user = this.users.get(userId);
    if (user) {
      this.users.set(userId, {
        ...user,
        birth_date: birthDate,
        updated_at: new Date().toISOString(),
      });
    }
  }

  async createUserWithProfile(
    user: UserRecord,
    profile: UserProfileRecord,
  ): Promise<void> {
    this.users.set(user.id, user);
    this.profiles.set(profile.user_id, profile);
  }

  async updateUserStatusAndLockout(
    userId: string,
    status: AccountStatus,
    lockoutHash: string | null,
  ): Promise<void> {
    const user = this.users.get(userId);
    if (user) {
      this.users.set(userId, {
        ...user,
        account_status: status,
        lockout_token_hash: lockoutHash,
        updated_at: new Date().toISOString(),
      });
    }
  }

  async listUsersWithProfiles(): Promise<AdminUserSummaryRecord[]> {
    const out: AdminUserSummaryRecord[] = [];
    for (const user of this.users.values()) {
      if (user.id === 'usr_system_official') continue;
      const profile = this.profiles.get(user.id);
      out.push({
        id: user.id,
        email: user.email,
        birth_date: user.birth_date,
        role: user.role,
        account_status: user.account_status,
        created_at: user.created_at,
        username: profile?.username ?? '',
        display_name: profile?.display_name ?? user.email,
      });
    }
    return out;
  }

  async findProfileByUserId(userId: string): Promise<UserProfileRecord | null> {
    return this.profiles.get(userId) ?? null;
  }

  async findProfileByUsername(username: string): Promise<UserProfileRecord | null> {
    for (const profile of this.profiles.values()) {
      if (profile.username === username) return profile;
    }
    return null;
  }

  async updateProfile(profile: UserProfileRecord): Promise<void> {
    this.profiles.set(profile.user_id, profile);
  }

  async findDeviceSecurity(
    fingerprint: string,
  ): Promise<DeviceSecurityRecord | null> {
    return this.devices.get(fingerprint) ?? null;
  }

  async upsertDeviceSecurity(record: DeviceSecurityRecord): Promise<void> {
    this.devices.set(record.device_fingerprint, record);
  }

  async createSession(session: SessionRecord): Promise<void> {
    this.sessions.set(session.token_jti, session);
  }

  async findSessionByJti(jti: string): Promise<SessionRecord | null> {
    return this.sessions.get(jti) ?? null;
  }

  async revokeSessionByJti(jti: string): Promise<void> {
    const existing = this.sessions.get(jti);
    if (existing) {
      this.sessions.set(jti, { ...existing, revoked: 1 });
    }
  }

  async revokeAllUserSessions(userId: string): Promise<void> {
    for (const [jti, session] of this.sessions.entries()) {
      if (session.user_id === userId) {
        this.sessions.set(jti, { ...session, revoked: 1 });
      }
    }
  }

  async listCampaigns(): Promise<CampaignRecord[]> {
    return Array.from(this.campaigns.values());
  }

  async listCampaignMembershipsByUser(
    userId: string,
  ): Promise<CampaignMemberRecord[]> {
    return this.memberships.filter((m) => m.user_id === userId);
  }

  async listCampaignMembersByCampaign(
    campaignId: string,
  ): Promise<CampaignMemberDetailRecord[]> {
    return this.memberships
      .filter((m) => m.campaign_id === campaignId)
      .map((m) => {
        const profile = this.profiles.get(m.user_id);
        return {
          ...m,
          username: profile?.username ?? '',
          display_name: profile?.display_name ?? '',
        };
      });
  }

  async findCampaignMember(
    campaignId: string,
    userId: string,
  ): Promise<CampaignMemberRecord | null> {
    return (
      this.memberships.find(
        (m) => m.campaign_id === campaignId && m.user_id === userId,
      ) ?? null
    );
  }

  async findCampaignByCode(code: string): Promise<CampaignRecord | null> {
    const norm = code.trim().toUpperCase();
    for (const c of this.campaigns.values()) {
      if (c.quick_join_code.toUpperCase() === norm) return c;
    }
    return null;
  }

  async findCampaignById(id: string): Promise<CampaignRecord | null> {
    return this.campaigns.get(id) ?? null;
  }

  async createCampaign(
    campaign: CampaignRecord,
    ownerMembership: CampaignMemberRecord,
  ): Promise<void> {
    this.campaigns.set(campaign.id, campaign);
    this.memberships.push(ownerMembership);
  }

  async upsertCampaignMember(member: CampaignMemberRecord): Promise<void> {
    const idx = this.memberships.findIndex(
      (m) => m.campaign_id === member.campaign_id && m.user_id === member.user_id,
    );
    if (idx >= 0) {
      this.memberships[idx] = member;
    } else {
      this.memberships.push(member);
    }
  }

  async incrementCampaignOccupiedSlots(campaignId: string): Promise<void> {
    const cmp = this.campaigns.get(campaignId);
    if (cmp) {
      this.campaigns.set(campaignId, {
        ...cmp,
        occupied_slots: cmp.occupied_slots + 1,
      });
    }
  }

  async listSystems(): Promise<SystemRecord[]> {
    return Array.from(this.systems.values());
  }

  async createSystem(system: SystemRecord): Promise<void> {
    this.systems.set(system.id, system);
  }

  async listCompendiumBySystem(systemId: string): Promise<CompendiumItemRecord[]> {
    return this.compendium.filter((item) => item.system_id === systemId);
  }

  async listGuilds(): Promise<GuildRecord[]> {
    return [...this.guilds];
  }

  async createGuild(guild: GuildRecord): Promise<void> {
    this.guilds.unshift(guild);
  }

  async boostGuild(guildId: string, points: number): Promise<GuildRecord | null> {
    const idx = this.guilds.findIndex((g) => g.id === guildId);
    if (idx < 0) return null;
    const current = this.guilds[idx]!;
    const updated: GuildRecord = {
      ...current,
      boost_points: Math.min(current.boost_goal, current.boost_points + points),
    };
    this.guilds[idx] = updated;
    return updated;
  }

  async listForumTopics(): Promise<ForumTopicRecord[]> {
    return [...this.topics];
  }

  async createForumTopic(topic: ForumTopicRecord): Promise<void> {
    this.topics.unshift(topic);
  }

  async upvoteForumTopic(topicId: string): Promise<ForumTopicRecord | null> {
    const topic = this.topics.find((t) => t.id === topicId);
    if (!topic) return null;
    topic.upvotes += 1;
    return topic;
  }

  async listChatMessages(channelId: string): Promise<ChatMessageRecord[]> {
    return this.messages.filter((m) => m.channel_id === channelId);
  }

  async findChatMessageById(messageId: string): Promise<ChatMessageRecord | null> {
    return this.messages.find((m) => m.id === messageId) ?? null;
  }

  async createChatMessage(message: ChatMessageRecord): Promise<void> {
    this.messages.push(message);
  }

  async listFriendships(userId: string): Promise<FriendshipRecord[]> {
    return this.friendships
      .filter((f) => f.user_id === userId)
      .map((f) => {
        const friendProfile = this.profiles.get(f.friend_id);
        return {
          ...f,
          friend_username: f.friend_username ?? friendProfile?.username,
          friend_display_name: f.friend_display_name ?? friendProfile?.display_name,
        };
      });
  }

  async addFriendship(record: FriendshipRecord): Promise<void> {
    const idx = this.friendships.findIndex(
      (f) => f.user_id === record.user_id && f.friend_id === record.friend_id,
    );
    if (idx >= 0) {
      this.friendships[idx] = record;
    } else {
      this.friendships.unshift(record);
    }
  }

  async listNotifications(userId: string): Promise<NotificationRecord[]> {
    return this.notifications.filter((n) => n.user_id === userId);
  }

  async createNotification(notification: NotificationRecord): Promise<void> {
    this.notifications.unshift(notification);
  }

  async markNotificationsRead(userId: string, notificationId?: string): Promise<void> {
    for (const n of this.notifications) {
      if (n.user_id === userId && (!notificationId || n.id === notificationId)) {
        n.is_read = 1;
      }
    }
  }

  async listCharactersByUser(userId: string): Promise<CharacterRecord[]> {
    return Array.from(this.characters.values()).filter((c) => c.user_id === userId);
  }

  async upsertCharacter(character: CharacterRecord): Promise<void> {
    this.characters.set(character.id, character);
  }

  async createReport(report: UniversalReportRecord): Promise<void> {
    this.reports.unshift(report);
  }

  async listReports(): Promise<UniversalReportRecord[]> {
    return [...this.reports];
  }

  async updateReportStatus(
    reportId: string,
    status: 'resolved' | 'dismissed',
  ): Promise<void> {
    const target = this.reports.find((r) => r.id === reportId);
    if (target) target.status = status;
  }

  async createP2pSignal(signal: P2pSignalRecord): Promise<void> {
    this.p2pSignals.push(signal);
  }

  async listP2pPresenceByCampaign(campaignId: string): Promise<P2pSignalRecord[]> {
    return this.p2pSignals.filter(
      (s) => s.campaign_id === campaignId && s.signal_type === 'presence',
    );
  }

  async listMetricsSummary(): Promise<{
    users_count: number;
    campaigns_count: number;
    pending_reports_count: number;
    banned_devices_count: number;
  }> {
    let realUsers = 0;
    for (const id of this.users.keys()) {
      if (id !== 'usr_system_official') realUsers += 1;
    }
    return {
      users_count: realUsers,
      campaigns_count: this.campaigns.size,
      pending_reports_count: this.reports.filter((r) => r.status === 'pending').length,
      banned_devices_count: Array.from(this.devices.values()).filter(
        (d) => d.is_hardware_banned === 1,
      ).length,
    };
  }
}

