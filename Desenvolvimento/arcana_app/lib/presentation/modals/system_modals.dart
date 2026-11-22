import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/security/rbac_guard.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../../domain/entities/arcana_entities.dart';
import '../../../domain/usecases/filter_compendium_categories_usecase.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import '../widgets/svg_icon_widget.dart';
import 'modal_shell.dart';
import 'universal_report_modal.dart';

class SystemPreviewModal extends StatefulWidget {
  final AppController controller;
  final RpgSystem system;

  const SystemPreviewModal({
    super.key,
    required this.controller,
    required this.system,
  });

  @override
  State<SystemPreviewModal> createState() => _SystemPreviewModalState();
}

class _SystemPreviewModalState extends State<SystemPreviewModal> {
  CompendiumCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final role = ctrl.currentUser.role;
    final isPrivileged = role == UserRole.mestre ||
        role == UserRole.assistenteMestre ||
        role == UserRole.admin ||
        role == UserRole.superadmin ||
        widget.system.authorId == ctrl.currentUser.id;

    final FilteredCompendiumResult comp = ctrl.queryCompendium(
      systemId: widget.system.id,
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );

    final visibleItems = comp.items.where((item) {
      if (!item.isAllHidden) return true;
      return isPrivileged || item.authorId == ctrl.currentUser.id;
    }).toList();

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.bookOpen,
      title: widget.system.name,
      subtitle: 'Motor ${widget.system.diceEngine} · ${widget.system.version}',
      badgeLabel: widget.system.isOfficial ? 'OFICIAL' : 'HOMEBREW',
      badgeColor: widget.system.isOfficial ? p.goldPrimary : p.infoBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeraldicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.system.description,
                  style: TextStyle(fontSize: 13, color: p.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.system.attributes
                      .map((a) => HeraldicChipPill(label: a, color: p.goldHighlight))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryHeraldicButton(
                        label: ctrl.favoriteSystemIds.contains(widget.system.id)
                            ? 'Favoritado'
                            : 'Favoritar',
                        svgIcon: ArcanaSvgIcons.heart,
                        borderColor:
                            ctrl.favoriteSystemIds.contains(widget.system.id)
                                ? p.crimson
                                : null,
                        onPressed: () {
                          ctrl.toggleFavoriteSystem(widget.system.id);
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SecondaryHeraldicButton(
                        label: ctrl.offlineCachedSystemIds.contains(widget.system.id)
                            ? 'Salvo Offline'
                            : 'Baixar Offline',
                        svgIcon: ArcanaSvgIcons.download,
                        borderColor:
                            ctrl.offlineCachedSystemIds.contains(widget.system.id)
                                ? p.emerald
                                : null,
                        onPressed: () {
                          ctrl.toggleOfflineCacheSystem(widget.system.id);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar no compendio...',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgIconWidget(ArcanaSvgIcons.search, size: 17),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PrimaryGoldPillButton(
                label: 'Novo Item',
                svgIcon: ArcanaSvgIcons.plus,
                onPressed: () => showArcanaModal(context,
                  builder: (_) => _CompendiumItemEditorModal(
                    controller: ctrl,
                    systemId: widget.system.id,
                  ),
                ).then((_) {
                  if (mounted) setState(() {});
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (comp.visibleCategories.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  for (final cat in comp.visibleCategories) ...[
                    ChoiceChip(
                      label: Text('${cat.labelPtBr} (${comp.counts[cat] ?? 0})'),
                      selected: _selectedCategory == cat,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (visibleItems.isEmpty)
            HeraldicCard(
              child: Text(
                'Nenhum item cadastrado no Compendio deste sistema ainda (categorias vazias ficam ocultas automaticamente). Clique em "+ Novo Item" para forjar Itens, Equipamentos, Seres, Poderes ou Pistas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: p.textSecondary),
              ),
            )
          else
            for (final item in visibleItems) ...[
              HeraldicCard(
                borderColor: item.isAllHidden ? p.crimson : null,
                onTap: () => showArcanaModal(context,
                  builder: (_) => _CompendiumItemDetailModal(
                    controller: ctrl,
                    item: item,
                    canViewHidden: isPrivileged || item.authorId == ctrl.currentUser.id,
                  ),
                ).then((_) {
                  if (mounted) setState(() {});
                }),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HeraldicChipPill(
                          label: item.category.labelPtBr.toUpperCase(),
                          color: p.infoBlue,
                        ),
                        const SizedBox(width: 6),
                        if (item.parentId != null)
                          HeraldicChipPill(label: 'DELTA', color: p.goldHighlight),
                        if (item.isAllHidden) ...[
                          const SizedBox(width: 6),
                          HeraldicChipPill(
                            label: 'OCULTO (SEGREDO)',
                            color: p.crimson,
                            svgIcon: ArcanaSvgIcons.lock,
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '${item.rarity} · ${item.slotsWeight} slot(s)',
                          style: TextStyle(fontSize: 11, color: p.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                    ),
                    if (item.blocks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final b in item.blocks)
                        if (b.isVisible || isPrivileged || item.authorId == ctrl.currentUser.id)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: !b.isVisible
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                                  : p.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: !b.isVisible
                                    ? const Color(0xFFEF4444)
                                    : p.subtleBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (!b.isVisible) ...[
                                  const SvgIconWidget(
                                    ArcanaSvgIcons.lock,
                                    size: 14,
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    '${b.label}: ${b.value}'
                                    '${b.diceFormula != null ? " (${b.diceFormula}${b.parsedMin != null ? " [${b.parsedMin}..${b.parsedMax}]" : ""})" : ""}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: !b.isVisible
                                          ? const Color(0xFFEF4444)
                                          : p.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: SecondaryHeraldicButton(
              label: 'Denunciar Sistema',
              svgIcon: ArcanaSvgIcons.flag,
              borderColor: p.crimson,
              textColor: p.crimson,
              onPressed: () => showArcanaModal(context,
                builder: (_) => UniversalReportModal(
                  controller: ctrl,
                  originType: 'sistema',
                  originId: widget.system.id,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompendiumItemDetailModal extends StatelessWidget {
  final AppController controller;
  final CompendiumItem item;
  final bool canViewHidden;

  const _CompendiumItemDetailModal({
    required this.controller,
    required this.item,
    required this.canViewHidden,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.shield,
      title: item.name,
      subtitle: '${item.category.labelPtBr} · ${item.rarity}',
      badgeLabel: item.parentId != null ? 'HERANCA DELTA' : 'BASE',
      badgeColor: p.goldPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeraldicCard(
            borderColor: item.isAllHidden ? p.crimson : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, style: TextStyle(fontSize: 13.5, color: p.textPrimary)),
                const SizedBox(height: 10),
                Text(
                  'Peso: ${item.slotsWeight} slot(s) · Equipavel: ${item.equipSlot ?? "Mochila Geral"}',
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final b in item.blocks)
            if (b.isVisible || canViewHidden)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: !b.isVisible
                      ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                      : p.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !b.isVisible ? const Color(0xFFEF4444) : p.goldBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!b.isVisible) ...[
                          const SvgIconWidget(ArcanaSvgIcons.lock,
                              size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            b.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: !b.isVisible ? const Color(0xFFEF4444) : p.goldHighlight,
                            ),
                          ),
                        ),
                        if (b.targetVariableId != null)
                          HeraldicChipPill(
                            label: '${b.operation.toUpperCase()} -> ${b.targetVariableId}',
                            color: p.infoBlue,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(b.value, style: TextStyle(fontSize: 12.5, color: p.textPrimary)),
                    if (b.diceFormula != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Formula: ${b.diceFormula} (Min ${b.parsedMin ?? "-"} .. Max ${b.parsedMax ?? "-"})',
                        style: TextStyle(fontSize: 11.5, color: p.emerald),
                      ),
                    ],
                  ],
                ),
              ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryGoldPillButton(
                  label: 'Criar Variante (Delta)',
                  svgIcon: ArcanaSvgIcons.sparkles,
                  onPressed: () {
                    Navigator.of(context).pop();
                    showArcanaModal(context,
                      builder: (_) => _CompendiumItemEditorModal(
                        controller: controller,
                        systemId: item.systemId,
                        parentItem: item,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SecondaryHeraldicButton(
                label: 'Denunciar',
                svgIcon: ArcanaSvgIcons.flag,
                borderColor: p.crimson,
                textColor: p.crimson,
                onPressed: () => showArcanaModal(context,
                  builder: (_) => UniversalReportModal(
                    controller: controller,
                    originType: item.parentId != null ? 'homebrew' : 'compendio',
                    originId: item.id,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompendiumItemEditorModal extends StatefulWidget {
  final AppController controller;
  final String systemId;
  final CompendiumItem? parentItem;

  const _CompendiumItemEditorModal({
    required this.controller,
    required this.systemId,
    this.parentItem,
  });

  @override
  State<_CompendiumItemEditorModal> createState() => _CompendiumItemEditorModalState();
}

class _CompendiumItemEditorModalState extends State<_CompendiumItemEditorModal> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  final _blockLabelCtrl = TextEditingController(text: 'Dano / Efeito');
  final _blockValCtrl = TextEditingController(text: 'Bonus de ataque ou efeito');
  final _formulaCtrl = TextEditingController(text: '1d8+2');
  final _targetVarCtrl = TextEditingController(text: 'hp_current');
  late CompendiumCategory _category;
  String _rarity = 'Comum';
  int _weight = 1;
  bool _isAllHidden = false;
  bool _blockVisible = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.parentItem != null ? '${widget.parentItem!.name} (Delta)' : '',
    );
    _descCtrl = TextEditingController(text: widget.parentItem?.description ?? '');
    _category = widget.parentItem?.category ?? CompendiumCategory.itens;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _blockLabelCtrl.dispose();
    _blockValCtrl.dispose();
    _formulaCtrl.dispose();
    _targetVarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.sparkles,
      title: widget.parentItem != null ? 'Delta Homebrew' : 'Novo Item no Compendio',
      subtitle: 'Blocos visuais RoleGate + Parser {min, max}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<CompendiumCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Categoria Universal'),
            items: CompendiumCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.labelPtBr)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome do Item / Poder / Ser'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descricao Completa'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _rarity,
                  decoration: const InputDecoration(labelText: 'Raridade'),
                  items: const ['Comum', 'Incomum', 'Raro', 'Epico', 'Lendario']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _rarity = v ?? 'Comum'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _weight,
                  decoration: const InputDecoration(labelText: 'Peso (Slots)'),
                  items: [0, 1, 2, 3, 5, 8]
                      .map((w) => DropdownMenuItem(value: w, child: Text('$w slot(s)')))
                      .toList(),
                  onChanged: (v) => setState(() => _weight = v ?? 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _isAllHidden,
            onChanged: (v) => setState(() => _isAllHidden = v),
            title: Text(
              'Ocultar Elemento Inteiro (Segredo do Mestre)',
              style: TextStyle(fontSize: 13, color: p.crimson, fontWeight: FontWeight.w700),
            ),
          ),
          Divider(color: p.subtleBorder),
          Text(
            'Bloco de Regra Dinamico (RoleGate)',
            style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _blockLabelCtrl,
            decoration: const InputDecoration(labelText: 'Titulo do Bloco'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _blockValCtrl,
            decoration: const InputDecoration(labelText: 'Valor / Regra'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _formulaCtrl,
                  decoration: const InputDecoration(labelText: 'Formula (ex: 1d8+2)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _targetVarCtrl,
                  decoration: const InputDecoration(labelText: 'target_variable_id'),
                ),
              ),
            ],
          ),
          SwitchListTile(
            value: _blockVisible,
            onChanged: (v) => setState(() => _blockVisible = v),
            title: const Text('Visivel para Jogadores (RoleGate)'),
          ),
          const SizedBox(height: 12),
          PrimaryGoldPillButton(
            label: _saving ? 'Salvando...' : 'Salvar no Compendio',
            svgIcon: ArcanaSvgIcons.check,
            expand: true,
            onPressed: _saving
                ? null
                : () async {
                    if (_nameCtrl.text.trim().length < 2) return;
                    setState(() => _saving = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await widget.controller.upsertCompendiumItem(
                      systemId: widget.systemId,
                      parentId: widget.parentItem?.id,
                      category: _category,
                      name: _nameCtrl.text,
                      rarity: _rarity,
                      slotsWeight: _weight,
                      description: _descCtrl.text.trim().isEmpty
                          ? 'Elemento criado no Compendio'
                          : _descCtrl.text,
                      isAllHidden: _isAllHidden,
                      blocks: {
                        'bloco_principal': CompendiumBlock(
                          id: 'bloco_principal',
                          label: _blockLabelCtrl.text.trim(),
                          value: _blockValCtrl.text.trim(),
                          diceFormula: _formulaCtrl.text.trim(),
                          targetVariableId: _targetVarCtrl.text.trim(),
                          operation: 'sub',
                          isVisible: _blockVisible,
                        ),
                      },
                    );
                    if (ok && nav.mounted) {
                      nav.pop();
                    } else if (!ok) {
                      setState(() => _saving = false);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.controller.lastSyncError ?? 'Falha ao salvar.',
                          ),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class SystemFiltersModal extends StatelessWidget {
  final List<CompendiumCategory> availableCategories;
  final CompendiumCategory? selected;
  final ValueChanged<CompendiumCategory?> onSelect;

  const SystemFiltersModal({
    super.key,
    required this.availableCategories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.filter,
      title: 'Filtrar Compendio',
      subtitle: 'Categorias vazias ocultas automaticamente',
      child: Column(
        children: [
          ListTile(
            title: const Text('Todas as Categorias Ativas'),
            trailing: selected == null ? const Icon(Icons.check) : null,
            onTap: () {
              onSelect(null);
              Navigator.of(context).pop();
            },
          ),
          for (final cat in availableCategories)
            ListTile(
              title: Text(cat.labelPtBr),
              trailing: selected == cat ? const Icon(Icons.check) : null,
              onTap: () {
                onSelect(cat);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

class SystemForgeModal extends StatefulWidget {
  final AppController controller;

  const SystemForgeModal({super.key, required this.controller});

  @override
  State<SystemForgeModal> createState() => _SystemForgeModalState();
}

class _SystemForgeModalState extends State<SystemForgeModal> {
  final _nameCtrl = TextEditingController();
  final _diceCtrl = TextEditingController(text: '2d12 / Pool / 1d20');
  final _attrsCtrl = TextEditingController(text: 'Forca, Destreza, Intelecto, Vontade');
  final _descCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool _isOfficial = false;
  bool _creating = false;
  String? _errorText;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _diceCtrl.dispose();
    _attrsCtrl.dispose();
    _descCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final isAdmin = RbacGuard.canAccessAdminPanel(widget.controller.currentUser.role);

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.sparkles,
      title: 'Forja de Sistema Universal',
      subtitle: isAdmin
          ? 'Modo Admin/Superadmin (Bypass de Key habilitado)'
          : 'Exige Key de Criacao emitida pelo Admin/Superadmin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isAdmin) ...[
            TextField(
              controller: _keyCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Key de Criacao (KEY-ARC-XXXXXX)',
                hintText: 'Solicite uma Key ao Administrador no Painel',
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome do Sistema de RPG'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _diceCtrl,
            decoration: const InputDecoration(
              labelText: 'Motor / Expressao Principal',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _attrsCtrl,
            decoration: const InputDecoration(
              labelText: 'Atributos Dinamicos (separados por virgula)',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Sinopse de Regras e Cenario',
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isOfficial,
              onChanged: (v) => setState(() => _isOfficial = v),
              title: const Text('Publicar como Sistema Oficial da Plataforma'),
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(_errorText!, style: TextStyle(color: p.crimson, fontSize: 12.5)),
          ],
          const SizedBox(height: 16),
          PrimaryGoldPillButton(
            label: _creating ? 'Forjando...' : 'Criar Sistema Dinamico',
            svgIcon: ArcanaSvgIcons.check,
            expand: true,
            onPressed: _creating
                ? null
                : () async {
                    if (_nameCtrl.text.trim().length < 3 ||
                        _descCtrl.text.trim().length < 10) {
                      setState(() =>
                          _errorText = 'Nome (>=3) e descricao (>=10) obrigatorios.');
                      return;
                    }
                    setState(() {
                      _creating = true;
                      _errorText = null;
                    });
                    final nav = Navigator.of(context);
                    final attrs = _attrsCtrl.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    final ok = await widget.controller.createCustomSystem(
                      name: _nameCtrl.text,
                      diceEngine: _diceCtrl.text,
                      description: _descCtrl.text,
                      attributes: attrs.isEmpty ? const ['Atributo Unico'] : attrs,
                      creationKey: _keyCtrl.text,
                      isOfficial: isAdmin && _isOfficial,
                    );
                    if (ok && nav.mounted) {
                      nav.pop();
                    } else if (!ok) {
                      setState(() {
                        _creating = false;
                        _errorText = widget.controller.lastSyncError ??
                            'Falha ao validar Key ou criar sistema.';
                      });
                    }
                  },
          ),
        ],
      ),
    );
  }
}
