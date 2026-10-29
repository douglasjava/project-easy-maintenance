# TASK-377 — Frontend: página `/configuracoes` + aba de SLA de Chamados

## Tipo
FRONTEND

## Prioridade
🟠 Alto

## Épico
[EPIC-038](../epics/EPIC-038.md) — Módulo de Configurações da Organização

## Depende de
[TASK-375](TASK-375.md)

## QA obrigatório
Sim — tela nova, precisa validar manualmente contra API real (carregar defaults, editar, salvar,
persistir após reload).

## Contexto
Desenho completo na spec/plano citados na TASK-373 (Task 5 do plano).

Rota nova `/configuracoes` (não dentro de `/profile` — decisão explícita do Douglas, pensando no
módulo crescer). Abas por state local (`activeTab`), sem sub-rota por aba, mesmo molde do
segmented-control já usado em `reports/page.tsx` — **não** usar `AdminTabs.tsx` (esse componente é
route-based no único uso real, `BillingAdminLayout.tsx`, o que exigiria sub-rotas sem necessidade
aqui). Guard de role ADMIN/SYNDIC igual ao de `financeiro/page.tsx`. Aba "SLA de Chamados"
(`SlaSettingsTab.tsx`): formulário ligado a `GET`/`PUT /organizations/settings/TICKETS_SLA`
(TASK-375), usando `api` de `@/lib/apiClient` e `mapError`/`toast` no mesmo padrão de
`financeiro/page.tsx`.

**Prompt**: `execute a TASK-377 (EPIC-038): página /configuracoes com aba de SLA, seguindo a
Task 5 do plano docs/superpowers/plans/2026-10-29-organization-settings-module.md.`

## Critérios de aceite
- [ ] `npx tsc --noEmit` e `npm run build` limpos, `/configuracoes` listada como rota.
- [ ] QA manual: logado como ADMIN/SYNDIC, aba de SLA carrega os defaults, edição salva e
      persiste depois de recarregar a página.

## Execução
Implementado em `feature/EPIC-038-organization-settings` (easy-maintenance-web), a partir de
`staging`. `npx tsc --noEmit`/`npm run build` limpos, `/configuracoes` presente nas rotas. Sem
teste automatizado de UI (não há runner de teste de componente neste módulo). PR aberta:
[web#120](https://github.com/douglasjava/easy-maintenance-web/pull/120) (mesma PR cobre
TASK-377 a TASK-379).

## Status
Em Validação — PR aberta, QA manual contra backend real ainda pendente (Douglas).
