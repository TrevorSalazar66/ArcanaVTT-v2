import '../../domain/entities/arcana_entities.dart';

/// Catálogo canônico local do Sistema Oficial AlphaD6 Core v2.4 e Tutoriais Sandboxed.
/// Zero dados fictícios de usuários, campanhas, guildas, chats ou denúncias.
class ArcanaSeedData {
  ArcanaSeedData._();

  static List<RpgSystem> officialSystems() => const [
        RpgSystem(
          id: 'sys_alphad6_v24',
          name: 'AlphaD6 Core',
          version: 'v2.4',
          segment: SystemSegment.oficiais,
          diceEngine: '3d6',
          description:
              'Sistema oficial Dark Fantasy em 3d6 (Corpo, Mente, Espírito), acertos 5+, reserva de Ânima e inventário estrito de 12 slots.',
          attributes: ['Corpo', 'Mente', 'Espírito'],
          downloadsCount: 0,
          rating: 5.0,
          isOfficial: true,
        ),
      ];

  static List<CompendiumItem> officialCompendium() => const [
        CompendiumItem(
          id: 'item_espada_runica',
          systemId: 'sys_alphad6_v24',
          category: CompendiumCategory.equipamentos,
          name: 'Espada Rúnica de Ferro Negro',
          rarity: 'Raro',
          slotsWeight: 2,
          description:
              'Lâmina forjada com runas douradas que concedem +1 dado contra espectros.',
        ),
        CompendiumItem(
          id: 'item_elixir_anima',
          systemId: 'sys_alphad6_v24',
          category: CompendiumCategory.itens,
          name: 'Elixir de Ânima Concentrada',
          rarity: 'Incomum',
          slotsWeight: 1,
          description: 'Restaura imediatamente 4 pontos de Ânima sem gastar turno.',
        ),
        CompendiumItem(
          id: 'item_sentinela_cinza',
          systemId: 'sys_alphad6_v24',
          category: CompendiumCategory.seres,
          name: 'Sentinela das Cinzas',
          rarity: 'Épico',
          slotsWeight: 0,
          description:
              'Autômato de armadura oca movido a brasas arcanas. Resistência 2.',
        ),
        CompendiumItem(
          id: 'item_selo_chama',
          systemId: 'sys_alphad6_v24',
          category: CompendiumCategory.poderes,
          name: 'Selo da Chama Eterna',
          rarity: 'Raro',
          slotsWeight: 0,
          description: 'Conjura um escudo heráldico dourado que reduz dano em 2.',
        ),
        CompendiumItem(
          id: 'item_pergaminho_valen',
          systemId: 'sys_alphad6_v24',
          category: CompendiumCategory.pistas,
          name: 'Pergaminho do Pacto de Valen',
          rarity: 'Único',
          slotsWeight: 1,
          description:
              'Fragmento lacrado revelando a passagem secreta sob a Capela.',
        ),
      ];

  static List<TutorialModule> initialTutorials() => const [
        TutorialModule(
          id: 'tut_01',
          title: '1. Criação & Gestão de Mesas',
          subtitle: 'Wizard em 4 etapas, códigos Quick Join e compêndio modular',
          completed: false,
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
          title: 'Sistema Oficial AlphaD6 Core Integrado',
          summary:
              'Motor 3d6, inventário de 12 slots e compêndio oficial prontos para mesas na Cloudflare.',
        ),
        NewsItem(
          id: 'nws_02',
          tag: 'SEGURANÇA',
          title: 'Google OAuth 2.0 & Blindagem Zero-Trust',
          summary:
              'Sessões criptografadas via HMAC-SHA256 com validação etária LGPD e sincronização D1.',
        ),
      ];
}

