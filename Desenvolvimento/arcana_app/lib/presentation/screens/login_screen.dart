import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/theme/arcana_colors.dart';
import '../../domain/usecases/authenticate_oauth_usecase.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import '../widgets/heraldic_section_divider.dart';
import '../widgets/svg_icon_widget.dart';

/// Portal de Autenticação 100% Google OAuth 2.0 (Zero Senhas).
/// Implementa fielmente os estados Padrão OAuth, Erro/Bloqueio e Sucesso + Onboarding.
class LoginScreen extends StatefulWidget {
  final AppController controller;

  const LoginScreen({super.key, required this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _displayNameCtrl;
  final TextEditingController _recoveryCodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameCtrl =
        TextEditingController(text: widget.controller.currentUser.username);
    _displayNameCtrl = TextEditingController(
      text: widget.controller.selectedGoogleAccountName,
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _recoveryCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final p = context.arcana;

    return Scaffold(
      backgroundColor: p.voidBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, p),
                  const SizedBox(height: 16),
                  _buildStatePreviewSelector(ctrl, p),
                  const SizedBox(height: 16),
                  if (ctrl.loginViewState == OAuthSecurityState.padrao)
                    _buildStandardOAuthView(context, ctrl, p)
                  else if (ctrl.loginViewState ==
                      OAuthSecurityState.sucessoAutenticado)
                    _buildSuccessOnboardingView(context, ctrl, p)
                  else
                    _buildSecurityErrorView(context, ctrl, p),
                  const SizedBox(height: 20),
                  Text(
                    '100% Google OAuth 2.0 • Zero senhas armazenadas • LGPD (>= 16 anos)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ArcanaPalette p) {
    return HeraldicCard(
      goldAccent: true,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.goldBorder),
            ),
            alignment: Alignment.center,
            child: SvgIconWidget(ArcanaSvgIcons.dices, size: 28, color: p.goldPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARCANA VTT',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: p.goldPrimary,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Portal de Autenticação Segura OAuth 2.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const HeraldicChipPill(label: 'V0.1'),
        ],
      ),
    );
  }

