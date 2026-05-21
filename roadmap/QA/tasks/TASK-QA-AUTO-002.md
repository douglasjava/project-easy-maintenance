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
- [x] `dueDate` nula E `expirationDate` nula → `pixExpiresAt` permanece `null` sem lançar exceção
- [x] `pixTransaction` presente mas `qrCode` nulo → campos PIX ficam nulos sem NPE
- [x] `pixTransaction` presente mas `encodedImage` em branco → `pixQrCodeBase64` **null** (comportamento definido: blank é tratado como ausente)
- [x] Múltiplos webhooks `PAYMENT_CREATED` PIX para a mesma subscription → cada payment salvo independentemente

### PaymentOverdueHandler — novos casos
- [x] Pagamento em estado `PAID` recebe `PAYMENT_OVERDUE` → e-mail NÃO enviado — **já coberto** por `handle_finalStatePayment_skipsUpdateAndEmail`
- [x] Pagamento com `payer` nulo → sem NPE; handler chama `sendPixOverdueEmail` normalmente (null payer é responsabilidade do serviço de notificação)
- [x] `paymentLink` nulo no Payment → e-mail enviado sem link (handler não acessa paymentLink)

### Endpoint GET /billing/pending-payment — novos casos
- [x] Nenhuma subscription → retorna `null` (sem interação com paymentRepository)
- [x] Pagamento `PENDING` presente → retorna com todos os campos PIX mapeados
- [x] Pagamento `OVERDUE` presente (sem PENDING) → retornado como resposta (exibir banner vermelho)
- [x] Nenhum pagamento (nem PENDING nem OVERDUE) → retorna `null` → controller responde 204

## Subtasks
- [x] Adicionar casos de borda em `PaymentCreatedHandlerPixTest`
- [x] Adicionar casos de borda em `PaymentOverdueHandlerPixTest`
- [x] Criar `BillingDashboardServicePendingPaymentTest`
- [ ] Verificar coverage antes e depois (meta: > 85% nas classes cobertas)

## Arquivos Criados / Modificados

| Arquivo | Operação |
|---------|----------|
| `PaymentCreatedHandler.java` | Corrigido: `isBlank()` adicionado ao guard de `encodedImage` para evitar salvar string vazia |
| `PaymentCreatedHandlerPixTest.java` | 4 novos testes de borda |
| `PaymentOverdueHandlerPixTest.java` | 2 novos testes de borda |
| `BillingDashboardServicePendingPaymentTest.java` | Criado — 4 testes unitários de serviço |

## Esforço Estimado
Pequeno (3-5h)

## Dependências
- Testes existentes nas classes mencionadas (não reescrever, apenas adicionar)

## Status
Concluido
