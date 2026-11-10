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
- [x] Corretiva não muda o vencimento; com o checkbox muda
- [x] Registrar data antiga não puxa o vencimento para trás
- [x] Cartão do Samu e prévia mostram exatamente o que o registro grava
- [x] Cancelamento recalcula pela regra nova (teste)

## Dependências
Nenhuma.

## Riscos
Mudança de regra afeta itens existentes só daqui para frente: não recalcular o histórico em massa sem decisão.

## Implementação (10/11/2026)
Branch `bugfix/TASK-440-regra-vencimento` (api e web, a partir de `staging`) · PRs
[api#190](https://github.com/douglasjava/easy-maintenance-api/pull/190) e
[web#138](https://github.com/douglasjava/easy-maintenance-web/pull/138).
- **API:**
  - Migration `V137`: coluna `maintenances.counts_as_periodic`; as linhas existentes recebem o valor pelo tipo, sem
    recálculo em massa.
  - `RegisterMaintenanceRequest.countsAsPeriodic`, campo opcional.
  - `MaintenanceService`: novas regras `resetsCycle` e `appliesToItem`. Uma próxima data manual num registro que não
    mexe no vencimento é recusada com mensagem clara, em vez de ser ignorada em silêncio.
  - Cancelamento: só recalcula se a manutenção cancelada era a que definia o item, e recalcula a partir da última
    execução que conta.
  - `previewNextDue` com tipo e `NextDuePreview.Effect`.
  - Cartão do Samu: "Vencimento continua DD/MM/AAAA (…)". O aviso antigo de "recalcula a partir de…" saiu, porque
    esse caso deixou de existir.
- **Web (`/maintenances/new`):**
  - Checkbox "Também conta como a manutenção periódica" na corretiva e na emergencial.
  - Aviso de que o vencimento continua quando o registro não mexe nele.
  - O campo de próxima data só aparece quando o registro reinicia o ciclo.
- **Testes:** `MaintenanceCycleRuleTest` (12) e ajustes em `MaintenanceCancelTest` e no cartão do Samu (+1).
  `mvn test` 1835, 0 falhas. Web: `tsc` e `build` ok, `eslint` sem erro novo.
- **Pendente:** teste no navegador real, que fica para o QA em `staging`.

## Status
🔵 Em Validação — PRs api#190 e web#138 → `staging`. Falta o QA manual em `staging`.
