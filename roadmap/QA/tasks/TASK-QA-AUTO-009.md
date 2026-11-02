# TASK-QA-AUTO-009 — Testes de integração: matriz `role`/`role_detail` e isolamento multi-tenant de `Unit`/`CondoPerson`

## Tipo
QA Automatizada — Integração (`easy-maintenance-api`, `@SpringBootTest`/`MockMvc`, mesmo padrão de
TASK-QA-AUTO-001)

## Categoria
Backend / Pessoas e Papéis

## Prioridade
🟠 Alto — **Now** (antes de promover `staging` → `main`)

## Épico
EPIC-039 (origem: TASK-382, TASK-383)

## Descrição
1. **Matriz `role`/`role_detail`**: um teste parametrizado cobrindo todas as combinações válidas
   (Síndico: Profissional/Morador/Morador remunerado; Conselheiro: Fiscal/Consultivo; Morador:
   Proprietário/Inquilino; Fornecedor: Recorrente/Avulso; Subsíndico/Zelador/Administradora/
   Construtora: sem detalhe) e um conjunto de combinações inválidas (ex. `role=MORADOR` +
   `role_detail="FISCAL"`, `role=ZELADOR` + qualquer detalhe não nulo) — esperado `400` via
   `RuleException`, nunca `422` (Bean Validation) nem `500`.
2. **Vínculo `supplier_id`**: `role=FORNECEDOR` sem `supplier_id` → 400; com `supplier_id` de outra
   organização → 400; `role≠FORNECEDOR` com `supplier_id` preenchido → 400; `role=FORNECEDOR` com
   `supplier_id` válido da mesma organização → 201.
3. **Isolamento multi-tenant** (`GET`/`POST`/`PUT`/`DELETE` em `/organizations/units` e
   `/organizations/condo-people`): `X-Org-Id` de outra organização → 403; `PUT`/`DELETE` em
   registro de outra organização → 404 (nunca vaza existência cross-tenant); `GET` só retorna
   registros da organização autenticada.
4. **Permissão**: `TECH`/`READER` → 403 em todos os endpoints de ambos os recursos.
5. **Constraint única de `Unit`**: `number` duplicado na mesma organização → 400 via banco
   (`DataIntegrityViolationException` capturada); mesmo número em organizações diferentes → 201 nas
   duas.
6. **Soft delete**: `DELETE /organizations/condo-people/{id}` muda `status` para `INATIVO`;
   registro continua recuperável via `GET` sem filtro, nunca removido fisicamente.

## Justificativa para Automatização
- Módulo novo sem nenhuma cobertura de integração HTTP ainda — hoje só tem testes unitários de
  serviço (Mockito, conforme TASK-382/383) e QA manual pontual (TASK-QA-MAN-027).
- A matriz `role`/`role_detail` tem 8 papéis e múltiplos detalhes válidos por papel — alto risco de
  regressão silenciosa se alguém adicionar um papel novo ou alterar o mapa sem repetir toda a QA
  manual.
- Isolamento multi-tenant é sempre launch-critical (ver FLOW-002) e o módulo expõe 7 endpoints
  novos sem nenhuma proteção automática além do que já existe em `TenantFilterInterceptor`.
- A constraint única de `Unit` e o soft delete de `CondoPerson` são comportamento de banco fácil de
  quebrar numa migration futura sem teste de regressão.

## Cobertura Esperada
- ~12 combinações da matriz `role`/`role_detail` (parametrizado).
- 4 cenários de `supplier_id`.
- 6+ cenários de isolamento multi-tenant (403/404) nos dois recursos.
- 4 cenários de permissão (`TECH`/`READER` × `Unit`/`CondoPerson`).
- 2 cenários de constraint única.
- 1 cenário de soft delete.

## Status
Backlog
