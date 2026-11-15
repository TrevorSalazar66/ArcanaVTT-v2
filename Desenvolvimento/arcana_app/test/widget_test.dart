import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arcana_app/controllers/app_controller.dart';
import 'package:arcana_app/core/security/rbac_guard.dart';
import 'package:arcana_app/core/theme/arcana_colors.dart';
import 'package:arcana_app/data/datasources/cloudflare_edge_client.dart';
import 'package:arcana_app/data/repositories/arcana_seed_repository.dart';
import 'package:arcana_app/domain/entities/arcana_entities.dart';
import 'package:arcana_app/domain/usecases/authenticate_oauth_usecase.dart';
import 'package:arcana_app/domain/usecases/build_universal_report_usecase.dart';
import 'package:arcana_app/domain/usecases/filter_compendium_categories_usecase.dart';
import 'package:arcana_app/domain/usecases/roll_3d6_usecase.dart';
import 'package:arcana_app/main.dart';
import 'package:arcana_app/presentation/modals/community_chat_modal.dart';

Future<Map<String, String>?> _fakeGoogleUser() async {
  return {
    'sub': 'sub_google_001',
    'email': 'mestre@arcanavtt.app',
    'displayName': 'Mestre Arcano',
    'idToken': 'tok_test_001',
  };
}

class _OfflineStubEdgeClient extends CloudflareEdgeClient {
  @override
  Future<EdgeResponse> postAuth(Map<String, dynamic> payload) async {
    return const EdgeResponse(ok: false, statusCode: 0, data: {'stub': true});
  }

  @override
  Future<EdgeResponse> postSync(Map<String, dynamic> payload) async {
    return const EdgeResponse(ok: false, statusCode: 0, data: {'stub': true});
  }
}

class _FakeSyncedEdgeClient extends CloudflareEdgeClient {
  final List<Map<String, dynamic>> _campaigns = [];
  final List<Map<String, dynamic>> _characters = [];
  final List<Map<String, dynamic>> _guilds = [];
  final List<Map<String, dynamic>> _messages = [];

  @override
  Future<EdgeResponse> checkHealth() async {
    return const EdgeResponse(ok: true, statusCode: 200, data: {'status': 'ok'});
  }

  @override
  Future<EdgeResponse> postAuth(Map<String, dynamic> payload) async {
    return EdgeResponse(
      ok: true,
      statusCode: 200,
      data: {
        'token': 'jwt_fake_sync_001',
        'trusted_device_days': 30,
        'user': {
          'id': 'usr_001',
          'email': payload['email'] ?? 'mestre@arcanavtt.app',
          'role': 'superadmin',
        },
        'profile': {
          'username': 'mestrearcano',
          'display_name': payload['display_name'] ?? 'Mestre Arcano',
          'bio': '',
          'avatar_icon': 'crown',
          'reputation_points': 100,
          'onboarding_completed': 0,
        },
      },
    );
  }

