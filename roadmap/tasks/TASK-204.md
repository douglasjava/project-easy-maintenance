# TASK-204 — Backend: alerta quando falha a criação do cliente Asaas

## Tipo
BACKEND

## Categoria
Billing / Onboarding — Observabilidade

## Prioridade
🟠 Alto

## Épico
[EPIC-002](../epics/EPIC-002.md) — Confiabilidade Operacional

## QA obrigatório
Sim — QA manual: forçar falha na criação do cliente Asaas (ex.: CPF inválido no onboarding, mesmo
cenário do Ricardo) e confirmar que o evento aparece no Sentry; forçar falha no
`ExternalCustomerSyncJob` (via endpoint admin `POST /admin/billing/external-customer-sync` com uma
conta propositalmente quebrada) e confirmar captura também.

---

## Contexto

O caso do Ricardo Cerqueira (25/08/2026) só foi descoberto porque Douglas lembrava de ter visto o
erro passar no log bruto da plataforma de deploy — não porque algum alerta avisou. Dois pontos do
código hoje engolem falha de criação de cliente Asaas com só `log.warn`/`log.error`, sem nenhuma
captura estruturada:

- `OnboardingService.createUser` (linha ~66-69) — catch genérico ao redor de
  `providerFactory.get(ASAAS).createExternalCustomer(customer)`, por design (não deve travar o
  onboarding se a Asaas falhar) — mas hoje não avisa ninguém quando isso acontece.
- `ExternalCustomerSyncService.syncMissingExternalCustomerIds` (linha ~43-46) — mesma falha, dentro
  do loop do job diário; só loga `log.error` quando `failure > 0` no fim, sem detalhe por conta.

O projeto já usa Sentry ativamente (`SentryConfigTest`, filtros `SentryUserFilter`/
`SentryTracingFilter`/`SentrySpringFilter` já configurados) e já existe precedente de captura manual
de exceção fora do fluxo HTTP padrão (`SupplierSearchService`, `GlobalExceptionHandler`) — não é
infraestrutura nova, só aplicar o padrão existente nesses dois pontos.

## Objetivo

Capturar no Sentry toda falha de criação de cliente Asaas — no onboarding (tempo real) e no job de
sincronização (diário) — sem mudar o comportamento funcional (onboarding continua não travando,
job continua retentando no dia seguinte).

## Escopo

- `OnboardingService.createUser`: dentro do catch existente, antes/depois do `log.warn`, adicionar
  `Sentry.captureException(e)` com contexto adicional (`Sentry.configureScope` ou
  `withScope`/tags — incluir `userId`, ideal também a mensagem de erro da Asaas se for
  `AsaasException`, já que ela costuma trazer o motivo exato tipo "CPF/CNPJ inválido").
- `ExternalCustomerSyncService.syncMissingExternalCustomerIds`: dentro do catch por conta (linha
  ~43-46), mesma captura, com `billingAccountId` como contexto. Manter o comportamento atual de
  continuar processando as outras contas do batch.

## Critérios de Aceite

- [ ] Falha de criação de cliente Asaas no onboarding é capturada no Sentry com contexto (userId,
      mensagem de erro da Asaas)
- [ ] Falha de criação de cliente Asaas no job de sincronização é capturada no Sentry por conta
      (billingAccountId), sem interromper o processamento das demais contas do batch
- [ ] Nenhuma mudança de comportamento funcional — onboarding não trava, job continua retentando
- [ ] `mvn test` sem regressão

## Fora de Escopo

- Alerta por e-mail/Slack adicional além do Sentry — o Sentry já notifica por padrão conforme a
  configuração existente do projeto; não criar canal novo agora.
- Dashboard ou relatório de falhas de sincronização — o Sentry já cobre a visibilidade necessária.

## Dependências
Nenhuma.

## Riscos
Baixo — só adiciona observabilidade, não altera fluxo de negócio.

## Esforço
Baixo

## Status
🔵 Não iniciada
