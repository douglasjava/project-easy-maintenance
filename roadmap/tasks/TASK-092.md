# TASK-092 — Backend: Trigger de comissão no PaymentReceivedHandler

## Tipo
BACKEND

## Épico
EPIC-012 — Sistema de Indicação

## Prioridade
🔴 Crítico

## Fase
3 — Divulgação / Pós-Lançamento

## Descrição
Modificar `PaymentReceivedHandler` para disparar `CommissionService.createCommission()` quando `payment.cycleNumber == 1` e a organização pagadora tem `referralCode` definido e o afiliado está `ACTIVE`.

**Caminho de navegação:**
`payment → billingSubscription → BillingSubscriptionItemRepository.findAllByBillingSubscriptionId() → item.sourceType=ORGANIZATION → OrganizationRepository.findByCode(item.sourceId) → organization.referralCode → AffiliateRepository.findByCode(referralCode) → CommissionService.createCommission()`

**Regras:**
- `cycleNumber != 1` → no-op (retorna sem fazer nada)
- `organization.referralCode == null` → no-op
- `affiliate.status != ACTIVE` → no-op
- Idempotência garantida pelo `CommissionService` (UNIQUE constraint em `organization_id`)

## Critérios de Aceite
- [ ] Primeiro pagamento (cycleNumber=1) com `referralCode` cria comissão `PENDING`
- [ ] Segundo pagamento (cycleNumber=2) não cria nova comissão
- [ ] Afiliado `INACTIVE` não gera comissão
- [ ] Ausência de `referralCode` não gera erro, apenas no-op
- [ ] Testes: PaymentReceivedHandlerCommissionTest (2 cenários mínimo)
- [ ] Regressão: testes existentes do `PaymentReceivedHandler` continuam passando

## Esforço
Pequeno (2-3h)

## Status
Em Validação

## Dependências
TASK-090
