# TASK-046 — PIX: popular QR Code e expiração nas cobranças recorrentes

## Tipo
Bug / Funcionalidade Core

## Categoria
Backend / Billing / Webhook

## Prioridade
🔴 Crítico

## Fase
2 — Pós-lançamento

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional

## Descrição
Quando o Asaas gera uma cobrança PIX recorrente (ciclo mensal da assinatura), envia um webhook `PAYMENT_CREATED` contendo os dados do QR Code dinâmico. O `PaymentCreatedHandler` atual não extrai esses dados — os campos `pixQrCode` e `pixQrCodeBase64`, que já existem na tabela `payments` desde a V31, nunca são populados. Também não existe o campo `pix_expires_at` para armazenar a data de expiração do QR Code, nem o endpoint que o frontend usa para exibir a cobrança pendente.

## Problema
- `AsaasDTO.PaymentObject` não tem campos para `pixTransaction` (QR Code payload e imagem base64)
- `PaymentCreatedHandler` não popula `pixQrCode`, `pixQrCodeBase64` mesmo com campos existindo na entidade
- Tabela `payments` não tem `pix_expires_at` (coluna nova necessária)
- Não existe endpoint `GET /billing/subscription/pending-payment` para o frontend consultar

## Impacto
Usuário PIX não consegue pagar a renovação mensal dentro do app. Assinatura é bloqueada silenciosamente após 3 dias.

## Dependências
- V31 migration já criou `pix_qr_code` e `pix_qr_code_base64` — não recriar

## Critérios de Aceite
- [x] Migration `V58__payment_pix_expires_at.sql`: adicionar coluna `pix_expires_at TIMESTAMP NULL DEFAULT NULL` à tabela `payments`
- [x] `Payment.java`: adicionar campo `pixExpiresAt` (`Instant`, `@Column(name = "pix_expires_at")`)
- [x] `AsaasDTO.PaymentObject`: adicionar record `PixTransaction` com `qrCode.payload` (String) e `qrCode.encodedImage` (String), e campo `pixTransaction` no `PaymentObject`
- [x] `PaymentCreatedHandler`: se `billingType == "PIX"` e `pixTransaction != null`, setar `pixQrCode`, `pixQrCodeBase64` e `pixExpiresAt` (derivado de `dueDate`)
- [x] `PaymentResponse.java`: incluir `pixExpiresAt` já que `pixQrCode` e `pixQrCodeBase64` já estão no record
- [x] Endpoint `GET /billing/pending-payment` (novo, autenticado): retorna o `Payment` mais recente com `status = PENDING` ou `OVERDUE` da subscription ativa do usuário

## Subtasks
- [x] Migration V58 com coluna `pix_expires_at`
- [x] Atualizar `Payment.java` com novo campo
- [x] Adicionar `PixTransaction` + `PixQrCode` records no `AsaasDTO`
- [x] Atualizar `PaymentCreatedHandler` para popular campos PIX
- [x] Criar endpoint `GET /billing/pending-payment`
- [x] Testes unitários no handler (5 testes: happy path, sem expirationDate, sem pixTransaction, CREDIT_CARD)

## Esforço
Pequeno-Médio (4-6h)

## Risco de não fazer
PIX prometido na UI nunca funciona para renovações. Perda de revenue por churn de usuários PIX.

## Status
Concluído
