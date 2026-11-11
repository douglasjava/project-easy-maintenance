# TASK-454 — QA do Financeiro v2

## Tipo
QA

## Categoria
Financeiro

## Prioridade
🟠 Alto

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
Quebra da [spec do Financeiro v2](../../docs/superpowers/specs/2026-11-11-financeiro-v2-fi05-design.md) (seção todas), aprovada por Douglas em 11/11/2026 ([TASK-446](TASK-446.md)).

## Escopo
- Regressão das somas (resumo, mensal, prestação de contas, dashboard) com PLANNED, fundos e transferência.
- Fluxos de parcela, recorrência, anexo e filtros.
- QA manual em staging.

## Critérios de Aceite
- [ ] Somas conferidas contra os lançamentos
- [ ] QA manual aprovado por Douglas

## Dependências
TASK-447 a 453

## Riscos
—

## Roteiro (11/11/2026)
[TASK-QA-MAN-032](../QA/tasks/TASK-QA-MAN-032.md) cobre a migração dos dados antigos, editar e clonar, visão mensal e competência, fundos, documento e comprovante, parcelas, recorrentes e o Samu.
O lado automatizado está nas PRs: api#219 a api#228 e web#152 a web#160, todas em `staging`, com a suíte da API com 2091 testes e 0 falhas.

## Status
🟡 Em andamento — automatizado ok; falta o QA manual ([TASK-QA-MAN-032](../QA/tasks/TASK-QA-MAN-032.md)) e a primeira execução das migrations V153 a V158 num MySQL (staging).
