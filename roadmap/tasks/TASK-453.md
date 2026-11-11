# TASK-453 — Financeiro v2: Samu avisa previstos e confirma pelo chat

## Tipo
BACKEND

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
Quebra da [spec do Financeiro v2](../../docs/superpowers/specs/2026-11-11-financeiro-v2-fi05-design.md) (seção D5), aprovada por Douglas em 11/11/2026 ([TASK-446](TASK-446.md)).

## Escopo
- No resumo do dia, "N contas previstas para confirmar" só para ADMIN e SYNDIC (matriz de papéis, EPIC-042).
- Botões [Confirmar] [Ver no painel].

## Critérios de Aceite
- [x] Só ADMIN e SYNDIC recebem
- [x] Confirmar pelo chat = mesma regra do web

## Dependências
[TASK-452](TASK-452.md), EPIC-042

## Riscos
Aviso para papel sem permissão financeira.

## Implementação (11/11/2026)
[api#228](https://github.com/douglasjava/easy-maintenance-api/pull/228), mergeadas em `staging`.
- Painel do Samu: só para quem tem `LANCAMENTO_FINANCEIRO` (ADMIN e SYNDIC), aparecem "💰 N conta(s) prevista(s) para confirmar" e o atalho [Confirmar contas]. Contam os previstos com data até hoje.
- `fin:prev` lista até 10 previstos. `fin:prev:{id}` confirma com o mesmo `FinancialEntryService.confirm` do web, rodando como o próprio usuário.
- Os demais papéis recebem CAPABILITY_DENIED antes de qualquer consulta.
- Correção junto: a mensagem "Despesa lançada" da TASK-442 saía com o real duplicado ("R$ R$"). Ganhou teste de regressão.

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
