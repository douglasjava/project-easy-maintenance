# TASK-E2E-004 — Testes E2E: Soft Delete e Filtro Automático de Listagens

## Tipo
QA Automatizada — E2E (End-to-End)

## Categoria
Banco de Dados / Compliance / Backend

## Prioridade
🟡 Médio

## Épico
EPIC-004 / EPIC-008 — Banco de Dados + Qualidade e Testes

## Flow relacionado
[FLOW-009](../Flow/FLOW-009.md)

## Migração
Substitui **TASK-QA-AUTO-005** (IT com TestContainers/Spring — pendente, não iniciada).

## Descrição
Criar testes E2E verificando que:
1. A deleção de entidades críticas via API preenche `deleted_at` (não remove o registro físico)
2. Registros deletados não aparecem nas listagens da API subsequentes
3. O filtro `@Where` do Hibernate está ativo — detectável via comparação entre a contagem da API e a contagem SQL raw

O filtro `@Where` é transparente ao código e só é testável com banco real. E2E é a abordagem correta: DELETE via API → GET verifica ausência → evidência de conformidade.

## Justificativa
- Soft delete é requisito de compliance — regressão causaria perda de dados de clientes sem alerta visível
- `@Where` do Hibernate pode ser removido acidentalmente em merge/rebase sem erro de compilação
- E2E com DB real é a única forma de verificar que o filtro está ativo de ponta a ponta

## Tecnologias
- Playwright (TypeScript) — `request` fixture (API testing sem browser)
- Docker Compose E2E com MySQL real
- Endpoint de verificação de contagem (ou query direta via endpoint de admin/actuator)

## Cobertura Esperada

### Soft delete correto (não remove fisicamente)
- [ ] `DELETE /items/{id}` → HTTP 200/204
- [ ] `GET /items/{id}` após deleção → HTTP 404 (filtrado pela API)
- [ ] Verificação: item AINDA existe no banco com `deleted_at IS NOT NULL` (via endpoint de auditoria ou contagem SQL)
- [ ] `DELETE /maintenances/{id}` → mesmo comportamento
- [ ] `DELETE /users/{id}` → mesmo comportamento

### Filtro automático de listagem
- [ ] Criar 3 itens → deletar 1 → `GET /items` retorna exatamente 2 itens
- [ ] Item deletado não aparece em nenhuma página da listagem paginada
- [ ] Contagem da API (`total`) = contagem SQL com `WHERE deleted_at IS NULL`

### Integridade histórica
- [ ] Deletar item que tem manutenções associadas → `GET /items/{id}/maintenances` retorna 404 (item deletado) mas manutenções permanecem visíveis via outros endpoints de histórico (se existirem)
- [ ] Manutenções do item deletado ainda existem no banco (soft delete não cascadeia fisicamente)

## Subtasks
- [ ] Criar fixture `items.ts` com `createItem()`, `createMaintenance()` para setup de dados
- [ ] Implementar `tests/data/soft-delete.spec.ts` com os cenários listados
- [ ] Criar helper `getDbCount(table, where)` via endpoint de admin ou query parametrizada para verificar contagem raw
- [ ] Garantir isolamento de dados entre testes (cada test suite usa prefixo único nos nomes)
- [ ] Integrar na suite CI como parte dos testes de integridade de dados

## Esforço Estimado
Médio (5-7h)

## Dependências
- TASK-E2E-001 (setup Playwright + Docker Compose) concluída
- Fixture de autenticação de TASK-E2E-002 disponível

## Status
Pendente
