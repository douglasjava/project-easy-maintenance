# TASK-448 — Financeiro v2: fundos (ordinária, reserva, obras), transferência e saldo inicial

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
Quebra da [spec do Financeiro v2](../../docs/superpowers/specs/2026-11-11-financeiro-v2-fi05-design.md) (seção 3.2, D2 e D3), aprovada por Douglas em 11/11/2026 ([TASK-446](TASK-446.md)).

## Escopo
- Enum fixo `fund` (ORDINARIA padrão, RESERVA, OBRAS) no lançamento.
- Saldo por fundo no resumo; total = soma dos fundos.
- Transferência entre fundos = par de lançamentos ligados que não altera o total.
- Saldo inicial por fundo nas configurações da organização (D3).
- Categoria `FUNDO_RESERVA` sai dos novos lançamentos; os existentes ficam como estão.

## Critérios de Aceite
- [ ] Saldo por fundo e total batem
- [ ] Transferência não infla receita nem despesa
- [ ] Saldo inicial entra no acumulado

## Dependências
[TASK-447](TASK-447.md)

## Riscos
Transferência contada como despesa no total do condomínio.

## Status
⬜ Backlog
