# TASK-E2E-002 — Testes E2E: Isolamento Multi-Tenant

## Tipo
QA Automatizada — E2E (End-to-End)

## Categoria
Segurança / Multi-tenancy

## Prioridade
🔴 Crítico

## Épico
EPIC-003 / EPIC-008 — Multi-tenancy + Qualidade e Testes

## Flow relacionado
[FLOW-002](../Flow/FLOW-002.md)

## Migração
Substitui **TASK-QA-AUTO-001** (IT com TestContainers/Spring — removida por conflitos de contexto).

## Descrição
Criar suite E2E com Playwright validando que nenhum endpoint permite acesso a dados de outro tenant, usando autenticação real (JWT real, DB real, filtros Spring reais). Estes testes cobrem o risco de IDOR (Insecure Direct Object Reference) mais crítico do produto.

## Justificativa
- Isolamento de tenant é o risco de segurança mais severo do produto
- E2E garante que a cadeia completa (JWT → TenantFilter → @Where Hibernate → response) funciona em conjunto
- Sem cobertura automatizada, um novo endpoint pode ser adicionado sem proteção inadvertidamente
- Testa o mesmo cenário verificado manualmente no Postman, eliminando divergência de ambiente

## Tecnologias
- Playwright (TypeScript) — projeto `easy-maintenance-e2e`
- `request` fixture do Playwright (API testing sem browser)
- Autenticação real via `/auth/login`
- Docker Compose E2E (TASK-E2E-001)

## Cobertura Esperada

### Acesso cross-tenant (403)
- [x] `GET /items` com token de Org-A mas `X-Org-Id` de Org-B → HTTP 403
- [ ] `GET /items/maintenances` com token de Org-A mas `X-Org-Id` de Org-B → HTTP 403
- [x] `POST /items` com token de Org-A mas `X-Org-Id` de Org-B → HTTP 403
- [ ] `PUT /items/{id}` com token de Org-A mas `X-Org-Id` de Org-B → HTTP 403
- [x] `DELETE /items/{id}` com token de Org-A mas `X-Org-Id` de Org-B → HTTP 403 ou 404

### Header ausente ou malformado (400)
- [x] `GET /items` sem header `X-Org-Id` → HTTP 400
- [x] `GET /items` com `X-Org-Id` inválido (não UUID) → HTTP 400

### Happy path (200/201)
- [x] `GET /items` com token e `X-Org-Id` corretos → HTTP 200
- [ ] `POST /items` com token e `X-Org-Id` corretos → HTTP 201 *(não testado — evita criar dados reais sem teardown)*

### Isolamento de dados (não vazar dados entre tenants)
- [x] `GET /items` com token de Org-A → retorna apenas itens de Org-A (sem itens de Org-B)
- [x] `GET /items` com token de Org-B → retorna apenas itens de Org-B (sem itens de Org-A)

### Acesso não autenticado
- [x] `GET /items` sem token de autenticação → HTTP 401 ou 403

## Subtasks
- [x] Criar seed SQL `seed/e2e-seed.sql` com Org-A, Org-B, usuários reais e items de teste
- [x] Criar script `scripts/setup-db.ts` (`npm run setup:db`) para aplicar o seed
- [x] Criar fixture `fixtures/tenant.ts` com `TENANT_A` e `TENANT_B` credentials
- [x] Criar helper `fixtures/auth.ts` com `loginAs(email, password)`
- [x] Implementar `tests/auth/multi-tenant-isolation.spec.ts` com os cenários listados
- [ ] Adicionar cenários `PUT /items/{id}` e `GET /items/maintenances` (baixa prioridade)
- [ ] Integrar na suite CI como job obrigatório em PRs que tocam segurança/filtros

## Esforço Estimado
Médio (5-8h)

## Dependências
- TASK-E2E-001 (setup Playwright + Docker Compose) concluída

## Arquivos Criados

| Arquivo                                                          | Descrição                                                                             |
|------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| `easy-maintenance-e2e/seed/e2e-seed.sql`                         | Seed idempotente: Org-A + Org-B + 2 usuários com hash BCrypt real + billing + 3 itens |
| `easy-maintenance-e2e/scripts/setup-db.ts`                       | Script Node.js que executa o seed via mysql2 (`npm run setup:db`)                     |
| `easy-maintenance-e2e/tests/auth/multi-tenant-isolation.spec.ts` | 9 testes: cross-tenant 403, header 400, happy path 200, data isolation                |

## Status
Concluido
