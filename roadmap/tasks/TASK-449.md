# TASK-449 — Financeiro v2: fornecedor e unidade no lançamento + filtro por fornecedor

## Tipo
FULL_STACK

## Categoria
Financeiro

## Prioridade
🔵 Baixo

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
Quebra da [spec do Financeiro v2](../../docs/superpowers/specs/2026-11-11-financeiro-v2-fi05-design.md) (seção 3.3 e D6), aprovada por Douglas em 11/11/2026 ([TASK-446](TASK-446.md)).

## Escopo
- `supplier_id` opcional só em despesa (fornecedores vinculados à organização).
- `unit_id` opcional só em receita (D6: agora, sem inadimplência).
- Filtro por fornecedor na lista (estende a TASK-445).

## Critérios de Aceite
- [ ] Só fornecedor e unidade da própria organização
- [ ] Fornecedor só em despesa e unidade só em receita
- [ ] Filtro por fornecedor combina com os demais

## Dependências
—

## Riscos
Vazamento entre organizações: validar o vínculo do fornecedor e da unidade com o tenant.

## Status
⬜ Backlog
