# TASK-382 — BACKEND: `Unit` — DTOs, serviço CRUD e API

## Tipo
BACKEND

## Categoria
Pessoas e Papéis

## Prioridade
🟠 Alto

## Épico
[EPIC-039](../epics/EPIC-039.md) — Pessoas e Papéis

## QA obrigatório
Sim — criar, editar e listar unidade num ambiente real, confirmar isolamento por organização e
rejeição de número duplicado.

---

## Contexto
Expõe `Unit` (TASK-380) via API autenticada. Detalhe completo na spec de Pessoas e Papéis, seção
"API (rascunho)".

## Escopo
- `GET /organizations/units` — lista as unidades da organização autenticada.
- `POST /organizations/units` — cria.
- `PUT /organizations/units/{id}` — atualiza.
- Permissão `ADMIN`/`SYNDIC` (`403 ProblemDetail` para `TECH`/`READER`, mesmo padrão de
  `MaintenanceService`/`FinancialEntryService`).
- Payload inválido (número duplicado na organização, campos obrigatórios ausentes) lança
  `RuleException` → `400`, nunca `@Valid`/Bean Validation (mesmo motivo documentado em
  `organization-settings-module-design.md`: `GlobalExceptionHandler` mapeia Bean Validation para
  422, aqui a intenção é 400).
- Tenant scoping explícito via `TenantContext` → `OrganizationRepository.findByCode(...)` →
  `Organization.getId()`, mesmo padrão de `resident_tickets`/`settings`.

## Critérios de Aceite
- [ ] `POST` cria unidade válida e retorna `201`/corpo com `id`
- [ ] `POST` com número já existente na mesma organização retorna `400` (não 500, não cria
      duplicata)
- [ ] `PUT` em unidade de outra organização retorna `404` (nunca vaza existência cross-tenant)
- [ ] `GET` lista só as unidades da organização autenticada
- [ ] `TECH`/`READER` recebem `403` nos três endpoints
- [ ] `mvn test` sem regressão

## Dependências
TASK-380 (entidade/repositório). Desbloqueia TASK-385 (frontend da aba Unidades).

## Riscos
Baixo.

## Esforço
Pequeno

## Status
Em Validação — implementado em `feature/EPIC-039-pessoas-papeis` (api), testes verdes, aguardando push/PR e QA manual (criar/editar/listar unidade, isolamento por organização, número duplicado).
