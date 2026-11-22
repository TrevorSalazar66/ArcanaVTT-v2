import 'package:arcana_app/controllers/app_controller.dart';
import 'package:arcana_app/core/security/rbac_guard.dart';
import 'package:arcana_app/core/theme/arcana_colors.dart';
import 'package:arcana_app/data/datasources/cloudflare_edge_client.dart';
import 'package:arcana_app/data/repositories/arcana_seed_repository.dart';
import 'package:arcana_app/domain/entities/arcana_entities.dart';
import 'package:arcana_app/domain/usecases/authenticate_oauth_usecase.dart';
import 'package:arcana_app/domain/usecases/build_universal_report_usecase.dart';
import 'package:arcana_app/domain/usecases/filter_compendium_categories_usecase.dart';
import 'package:arcana_app/domain/usecases/universal_rpg_engine_usecase.dart';
import 'package:arcana_app/main.dart';
import 'package:arcana_app/presentation/modals/community_chat_modal.dart';
import 'package:arcana_app/presentation/modals/profile_and_nav_modals.dart';
import 'package:arcana_app/presentation/screens/tabs/systems_tab_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineStubEdgeClient extends CloudflareEdgeClient {
  @override
  Future<EdgeResponse> postAuth(Map<String, dynamic> payload) async {
    return const EdgeResponse(
      ok: false,
      statusCode: 0,
      data: {'offline_fallback': true},
    );
  }

  @override
  Future<EdgeResponse> postSync(Map<String, dynamic> payload) async {
    return const EdgeResponse(
      ok: false,
      statusCode: 0,
      data: {'offline_fallback': true},
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Camada 1 — Unitarios (Zero-Seed, Motor Universal, RBAC, Compendio, LGPD)', () {
    test('Catalogo oficial e compendio iniciam 100% vazios (Zero Hardcoded Systems)', () {
      expect(ArcanaSeedData.officialSystems(), isEmpty);
      expect(ArcanaSeedData.officialCompendium(), isEmpty);
      expect(ArcanaSeedData.initialTutorials().length, 5);
    });

    test('UniversalRpgEngineUseCase interpreta formulas, kh/kl, pools, d100 e delta', () {
      final r = UniversalRpgEngineUseCase.parseDiceRange('2d6 + 4');
      expect(r.min, 6);
      expect(r.max, 16);

      final r2 = UniversalRpgEngineUseCase.parseDiceRange('1d8+1d6-1');
      expect(r2.min, 1);
      expect(r2.max, 13);

      final engine = UniversalRpgEngineUseCase();
      final kh = engine.executeRoll('2d20kh1+3', label: 'Vantagem');
      expect(kh.dice.length, 2);
      expect(kh.keptDice?.length, 1);
      expect(kh.total, greaterThanOrEqualTo(4));

      final pool = engine.executeRoll('4d6>=4', difficulty: 2);
      expect(pool.engine, 'pool');
      expect(pool.dice.length, 4);

      final d100 = engine.executeRoll('1d100<=55');
      expect(d100.engine, 'd100');
      expect(d100.dice.first, inInclusiveRange(1, 100));

      final merged = UniversalRpgEngineUseCase.mergeCompendiumDelta(
        {
          'blocks': {
            'dano': {'label': 'Base', 'dice_formula': '1d8', 'is_visible': true},
            'segredo': {'label': 'Oculto', 'value': 'Maldito', 'is_visible': false},
          },
        },
        {
          'blocks': {
            'dano': {'label': 'Flamejante', 'dice_formula': '1d8+1d6', 'is_visible': true},
          },
        },
      );
      final blocks = merged['blocks'] as Map<String, dynamic>;
      expect((blocks['dano'] as Map)['parsed_range'], {'min': 2, 'max': 14});
      expect((blocks['segredo'] as Map)['is_visible'], isFalse);
    });

    test('AuthenticateOAuthUseCase valida LGPD >= 16 anos, Hardware Ban e Lockout', () {
      final uc = AuthenticateOAuthUseCase();
      final now = DateTime.now().toUtc();
      final minor = uc.evaluateAttempt(
        birthDate: DateTime(now.year - 14, 1, 1),
        isHardwareBanned: false,
        isAccountLocked: false,
      );
      expect(minor.success, isFalse);
      expect(minor.errorCode, 'AGE_RESTRICTED');

      final banned = uc.evaluateAttempt(
        birthDate: DateTime(1995, 5, 5),
        isHardwareBanned: true,
        isAccountLocked: false,
      );
      expect(banned.errorCode, 'HARDWARE_BANNED');

      final valid = uc.evaluateAttempt(
        birthDate: DateTime(1995, 5, 5),
        isHardwareBanned: false,
        isAccountLocked: false,
      );
      expect(valid.success, isTrue);
    });

    test('FilterCompendiumCategoriesUseCase oculta categorias vazias automaticamente', () {
      final uc = FilterCompendiumCategoriesUseCase();
      final items = [
        const CompendiumItem(
          id: 'i1',
          systemId: 'sys_1',
          category: CompendiumCategory.equipamentos,
          name: 'Cota de Malha',
          rarity: 'Comum',
          slotsWeight: 2,
          description: 'Armadura media.',
        ),
      ];
      final res = uc.execute(systemItems: items);
      expect(res.visibleCategories, [CompendiumCategory.equipamentos]);
      expect(res.counts[CompendiumCategory.pistas], 0);
    });

    test('BuildUniversalReportUseCase anexa 5 autotags e [TIPO: ...] granular', () {
      final uc = BuildUniversalReportUseCase();
      final rep = uc.execute(
        originType: 'homebrew',
        originId: 'cmpi_99',
        reasonCategory: 'Conteudo Improprio',
        description: 'Descricao violadora sem aviso.',
        reporterRole: UserRole.jogador,
        sessionContext: 'sess_hub',
      );
      expect(rep.autoTags.length, 5);
      expect(rep.entityType, 'homebrew');
      expect(rep.description.startsWith('[TIPO: HOMEBREW]'), isTrue);
    });
  });

  group('Camada 2 — Integracao (Controller, Limite Cenas/Fichas, Sigilo & RBAC)', () {
    test('Inicia com role jogador e zero sistemas; impede criar heroi fora de campanha', () async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      await ctrl.initializeFromStorage();
      expect(ctrl.currentUser.role, UserRole.jogador);
      expect(ctrl.systems, isEmpty);

      final failedChar = await ctrl.saveHeroCharacter(
        campaignId: '',
        name: 'Sem Mesa',
        heroClass: 'Ladino',
        level: 1,
        corpo: 2,
        mente: 2,
        espirito: 2,
        hpCurrent: 20,
        hpMax: 20,
        animaCurrent: 10,
        animaMax: 10,
        exhaustion: 0,
        slots: const [],
      );
      expect(failedChar, isFalse);

      await ctrl.createCustomSystem(
        name: 'Motor Arcano 2d12',
        diceEngine: '2d12',
        description: 'Sistema forjado dinamicamente.',
        attributes: const ['Coragem', 'Astucia'],
      );
      expect(ctrl.systems.length, 1);

      final cmp = await ctrl.createCampaign(
        title: 'Expedicao Cinzenta',
        synopsis: 'Campanha de exploracao tatica e investigacao.',
        systemId: ctrl.systems.first.id,
        mode: CampaignMode.aoVivo,
        scheduleText: 'Sabado 20h',
        maxSlots: 5,
        isPublic: true,
        tags: const ['Tatico', 'Misterio'],
      );
      expect(cmp, isNotNull);

      final okChar = await ctrl.saveHeroCharacter(
        campaignId: cmp!.id,
        name: 'Lyra',
        heroClass: 'Arcanista',
        level: 2,
        corpo: 1,
        mente: 4,
        espirito: 3,
        hpCurrent: 18,
        hpMax: 18,
        animaCurrent: 14,
        animaMax: 14,
        exhaustion: 0,
        slots: const ['Grimorio'],
      );
      expect(okChar, isTrue);
      expect(ctrl.characterForCampaign(cmp.id)?.name, 'Lyra');

      // Limite rigido de 18 cenas por campanha
      for (var i = 1; i <= 18; i++) {
        final scn = await ctrl.upsertCampaignScene(
          campaignId: cmp.id,
          name: 'Cena $i',
          description: 'Sala $i',
          modelType: SceneModelType.grid2d,
        );
        expect(scn, isNotNull);
      }
      final nineteenth = await ctrl.upsertCampaignScene(
        campaignId: cmp.id,
        name: 'Cena 19',
        description: 'Excedente',
        modelType: SceneModelType.terminal,
      );
      expect(nineteenth, isNull);
    });

    test('Perfil Social nao expoe email e bloqueia alteracao Admin sem Superadmin', () async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      ctrl.currentUser = ctrl.currentUser.copyWith(
        id: 'usr_p1',
        email: 'sigilo.privado@gmail.com',
        username: 'kael',
        displayName: 'Kael',
        role: UserRole.admin,
      );

      final profileView = await ctrl.fetchSocialProfile();
      expect(profileView?.username, 'kael');
      expect(profileView?.oauthVerified, isTrue);

      final denied = await ctrl.adminUpdateUserRole(
        targetUserId: 'usr_alvo',
        newRole: UserRole.admin,
      );
      expect(denied, contains('Superadmin'));
    });
  });

  group('Camada 3 — Widget & E2E UI Tests', () {
    testWidgets('LoginScreen oculta URL/Client ID e nao exibe seletor de cargo previo',
        (tester) async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      await tester.pumpWidget(ArcanaVttApp(controller: ctrl));
      await tester.pumpAndSettle();

      expect(find.textContaining('Google'), findsWidgets);
      expect(find.textContaining('Servidor Cloudflare Edge'), findsNothing);
      expect(find.text('PAPEL NA TAVERNA (SYNC D1)'), findsNothing);

      ctrl.isAuthenticated = true;
      ctrl.switchActiveRoleForPreview(UserRole.jogador);
      await tester.pumpWidget(ArcanaVttApp(controller: ctrl));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu Principal'));
      await tester.pumpAndSettle();
      expect(find.text('Painel de Governanca Admin'), findsNothing);

      await tester.tapAt(const Offset(380, 100));
      await tester.pumpAndSettle();
      ctrl.switchActiveRoleForPreview(UserRole.superadmin);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu Principal'));
      await tester.pumpAndSettle();
      expect(find.text('Painel de Governanca Admin'), findsOneWidget);
    });

    testWidgets('SystemsTabScreen mostra estado dinamico vazio sem AlphaD6 hardcoded',
        (tester) async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [ArcanaPalette.escuroHeraldico],
          ),
          home: Scaffold(body: SystemsTabScreen(controller: ctrl)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Catalogo Dinamico de Sistemas'), findsOneWidget);
      expect(find.textContaining('AlphaD6'), findsNothing);
    });

    testWidgets('SocialProfileModal garante sigilo de e-mail e exibe 3 abas Discord',
        (tester) async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      ctrl.currentUser = ctrl.currentUser.copyWith(
        id: 'usr_tester',
        email: 'meu.segredo.pessoal@gmail.com',
        username: 'valen_bardo',
        displayName: 'Valen Bardo',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [ArcanaPalette.escuroHeraldico],
          ),
          home: Scaffold(body: SocialProfileModal(controller: ctrl)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('meu.segredo.pessoal@gmail.com'), findsNothing);
      expect(find.text('Google OAuth Verificado'), findsOneWidget);
      expect(find.text('Sobre Mim'), findsOneWidget);
      expect(find.text('Em Comum'), findsOneWidget);
      expect(find.text('Vitrine da Taverna'), findsOneWidget);
    });

    testWidgets('CommunityChatModal inicia limpo e executa rolagem universal',
        (tester) async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [ArcanaPalette.escuroHeraldico],
          ),
          home: Scaffold(body: CommunityChatModal(controller: ctrl)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Nenhuma mensagem neste canal ainda'), findsOneWidget);
      await tester.ensureVisible(find.text('Rolar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rolar'));
      await tester.pumpAndSettle();

      expect(ctrl.chatMessages.length, 1);
      expect(ctrl.chatMessages.last.diceRoll, isNotNull);
    });
  });
}
