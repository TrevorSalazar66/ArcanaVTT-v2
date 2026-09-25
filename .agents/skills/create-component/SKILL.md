---
name: create-component
description: Skill para criação de componentes de interface de usuário seguindo o padrão de design e arquitetura do repositório.
---

# Procedimento para Criação de Componentes UI

Quando instruído a criar um novo componente UI, siga os seguintes passos:

1. **Localização do Arquivo:**
   - Coloque o componente dentro do diretório `src/components/<nome-do-componente>/`.

2. **Estrutura de Arquivos do Componente:**
   - `index.ts`: Re-exportação do componente.
   - `<NomeDoComponente>.tsx`: Código principal do componente.
   - `<NomeDoComponente>.css` ou `<NomeDoComponente>.module.css`: Estilização dedicada.

3. **Diretrizes de Implementação:**
   - Crie a interface de props com nome `interface <NomeDoComponente>Props`.
   - Adicione suporte a acessibilidade (A11y), incluindo estados de foco e atributos ARIA quando necessário.
   - Utilize variáveis CSS do sistema de design.
