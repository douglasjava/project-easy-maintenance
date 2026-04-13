# RB-003 — Banco de Dados Lento

**Severidade:** Alta  
**Componente:** MySQL 8 + HikariCP + JPA/Hibernate  
**Categoria:** Performance / Infraestrutura

---

## Configuração Relevante

| Parâmetro | Valor |
|-----------|-------|
| Engine | MySQL 8.0 |
| ORM | JPA/Hibernate (Spring Boot 3.5) |
| Connection pool | HikariCP (defaults Spring Boot) |
| Migrations | Flyway |
| Timezone | UTC |
| DDL | `ddl-auto=none` (apenas Flyway) |

---

## Sintomas

- Requisições HTTP retornando lentamente (> 2s) ou timeout (500/504)
- Erros `HikariPool-1 - Connection is not available, request timed out after 30000ms`
- Jobs de billing ultrapassando o lock máximo de 30 min
- Logs com queries lentas (MySQL slow query log)
- Prometheus/Grafana mostrando latência elevada em `http_server_requests_seconds`
- Sentry com exceções `JDBCConnectionException` ou `QueryTimeoutException`
- Railway mostrando spike de CPU no serviço de banco

---

## Causa Provável

1. **Query sem índice** em tabela grande (N+1, full table scan)
2. **Pool de conexões esgotado** — muitas requisições simultâneas sem conexões disponíveis
3. **Lock de transação longa** — job ou operação segurando lock por muito tempo
4. **Crescimento de tabela** sem índices adequados (manutenções, audit_logs)
5. **Railway database tier** com recursos insuficientes para carga atual

---

## Passos de Diagnóstico

### 1. Identificar queries lentas em execução
```sql
-- Ver queries em execução agora (> 5 segundos)
SELECT id, user, host, db, command, time, state, info
FROM information_schema.PROCESSLIST
WHERE time > 5
ORDER BY time DESC;
```

### 2. Ver queries recentes lentas (se slow query log habilitado)
```sql
-- Verificar se slow query log está ativo
SHOW VARIABLES LIKE 'slow_query_log%';
SHOW VARIABLES LIKE 'long_query_time';

-- Queries mais lentas (se performance_schema disponível)
SELECT digest_text, count_star, avg_timer_wait/1e12 AS avg_sec,
       max_timer_wait/1e12 AS max_sec
FROM performance_schema.events_statements_summary_by_digest
ORDER BY avg_timer_wait DESC
LIMIT 10;
```

### 3. Verificar pool de conexões via logs
```bash
railway logs --service api --tail 300 | grep -iE "(HikariPool|Connection is not available|timed out)"
```

### 4. Verificar transações bloqueadas
```sql
-- Ver locks ativos
SELECT r.trx_id waiting_trx_id,
       r.trx_mysql_thread_id waiting_thread,
       r.trx_query waiting_query,
       b.trx_id blocking_trx_id,
       b.trx_mysql_thread_id blocking_thread,
       b.trx_query blocking_query
FROM information_schema.innodb_lock_waits w
INNER JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id
INNER JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id;
```

### 5. Verificar tamanho das tabelas
```sql
SELECT table_name,
       ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb,
       table_rows
FROM information_schema.tables
WHERE table_schema = 'easy_maintenance'
ORDER BY (data_length + index_length) DESC
LIMIT 10;
```

### 6. Verificar índices ausentes via EXPLAIN
```sql
-- Para a query suspeita, verificar plano de execução
EXPLAIN SELECT * FROM maintenances WHERE organization_code = 'ORG-001' ORDER BY created_at DESC;
-- "type: ALL" = full table scan = sem índice
```

---

## Passos de Resolução

### Caso A: Query sem índice (full table scan)
```sql
-- Adicionar índice faltante (avaliar impacto antes)
-- Preferir horário de baixo tráfego
ALTER TABLE maintenances ADD INDEX idx_maintenances_org_created (organization_code, created_at);

-- Para tabelas grandes, usar CREATE INDEX ... ALGORITHM=INPLACE, LOCK=NONE (online DDL MySQL 8)
ALTER TABLE audit_logs
ADD INDEX idx_audit_logs_created (created_at)
ALGORITHM=INPLACE, LOCK=NONE;
```

### Caso B: Pool de conexões esgotado
```bash
# Opção 1: Reiniciar aplicação para liberar conexões presas
railway redeploy --service api

# Opção 2: Aumentar pool (adicionar env var)
# Adicionar no Railway: SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=20
railway variables set SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=20
```

### Caso C: Transação longa segurando lock
```sql
-- Identificar a thread ID da query bloqueante (do passo 4)
-- Matar a transação bloqueante (CUIDADO — pode causar rollback)
KILL <thread_id>;
```

### Caso D: Job de billing travando banco
- Ver RB-001 para tratamento de jobs presos
- Matar thread do job no banco e liberar ShedLock

### Caso E: Banco sobrecarregado por spike de tráfego
1. Verificar no Railway se é possível escalar o plano do banco
2. Temporariamente reduzir `SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE` para evitar concorrência excessiva
3. Se carga for dos jobs, considerar adiar jobs para horário alternativo via variável de cron

---

## Como Comunicar o Cliente

**Degradação parcial (requisições lentas mas funcionando):**
- Não comunicar proativamente
- Se cliente reclamar: "Estamos passando por degradação de performance temporária. Nossa equipe está trabalhando na resolução."

**Indisponibilidade (erros 500 generalizados):**
- Publicar na status page (quando disponível)
- Template:
  > "O sistema Easy Maintenance está temporariamente indisponível por falha na infraestrutura de banco de dados. Estimativa de resolução: [ETA]. Nenhum dado foi perdido."

**Template Slack interno:**
> "INCIDENTE: DB lento desde [HORA]. Pool esgotado / query lenta identificada: [QUERY]. Ação: [O QUE ESTÁ SENDO FEITO]. ETA: [ETA]"

---

## Prevenção

- Índices críticos já criados via TASK-019 (V56 migration)
- Monitorar Prometheus metric `hikaricp_connections_active` / `hikaricp_connections_pending`
- Audit logs crescem rápido — configurar política de retenção (TASK-035)
- Habilitar slow query log no MySQL em produção (`long_query_time=1`)
