# Meu Template Base (Starter Blueprint)

Este repositório serve como a **base padronizada** para desenvolvimento de todos os novos projetos, definindo metodologias, arquiteturas de pastas, convenções de código, stacks tecnológicas, regras para assistentes de IA (Antigravity IDE / Gemini) e procedimentos de deploy.

---

## 📂 Estrutura do Repositório

```text
meu-template-base/
├── .agents/                        # Configurações e personalizações para IAs (Antigravity)
│   ├── rules/                      # Regras automáticas de estilo, arquitetura e Git
│   └── skills/                     # Procedimentos e workflows reutilizáveis
├── docs/                           # Documentação de processos, stacks e infraestrutura
│   ├── stacks-e-tecnologias.md     # Definição de tecnologias por tipo de projeto
│   ├── hospedagem-e-infra.md       # Guia de infraestrutura e hospedagem
│   ├── ferramentas-externas.md     # Catálogo de ferramentas e serviços auxiliares
│   └── metodologias-e-fluxo.md     # Fluxo de trabalho (do planejamento ao deploy)
├── templates/                      # Esqueletos e boilerplates por tipo de projeto
│   ├── web-nextjs/                 # Template base para aplicações Web
│   ├── edge-cloudflare-worker/     # Template base para APIs e Workers em Edge
│   └── mobile-flutter/             # Template base para aplicações Mobile
└── GEMINI.md                       # Diretrizes globais para assistentes de IA
```

---

## 🚀 Como Usar Este Template

1. Clone ou utilize este repositório como base para novos projetos.
2. Siga as orientações definidas na pasta `docs/`.
3. Os assistentes de IA lerão automaticamente as regras contidas em `.agents/` e `GEMINI.md`.
