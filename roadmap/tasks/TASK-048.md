# TASK-048 — PIX: exibir QR Code pendente na página de billing

## Tipo
Funcionalidade / UX

## Categoria
Frontend / Billing

## Prioridade
🔴 Crítico

## Fase
2 — Pós-lançamento

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional

## Descrição
A página de billing (`/billing`) não exibe cobranças PIX pendentes. Quando o Asaas gera uma nova cobrança mensalmente, o usuário PIX não tem onde visualizar o QR Code para pagar — precisa aguardar o e-mail do Asaas ou descobrir que foi bloqueado. Esta task implementa o card de "Pagamento PIX Pendente" na página de billing, usando o endpoint criado na TASK-046.

## Problema
- `/billing` page não consulta nem exibe pagamento pendente
- Usuário PIX não vê QR Code para pagar dentro do produto
- Sem feedback de expiração de QR Code
- Sem aviso quando cobrança vence (estado OVERDUE)
- Experiência inconsistente: cartão funciona automaticamente, PIX exige ação do usuário sem guia

## Dependências
- **TASK-046 obrigatória primeiro**: endpoint `GET /billing/subscription/pending-payment` deve existir

## Critérios de Aceite
- [x] Hook `usePendingPayment` que consulta `GET /me/billing/pending-payment`
- [x] Se há pagamento com `methodType = PIX`: exibir card "Pagamento PIX Pendente" com:
  - QR Code (imagem do `pixQrCodeBase64`)
  - String Copia e Cola (`pixQrCode`) com botão "Copiar" (Clipboard API)
  - Valor da cobrança formatado (R$)
  - Data/hora de expiração baseada em `pixExpiresAt`
- [x] Se `pixExpiresAt < now`: exibir "QR Code expirado" + botão "Solicitar novo QR Code" (link `paymentLink` Asaas)
- [x] Se `status = OVERDUE`: exibir banner de aviso em vermelho "Sua cobrança PIX venceu"
- [x] Auto-refresh a cada 30s via `refetchInterval` — card some quando `status = PAID`
- [x] Responsivo — Bootstrap col-12 col-lg-4, funcional no mobile
- [~] Botão "Alterar para Cartão de Crédito" — não implementado (fluxo de troca de método não existe no produto ainda)

## Subtasks
- [x] Criar hook `usePendingPayment` em `src/hooks/usePendingPayment.ts` com React Query + `refetchInterval: 30000`
- [x] Criar componente `PendingPixPaymentCard` em `src/components/billing/PendingPixPaymentCard.tsx`
- [x] Integrar na `/billing` page — sidebar, acima de InvoiceList
- [x] Banner OVERDUE em vermelho
- [x] Botão "Copiar" para Copia e Cola (Clipboard API com feedback visual)
- [x] Testes em `PendingPixPaymentCard.test.ts` (10 testes: isExpired, formatExpiration, canFetch)

## Esforço
Médio (6-8h)

## Risco de não fazer
Mesmo com TASK-046 e TASK-047 implementadas, o usuário PIX não tem experiência visual adequada no produto para pagar a renovação mensal.

## Status
Concluído
