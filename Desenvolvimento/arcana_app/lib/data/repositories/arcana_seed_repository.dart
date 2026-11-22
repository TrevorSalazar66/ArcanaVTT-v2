import '../../domain/entities/arcana_entities.dart';

/// Provedor de dados iniciais neutros (Zero Sistemas RPG Hardcoded).
/// Todos os sistemas, homebrews, campanhas e herois sao criados dinamicamente pelos usuarios no Cloudflare D1.
class ArcanaSeedData {
  /// Catalogo de sistemas inicia estritamente vazio conforme diretriz "Zero Hardcoded Systems".
  static List<RpgSystem> officialSystems() => const [];

  /// Compendio global inicial estritamente vazio ate a criacao dinamica de sistemas/homebrews.
  static List<CompendiumItem> officialCompendium() => const [];

  static List<TutorialModule> initialTutorials() => const [
        TutorialModule(
          id: 'tut_01',
          title: '1. Criacao & Gestao de Mesas',
          subtitle: 'Wizard em 4 etapas, Quick Join vs Convites Diretos e Elenco',
          completed: false,
        ),
        TutorialModule(
          id: 'tut_02',
          title: '2. Oficina & Os 6 Modelos de Cena',
          subtitle: 'Grid Tatico 2D, Mahjong, Cofres, Dialogos, Combate JRPG e Terminal',
          completed: false,
        ),
        TutorialModule(
          id: 'tut_03',
          title: '3. Jogabilidade do Aventureiro',
          subtitle: 'Fichas 1-por-campanha, Motor Universal de Dados e Papel/Equipamentos',
          completed: false,
        ),
        TutorialModule(
          id: 'tut_04',
          title: '4. Comunidades, DMs & Guildas',
          subtitle: 'Shared World, Clas, Boost Nv.1-5, DMs 1-a-1 e Denuncia Universal',
          completed: false,
        ),
        TutorialModule(
          id: 'tut_05',
          title: '5. Forja de Sistemas & Delta Homebrew',
          subtitle: 'Keys de Criacao, Blocos RoleGate e Motor Agnostico de Regras',
          completed: false,
        ),
      ];

  static List<NewsItem> initialNews() => const [
        NewsItem(
          id: 'news_01',
          tag: 'OFICIAL',
          title: 'ArcanaVTT Motor Universal Agnostico Ativo',
          summary:
              'Nenhum sistema engessado: forje sistemas com Key de Criacao, role formulas dinamicas e crie ate 18 cenas por mesa.',
        ),
        NewsItem(
          id: 'news_02',
          tag: 'OFICINA DO MESTRE',
          title: '6 Modelos de Cena & Gatilhos No-Code [QUANDO]->[SE]->[ENTAO]',
          summary:
              'Grid Tatico com Fog of War, Mahjong & Minas, Cofres com Pistas, Dialogos, JRPG e Terminal CRT agora no servidor.',
        ),
      ];
}
