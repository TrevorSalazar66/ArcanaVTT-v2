# Regras de Estilo e Formatação de Código (Code Style)

## 📌 JavaScript / TypeScript
- **Formatação:** Usar 2 espaços para indentação, aspas simples `'` para strings e ponto e vírgula `;` explícito.
- **Tipagem:** TypeScript estrito (`strict: true`). Evite usar `any`. Prefira `unknown` com type guards ou interfaces/types bem definidos.
- **Nomenclatura:**
  - `camelCase` para variáveis, propriedades e funções.
  - `PascalCase` para componentes React/Vue, classes, tipos e interfaces.
  - `UPPER_SNAKE_CASE` para constantes globais e variáveis de ambiente.
  - `kebab-case` para nomes de arquivos e diretórios (ex: `user-profile.ts`).

## 📌 CSS / Estilização
- Dar preferência a CSS Moderno (Vanilla CSS, CSS Modules ou TailwindCSS quando especificado).
- Usar variáveis CSS (`--primary-color`, etc.) para design tokens e temas.

## 📌 Funções e Métodos
- Mantenha funções pequenas e com uma única responsabilidade.
- Use early returns para evitar múltiplos níveis de aninhamento de `if`.
