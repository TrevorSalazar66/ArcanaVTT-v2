import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import type { syncPresenceSchema, syncSignalSchema } from '../../schemas/sync_schemas';
import type { AuthenticatedUser, UserRole } from '../../types/env';
import { generateId } from '../../utils/crypto_jwt';

const ROLE_WEIGHT: Record<UserRole, number> = {
  superadmin: 500,
  admin: 450,
  mestre: 400,
  assistente_mestre: 250,
  jogador: 100,
};

interface PresencePayload {
  user_id: string;
  peer_id: string;
  role: UserRole;
  latency_ms: number;
  battery_pct: number;
  score: number;
}

/**
 * Eleição Dinâmica de Líder P2P: calcula pontuação priorizando Mestre -> Auxiliar -> Jogador
 * e desempata por menor latência + bateria disponível.
 */
export function computeLeaderScore(
  role: UserRole,
  latencyMs: number,
  batteryPct: number,
): number {
  const roleBase = ROLE_WEIGHT[role] ?? 100;
  const latencyScore = Math.max(0, 100 - Math.min(100, Math.floor(latencyMs / 5)));
  const batteryScore = Math.floor(batteryPct * 0.5);
  return roleBase + latencyScore + batteryScore;
}

export async function registerP2pPresenceUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof syncPresenceSchema>,
  repo: IArcanaRepository,
) {
  const score = computeLeaderScore(authUser.role, input.latency_ms, input.battery_pct);
  const payload: PresencePayload = {
    user_id: authUser.userId,
    peer_id: input.peer_id,
    role: authUser.role,
    latency_ms: input.latency_ms,
    battery_pct: input.battery_pct,
    score,
  };

  await repo.createP2pSignal({
    id: generateId('p2p'),
    campaign_id: input.campaign_id,
    leader_user_id: authUser.userId,
    from_peer_id: input.peer_id,
    to_peer_id: '*',
    signal_type: 'presence',
    payload_json: JSON.stringify(payload),
    created_at: new Date().toISOString(),
  });

  const peersRaw = await repo.listP2pPresenceByCampaign(input.campaign_id);
  const latestByPeer = new Map<string, PresencePayload>();
  for (const row of peersRaw) {
    try {
      const parsed = JSON.parse(row.payload_json) as PresencePayload;
      if (!latestByPeer.has(parsed.peer_id)) {
        latestByPeer.set(parsed.peer_id, parsed);
      }
    } catch {
      // Ignora entradas corrompidas
    }
  }

  let elected = payload;
  for (const candidate of latestByPeer.values()) {
    if (candidate.score > elected.score) {
      elected = candidate;
    }
  }

  return {
    ok: true,
    campaign_id: input.campaign_id,
    elected_leader: {
      user_id: elected.user_id,
      peer_id: elected.peer_id,
      role: elected.role,
      score: elected.score,
    },
    active_peers_count: latestByPeer.size,
  };
}

export async function forwardP2pSignalUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof syncSignalSchema>,
  repo: IArcanaRepository,
) {
  const signal = {
    id: generateId('sig'),
    campaign_id: input.campaign_id,
    leader_user_id: authUser.userId,
    from_peer_id: input.from_peer_id,
    to_peer_id: input.to_peer_id,
    signal_type: input.signal_type,
    payload_json: input.payload_json,
    created_at: new Date().toISOString(),
  };

  await repo.createP2pSignal(signal);
  return { ok: true, signal_id: signal.id };
}

