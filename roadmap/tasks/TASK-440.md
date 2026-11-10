# TASK-440 — Regra do vencimento: só preventiva/inspeção/teste reiniciam; data antiga não puxa para trás

## Tipo
FULL_STACK

## Categoria
Manutenção / Vencimento

## Prioridade
🔴 Crítico — integridade do vencimento (dado errado em item de norma).

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
Decisões de 10/11/2026 ([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), seção 7, perguntas 1 e 6). Hoje `MaintenanceService.applyPerformedMaintenance`
recalcula o vencimento com **qualquer** tipo e com **qualquer** data, até mais antiga que a última.

## Escopo
- Preventiva, inspeção e teste reiniciam o ciclo; corretiva e emergencial entram no histórico sem mexer no vencimento.
- Web: checkbox "também conta como a manutenção periódica" na corretiva/emergencial (exceção). O Samu não pergunta.
- Data anterior à última execução: entra no histórico, não muda `lastPerformedAt` nem o vencimento.
- Mesma regra no cancelamento (recálculo), na prévia `previewNextDue` e no cartão do Samu (TASK-403).

## Critérios de Aceite
- [ ] Corretiva não muda o vencimento; com o checkbox muda
- [ ] Registrar data antiga não puxa o vencimento para trás
- [ ] Cartão do Samu e prévia mostram exatamente o que o registro grava
- [ ] Cancelamento recalcula pela regra nova (teste)

## Dependências
Nenhuma.

## Riscos
Mudança de regra afeta itens existentes só daqui para frente: não recalcular o histórico em massa sem decisão.

## Status
⬜ Backlog
