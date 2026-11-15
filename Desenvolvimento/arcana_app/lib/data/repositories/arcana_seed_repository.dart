import '../../core/security/rbac_guard.dart';
import '../../domain/entities/arcana_entities.dart';

/// Dados iniciais locais sincronizados com o schema do Cloudflare D1.
class ArcanaSeedData {
  ArcanaSeedData._();

  static List<Campaign> initialCampaigns() => const [
        Campaign(
          id: 'cmp_valen_01',
          title: 'A Maldição de Valen',
          synopsis:
              'Os sinos da Capela Submersa voltaram a tocar após três séculos de silêncio, trazendo névoa viva sobre as criptas.',
          masterHandle: '@mestre_cypher',
          systemId: 'sys_alphad6_v24',
          systemName: 'AlphaD6 Core v2.4',
          quickJoinCode: 'ARC774',
          mode: CampaignMode.aoVivo,
          scheduleText: 'Sáb 20h',
          maxSlots: 5,
          occupiedSlots: 4,
          userRelation: CampaignSegment.jogando,
          chapterTitle: 'Ato II — As Criptas de Basalto',
          isPublic: true,
        ),
        Campaign(
          id: 'cmp_cinza_02',
          title: 'Crônicas de Cinza',
          synopsis:
              'Campanha assíncrona de investigação arcana e intriga política entre casas mercantes.',
          masterHandle: '@mestre_cypher',
          systemId: 'sys_alphad6_v24',
          systemName: 'AlphaD6 Core v2.4',
          quickJoinCode: 'CIN882',
          mode: CampaignMode.tempoLivre,
          scheduleText: 'Tempo Livre',
          maxSlots: 6,
          occupiedSlots: 3,
          userRelation: CampaignSegment.auxiliar,
          chapterTitle: 'Prólogo — O Selo Quebrado',
          isPublic: true,
        ),
        Campaign(
          id: 'cmp_obelisco_03',
          title: 'O Obelisco Submerso',
          synopsis:
              'Expedição tática para recuperar relíquias de âmbar antes da maré sombria.',
          masterHandle: '@admin_thorin',
          systemId: 'sys_alphad6_v24',
          systemName: 'AlphaD6 Core v2.4',
          quickJoinCode: 'OBE309',
          mode: CampaignMode.agendada,
          scheduleText: 'Dom 19h',
          maxSlots: 5,
          occupiedSlots: 2,
          userRelation: CampaignSegment.explorar,
          chapterTitle: 'Capítulo I — Farol Partido',
          isPublic: true,
        ),
      ];

  static HeroCharacter initialHero() => const HeroCharacter(
        id: 'chr_kaelen_01',
        name: 'Kaelen Voss',
        heroClass: 'Lâmina Rúnica',
        campaignTitle: 'A Maldição de Valen',
        level: 4,
        hpCurrent: 18,
        hpMax: 22,
        animaCurrent: 9,
        animaMax: 12,
        exhaustion: 1,
        corpo: 4,
        mente: 3,
        espirito: 5,
        slots: [
          'Espada Rúnica de Ferro Negro (2 slots)',
          'Elixir de Ânima Concentrada (1 slot)',
          'Lanterna de Óleo Sagrado (1 slot)',
          'Pergaminho do Pacto de Valen (1 slot)',
          'Corda de Cânhamo 15m (1 slot)',
          'Amuleto da Vigília (1 slot)',
        ],
      );

  static List<RpgSystem> initialSystems() => const [
        RpgSystem(
          id: 'sys_alphad6_v24',
          name: 'AlphaD6 Core',
          version: 'v2.4',
          segment: SystemSegment.oficiais,
          diceEngine: '3d6',
          description:
              'Sistema oficial Dark Fantasy em 3d6 (Corpo, Mente, Espírito), acertos 5+, reserva de Ânima e inventário estrito de 12 slots.',
          attributes: ['Corpo', 'Mente', 'Espírito'],
          downloadsCount: 12480,
          rating: 4.9,
          isOfficial: true,
        ),
        RpgSystem(
          id: 'sys_lamina_carmesim',
          name: 'Lâmina Carmesim',
          version: 'v1.2',
          segment: SystemSegment.comunidade,
          diceEngine: '3d6',
          description:
              'Adaptação minimalista focada em duelos de esgrima e combate letal (apenas Poderes cadastrados neste módulo).',
          attributes: ['Acuidade', 'Engenho', 'Vontade'],
          downloadsCount: 3120,
          rating: 4.7,
          isOfficial: false,
        ),
        RpgSystem(
          id: 'sys_grimorio_pessoal',
          name: 'Códice das Brumas',
          version: 'v0.9',
          segment: SystemSegment.proprios,
          diceEngine: '3d6',
          description:
              'Sistema homebrew focado em exploração de masmorras com mecânica de tochas e sanidade.',
          attributes: ['Físico', 'Sabedoria', 'Vigor'],
          downloadsCount: 84,
          rating: 4.8,
          isOfficial: false,
        ),
      ];

