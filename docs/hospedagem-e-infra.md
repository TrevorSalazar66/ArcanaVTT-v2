# Guia de Hospedagem & Infraestrutura

Matriz de decisão para escolha de hospedagem conforme a natureza do projeto.

---

## 🌐 1. Cloudflare (Workers / Pages)
- **Melhor para:** APIs serverless de alta velocidade (Edge), sites estáticos, microserviços leves e Workers.
- **Vantagens:** Latência global extremamente baixa, plano gratuito generoso, proteção DDoS nativa.

## 🚀 2. Vercel
- **Melhor para:** Aplicações SSR/SSG em Next.js e frontends React complexos.
- **Vantagens:** Integração nativa com Next.js, preview deployments automáticos por PR.

## 🗄️ 3. Supabase / Firebase
- **Melhor para:** BaaS (Backend as a Service), autenticação rápida, banco de dados gerenciado e armazenamentos de mídia (Storage).
