# ArcanaVTT — Governança de Estrutura de Pastas (`estrutura-pastas.md`)

Este documento é a regra viva e restritiva de organização física do projeto em `Desenvolvimento/`.

```text
ArcanaVTT/
├── Diretrizes/                          # Somente consulta (regras, templates e metodologias)
├── task-atual.md                        # Ponto de sincronização viva da tarefa atual
├── CHANGELOG.md                         # Registro formal de versões e entregas
└── Desenvolvimento/                     # Área oficial do projeto ativo
    ├── idealizacao.md                   # Visão do produto e conceito humano
    ├── planejamento.md                  # Faseamento e arquitetura técnica
    ├── funcoes.md                       # Contratos técnicos de backend e app
    ├── estrutura-pastas.md              # Este documento de governança
    ├── tarefas.md                       # Checklist rastreável por ciclos
    ├── docs/
    │   └── historico-ciclos/            # Relatórios imutáveis de cada ciclo concluído
    ├── idealizacao/                     # Especificações detalhadas e GuiaDeEstetica (SVG/WebP)
    ├── arcana_backend/                  # Cloudflare Workers (TypeScript + D1 SQLite)
    │   ├── package.json
    │   ├── tsconfig.json
    │   ├── wrangler.toml
    │   ├── schema.sql                   # Schema D1 completo + seeds oficiais
    │   ├── migrations/                  # Migrações versionadas do D1
    │   │   └── 0001_initial_schema.sql
    │   ├── src/
    │   │   ├── index.ts                 # Entrypoint HTTP (/api/health, /api/auth, /api/sync)
    │   │   ├── types/env.ts             # Bindings e tipos de domínio Edge
    │   │   ├── utils/crypto_jwt.ts      # WebCrypto HMAC-SHA256 & SHA-256
    │   │   ├── schemas/                 # Validação Zod Fail-Fast
    │   │   ├── middlewares/             # Security Headers, Rate Limiter, Auth Zero-Trust
    │   │   ├── data/d1_repository.ts    # Repositório D1 parametrizado + Adaptador In-Memory
    │   │   └── domain/usecases/         # 1 arquivo por caso de uso (auth, campaigns, systems, etc.)
    │   └── tests/                       # Testes em 3 camadas (Unitário, Integração, E2E HTTP)
    └── arcana_app/                      # Aplicativo Mobile Android (Flutter Clean Arch 4 Camadas)
        ├── pubspec.yaml
        ├── assets/
        │   └── icons/                   # 50+ ícones vetoriais SVG oficiais (Zero Emojis)
        ├── android/                     # Projeto Android (JDK 17 + SDK 34/36 via caminho ASCII)
        ├── lib/
        │   ├── main.dart                # Ponto de entrada do app
        │   ├── core/                    # Temas (3 oficiais + escala 80-150%), RBAC Guard, SvgIcons
        │   ├── domain/                  # Entidades imutáveis e Casos de Uso puros
        │   ├── data/                    # Cliente Cloudflare Worker, Storage Local e Repositório
        │   ├── controllers/             # AppController reativo (ChangeNotifier)
        │   └── presentation/            # Widgets heráldicos, Telas (Login/Hub/4 Abas) e 20 Modais
        └── test/                        # Testes em 3 camadas (Unitários, Controllers, Widgets UI)
```

