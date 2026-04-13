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
- TestContainers (MySQL)
- `@SpringBootTest(webEnvironment = RANDOM_PORT)`

## Cobertura Esperada

### Cenários de isolamento (403)
- [ ] `GET /items` com X-Org-Id de outra org → HTTP 403
- [ ] `GET /maintenances` com X-Org-Id de outra org → HTTP 403
- [ ] `GET /users` com X-Org-Id de outra org → HTTP 403
- [ ] `POST /items` com X-Org-Id de outra org → HTTP 403
- [ ] `DELETE /items/{id}` com X-Org-Id de outra org → HTTP 403

### Regressão (200)
- [ ] `GET /items` com X-Org-Id correto → HTTP 200 com dados do tenant correto
- [ ] `POST /items` com X-Org-Id correto → HTTP 201

### Filtro de repositório
- [ ] Query JPA sem TenantContext ativo → lança exceção fail-fast (TASK-017)
- [ ] GET /items retorna apenas registros do tenant ativo (contagem SQL = contagem API)

## Subtasks
- [ ] Configurar TestContainers com MySQL para o módulo de segurança
- [ ] Criar fixture de 2 organizações com usuários e dados separados
- [ ] Implementar helper para gerar JWT de teste para cada organização
- [ ] Criar classe `MultiTenantIsolationIT` com os cenários listados
- [ ] Integrar na suite de CI (deve rodar em todo pull request)

## Esforço Estimado
Médio (8-12h) — incluindo configuração do TestContainers se não existir

## Dependências
- TestContainers já configurado (TASK-026 deve configurar — coordenar)
- Estrutura de autenticação de teste disponível

## Status
Pendente — prioridade para SPRINT-03 (junto com TASK-026)
