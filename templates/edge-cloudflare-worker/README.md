# Template Edge API / Cloudflare Worker

Esqueleto base para APIs serverless de alta velocidade e workers.

## Estrutura Recomendada
- `src/index.ts`: Ponto de entrada do worker.
- `src/routes/`: Endpoints e roteamento HTTP (Hono.js).
- `src/services/`: Lógica de negócios.
- `wrangler.toml`: Configuração do Cloudflare Workers.