  static List<CompendiumItem> initialCompendium() => const [
        CompendiumItem(
          id: 'cmp_item_01',
          systemId: 'sys_alphad6_v24',
          category: CompendiumCategory.equipamentos,
          name: 'Espada Rúnica de Ferro Negro',
          rarity: 'Raro',
          slotsWeight: 2,
          description:
              'Lâmina forjada com runas douradas que concedem +1 dado contra espectros.',
        ),
        CompendiumItem(
          id: 'cmp_item_02',
          systemId: 'sys_alphad6_v24',
          category: CompendiumCategory.itens,
          name: 'Elixir de Ânima Concentrada',
          rarity: 'Incomum',
          slotsWeight: 1,
          description: 'Restaura imediatamente 4 pontos de Ânima sem gastar turno.',
        ),
        CompendiumItem(
          id: 'cmp_item_03',
          systemId: 'sys_alphad6_v24',
          category: CompendiumCategory.seres,
          name: 'Sentinela das Cinzas',
          rarity: 'Épico',
          slotsWeight: 0,
          description:
              'Autômato de armadura oca movido a brasas arcanas. Resistência 2.',
        ),
        CompendiumItem(
          id: 'cmp_item_04',
          systemId: 'sys_alphad6_v24',
          category: CompendiumCategory.poderes,
          name: 'Selo da Chama Eterna',
          rarity: 'Raro',
          slotsWeight: 0,
          description: 'Conjura um escudo heráldico dourado que reduz dano em 2.',
        ),
        CompendiumItem(
          id: 'cmp_item_05',
          systemId: 'sys_alphad6_v24',
          category: CompendiumCategory.pistas,
          name: 'Pergaminho do Pacto de Valen',
          rarity: 'Único',
          slotsWeight: 1,
          description:
              'Fragmento lacrado revelando a passagem secreta sob a Capela.',
        ),
        // Para Lâmina Carmesim: apenas Poderes -> demonstra ocultação automática das outras 4 categorias!
        CompendiumItem(
          id: 'cmp_item_06',
          systemId: 'sys_lamina_carmesim',
          category: CompendiumCategory.poderes,
          name: 'Estocada do Crepúsculo',
          rarity: 'Raro',
          slotsWeight: 0,
          description: 'Contra-ataque imediato ao aparar um golpe corpo a corpo.',
        ),
      ];

  static List<Guild> initialGuilds() => const [
        Guild(
          id: 'gld_chama',
          name: 'Ordem da Chama Cinzenta',
          tag: 'CHAMA',
          leaderHandle: '@mestre_cypher',
          description:
              'Guilda de mundo compartilhado dedicada a campanhas interligadas no continente de Valen.',
          memberCount: 42,
          activeTablesCount: 6,
          boostPoints: 780,
          boostGoal: 1000,
          sharedWorldName: 'Continente de Valen',
          currentSeason: 'Temporada III — Era das Brasas',
        ),
        Guild(
          id: 'gld_bastiao',
          name: 'Bastião dos Cartógrafos',
          tag: 'MAPA',
          leaderHandle: '@admin_thorin',
          description:
              'Comunidade focada em criação de cenários táticos e sistemas próprios AlphaD6.',
          memberCount: 28,
          activeTablesCount: 4,
          boostPoints: 450,
          boostGoal: 800,
          sharedWorldName: 'Arquipélago de Basalto',
          currentSeason: 'Ciclo de Cartografia Tática',
        ),
      ];

  static List<ForumTopic> initialForumTopics() => const [
        ForumTopic(
          id: 'top_01',
          authorHandle: '@mestre_cypher',
          category: 'Regras & Oficina',
          title: 'Guia de balanceamento de encontros 3d6 para 4 heróis',
          content:
              'Ao posicionar sentinelas de elite em corredores estreitos, limite recargas de Ânima para manter a tensão dramática.',
          upvotes: 29,
          repliesCount: 8,
          pinned: true,
          timeAgo: 'há 2h',
        ),
        ForumTopic(
          id: 'top_02',
          authorHandle: '@valen_bard',
          category: 'Narrativa',
          title: 'Rotas comerciais secretas sob a Cidadela de Basalto',
          content:
              'Compartilho nossa compilação de pistas e facções neutras para enriquecer campanhas em Tempo Livre.',
          upvotes: 17,
          repliesCount: 4,
          pinned: false,
          timeAgo: 'há 5h',
        ),
      ];

