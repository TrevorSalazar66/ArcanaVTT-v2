# Histórico do Ciclo 02 — Core Flutter, Design System Heráldico & Login 100% Google OAuth

## 1. Contexto de Encadeamento
- **Fase Atual:** Fase 1 (`fase-1`)
- **Subfase:** Ciclo 02 (Base Visual SVG-First, Temas e Autenticação)
- **Subfase Anterior:** Ciclo 01 (Backend Cloudflare Workers / D1)
- **Próxima Subfase:** Ciclo 03 (Hub Central, 4 Abas & 20 Modais)

## 2. O que foi Implementado
1. **Toolchain Windows/Android (`Desenvolvimento/arcana_app/`):**
   - Flutter configurado com JDK 17 Adoptium (`C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot`) e Android SDK via caminho curto ASCII 8.3 (`C:\Users\JOO~1\...`) em `android/local.properties` e `android/gradle.properties`.
   - Copiados os 50 SVGs oficiais do Guia de Estética para `assets/icons/` e adicionados vetores `menu.svg`, `google-g.svg` e `arrow-right.svg`.
2. **Design System & Segurança (`lib/core/` & `lib/presentation/widgets/`):**
   - `ArcanaColors` & `ArcanaThemeBuilder`: 3 Temas Oficiais (*Modo Escuro Heráldico*, *OLED `#000000`*, *Alto Contraste Solar*) + multiplicador dinâmico de escala tipográfica (`0.8` a `1.5`).
   - `SvgIconWidget`: Renderização 100% SVG com política Tolerância Zero a Emojis.
   - `RbacGuard`: Poda de árvore de widgets (`Widget Tree Pruning`) Zero-Trust.
3. **Tela de Login 100% Google OAuth 2.0 (`login_screen.dart`):**
   - Remoção definitiva de campos de e-mail/senha.
   - Fluxo Google OAuth 2.0 1-Tap, toggle de Dispositivo Confiável Keystore e visualização interativa dos estados Padrão, Erro (`< 16 anos`, Hardware Ban, Lockout Total) e Sucesso + Onboarding `@username`.

