# Histórico do Ciclo 04 — Testes em 3 Camadas, APK Release & Entrega GitHub

## 1. Contexto de Encadeamento
- **Fase Atual:** Fase 1 (`fase-1`)
- **Subfase:** Ciclo 04 (Validação Sistêmica, Build APK Release & Publicação Git)
- **Subfase Anterior:** Ciclo 03 (Hub Central, 4 Abas & 20 Modais Interativos)
- **Próxima Subfase:** Fase 2 (Tabuleiro Tático P2P WebRTC em Tempo Real)

## 2. Resultados das Verificações Executadas
1. **Backend Serverless (`Desenvolvimento/arcana_backend/`):**
   - `npm run typecheck` (`tsc --noEmit`): 0 erros.
   - `npm test` (`vitest run`): 3 arquivos, **10/10 testes aprovados** (Camada 1 Unitário, Camada 2 Integração/RBAC/Lockout/Compêndio, Camada 3 E2E HTTP Worker).
   - `npx wrangler deploy --dry-run`: empacotamento validado (`262.20 KiB / gzip: 54.42 KiB`, binding D1 `arcana_vtt_db`).
2. **Aplicativo Mobile Flutter (`Desenvolvimento/arcana_app/`):**
   - `dart analyze`: **No issues found!** (0 erros, 0 avisos).
   - `flutter test`: **9/9 testes aprovados** em 3 camadas (Unitário 3d6/Compêndio/Autotags/RBAC, Integração Controller OAuth/Lockout/Temas/Chat, UI/Widget Login OAuth + Navegação 4 Abas + Widget Tree Pruning no Drawer + Chat WhatsApp+Discord com 3d6).
3. **Empacotamento APK Release Android:**
   - Gerado com sucesso em `Desenvolvimento/arcana_app/build/app/outputs/flutter-apk/app-release.apk` (**52.4 MB**) e disponibilizado localmente em `Desenvolvimento/releases/arcana_vtt_v0.1.0_fase1.apk` (ignorado pelo `.gitignore`).

## 3. Erro Encontrado no Build AOT & Solução Aplicada
- **Erro:** O binário nativo C++ `gen_snapshot.exe` do Dart AOT falhava no Windows com exit code `255` ao ler `.dart_tool/.../app.dill` devido ao caractere não-ASCII `ã` em `C:\Users\João\...`.
- **Solução Definitiva:** Execução do build dentro da unidade virtual ASCII temporária via `subst W: $env:USERPROFILE` (com `PUB_CACHE`, `GRADLE_USER_HOME` e `android/local.properties` apontando para `W:\`), permitindo que Gradle e CMake compilassem todas as arquiteturas (`arm`, `arm64`, `x64`) perfeitamente.

## 4. Alerta para Próximas Fases
- Ao gerar novos APKs em máquinas Windows cuja pasta de usuário contenha acentos, sempre executar o `flutter build apk --release` mapeando o diretório para unidade ASCII (`subst W:`).
- Antes de publicar o Worker na Cloudflare em produção, executar `npx wrangler d1 create arcana_vtt_db`, atualizar o `database_id` em `wrangler.toml`, aplicar `npm run db:migrate:remote` e cadastrar `JWT_SECRET`, `GOOGLE_CLIENT_ID` e `RESEND_API_KEY`.
