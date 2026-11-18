import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arcana_app/controllers/app_controller.dart';
import 'package:arcana_app/core/security/rbac_guard.dart';
import 'package:arcana_app/core/theme/arcana_colors.dart';
import 'package:arcana_app/data/datasources/cloudflare_edge_client.dart';
import 'package:arcana_app/data/datasources/local_storage_datasource.dart';
import 'package:arcana_app/data/repositories/arcana_seed_repository.dart';
import 'package:arcana_app/domain/entities/arcana_entities.dart';
import 'package:arcana_app/domain/usecases/authenticate_oauth_usecase.dart';
import 'package:arcana_app/domain/usecases/build_universal_report_usecase.dart';
import 'package:arcana_app/domain/usecases/filter_compendium_categories_usecase.dart';
import 'package:arcana_app/domain/usecases/roll_3d6_usecase.dart';
import 'package:arcana_app/main.dart';
import 'package:arcana_app/presentation/modals/campaign_modals.dart';
import 'package:arcana_app/presentation/modals/community_chat_modal.dart';
import 'package:arcana_app/presentation/modals/profile_and_nav_modals.dart';
import 'package:arcana_app/presentation/screens/tabs/communities_tab_screen.dart';

Future<Map<String, String>?> _fakeStandardPlayerGoogle() async {
  return {
    'sub': 'sub_google_player_001',
    'email': 'jogador@arcanavtt.app',
    'displayName': 'Kaelen Viajante',
    'idToken': 'tok_player_001',
  };
}

