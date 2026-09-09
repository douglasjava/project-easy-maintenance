# TASK-249 — FRONTEND: Shell do dashboard (layout, filtros, máquina de estado)

## Tipo
FRONTEND

## Categoria
Dashboard / Compliance

## Prioridade
🔴 Crítico

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Sim — confirmar que trocar filtro atualiza a URL e refaz as duas chamadas, que voltar/avançar do
navegador funciona, e que os banners de trial/bloqueio/atraso continuam aparecendo.

---

## Contexto

Renumerada de TASK-133 do documento original. Reconstrói `app/dashboard` como um shell que lê
`state` de `/dashboard/summary` e renderiza `ONBOARDING`/`OPERATING`/`PORTFOLIO`.

**Não é uma tela nova — é a reescrita de `src/app/page.tsx` (116 linhas) e de tudo que ele já
orquestra.** A tela atual não é só 4 contadores; ela já resolve estados reais que este task precisa
preservar ou reintegrar deliberadamente:
- `PrivateRoute`, `DashboardLoadingState`, `DashboardNoOrganizationState`,
  `DashboardAccessDeniedState`, `DashboardErrorState`
- `DashboardBlockedBanner` (conta bloqueada), `PastDueBanner` (pagamento atrasado), `TrialBanner`
  (trial ativo/expirado)
- `OnboardingChecklist` e `GuidedTour` — **já existe uma versão do conceito "conta nova" hoje**,
  não é greenfield puro (ver TASK-253)

## Escopo

- Reconstruir `app/dashboard` como shell orientado por `state` (nunca re-derivado no cliente).
- Barra de filtro: empresa (com "Todas as unidades (n)" quando multi-empresa), período, categoria
  — como query params de URL.
- Remover a fileira "Acesso rápido" (duplica a sidebar); mover "Registrar manutenção"/"Exportar
  PDF" pra barra de filtro.
- Container `max-width: 1320px`.

## Critérios de Aceite

- [ ] Trocar filtro atualiza a URL e refaz as duas chamadas (summary + series); voltar/avançar
      funciona
- [ ] Loading é skeleton com a geometria do layout final, não spinner nem pulo de layout
- [ ] Nenhuma re-derivação de `state` no cliente
- [ ] Banners existentes (trial/bloqueio/atraso) continuam funcionando

## Viabilidade Técnica

**O que muda de verdade:**
- A rota atual do dashboard é `src/app/page.tsx` (raiz), não `app/dashboard` — o documento
  original assume um path que não é o real neste projeto. Confirmar com Douglas se a intenção é
  manter a URL raiz (mais provável, já que é a home autenticada) ou migrar de fato pra `/dashboard`
  (mudaria o link "Dashboard" usado em várias telas, ex. `src/app/items/page.tsx` usa `href={backHref}`
  apontando pra `/`).
- "Todas as unidades (n)": **não existe hoje um seletor de organização com modo "todas"** — o
  app inteiro opera com uma organização ativa por vez (`X-Org-Id`, salvo em
  `localStorage`/`sessionStorage` como `organizationCode`). Esse componente é novo de verdade, não
  uma variação de algo existente.
- Filtros como query params: não é um padrão novo pro projeto — `src/app/items/page.tsx` já faz
  isso parcialmente (`useSearchParams`), pode servir de referência de implementação.

**Precisa de decisão explícita antes de codar:**
- O que acontece com `/easy-maintenance/api/v1/dashboard` (endpoint atual) durante a transição?
  Duas opções: (a) big-bang — troca tudo numa PR só, endpoint antigo é removido junto; (b)
  convivência temporária. O documento original não trata disso porque não sabia que o endpoint já
  existia.

## Dependências
TASK-246 (precisa do campo `state` no `/dashboard/summary`).

## Riscos
Médio-alto — é o task que decide se a migração é big-bang ou incremental, e é o único ponto que
toca todos os banners/estados de conta já existentes. Bloqueia TASK-250/251/252/253.

## Esforço
Grande.

## Status
🔴 Não iniciada — bloqueada por TASK-246.
