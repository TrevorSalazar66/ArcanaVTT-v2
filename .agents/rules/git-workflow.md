# Convenções e Workflow Git

## 📌 Padronização de Commits (Conventional Commits)

Estrutura da mensagem de commit:
`<tipo>(<escopo>): <descrição sucinta>`

### Tipos Permitidos:
- **`feat`**: Nova funcionalidade para o usuário.
- **`fix`**: Correção de bug.
- **`docs`**: Alterações em documentação.
- **`style`**: Ajustes de formatação ou estilo sem alterar comportamento do código.
- **`refactor`**: Refatoração de código sem alterar regra de negócio ou comportamento.
- **`test`**: Adição ou ajuste de testes.
- **`chore`**: Tarefas de manutenção, atualização de dependências ou build.

### Exemplo:
```bash
git commit -m "feat(auth): adiciona fluxo de login com Google OAuth"
git commit -m "fix(worker): corrige tratamento de erro em requisições de timeout"
```
