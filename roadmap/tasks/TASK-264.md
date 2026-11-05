# TASK-264 — BACKEND: Auto-cadastro público de fornecedor + cobrança PIX inicial

## Tipo
BACKEND

## Categoria
Fornecedores / Marketplace

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — validar em ambiente com credenciais Asaas reais (sandbox) que a cobrança PIX é gerada
corretamente com o `externalReference` no formato `SUPPLIER-<id>`.

---

## Contexto

Decisão de escopo #6 do spec: só PIX no v1 (sem cartão). Cobrança "detached" (sem assinatura
nativa Asaas — essa só existe pra cartão) — mesmo padrão já usado em `TrialExpirationService` pra
renovação PIX de organização. Valor fixo: R$15,99/mês.

## Escopo

- `POST /easy-maintenance/api/v1/public/suppliers/register` — público, rate-limited por IP (5
  cadastros/hora — endpoint público que dispara cobrança Asaas, limite conservador).
- `SupplierRegistrationService`: reaproveita `Supplier` existente por `document` se já cadastrado
  (não duplica); cria `AsaasDTO.CustomerResponse` + `PaymentResponse` (PIX, vencimento em 3 dias);
  grava `SupplierSubscription` com status `PAST_DUE` (fica `ACTIVE` só quando o webhook confirma o
  pagamento — TASK-265).

## Critérios de Aceite

- [x] Documento novo cria `Supplier` + `SupplierSubscription` (`PAST_DUE`) + cobrança Asaas
- [x] Documento já cadastrado reaproveita o `Supplier` existente, não duplica
- [x] `externalReference` da cobrança segue o formato `SUPPLIER-<id>`
- [x] Rate limit configurado (5/hora por IP)

## Dependências
TASK-260, TASK-261.

## Riscos
Médio — integração com gateway de pagamento externo (Asaas). Mitigado reaproveitando
`AsaasClient`/`AsaasDTO` já testados em produção pelo billing de organização, sem lógica nova de
protocolo HTTP.

## Esforço
Médio

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `supplier_billing/application/dto/SelfRegisterSupplierRequest.java` | `document` (`@Doc`), `name`, `email`, `phone`, `category`, `city`, `state` |
| `supplier_billing/application/dto/SelfRegisterSupplierResponse.java` | `supplierId`, `paymentLink` |
| `supplier_billing/application/service/SupplierRegistrationService.java` | `register()` |
| `supplier_billing/infrastructure/web/SupplierPublicController.java` | `POST /public/suppliers/register` |
| `test/.../supplier_billing/application/service/SupplierRegistrationServiceTest.java` | 2 testes |

### Arquivos modificados
`application.properties` — `rate-limit.limits.supplier-self-register.*` (5 cadastros/hora por IP).

### Decisões tomadas durante a implementação
- Assinaturas de `AsaasDTO.CreateCustomerRequest` (13 campos posicionais) e `CreatePaymentRequest`
  (6 campos) conferidas contra o `AsaasDTO.java` real antes de implementar — já haviam sido
  corrigidas no plano durante o self-review da fase de `writing-plans` (versão inicial do plano
  assumia 11 campos pro primeiro).

### Verificação
`mvn test -Dtest=SupplierRegistrationServiceTest` → PASS (2/2). Compilação completa (`mvn compile`)
limpa.

## Status
🟢 Implementado e testado (mocks). Validação end-to-end contra o Asaas sandbox fica pra a rodada de
QA manual do Douglas no final do épico (esta sessão não tem credenciais Asaas configuradas).
