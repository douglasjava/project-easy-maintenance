# TASK-424 — Execução enviada (📝) por zelador ou fornecedor, validada pelo síndico

## Tipo
FULL_STACK

## Categoria
Manutenção / Prova de manutenção

## Prioridade
🔴 Crítico — o ponto de produto mais forte da matriz (prova de manutenção, EPIC-033).

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D9 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md) e item 5 da "Proposta técnica": quem executou registra a evidência na hora e o síndico só
confirma. Execução não validada não conta como manutenção feita.

## Escopo
- Entidade de execução enviada com status `PENDENTE_VALIDACAO` | `VALIDADA` | `RECUSADA`, sem expiração.
- Só `VALIDADA` vira manutenção (recalcula vencimento pela regra da [TASK-440](TASK-440.md), entra no índice).
- Síndico valida pelo bot (botões, fan-out e lock como no EPIC-040) ou pelo web (fila de validação).
- Foto, laudo e ART anexados seguem para a manutenção validada.

## Critérios de Aceite
- [x] Execução pendente não mexe em vencimento nem no índice
- [x] Validar duas vezes (bot e web) não cria duas manutenções (lock)
- [x] Recusada fica como rastro, com motivo

## Dependências
[TASK-417](TASK-417.md).

## Riscos
Duplo processamento entre canais: reaproveitar o lock de idempotência do EPIC-040.

## Implementação (10/11/2026)
[api#201](https://github.com/douglasjava/easy-maintenance-api/pull/201), mergeada em `staging`.
- `maintenance_submissions` (V143) e `MaintenanceSubmissionService`: enviar, validar (vira manutenção, com os anexos) e recusar com motivo. A trava garante que só a primeira decisão vale.
- API da fila: `/maintenance-submissions`. No bot, a linha "Validar execuções" no menu do síndico.
- Pendente: a tela da fila no web e o teste unitário do serviço.

## Status
🔵 Em `staging` (10/11/2026) — falta a tela da fila no web; aguarda a validação de Douglas.
