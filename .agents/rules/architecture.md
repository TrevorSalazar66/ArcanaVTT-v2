# Diretrizes de Arquitetura de Software

## 🧱 Arquitetura em Camadas

### Frontend (Web / Mobile)
- **`components/`**: Componentes de interface de usuário reutilizáveis e puros (UI).
- **`pages/` ou `app/`**: Estrutura de rotas e telas da aplicação.
- **`services/`**: Camada de integração HTTP/API e comunicação externa.
- **`hooks/` / `state/`**: Lógica de estado e hooks customizados.
- **`utils/` / `helpers/`**: Funções utilitárias puras e formatações.
- **`types/`**: Definições de interfaces e tipos TypeScript.

### Backend / Edge APIs
- **`routes/` / `controllers/`**: Definição de endpoints e manipulação de requisições.
- **`services/`**: Lógica de negócios central da aplicação.
- **`models/` / `schemas/`**: Schemas de validação (ex: Zod) e entidades de banco de dados.
- **`middlewares/`**: Autenticação, validação, tratamento de erros e logs.
