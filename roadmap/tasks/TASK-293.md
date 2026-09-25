# TASK-293 — Trial: tela de onboarding diz "7 dias grátis", sistema concede 14

## Tipo
BUGFIX (Frontend — copy; checar backend)

## Prioridade
🟠 Alto — promessa comercial divergente na tela de cadastro

## Contexto
Levantado na atualização dos documentos de produto (25/09/2026). Decisão do Douglas: **o trial é
de 14 dias** (documentos comerciais, landing e `OnboardingService.createUser` →
`createTrial(savedAccount, Duration.ofDays(14))`).

Divergências encontradas:
- `easy-maintenance-web/src/app/onboarding/page.tsx`: "7 dias grátis — plano Business completo"
  (passo 1) e "Sua empresa entra direto no plano Business por 7 dias" (passo 2); o payload do passo
  2 também calcula `currentPeriodEnd`/`trialEndsAt` com +7 dias (conferir se o backend usa esses
  campos ou ignora).
- Backend: existe outro `createTrial(account, Duration.ofDays(7))` — identificar o fluxo (ex.:
  criação de organização fora do onboarding) e alinhar com os 14 dias se for trial de cliente novo.

## Critérios de Aceite
- [ ] Toda menção de duração do trial nas telas diz 14 dias
- [ ] Todo trial de cliente novo é criado com 14 dias (ou divergência justificada e documentada)
- [ ] Teste cobrindo a duração do trial

## Status
Backlog
