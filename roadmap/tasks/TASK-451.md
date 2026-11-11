# TASK-451 — Financeiro v2: parcelas e status previsto (PLANNED)

## Tipo
FULL_STACK

## Categoria
Financeiro

## Prioridade
🟡 Médio

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
Quebra da [spec do Financeiro v2](../../docs/superpowers/specs/2026-11-11-financeiro-v2-fi05-design.md) (seção 3.5), aprovada por Douglas em 11/11/2026 ([TASK-446](TASK-446.md)).

## Escopo
- Status `PLANNED`/`CONFIRMED` no lançamento (existentes = CONFIRMED).
- Parcelado: gera N lançamentos PLANNED com `installment_group_id` e "1/N".
- Confirmar parcela (ajusta valor e data) e descartar.
- **Todas as somas filtram CONFIRMED**: `/summary`, `/summary/monthly`, prestação de contas e KPI do dashboard — teste para cada uma antes de ligar.
- Resumo mostra "Previsto no mês" à parte.

## Critérios de Aceite
- [ ] Previsto nunca entra no saldo
- [ ] Cada soma existente tem teste com lançamento PLANNED
- [ ] Confirmar e descartar auditados

## Dependências
[TASK-450](TASK-450.md)

## Riscos
Maior risco de regressão do épico: alguma soma esquecer o filtro de status.

## Status
⬜ Backlog
