# FLOW-003 — PIX End-to-End Recorrente

## Criticidade
🔴 CRITICAL

## Launch Relevance
Revenue direto — usuários PIX que não conseguem pagar a renovação cancelam ou fazem chargeback silencioso.

## Tasks Relacionadas
- TASK-046 — PIX: popular QR Code e expiração nas cobranças recorrentes
- TASK-047 — PIX: e-mail de lembrete no PAYMENT_OVERDUE
- TASK-048 — PIX: exibir QR Code pendente na página de billing

## Descrição do Fluxo

1. Asaas gera nova cobrança mensal PIX e envia webhook `PAYMENT_CREATED`
2. `PaymentCreatedHandler` popula `pixQrCode`, `pixQrCodeBase64`, `pixExpiresAt` na entidade `Payment`
3. Frontend consulta `GET /billing/pending-payment` (a cada 30s via `refetchInterval`)
4. Card "Pagamento PIX Pendente" exibe QR Code + Copia e Cola + countdown
5. Quando Asaas envia `PAYMENT_OVERDUE`, `PaymentOverdueHandler` envia e-mail ao usuário
6. Quando pagamento é confirmado (`PAYMENT_RECEIVED`), frontend detecta ausência de pending → card desaparece

## Camadas Impactadas
- **Backend:** `PaymentCreatedHandler`, `PaymentOverdueHandler`, `BillingNotificationService`, `EmailTemplateHelper`, endpoint `GET /billing/pending-payment`
- **Frontend:** `usePendingPayment` hook, `PendingPixPaymentCard` componente, `/billing` page
- **Infra:** Asaas webhook, tabela `payments` (campos PIX)

## Cenários Críticos

| Cenário | Tipo | Cobertura Atual |
|---------|------|----------------|
| Webhook PAYMENT_CREATED PIX popula campos QR Code | Backend | Unitário — 5 testes (TASK-046) |
| PAYMENT_CREATED CREDIT_CARD não popula campos PIX | Regressão | Unitário (TASK-046) |
| Card aparece em /billing com QR Code válido | Frontend | Manual (TASK-048 critérios) |
| Copia e Cola funcional | Frontend | Manual |
| Countdown de expiração correto | Frontend | Unitário — 10 testes (TASK-048) |
| E-mail enviado no PAYMENT_OVERDUE (PIX) | Backend | Unitário — 5 testes (TASK-047) |
| E-mail NÃO enviado para CREDIT_CARD | Regressão | Unitário (TASK-047) |
| Card desaparece após pagamento confirmado (auto-refresh 30s) | Frontend | Manual |
| QR Code expirado → mensagem + link externo | Edge case | Unitário (TASK-048) |
| Responsivo no mobile (≤ 375px) | UX | Manual |
| Múltiplos pagamentos PENDING → exibir o mais recente | Edge case | Não coberto |

## Validação Recomendada
- **Manual:** [MTD-003](../MTD/MTD-003.md) — com sandbox Asaas
- **Automatizada:** [TASK-QA-AUTO-002](../tasks/TASK-QA-AUTO-002.md) — casos de borda unitários

## Gaps
- Comportamento com 2+ pagamentos PENDING simultâneos (edge case Asaas)
- Teste de integração do endpoint `/billing/pending-payment` com TestContainers
- Teste E2E do auto-refresh (card sumindo após 30s)

## Status de Validação
- [x] Unitários TASK-046: 5 testes (handler)
- [x] Unitários TASK-047: 5 testes (e-mail overdue)
- [x] Unitários TASK-048: 10 testes (componente)
- [ ] Teste manual E2E com sandbox Asaas (MTD-003)
- [ ] Casos de borda adicionais (TASK-QA-AUTO-002)
