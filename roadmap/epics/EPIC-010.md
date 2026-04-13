# EPIC-010 — PIX como Método de Pagamento Funcional

## Status
Concluído ✅ — 3/3 tasks entregues (SPRINT-06 concluída em 12/04/2026)

## Objetivo
Tornar o PIX um método de pagamento completamente funcional para assinaturas recorrentes — da seleção no onboarding até a exibição do QR Code mensal na página de billing.

## Descrição
A UI do Easy Maintenance já oferece PIX como opção de pagamento e a infraestrutura backend já tem o mapeamento correto para o Asaas. O problema é que o fluxo quebra silenciosamente a partir do segundo mês: o Asaas gera uma nova cobrança PIX a cada ciclo e envia os dados via webhook (`PAYMENT_CREATED`), mas o handler não captura o QR Code, a entidade `Payment` já possui os campos `pix_qr_code` e `pix_qr_code_base64` porém nunca são populados, e a página de billing não exibe nenhuma cobrança pendente para o usuário PIX. O resultado é que após 3 dias o `SubscriptionBlockingJob` bloqueia a assinatura sem que o usuário saiba que precisava pagar.

## Impacto no Produto
- **Sem este épico:** Usuário seleciona PIX no onboarding, paga o primeiro mês, no segundo mês a assinatura é bloqueada silenciosamente. Perda de revenue e experiência péssima.
- **Com este épico:** PIX funciona end-to-end como prometido na UI. Renovações mensais exibem QR Code diretamente no billing. Usuário recebe e-mail de lembrete antes do bloqueio. Taxa de churn por PIX reduz significativamente.

## Contexto Técnico
- `Payment` entity: campos `pixQrCode` (TEXT) e `pixQrCodeBase64` (MEDIUMTEXT) já existem no banco — criados na V31
- `PaymentOverdueHandler` já existe e marca como OVERDUE — falta apenas o envio de e-mail
- Faltam: `pix_expires_at` na tabela, população dos campos no webhook handler, endpoint de pending payment, e UI no billing
- Modalidade Asaas escolhida: **PIX via Assinatura** (QR Code dinâmico por ciclo) — não PIX Automático

## Tasks Relacionadas

| ID | Título | Prioridade | Fase |
|----|--------|-----------|------|
| TASK-046 | PIX: popular QR Code e expiração nas cobranças recorrentes | 🔴 Crítico | 2 |
| TASK-047 | PIX: e-mail de lembrete no PAYMENT_OVERDUE | 🟠 Alto | 2 |
| TASK-048 | PIX: exibir QR Code pendente na página de billing | 🔴 Crítico | 2 |

## Critério de Conclusão do Épico
- [ ] Webhook `PAYMENT_CREATED` com `billingType=PIX` popula `pixQrCode`, `pixQrCodeBase64` e `pixExpiresAt` em `Payment`
- [ ] Endpoint `GET /billing/subscription/pending-payment` retorna dados PIX quando há cobrança pendente
- [ ] Página de billing exibe QR Code + Copia e Cola + countdown de expiração para pagamentos PIX pendentes
- [ ] E-mail de lembrete enviado ao usuário quando cobrança PIX vence (`PAYMENT_OVERDUE`)
- [ ] Usuário PIX consegue renovar assinatura mensalmente sem contato com suporte
