# FLOW-008 — Jobs Agendados com ShedLock

## Criticidade
🟠 HIGH

## Launch Relevance
Cobranças duplicadas em blue-green deploy ou auto-scale comprometem receita e geram chargebacks.

## Tasks Relacionadas
- TASK-003 — Implementar ShedLock nos jobs agendados

## Descrição do Fluxo

5 jobs agendados executam em horários específicos (madrugada):
- `SubscriptionBlockingJob` (3h AM) — bloqueia assinaturas inadimplentes
- `DailyTrialJob` (1h15 AM) — processa trials expirando
- `BillingCycleJob` (2h AM) — gera cobranças do ciclo atual
- `BillingCancellationJob` (4h AM) — cancela assinaturas pendentes
- `NotificationEventDetectionJob` (5h AM) — detecta eventos de notificação

ShedLock garante que mesmo com N instâncias rodando simultaneamente, cada job execute em apenas uma instância. O lock é persistido na tabela `shedlock` via JDBC.

## Camadas Impactadas
- **Backend:** Todos os 5 jobs anotados com `@SchedulerLock`, `LockProvider` bean, tabela `shedlock`
- **Banco:** Tabela `shedlock` (migration Flyway V54)

## Cenários Críticos

| Cenário | Tipo | Cobertura Atual |
|---------|------|----------------|
| Job executa normalmente (1 instância) | Happy path | Logs de produção |
| 2 instâncias: job executa em apenas 1 | ShedLock | Manual (descrito em TASK-003) |
| Tabela `shedlock` populada com lock ativo | Banco | Manual |
| Lock liberado após `lockAtMostFor` expirar | Timeout | Não testado |
| Job falha → lock liberado para próxima execução | Resiliência | Não testado |

## Validação Recomendada
- **Manual:** Subir 2 instâncias localmente com Docker Compose e verificar logs de lock
- **Automatizada:** Não prioritário agora — risco coberto pelo ShedLock + constraint de banco

## Gaps
- Nenhum teste automatizado de ShedLock
- `lockAtMostFor` configurado — testar expiração de lock após job lento
- Monitoramento de falha de job em produção (TASK-021 pendente — sem alertas ainda)

## Status de Validação
- [ ] Tabela `shedlock` criada (migration V54 confirmada)
- [ ] Todos os 5 jobs com `@SchedulerLock`
- [ ] Teste manual com 2 instâncias executado
- [ ] TASK-021 (alertas) priorizada para detectar falhas de job em produção
