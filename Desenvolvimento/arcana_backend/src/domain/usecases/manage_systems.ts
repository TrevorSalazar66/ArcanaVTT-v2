import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import type {
  compendiumQuerySchema,
  systemsCreateSchema,
  systemsListSchema,
} from '../../schemas/sync_schemas';
import type { CompendiumCategory } from '../../types/env';
import { generateId } from '../../utils/crypto_jwt';

const ALL_UNIVERSAL_CATEGORIES: CompendiumCategory[] = [
  'itens',
  'equipamentos',
  'seres',
  'poderes',
  'pistas',
];

export async function listSystemsUseCase(
  input: z.infer<typeof systemsListSchema>,
  repo: IArcanaRepository,
) {
  const all = await repo.listSystems();
  const query = input.search?.trim().toLowerCase() ?? '';
  const systems = all.filter((sys) => {
    if (input.segment !== 'todos' && sys.category_type !== input.segment) {
      return false;
    }
    if (query) {
      const hay = `${sys.name} ${sys.description}`.toLowerCase();
      if (!hay.includes(query)) return false;
    }
    return true;
  });
  return { ok: true, systems };
}

export async function createSystemUseCase(
  userId: string,
  input: z.infer<typeof systemsCreateSchema>,
  repo: IArcanaRepository,
) {
  const nowIso = new Date().toISOString();
  const system = {
    id: generateId('sys'),
    author_id: userId,
    name: input.name,
    version: input.version,
    category_type: 'proprios' as const,
    dice_engine: input.dice_engine,
    description: input.description,
    rules_json: JSON.stringify({
      attributes: input.attributes,
      inventory_slots: 12,
      success_threshold: 5,
    }),
    downloads_count: 1,
    rating: 5.0,
    is_official: 0,
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

  const visibleCategories = ALL_UNIVERSAL_CATEGORIES.filter(
    (cat) => counts[cat] > 0,
  );

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

