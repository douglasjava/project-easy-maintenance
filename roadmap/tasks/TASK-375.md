# TASK-375 — Backend: configuração de SLA de chamados — DTOs, serviço e API

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-038](../epics/EPIC-038.md) — Módulo de Configurações da Organização

## Depende de
[TASK-373](TASK-373.md)

## QA obrigatório
Sim — regra de permissão (ADMIN/SYNDIC) e validação de payload são o núcleo de risco desta task.

## Contexto
Desenho completo na spec/plano citados na TASK-373 (Task 3 do plano).

Enum `OrganizationSettingCategory` (`TICKETS_SLA` por ora, com `fromPathValue(String)` rejeitando
categoria desconhecida via `RuleException`, nunca 500). Record `TicketSlaSettings`
(`defaultSlaHours`, `businessHoursOnly`, `businessHours{start,end}`, `prioritySla` com chaves
exatas `LOW/MEDIUM/HIGH/CRITICAL`). `SettingsAccessGuard.requireAdminOrSyndic` (compartilhado com a
TASK-376). `OrganizationSettingsService.getSettings`/`.updateSettings`: `GET` sem linha salva
retorna os defaults do exemplo da spec com `200` (nunca `404`); `PUT` valida manualmente (não
`@Valid`/Bean Validation, que mapeia para `422` neste projeto — aqui o contrato é `400` via
`RuleException`, mesmo padrão de `FinancialEntryService.validateAmount`). Endpoints:
`GET`/`PUT /organizations/settings/{category}`.

**Prompt**: `execute a TASK-375 (EPIC-038): TICKETS_SLA settings service, controller e validação,
seguindo a Task 3 do plano docs/superpowers/plans/2026-10-29-organization-settings-module.md.`

## Critérios de aceite
- [ ] `OrganizationSettingsServiceTest`: defaults no primeiro `GET`, `PUT` rejeita `prioritySla`
      com chave extra/faltante, rejeita role fora de ADMIN/SYNDIC (`ForbiddenException`), rejeita
      categoria desconhecida em `GET` e em `PUT` (`RuleException`), salva e retorna o payload.
- [ ] `mvn test` sem regressão.

## Execução
Implementado em `feature/EPIC-038-organization-settings` (easy-maintenance-api), a partir de
`staging`. `OrganizationSettingsServiceTest` (12 testes) verde. Revisão final de branch encontrou
validação faltante em `businessHours` (formato/ordem) e cobertura de teste incompleta
(`prioritySla` malformado, upsert de linha existente) — corrigido no mesmo PR. `mvn test`
1538/1538 sem regressão. PR aberta:
[api#167](https://github.com/douglasjava/easy-maintenance-api/pull/167) (mesma PR cobre
TASK-373 a TASK-376).

## Status
Em Validação — PR aberta, aguardando QA manual de Douglas.
