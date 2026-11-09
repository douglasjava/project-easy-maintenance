# TASK-365 — QA: validar fluxo completo contra sandbox Asaas + checklist de rollout (CNPJ/certificado A1)

## Tipo
QA

## Prioridade
🟠 Alto

## Épico
[EPIC-037](../epics/EPIC-037.md) — Emissão de NFS-e para Assinaturas (Asaas Nativo)

## Depende de
TASK-360, TASK-361, TASK-362, TASK-363, TASK-364

## QA obrigatório
Sim (é a própria task de QA).

## Contexto
Spec em [`docs/superpowers/specs/2026-10-13-fiscal-invoice-nfse-design.md`](../../docs/superpowers/specs/2026-10-13-fiscal-invoice-nfse-design.md),
seção "Testes" e "Rollout". **Nenhuma chamada real à API de produção da Asaas antes do certificado
digital A1 (novo CNPJ) estar pronto** — todo teste desta task é contra sandbox.

Dois blocos:
1. **Funcional (sandbox)**: criar assinatura de teste → confirmar configuração de NF criada na
   Asaas → simular pagamento → confirmar webhook `INVOICE_AUTHORIZED` chega e atualiza o
   `FiscalInvoice` local → simular `INVOICE_ERROR` → confirmar status e `errorMessage`. Rodar o job
   de reconciliação manualmente contra uma assinatura com `fiscalInvoiceConfigured=false` e
   confirmar nova tentativa.
2. **Checklist de rollout (bloqueado, não executar em produção ainda)**: confirmar com Douglas, antes
   de qualquer ativação real —
   - [ ] CNPJ novo existe.
   - [ ] Certificado Digital A1 emitido.
   - [ ] Onboarding manual completo no portal da Asaas (`asaas.com/customerInvoiceOnboarding`).
   - [ ] Alíquotas fiscais reais (iss/pis/cofins/csll/inss/ir) e `municipalServiceCode` confirmados
         com o contábil (hoje são placeholder de sandbox em `application.properties`).

**Prompt**: `execute a TASK-365 (EPIC-037): QA do fluxo de NFS-e contra sandbox Asaas + checklist de
rollout, seguindo a seção "Testes"/"Rollout" da spec docs/superpowers/specs/2026-10-13-fiscal-invoice-nfse-design.md.`

## Critérios de aceite
- [ ] Fluxo funcional validado ponta a ponta contra sandbox (configuração → webhook autorizado →
      webhook de erro → reconciliação).
- [ ] Checklist de rollout documentado e explicitamente **não marcado como pronto** até confirmação
      do Douglas (CNPJ/certificado A1/alíquotas reais) — este épico não ativa nada em produção.
- [ ] `mvn test` sem regressão na suíte completa.

## Status
Backlog — TASK-360/361/362/363/364 implementadas e com suíte automatizada verde em
`feature/EPIC-037-fiscal-invoice-nfse` (easy-maintenance-api). Roteiro de QA manual do bloco
funcional criado em [TASK-QA-MAN-026](../QA/tasks/TASK-QA-MAN-026.md) — falta a execução de fato
contra sandbox real da Asaas (precisa das credenciais de sandbox do Douglas). O checklist de
rollout continua **não marcado como pronto** — nenhuma ativação em produção.
