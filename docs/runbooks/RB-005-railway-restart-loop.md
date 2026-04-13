# RB-005 — Railway Restart Loop

**Severidade:** Crítica (aplicação indisponível)  
**Componente:** Railway Deployment + Spring Boot + entrypoint.sh  
**Categoria:** Infraestrutura / Deploy

---

## Arquitetura de Deploy

```
Railway Service
    └─ Docker (multi-stage: Maven 3.9 + Eclipse Temurin JDK 21)
        └─ entrypoint.sh
            ├─ Gera config do Grafana Alloy (telemetria)
            ├─ Inicia Grafana Alloy em background (métricas → Prometheus)
            └─ Inicia Spring Boot JAR (java -jar app.jar)
```

**Variáveis críticas de inicialização:**
- `SPRING_PROFILES_ACTIVE` — perfil do Spring (prod, hml)
- `MYSQL_HOST`, `MYSQLPORT`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`
- `ASAAS_API_KEY`, `ASAAS_WEBHOOK_TOKEN`
- `JWT_RSA_PRIVATE_KEY`, `JWT_RSA_PUBLIC_KEY`
- `SENTRY_DSN_BACKEND` (opcional — ausência não falha)

---

## Sintomas

- Railway dashboard mostra deploy em loop: "Deploying → Failed → Deploying → Failed"
- Serviço não responde: `curl https://api.easy-maintenance.com/actuator/health` → timeout ou connection refused
- `railway logs` mostra stack trace logo após startup
- Contagem de restarts aumentando no Railway dashboard
- Frontend mostra erros de rede para todos os usuários

---

## Causa Provável

1. **Variável de ambiente ausente ou inválida** — Spring Boot falha no `ApplicationContext`
2. **Banco de dados inacessível** — Spring não consegue conectar ao MySQL no startup
3. **Migration Flyway falhou** — migration inválida impede startup
4. **OOM (Out of Memory)** — JVM com heap insuficiente para o container Railway
5. **Erro na entrypoint.sh** — script falha antes de iniciar o JAR
6. **Deploy com código quebrado** — erro de compilação ou NPE no startup
7. **Porta em uso** — conflito de porta (improvável no Railway isolado)

---

## Passos de Diagnóstico

### 1. Ler os logs de startup no Railway
```bash
railway logs --service api --tail 100
```
Procurar por:
- `APPLICATION FAILED TO START` → contexto Spring não inicializado
- `FlywayException` → migration falhou
- `HikariPool ... Connection refused` → banco inacessível
- `java.lang.OutOfMemoryError` → sem memória
- Stack trace em `entrypoint.sh` → script falhou

### 2. Verificar a migration Flyway que falhou
```bash
railway logs | grep -iE "(flyway|migration|V[0-9]+__)"
```
```sql
-- Ver estado das migrations no banco (se banco acessível)
SELECT version, description, success, installed_on
FROM flyway_schema_history
ORDER BY installed_rank DESC
LIMIT 10;
-- success=false indica migration quebrada
```

### 3. Verificar variáveis de ambiente no Railway
- Railway dashboard → Service → Variables
- Confirmar que todas as variáveis críticas estão preenchidas
- Especialmente: `MYSQL_HOST`, `MYSQL_USER`, `MYSQL_PASSWORD`, `JWT_RSA_PRIVATE_KEY`

### 4. Testar conexão com banco manualmente
```bash
# Via Railway shell (se disponível)
railway run -- mysql -h $MYSQLHOST -P $MYSQLPORT -u $MYSQLUSER -p$MYSQLPASSWORD $MYSQL_DATABASE -e "SELECT 1"
```

### 5. Verificar último deploy bem-sucedido no Railway
- Railway dashboard → Deployments → ver qual deployment estava funcionando
- Identificar o commit do último deploy estável

---

## Passos de Resolução

### Caso A: Variável de ambiente ausente/inválida
```bash
# Identificar variável faltante no log (ex: "Could not resolve placeholder 'JWT_RSA_PRIVATE_KEY'")
# Adicionar no Railway dashboard → Variables, ou via CLI:
railway variables set NOME_DA_VARIAVEL=valor
```
Railway faz redeploy automático após set de variável.

### Caso B: Migration Flyway falhou
```sql
-- Opção 1: Corrigir a migration quebrada (requer novo deploy)
-- Opção 2: Marcar migration como falsa (CUIDADO — apenas se tiver certeza)
UPDATE flyway_schema_history
SET success = 1
WHERE version = 'XX'  -- versão da migration quebrada
  AND success = 0;
```
**Atenção:** Só usar opção 2 se a migration aplicou parcialmente e o estado do banco está consistente.

### Caso C: Banco inacessível (Railway DB reiniciando)
1. Verificar Railway DB service status no dashboard
2. Se Railway DB estiver OK mas o app ainda não conecta: reiniciar app service
3. Se Railway DB estiver down: aguardar Railway recovery (verificar https://status.railway.app)

### Caso D: Rollback para deploy estável
```bash
# Railway dashboard → Deployments → Selecionar deployment anterior → Redeploy
# ou via CLI (se suportado)
railway rollback --deployment <deployment-id>
```
**Este é geralmente o passo mais rápido para restabelecer o serviço.**

### Caso E: OOM (Out of Memory)
```bash
# Aumentar memória do container no Railway
# railway.toml ou Railway dashboard → Service Settings → Memory limit
# ou adicionar variável JVM:
railway variables set JAVA_OPTS="-Xmx512m -Xms256m"
```

### Caso F: Erro no entrypoint.sh
```bash
railway logs | grep -A 10 "entrypoint"
# Se Alloy falha mas Spring Boot deveria funcionar:
# Verificar se $PROM_URL está configurado corretamente
# Alloy falha silenciosamente — não deveria parar o JAR
```

---

## Sequência de Triage Rápida (< 5 min)

```
1. railway logs | tail 50
2. Leu "APPLICATION FAILED TO START"?
   Sim → Ler causa em "Description" e "Action" no log
   Não → Ver próximo error
3. Erro de DB? → Verificar MYSQL_* vars e Railway DB status
4. Erro de Flyway? → Ver migration com success=false no DB
5. Código NPE no startup? → Rollback imediato para último deploy estável
6. Sem pista clara? → Rollback imediato, investigar depois
```

---

## Como Comunicar o Cliente

**Downtime confirmado (serviço indisponível):**

Template status page / e-mail:
> "O Easy Maintenance está temporariamente indisponível por uma falha na infraestrutura. Nossa equipe está trabalhando na resolução. Nenhum dado foi perdido. Previsão de retorno: [ETA ou 'Em investigação']."

**Template Slack interno:**
> "CRÍTICO: Restart loop no Railway desde [HORA]. Logs: [LINK]. Causa provável: [CAUSA]. Ação: [ROLLBACK/FIX]. ETA: [ETA]"

**Após resolução:**
> "RESOLVIDO: Serviço restabelecido às [HORA]. Causa: [CAUSA]. Duração: [X min]. Ação corretiva: [O QUE FOI FEITO]."

---

## Prevenção

- Configurar Railway health check apontando para `/actuator/health`
- Testar migrations em ambiente HML antes de aplicar em produção
- Nunca subir código sem CI passando
- Manter variáveis de ambiente documentadas e versionadas (sem os valores)
- Configurar alerta no Railway ou Sentry para reinícios repetidos
