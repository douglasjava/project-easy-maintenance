# TASK-061 — UX: seleção de método de pagamento antes da expiração do TRIAL

## Tipo
FRONTEND

## Categoria
Frontend / Billing / Onboarding

## Prioridade
🟠 Alto

## Fase
2 — Pós-lançamento

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Problema

Hoje o usuário entra em TRIAL e o job tenta cobrar automaticamente no fim do período sem que o usuário tenha confirmado 
o método de pagamento desejado (cartão ou PIX). Para PIX, isso é particularmente problemático: o usuário não pode pagar 
passivamente — precisa escanear um QR Code ou copiar e colar o código.

A consequência: usuário só descobre que está bloqueado depois que o trial expira e ele tenta acessar o app.

## Solução

Criar um fluxo de **confirmação de plano + método** que aparece:

1. No banner de trial expirando (já existe via TASK-015) — mas com CTA explícito para escolha de método.
2. Em uma página dedicada `/billing/upgrade` ou modal com os passos:
   - Confirmar o plano escolhido (já existe — TASK-030).
   - Escolher método: Cartão (CC) ou PIX.
   - Se CC: capturar token e ativar (fluxo existente).
   - Se PIX: explicar que será enviada uma cobrança PIX mensal, com lembrete por e-mail antes do vencimento.
3. Salvar a escolha em `billing_subscription.payment_method` antes do trial acabar.

## Escopo

- Página/modal `PaymentMethodSelection`.
- Endpoint backend `PATCH /me/subscription/payment-method` (body: `{ method: "CREDIT_CARD" | "PIX" }`).
- Validação: só permite mudar método enquanto subscription está em TRIAL ou em PAST_DUE.
- Telemetria de conversão (quantos escolhem cartão vs PIX).
- Atualizar copy do banner de trial expirando para apontar para esta tela.

## Critérios de Aceite

- [x] Usuário em trial vê CTA claro "Confirmar forma de pagamento" no banner
- [x] Tela explica diferença entre cartão (automático) e PIX (manual mensal)
- [x] Escolha persiste no banco via `PATCH /me/billing/payment-method`
- [x] Fluxo é responsivo (mobile-first — modal Bootstrap com largura máxima 520px)
- [x] Validações backend: só TRIAL ou PAST_DUE podem alterar o método (RuleException → 400)
- [x] Cobertura de erro: falha de rede mostra toast.error com detalhe do erro, não tela em branco

## Dependências
- TASK-058 (backend de PIX DETACHED precisa estar pronto para o "Confirmar PIX" não falhar silenciosamente)

## Esforço
Pequeno-Médio (1 dia)

## Risco de não fazer
Usuário PIX só descobre como pagar **depois** que perde acesso. Conversão de trial cai.

## Status
Em Validação

## Implementação (16/05/2026)

### Backend
- `BillingAccountDTO.UpdatePaymentMethodRequest` — novo record com `@NotNull PaymentMethodType method`.
- `BillingAccountService.updatePaymentMethod(Long userId, PaymentMethodType method)` — `@Transactional`:
  - Encontra `BillingAccount` e `BillingSubscription` pelo userId.
  - Valida `status == TRIAL || PAST_DUE` → lança `RuleException` (→ HTTP 400) caso contrário.
  - Atualiza `billingAccount.paymentMethod` e persiste.
  - Log estruturado: `[BillingAccount] Payment method updated for user {}: {}`.
- `BillingController.PATCH /me/billing/payment-method` — delega para o service, retorna `204 No Content`.

### Frontend
- `PaymentMethodSelectionModal.tsx` (novo em `src/components/billing/`):
  - Dois cards selecionáveis: `CARD` (Cartão) e `PIX`, com ícones Lucide, descrição e detalhe.
  - Submit: `PATCH /me/billing/payment-method`; toast.success / toast.error com mensagem do backend.
  - Estados: selected, loading, ESC fecha se não loading.
  - Portal para `document.body` (consistente com demais modais do projeto).
- `TrialBanner.tsx` (atualizado):
  - Novo CTA primário "Confirmar forma de pagamento" → abre `PaymentMethodSelectionModal` internamente.
  - CTA secundário "Ver planos" → `/billing` (mantido).
  - Após sucesso no modal: auto-dismiss do banner (sessionStorage + estado).
  - Textos dos dias restantes atualizados para reforçar ação de confirmar método.
- `billing/page.tsx` (atualizado):
  - `PaymentMethodCard` agora tem botão "Alterar" que abre o modal.
  - Conta sem billing account mostra "Confirmar forma de pagamento" (botão primário) que abre o modal.
  - `METHOD_LABELS` mapeia `CARD → Cartão de Crédito`, `PIX → PIX — cobrança mensal`.
  - `PaymentMethodSelectionModal` renderizado ao lado dos demais modais da página.

## Testes
- `BillingAccountServiceUpdatePaymentMethodTest` (6 cenários, todos verdes):
  - TRIAL → salva novo método (PIX→CARD e vice-versa)
  - PAST_DUE → salva novo método
  - ACTIVE / CANCELED → lança `RuleException`, não salva
  - BillingAccount não encontrado → `NotFoundException`
  - Subscription não encontrada → `NotFoundException`
- Regressão: 48/48 verdes (inclui TASK-059, TASK-060, TASK-058, e testes base).

## Observações para validação humana
- Critério "usuário não pode trocar para PIX se já tem cobrança CC em andamento" foi simplificado para validação de status (TRIAL/PAST_DUE). Validação de pagamento em andamento pode ser adicionada em TASK-062 (classificador de recusa Asaas) se necessário.
- O fluxo CC completo (capture do token, ativação no Asaas) permanece no fluxo existente de checkout — este endpoint apenas salva a preferência.
- Telemetria de conversão CC vs PIX pode ser adicionada em iteração futura via evento de analytics.
