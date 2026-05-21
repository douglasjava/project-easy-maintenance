# TASK-QA-AUTO-001 — Testes de Integração: Isolamento Multi-Tenant via MockMvc

## Tipo
QA Automatizada — Integração (API)

## Categoria
Segurança / Multi-tenancy / Backend

## Prioridade
🔴 Crítico

## Épico
EPIC-003 / EPIC-008 — Multi-tenancy + Qualidade e Testes

## Flow relacionado
[FLOW-002](../Flow/FLOW-002.md)

## Descrição
Criar suite de testes de integração com MockMvc + TestContainers (MySQL) cobrindo os cenários de acesso cross-tenant via header `X-Org-Id` manipulado. Garantir que nenhum endpoint existente permite acesso a dados de outro tenant.

Esta task é **pré-requisito para fechar TASK-026** (testes de integração billing e auth completos) e deve ser desenvolvida nessa sprint.

## Justificativa para Automatização
- Isolamento de tenant é o risco de segurança mais severo do produto
- Novos endpoints criados no futuro podem ser adicionados sem proteção inadvertidamente
- Testes manuais de IDOR são realizados apenas pontualmente — automação garante regressão contínua
- Sem cobertura automatizada, um deploy pode introduzir IDOR silenciosamente

## Tecnologias
- JUnit 5
- MockMvc (Spring Boot Test)
- TestContainers (MySQL 8.0) com `@ServiceConnection`
- `@SpringBootTest(webEnvironment = MOCK)` + `@AutoConfigureMockMvc`

## Cobertura Esperada

### Cenários de isolamento (403)
- [x] `GET /items` com X-Org-Id de outra org → HTTP 403
- [x] `GET /items/maintenances` com X-Org-Id de outra org → HTTP 403
- [x] `POST /items` com X-Org-Id de outra org → HTTP 403
- [x] `DELETE /items/{id}` com X-Org-Id de outra org → HTTP 403
- [x] `PUT /items/{id}` com X-Org-Id de outra org → HTTP 403

### Header malformado (400)
- [x] `GET /items` sem header X-Org-Id → HTTP 400
- [x] `GET /items` com X-Org-Id inválido (não UUID) → HTTP 400

### Regressão (200/201)
- [x] `GET /items` com X-Org-Id correto → HTTP 200
- [x] `GET /items/maintenances` com X-Org-Id correto → HTTP 200
- [x] `POST /items` com X-Org-Id correto e assinatura ativa → HTTP 201

### Filtro de repositório / isolamento de dados
- [x] GET /items retorna apenas registros do tenant ativo (`IT_ITEM_ORG_A` sem `IT_ITEM_ORG_B`)
- [x] GET /items com token org-b não retorna dados de org-a

### Acesso não autenticado
- [x] `GET /items` sem token → HTTP 401/403/400
- [x] `GET /items` com token inválido → HTTP 400/401/403

## Subtasks
- [x] Configurar TestContainers com MySQL para o módulo de segurança
- [x] Criar fixture de 2 organizações com usuários e dados separados (`it-seed.sql`)
- [x] Implementar helper para gerar JWT de teste para cada organização (`buildToken()`)
- [x] Criar classe `MultiTenantIsolationIT` com os cenários listados
- [ ] Integrar na suite de CI (deve rodar em todo pull request)

## Arquivos Criados / Modificados

| Arquivo                                                      | Operação                                                                                                   |
|--------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|
| `pom.xml`                                                    | Adicionado BOM TestContainers 1.20.4 + deps `junit-jupiter` e `mysql`                                      |
| `src/test/resources/application-integration-test.properties` | Criado — profile `integration-test` com JWT secret, Flyway habilitado, serviços externos stubados          |
| `src/test/resources/db/it-seed.sql`                          | Criado — seed de 2 orgs, billing plan `IT_FREE`, assinatura ativa para org-a, 2 items org-a + 1 item org-b |
| `src/test/java/.../security/MultiTenantIsolationIT.java`     | Criado — 14 testes em 5 grupos `@Nested`                                                                   |

## Esforço Estimado
Médio (8-12h) — incluindo configuração do TestContainers se não existir

## Dependências
- TestContainers já configurado (TASK-026 deve configurar — coordenar)
- Estrutura de autenticação de teste disponível

## Status
Substituída por E2E — ver [TASK-E2E-002](TASK-E2E-002.md)

O teste foi removido por conflitos de contexto Spring (cenários que funcionam no Postman falhavam no código de teste). A cobertura foi migrada para Playwright E2E no projeto `easy-maintenance-e2e`, que testa a cadeia completa sem conflitos de contexto.
