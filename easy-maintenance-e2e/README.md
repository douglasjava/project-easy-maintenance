# Easy Maintenance — E2E Tests (Playwright)

Testes E2E para o projeto Easy Maintenance. Substitui os IT tests com TestContainers que geravam conflitos de contexto Spring.

## Pré-requisitos

- Node.js 20+
- Docker e Docker Compose

## Setup inicial

```bash
npm install
npx playwright install chromium
cp .env.e2e.example .env.e2e
# edite .env.e2e com as credenciais dos tenants de teste
```

## Rodando localmente

### 1. Suba MySQL + MailHog

```bash
docker compose -f docker-compose.yml up -d
```

### 2. Inicie a API (com perfil local apontando para porta 3307)

No projeto `easy-maintenance-api`, configure `application-local.properties` com:
```
easy.datasource.url=jdbc:mysql://localhost:3307/easy_maintenance?...
spring.mail.port=1026
```

Depois suba:
```bash
cd ../easy-maintenance-api
mvn spring-boot:run -Dspring-boot.run.profiles=local
```

### 3. Rode o smoke test

```bash
npm run test:smoke
```

### 4. Rode os testes de API

```bash
npm run test:api
```

### 5. Rode os testes de UI (requer frontend rodando)

```bash
cd ../easy-maintenance-web && npm run dev
# em outro terminal:
npm run test:ui
```

## Estrutura

```
tests/
  smoke.spec.ts         # health check básico — rode primeiro
  auth/                 # TASK-E2E-002: isolamento multi-tenant
  billing/              # TASK-E2E-003: webhook idempotência
  data/                 # TASK-E2E-004: soft delete
  frontend/             # TASK-E2E-005: React Query cache
fixtures/
  auth.ts               # loginAs(email, password) → { token, orgId }
  tenant.ts             # TENANT_A, TENANT_B credentials
  api-client.ts         # helpers api.get/post/delete com auth headers
```

## Tenants de teste

Os testes multi-tenant precisam de 2 organizações no banco antes de rodar.
Crie via endpoint de bootstrap ou SQL manual:

```sql
-- Exemplo — adaptar para o schema real
INSERT INTO organizations (id, name, code, ...) VALUES (...)
INSERT INTO users (email, password_hash, org_id, role, ...) VALUES (...)
```

## CI

```bash
npm run test:ci
# gera results/junit.xml e results/html/
```

Adicione como step no pipeline após `docker compose up -d` e o health check da API.
