import { describe, expect, it } from 'vitest';
import { InMemoryArcanaRepository } from '../src/data/in_memory_repository';
import {
  executeUniversalRoll,
  mergeCompendiumDelta,
  parseChatCommand,
  parseDiceRange,
  resolveOpposedRoll,
} from '../src/domain/usecases/universal_rpg_engine';
import { queryCompendiumUseCase } from '../src/domain/usecases/manage_systems';
import { signJwt, verifyJwt } from '../src/utils/crypto_jwt';

describe('Layer 1 — Unit Tests: Motor Universal & Regras Puras', () => {
  it('calcula intervalo minimo e maximo {min, max} para formulas multi-dados', () => {
    expect(parseDiceRange('2d6 + 4')).toEqual({ min: 6, max: 16 });
    expect(parseDiceRange('1d8+1d6-1')).toEqual({ min: 1, max: 13 });
    expect(parseDiceRange('3d4')).toEqual({ min: 3, max: 12 });
  });

  it('executa rolagens universais (formula, kh/kl, pool com dificuldade, d100)', () => {
    const formula = executeUniversalRoll({ expression: '2d6+3', label: 'ATAQUE' });
    expect(formula.engine).toBe('formula');
    expect(formula.dice).toHaveLength(2);
    expect(formula.total).toBeGreaterThanOrEqual(5);
    expect(formula.total).toBeLessThanOrEqual(15);

    const adv = executeUniversalRoll({ expression: '2d20kh1+2', label: 'VANTAGEM' });
    expect(adv.engine).toBe('formula');
    expect(adv.dice).toHaveLength(2);
    expect(adv.kept_dice).toHaveLength(1);
    expect(adv.kept_dice![0]).toBe(Math.max(adv.dice[0]!, adv.dice[1]!));

    const pool = executeUniversalRoll({ expression: '4d6>=4', label: 'POOL', difficulty: 2 });
    expect(pool.engine).toBe('pool');
    expect(pool.dice).toHaveLength(4);
    expect(pool.threshold).toBe(4);
    expect(pool.difficulty).toBe(2);

    const d100 = executeUniversalRoll({ expression: '1d100<=55', label: 'FURTIVIDADE' });
    expect(d100.engine).toBe('d100');
    expect(d100.total).toBeGreaterThanOrEqual(1);
    expect(d100.total).toBeLessThanOrEqual(100);
  });

  it('resolve testes resistidos (/opposed) usando sucessos e desempate por soma', () => {
    const rA = {
      label: 'A',
      expression: '3d6>=4',
      engine: 'pool' as const,
      dice: [5, 6, 2],
      modifier: 11,
      total: 13,
      successes: 2,
      outcome: '2 Sucessos!',
    };
    const rB = {
      label: 'B',
      expression: '3d6>=4',
      engine: 'pool' as const,
      dice: [4, 4, 1],
      modifier: 8,
      total: 9,
      successes: 2,
      outcome: '2 Sucessos!',
    };
    const cmp = resolveOpposedRoll(rA, rB);
    expect(cmp.winner).toBe('A');
    expect(cmp.summary).toContain('Desempate por soma');
  });

  it('mescla Heranca Delta de Compendio preservando atributos do pai e gerando parsed_range', () => {
    const parent = {
      author_id: 'usr_admin',
      is_all_hidden: false,
      blocks: {
        dano: { label: 'Dano Base', dice_formula: '1d8', is_visible: true },
        segredo: { label: 'Maldicao', value: 'Sangue', is_visible: false },
      },
    };
    const merged = mergeCompendiumDelta(parent, {
      blocks: {
        dano: { label: 'Dano Flamejante', dice_formula: '1d8+1d6', is_visible: true },
      },
    });
    const blocks = merged.blocks as Record<string, Record<string, unknown>>;
    expect(blocks.dano!.label).toBe('Dano Flamejante');
    expect(blocks.dano!.parsed_range).toEqual({ min: 2, max: 14 });
    expect(blocks.segredo!.is_visible).toBe(false);
  });

  it('interpreta comandos universais (/roll, /gmroll, /opposed, /w, /me, /ooc, /gm, /npc, /rest, /heal, /init)', () => {
    expect(parseChatCommand('/r 2d6+1 dif:1', '@heroi', 'jogador').msgType).toBe('roll');
    expect(parseChatCommand('/opposed 2d6 vs 2d6', '@heroi', 'jogador').msgType).toBe('roll');
    const whisper = parseChatCommand('/w @mestre achei a chave', '@heroi', 'jogador');
    expect(whisper.msgType).toBe('whisper');
    expect(whisper.whisperTargetHandle).toBe('mestre');
    expect(parseChatCommand('/me saca a lamina', '@heroi', 'jogador').msgType).toBe('acao');
    expect(parseChatCommand('/ooc pausa de 5 min', '@heroi', 'jogador').msgType).toBe('ooc');
    expect(parseChatCommand('/rest longo', '@heroi', 'jogador').actionCard?.card_type).toBe('rest');
    expect(parseChatCommand('/heal 2d4+2', '@heroi', 'jogador').actionCard?.card_type).toBe('heal');
    expect(parseChatCommand('/init 1d20+3', '@heroi', 'jogador').msgType).toBe('roll');

    expect(() => parseChatCommand('/gmroll 3d6', '@heroi', 'jogador')).toThrow();
    expect(parseChatCommand('/gmroll 3d6', '@gm', 'mestre').msgType).toBe('gmroll');
    expect(parseChatCommand('/npc Estalajadeiro: Cuidado na floresta.', '@gm', 'mestre').npcName).toBe(
      'Estalajadeiro',
    );
  });

  it('oculta categorias vazias automaticamente ao consultar compendio', async () => {
    const repo = new InMemoryArcanaRepository();
    const emptyRes = await queryCompendiumUseCase(
      { action: 'compendium.query', system_id: 'sys_custom_1' },
      repo,
    );
    expect(emptyRes.visible_categories).toEqual([]);

    await repo.upsertCompendiumItem({
      id: 'cmpi_test_1',
      system_id: 'sys_custom_1',
      campaign_id: null,
      category: 'equipamentos',
      name: 'Cota de Escamas',
      rarity: 'Raro',
      slots_weight: 2,
      description: 'Armadura leve forjada.',
      properties_json: '{}',
      created_at: new Date().toISOString(),
    });

    const result = await queryCompendiumUseCase(
      { action: 'compendium.query', system_id: 'sys_custom_1' },
      repo,
    );
    expect(result.visible_categories).toEqual(['equipamentos']);
    expect(result.category_counts.pistas).toBe(0);
    expect(result.items).toHaveLength(1);
  });

  it('assina e valida JWT HMAC-SHA256 com verificacao de integridade', async () => {
    const nowSec = Math.floor(Date.now() / 1000);
    const token = await signJwt(
      {
        sub: 'usr_tester',
        email: 'tester@arcana.gg',
        role: 'jogador',
        jti: 'jti_123',
        dfp: 'fp_unit',
        iat: nowSec,
        exp: nowSec + 3600,
      },
      'super-secret-unit-key',
    );
    const decoded = await verifyJwt(token, 'super-secret-unit-key');
    expect(decoded?.sub).toBe('usr_tester');
    expect(decoded?.role).toBe('jogador');

    const tampered = await verifyJwt(`${token.slice(0, -4)}zzzz`, 'super-secret-unit-key');
    expect(tampered).toBeNull();
  });
});
