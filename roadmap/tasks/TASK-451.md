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
- [x] Previsto nunca entra no saldo
- [x] Cada soma existente tem teste com lançamento PLANNED
- [x] Confirmar e descartar auditados

## Dependências
[TASK-450](TASK-450.md)

## Riscos
Maior risco de regressão do épico: alguma soma esquecer o filtro de status.

## Implementação (11/11/2026)
[api#226](https://github.com/douglasjava/easy-maintenance-api/pull/226) e [web#159](https://github.com/douglasjava/easy-maintenance-web/pull/159), mergeadas em `staging`.
- A migração V157 cria `status` (CONFIRMED padrão, PLANNED) e as colunas da parcela (grupo, número e total). ⚠️ Ainda não foi executada num MySQL.
- As 6 somas do repository contam só CONFIRMED. Elas alimentam `/summary`, as duas visões de `/summary/monthly`, os dois cálculos de `/funds` e o resumo do Samu, e cada soma tem um teste com um previsto que precisa ficar de fora. A prestação de contas lista só CONFIRMED.
- `POST /finance/installments` gera de 2 a 60 previstos, um por mês, com "descrição (i/N)", e os centavos que sobram vão na 1ª parcela.
- `POST /finance/entries/{id}/confirm` confirma o previsto, com valor e data opcionais (data não futura). Se já estiver confirmado, devolve 409.
- Descartar um previsto é o cancelamento que já existe. Previsto pode ter data futura na edição.
- Na visão mensal, `plannedRevenueCents` e `plannedExpenseCents` ficam fora do saldo. Web: botão "Parcelado", selo "Previsto i/N", botão Confirmar e coluna "Previsto".

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
