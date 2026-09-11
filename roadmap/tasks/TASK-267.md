# TASK-267 — BACKEND: Job mensal de cobrança PIX + suspensão por atraso

## Tipo
BACKEND

## Categoria
Fornecedores / Marketplace

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — validar em ambiente com credenciais Asaas reais que a cobrança do próximo ciclo é gerada e
que a suspensão respeita o prazo de graça.

---

## Contexto

Cobrança PIX "detached" não tem renovação automática do gateway (diferente de cartão) — precisa de
um job próprio que gera uma nova cobrança a cada ciclo, mesmo padrão já usado em
`TrialExpirationService`/`PixRenewalService` pro billing de organização.

## Escopo

- `SupplierBillingService.processDueCycles()`: assinaturas `ACTIVE` com `currentPeriodEnd` vencido
  recebem nova cobrança PIX (3 dias de vencimento); falha em uma não impede as demais (try/catch
  por item, logado).
- `SupplierBillingService.suspendOverdueSubscriptions()`: assinaturas `PAST_DUE` vencidas há mais
  de 3 dias (prazo de graça, mesmo valor de `billing.blocking.days-after-due` — TASK-236) têm
  `marketplace_enabled` desligado.
- `SupplierBillingJob` (`@Scheduled` diário, 02:15, depois do `DailyTrialJob` de organização às
  01:15, `@SchedulerLock` mesmo padrão).

## Critérios de Aceite

- [x] Assinatura `ACTIVE` vencida gera nova cobrança e atualiza `currentPeriodEnd`
- [x] Assinatura `PAST_DUE` além do prazo de graça desliga `marketplace_enabled`
- [x] Falha numa cobrança individual não interrompe o processamento das demais

## Dependências
TASK-261 (`SupplierSubscriptionRepository.findByStatusAndCurrentPeriodEndLessThanEqual`),
TASK-264/265 (gera/ativa a assinatura que este job cobra).

## Riscos
Baixo — job novo e isolado (`supplier_billing`), não compartilha lock nem tabela com os jobs de
billing de organização existentes.

## Esforço
Médio

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `supplier_billing/application/service/SupplierBillingService.java` | `processDueCycles()`, `suspendOverdueSubscriptions()` |
| `jobs/SupplierBillingJob.java` | `@Scheduled` diário 02:15 |
| `test/.../supplier_billing/application/service/SupplierBillingServiceTest.java` | 2 testes |

### Verificação
`mvn test` (suíte completa) → PASS, sem regressão.

## Status
🟢 Implementado e testado. Execução real do job (cron) fica pra validação em ambiente com
credenciais Asaas — não roda nesta sessão.
