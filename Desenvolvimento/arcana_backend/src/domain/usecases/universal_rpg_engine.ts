import { AppError } from '../../middlewares/error_handler';

export interface DiceRange {
  min: number;
  max: number;
}

export interface UniversalRollResult {
  label: string;
  expression: string;
  engine: 'formula' | 'pool' | 'd100';
  dice: number[];
  kept_dice?: number[];
  modifier: number;
  total: number;
  successes: number;
  threshold?: number;
  difficulty?: number;
  outcome: string;
}

export interface ParsedChatCommand {
  msgType:
    | 'ic'
    | 'ooc'
    | 'narracao'
    | 'acao'
    | 'roll'
    | 'gmroll'
    | 'whisper'
    | 'action_card';
  cleanContent: string;
  whisperTargetHandle?: string;
  npcName?: string;
  rollResult?: UniversalRollResult;
  actionCard?: {
    card_type: 'rest' | 'heal';
    subtype: string;
    hours_advance: number;
    heal_amount: number;
    roll?: UniversalRollResult;
    status: 'pending' | 'approved' | 'rejected';
  };
}

function secureRandomInt(min: number, max: number): number {
  const span = max - min + 1;
  if (span <= 1) return min;
  const arr = new Uint32Array(1);
  crypto.getRandomValues(arr);
  return min + ((arr[0] ?? 0) % span);
}

/**
 * Extrai intervalo mínimo e máximo `{min, max}` de qualquer fórmula de dados (ex: "2d6 + 4", "1d8+1d6-1").
 */
export function parseDiceRange(rawFormula: string): DiceRange {
  const cleaned = rawFormula.replace(/\s+/g, '').toLowerCase();
  if (!cleaned) return { min: 0, max: 0 };

  const tokenRegex = /([+-]?)(\d*d\d+|\d+)/g;
  let minTotal = 0;
  let maxTotal = 0;
  let matched = false;

  for (const match of cleaned.matchAll(tokenRegex)) {
    matched = true;
    const sign = match[1] === '-' ? -1 : 1;
    const body = match[2] ?? '0';
    if (body.includes('d')) {
      const [countStr, facesStr] = body.split('d');
      const count = Math.min(100, Math.max(1, Number.parseInt(countStr || '1', 10) || 1));
      const faces = Math.min(1000, Math.max(2, Number.parseInt(facesStr || '6', 10) || 6));
      if (sign > 0) {
        minTotal += count * 1;
        maxTotal += count * faces;
      } else {
        minTotal -= count * faces;
        maxTotal -= count * 1;
      }
    } else {
      const val = Number.parseInt(body, 10) || 0;
      minTotal += sign * val;
      maxTotal += sign * val;
    }
  }

  if (!matched) return { min: 0, max: 0 };
  return {
    min: Math.min(minTotal, maxTotal),
    max: Math.max(minTotal, maxTotal),
  };
}

/**
 * Executa qualquer rolagem universal segura em Edge WebCrypto:
 * - Fórmulas aritméticas multi-dados: `2d6+1d4+3`, `1d20+5`, `3d8-2`
 * - Vantagem / Desvantagem Keep High/Low: `2d20kh1`, `2d20kl1`
 * - Paradas de Dados (Pools configuráveis): `4d6>=4`, `5d10>=6`
 * - Percentuais: `1d100<=45`
 */
