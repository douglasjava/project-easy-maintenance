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
- [x] Saldo por fundo e total batem
- [x] Transferência não infla receita nem despesa
- [x] Saldo inicial entra no acumulado

## Dependências
[TASK-447](TASK-447.md)

## Riscos
Transferência contada como despesa no total do condomínio.

## Implementação (11/11/2026)
[api#223](https://github.com/douglasjava/easy-maintenance-api/pull/223) e [web#156](https://github.com/douglasjava/easy-maintenance-web/pull/156), mergeadas em `staging`.
- A migração V154 cria `fund` (ORDINARIA, RESERVA, OBRAS) e `transfer_group_id` no lançamento, e a tabela `financial_fund_settings` com o saldo inicial e a data por fundo. ⚠️ Ainda não foi executada num MySQL.
- `POST /finance/transfers` grava os dois lados com o mesmo grupo. Um lado não pode ser editado, e cancelar um cancela os dois. Transferências ficam fora de `/summary`, `/summary/monthly` e da prestação de contas.
- `GET /finance/funds` devolve o saldo por fundo e o total. O custo da manutenção sem lançamento vinculado sai da ordinária. `PUT /finance/funds/{fund}/initial-balance` grava o saldo inicial, com auditoria.
- Visão mensal: novo campo `openingBalanceCents`, e o acumulado agora parte dele. Isso muda a TASK-444, que partia do zero.
- `FUNDO_RESERVA` virou legado: não pode ser escolhida em lançamentos novos, nem no web nem no Samu.
- Web: cartão "Fundos" com Transferir e Saldo inicial, campo "Conta / fundo" no formulário e selo do fundo na lista.

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