Future<Map<String, String>?> _fakeFounderGoogle() async {
  return {
    'sub': 'sub_google_founder_001',
    'email': 'founder@arcanavtt.app',
    'displayName': 'Fundador Arcano',
    'idToken': 'tok_founder_001',
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
  final List<Map<String, dynamic>> _campaigns = [
    {
      'id': 'cmp_other_master',
      'owner_id': 'usr_other_master',
      'title': 'Cidadela das Sombras',
      'synopsis': 'Mesa pública aguardando novos heróis.',
      'master_handle': '@outro_mestre',
      'system_id': 'sys_alphad6_v24',
      'system_name': 'AlphaD6 Core (v2.4)',
      'quick_join_code': 'OTHER9',
      'mode': 'ao_vivo',
      'schedule_text': 'Sáb 20h',
      'max_slots': 5,
      'occupied_slots': 2,
      'chapter_title': 'Prólogo — Portões de Obsidiana',
      'visibility': 'publica',
    },
  ];
  final List<Map<String, dynamic>> _memberships = [];
  final List<Map<String, dynamic>> _characters = [];
  final List<Map<String, dynamic>> _guilds = [];
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _users = [
    {
      'id': 'usr_player_01',
      'email': 'jogador@arcanavtt.app',
      'birth_date': '1999-05-12',
      'role': 'jogador',
      'account_status': 'active',
      'username': 'kaelenviajante',
      'display_name': 'Kaelen Viajante',
    },
  ];

  String _activeUserId = 'usr_player_01';
  String _activeRole = 'jogador';

  @override
  Future<EdgeResponse> checkHealth() async {
    return const EdgeResponse(ok: true, statusCode: 200, data: {'status': 'ok'});
  }

  @override
  Future<EdgeResponse> postAuth(Map<String, dynamic> payload) async {
    final email = (payload['email'] as String?) ?? 'jogador@arcanavtt.app';
    final isFounder = email == 'founder@arcanavtt.app';
    _activeUserId = isFounder ? 'usr_founder' : 'usr_player_01';
    _activeRole = isFounder ? 'superadmin' : 'jogador';

    return EdgeResponse(
      ok: true,
      statusCode: 200,
      data: {
        'token': 'jwt_fake_sync_001',
        'trusted_device_days': 30,
        'user': {
          'id': _activeUserId,
          'email': email,
          'role': _activeRole,
        },
        'profile': {
          'username': isFounder ? 'fundadorarcano' : 'kaelenviajante',
          'display_name': payload['display_name'] ?? 'Aventureiro',
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
        return const EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {'systems': <dynamic>[]},
        );
      case 'compendium.query':
        return const EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {'items': <dynamic>[]},
        );
      case 'campaigns.list':
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {'campaigns': _campaigns, 'memberships': _memberships},
        );
      case 'communities.overview':
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {
            'guilds': _guilds,
            'forum_topics': <dynamic>[],
            'messages': _messages,
          },
        );
      case 'social.overview':
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {
            'friends': <dynamic>[],
            'notifications': <dynamic>[],
            'characters': _characters,
          },
        );
      case 'admin.overview':
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {
            'reports': <dynamic>[],
            'users': _users,
          },
        );
      case 'admin.update_role':
        final targetId = payload['target_user_id'] as String?;
        final role = payload['role'] as String?;
        if (targetId != null && role != null) {
          for (var i = 0; i < _users.length; i++) {
            if (_users[i]['id'] == targetId) {
              _users[i]['role'] = role;
            }
          }
        }
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {'user_id': targetId, 'role': role},
        );
      case 'profile.setup':
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {
            'role': _activeRole,
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
          'owner_id': _activeUserId,
          'title': payload['title'],
          'synopsis': payload['synopsis'],
          'master_handle': '@fundadorarcano',
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
        _memberships.add({
          'campaign_id': 'cmp_001',
          'user_id': _activeUserId,
          'table_role': 'mestre',
          'status': 'active',
        });
        return EdgeResponse(ok: true, statusCode: 201, data: {'campaign': cmp});
      case 'campaigns.lookup_code':
        final code = payload['code'] as String?;
        final found = _campaigns.where((c) => c['quick_join_code'] == code).toList();
        if (found.isEmpty) {
          return const EdgeResponse(
            ok: false,
            statusCode: 404,
            data: {'error': {'code': 'NOT_FOUND', 'message': 'Código inválido'}},
          );
        }
        final cmp = found.first;
        final mem = _memberships.where(
          (m) => m['campaign_id'] == cmp['id'] && m['user_id'] == _activeUserId,
        );
        final membership = mem.isEmpty ? null : mem.first;
        final isMember = cmp['owner_id'] == _activeUserId ||
            membership?['status'] == 'active';
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {
            'campaign': cmp,
            'membership': membership,
            'is_member': isMember,
          },
        );
      case 'campaigns.apply':
        final cmpId = payload['campaign_id'] as String?;
        final pitch = (payload['pitch'] as String?) ?? '';
        if (cmpId == null || pitch.trim().length < 5 || pitch.length > 200) {
          return const EdgeResponse(
            ok: false,
            statusCode: 400,
            data: {'error': {'code': 'INVALID_PITCH', 'message': 'Apresentação inválida'}},
          );
        }
        _memberships.add({
          'campaign_id': cmpId,
          'user_id': _activeUserId,
          'table_role': 'jogador',
          'status': 'pending',
          'application_pitch': pitch,
        });
        return const EdgeResponse(ok: true, statusCode: 201, data: {'status': 'pending'});
      case 'campaigns.list_members':
        return EdgeResponse(
          ok: true,
          statusCode: 200,
          data: {'members': _memberships},
        );
      case 'characters.upsert':
        final cmpId = (payload['campaign_id'] as String?) ?? '';
        if (cmpId.isEmpty) {
          return const EdgeResponse(
            ok: false,
            statusCode: 403,
            data: {
              'error': {
                'code': 'CHARACTER_REQUIRES_ACTIVE_CAMPAIGN',
                'message': 'Ficha requer campanha ativa.',
              },
            },
          );
        }
        final ch = {
          'id': payload['id'] ?? 'char_001',
          'campaign_id': cmpId,
          'name': payload['name'],
          'title': payload['title'],
          'level': payload['level'],
          'attributes_json':
              '{"corpo":${payload['corpo']},"mente":${payload['mente']},"espirito":${payload['espirito']}}',
          'slots_json': '["Espada Curta","Lanterna"]',
          'statuses_json':
              '{"hp_current":${payload['hp_current']},"hp_max":${payload['hp_max']},"anima_current":${payload['anima_current']},"anima_max":${payload['anima_max']},"exhaustion":0}',
        };
        _characters
          ..clear()
          ..add(ch);
        return EdgeResponse(ok: true, statusCode: 200, data: {'character': ch});
      case 'guilds.create':
        if (_activeRole == 'jogador') {
          return const EdgeResponse(
            ok: false,
            statusCode: 403,
            data: {'error': {'code': 'FORBIDDEN', 'message': 'Cargo insuficiente'}},
          );
        }
        final g = {
          'id': 'gld_001',
          'name': payload['name'],
          'tag': payload['tag'],
          'leader_handle': '@fundadorarcano',
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
      case 'chat.send_message':
        final msg = {
          'id': 'msg_001',
          'sender_id': _activeUserId,
          'sender_handle': '@kaelenviajante',
          'sender_role': _activeRole,
          'content': payload['content'],
          'created_at': DateTime.now().toUtc().toIso8601String(),
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

    test('AppController inicia limpo, como Jogador e com URLs imutáveis internas', () {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      expect(ctrl.currentUser.role, UserRole.jogador);
      expect(ctrl.edgeClient.baseUrl, CloudflareEdgeClient.defaultBaseUrl);
      expect(
        LocalStorageDatasource.defaultGoogleServerClientId
            .contains('apps.googleusercontent.com'),
        isTrue,
      );
      expect(ctrl.campaigns, isEmpty);
      expect(ctrl.characters, isEmpty);
      expect(ctrl.hero, isNull);
      expect(ctrl.guilds, isEmpty);
      expect(ctrl.adminUsers, isEmpty);
      expect(ctrl.systems.length, 1);
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

    test('RbacGuard aplica matriz Zero-Trust e Rebaixamento Local corretamente', () {
      expect(RbacGuard.canForgeCampaign(UserRole.jogador), isFalse);
      expect(RbacGuard.canCreateGuild(UserRole.jogador), isFalse);
      expect(RbacGuard.canAccessAdminPanel(UserRole.jogador), isFalse);

      expect(RbacGuard.canForgeCampaign(UserRole.mestre), isTrue);
      expect(RbacGuard.canCreateGuild(UserRole.mestre), isTrue);
      expect(RbacGuard.canManageAdmins(UserRole.mestre), isFalse);
      // Rebaixamento local: Mestre em mesa alheia não administra Oficina/Configs
      expect(
        RbacGuard.canManageCampaignTable(
          isTableMaster: false,
          globalRole: UserRole.mestre,
        ),
        isFalse,
      );
      expect(
        RbacGuard.canManageCampaignTable(
          isTableMaster: true,
          globalRole: UserRole.mestre,
        ),
        isTrue,
      );

      expect(RbacGuard.canAccessAdminPanel(UserRole.admin), isTrue);
      expect(RbacGuard.canManageAdmins(UserRole.admin), isFalse);
      expect(RbacGuard.canAccessAdminPanel(UserRole.superadmin), isTrue);
      expect(RbacGuard.canManageAdmins(UserRole.superadmin), isTrue);
    });
  });

  group('Camada 2 — Testes de Integração de Controller & Sync D1', () {
    test('Novo usuário inicia como Jogador, LGPD <16 bloqueado e Onboarding salva contatos', () async {
      final ctrl = AppController(
        edgeClient: _FakeSyncedEdgeClient(),
        googleSignInProvider: _fakeStandardPlayerGoogle,
      );

      final blockedBan = await ctrl.signInWithGoogleOAuth(
        simulateHardwareBan: true,
      );
      expect(blockedBan, isFalse);
      expect(ctrl.loginViewState, OAuthSecurityState.erroHardwareBan);

      final ok = await ctrl.signInWithGoogleOAuth();
      expect(ok, isTrue);
      expect(ctrl.currentUser.role, UserRole.jogador);
      expect(ctrl.loginViewState, OAuthSecurityState.sucessoAutenticado);

      // Bloqueia menor de 16 anos na etapa de Onboarding
      final minorOk = await ctrl.completeLoginTransitionToHub(
        newUsername: 'kaelenviajante',
        newDisplayName: 'Kaelen Viajante',
        birthDate: DateTime(2015, 1, 1),
      );
      expect(minorOk, isFalse);
      expect(ctrl.isAuthenticated, isFalse);
      expect(ctrl.loginViewState, OAuthSecurityState.erroMenorIdade);

      // Novo login + onboarding válido >= 16 anos + contatos
      await ctrl.signInWithGoogleOAuth();
      final adultOk = await ctrl.completeLoginTransitionToHub(
        newUsername: 'kaelenviajante',
        newDisplayName: 'Kaelen Viajante',
        birthDate: DateTime(1998, 4, 20),
        bio: 'Jogador de dark fantasy.',
        contacts: const {'discord': 'kaelen#9999', 'whatsapp': '+5511999999999'},
      );
      expect(adultOk, isTrue);
      expect(ctrl.loginViewState, OAuthSecurityState.padrao);
      expect(ctrl.currentUser.bio, 'Jogador de dark fantasy.');
      expect(ctrl.currentUser.socialContacts['discord'], 'kaelen#9999');
    });

    test('Bloqueia ficha sem campanha, aprova criação com campaignId, QuickJoin/Candidatura e Guild RBAC', () async {
      final ctrl = AppController(
        edgeClient: _FakeSyncedEdgeClient(),
        googleSignInProvider: _fakeFounderGoogle,
      );
      await ctrl.signInWithGoogleOAuth();
      await ctrl.completeLoginTransitionToHub(
        newUsername: 'fundadorarcano',
        newDisplayName: 'Fundador Arcano',
        birthDate: DateTime(1996, 5, 10),
      );
      expect(ctrl.currentUser.role, UserRole.superadmin);

      // Recusa ficha sem campaignId
      final rejectedHero = await ctrl.saveHeroCharacter(
        campaignId: '',
        name: 'Sem Mesa',
        heroClass: 'Ladino',
        campaignTitle: '',
        level: 1,
        corpo: 2,
        mente: 2,
        espirito: 2,
        slots: const [],
      );
      expect(rejectedHero, isFalse);

      // Lookup não membro retorna isMember = false e candidatura limita 200 chars sem nome de ficha
      final otherLookup = await ctrl.lookupCampaignByCode('OTHER9');
      expect(otherLookup, isNotNull);
      expect(otherLookup!.isMember, isFalse);
      final appOk = await ctrl.applyToCampaign(
        campaignId: otherLookup.campaign.id,
        pitch: 'Curto demais para passar' * 15, // > 200
      );
      expect(appOk, isFalse);
      final validApp = await ctrl.applyToCampaign(
        campaignId: otherLookup.campaign.id,
        pitch: 'Curto interpretacionismo tático aos sábados!',
      );
      expect(validApp, isTrue);

      // Mestre/Superadmin forja campanha e cria ficha vinculada a ela
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

      final heroOk = await ctrl.saveHeroCharacter(
        campaignId: cmp!.id,
        name: 'Kaelen Silvaris',
        heroClass: 'Lâmina Arcana',
        campaignTitle: cmp.title,
        level: 1,
        corpo: 3,
        mente: 2,
        espirito: 2,
        slots: const ['Espada Curta', 'Lanterna'],
      );
      expect(heroOk, isTrue);
      expect(ctrl.characterForCampaign(cmp.id)?.name, 'Kaelen Silvaris');

      // Jogador não pode criar guilda, Superadmin pode
      ctrl.switchActiveRoleForPreview(UserRole.jogador);
      expect(
        await ctrl.createGuild(
          name: 'Guilda Bloqueada',
          tag: 'BLK',
          description: 'Deve falhar para jogador.',
        ),
        isFalse,
      );
      ctrl.switchActiveRoleForPreview(UserRole.superadmin);
      expect(
        await ctrl.createGuild(
          name: 'Ordem Dourada',
          tag: 'ORDE',
          description: 'Guilda inaugural.',
        ),
        isTrue,
      );

      // Admin promove jogador a mestre
      final errRole = await ctrl.adminUpdateUserRole(
        targetUserId: 'usr_player_01',
        newRole: UserRole.mestre,
      );
      expect(errRole, isNull);
    });
  });

  group('Camada 3 — Testes de Interface (OAuth Limpo, Candidatura, RBAC e Configurações)', () {
    testWidgets('LoginScreen oculta config/cargos e Hub bloqueia criação avulsa de ficha',
        (tester) async {
      final ctrl = AppController(
        edgeClient: _FakeSyncedEdgeClient(),
        googleSignInProvider: _fakeStandardPlayerGoogle,
      );
      await tester.pumpWidget(ArcanaVttApp(controller: ctrl));
      await tester.pumpAndSettle();

      // Nenhum seletor de cargo, URL de worker ou Client ID expostos ao usuário
      expect(find.text('Senha de acesso'), findsNothing);
      expect(find.text('PAPEL INICIAL NA TAVERNA'), findsNothing);
      expect(find.text('Servidor Cloudflare Edge & Client ID OAuth'), findsNothing);
      expect(find.text('URL do Cloudflare Worker (Edge API)'), findsNothing);
      expect(find.text('Auxiliar'), findsNothing);
      expect(find.text('Entrar com Conta Google'), findsOneWidget);
      expect(
        find.text('Selecionar Outra Conta Google no Android'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Entrar com Conta Google'));
      await tester.tap(find.text('Entrar com Conta Google'));
      await tester.pumpAndSettle();

      expect(find.text('FORJE SUA IDENTIDADE DE AVENTUREIRO'), findsOneWidget);
      expect(find.text('JOGADOR'), findsOneWidget);
      expect(find.text('Discord (opcional)'), findsOneWidget);
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
      expect(find.text('Criar Ficha de Herói'), findsNothing);
      expect(find.text('Explorar Campanhas'), findsOneWidget);
    });

    testWidgets('QuickJoin abre Candidatura para não-membro sem campo de nome de ficha',
        (tester) async {
      final ctrl = AppController(edgeClient: _FakeSyncedEdgeClient());
      ctrl.isAuthenticated = true;
      ctrl.campaigns = const [
        Campaign(
          id: 'cmp_other_master',
          title: 'Cidadela das Sombras',
          synopsis: 'Mesa pública.',
          masterHandle: '@outro_mestre',
          systemId: 'sys_alphad6_v24',
          systemName: 'AlphaD6 Core (v2.4)',
          quickJoinCode: 'OTHER9',
          mode: CampaignMode.aoVivo,
          scheduleText: 'Sáb 20h',
          maxSlots: 5,
          occupiedSlots: 2,
          userRelation: CampaignSegment.explorar,
          chapterTitle: 'Prólogo',
          isPublic: true,
        ),
      ];

      await tester.pumpWidget(ArcanaVttApp(controller: ctrl));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Inserir Código da Mesa'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'OTHER9');
      await tester.tap(find.text('Localizar Campanha Agora'));
      await tester.pumpAndSettle();

      expect(find.text('CANDIDATURA À MESA'), findsOneWidget);
      expect(find.text('REGRA OFICIAL DE CRIAÇÃO DE FICHA'), findsOneWidget);
      expect(find.text('Nome do Personagem'), findsNothing);
      expect(find.text('0 / 200 caracteres'), findsOneWidget);
    });

    testWidgets('CampaignGeneralModal exibe 7 abas ao Mestre dono e aplica Rebaixamento Local em mesa alheia',
        (tester) async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      ctrl.switchActiveRoleForPreview(UserRole.mestre);

      const ownTable = Campaign(
        id: 'cmp_own',
        title: 'Trono de Cinzas',
        synopsis: 'Mesa do próprio mestre.',
        masterHandle: '@mestre',
        systemId: 'sys_alphad6_v24',
        systemName: 'AlphaD6 Core',
        quickJoinCode: 'OWN123',
        mode: CampaignMode.aoVivo,
        scheduleText: 'Sex 21h',
        maxSlots: 5,
        occupiedSlots: 1,
        userRelation: CampaignSegment.mestre,
        chapterTitle: 'Cap 1',
        isPublic: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [ArcanaPalette.escuroHeraldico],
          ),
          home: Scaffold(
            body: CampaignGeneralModal(controller: ctrl, campaign: ownTable),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final tab in const [
        'Geral',
        'Chats',
        'Cenas',
        'Diário',
        'Oficina',
        'Personagens',
        'Configs',
      ]) {
        expect(find.text(tab), findsOneWidget);
      }

      // Mesma conta Mestre abrindo campanha onde é apenas Jogador -> Oficina/Configs ocultos
      const otherTable = Campaign(
        id: 'cmp_other',
        title: 'Taverna Alheia',
        synopsis: 'Mesa de outro mestre.',
        masterHandle: '@outro',
        systemId: 'sys_alphad6_v24',
        systemName: 'AlphaD6 Core',
        quickJoinCode: 'OTH456',
        mode: CampaignMode.aoVivo,
        scheduleText: 'Dom 19h',
        maxSlots: 5,
        occupiedSlots: 3,
        userRelation: CampaignSegment.jogando,
        chapterTitle: 'Cap 2',
        isPublic: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [ArcanaPalette.escuroHeraldico],
          ),
          home: Scaffold(
            body: CampaignGeneralModal(controller: ctrl, campaign: otherTable),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Geral'), findsOneWidget);
      expect(find.text('Personagens'), findsOneWidget);
      expect(find.text('Oficina'), findsNothing);
      expect(find.text('Configs'), findsNothing);
    });

    testWidgets('CommunitiesTabScreen oculta criação de guilda para Jogador e mostra para Mestre',
        (tester) async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      ctrl.switchActiveRoleForPreview(UserRole.jogador);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [ArcanaPalette.escuroHeraldico],
          ),
          home: Scaffold(body: CommunitiesTabScreen(controller: ctrl)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guildas'));
      await tester.pumpAndSettle();
      expect(find.text('Fundar Nova Guilda'), findsNothing);

      ctrl.switchActiveRoleForPreview(UserRole.mestre);
      await tester.pumpAndSettle();
      expect(find.text('Fundar Nova Guilda'), findsOneWidget);
    });

    testWidgets('GeneralSettingsModal e Drawer RBAC não expõem servidor/cargo e preservam governança',
        (tester) async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [ArcanaPalette.escuroHeraldico],
          ),
          home: Scaffold(body: GeneralSettingsModal(controller: ctrl)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('IDIOMA & FEEDBACK HÁPTICO'), findsOneWidget);
      expect(find.text('PT-BR'), findsOneWidget);
      expect(find.text('SERVIDOR CLOUDFLARE EDGE & D1'), findsNothing);
      expect(find.text('PAPEL NA TAVERNA (SYNC D1)'), findsNothing);

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