  @override
  Future<EdgeResponse> postSync(Map<String, dynamic> payload) async {
    final action = payload['action'] as String?;
    switch (action) {
      case 'systems.list':
        return const EdgeResponse(ok: true, statusCode: 200, data: {'systems': <dynamic>[]});
      case 'compendium.query':
        return const EdgeResponse(ok: true, statusCode: 200, data: {'items': <dynamic>[]});
      case 'campaigns.list':
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {'campaigns': _campaigns, 'memberships': <dynamic>[]},
        );
      case 'characters.list':
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {'characters': _characters},
        );
      case 'guilds.list':
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {'guilds': _guilds},
        );
      case 'forum.list':
        return const EdgeResponse(ok: true, statusCode: 200, data: {'topics': <dynamic>[]});
      case 'chat.list':
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {'messages': _messages},
        );
      case 'friends.list':
        return const EdgeResponse(ok: true, statusCode: 200, data: {'friends': <dynamic>[]});
      case 'notifications.list':
        return const EdgeResponse(ok: true, statusCode: 200, data: {'notifications': <dynamic>[]});
      case 'reports.list':
        return const EdgeResponse(ok: true, statusCode: 200, data: {'reports': <dynamic>[]});
      case 'profile.setup':
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {
            'role': 'superadmin',
            'profile': {
              'username': payload['username'],
              'display_name': payload['display_name'],
              'bio': payload['bio'] ?? '',
            },
          },
        );
      case 'campaigns.create':
        final cmp = {
          'id': 'cmp_001',
          'title': payload['title'],
          'synopsis': payload['synopsis'],
          'master_handle': '@mestrearcano',
          'system_id': payload['system_id'],
          'system_name': 'AlphaD6 Core (v2.4)',
          'quick_join_code': 'D1A99Z',
          'mode': payload['mode'],
          'schedule_text': payload['schedule_text'],
          'max_slots': payload['max_slots'],
          'occupied_slots': 1,
          'chapter_title': 'Prólogo: Mesa Recém-Forjada',
          'visibility': payload['visibility'],
        };
        _campaigns.insert(0, cmp);
        return EdgeResponse(ok: true, statusCode: 201, data: {'campaign': cmp});
      case 'campaigns.quick_join':
        final code = payload['code'] as String?;
        final found = _campaigns.where((c) => c['quick_join_code'] == code).toList();
        if (found.isEmpty) {
          return const EdgeResponse(
            ok: false,
            statusCode: 404,
            data: {'error': {'code': 'NOT_FOUND', 'message': 'Código inválido'}},
          );
        }
        return EdgeResponse(ok: true, statusCode: 200, data: {'campaign': found.first});
      case 'characters.upsert':
        final ch = {
          'id': payload['id'] ?? 'char_001',
          'name': payload['name'],
          'title': payload['title'],
          'campaign_title': 'Mesa Livre',
          'level': payload['level'],
          'corpo': payload['corpo'],
          'mente': payload['mente'],
          'espirito': payload['espirito'],
          'hp_current': payload['hp_current'],
          'hp_max': payload['hp_max'],
          'anima_current': payload['anima_current'],
          'anima_max': payload['anima_max'],
          'exhaustion': payload['exhaustion'],
          'slots': payload['slots'],
        };
        _characters
          ..clear()
          ..add(ch);
        return EdgeResponse(ok: true, statusCode: 200, data: {'character': ch});
      case 'guilds.create':
        final g = {
          'id': 'gld_001',
          'name': payload['name'],
          'tag': payload['tag'],
          'leader_handle': '@mestrearcano',
          'description': payload['description'],
          'member_count': 1,
          'active_tables_count': 0,
          'boost_points': 0,
          'boost_goal': 1000,
          'shared_world_name': payload['shared_world_name'],
          'current_season': payload['current_season'],
        };
        _guilds.insert(0, g);
        return EdgeResponse(ok: true, statusCode: 201, data: {'guild': g});
      case 'guilds.boost':
        final g = _guilds.first;
        g['boost_points'] = (g['boost_points'] as int) + (payload['points'] as int);
        return EdgeResponse(ok: true, statusCode: 200, data: {'guild': g});
      case 'chat.send':
        final msg = {
          'id': 'msg_001',
          'author_handle': '@mestrearcano',
          'author_role': 'SUPERADMIN',
          'content': payload['content'],
          'time_label': 'Agora',
          'dice_summary': payload['dice_summary'],
        };
        _messages.add(msg);
        return EdgeResponse(ok: true, statusCode: 201, data: {'message': msg});
      default:
        return const EdgeResponse(ok: true, statusCode: 200, data: {'ok': true});
    }
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Camada 1 — Testes Unitários de Domínio & Segurança', () {
    test('Roll3d6UseCase gera exatamente 3 dados entre 1 e 6 e calcula acertos >= 5', () {
      final usecase = Roll3d6UseCase();
      for (var i = 0; i < 30; i++) {
        final result = usecase.execute(label: 'Teste de Mente');
        expect(result.dice.length, 3);
        for (final face in result.dice) {
          expect(face, inInclusiveRange(1, 6));
        }
        expect(result.successes, result.dice.where((d) => d >= 5).length);
      }
    });

    test('FilterCompendiumCategoriesUseCase oculta categorias vazias automaticamente', () {
      final filter = FilterCompendiumCategoriesUseCase();
      final officialItems = ArcanaSeedData.officialCompendium();
      final alphaResult = filter.execute(systemItems: officialItems);
      expect(alphaResult.visibleCategories.length, 5);

      final singleCatOnly = [
        officialItems.firstWhere((e) => e.category == CompendiumCategory.poderes),
      ];
      final filteredResult = filter.execute(systemItems: singleCatOnly);
      expect(filteredResult.visibleCategories, [CompendiumCategory.poderes]);
      expect(
        filteredResult.visibleCategories.contains(CompendiumCategory.seres),
        isFalse,
      );
    });

    test('AppController inicia 100% limpo sem campanhas, heróis ou guildas mockadas', () {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      expect(ctrl.campaigns, isEmpty);
      expect(ctrl.hero, isNull);
      expect(ctrl.guilds, isEmpty);
      expect(ctrl.forumTopics, isEmpty);
      expect(ctrl.chatMessages, isEmpty);
      expect(ctrl.friends, isEmpty);
      expect(ctrl.notifications, isEmpty);
      expect(ctrl.reports, isEmpty);
      expect(ctrl.systems.length, 1);
      expect(ctrl.systems.first.id, 'sys_alphad6_v24');
    });

    test('BuildUniversalReportUseCase anexa autotags de contexto automaticamente', () {
      final report = BuildUniversalReportUseCase().execute(
        originType: 'chat',
        originId: 'msg_01',
        reasonCategory: 'Linguagem Ofensiva',
        description: 'Teste automatizado de autotags.',
        reporterRole: UserRole.mestre,
        sessionContext: 'taverna',
      );
      expect(report.autoTags.any((t) => t == '#origem:chat'), isTrue);
      expect(report.autoTags.any((t) => t == '#alvo:msg_01'), isTrue);
      expect(report.autoTags.any((t) => t == '#relator:mestre'), isTrue);
    });

    test('RbacGuard aplica matriz Zero-Trust correta para Jogador, Mestre e Superadmin', () {
      expect(RbacGuard.canForgeCampaign(UserRole.jogador), isFalse);
      expect(RbacGuard.canAccessAdminPanel(UserRole.jogador), isFalse);
      expect(RbacGuard.canForgeCampaign(UserRole.mestre), isTrue);
      expect(RbacGuard.canAccessAdminPanel(UserRole.mestre), isFalse);
      expect(RbacGuard.canAccessAdminPanel(UserRole.admin), isTrue);
      expect(RbacGuard.canAccessAdminPanel(UserRole.superadmin), isTrue);
    });
  });

  group('Camada 2 — Testes de Integração de Controller & Sync D1', () {
    test('Bloqueia menor de 16 anos, Hardware Ban e autentica via GoogleOAuth + onboarding', () async {
      final ctrl = AppController(
        edgeClient: _FakeSyncedEdgeClient(),
        googleSignInProvider: _fakeGoogleUser,
      );

      final blockedAge = await ctrl.signInWithGoogleOAuth(
        birthDate: DateTime(2015, 1, 1),
      );
      expect(blockedAge, isFalse);
      expect(ctrl.isAuthenticated, isFalse);
      expect(ctrl.loginViewState, OAuthSecurityState.erroMenorIdade);

      final blockedBan = await ctrl.signInWithGoogleOAuth(
        birthDate: DateTime(1998, 1, 1),
        simulateHardwareBan: true,
      );
      expect(blockedBan, isFalse);
      expect(ctrl.loginViewState, OAuthSecurityState.erroHardwareBan);

      final ok = await ctrl.signInWithGoogleOAuth(
        birthDate: DateTime(1998, 1, 1),
      );
      expect(ok, isTrue);
      expect(ctrl.isAuthenticated, isTrue);
      expect(ctrl.currentUser.role, UserRole.superadmin);
      expect(ctrl.loginViewState, OAuthSecurityState.sucessoAutenticado);

      await ctrl.completeLoginTransitionToHub(
        newUsername: 'mestrearcano',
        newDisplayName: 'Mestre Arcano',
      );
      expect(ctrl.loginViewState, OAuthSecurityState.padrao);
    });

    test('CRUD completo sincronizado (ficha, campanha, quick join, guilda e chat 3d6)', () async {
      final ctrl = AppController(
        edgeClient: _FakeSyncedEdgeClient(),
        googleSignInProvider: _fakeGoogleUser,
      );
      await ctrl.signInWithGoogleOAuth(birthDate: DateTime(1996, 5, 10));
      await ctrl.completeLoginTransitionToHub(
        newUsername: 'mestrearcano',
        newDisplayName: 'Mestre Arcano',
      );

      final heroOk = await ctrl.saveHeroCharacter(
        name: 'Kaelen Silvaris',
        heroClass: 'Lâmina Arcana',
        campaignTitle: 'Mesa Livre',
        level: 1,
        corpo: 3,
        mente: 2,
        espirito: 2,
        slots: const ['Espada Curta', 'Lanterna'],
      );
      expect(heroOk, isTrue);
      expect(ctrl.hero?.name, 'Kaelen Silvaris');

      final cmp = await ctrl.createCampaign(
        title: 'Fortaleza de Basalto',
        synopsis: 'Exploração sem dados mockados.',
        systemId: 'sys_alphad6_v24',
        mode: CampaignMode.aoVivo,
        scheduleText: 'Sextas 20h',
        maxSlots: 5,
        isPublic: true,
      );
      expect(cmp, isNotNull);
      expect(cmp?.quickJoinCode, 'D1A99Z');

      final joined = await ctrl.quickJoinByCode('d1a-99z');
      expect(joined?.title, 'Fortaleza de Basalto');

      final guildOk = await ctrl.createGuild(
        name: 'Ordem Dourada',
        tag: 'ORDE',
        description: 'Guilda inaugural.',
      );
      expect(guildOk, isTrue);
      await ctrl.contributeGuildBoost(ctrl.guilds.first.id, 50);
      expect(ctrl.guilds.first.boostPoints, 50);

      await ctrl.sendCommunityMessage(
        content: 'Testando rolagem',
        with3d6Roll: true,
      );
      expect(ctrl.chatMessages.length, 1);
      expect(ctrl.chatMessages.last.diceRoll, isNotNull);

      await ctrl.setThemeMode(ArcanaThemeMode.oled);
      await ctrl.setFontScale(1.2);
      expect(ctrl.themeMode, ArcanaThemeMode.oled);
      expect(ctrl.fontScale, 1.2);
    });
  });

  group('Camada 3 — Testes de Interface (Google OAuth, Estados Vazios e RBAC)', () {
    testWidgets('LoginScreen exibe 100% Google OAuth sem mocks e navega ao Hub limpo',
        (tester) async {
      final ctrl = AppController(
        edgeClient: _FakeSyncedEdgeClient(),
        googleSignInProvider: _fakeGoogleUser,
      );
      await tester.pumpWidget(ArcanaVttApp(controller: ctrl));
      await tester.pumpAndSettle();

      // Garante ausência de senha, barra de debug e contas fictícias
      expect(find.text('Senha de acesso'), findsNothing);
      expect(find.text('Valen Voss'), findsNothing);
      expect(find.text('INSPEÇÃO RÁPIDA DE ESTADOS DO PORTAL'), findsNothing);
      expect(find.text('Continuar com o Google'), findsOneWidget);

      await tester.ensureVisible(find.text('Continuar com o Google'));
      await tester.tap(find.text('Continuar com o Google'));
      await tester.pumpAndSettle();

      expect(find.text('Autenticação Google Verificada!'), findsOneWidget);
      await tester.ensureVisible(find.text('Entrar no Hub da Taverna'));
      await tester.tap(find.text('Entrar no Hub da Taverna'));
      await tester.pumpAndSettle();

      expect(find.text('CONTINUAR A JORNADA'), findsOneWidget);
      expect(find.text('Nenhuma campanha por enquanto'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Suas fichas aparecerão aqui'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Suas fichas aparecerão aqui'), findsOneWidget);

      await tester.tap(find.text('Campanhas'));
      await tester.pumpAndSettle();
      expect(find.text('A Maldição de Valen'), findsNothing);

      await tester.tap(find.text('Sistemas'));
      await tester.pumpAndSettle();
      expect(find.text('AlphaD6 Core (v2.4)'), findsOneWidget);

      await tester.tap(find.text('Comunidades'));
      await tester.pumpAndSettle();
      expect(find.text('Taverna dos Mestres'), findsOneWidget);
    });

    testWidgets('Drawer aplica Widget Tree Pruning RBAC para Jogador vs Superadmin',
        (tester) async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      ctrl.isAuthenticated = true;
      ctrl.switchActiveRoleForPreview(UserRole.jogador);

      await tester.pumpWidget(ArcanaVttApp(controller: ctrl));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu Principal'));
      await tester.pumpAndSettle();
      expect(find.text('Painel de Governança Admin'), findsNothing);

      await tester.tapAt(const Offset(380, 100));
      await tester.pumpAndSettle();
      ctrl.switchActiveRoleForPreview(UserRole.superadmin);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu Principal'));
      await tester.pumpAndSettle();
      expect(find.text('Painel de Governança Admin'), findsOneWidget);
    });

    testWidgets('CommunityChatModal inicia limpo e envia rolagem 3d6 ao vivo',
        (tester) async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [ArcanaPalette.escuroHeraldico],
          ),
          home: Scaffold(
            body: CommunityChatModal(controller: ctrl),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TAVERNA DOS MESTRES'), findsOneWidget);
      expect(
        find.textContaining('Nenhuma mensagem neste canal ainda'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Rolar 3d6 no Chat'));
      await tester.pumpAndSettle();

      expect(ctrl.chatMessages.length, 1);
      expect(ctrl.chatMessages.last.diceRoll, isNotNull);
    });
  });
}
