---
name: deploy-guide
description: Skill de procedimentos e verificações para publicação e deploy de aplicações.
---

# Checklist de Pré-Deploy

Antes de realizar qualquer deploy de aplicação para produção, execute a seguinte verificação:

1. **Análise Estática & Linter:** Garanta que não existam erros de compilação ou linter (`npm run build` ou `npx tsc --noEmit`).
2. **Variáveis de Ambiente:** Verifique se todas as chaves secretas necessárias estão cadastradas na plataforma de hospedagem alvo.
3. **Erros de Console:** Certifique-se de que nenhum `console.log` desnecessário esteja presente.
4. **Deploy Command:** Execute o comando correspondente ao serviço escolhido (ex: `npx wrangler deploy` para Cloudflare Workers ou `vercel --prod`).
