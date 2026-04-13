# TASK-QA-AUTO-002 — Testes Unitários: Handler PIX e PAYMENT_OVERDUE (Casos de Borda)

## Tipo
QA Automatizada — Unitário

## Categoria
Billing / PIX / Backend

## Prioridade
🟠 Alto

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional

## Flow relacionado
[FLOW-003](../Flow/FLOW-003.md)

## Descrição
Expandir a cobertura dos testes unitários existentes no `PaymentCreatedHandler` e `PaymentOverdueHandler` para cobrir casos de borda identificados na análise de QA. Os 10 testes existentes cobrem o happy path — esta task adiciona os cenários que podem causar comportamento inesperado em produção.

## Justificativa para Automatização
- PIX é um fluxo novo de alta criticidade e revenue direto
- Casos de borda com dados nulos (expiração nula, pixTransaction ausente) podem causar NPE silencioso
- Múltiplos pagamentos pendentes é um caso realista em caso de falha do Asaas
- Baixo esforço, alto valor de proteção

## Tecnologias
- JUnit 5 + Mockito
- `@ExtendWith(MockitoExtension.class)`
- Complementa os testes existentes em `PaymentCreatedHandlerTest` e `PaymentOverdueHandlerPixTest`

## Cobertura Esperada

### PaymentCreatedHandler — novos casos
- [ ] `dueDate` nula → `pixExpiresAt` permanece `null` sem lançar exceção
- [ ] `pixTransaction` presente mas `qrCode` nulo → campos PIX ficam nulos sem NPE
- [ ] `pixTransaction` presente mas `encodedImage` vazia → `pixQrCodeBase64` salvo como null ou empty (definir comportamento esperado)
- [ ] Múltiplos webhooks `PAYMENT_CREATED` PIX para a mesma subscription → cada payment salvo independentemente

### PaymentOverdueHandler — novos casos
- [ ] Pagamento em estado `PAID` recebe `PAYMENT_OVERDUE` → e-mail NÃO enviado (já em estado final)
- [ ] Pagamento com `payer` nulo → sem NPE, log de warn emitido
- [ ] `paymentLink` nulo no Payment → e-mail enviado mas sem link (ou com mensagem fallback)

### Endpoint GET /billing/pending-payment — novos casos
- [ ] Múltiplos pagamentos `PENDING` para a mesma subscription → retorna o mais recente (por `created_at DESC`)
- [ ] Nenhum pagamento pendente → HTTP 204 No Content (comportamento documentado na TASK-046)
- [ ] Pagamento `OVERDUE` presente → retorna como pendente (exibir banner vermelho)

## Subtasks
- [ ] Adicionar casos de borda em `PaymentCreatedHandlerTest`
- [ ] Adicionar casos de borda em `PaymentOverdueHandlerPixTest`
- [ ] Criar `PendingPaymentEndpointTest` ou adicionar ao controller test existente
- [ ] Verificar coverage antes e depois (meta: > 85% nas classes cobertas)

## Esforço Estimado
Pequeno (3-5h)

## Dependências
- Testes existentes nas classes mencionadas (não reescrever, apenas adicionar)

## Status
Pendente — prioridade alta pós-launch
