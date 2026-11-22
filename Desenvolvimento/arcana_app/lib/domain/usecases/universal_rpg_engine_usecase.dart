import 'dart:math';

/// Faixa numérica mínima e máxima extraída de uma fórmula (ex: `2d6 + 4` -> `{min: 6, max: 16}`).
class DiceRange {
  const DiceRange({required this.min, required this.max});

  final int min;
  final int max;
}

/// Resultado padronizado de uma rolagem universal no ArcanaVTT.
class UniversalRollResult {
  const UniversalRollResult({
    required this.label,
    required this.expression,
    required this.engine,
    required this.dice,
    this.keptDice,
    required this.modifier,
    required this.total,
    required this.successes,
    this.threshold,
    this.difficulty,
    required this.outcome,
  });

  final String label;
  final String expression;
  final String engine; // formula | pool | d100
  final List<int> dice;
  final List<int>? keptDice;
  final int modifier;
  final int total;
  final int successes;
  final int? threshold;
  final int? difficulty;
  final String outcome;

  factory UniversalRollResult.fromJson(Map<String, dynamic> json) {
    return UniversalRollResult(
      label: json['label']?.toString() ?? 'ROLAGEM',
      expression: json['expression']?.toString() ?? '1d20',
      engine: json['engine']?.toString() ?? 'formula',
      dice: (json['dice'] as List<dynamic>? ?? const [])
          .map((e) => int.tryParse(e.toString()) ?? 1)
          .toList(),
      keptDice: (json['kept_dice'] as List<dynamic>?)
          ?.map((e) => int.tryParse(e.toString()) ?? 1)
          .toList(),
      modifier: (json['modifier'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      successes: (json['successes'] as num?)?.toInt() ?? 0,
      threshold: (json['threshold'] as num?)?.toInt(),
      difficulty: (json['difficulty'] as num?)?.toInt(),
      outcome: json['outcome']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'expression': expression,
        'engine': engine,
        'dice': dice,
        if (keptDice != null) 'kept_dice': keptDice,
        'modifier': modifier,
        'total': total,
        'successes': successes,
        if (threshold != null) 'threshold': threshold,
        if (difficulty != null) 'difficulty': difficulty,
        'outcome': outcome,
      };
}

/// Motor Universal Agnóstico de Regras e Rolagens (client-side preview/offline + espelho Edge).
class UniversalRpgEngineUseCase {
  UniversalRpgEngineUseCase([Random? rng]) : _rng = rng ?? Random.secure();

  final Random _rng;

  int _rollDie(int faces) => _rng.nextInt(faces.clamp(2, 1000)) + 1;

  /// Extrai intervalo `{min, max}` de qualquer fórmula (ex: `"2d6 + 4"` -> `{min: 6, max: 16}`).
  static DiceRange parseDiceRange(String rawFormula) {
    final cleaned = rawFormula.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (cleaned.isEmpty) return const DiceRange(min: 0, max: 0);

    final tokenRegex = RegExp(r'([+-]?)(\d*d\d+|\d+)');
    var minTotal = 0;
    var maxTotal = 0;
    var matched = false;

    for (final m in tokenRegex.allMatches(cleaned)) {
      matched = true;
      final sign = m.group(1) == '-' ? -1 : 1;
      final body = m.group(2) ?? '0';
      if (body.contains('d')) {
        final parts = body.split('d');
        final count = (int.tryParse(parts[0].isEmpty ? '1' : parts[0]) ?? 1).clamp(1, 100);
        final faces = (int.tryParse(parts[1]) ?? 6).clamp(2, 1000);
        if (sign > 0) {
          minTotal += count * 1;
          maxTotal += count * faces;
        } else {
          minTotal -= count * faces;
          maxTotal -= count * 1;
        }
      } else {
        final val = int.tryParse(body) ?? 0;
        minTotal += sign * val;
        maxTotal += sign * val;
      }
    }

    if (!matched) return const DiceRange(min: 0, max: 0);
    return DiceRange(
      min: minTotal < maxTotal ? minTotal : maxTotal,
      max: minTotal > maxTotal ? minTotal : maxTotal,
    );
  }

  /// Executa fórmulas `XdY+Z`, vantagem/desvantagem `2d20kh1`/`kl1`, pools `XdY>=T` e `1d100<=Target`.
  UniversalRollResult executeRoll(
    String expression, {
    String? label,
    int? forcedPoolThreshold,
    int? difficulty,
  }) {
    final raw = expression.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (raw.isEmpty || raw.length > 64) {
      throw ArgumentError('Expressao de dados invalida: $expression');
    }

    final finalLabel = (label ?? 'ROLAGEM $raw').toUpperCase();

    // Keep Highest / Keep Lowest
    final keepMatch = RegExp(r'^(\d+)d(\d+)(kh|kl)(\d+)([+-]\d+)?$').firstMatch(raw);
    if (keepMatch != null) {
      final count = (int.parse(keepMatch.group(1)!)).clamp(1, 20);
      final faces = (int.parse(keepMatch.group(2)!)).clamp(2, 1000);
      final mode = keepMatch.group(3)!;
      final keepCount = (int.parse(keepMatch.group(4)!)).clamp(1, count);
      final mod = keepMatch.group(5) != null ? int.parse(keepMatch.group(5)!) : 0;

      final dice = List<int>.generate(count, (_) => _rollDie(faces));
      final sorted = List<int>.from(dice)
        ..sort((a, b) => mode == 'kh' ? b.compareTo(a) : a.compareTo(b));
      final kept = sorted.take(keepCount).toList();
      final total = kept.fold<int>(0, (acc, v) => acc + v) + mod;

      return UniversalRollResult(
        label: finalLabel,
        expression: raw,
        engine: 'formula',
        dice: dice,
        keptDice: kept,
        modifier: mod,
        total: total,
        successes: total > 0 ? 1 : 0,
        outcome: 'Total $total (${mode == 'kh' ? 'Vantagem' : 'Desvantagem'})',
      );
    }

    // D100 percentual
    final d100Match = RegExp(r'^(?:1)?d100(?:<=|<)(\d+)$').firstMatch(raw);
    if (d100Match != null) {
      final target = int.parse(d100Match.group(1)!).clamp(1, 100);
      final roll = _rollDie(100);
      final ok = roll <= target;
      var outcome = ok ? 'Sucesso Percentual' : 'Falha Percentual';
      if (roll <= 5 && ok) outcome = 'Sucesso Extremo!';
      if (roll >= 96 && !ok) outcome = 'Desastre!';

      return UniversalRollResult(
        label: finalLabel,
        expression: raw,
        engine: 'd100',
        dice: [roll],
        modifier: 0,
        total: roll,
        successes: ok ? 1 : 0,
        threshold: target,
        outcome: '$outcome ($roll vs <=$target)',
      );
    }

    // Pool com limiar
    final poolMatch = RegExp(r'^(\d*)d(\d+)(?:>=|>)(\d+)$').firstMatch(raw);
    if (poolMatch != null || forcedPoolThreshold != null) {
      final countStr = poolMatch?.group(1) ?? RegExp(r'^(\d*)d').firstMatch(raw)?.group(1) ?? '3';
      final facesStr = poolMatch?.group(2) ?? RegExp(r'd(\d+)').firstMatch(raw)?.group(1) ?? '6';
      final count = (int.tryParse(countStr.isEmpty ? '1' : countStr) ?? 3).clamp(1, 100);
      final faces = (int.tryParse(facesStr) ?? 6).clamp(2, 1000);
      final threshold = poolMatch != null ? int.parse(poolMatch.group(3)!) : (forcedPoolThreshold ?? 5);

      final dice = List<int>.generate(count, (_) => _rollDie(faces));
      final successes = dice.where((v) => v >= threshold).length;
      final sumSuccess = dice.where((v) => v >= threshold).fold<int>(0, (a, b) => a + b);
      final total = dice.fold<int>(0, (a, b) => a + b);

      var outcome = 'Falha';
      if (dice.every((v) => v == faces)) {
        outcome = 'Sucesso Crítico!';
      } else if (dice.every((v) => v == 1)) {
        outcome = 'Falha Crítica';
      } else if (difficulty != null) {
        if (successes >= difficulty) {
          outcome = 'Sucesso Total ($successes/$difficulty)';
        } else if (successes >= (difficulty / 2).ceil()) {
          outcome = 'Sucesso Parcial ($successes/$difficulty)';
        } else {
          outcome = 'Falha ($successes/$difficulty)';
        }
      } else if (successes > 0) {
        outcome = successes == 1 ? '1 Sucesso' : '$successes Sucessos!';
      }

      return UniversalRollResult(
        label: finalLabel,
        expression: raw,
        engine: 'pool',
        dice: dice,
        modifier: sumSuccess,
        total: total,
        successes: successes,
        threshold: threshold,
        difficulty: difficulty,
        outcome: outcome,
      );
    }

    // Expressão aritmética genérica (XdY + Z)
    final termRegex = RegExp(r'([+-]?)(\d*d\d+|\d+)');
    final matches = termRegex.allMatches(raw).toList();
    if (matches.isEmpty || !raw.contains('d')) {
      throw ArgumentError('Formula de dados invalida: $expression');
    }

    final dice = <int>[];
    var modifier = 0;
    var total = 0;
    for (final m in matches) {
      final sign = m.group(1) == '-' ? -1 : 1;
      final body = m.group(2)!;
      if (body.contains('d')) {
        final parts = body.split('d');
        final count = (int.tryParse(parts[0].isEmpty ? '1' : parts[0]) ?? 1).clamp(1, 100);
        final faces = (int.tryParse(parts[1]) ?? 6).clamp(2, 1000);
        for (var i = 0; i < count; i++) {
          final v = _rollDie(faces);
          dice.add(v);
          total += sign * v;
        }
      } else {
        final modVal = sign * (int.tryParse(body) ?? 0);
        modifier += modVal;
        total += modVal;
      }
    }

    return UniversalRollResult(
      label: finalLabel,
      expression: raw,
      engine: 'formula',
      dice: dice,
      modifier: modifier,
      total: total,
      successes: dice.where((d) => d >= 5).length,
      outcome: 'Total $total',
    );
  }

  /// Resolve teste resistido com desempate por soma total.
  static Map<String, String> resolveOpposed(
    UniversalRollResult a,
    UniversalRollResult b,
  ) {
    if (a.successes > b.successes) {
      return {'winner': 'A', 'summary': 'Lado A venceu (${a.successes} vs ${b.successes} sucessos)'};
    }
    if (b.successes > a.successes) {
      return {'winner': 'B', 'summary': 'Lado B venceu (${b.successes} vs ${a.successes} sucessos)'};
    }
    if (a.total > b.total) {
      return {'winner': 'A', 'summary': 'Desempate por soma: Lado A venceu (${a.total} vs ${b.total})'};
    }
    if (b.total > a.total) {
      return {'winner': 'B', 'summary': 'Desempate por soma: Lado B venceu (${b.total} vs ${a.total})'};
    }
    return {'winner': 'tie', 'summary': 'Empate absoluto (${a.successes} sucessos / soma ${a.total})'};
  }

  /// Mescla Herança Delta sobre um mapa de blocos do item pai.
  static Map<String, dynamic> mergeCompendiumDelta(
    Map<String, dynamic> parentProps,
    Map<String, dynamic> deltaChanges,
  ) {
    final parentBlocks = Map<String, dynamic>.from(
      (parentProps['blocks'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final deltaBlocks = (deltaChanges['blocks'] as Map?)?.cast<String, dynamic>() ?? const {};

    for (final entry in deltaBlocks.entries) {
      final prev = Map<String, dynamic>.from(
        (parentBlocks[entry.key] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final next = entry.value is Map
          ? Map<String, dynamic>.from((entry.value as Map).cast<String, dynamic>())
          : <String, dynamic>{'value': entry.value};
      final combined = <String, dynamic>{...prev, ...next};
      if (combined['dice_formula'] is String &&
          (combined['dice_formula'] as String).trim().isNotEmpty) {
        final range = parseDiceRange(combined['dice_formula'] as String);
        combined['parsed_range'] = {'min': range.min, 'max': range.max};
      }
      parentBlocks[entry.key] = combined;
    }

    return <String, dynamic>{
      ...parentProps,
      ...deltaChanges,
      'blocks': parentBlocks,
    };
  }
}
