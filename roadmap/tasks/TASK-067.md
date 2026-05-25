# TASK-067 — CTA de Geração de Cobrança PIX para Usuários PAST_DUE

## Tipo

Full-Stack

## Categoria

Billing / UX

## Prioridade

🔴 Alto

## Fase

2 — Pré-produção / Refinamento UX

## Épico

EPIC-010 — PIX como Método de Pagamento Funcional

## Descrição

Existe um gap crítico no fluxo de billing: quando o usuário com plano **TRIAL_EXPIRED** troca o método de pagamento para **PIX**, o sistema bloqueia o acesso (`isBlocked = true`) mas a tela `/billing` não oferece nenhuma ação para gerar a cobrança. O usuário fica preso sem CTA.

### Fluxo esperado

1. Usuário com `subscriptionStatus = PAST_DUE` e `paymentMethod = PIX` acessa `/billing`
2. A tela exibe um banner de alerta com botão **"Gerar cobrança PIX"**
3. O clique chama `POST /billing/generate-payment` (endpoint novo no backend)
4. O backend cria uma cobrança avulsa via Asaas e retorna a URL do QR Code / copia-e-cola
5. O frontend redireciona ou exibe o QR Code para pagamento imediato
6. Após confirmação do pagamento (webhook Asaas), o status volta para `ACTIVE`

## Problema atual

- `PastDueBanner` exibe apenas texto de aviso sem ação
- Não existe endpoint `POST /billing/generate-payment` no backend
- Usuário com PIX selecionado não tem caminho para reativar o plano

## Impacto

- **Revenue direto**: usuários bloqueados não podem pagar → churn involuntário
- **UX crítico**: usuário vê plano bloqueado sem saída clara
- **Confiança no produto**: frustração na hora do pagamento pode cancelar a conta

## Critérios de Aceite

### Backend
- [ ] Endpoint `POST /billing/generate-payment` criado e protegido (autenticação + `X-Org-Id`)
- [ ] Cria cobrança avulsa PIX via Asaas para a organização do usuário autenticado
- [ ] Retorna `{ paymentUrl: string, pixQrCode: string, pixCopyPaste: string, dueDate: string }`
- [ ] Validação: só executa se `subscriptionStatus = PAST_DUE` e `paymentMethod = PIX`
- [ ] Retorna erro `409 Conflict` se já existe cobrança pendente para o ciclo

### Frontend
- [ ] `PastDueBanner` exibe botão **"Gerar cobrança PIX"** quando `paymentMethod = PIX`
- [ ] Clique no botão chama o endpoint e exibe loading state
- [ ] Após sucesso: exibe modal/card com QR Code PIX + copia-e-cola + data de vencimento
- [ ] Em caso de erro: toast com mensagem amigável
- [ ] Botão desabilitado após geração (evita duplicação de cobranças)

## Subtasks

- [ ] Backend: criar `BillingGeneratePaymentController` (POST `/billing/generate-payment`)
- [ ] Backend: criar `BillingGeneratePaymentService` com integração Asaas
- [ ] Backend: adicionar validação de status e idempotência
- [ ] Frontend: atualizar `PastDueBanner` com CTA e lógica de estado
- [ ] Frontend: criar componente `PixPaymentModal` com QR Code + copia-e-cola
- [ ] Frontend: integrar hook `useBillingGeneratePayment`
- [ ] QA: testar cenário PAST_DUE + PIX → geração de cobrança → pagamento confirmado

## Arquivos afetados

**Backend:**
- `src/main/java/com/easymaintenance/billing/controller/BillingGeneratePaymentController.java` (novo)
- `src/main/java/com/easymaintenance/billing/service/BillingGeneratePaymentService.java` (novo)

**Frontend:**
- `src/components/billing/PastDueBanner.tsx`
- `src/components/billing/PixPaymentModal.tsx` (novo)
- `src/hooks/useBillingGeneratePayment.ts` (novo)

## Esforço

Médio (2–3 dias)

## Risco de não fazer

- Usuários com PIX não conseguem reativar o plano após bloqueio → churn involuntário
- Deterioração da percepção de confiabilidade do produto no momento mais crítico (pagamento)

## Status

TODO
