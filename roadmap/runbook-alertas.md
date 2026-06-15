# Runbook de Alertas — Easy Maintenance

> Documento de resposta a incidentes para cada alerta configurado no Prometheus/AlertManager.
> Atualizado em: 2026-06-15

---

## Como acessar o ambiente de observabilidade

| Serviço      | URL local             | Credenciais   |
|--------------|-----------------------|---------------|
| Prometheus   | http://localhost:9090 | —             |
| AlertManager | http://localhost:9093 | —             |
| Grafana      | http://localhost:3001 | admin / admin |

---

## High Error Rate

**Alerta:** `HighErrorRate`
**Condição:** Taxa de erros HTTP 5xx > 1% por 5 minutos

### Diagnóstico
1. Acessar logs da aplicação: `docker logs easy_maintenance_api --tail 200`
2. Verificar qual endpoint está gerando os erros:
   ```promql
   topk(5, rate(http_server_requests_seconds_count{status=~"5..",application="easy-maintenance"}[5m])) by (uri)
   ```
3. Verificar se é problema de banco, serviço externo (Asaas, MailerSend) ou bug de código

### Ações
- **Banco de dados:** verificar conexões ativas, locks, queries lentas
- **Asaas:** verificar status em https://status.asaas.com
- **MailerSend:** verificar status em https://status.mailersend.com
- **Bug de código:** revisar commit mais recente, considerar rollback via Railway

---

## High Latency P95

**Alerta:** `HighLatencyP95`
**Condição:** Latência P95 > 2 segundos por 5 minutos

### Diagnóstico
1. Identificar endpoints lentos:
   ```promql
   topk(5, histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{application="easy-maintenance"}[5m])) by (le, uri))
   ```
2. Verificar uso de heap JVM (GC overhead?)
3. Verificar pool de conexões MySQL

### Ações
- **GC:** aumentar heap via `JAVA_OPTS=-Xmx512m` se em limite; revisar vazamentos de memória
- **Queries lentas:** `SHOW PROCESSLIST` no MySQL, adicionar índices se necessário
- **Serviços externos lentos:** verificar timeout e circuit breaker do Resilience4j

---

## Job Failure

**Alerta:** `JobFailure`
**Condição:** Job sem execução bem-sucedida por mais de 26 horas

### Jobs monitorados
| Job                    | Cron (padrão)    | Impacto se falhar                               |
|------------------------|------------------|-------------------------------------------------|
| `daily_trial`          | 01:15            | Trials não expiram, clientes sem aviso          |
| `billing_cycle`        | 02:00            | Ciclo de billing não avança, clientes não pagam |
| `billing_reconciliation` | 03:00          | Divergências Asaas não detectadas               |
| `subscription_blocking` | 03:00          | Assinaturas vencidas não bloqueadas             |

### Diagnóstico
1. Verificar logs: `docker logs easy_maintenance_api | grep -i "[JobName]"`
2. Verificar tabela ShedLock no banco: `SELECT * FROM shedlock WHERE name = 'JobName';`
3. Verificar se o lock está travado (lock_until no passado = problema)

### Ações
- **Lock travado:** `UPDATE shedlock SET lock_until = NOW() WHERE name = 'JobName' AND lock_until > NOW();`
- **Exceção no job:** corrigir causa raiz, triggerar manualmente via endpoint admin se existir
- **App fora do ar:** verificar status da instância no Railway

---

## JVM Memory High

**Alerta:** `JvmMemoryHigh`
**Condição:** JVM Heap > 85% por 10 minutos

### Diagnóstico
1. Verificar trend de crescimento no Grafana (vazamento ou carga pontual?)
2. Identificar o que está consumindo memória:
   ```
   jvm_memory_used_bytes{id=~".*",application="easy-maintenance"}
   ```

### Ações
- **Carga pontual:** aguardar GC; se não resolver em 15min, reiniciar instância via Railway
- **Crescimento contínuo:** heap dump via `jmap`, análise posterior; aumentar limites de memória temporariamente
- **Longo prazo:** revisar queries com resultsets grandes, mapas/caches em memória

---

## DB Connections High

**Alerta:** `DbConnectionsHigh`
**Condição:** Pool HikariCP > 80% de utilização por 5 minutos

### Diagnóstico
1. Verificar conexões ativas no MySQL:
   ```sql
   SHOW PROCESSLIST;
   SELECT count(*) FROM information_schema.processlist WHERE command != 'Sleep';
   ```
2. Verificar se há queries longas bloqueando conexões
3. Verificar se o pool está sub-dimensionado para a carga atual

### Ações
- **Queries longas:** `KILL <process_id>` se travar por mais de 30s
- **Pool pequeno:** aumentar `spring.datasource.hikari.maximum-pool-size` (padrão 10) — requer restart
- **Curto prazo:** reiniciar instância para liberar conexões ociosas se necessário

---

## Webhook DLQ Growing

**Alerta:** `WebhookDlqGrowing`
**Condição:** DLQ de webhooks Asaas acumulando > 5 eventos em 1 hora

### Diagnóstico
1. Verificar tabela `webhook_dlq` no banco:
   ```sql
   SELECT event_type, COUNT(*), MAX(created_at) FROM webhook_dlq GROUP BY event_type ORDER BY COUNT(*) DESC;
   ```
2. Verificar se o endpoint de webhook está recebendo as chamadas (logs)
3. Verificar se o Asaas está enviando eventos (dashboard Asaas)

### Ações
- **Endpoint fora do ar:** verificar se o webhook está registrado no Asaas com a URL correta
- **Erro de processamento:** verificar exceções nos logs, corrigir e usar endpoint de replay (`/admin/webhooks/dlq/replay`)
- **Asaas com problema:** aguardar normalização; os eventos ficam na DLQ para retry manual

---

## Billing Reconciliation Divergence

**Alerta:** `BillingReconciliationDivergence`
**Condição:** Mais de 3 divergências Asaas detectadas em 24 horas

### Diagnóstico
1. Verificar logs do job de reconciliação: `grep "reconciliation" app.log | tail -50`
2. Identificar quais subscriptions estão divergentes:
   ```sql
   SELECT bs.id, bs.status, bs.external_subscription_id 
   FROM billing_subscriptions bs 
   WHERE bs.status != 'CANCELED' AND bs.external_subscription_id IS NOT NULL;
   ```
3. Comparar com status no painel Asaas

### Ações
- **Cancelamentos não propagados:** verificar se webhook `SUBSCRIPTION_DELETED` está chegando
- **Pagamentos não registrados:** verificar webhook `PAYMENT_RECEIVED` nos logs
- **Divergência de dados:** corrigir manualmente via SQL + audit log, notificar cliente se impactado

---

## Configuração de notificações (produção)

No Railway ou no ambiente de produção, configurar as variáveis de ambiente:

```
ALERTMANAGER_SMTP_USERNAME=douglasmarquesdias@gmail.com
ALERTMANAGER_SMTP_PASSWORD=<app-password-gmail>
```

Para Gmail, gerar uma App Password em: https://myaccount.google.com/apppasswords

---

## Contato de escalonamento

| Nível | Contato          | Canal                        |
|-------|------------------|------------------------------|
| L1    | Douglas Dias     | douglasmarquesdias@gmail.com |
