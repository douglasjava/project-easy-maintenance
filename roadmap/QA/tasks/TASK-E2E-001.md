# TASK-E2E-001 — Setup do Projeto Playwright E2E

## Tipo
QA Automatizada — E2E (End-to-End)

## Categoria
Infraestrutura de Testes / Setup

## Prioridade
🟠 Alto

## Épico
EPIC-008 — Qualidade e Testes

## Descrição
Criar o projeto `easy-maintenance-e2e` com Playwright configurado para testar a aplicação Easy Maintenance de ponta a ponta. 
Este projeto é o prerequisito para todas as tasks TASK-E2E-002 a 005 e substitui a abordagem de IT tests com TestContainers que gerava conflitos de contexto Spring.

## Justificativa
- IT tests com `@SpringBootTest + TestContainers` causam conflitos de contexto Spring que não ocorrem em Postman
- Playwright E2E testa o sistema real (sem mocks de contexto Spring), eliminando a classe de falso-positivo/falso-negativo
- Projeto separado evita poluir o repositório backend com dependências Node/browser
- Playwright tem suporte nativo a API testing (`request` fixture) — não precisa de browser para testes de API pura

## Tecnologias
- Playwright (TypeScript)
- Docker Compose (API + MySQL + MailHog)
- Node.js 20+

## Estrutura do Projeto

```
easy-maintenance-e2e/
├── playwright.config.ts
├── docker-compose.e2e.yml
├── package.json
├── tsconfig.json
├── fixtures/
│   ├── auth.ts           # login helpers, geração de tokens
│   ├── tenant.ts         # setup/teardown de orgs de teste
│   └── api-client.ts     # wrapper para APIRequestContext
├── tests/
│   ├── auth/             # multi-tenant isolation (TASK-E2E-002)
│   ├── billing/          # webhook idempotency (TASK-E2E-003)
│   ├── data/             # soft delete (TASK-E2E-004)
│   └── frontend/         # React Query cache (TASK-E2E-005)
└── helpers/
    └── db.ts             # queries diretas para verificação de estado (via API ou endpoint de admin)
```

## Cobertura Esperada (setup)

- [ ] `playwright.config.ts` configurado com `baseURL`, `timeout`, projetos `api` (sem browser) e `ui` (browser)
- [ ] `docker-compose.e2e.yml` com serviços: `api`, `mysql`, `mailhog`; health checks; `depends_on`
- [ ] Fixture `auth.ts` com `loginAs(email, password)` retornando `{ token, orgId }`
- [ ] Fixture `tenant.ts` com `createTestOrg()` e `cleanupTestData()` para isolamento entre testes
- [ ] Script `package.json`: `test:api` (headless, API only), `test:ui` (com browser), `test:ci` (report JUnit)
- [ ] README com instruções de `docker compose up` + `npm run test:api`
- [ ] `.env.e2e.example` com variáveis necessárias (`BASE_URL`, `DB_PASSWORD`, etc.)

## Subtasks

- [x] Criar repositório/diretório `easy-maintenance-e2e`
- [x] Inicializar projeto Playwright com `package.json` + `npm install`
- [x] Configurar `playwright.config.ts` com projetos `api` e `ui`
- [x] Criar `docker-compose.e2e.yml` baseado no `docker-compose.yml` existente
- [x] Implementar fixture `auth.ts` com login real via API
- [x] Implementar fixture `tenant.ts` para credenciais dos tenants de teste
- [x] Implementar fixture `api-client.ts` com helpers de request autenticados
- [x] Criar smoke test (`tests/smoke.spec.ts`: health check + login 401)
- [x] Criar `.env.e2e.example` com variáveis necessárias
- [x] Documentar no README como rodar localmente e em CI
- [ ] Instalar browsers Playwright no CI (`npx playwright install chromium`)
- [ ] Criar seed SQL para tenants de teste (TENANT_A e TENANT_B) — pré-requisito para TASK-E2E-002

## Esforço Estimado
Médio (4-6h)

## Dependências
- `docker-compose.yml` existente no projeto como base
- API rodando corretamente com o profile de teste

## Arquivos Criados

| Arquivo | Descrição |
|---------|-----------|
| `easy-maintenance-e2e/package.json` | Dependências: `@playwright/test`, `dotenv`, `typescript` |
| `easy-maintenance-e2e/playwright.config.ts` | Projetos `api` (headless) e `ui` (Chromium); lê `.env.e2e` |
| `easy-maintenance-e2e/tsconfig.json` | TypeScript strict — compila sem erros |
| `easy-maintenance-e2e/docker-compose.e2e.yml` | MySQL:3307 + MailHog:1026/8026 |
| `easy-maintenance-e2e/fixtures/auth.ts` | `loginAs(email, password) → LoginResult` |
| `easy-maintenance-e2e/fixtures/tenant.ts` | `TENANT_A`, `TENANT_B` lidos de `.env.e2e` |
| `easy-maintenance-e2e/fixtures/api-client.ts` | `api.get/post/put/delete/getAs/postAs` com auth headers |
| `easy-maintenance-e2e/tests/smoke.spec.ts` | `GET /actuator/health → UP` + `POST /auth/login → 401` |
| `easy-maintenance-e2e/.env.e2e.example` | Template de variáveis de ambiente |
| `easy-maintenance-e2e/.gitignore` | Ignora `node_modules`, `results`, `.env.e2e` |
| `easy-maintenance-e2e/README.md` | Instruções de setup local e CI |

## Status
Concluido — projeto criado, TypeScript compila, smoke test pronto; aguarda execução contra API real
