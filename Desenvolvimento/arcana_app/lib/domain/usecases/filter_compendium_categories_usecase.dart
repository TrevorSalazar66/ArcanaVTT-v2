import '../entities/arcana_entities.dart';

class FilteredCompendiumResult {
  final List<CompendiumCategory> visibleCategories;
  final Map<CompendiumCategory, int> counts;
  final List<CompendiumItem> items;

  const FilteredCompendiumResult({
    required this.visibleCategories,
    required this.counts,
    required this.items,
  });
}

/// Caso de Uso oficial: Ocultação Automática de Categorias Vazias no Compêndio.
class FilterCompendiumCategoriesUseCase {
  FilteredCompendiumResult execute({
    required List<CompendiumItem> systemItems,
    CompendiumCategory? selectedCategory,
    String searchQuery = '',
  }) {
    final counts = {
      for (final category in CompendiumCategory.values) category: 0,
    };
    for (final item in systemItems) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }

    final visibleCategories = CompendiumCategory.values
        .where((category) => (counts[category] ?? 0) > 0)
        .toList();

    final normQuery = searchQuery.trim().toLowerCase();
    final filteredItems = systemItems.where((item) {
      if (selectedCategory != null && item.category != selectedCategory) {
        return false;
      }
      if (normQuery.isNotEmpty) {
        final hay = '${item.name} ${item.description} ${item.rarity}'.toLowerCase();
        if (!hay.contains(normQuery)) return false;
      }
      return true;
    }).toList();

    return FilteredCompendiumResult(
      visibleCategories: visibleCategories,
      counts: counts,
      items: filteredItems,
    );
  }
}

