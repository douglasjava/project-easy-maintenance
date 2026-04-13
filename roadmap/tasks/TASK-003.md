# TASK-003 — Implementar ShedLock nos jobs agendados

## Tipo
Segurança / Confiabilidade / Infra

## Categoria
Backend / Jobs / Infra

## Prioridade
🔴 Crítico

## Fase
1 — Antes do lançamento

## Épico
EPIC-002 — Confiabilidade Operacional

## Descrição
Os 5 jobs agendados do sistema usam `@Scheduled` do Spring sem nenhum mecanismo de lock distribuído:
- `SubscriptionBlockingJob` (3h AM)
- `DailyTrialJob` (1h15 AM)
- `BillingCycleJob` (2h AM)
- `BillingCancellationJob` (4h AM)
- `NotificationEventDetectionJob` (5h AM)

Se a aplicação rodar em mais de uma instância (Railway auto-scale, blue-green deploy, HA setup), **todos os jobs executam em todas as instâncias simultaneamente**, causando cobranças duplicadas, e-mails duplicados e estados inconsistentes.

## Problema
Escalonamento horizontal ou qualquer cenário de múltiplas instâncias (inclusive durante um deploy rolling) gera:
- Cliente cobrado duas vezes no mesmo ciclo
- Dois e-mails de "trial expirando" enviados para o mesmo cliente
- Assinatura bloqueada duas vezes com possíveis conflitos de estado

## Impacto
- Impacto financeiro direto (cobranças duplicadas)
- Dano reputacional (e-mails duplicados)
- Possível inconsistência de estado de assinatura

## Dependências
- MySQL já configurado — ShedLock com JDBC backend não requer infraestrutura adicional

## Critérios de Aceite
- [ ] Dependência `shedlock-spring` e `shedlock-provider-jdbc-template` adicionadas ao `pom.xml`
- [ ] Tabela `shedlock` criada via migration Flyway
- [ ] Todos os 5 jobs anotados com `@SchedulerLock`
- [ ] Locks configurados com `lockAtMostFor` e `lockAtLeastFor` adequados para cada job
- [ ] Teste manual: subir 2 instâncias e verificar que job executa apenas em uma
- [ ] Logs de job indicam quando lock foi adquirido e quando não foi

## Subtasks
- [ ] Adicionar dependências ShedLock no `pom.xml`
- [ ] Criar migration `V54__shedlock_table.sql`
- [ ] Configurar `LockProvider` bean com `JdbcTemplateLockProvider`
- [ ] Anotar `SubscriptionBlockingJob` com `@SchedulerLock`
- [ ] Anotar `DailyTrialJob` com `@SchedulerLock`
- [ ] Anotar `BillingCycleJob` com `@SchedulerLock`
- [ ] Anotar `BillingCancellationJob` com `@SchedulerLock`
- [ ] Anotar `NotificationEventDetectionJob` com `@SchedulerLock`
- [ ] Validar configuração de lockAtMostFor (máximo tempo de lock) para cada job

## Esforço
Pequeno (3-5h)

## Risco de não fazer
Cobranças duplicadas garantidas no primeiro cenário de múltiplas instâncias. Isso gera disputa de chargeback e perda de confiança do cliente.

## Status
Concluído
