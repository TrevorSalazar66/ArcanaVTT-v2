import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { AppError } from '../../middlewares/error_handler';
import type {
  compendiumQuerySchema,
  compendiumUpsertSchema,
  systemsCreateSchema,
  systemsListSchema,
} from '../../schemas/sync_schemas';
import type { AuthenticatedUser, CompendiumCategory } from '../../types/env';
import { generateId } from '../../utils/crypto_jwt';
import { mergeCompendiumDelta, parseDiceRange } from './universal_rpg_engine';

const ALL_UNIVERSAL_CATEGORIES: CompendiumCategory[] = [
  'itens',
  'equipamentos',
  'seres',
  'poderes',
  'pistas',
];

export async function listSystemsUseCase(
  userId: string,
  input: z.infer<typeof systemsListSchema>,
  repo: IArcanaRepository,
) {
  const [all, favorites] = await Promise.all([
    repo.listSystems(),
    repo.listFavoriteSystemIds(userId),
  ]);
  const query = input.search?.trim().toLowerCase() ?? '';
  const systems = all.filter((sys) => {
    if (input.segment === 'meus') {
      if (sys.author_id !== userId && !favorites.includes(sys.id)) return false;
    } else if (input.segment !== 'todos' && sys.category_type !== input.segment) {
      return false;
    }
    if (query) {
      const hay = `${sys.name} ${sys.description}`.toLowerCase();
      if (!hay.includes(query)) return false;
    }
    return true;
  });
  return { ok: true, systems, favorite_ids: favorites };
}

export async function toggleFavoriteSystemUseCase(
  userId: string,
  systemId: string,
  repo: IArcanaRepository,
) {
  const favoriteIds = await repo.toggleFavoriteSystem(userId, systemId);
  return { ok: true, favorite_ids: favoriteIds };
}

export async function createSystemUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof systemsCreateSchema>,
  repo: IArcanaRepository,
) {
  const isPlatformAdmin = authUser.role === 'admin' || authUser.role === 'superadmin';
  const keyCode = input.creation_key?.trim().toUpperCase();

  if (!isPlatformAdmin) {
    if (!keyCode) {
      throw new AppError(
        403,
        'CREATION_KEY_REQUIRED',
        'Forjar um novo sistema requer uma Key de Criacao emitida pelo Admin/Superadmin.',
      );
    }
    const key = await repo.findSystemKey(keyCode);
    if (!key || key.is_used === 1) {
      throw new AppError(403, 'INVALID_CREATION_KEY', 'Key de Criacao invalida ou ja utilizada.');
    }
    if (key.assigned_to_user_id && key.assigned_to_user_id !== authUser.userId) {
      throw new AppError(403, 'CREATION_KEY_MISMATCH', 'Esta Key esta vinculada a outro usuario.');
    }
    await repo.markSystemKeyUsed(key.code, authUser.userId);
  }

  const nowIso = new Date().toISOString();
  const isOfficialFlag = isPlatformAdmin && input.is_official ? 1 : 0;
  const system = {
    id: generateId('sys'),
    author_id: authUser.userId,
    name: input.name,
    version: input.version,
    category_type: isOfficialFlag ? ('oficiais' as const) : ('proprios' as const),
    dice_engine: input.dice_engine,
    description: input.description,
    rules_json: JSON.stringify({
      attributes: input.attributes,
      ...(input.rules_config ?? {}),
    }),
    downloads_count: 1,
    rating: 5.0,
    is_official: isOfficialFlag,
    created_at: nowIso,
  };
  await repo.createSystem(system);
  return { ok: true, system };
}

/**
 * Consulta compêndio do sistema aplicando a regra oficial de Ocultação Automática de Categorias Vazias.
 */
export async function queryCompendiumUseCase(
  input: z.infer<typeof compendiumQuerySchema>,
  repo: IArcanaRepository,
) {
  const allItems = await repo.listCompendiumBySystem(input.system_id);
  const counts: Record<CompendiumCategory, number> = {
    itens: 0,
    equipamentos: 0,
    seres: 0,
    poderes: 0,
    pistas: 0,
  };

  for (const item of allItems) {
    counts[item.category] += 1;
  }

  const visibleCategories = ALL_UNIVERSAL_CATEGORIES.filter((cat) => counts[cat] > 0);

  const query = input.search?.trim().toLowerCase() ?? '';
  const filteredItems = allItems.filter((item) => {
    if (input.category && item.category !== input.category) return false;
    if (query) {
      const hay = `${item.name} ${item.description}`.toLowerCase();
      if (!hay.includes(query)) return false;
    }
    return true;
  });

  return {
    ok: true,
    system_id: input.system_id,
    visible_categories: visibleCategories,
    category_counts: counts,
    items: filteredItems,
  };
}

/**
 * Cria ou edita item do Compêndio com Herança Delta, Blocos RoleGate, Parser {min, max} e limite de 100/categoria.
 */
export async function upsertCompendiumItemUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof compendiumUpsertSchema>,
  repo: IArcanaRepository,
) {
  const existingForSystem = await repo.listCompendiumBySystem(input.system_id);
  const isUpdate = Boolean(input.id && existingForSystem.some((i) => i.id === input.id));
  const categoryCount = existingForSystem.filter((i) => i.category === input.category).length;
  if (!isUpdate && categoryCount >= 100) {
    throw new AppError(
      409,
      'COMPENDIUM_CATEGORY_LIMIT',
      `Limite maximo rigido de 100 homebrews na categoria ${input.category} atingido.`,
    );
  }

  let parentProps: Record<string, unknown> = {};
  if (input.parent_id) {
    const parent = await repo.findCompendiumItemById(input.parent_id);
    if (parent) {
      try {
        parentProps = JSON.parse(parent.properties_json) as Record<string, unknown>;
      } catch {
        parentProps = {};
      }
    }
  }

  const enrichedBlocks: Record<string, Record<string, unknown>> = {};
  for (const [k, rawBlock] of Object.entries(input.blocks)) {
    const b = { ...rawBlock };
    if (typeof b.dice_formula === 'string' && b.dice_formula.trim().length > 0) {
      b.parsed_range = parseDiceRange(b.dice_formula);
    }
    enrichedBlocks[k] = b;
  }

  const baseProps = {
    author_id: authUser.userId,
    parent_id: input.parent_id ?? null,
    is_all_hidden: input.is_all_hidden,
    base_asset_id: input.base_asset_id,
    equip_slot: input.equip_slot ?? null,
    blocks: enrichedBlocks,
    delta_changes: input.delta_changes ?? null,
  };

  const finalProps = input.parent_id
    ? mergeCompendiumDelta(parentProps, baseProps)
    : baseProps;

  const item = {
    id: input.id && input.id.trim().length > 0 ? input.id.trim() : generateId('cmpi'),
    system_id: input.system_id,
    campaign_id: input.campaign_id ?? null,
    category: input.category,
    name: input.name.trim(),
    rarity: input.rarity,
    slots_weight: input.slots_weight,
    description: input.description.trim(),
    properties_json: JSON.stringify(finalProps),
    created_at: new Date().toISOString(),
  };

  await repo.upsertCompendiumItem(item);
  return { ok: true, item };
}
