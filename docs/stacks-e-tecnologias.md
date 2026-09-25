# Stacks & Tecnologias Padrão

Este documento detalha as stacks tecnológicas recomendadas para cada tipo de projeto no nosso ecossistema de desenvolvimento.

---

## 💻 1. Aplicações Web Frontend
- **Framework Principal:** Next.js (App Router) ou Vite (React / Vanilla JS)
- **Linguagem:** TypeScript
- **Estilização:** Vanilla CSS moderno / CSS Modules / TailwindCSS
- **Gerenciamento de Estado:** Zustand / React Context API

---

## ⚡ 2. APIs Serverless & Edge
- **Ambiente de Execução:** Cloudflare Workers / Node.js
- **Framework HTTP:** Hono.js / Fastify
- **Validação de Schemas:** Zod
- **Banco de Dados:** Cloudflare D1 / Supabase (PostgreSQL) / Prisma ORM

---

## 📱 3. Aplicações Mobile
- **Framework Principal:** Flutter
- **Linguagem:** Dart
- **Arquitetura:** Layered Architecture (UI, Logic, Data)
