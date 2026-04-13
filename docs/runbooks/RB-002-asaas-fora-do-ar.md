# RB-002 — Asaas Fora do Ar

**Severidade:** Alta  
**Componente:** `AsaasClient` + Circuit Breaker `asaas`  
**Categoria:** Pagamentos / Integração Externa

---

## Configuração do Circuit Breaker `asaas`

| Parâmetro | Valor |
|-----------|-------|
| Sliding window | 10 chamadas |
| Threshold de falha | 50% |
| Espera no estado aberto | 30 segundos |
| Chamadas em half-open | 3 |
| Timeout por chamada | 10 segundos |

**Quando o circuito abre:** Após 5 falhas em 10 chamadas → Asaas não é mais chamado por 30s. Após 30s entra em half-open e testa com 3 chamadas.

---

## Sintomas

- Erros `AsaasException` nos logs / Sentry
- Novos clientes não conseguem se registrar ou assinar plano
- Tentativas de pagamento falhando (status 503 ou mensagem de "serviço indisponível")
- Log com `CircuitBreakerOpenException` ou `CallNotPermittedException` para o circuito `asaas`
- Actuator health mostra `asaas` como `DOWN`:
  ```
  GET /actuator/health
  {"status":"DOWN","components":{"circuitBreakers":{"asaas":{"state":"OPEN"}}}}
  ```
- Página de status do Asaas reportando incidente: https://status.asaas.com

---

## Causa Provável

1. **Asaas em manutenção** — verifique https://status.asaas.com
2. **Timeout de rede** — Railway sem conectividade de saída temporária
3. **API key inválida/expirada** — erro 401 do Asaas
4. **Webhook token rotacionado** — validação de webhook falhando
5. **Rate limit do Asaas** — muitas chamadas em pouco tempo (429)

---

## Passos de Diagnóstico

### 1. Verificar status do Asaas
- https://status.asaas.com — confirmar se é incidente global

### 2. Verificar health do circuit breaker
```bash
curl -s https://api.easy-maintenance.com/actuator/health | jq '.components.circuitBreakers'
```

### 3. Verificar logs de erro
```bash
railway logs --service api --tail 200 | grep -iE "(asaas|circuit|CallNotPermitted)"
```

### 4. Testar conectividade manual com Asaas (a partir do Railway shell)
```bash
curl -I -H "access_token: $ASAAS_API_KEY" \
  https://api.asaas.com/api/v3/customers?limit=1
```
- 200 → API do Asaas OK, problema no app
- 401 → API key inválida
- 503/timeout → Asaas fora do ar

### 5. Verificar Sentry
- Filtrar por tag `asaas` ou `CircuitBreakerOpenException`
- Verificar se é falha pontual ou sistêmica

---

## Passos de Resolução

### Caso A: Asaas confirmado fora do ar (status page)
1. **Não fazer nada no código** — o circuit breaker já protege o sistema
2. Acompanhar https://status.asaas.com para atualização de resolução
3. Após resolução confirmada, o circuit breaker voltará ao estado CLOSED automaticamente em até 30s
4. Se circuit não fechar automaticamente: reiniciar a aplicação no Railway

### Caso B: API key expirada / inválida
```bash
# Atualizar variável de ambiente no Railway
railway variables set ASAAS_API_KEY=nova_chave_aqui

# Redeploy automático após set de variável no Railway
```

### Caso C: Circuit aberto mas Asaas está OK (falso positivo)
```bash
# Reiniciar a aplicação para resetar o estado do circuit breaker em memória
railway redeploy --service api
```

### Caso D: Rate limit do Asaas (429)
- Verificar se há loop de chamadas inesperado nos logs
- Aguardar 1-5 minutos para o rate limit resetar
- Se persistir, contatar suporte Asaas com logs das chamadas

---

## O Que Bloquear vs Liberar Durante o Incidente

| Funcionalidade | Durante Asaas fora | Justificativa |
|---------------|-------------------|---------------|
| Novos cadastros (trial) | **Liberar** | Não depende de Asaas |
| Login e uso da plataforma | **Liberar** | Funciona offline |
| Assinar plano pago | **Bloquear** | Depende de Asaas |
| Mudança de plano | **Bloquear** | Depende de Asaas |
| Cobrança recorrente (jobs) | **Aguardar** | Jobs reprocessam no próximo dia |
| Webhooks de pagamento | **Aguardar** | Asaas reenviará quando voltar |

---

## Como Comunicar o Cliente

**Incidente curto (< 2h):**
- Não comunicar proativamente
- Se cliente reclamar: "Estamos cientes de uma instabilidade no processamento de pagamentos. Nossa equipe está acompanhando. Não há perda de dados."

**Incidente longo (> 2h):**
- Banner no dashboard ou e-mail para usuários em processo de assinatura:
  > "Nosso processador de pagamentos está passando por instabilidade. Seus dados estão seguros e você não perderá nenhum benefício. Assim que normalizar, entraremos em contato."

**Template Slack interno:**
> "INCIDENTE: Asaas fora do ar desde [HORA]. Circuit breaker `asaas` está OPEN. Novas assinaturas bloqueadas. Acompanhando status.asaas.com. ETA: [SE DISPONÍVEL]"

---

## Prevenção

- Monitorar Prometheus metric `resilience4j_circuitbreaker_state{name="asaas"}` > 0 (OPEN)
- Configurar alerta no Grafana para circuit breaker do Asaas
- Assinar updates de status do Asaas por e-mail/RSS
