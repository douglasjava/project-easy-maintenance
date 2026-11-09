# EPIC-037 — Emissão de NFS-e para Assinaturas (Asaas Nativo)

## Status
📝 Backlog — spec aprovada por Douglas (12-13/10/2026), plano de implementação escrito. Criado em
19/10/2026. Implementação e testes correm contra sandbox da Asaas; ativação em produção **bloqueada**
(ver "Dependência externa" abaixo).

Spec: `docs/superpowers/specs/2026-10-13-fiscal-invoice-nfse-design.md`.
Plano: `docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md`.

## Objetivo
Emitir NFS-e automaticamente para cada cobrança paga de assinatura de organização
(STARTER/BUSINESS/ENTERPRISE), usando a emissão nativa do Asaas (nosso provedor de pagamento atual),
sem depender de provedor fiscal terceiro (Focus NFe, eNotas, NFE.io — avaliados e descartados por
custo/mensalidade).

## Escopo
- Só assinatura de organização (condomínio/administradora). Cadastro de fornecedores (Pix Automático
  próprio) **não** entra — pode ser extensão futura do mesmo padrão.
- Só NFS-e (nota de serviço); não cobre NF-e de produto nem NFC-e.

## Arquitetura (resumo)
1. Na ativação da assinatura (`SubscriptionCreatedHandler`), configura a emissão automática de NF
   **uma vez** via Asaas (`effectiveDatePeriod=ON_PAYMENT_CONFIRMATION`). Falha nessa chamada nunca
   bloqueia a ativação da assinatura.
2. A partir daí a Asaas emite a NFS-e sozinha a cada cobrança paga e avisa via webhook dedicado
   (`INVOICE_AUTHORIZED` / `INVOICE_ERROR`), endpoint novo e separado do `AsaasWebhookController`
   existente.
3. Job diário de reconciliação cobre falha transitória na configuração e sinaliza notas travadas
   (`ERROR`/`PENDING` antigo) para revisão manual — sem retry automático de emissão.

Nova entidade `FiscalInvoice` (não confundir com `Invoice`, que é cobrança interna).

## Dependência externa (bloqueador de rollout, não de engenharia)
Ativar a configuração de NF numa assinatura real exige Certificado Digital A1 no portal da Asaas
(`asaas.com/customerInvoiceOnboarding`), que depende da abertura de um novo CNPJ (em andamento,
confirmado por Douglas em 12/10/2026). **Todo o código deste épico é implementado e testado contra
sandbox; a ativação em produção é decisão manual posterior**, condicionada a essa dependência — ver
[[project_fiscal_invoice_nfse]].

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-360](../tasks/TASK-360.md) | Backend: `FiscalInvoice` — entidade, enum, migration V124 e repositório | BACKEND | 🟠 Alto |
| [TASK-361](../tasks/TASK-361.md) | Backend: configuração de NF na Asaas — DTOs, `AsaasClient`, `FiscalInvoiceConfigurationService` | BACKEND | 🟠 Alto |
| [TASK-362](../tasks/TASK-362.md) | Backend: acionar configuração de NF na ativação da assinatura | BACKEND | 🟠 Alto |
| [TASK-363](../tasks/TASK-363.md) | Backend: webhook de nota fiscal — endpoint e processamento (`INVOICE_AUTHORIZED`/`INVOICE_ERROR`) | BACKEND | 🟠 Alto |
| [TASK-364](../tasks/TASK-364.md) | Backend: job de reconciliação fiscal | BACKEND | 🟡 Médio |
| [TASK-365](../tasks/TASK-365.md) | QA: validar fluxo completo contra sandbox Asaas + checklist de rollout (CNPJ/certificado A1) | QA | 🟠 Alto |

Ordem: TASK-360 → TASK-361 → TASK-362 e TASK-363 (podem andar em paralelo, ambas dependem só da 361)
→ TASK-364 (depende de 361) → TASK-365 ao final.

## Critério de Conclusão do Épico
- [ ] `FiscalInvoice` persiste e reconcilia corretamente (testes unitários + persistência real)
- [ ] Falha ao configurar NF nunca bloqueia ativação de assinatura (testado)
- [ ] Webhook idempotente por `externalFiscalInvoiceId`, aceita `FiscalInvoice` sem `Payment`/`BillingSubscription` resolvido
- [ ] Job de reconciliação roda diariamente (ShedLock) e sinaliza notas travadas sem retry automático de emissão
- [ ] `mvn test` sem regressão
- [ ] Validado contra sandbox da Asaas (TASK-365)
- [ ] Confirmado com Douglas: CNPJ novo existe e certificado A1 emitido, **antes** de ativar em produção

## Fora de Escopo
- Ativação em produção (fica para decisão manual posterior do Douglas, fora deste épico).
- Cadastro de fornecedores / Pix Automático próprio.
- NF-e de produto, NFC-e.
- Retry automático de emissão de nota em `ERROR` (decisão manual/contábil).

## Riscos
- Dependência externa (CNPJ + certificado A1) fora do controle da implementação — mesma classe de
  risco que já atrasou outros templates/aprovações externas no projeto (ex.: EPIC-023/Meta).
- Alíquotas fiscais e `municipalServiceCode` reais precisam ser confirmados com o contábil antes do
  rollout — os valores em `application.properties` ficam como placeholder/sandbox até então.
