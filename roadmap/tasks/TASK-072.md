---
id: TASK-072
title: Exibir link de comprovante nas faturas pagas da tela /billing
type: FULL_STACK
epic: EPIC-006
priority: 🟡 Médio
status: In Progress
created: 2026-05-30
---

## Problema

A tela `/billing` exibe as faturas recentes mas não mostra o comprovante/recibo para faturas já pagas.
O campo `payment_link` na tabela `payments` serve como link de pagamento (antes do pagamento) e como
link de comprovante (após o pagamento confirmado pelo Asaas, ex: `https://sandbox.asaas.com/i/xxx`).
A tabela `invoices` não possui esse campo — ele existe apenas em `payments`.

## Impacto

Usuários que pagam via PIX não têm confirmação visual do pagamento dentro do sistema.
O recibo fecha o ciclo de feedback pós-pagamento.

## Solução

### Backend
- Adicionar `receiptUrl: String` em `BillingSummaryResponse.InvoiceSummaryDTO`
- Em `BillingDashboardService.mapInvoiceToSummary()`: para invoices com status `PAID`, buscar o
  payment mais recente com status `PAID` ou `RECEIVED` e expor seu `paymentLink` como `receiptUrl`

### Frontend
- `InvoiceList.tsx`: adicionar `receiptUrl?: string | null` ao tipo `Invoice`; para invoices PAID
  com `receiptUrl` presente, mostrar link "Ver recibo" (abre em nova aba)
- `billing/page.tsx`: adicionar `receiptUrl?: string | null` ao tipo `Invoice`

## Acceptance Criteria

- [ ] Invoice PAID com payment confirmado exibe link "Ver recibo" na lista de faturas
- [ ] Invoice OPEN/OVERDUE mantém o comportamento atual ("Pagar agora" / "Pagar")
- [ ] Invoice PAID sem payment confirmado (edge case) não exibe nenhum link (graceful)
- [ ] Link abre em nova aba (`target="_blank"`)
- [ ] Sem regressão nas faturas pendentes

## Arquivos impactados

**Backend:**
- `billing/application/dto/response/BillingSummaryResponse.java` — campo `receiptUrl`
- `billing/application/service/BillingDashboardService.java` — lógica de busca do payment PAID

**Frontend:**
- `src/components/billing/InvoiceList.tsx`
- `src/app/billing/page.tsx`