  Widget _buildStatePreviewSelector(AppController ctrl, ArcanaPalette p) {
    final activeIdx = switch (ctrl.loginViewState) {
      OAuthSecurityState.padrao => 0,
      OAuthSecurityState.sucessoAutenticado => 2,
      _ => 1,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'INSPEÇÃO RÁPIDA DE ESTADOS DO PORTAL',
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        HeraldicSegmentBar(
          segments: const ['OAuth Padrão', 'Erro / Bloqueio', 'Sucesso'],
          selectedIndex: activeIdx,
          onSelected: (index) {
            if (index == 0) {
              ctrl.previewLoginState(OAuthSecurityState.padrao);
            } else if (index == 1) {
              ctrl.previewLoginState(OAuthSecurityState.erroMenorIdade);
            } else {
              ctrl.previewLoginState(OAuthSecurityState.sucessoAutenticado);
            }
          },
        ),
      ],
    );
  }

  Widget _buildStandardOAuthView(
    BuildContext context,
    AppController ctrl,
    ArcanaPalette p,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeraldicCard(
          goldAccent: true,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.surfaceElevated,
                  border: Border.all(color: p.goldBorder),
                ),
                alignment: Alignment.center,
                child: SvgIconWidget(ArcanaSvgIcons.shield, size: 24, color: p.goldPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'SAUDAÇÕES, AVENTUREIRO!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Acesso exclusivo via Conta Google. Nenhuma senha é criada ou armazenada pelo ArcanaVTT.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const HeraldicSectionDivider(
          svgIcon: ArcanaSvgIcons.key,
          title: 'ACESSO RÁPIDO GOOGLE OAUTH',
        ),
        const SizedBox(height: 6),
        HeraldicCard(
          goldAccent: true,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const SvgIconWidget(
                      ArcanaSvgIcons.googleG,
                      size: 22,
                      preserveOriginalColors: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ctrl.selectedGoogleAccountName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          ctrl.selectedGoogleAccountEmail,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  HeraldicChipPill(
                    label: 'OAuth 2.0',
                    color: p.emerald,
                    svgIcon: ArcanaSvgIcons.check,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: p.subtleBorder, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  SvgIconWidget(ArcanaSvgIcons.shield, size: 18, color: p.emerald),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confiar neste aparelho Android',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          'Sessão persistente de 15 a 30 dias (Keystore)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: ctrl.trustDevice,
                    activeTrackColor: p.emerald,
                    onChanged: ctrl.setTrustDevice,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryGoldPillButton(
          label: 'Continuar com o Google',
          svgIcon: ArcanaSvgIcons.sparkles,
          onPressed: () async {
            await ctrl.signInWithGoogleOAuth();
          },
        ),
        const SizedBox(height: 10),
        SecondaryHeraldicButton(
          label: 'Usar Outra Conta Google',
          svgIcon: ArcanaSvgIcons.user,
          expand: true,
          onPressed: () {
            ctrl.switchSimulatedGoogleAccount();
            _displayNameCtrl.text = ctrl.selectedGoogleAccountName;
          },
        ),
      ],
    );
  }

  Widget _buildSecurityErrorView(
    BuildContext context,
    AppController ctrl,
    ArcanaPalette p,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeraldicCard(
          borderColor: p.crimson,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.crimson.withValues(alpha: 0.14),
                  border: Border.all(color: p.crimson),
                ),
                alignment: Alignment.center,
                child: SvgIconWidget(ArcanaSvgIcons.lock, size: 26, color: p.crimson),
              ),
              const SizedBox(height: 12),
              Text(
                ctrl.authErrorTitle ?? 'Acesso Bloqueado por Segurança',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: p.crimson,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                ctrl.authErrorMessage ??
                    'Requisito mínimo de 16 anos (LGPD) ou verificação de segurança falhou.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ActionChip(
                    label: const Text('Simular < 16 anos'),
                    onPressed: () =>
                        ctrl.previewLoginState(OAuthSecurityState.erroMenorIdade),
                  ),
                  ActionChip(
                    label: const Text('Hardware Ban'),
                    onPressed: () =>
                        ctrl.previewLoginState(OAuthSecurityState.erroHardwareBan),
                  ),
                  ActionChip(
                    label: const Text('Lockout Total'),
                    onPressed: () =>
                        ctrl.previewLoginState(OAuthSecurityState.erroLockoutTotal),
                  ),
                ],
              ),
              if (ctrl.loginViewState == OAuthSecurityState.erroLockoutTotal) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _recoveryCodeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Código de Desbloqueio (6 dígitos via Resend)',
                    hintText: 'Ex: 482910',
                  ),
                ),
                const SizedBox(height: 10),
                SecondaryHeraldicButton(
                  label: 'Validar Código & Restaurar Acesso',
                  svgIcon: ArcanaSvgIcons.mail,
                  borderColor: p.emerald,
                  textColor: p.emerald,
                  expand: true,
                  onPressed: () => ctrl.previewLoginState(OAuthSecurityState.padrao),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        SecondaryHeraldicButton(
          label: 'Voltar ao Login Google OAuth',
          svgIcon: ArcanaSvgIcons.arrowLeft,
          expand: true,
          onPressed: () => ctrl.previewLoginState(OAuthSecurityState.padrao),
        ),
      ],
    );
  }

  Widget _buildSuccessOnboardingView(
    BuildContext context,
    AppController ctrl,
    ArcanaPalette p,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeraldicCard(
          borderColor: p.emerald,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.emerald.withValues(alpha: 0.14),
                  border: Border.all(color: p.emerald),
                ),
                alignment: Alignment.center,
                child: SvgIconWidget(
                  ArcanaSvgIcons.circleCheck,
                  size: 28,
                  color: p.emerald,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Autenticação Google Verificada!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: p.emerald,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Confirme seu identificador único na Taverna antes de entrar no Hub Central.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Identificador Único (@username)',
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _displayNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome de Aventureiro / Mestre',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PrimaryGoldPillButton(
          label: 'Entrar no Hub da Taverna',
          svgIcon: ArcanaSvgIcons.arrowRight,
          onPressed: () {
            ctrl.completeLoginTransitionToHub(
              newUsername: _usernameCtrl.text,
              newDisplayName: _displayNameCtrl.text,
            );
          },
        ),
      ],
    );
  }
}

