# RB-001 — Job de Billing Falhou

**Severidade:** Alta  
**Componente:** Jobs Agendados (ShedLock + Spring Scheduler)  
**Categoria:** Billing / Financeiro

---

## Jobs de Billing

| Job | Horário | O que faz |
|-----|---------|-----------|
| `BillingCycleJob` | 02:00 AM | Processa viradas de ciclo e aplica mudanças de plano pendentes |
| `SubscriptionBlockingJob` | 03:00 AM | Bloqueia assinaturas vencidas há > 3 dias |
| `BillingCancellationJob` | 04:00 AM | Processa cancelamentos de assinatura |
| `DailyTrialJob` | 01:15 AM | Processa expirações de trial |

---

## Sintomas

- Assinatura deveria ter sido bloqueada mas continua ativa
- Mudança de plano pendente não foi aplicada
- Trial expirou mas cliente ainda tem acesso
- Log com `ERROR ... BillingCycleJob` ou `BillingSubscriptionService`
- Alerta Sentry com exceção em job de billing
- Lock ShedLock preso: linha em `shedlock` na DB com `locked_until` no passado e `locked_by` ainda preenchido

---

## Causa Provável

1. **Exceção não tratada** no job — job abortou sem completar
2. **Lock ShedLock preso** — instância anterior travou antes de liberar o lock (Railway restart no meio do job)
3. **Banco fora do ar** durante a execução do job
4. **Asaas indisponível** durante job de cobrança (ver RB-002)
5. **Job nunca executou** — variável de cron mal configurada ou horário errado no ambiente

---

## Passos de Diagnóstico

### 1. Verificar Sentry
- Acesse o painel Sentry → filtrar por `easy-maintenance` + environment `production`
- Buscar exceções de `BillingCycleJob`, `SubscriptionBlockingJob`, `BillingCancellationJob`
- Identificar stack trace e mensagem de erro

### 2. Verificar logs no Railway
```bash
# Railway CLI
railway logs --service api --tail 500 | grep -E "(BillingCycle|SubscriptionBlocking|BillingCancellation|DailyTrial|ShedLock)"
```

### 3. Verificar estado do ShedLock no banco
```sql
SELECT name, lock_until, locked_at, locked_by
FROM shedlock
WHERE name IN (
    'BillingCycleJob',
    'SubscriptionBlockingJob',
    'BillingCancellationJob',
    'DailyTrialJob'
);
```
- `lock_until` no passado com `locked_by` preenchido → lock preso (instância morreu sem liberar)
- `lock_until` no futuro → job ainda em execução (aguardar ou verificar se instância está viva)

### 4. Verificar assinaturas impactadas
```sql
-- Assinaturas que deveriam ter sido bloqueadas (vencidas há > 3 dias)
SELECT id, organization_code, status, due_date
FROM billing_subscriptions
WHERE status = 'ACTIVE'
  AND due_date < DATE_SUB(NOW(), INTERVAL 3 DAY);

-- Mudanças de plano pendentes não aplicadas
SELECT * FROM billing_subscriptions
WHERE pending_plan_code IS NOT NULL;
```

---

## Passos de Resolução

### Caso A: Lock ShedLock preso
```sql
-- Liberar o lock manualmente (só execute se tiver certeza que o job não está rodando)
UPDATE shedlock
SET locked_by = NULL, lock_until = NOW() - INTERVAL 1 SECOND
WHERE name = 'BillingCycleJob'  -- trocar pelo job afetado
  AND lock_until < NOW();
```
Após liberar, o job executará normalmente no próximo ciclo (próximo dia).

### Caso B: Reprocessar job manualmente (via endpoint admin)
```bash
# Se existir endpoint de trigger manual (verificar AdminController)
curl -X POST https://api.easy-maintenance.com/admin/jobs/billing-cycle/trigger \
  -H "X-Admin-Token: $ADMIN_TOKEN"
```
Se endpoint não existir, reprocessar via SQL (Caso C).

### Caso C: Reprocessar assinaturas via SQL (cirurgia manual)
```sql
-- Bloquear manualmente assinaturas vencidas (substitui SubscriptionBlockingJob)
UPDATE billing_subscriptions
SET status = 'BLOCKED', updated_at = NOW()
WHERE status = 'ACTIVE'
  AND due_date < DATE_SUB(NOW(), INTERVAL 3 DAY);
```
**Atenção:** Execute em horário de baixo tráfego. Confirme com `SELECT` antes de `UPDATE`.

### Caso D: Job falhou por Asaas indisponível
- Ver RB-002 para tratamento de Asaas fora do ar
- O circuit breaker pode ter aberto durante a execução do job
- Após Asaas voltar, o job reprocessará no próximo dia ou via trigger manual

---

## Como Comunicar o Cliente

**Cenário:** Assinatura não bloqueada / Trial não expirado (impacto positivo para o cliente — baixa urgência)
- Não comunicar proativamente
- Corrigir silenciosamente via resolução acima

**Cenário:** Mudança de plano pendente não aplicada
- Template interno (Slack/e-mail equipe):
  > "Detectamos falha no job de billing na madrugada de [DATA]. Mudança de plano para org [ORG_CODE] não foi aplicada. Reprocessando manualmente."

**Cenário:** Cliente reclamou de cobrança ou acesso incorreto
- Resposta ao cliente:
  > "Identificamos uma instabilidade em nosso sistema de cobrança automatizado. Sua situação já foi corrigida manualmente. Se perceber qualquer inconsistência nos próximos dias, entre em contato."

---

## Prevenção

- Monitorar alerta Sentry configurado para jobs de billing
- Verificar Prometheus metric `shedlock_job_duration_seconds` para detectar jobs lentos
- Manter ShedLock com `lockAtLeastFor` = 15 min e `lockAtMostFor` = 30 min (já configurado)
