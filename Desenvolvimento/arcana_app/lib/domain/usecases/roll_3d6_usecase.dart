import 'dart:math';
import '../entities/arcana_entities.dart';

/// Motor oficial AlphaD6 3d6 executado client-side (zero custo de servidor).
class Roll3d6UseCase {
  final Random _random;

  Roll3d6UseCase({Random? random}) : _random = random ?? Random.secure();

  DiceRoll3d6 execute({String label = 'TESTE GERAL (3D6)'}) {
    final d1 = _random.nextInt(6) + 1;
    final d2 = _random.nextInt(6) + 1;
    final d3 = _random.nextInt(6) + 1;
    final dice = [d1, d2, d3];
    final successes = dice.where((value) => value >= 5).length;

    String outcome;
    if (d1 == 6 && d2 == 6 && d3 == 6) {
      outcome = 'Sucesso Crítico!';
    } else if (d1 == 1 && d2 == 1 && d3 == 1) {
      outcome = 'Falha Crítica';
    } else if (successes > 0) {
      outcome = successes == 1 ? '1 Sucesso' : '$successes Sucessos!';
    } else {
      outcome = 'Falha';
    }

    return DiceRoll3d6(
      label: label.toUpperCase(),
      dice: dice,
      successes: successes,
      outcome: outcome,
    );
  }
}

