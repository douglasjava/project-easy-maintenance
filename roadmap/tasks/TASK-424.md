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
- [ ] Execução pendente não mexe em vencimento nem no índice
- [ ] Validar duas vezes (bot e web) não cria duas manutenções (lock)
- [ ] Recusada fica como rastro, com motivo

## Dependências
[TASK-417](TASK-417.md).

## Riscos
Duplo processamento entre canais: reaproveitar o lock de idempotência do EPIC-040.

## Status
⬜ Backlog
