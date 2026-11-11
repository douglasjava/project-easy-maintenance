# TASK-452 — Financeiro v2: recorrência mensal (regra, job diário, confirmar ou descartar)

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
Quebra da [spec do Financeiro v2](../../docs/superpowers/specs/2026-11-11-financeiro-v2-fi05-design.md) (seção 3.5 e D4), aprovada por Douglas em 11/11/2026 ([TASK-446](TASK-446.md)).

## Escopo
- Tabela `financial_recurrences` (dia, valor, categoria, fundo, fornecedor).
- "Repetir todo mês" no formulário cria a regra.
- Job diário gera o lançamento do mês como PLANNED (D4), idempotente.
- Encerrar a regra não apaga os confirmados.

## Critérios de Aceite
- [ ] Job não gera duplicado no mesmo mês
- [ ] Previsto aguarda confirmação
- [ ] Encerrar regra preserva o histórico

## Dependências
[TASK-451](TASK-451.md)

## Riscos
Job rodando duas vezes (idempotência por regra + mês).

## Status
⬜ Backlog
