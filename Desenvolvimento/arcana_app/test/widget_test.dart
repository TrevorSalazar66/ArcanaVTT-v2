import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arcana_app/controllers/app_controller.dart';
import 'package:arcana_app/core/security/rbac_guard.dart';
import 'package:arcana_app/core/theme/arcana_colors.dart';
import 'package:arcana_app/data/datasources/cloudflare_edge_client.dart';
import 'package:arcana_app/domain/entities/arcana_entities.dart';
import 'package:arcana_app/domain/usecases/authenticate_oauth_usecase.dart';
import 'package:arcana_app/domain/usecases/build_universal_report_usecase.dart';
import 'package:arcana_app/domain/usecases/roll_3d6_usecase.dart';
import 'package:arcana_app/main.dart';
import 'package:arcana_app/presentation/modals/community_chat_modal.dart';

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
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      final laminaResult = ctrl.queryCompendium(systemId: 'sys_lamina_carmesim');
      expect(laminaResult.visibleCategories, [CompendiumCategory.poderes]);
      expect(laminaResult.visibleCategories.contains(CompendiumCategory.seres), isFalse);

      final alphaResult = ctrl.queryCompendium(systemId: 'sys_alphad6_v24');
      expect(alphaResult.visibleCategories.length, 5);
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

  group('Camada 2 — Testes de Integração de Controller', () {
    test('Bloqueia login menor de 16 anos, Hardware Ban e Lockout Total', () async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());

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
    });

    test('Quick Join por codigo, envio de 3d6 no chat e troca de tema/escala', () async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      await ctrl.setThemeMode(ArcanaThemeMode.oled);
      await ctrl.setFontScale(1.2);
      expect(ctrl.themeMode, ArcanaThemeMode.oled);
      expect(ctrl.fontScale, 1.2);

      final joined = ctrl.quickJoinByCode('arc-774');
      expect(joined, isNotNull);
      expect(joined?.quickJoinCode, 'ARC774');

      final initialCount = ctrl.chatMessages.length;
      ctrl.sendCommunityMessage(content: 'Testando rolagem', with3d6Roll: true);
      expect(ctrl.chatMessages.length, initialCount + 1);
      expect(ctrl.chatMessages.last.diceRoll, isNotNull);
      expect(ctrl.chatMessages.last.isMine, isTrue);
    });
  });

  group('Camada 3 — Testes de Interface (UI, OAuth, Navegação, Chat e RBAC Pruning)', () {
    testWidgets('LoginScreen exibe 100% Google OAuth sem campo de senha e navega ao Hub',
        (tester) async {
      final ctrl = AppController(edgeClient: _OfflineStubEdgeClient());
      await tester.pumpWidget(ArcanaVttApp(controller: ctrl));
      await tester.pumpAndSettle();

      // Garante ausência de campos tradicionais de email/senha
      expect(find.text('Senha de acesso'), findsNothing);
      expect(find.text('Recuperar Senha'), findsNothing);
      expect(find.text('Continuar com o Google'), findsOneWidget);

      // Login 1-Tap com Google
      await tester.ensureVisible(find.text('Continuar com o Google'));
      await tester.tap(find.text('Continuar com o Google'));
      await tester.pumpAndSettle();

      expect(ctrl.isAuthenticated, isTrue);
      expect(find.text('CONTINUAR A JORNADA'), findsOneWidget);

      // Navega entre as 4 abas
      await tester.tap(find.text('Campanhas'));
      await tester.pumpAndSettle();
      expect(find.text('A Maldição de Valen'), findsOneWidget);

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

      // Fecha Drawer e promove para Superadmin
      await tester.tapAt(const Offset(380, 100));
      await tester.pumpAndSettle();
      ctrl.switchActiveRoleForPreview(UserRole.superadmin);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu Principal'));
      await tester.pumpAndSettle();
      expect(find.text('Painel de Governança Admin'), findsOneWidget);
    });

    testWidgets('CommunityChatModal renderiza chat WhatsApp+Discord e rola 3d6 ao vivo',
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
      expect(find.textContaining('TESTE DE MENTE (3D6)'), findsOneWidget);

      final beforeCount = ctrl.chatMessages.length;
      await tester.tap(find.byTooltip('Rolar 3d6 no Chat'));
      await tester.pumpAndSettle();

      expect(ctrl.chatMessages.length, beforeCount + 1);
      expect(ctrl.chatMessages.last.diceRoll, isNotNull);
    });
  });
}
