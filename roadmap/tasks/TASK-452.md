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
- [x] Job não gera duplicado no mesmo mês
- [x] Previsto aguarda confirmação
- [x] Encerrar regra preserva o histórico

## Dependências
[TASK-451](TASK-451.md)

## Riscos
Job rodando duas vezes (idempotência por regra + mês).

## Implementação (11/11/2026)
[api#227](https://github.com/douglasjava/easy-maintenance-api/pull/227) e [web#160](https://github.com/douglasjava/easy-maintenance-web/pull/160), mergeadas em `staging`.
- A migração V158 cria a tabela `financial_recurrences` e a coluna `recurrence_id`, com `UNIQUE (recurrence_id, competence)`. ⚠️ Ainda não foi executada num MySQL.
- `POST /finance/recurrences` valida como um lançamento comum, aceita dia de 1 a 31 (vira o último dia nos meses curtos) e recusa mês inicial passado. Já gera o previsto do mês atual. `GET` lista as regras e `POST /{id}/end` encerra sem apagar nada.
- `FinancialRecurrenceJob` roda todo dia às 03:15, com ShedLock e health, e gera o PLANNED do mês com transação própria por regra. É idempotente: um mês descartado não volta a ser gerado.
- Web: opção "Repetir todo mês" no formulário (a regra começa no mês seguinte), modal "Recorrentes" com Encerrar e selo "Recorrente" na lista.

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
