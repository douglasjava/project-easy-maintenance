# TASK-265 — BACKEND: Ativação de fornecedor via webhook `PAYMENT_RECEIVED`

## Tipo
BACKEND

## Categoria
Fornecedores / Marketplace

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — validar em sandbox que o pagamento PIX confirmado ativa o `marketplace_enabled`, gera o link
mágico e dispara o e-mail de boas-vindas.

---

## Contexto

Asaas só suporta uma URL de webhook / um handler por tipo de evento (`AsaasWebhookService` mapeia
1:1 evento → strategy). Fornecedor e organização compartilham o mesmo evento `PAYMENT_RECEIVED`,
então a distinção é feita pelo prefixo do `externalReference` (`SUPPLIER-<id>` vs o formato usado
pelo billing de organização) — branch mínimo no início do `PaymentReceivedHandler` existente, sem
criar um handler novo.

## Escopo

- `SupplierPaymentActivationService.activateFromWebhook(supplierId)`: idempotente (se a
  `SupplierSubscription` já está `ACTIVE`, no-op); ativa `marketplaceEnabled`, grava
  `activatedAt`/`activationSource=SELF_REGISTERED`; gera (ou reaproveita) `SupplierAccessToken`;
  dispara e-mail via `CriticalEmailDispatchService` com o link mágico de gestão.
- `PaymentReceivedHandler.handle()`: branch novo logo após obter `paymentObj` — se
  `externalReference` começa com `SUPPLIER-`, delega pro serviço acima e retorna, sem tocar no
  fluxo de organização.
- `NotificationEventType.SUPPLIER_ACTIVATION` (novo) + `EmailTemplateHelper.generateSupplierActivationHtml`.

## Critérios de Aceite

- [x] Pagamento confirmado ativa `marketplace_enabled`, `activatedAt`, `activationSource`
- [x] Gera `SupplierAccessToken` novo (ou reaproveita o existente, não duplica)
- [x] Idempotente — segunda chamada com subscription já `ACTIVE` não reenvia e-mail
- [x] Branch novo não interfere no fluxo de pagamento de organização (mesmo evento, prefixo
      diferente)
- [x] Suíte completa do backend sem regressão

## Dependências
TASK-261 (`SupplierSubscriptionRepository`/`SupplierAccessTokenRepository`), TASK-264 (gera a
`SupplierSubscription` que este webhook ativa).

## Riscos
Médio — altera um handler de webhook de pagamento em produção (`PaymentReceivedHandler`), usado
tanto pelo fluxo de organização quanto agora pelo de fornecedor. Mitigado: branch retorna cedo
(`return`) antes de qualquer lógica de organização, e a suíte completa (990+ testes) rodou sem
regressão, incluindo o `PaymentReceivedHandlerTest.java` já existente (fluxo de organização
intocado).

## Esforço
Médio

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `supplier_billing/application/service/SupplierPaymentActivationService.java` | `activateFromWebhook(Long supplierId)` |
| `test/.../supplier_billing/application/service/SupplierPaymentActivationServiceTest.java` | 3 testes |
| `test/.../webhooks/asaas/strategy/impl/PaymentReceivedHandlerSupplierBranchTest.java` | 1 teste focado só no branch novo |

### Arquivos modificados
| Arquivo | Descrição |
|---|---|
| `PaymentReceivedHandler.java` | branch novo (prefixo `SUPPLIER-`) + novo parâmetro de construtor `SupplierPaymentActivationService` |
| `NotificationEventType.java` | `SUPPLIER_ACTIVATION` |
| `EmailTemplateHelper.java` | `generateSupplierActivationHtml(supplierName, manageLink)` — seguindo o mesmo padrão estilizado (HTML com CSS inline) já usado nos outros templates do arquivo, não a versão simplificada inicial do plano |

### Decisões tomadas durante a implementação
- Gap real do plano encontrado no teste `SupplierPaymentActivationServiceTest`: faltava o stub de
  `accessTokenRepository.save(...)` no caso de token novo — sem ele o mock Mockito retorna `null`
  por padrão, causando `NullPointerException` em `token.getToken()`. Corrigido no teste e
  retroativamente no plano.
- `PaymentReceivedHandlerTest.java` (existente) não precisou de nenhum ajuste — o novo parâmetro do
  construtor (`SupplierPaymentActivationService`) fica `null` via injeção automática do Mockito
  (`@InjectMocks` sem mock correspondente), inofensivo porque nenhum teste existente usa
  `externalReference` com prefixo `SUPPLIER-`.

### Verificação
`mvn test -Dtest=PaymentReceivedHandlerSupplierBranchTest,PaymentReceivedHandlerTest` → PASS.
`mvn test` (suíte completa do backend) → PASS, sem regressão em nenhum módulo.

## Status
🟢 Implementado e testado. Validação end-to-end contra o Asaas sandbox (webhook real) fica pra a
rodada de QA manual do Douglas no final do épico.
