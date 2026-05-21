# TASK-065 — Frontend: tela "Atualizar método de pagamento" para subscriptions PAST_DUE

## Tipo
FRONTEND

## Categoria
Frontend / Billing / UX de Recuperação

## Prioridade
🟠 Alto

## Fase
2 — Pós-lançamento

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Problema

Quando uma renovação falha (cartão recusado, PIX vencido, consentimento revogado no futuro Pix Automático), 
o usuário precisa de um caminho **óbvio** e **rápido** para resolver. Hoje não existe uma tela dedicada — 
o usuário fica numa zona cinzenta entre "tem acesso" e "perdeu acesso", sem saber o que fazer.

## Solução

Criar `/billing/recover` (ou modal):

1. Visível para subscriptions em `PAST_DUE`.
2. Mostra:
   - Motivo da falha (humanizado, vindo do classificador da TASK-062).
   - Valor + data da próxima tentativa (se houver) ou data limite até suspensão.
   - CTA principal: "Atualizar método de pagamento" → reaproveita a tela de TASK-061.
   - CTA secundário: "Pagar agora via PIX avulso" → gera cobrança PIX imediata.
3. Acessível via banner persistente até o problema ser resolvido.

## Escopo

- Página/rota `/billing/recover`.
- Componente `PaymentFailureSummary` reutilizável.
- Endpoint backend `GET /me/subscription/payment-failure` que retorna o último motivo de falha + bucket (depende da TASK-062 estar pronta para enriquecer essa resposta).
- Banner global mostrado quando subscription está em PAST_DUE.

## Critérios de Aceite

- [x] Banner persistente quando subscription está em PAST_DUE
- [x] Tela mostra motivo humanizado e prazo até suspensão
- [x] CTA "Atualizar método" leva ao fluxo da TASK-061
- [x] CTA "Pagar agora via PIX" exibe QR code do pagamento PIX pendente (se houver)
- [x] Responsivo (mobile-first via Bootstrap container)
- [ ] Testes E2E: PAST_DUE → recover → atualizar método → ACTIVE

## Dependências
- TASK-061 (tela de seleção de método precisa existir)
- TASK-062 (classificador para humanizar o motivo)

## Esforço
Médio (1 dia)

## Risco de não fazer
Usuário fica em PAST_DUE sem entender o que fazer. Churn evitável.

## Implementação

### Arquivos criados
- `components/billing/PastDueBanner.tsx` — banner persistente (não dismissível) mostrado no dashboard quando `subscriptionStatus === "PAST_DUE"`; link direto para `/billing/recover`
- `app/billing/recover/page.tsx` — página de recuperação: busca `GET /me/billing/payment-failure`, exibe motivo humanizado por bucket (TRANSIENT / USER_ACTION / HARD_FAIL / INFO / UNKNOWN), CTA "Atualizar método" abre `PaymentMethodSelectionModal`, exibe `PendingPixPaymentCard` se houver PIX pendente

### Arquivos modificados
- `app/page.tsx` — adicionado `import { PastDueBanner }` + `isPastDue` + render condicional `{isPastDue && <PastDueBanner />}`
- `billing/application/dto/BillingAccountDTO.java` — adicionado record `PaymentFailureResponse(failureReason, bucket, failedAt)`
- `billing/application/service/BillingAccountService.java` — injetado `PaymentRepository` + `RefusalReasonClassifier`; adicionado `getLastPaymentFailure(Long userId)`
- `billing/infrastructure/web/BillingController.java` — adicionado `GET /payment-failure`
- `BillingAccountServiceUpdatePaymentMethodTest.java` — adicionados `@Mock PaymentRepository` e `@Mock RefusalReasonClassifier`

### Testes criados
- `billing/application/service/BillingAccountServiceGetPaymentFailureTest.java` — 5 cenários: sem subscription, sem pagamento FAILED, com motivo + bucket, razão nula → UNKNOWN, updatedAt nula → failedAt nulo

### Resultado dos testes
- 360/360 testes backend green ✅
- TypeScript: sem novos erros (2 erros em test files pré-existentes)

## Status
Em Validação
