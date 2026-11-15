import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/security/rbac_guard.dart';
import '../../core/theme/arcana_colors.dart';
import '../../domain/usecases/authenticate_oauth_usecase.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import '../widgets/heraldic_section_divider.dart';
import '../widgets/svg_icon_widget.dart';

/// Portal de Autenticação 100% Google OAuth 2.0 (Zero Senhas).
/// Sincronizado com Cloudflare Workers + D1 em tempo real.
class LoginScreen extends StatefulWidget {
  final AppController controller;

  const LoginScreen({super.key, required this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _edgeUrlCtrl;
  late final TextEditingController _googleClientIdCtrl;
  final TextEditingController _recoveryEmailCtrl = TextEditingController();
  final TextEditingController _recoveryCodeCtrl = TextEditingController();

  bool _showServerConfig = false;
  bool _testingConnection = false;
  bool? _connectionOk;
  String? _connectionStatusText;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser;
    _usernameCtrl = TextEditingController(text: user.username);
    _displayNameCtrl = TextEditingController(text: user.displayName);
    _edgeUrlCtrl = TextEditingController(
      text: widget.controller.edgeClient.baseUrl,
    );
    _googleClientIdCtrl = TextEditingController(
      text: widget.controller.googleServerClientId,
    );
    widget.controller.addListener(_syncFromController);
  }

  void _syncFromController() {
    if (!mounted) return;
    final ctrl = widget.controller;
    if (ctrl.loginViewState == OAuthSecurityState.sucessoAutenticado) {
      if (_usernameCtrl.text.trim().isEmpty &&
          ctrl.currentUser.username.isNotEmpty) {
        _usernameCtrl.text = ctrl.currentUser.username;
      }
      if ((_displayNameCtrl.text.trim().isEmpty ||
              _displayNameCtrl.text == 'Aventureiro') &&
          ctrl.currentUser.displayName.isNotEmpty) {
        _displayNameCtrl.text = ctrl.currentUser.displayName;
      }
    }
    if (_edgeUrlCtrl.text != ctrl.edgeClient.baseUrl) {
      _edgeUrlCtrl.text = ctrl.edgeClient.baseUrl;
    }
    if (_googleClientIdCtrl.text != ctrl.googleServerClientId) {
      _googleClientIdCtrl.text = ctrl.googleServerClientId;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _edgeUrlCtrl.dispose();
    _googleClientIdCtrl.dispose();
    _recoveryEmailCtrl.dispose();
    _recoveryCodeCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Future<void> _pickBirthDate(AppController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.selectedBirthDate,
      firstDate: DateTime(1920, 1, 1),
      lastDate: now,
      helpText: 'Data de Nascimento (LGPD >= 16 anos)',
    );
    if (picked != null && mounted) {
      ctrl.setSelectedBirthDate(picked);
    }
  }

  Future<void> _saveAndTestConnection(AppController ctrl) async {
    setState(() {
      _testingConnection = true;
      _connectionStatusText = null;
    });
    await ctrl.updateServerConfig(
      edgeUrl: _edgeUrlCtrl.text,
      googleClientId: _googleClientIdCtrl.text,
    );
    final res = await ctrl.testEdgeConnection();
    if (!mounted) return;
    setState(() {
      _testingConnection = false;
      _connectionOk = res.ok;
      _connectionStatusText = res.ok
          ? 'Conectado ao Edge Worker (HTTP ${res.statusCode}) • Serviço ativo'
          : 'Falha ao conectar (${res.statusCode == 0 ? 'Sem resposta de rede' : 'HTTP ${res.statusCode}'}): verifique a URL do Worker';
    });
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

  Widget _buildStandardOAuthView(
    BuildContext context,
    AppController ctrl,
    ArcanaPalette p,
  ) {
    final roleChoices = const <(UserRole, String)>[
      (UserRole.jogador, 'Jogador'),
      (UserRole.assistenteMestre, 'Auxiliar'),
      (UserRole.mestre, 'Mestre'),
    ];

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
          title: 'ACESSO GOOGLE OAUTH 2.0',
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
                          'Conta Google Android (OAuth 2.0)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'O seletor nativo do Google abrirá ao continuar',
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
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: ctrl.isSyncing ? null : () => _pickBirthDate(ctrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SvgIconWidget(
                        ArcanaSvgIcons.calendar,
                        size: 18,
                        color: p.goldPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data de Nascimento (LGPD >= 16 anos)',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              _formatDate(ctrl.selectedBirthDate),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: p.goldPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const HeraldicChipPill(label: 'Alterar'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Divider(color: p.subtleBorder, height: 1),
              const SizedBox(height: 10),
              Text(
                'PAPEL INICIAL NA TAVERNA',
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: roleChoices.map((entry) {
                  final selected = ctrl.initialRequestedRole == entry.$1;
                  return ChoiceChip(
                    label: Text(entry.$2),
                    selected: selected,
                    onSelected: ctrl.isSyncing
                        ? null
                        : (_) => ctrl.setInitialRequestedRole(entry.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
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
                    onChanged: ctrl.isSyncing ? null : ctrl.setTrustDevice,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HeraldicCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() {
                  _showServerConfig = !_showServerConfig;
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SvgIconWidget(
                        ArcanaSvgIcons.settings,
                        size: 16,
                        color: p.goldPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Servidor Cloudflare Edge & Client ID OAuth',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: p.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      HeraldicChipPill(
                        label: _showServerConfig ? 'Ocultar' : 'Configurar',
                      ),
                    ],
                  ),
                ),
              ),
              if (_showServerConfig) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _edgeUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL do Cloudflare Worker (Edge API)',
                    hintText: 'https://arcana-edge.<subdominio>.workers.dev',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _googleClientIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Google Web/Server Client ID (OAuth 2.0)',
                    hintText: 'xxxxxxxx.apps.googleusercontent.com',
                  ),
                ),
                const SizedBox(height: 10),
                SecondaryHeraldicButton(
                  label: _testingConnection
                      ? 'Testando conexão Edge...'
                      : 'Salvar & Testar Cloudflare Worker',
                  svgIcon: ArcanaSvgIcons.wifi,
                  expand: true,
                  onPressed: _testingConnection
                      ? null
                      : () => _saveAndTestConnection(ctrl),
                ),
                if (_connectionStatusText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _connectionStatusText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _connectionOk == true ? p.emerald : p.crimson,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (ctrl.isSyncing)
          HeraldicCard(
            goldAccent: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: p.goldPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Autenticando no Google e Cloudflare D1...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.goldPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          )
        else
          PrimaryGoldPillButton(
            label: 'Continuar com o Google',
            svgIcon: ArcanaSvgIcons.sparkles,
            onPressed: () async {
              await ctrl.signInWithGoogleOAuth();
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
              if (ctrl.loginViewState == OAuthSecurityState.erroLockoutTotal) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _recoveryEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail Google da Conta Bloqueada',
                    hintText: 'seuemail@gmail.com',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _recoveryCodeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Código de Desbloqueio (6 dígitos)',
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
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await ctrl.verifyLockoutRecovery(
                      email: _recoveryEmailCtrl.text,
                      recoveryCode: _recoveryCodeCtrl.text,
                    );
                    if (!ok && mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ctrl.authErrorMessage ??
                                'Não foi possível validar o código de desbloqueio.',
                          ),
                        ),
                      );
                    }
                  },
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
          onPressed: ctrl.resetLoginState,
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
          label: ctrl.isSyncing
              ? 'Salvando perfil no Cloudflare D1...'
              : 'Entrar no Hub da Taverna',
          svgIcon: ArcanaSvgIcons.arrowRight,
          onPressed: ctrl.isSyncing
              ? null
              : () async {
                  await ctrl.completeLoginTransitionToHub(
                    newUsername: _usernameCtrl.text,
                    newDisplayName: _displayNameCtrl.text,
                  );
                },
        ),
      ],
    );
  }
}

