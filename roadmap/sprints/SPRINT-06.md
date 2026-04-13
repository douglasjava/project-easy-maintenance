# SPRINT-06 — PIX como Método de Pagamento Funcional

> **Período:** Semana 13–14 (estimado)
> **Objetivo:** Fechar o gap de PIX recorrente — da captura do QR Code no webhook até a exibição no billing, com notificação de vencimento
> **Capacidade estimada:** 3 tasks
> **Critério de saída:** Usuário PIX consegue pagar renovações mensais dentro do produto sem contato com suporte

---

## Meta da Sprint

> "Ao final desta sprint, PIX funciona end-to-end: o QR Code mensal aparece na página de billing, o usuário recebe e-mail quando a cobrança vence, e a assinatura nunca é bloqueada por falta de visibilidade do pagamento."

---

## Contexto

A UI já oferece PIX no onboarding e a infraestrutura backend já tem o mapeamento correto para o Asaas (`billingType: PIX`). O primeiro pagamento (via hosted checkout) já funciona. O problema está nas **renovações mensais**: o Asaas gera uma nova cobrança PIX a cada ciclo mas o sistema não captura o QR Code nem exibe para o usuário. Resultado: assinatura bloqueada silenciosamente após 3 dias.

A tabela `payments` já tem `pix_qr_code` e `pix_qr_code_base64` desde a V31. O `PaymentOverdueHandler` já existe. O gap é pequeno e bem delimitado.

---

## Tasks da Sprint

---

### 🔴 TASK-046 — PIX: popular QR Code e expiração nas cobranças recorrentes
**Arquivo:** [TASK-046.md](../tasks/TASK-046.md)
**Épico:** EPIC-010 — PIX como Método de Pagamento Funcional

**Objetivo nesta sprint:** Capturar os dados PIX do webhook Asaas e expô-los via endpoint para o frontend consumir.

**Por que está na Sprint 6:**
É a fundação técnica das demais tasks de PIX. Sem os dados PIX persistidos e o endpoint disponível, TASK-047 e TASK-048 não têm dados para trabalhar.

**Dependências:** Nenhuma — campos `pix_qr_code` e `pix_qr_code_base64` já existem na tabela `payments`

**Como validar:**
- [ ] Envio de webhook `PAYMENT_CREATED` com `billingType=PIX` popula `pixQrCode`, `pixQrCodeBase64` e `pixExpiresAt` no Payment
- [ ] Campos NULL para pagamentos com `billingType=CREDIT_CARD`
- [ ] `GET /billing/subscription/pending-payment` retorna Payment pendente com campos PIX preenchidos

**Área impactada:** Backend (AsaasDTO, PaymentCreatedHandler, Payment entity, novo endpoint)

**Esforço:** 4-6h

---

### 🟠 TASK-047 — PIX: e-mail de lembrete no PAYMENT_OVERDUE
**Arquivo:** [TASK-047.md](../tasks/TASK-047.md)
**Épico:** EPIC-010 — PIX como Método de Pagamento Funcional

**Objetivo nesta sprint:** Notificar proativamente o usuário PIX quando a cobrança vence, antes do bloqueio.

**Por que está na Sprint 6:**
`PaymentOverdueHandler` já existe, é um incremento pequeno. Sem notificação, o usuário PIX descobre que foi bloqueado apenas quando tenta usar o sistema.

**Dependências:** TASK-046 (para ter o `paymentLink` disponível no e-mail)

**Como validar:**
- [ ] E-mail recebido pelo usuário PIX com valor, data e link de pagamento quando cobrança vence
- [ ] E-mail NÃO enviado para cartão de crédito (que é cobrado automaticamente)
- [ ] E-mail NÃO reenviado se payment já em estado final (PAID, REFUNDED)

**Área impactada:** Backend (PaymentOverdueHandler, EmailService/BillingNotificationService, template e-mail)

**Esforço:** 2-4h

---

### 🔴 TASK-048 — PIX: exibir QR Code pendente na página de billing
**Arquivo:** [TASK-048.md](../tasks/TASK-048.md)
**Épico:** EPIC-010 — PIX como Método de Pagamento Funcional

**Objetivo nesta sprint:** Dar visibilidade completa ao usuário PIX na página de billing para pagar a renovação mensal sem precisar sair do produto.

**Por que está na Sprint 6:**
Sem a interface visual, mesmo com TASK-046 e TASK-047 entregues, o usuário PIX ainda não consegue pagar dentro do app.

**Dependências:** TASK-046 obrigatória (endpoint de pending payment)

**Como validar:**
- [ ] Card "Pagamento PIX Pendente" aparece na `/billing` quando há cobrança PENDING com metodType=PIX
- [ ] QR Code visível + Copia e Cola com botão copiar
- [ ] Countdown de expiração funcional
- [ ] Card desaparece automaticamente quando pagamento é confirmado (auto-refresh 30s)
- [ ] Banner de aviso exibido para estado OVERDUE
- [ ] Responsivo no mobile

**Área impactada:** Frontend (billing/page.tsx, novo componente PendingPixPaymentCard, hook usePendingPayment)

**Esforço:** 6-8h

---

## Ordem de Execução

```
TASK-046 (backend fundação)
    ↓
TASK-047 (backend e-mail — pode ser paralelo com 048 após 046)
TASK-048 (frontend — depende do endpoint de 046)
```

---

## Definition of Done (DoD) desta Sprint

Para marcar uma task como concluída:
- [ ] Código implementado e revisado
- [ ] Sem regressão no fluxo de cartão de crédito
- [ ] Testes unitários adicionados para a mudança
- [ ] PIX testado com webhook simulado (Asaas sandbox)
- [ ] Task movida para "Concluído" no kanban

---

## Backlog da Sprint (para Sprint posterior)

- PIX Automático (Open Finance) — futuro, quando adoção bancária aumentar
- TASK-025 — Fila/retry para envio de e-mails (reforça confiabilidade do e-mail de TASK-047)
- TASK-026 — Testes de integração billing e auth

---

## Status da Sprint

**Concluída em:** 12/04/2026

| Task | Status | Observação |
|------|--------|-----------|
| TASK-046 | ✅ Concluída | V58 migration, AsaasDTO PixTransaction, handler, endpoint, 5 testes |
| TASK-047 | ✅ Concluída | EmailTemplateHelper, BillingNotificationService, PaymentOverdueHandler, 5 testes |
| TASK-048 | ✅ Concluída | usePendingPayment hook, PendingPixPaymentCard, integração billing page, 10 testes |

---

## Retrospectiva

**O que funcionou bem:**
- Gap bem delimitado: campos já existiam na DB desde V31, só faltava popular
- Handler existente (`PaymentOverdueHandler`) precisou de incremento mínimo
- Endpoint 204 No Content (em vez de 404) foi a escolha correta para "sem pagamento pendente"
- Hook com `refetchInterval: 30s` garante que o card desaparece automaticamente após confirmação

**Desvios do planejado:**
- Botão "Alterar para Cartão de Crédito" não implementado (fluxo de troca de método não existe no produto ainda)
- Audit log via `AuditService` não implementado para TASK-047 (enum não tem ação customizada; logs cobre o caso)

**Próximos passos:**
- TASK-025: Fila/retry para envio de e-mails (aumenta confiabilidade do e-mail de TASK-047)
- TASK-026: Testes de integração billing e auth
