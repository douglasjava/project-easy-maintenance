# RB-004 — OpenAI / DeepSeek Quota Esgotada ou Indisponível

**Severidade:** Média (funcionalidade de IA é opcional — core do produto não é afetado)  
**Componente:** `AiService` + Circuit Breaker `ai` + `FallbackAiProvider`  
**Categoria:** IA / Integração Externa

---

## Arquitetura de IA do Easy Maintenance

```
AiService (@CircuitBreaker "ai")
    ↓
FallbackAiProvider
    ├─ Tenta DeepSeek primeiro (deepseek-chat, https://api.deepseek.com)
    └─ Fallback para OpenAI (gpt-4o-mini) se DeepSeek falhar
        └─ Se ambos falharem → IAException → resposta retorna com usedAi=false
```

**Rate limit da aplicação:** 60 chamadas de IA por usuário por hora (Bucket4j)

---

## Configuração do Circuit Breaker `ai`

| Parâmetro | Valor |
|-----------|-------|
| Sliding window | 5 chamadas |
| Threshold de falha | 50% |
| Espera no estado aberto | 60 segundos |
| Chamadas em half-open | 2 |

**Quando o circuito abre:** Após 3 falhas em 5 chamadas → IA não é chamada por 60s.

---

## Sintomas

- Respostas de IA retornando `usedAi: false` no payload JSON
- Erros `IAException` no Sentry
- Log com `CircuitBreakerOpenException` para o circuito `ai`
- Usuários relatando que o assistente de IA não responde ou retorna mensagem de erro
- Health check do circuit breaker `ai` em OPEN:
  ```bash
  GET /actuator/health → "ai": {"state": "OPEN"}
  ```
- E-mail de quota esgotada da OpenAI ou DeepSeek na caixa do responsável técnico

---

## Causa Provável

1. **Quota mensal da OpenAI esgotada** — limite de tokens/mês atingido
2. **Quota mensal do DeepSeek esgotada** — ambos falhando em cascata
3. **API key OpenAI/DeepSeek inválida ou expirada**
4. **Instabilidade do DeepSeek** — serviço fora do ar
5. **Instabilidade da OpenAI** — serviço fora do ar (https://status.openai.com)
6. **Rate limit por minuto/hora** dos provedores (429) por spike de uso

---

## Passos de Diagnóstico

### 1. Verificar health do circuit breaker
```bash
curl -s https://api.easy-maintenance.com/actuator/health | jq '.components.circuitBreakers.ai'
```

### 2. Verificar Sentry para tipo de erro
- Filtrar por `IAException` ou `CallNotPermittedException`
- O stack trace indicará qual provedor falhou (DeepSeek ou OpenAI) e o HTTP status code

### 3. Verificar logs do app
```bash
railway logs --service api --tail 300 | grep -iE "(IAException|deepseek|openai|circuit.*ai)"
```

### 4. Verificar quota no painel dos provedores
- **OpenAI:** https://platform.openai.com/usage — verificar `Usage this month`
- **DeepSeek:** https://platform.deepseek.com — verificar billing/usage
- Status OpenAI: https://status.openai.com
- Status DeepSeek: https://status.deepseek.com (se disponível)

### 5. Testar API key diretamente
```bash
# Testar OpenAI
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"ping"}],"max_tokens":5}'

# Testar DeepSeek
curl https://api.deepseek.com/chat/completions \
  -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"ping"}],"max_tokens":5}'
```

---

## Passos de Resolução

### Caso A: Quota OpenAI esgotada
1. Acessar https://platform.openai.com/billing → `Add to credit balance`
2. Recarregar créditos ou aumentar o limite mensal
3. O circuit breaker voltará ao normal automaticamente após 60s de resolução

### Caso B: Quota DeepSeek esgotada
1. Acessar https://platform.deepseek.com → Billing → recarregar
2. O fallback para OpenAI funciona automaticamente se DeepSeek falhar e OpenAI estiver OK

### Caso C: API key inválida / expirada
```bash
# Gerar nova API key no painel do provedor
# Atualizar no Railway:
railway variables set SPRING_AI_OPENAI_API_KEY=nova_chave
# ou
railway variables set SPRING_AI_DEEPSEEK_API_KEY=nova_chave
```

### Caso D: Instabilidade temporária do provedor
- O circuit breaker já protege o sistema
- `usedAi: false` é retornado — o app funciona sem IA
- Aguardar resolução do provedor (verificar status page)
- Circuit voltará ao CLOSED automaticamente após 60s quando provedor recuperar

### Caso E: Circuit aberto mas provedores OK (falso positivo)
```bash
# Reiniciar aplicação para resetar estado em memória do circuit breaker
railway redeploy --service api
```

---

## Comportamento da Aplicação com IA Indisponível

O Easy Maintenance foi desenhado para degradar graciosamente:

| Funcionalidade | Comportamento sem IA |
|---------------|---------------------|
| `POST /ai/summary` | Retorna `{"usedAi": false, "summary": null}` — sem erro 500 |
| `POST /ai/assistant` | Retorna resposta vazia com `usedAi: false` |
| `POST /ai/suggest-item` | Retorna lista vazia de sugestões |
| Dashboard, listagens | **Não afetado** — funciona normalmente |
| Billing, relatórios | **Não afetado** — funciona normalmente |

**Impacto:** Usuários de planos com `aiEnabled: true` ficam temporariamente sem funcionalidades de IA. Não há perda de dados.

---

## Como Comunicar o Cliente

**Interrupção curta (< 1h, circuito abrindo e fechando):**
- Não comunicar proativamente
- O app já mostra degradação graciosamente

**Interrupção longa (> 1h) ou quota esgotada:**
- Template para clientes com plano IA:
  > "O assistente de IA do Easy Maintenance está temporariamente indisponível por instabilidade em nosso provedor de IA. Todas as outras funcionalidades estão operando normalmente. Resolução prevista: [ETA ou 'Em investigação']."

**Template Slack interno:**
> "INCIDENTE IA: Circuit breaker `ai` OPEN desde [HORA]. Causa: [quota/API key/instabilidade]. Provedor: [DeepSeek/OpenAI/ambos]. Impacto: usuários com AI plan sem resposta de IA. Ação: [recarregar quota/trocar chave]. ETA: [ETA]"

---

## Prevenção

- Configurar alertas de billing nos painéis da OpenAI e DeepSeek (e-mail ao atingir 80% da quota)
- Monitorar Prometheus metric `resilience4j_circuitbreaker_state{name="ai"}` > 0
- Revisar quota mensalmente — o uso escala conforme crescimento de usuários AI-enabled
- Rate limit do app (60 chamadas/usuário/hora) já protege contra uso abusivo de um único tenant