export function executeUniversalRoll(input: {
  expression: string;
  label?: string;
  forcedPoolThreshold?: number;
  difficulty?: number;
}): UniversalRollResult {
  const raw = input.expression.trim().toLowerCase().replace(/\s+/g, '');
  if (!raw || raw.length > 64) {
    throw new AppError(400, 'INVALID_DICE_EXPRESSION', 'Expressao de dados invalida.');
  }

  const label = (input.label ?? `ROLAGEM ${raw}`).toUpperCase();

  // Caso 1: Keep Highest / Lowest (ex: 2d20kh1, 2d20kl1+3)
  const keepMatch = /^(\d+)d(\d+)(kh|kl)(\d+)([+-]\d+)?$/.exec(raw);
  if (keepMatch) {
    const count = Math.min(20, Math.max(1, Number.parseInt(keepMatch[1]!, 10)));
    const faces = Math.min(1000, Math.max(2, Number.parseInt(keepMatch[2]!, 10)));
    const mode = keepMatch[3]!;
    const keepCount = Math.min(count, Math.max(1, Number.parseInt(keepMatch[4]!, 10)));
    const mod = keepMatch[5] ? Number.parseInt(keepMatch[5], 10) : 0;

    const dice = Array.from({ length: count }, () => secureRandomInt(1, faces));
    const sorted = [...dice].sort((a, b) => (mode === 'kh' ? b - a : a - b));
    const kept = sorted.slice(0, keepCount);
    const total = kept.reduce((acc, v) => acc + v, 0) + mod;

    return {
      label,
      expression: raw,
      engine: 'formula',
      dice,
      kept_dice: kept,
      modifier: mod,
      total,
      successes: total > 0 ? 1 : 0,
      outcome: `Total ${total} (${mode === 'kh' ? 'Vantagem' : 'Desvantagem'})`,
    };
  }

  // Caso 2: Percentual (1d100<=alvo ou d100<=alvo)
  const d100Match = /^(?:1)?d100(?:<=|<)(\d+)$/.exec(raw);
  if (d100Match) {
    const target = Math.min(100, Math.max(1, Number.parseInt(d100Match[1]!, 10)));
    const roll = secureRandomInt(1, 100);
    const ok = roll <= target;
    let outcome = ok ? 'Sucesso Percentual' : 'Falha Percentual';
    if (roll <= 5 && ok) outcome = 'Sucesso Extremo!';
    if (roll >= 96 && !ok) outcome = 'Desastre!';

    return {
      label,
      expression: raw,
      engine: 'd100',
      dice: [roll],
      modifier: 0,
      total: roll,
      successes: ok ? 1 : 0,
      threshold: target,
      outcome: `${outcome} (${roll} vs <=${target})`,
    };
  }

  // Caso 3: Pool de Dados com limiar (ex: 5d6>=4, 4d10>=6 dif:3)
  const poolMatch = /^(\d*)d(\d+)(?:>=|>)(\d+)$/.exec(raw);
  if (poolMatch || input.forcedPoolThreshold !== undefined) {
    const count = poolMatch
      ? Math.min(100, Math.max(1, Number.parseInt(poolMatch[1] || '1', 10)))
      : Math.min(100, Math.max(1, Number.parseInt(/^(\d*)d/.exec(raw)?.[1] || '3', 10)));
    const faces = poolMatch
      ? Math.min(1000, Math.max(2, Number.parseInt(poolMatch[2]!, 10)))
      : Math.min(1000, Math.max(2, Number.parseInt(/d(\d+)/.exec(raw)?.[1] || '6', 10)));
    const threshold = poolMatch
      ? Number.parseInt(poolMatch[3]!, 10)
      : (input.forcedPoolThreshold ?? 5);

    const dice = Array.from({ length: count }, () => secureRandomInt(1, faces));
    const successes = dice.filter((v) => v >= threshold).length;
    const sumSuccesses = dice.filter((v) => v >= threshold).reduce((a, b) => a + b, 0);
    const total = dice.reduce((a, b) => a + b, 0);

    let outcome = 'Falha';
    if (dice.every((v) => v === faces)) {
      outcome = 'Sucesso Crítico!';
    } else if (dice.every((v) => v === 1)) {
      outcome = 'Falha Crítica';
    } else if (input.difficulty !== undefined) {
      if (successes >= input.difficulty) {
        outcome = `Sucesso Total (${successes}/${input.difficulty})`;
      } else if (successes >= Math.ceil(input.difficulty / 2)) {
        outcome = `Sucesso Parcial (${successes}/${input.difficulty})`;
      } else {
        outcome = `Falha (${successes}/${input.difficulty})`;
      }
    } else if (successes > 0) {
      outcome = successes === 1 ? '1 Sucesso' : `${successes} Sucessos!`;
    }

    return {
      label,
      expression: raw,
      engine: 'pool',
      dice,
      modifier: sumSuccesses,
      total,
      successes,
      threshold,
      difficulty: input.difficulty,
      outcome,
    };
  }

  // Caso 4: Expressão matemática genérica de dados (ex: 3d6, 1d20+5, 2d6+1d4-1)
  const termRegex = /([+-]?)(\d*d\d+|\d+)/g;
  const matchedTerms = Array.from(raw.matchAll(termRegex));
  if (matchedTerms.length === 0 || !raw.includes('d')) {
    throw new AppError(
      400,
      'INVALID_DICE_EXPRESSION',
      'Formula invalida. Use formatos como 1d20+5, 3d6, 4d6>=4, 2d20kh1 ou 1d100<=50.',
    );
  }

  const dice: number[] = [];
  let modifier = 0;
  let total = 0;

  for (const match of matchedTerms) {
    const sign = match[1] === '-' ? -1 : 1;
    const body = match[2]!;
    if (body.includes('d')) {
      const [cStr, fStr] = body.split('d');
      const count = Math.min(100, Math.max(1, Number.parseInt(cStr || '1', 10) || 1));
      const faces = Math.min(1000, Math.max(2, Number.parseInt(fStr || '6', 10) || 6));
      for (let i = 0; i < count; i += 1) {
        const val = secureRandomInt(1, faces);
        dice.push(val);
        total += sign * val;
      }
    } else {
      const modVal = sign * (Number.parseInt(body, 10) || 0);
      modifier += modVal;
      total += modVal;
    }
  }

  return {
    label,
    expression: raw,
    engine: 'formula',
    dice,
    modifier,
    total,
    successes: dice.filter((d) => d >= 5).length,
    outcome: `Total ${total}`,
  };
}

