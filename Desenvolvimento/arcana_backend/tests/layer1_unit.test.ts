import { describe, expect, it } from 'vitest';
import { roll3d6Engine } from '../src/domain/usecases/manage_communities';
import { computeLeaderScore } from '../src/domain/usecases/p2p_signaling';
import { calculateAgeUtc, signJwt, verifyJwt } from '../src/utils/crypto_jwt';

describe('Camada 1 — Testes Unitários (Criptografia, Dados 3d6, Idade e P2P)', () => {
  it('deve assinar e validar JWT HMAC-SHA256 via WebCrypto e rejeitar token adulterado', async () => {
    const secret = 'chave-secreta-teste-arcanavtt-123456';
    const now = Math.floor(Date.now() / 1000);
    const token = await signJwt(
      {
        sub: 'usr_123',
        email: 'heroi@arcanavtt.app',
        role: 'jogador',
        jti: 'jti_abc',
        dfp: 'fp_android_01',
        iat: now,
        exp: now + 3600,
      },
      secret,
    );

    const verified = await verifyJwt(token, secret);
    expect(verified).not.toBeNull();
    expect(verified?.sub).toBe('usr_123');
    expect(verified?.role).toBe('jogador');

    const tampered = `${token.slice(0, -3)}xxx`;
    const rejected = await verifyJwt(tampered, secret);
    expect(rejected).toBeNull();
  });

  it('deve calcular idade UTC com precisao para barreira LGPD >= 16 anos', () => {
    const referenceDate = new Date('2026-06-15T00:00:00.000Z');
    expect(calculateAgeUtc('2010-06-15', referenceDate)).toBe(16);
    expect(calculateAgeUtc('2010-06-16', referenceDate)).toBe(15);
    expect(calculateAgeUtc('1995-01-01', referenceDate)).toBe(31);
  });

  it('deve executar rolagem 3d6 com valores entre 1 e 6 e contagem consistente de sucessos', () => {
    for (let i = 0; i < 25; i += 1) {
      const roll = roll3d6Engine('Teste de Espirito');
      expect(roll.dice.length).toBe(3);
      for (const face of roll.dice) {
        expect(face).toBeGreaterThanOrEqual(1);
        expect(face).toBeLessThanOrEqual(6);
      }
      const expectedSuccesses = roll.dice.filter((d) => d >= 5).length;
      expect(roll.successes).toBe(expectedSuccesses);
    }
  });

  it('deve priorizar Mestre e melhor estabilidade na Eleicao Dinamica de Lider P2P', () => {
    const mestreScore = computeLeaderScore('mestre', 60, 80);
    const auxiliarScore = computeLeaderScore('assistente_mestre', 20, 100);
    const jogadorScore = computeLeaderScore('jogador', 10, 100);
    expect(mestreScore).toBeGreaterThan(auxiliarScore);
    expect(auxiliarScore).toBeGreaterThan(jogadorScore);
  });
});