  static List<ChatMessage> initialChatMessages() => const [
        ChatMessage(
          id: 'msg_01',
          channelId: 'taverna-dos-mestres',
          senderHandle: '@mestre_cypher',
          senderRole: UserRole.mestre,
          content:
              'Alguém já testou o encontro na cripta com névoa densa e armadilhas de runas?',
          timeText: '14:22',
          isMine: false,
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_02',
          channelId: 'taverna-dos-mestres',
          senderHandle: '@valen_bard',
          senderRole: UserRole.jogador,
          content: 'Rodei um Teste de Mente agora há pouco para decifrar o altar!',
          timeText: '14:25',
          isMine: true,
          isRead: true,
          replyPreview: '@mestre_cypher: Alguém já testou o encontro...',
          diceRoll: DiceRoll3d6(
            label: 'TESTE DE MENTE (3D6)',
            dice: [5, 6, 2],
            successes: 2,
            outcome: '2 Sucessos!',
          ),
        ),
        ChatMessage(
          id: 'msg_03',
          channelId: 'taverna-dos-mestres',
          senderHandle: '@admin_thorin',
          senderRole: UserRole.admin,
          content:
              'Excelente resultado! O dano de armadilha desconta direto da Ânima e sincroniza sem latência.',
          timeText: '14:28',
          isMine: false,
          isRead: true,
        ),
      ];

  static List<FriendContact> initialFriends() => const [
        FriendContact(
          id: 'fr_01',
          username: 'mestre_cypher',
          displayName: 'Mestre Cypher',
          presenceStatus: 'Em Mesa',
          activity: 'Mestrando A Maldição de Valen',
          lastDm: 'Te espero na sessão de sábado às 20h!',
        ),
        FriendContact(
          id: 'fr_02',
          username: 'lyra_arcana',
          displayName: 'Lyra Noctis',
          presenceStatus: 'Online',
          activity: 'Editando ficha no AlphaD6',
          lastDm: 'Compartilhei meu grimório de feitiços contigo.',
        ),
        FriendContact(
          id: 'fr_03',
          username: 'kael_shield',
          displayName: 'Kael Escudeiro',
          presenceStatus: 'Ausente',
          activity: 'Na Taverna dos Mestres',
          lastDm: 'Vamos formar grupo na próxima expedição!',
        ),
      ];

  static List<AppNotification> initialNotifications() => const [
        AppNotification(
          id: 'not_01',
          category: 'mesas',
          title: 'Convite de Sessão Ao Vivo',
          body: '@mestre_cypher abriu a sala de A Maldição de Valen (Código ARC774).',
          timeAgo: 'há 10 min',
          isRead: false,
          campaignCode: 'ARC774',
        ),
        AppNotification(
          id: 'not_02',
          category: 'social',
          title: 'Novo Comentário no Fórum',
          body: '@lyra_arcana respondeu seu tópico sobre rotas de Basalto.',
          timeAgo: 'há 1h',
          isRead: false,
        ),
        AppNotification(
          id: 'not_03',
          category: 'sistema',
          title: 'AlphaD6 Core v2.4 Atualizado',
          body: 'Compêndio oficial verificado e cacheado para uso offline.',
          timeAgo: 'há 1d',
          isRead: true,
        ),
      ];

  static List<TutorialModule> initialTutorials() => const [
        TutorialModule(
          id: 'tut_01',
          title: '1. Criação & Gestão de Mesas',
          subtitle: 'Wizard em 4 etapas, códigos Quick Join e compêndio modular',
          completed: true,
        ),
        TutorialModule(
          id: 'tut_02',
          title: '2. Oficina & Os 6 Modelos de Cenário',
          subtitle: 'Grid Tático 2D, Mahjong, Cofres e Terminais em tempo real',
          completed: false,
        ),
        TutorialModule(
          id: 'tut_03',
          title: '3. Jogabilidade do Aventureiro',
          subtitle: 'Fichas interativas AlphaD6, dados 3d6 e 12 slots de peso',
          completed: false,
        ),
        TutorialModule(
          id: 'tut_04',
          title: '4. Comunidades, Fóruns & Guildas',
          subtitle: 'Shared World, Guild Boost e protocolo de denúncia universal',
          completed: false,
        ),
        TutorialModule(
          id: 'tut_05',
          title: '5. Forja de Sistemas & Homebrew',
          subtitle: 'Criação de regras próprias e ocultação de categorias vazias',
          completed: false,
        ),
      ];

  static List<NewsItem> initialNews() => const [
        NewsItem(
          id: 'nws_01',
          tag: 'OFICIAL v2.4',
          title: 'Lançamento da Fase 1 no Android',
          summary:
              'Login 100% Google OAuth 2.0, Temas Heráldicos e Chat Comunitário híbrido ativos.',
        ),
        NewsItem(
          id: 'nws_02',
          tag: 'SEGURANÇA',
          title: 'Blindagem Zero-Trust & Lockout Total',
          summary:
              'Proteção de sessão Keystore por 30 dias com revogação instantânea via e-mail.',
        ),
      ];

  static List<UniversalReport> initialReports() => const [
        UniversalReport(
          id: 'rep_demo_01',
          originType: 'chat',
          originId: 'canal_geral_92',
          reasonCategory: 'Linguagem Ofensiva',
          description:
              'Usuário desrespeitou as Diretrizes de Convivência durante recrutamento.',
          autoTags: [
            '#origem:chat',
            '#alvo:canal_geral_92',
            '#sessao:taverna',
            '#utc:2026-01-15T14:20Z',
          ],
          status: 'pending',
          createdAtText: 'há 35 min',
        ),
      ];
}