export function resolveOpposedRoll(
  rollA: UniversalRollResult,
  rollB: UniversalRollResult,
): { winner: 'A' | 'B' | 'tie'; summary: string } {
  if (rollA.successes > rollB.successes) {
    return {
      winner: 'A',
      summary: `Lado A venceu (${rollA.successes} vs ${rollB.successes} sucessos)`,
    };
  }
  if (rollB.successes > rollA.successes) {
    return {
      winner: 'B',
      summary: `Lado B venceu (${rollB.successes} vs ${rollA.successes} sucessos)`,
    };
  }
  if (rollA.total > rollB.total) {
    return {
      winner: 'A',
      summary: `Desempate por soma: Lado A venceu (${rollA.total} vs ${rollB.total})`,
    };
  }
  if (rollB.total > rollA.total) {
    return {
      winner: 'B',
      summary: `Desempate por soma: Lado B venceu (${rollB.total} vs ${rollA.total})`,
    };
  }
  return {
    winner: 'tie',
    summary: `Empate absoluto (${rollA.successes} sucessos / soma ${rollA.total})`,
  };
}

/**
 * Mescla Herança Delta sobre um elemento pai do Compêndio e resolve `parsed_range` automaticamente.
 */
export function mergeCompendiumDelta(
  parentProps: Record<string, unknown>,
  deltaChanges: Record<string, unknown>,
): Record<string, unknown> {
  const mergedBlocks: Record<string, unknown> = {
    ...((parentProps.blocks as Record<string, unknown> | undefined) ?? {}),
  };
  const deltaBlocks = (deltaChanges.blocks as Record<string, unknown> | undefined) ?? {};
  for (const [key, val] of Object.entries(deltaBlocks)) {
    const prev = (mergedBlocks[key] as Record<string, unknown> | undefined) ?? {};
    const next = typeof val === 'object' && val !== null ? (val as Record<string, unknown>) : { value: val };
    const combined = { ...prev, ...next };
    if (typeof combined.dice_formula === 'string' && combined.dice_formula.trim().length > 0) {
      combined.parsed_range = parseDiceRange(combined.dice_formula);
    }
    mergedBlocks[key] = combined;
  }

  for (const [key, val] of Object.entries(mergedBlocks)) {
    if (typeof val === 'object' && val !== null) {
      const block = val as Record<string, unknown>;
      if (typeof block.dice_formula === 'string' && !block.parsed_range) {
        block.parsed_range = parseDiceRange(block.dice_formula);
      }
      mergedBlocks[key] = block;
    }
  }

  return {
    ...parentProps,
    ...deltaChanges,
    blocks: mergedBlocks,
  };
}

