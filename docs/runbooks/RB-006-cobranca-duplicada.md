# RB-006 — Cobrança Duplicada

**Severidade:** Alta (impacto financeiro direto no cliente)  
**Componente:** `AsaasClient` + `BillingSubscriptionService` + Webhook Asaas  
**Categoria:** Billing / Financeiro / Compliance

---

## Fluxo de Cobrança do Easy Maintenance

```
1. Cliente assina plano → POST /asaas/subscriptions (cria assinatura recorrente no Asaas)
2. Asaas cobra mensalmente e envia webhook PAYMENT_CONFIRMED
3. App processa webhook → atualiza status da subscription para ACTIVE
4. BillingCycleJob (02:00 AM) → processa viradas de ciclo e mudanças de plano
5. SubscriptionBlockingJob (03:00 AM) → bloqueia se vencida há > 3 dias
```

---

## Sintomas

- Cliente contata suporte relatando duas cobranças no mesmo período
- Dois registros de pagamento no Asaas para a mesma assinatura no mesmo ciclo
- Log com `POST /payments` ou `POST /subscriptions` executado duas vezes para o mesmo `organization_code`
- Dois webhooks `PAYMENT_CONFIRMED` processados para o mesmo pagamento
- Sentry com log de webhook duplicado

---

## Causa Provável

1. **Dupla submissão no frontend** — usuário clicou "Assinar" duas vezes (debounce não funcionou)
2. **Webhook entregue duas vezes pelo Asaas** — Asaas pode reenviar webhook se não receber confirmação 200
3. **BillingCycleJob executou mais de uma vez** — ShedLock não funcionou corretamente (ex: dois pods ativos)
4. **Mudança de plano processada duas vezes** — race condition no serviço de mudança de plano
5. **Retry HTTP no cliente** — timeout na chamada ao Asaas causou retry que foi processado pelo Asaas

---

## Passos de Diagnóstico

### 1. Confirmar a duplicata no Asaas
- Acessar painel Asaas → Cobranças / Pagamentos
- Filtrar por cliente (buscar pelo CPF/CNPJ ou nome da org)
- Identificar dois pagamentos com:
  - Mesmo valor
  - Mesmo período de referência
  - Status CONFIRMED/RECEIVED

### 2. Verificar audit log da organização
```sql
-- Ver eventos de billing para a organização
SELECT entity_type, entity_id, action, created_at, actor_id
FROM audit_logs
WHERE entity_type IN ('BILLING_SUBSCRIPTION', 'BILLING_PLAN_CHANGE')
  AND created_at > DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY created_at DESC
LIMIT 50;
```

### 3. Verificar webhooks recebidos
```bash
# Procurar no log por webhooks do mesmo payment_id
railway logs --service api --tail 500 | grep -E "(webhook|PAYMENT_CONFIRMED|paymentId)"
```

### 4. Verificar subscription no banco
```sql
SELECT id, organization_code, status, current_period_start, current_period_end,
       asaas_subscription_id, plan_code, updated_at
FROM billing_subscriptions
WHERE organization_code = 'ORG-XXX';  -- substituir pela org afetada
```

### 5. Verificar se BillingCycleJob executou duas vezes
```sql
SELECT name, lock_until, locked_at, locked_by
FROM shedlock
WHERE name = 'BillingCycleJob';
```
Dois registros ou `locked_by` com dois hosts diferentes indica problema no ShedLock.

---

## Passos de Resolução

### Passo 1: Confirmar e documentar a duplicata
Antes de qualquer ação:
- Screenshot do painel Asaas mostrando as duas cobranças
- Anotar: `payment_id` de ambas, valor, data, `organization_code` afetada

### Passo 2: Estornar o pagamento duplicado no Asaas

**Via painel Asaas:**
1. Acessar Asaas → Cobranças
2. Localizar o pagamento duplicado (o mais recente, ou o incorreto)
3. Clicar em "Estornar" / "Reembolsar"
4. Confirmar o motivo: "Cobrança duplicada"

**Via API Asaas (se necessário):**
```bash
# Estornar pagamento via API (substituir PAYMENT_ID)
curl -X POST https://api.asaas.com/api/v3/payments/PAYMENT_ID/refund \
  -H "access_token: $ASAAS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"description": "Cobrança duplicada - estorno automático"}'
```

### Passo 3: Verificar e corrigir estado no banco
```sql
-- Confirmar que a subscription está em estado correto após estorno
SELECT id, status, current_period_start, current_period_end
FROM billing_subscriptions
WHERE organization_code = 'ORG-XXX';

-- Se status ficou inconsistente por causa da duplicata:
UPDATE billing_subscriptions
SET status = 'ACTIVE',
    updated_at = NOW()
WHERE organization_code = 'ORG-XXX'
  AND status != 'ACTIVE';  -- só atualizar se realmente necessário
```

### Passo 4: Investigar causa raiz e prevenir recorrência

**Se foi dupla submissão do frontend:**
- Verificar se debounce no botão de assinatura está funcionando
- Adicionar idempotency key na chamada ao Asaas se não existir

**Se foi webhook duplicado:**
- O Asaas reEnvia webhooks não confirmados (sem resposta 200)
- Verificar se o endpoint `/webhooks/asaas` retornou 200 corretamente
- Implementar deduplicação por `payment_id` no webhook handler se necessário

**Se foi BillingCycleJob duplicado:**
- Investigar ShedLock (ver RB-001)
- Garantir que há apenas uma instância ativa no Railway

---

## Como Comunicar o Cliente

**Contato reativo (cliente reclamou):**

Template de resposta:
> "Olá [NOME],
>
> Pedimos desculpas pelo inconveniente. Identificamos que houve uma cobrança duplicada em sua conta referente ao período de [PERÍODO]. O estorno de R$ [VALOR] já foi processado e deve aparecer em seu cartão/conta em até [3-10] dias úteis, dependendo do seu banco.
>
> Tomamos medidas para evitar que isso ocorra novamente. Se tiver qualquer dúvida ou perceber que o estorno não foi creditado no prazo, entre em contato.
>
> Atenciosamente,
> Equipe Easy Maintenance"

**Comunicação interna (Slack):**
> "BILLING: Cobrança duplicada identificada para org [ORG_CODE]. Valor: R$ [VALOR]. Estorno realizado via Asaas (payment_id: [ID]). Causa: [CAUSA]. Ação preventiva: [O QUE FOI FEITO]."

---

## Registro Obrigatório

Para fins de compliance e auditoria, registrar no sistema de tickets:
- Data e hora da descoberta
- Organização afetada (`organization_code`)
- Valor estornado
- `payment_id` da cobrança indevida e da cobrança correta
- Causa raiz identificada
- Ação corretiva tomada

---

## Prevenção

- Validar idempotency no `AsaasClient` ao criar cobranças (usar `externalReference` único)
- Deduplicar webhooks por `payment_id` antes de processar
- ShedLock já garante execução única do `BillingCycleJob` (não remover)
- Monitorar Sentry por webhooks processados duas vezes para o mesmo `payment_id`
- Revisão mensal de cobranças para detectar duplicatas não reportadas
