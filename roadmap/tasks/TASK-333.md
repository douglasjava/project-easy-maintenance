# TASK-333 — Painel de conformidade liberado desde o 1º item

## Tipo
FRONTEND

## Prioridade
🟠 Alto

## Épico
[EPIC-033](../epics/EPIC-033.md) — Prova de manutenção (reposicionamento: evidência, relatório e North Star) · **Fase 0**

## Depende de
—

## QA obrigatório
Sim.

## Contexto
Hoje o painel só libera com 5 itens (`OnboardingPanel.tsx:20`), o que atrasa o primeiro valor percebido.
Base: `staging` · branch `feature/TASK-333-<descricao-curta>`.

## Escopo
- Mostrar o painel parcial a partir de 1 item, com o checklist de primeiros passos ao lado.
- Estado vazio claro para 0 itens.
- Mobile.

## Critérios de aceite
- [ ] Com 1 item o índice e a lista de vencimentos aparecem
- [ ] 0 itens mostra o estado vazio com CTA
- [ ] Sem regressão no checklist de onboarding

## Status
Backlog