/**
 * Interpretador Universal de Comandos de Chat (`/roll`, `/gmroll`, `/w`, `/me`, `/ooc`, `/gm`, `/npc`, `/rest`, `/heal`, `/init`).
 */
export function parseChatCommand(
  rawContent: string,
  senderHandle: string,
  tableOrGlobalRole: string,
): ParsedChatCommand {
  const text = rawContent.trim();
  const isLeader =
    tableOrGlobalRole === 'mestre' ||
    tableOrGlobalRole === 'assistente_mestre' ||
    tableOrGlobalRole === 'admin' ||
    tableOrGlobalRole === 'superadmin';

  // /gmroll ou /gr (oculto)
  if (/^\/(gmroll|gr)\s+(.+)$/i.test(text)) {
    if (!isLeader) {
      throw new AppError(403, 'FORBIDDEN_GM_COMMAND', 'Apenas Mestre ou Auxiliar pode usar /gmroll.');
    }
    const expr = text.replace(/^\/(gmroll|gr)\s+/i, '').trim();
    const roll = executeUniversalRoll({ expression: expr, label: 'ROLAGEM OCULTA DO MESTRE' });
    return {
      msgType: 'gmroll',
      cleanContent: `[OCULTO GM] ${roll.expression}: [${roll.dice.join(', ')}] -> ${roll.outcome}`,
      rollResult: roll,
    };
  }

  // /roll ou /r
  if (/^\/(roll|r)\s+(.+)$/i.test(text)) {
    const rest = text.replace(/^\/(roll|r)\s+/i, '').trim();
    const difMatch = /dif:(\d+)/i.exec(rest);
    const difficulty = difMatch ? Number.parseInt(difMatch[1]!, 10) : undefined;
    const expr = rest.replace(/dif:\d+/gi, '').trim() || '1d20';
    const roll = executeUniversalRoll({
      expression: expr,
      label: `ROLAGEM (${expr.toUpperCase()})`,
      difficulty,
    });
    return {
      msgType: 'roll',
      cleanContent: `Rolou ${roll.expression}: [${roll.dice.join(', ')}] -> ${roll.outcome}`,
      rollResult: roll,
    };
  }

  // /opposed A vs B
  if (/^\/opposed\s+(.+)\s+vs\s+(.+)$/i.test(text)) {
    const match = /^\/opposed\s+(.+?)\s+vs\s+(.+)$/i.exec(text)!;
    const rollA = executeUniversalRoll({ expression: match[1]!.trim(), label: 'TESTE RESISTIDO (LADO A)' });
    const rollB = executeUniversalRoll({ expression: match[2]!.trim(), label: 'TESTE RESISTIDO (LADO B)' });
    const cmp = resolveOpposedRoll(rollA, rollB);
    return {
      msgType: 'roll',
      cleanContent: `Teste Resistido: [${rollA.dice.join(',')}] (${rollA.total}) vs [${rollB.dice.join(',')}] (${rollB.total}) -> ${cmp.summary}`,
      rollResult: {
        ...rollA,
        label: 'TESTE RESISTIDO',
        outcome: cmp.summary,
      },
    };
  }

  // /w @alvo mensagem ou /whisper @alvo mensagem
  if (/^\/(w|whisper)\s+@?([a-zA-Z0-9_]+)\s+(.+)$/i.test(text)) {
    const match = /^\/(w|whisper)\s+@?([a-zA-Z0-9_]+)\s+(.+)$/i.exec(text)!;
    return {
      msgType: 'whisper',
      whisperTargetHandle: match[2]!.toLowerCase(),
      cleanContent: match[3]!.trim(),
    };
  }

  // /me ação narrativa
  if (/^\/me\s+(.+)$/i.test(text)) {
    const actionText = text.replace(/^\/me\s+/i, '').trim();
    return {
      msgType: 'acao',
      cleanContent: `* ${senderHandle} ${actionText}`,
    };
  }

  // /ooc mensagem
  if (/^\/ooc\s+(.+)$/i.test(text)) {
    return {
      msgType: 'ooc',
      cleanContent: text.replace(/^\/ooc\s+/i, '').trim(),
    };
  }

  // /gm ou /nar (narração solene)
  if (/^\/(gm|nar)\s+(.+)$/i.test(text)) {
    if (!isLeader) {
      throw new AppError(403, 'FORBIDDEN_GM_COMMAND', 'Apenas o Mestre ou Auxiliar pode narrar com /gm.');
    }
    return {
      msgType: 'narracao',
      cleanContent: text.replace(/^\/(gm|nar)\s+/i, '').trim(),
    };
  }

  // /npc Nome: fala
  if (/^\/npc\s+([^:]+):\s*(.+)$/i.test(text)) {
    if (!isLeader) {
      throw new AppError(403, 'FORBIDDEN_GM_COMMAND', 'Apenas o Mestre pode interpretar NPCs com /npc.');
    }
    const match = /^\/npc\s+([^:]+):\s*(.+)$/i.exec(text)!;
    return {
      msgType: 'narracao',
      npcName: match[1]!.trim(),
      cleanContent: `[${match[1]!.trim()}]: "${match[2]!.trim()}"`,
    };
  }

  // /rest ou /descanso [curto|longo|completo]
  if (/^\/(rest|descanso)(?:\s+(curto|longo|completo))?$/i.test(text)) {
    const match = /^\/(rest|descanso)(?:\s+(curto|longo|completo))?$/i.exec(text)!;
    const tipo = (match[2] ?? 'curto').toLowerCase();
    const spec =
      tipo === 'completo'
        ? { expr: '3d8', hours: 8, label: 'DESCANSO COMPLETO' }
        : tipo === 'longo'
          ? { expr: '3d6', hours: 6, label: 'DESCANSO LONGO' }
          : { expr: '3d4', hours: 2, label: 'DESCANSO CURTO' };
    const roll = executeUniversalRoll({ expression: spec.expr, label: spec.label });
    return {
      msgType: 'action_card',
      cleanContent: `Solicitou ${spec.label} (+${roll.total} recuperação, +${spec.hours}h no Relógio).`,
      rollResult: roll,
      actionCard: {
        card_type: 'rest',
        subtype: tipo,
        hours_advance: spec.hours,
        heal_amount: roll.total,
        roll,
        status: 'pending',
      },
    };
  }

  // /heal [emergencia|cuidadosa|completa|1d8+2]
  if (/^\/heal(?:\s+(.+))?$/i.test(text)) {
    const arg = (text.replace(/^\/heal\s*/i, '').trim() || 'emergencia').toLowerCase();
    let amount = 6;
    let hours = 0;
    let roll: UniversalRollResult | undefined;
    if (arg === 'completa') {
      amount = 999;
      hours = 24;
    } else if (arg === 'cuidadosa') {
      amount = 12;
    } else if (arg === 'emergencia') {
      amount = 6;
    } else if (arg.includes('d')) {
      roll = executeUniversalRoll({ expression: arg, label: 'CURA / RESTAURAÇÃO' });
      amount = roll.total;
    } else {
      const parsed = Number.parseInt(arg, 10);
      if (Number.isFinite(parsed) && parsed > 0) amount = parsed;
    }
    return {
      msgType: 'action_card',
      cleanContent: `Solicitou Cura (${arg}) — Recuperação estimada: ${amount === 999 ? '100%' : `+${amount}`}${hours > 0 ? `, +${hours}h` : ''}.`,
      rollResult: roll,
      actionCard: {
        card_type: 'heal',
        subtype: arg,
        hours_advance: hours,
        heal_amount: amount,
        roll,
        status: 'pending',
      },
    };
  }

  // /init ou /iniciativa [formula]
  if (/^\/(init|iniciativa)(?:\s+(.+))?$/i.test(text)) {
    const expr = text.replace(/^\/(init|iniciativa)\s*/i, '').trim() || '1d20';
    const roll = executeUniversalRoll({ expression: expr, label: 'ROLAGEM DE INICIATIVA' });
    return {
      msgType: 'roll',
      cleanContent: `Iniciativa (${roll.expression}): [${roll.dice.join(', ')}] -> Total ${roll.total}`,
      rollResult: roll,
    };
  }

  return {
    msgType: 'ic',
    cleanContent: text,
  };
}
