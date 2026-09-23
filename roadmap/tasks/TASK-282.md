# TASK-282 — Capturar telefone no formulário público da landing (`POST /landing/leads`)

## Tipo
FULL_STACK

## Categoria
Backend (leads) / Frontend (landing pública)

## Prioridade
🟠 Alto — Douglas reportou dificuldade de contatar leads capturados só por e-mail; telefone melhora
taxa de contato/conversão e a qualidade de match do Meta CAPI.

## Épico
Sem épico — pedido direto de Douglas em 23/09/2026, junto da TASK-283 (recursos novos na landing).

## QA obrigatório
Sim — fluxo de captação de lead, afeta conversão comercial.

---

## Contexto

O formulário público da landing (`easy-maintenance-web/src/app/landing/page.tsx`) só coleta e-mail
(`<input type="email">`) e envia só `email` no `POST /landing/leads`. A infraestrutura de telefone
**já existe em produção**, só não está conectada nesse formulário:

- `LandingLead.phone` (`leads/domain/LandingLead.java:28`) já é uma coluna da tabela `landing_leads`.
- `LeadAdminDTO` (list/detail) **já expõe `phone`** — a tela `/private/admin/leads` já tem coluna
  pronta pra mostrar telefone, hoje sempre vazia pra leads vindos do formulário público.
- `LeadAdminService` (criação/edição manual de lead pelo admin) já normaliza telefone pra E.164 via
  `PhoneNumberNormalizer.toE164BR(...)` antes de salvar, e já valida "pelo menos um contato (e-mail
  ou telefone)" (`validateHasContact`).
- O único ponto que falta é `CreateLeadRequest` (DTO do form público) **não tem campo `phone`**, e
  `LeadService.createLead` não popula `LandingLead.phone` a partir da request.
- No frontend já existe utilitário de máscara pronto e testado: `src/lib/phoneMask.ts`
  (`maskBRPhoneInput`, usado hoje em `/private/admin/leads/LeadFormModal.tsx`, `/fornecedores/cadastro`,
  onboarding, perfil).

Ou seja: é um gap de "fiação" (wiring), não uma feature nova do zero — reaproveita padrão já
validado em produção (`LeadAdminService`) e componente de máscara já em uso em 4+ telas.

## Escopo da correção

1. **Backend — `CreateLeadRequest`**: adicionar campo `String phone`.
2. **Backend — `LeadService.createLead`**: normalizar com `PhoneNumberNormalizer.toE164BR(request.phone())`
   (mesmo padrão do `LeadAdminService.normalizePhone`) e popular `LandingLead.builder().phone(...)`.
   Telefone inválido não deve derrubar o form inteiro — decidir no `/execute-task` se ignora
   silenciosamente (loga e segue sem phone) ou rejeita com 400 (mais rígido, mas evita lead "sujo").
   Recomendação: rejeitar com 400 e mensagem clara, já que o campo é opcional — se o usuário
   preencheu algo, deve ser válido.
3. **Frontend — `landing/page.tsx`**: adicionar `<input>` de telefone no formulário do hero, com
   `maskBRPhoneInput` (mesmo padrão do `LeadFormModal.tsx`), campo **opcional** (recomendação — ver
   nota abaixo), e enviar `phone: phone.trim() || undefined` no `handleSubmit`.
4. **Meta CAPI**: `MetaCapiClient.sendEvent` já recebe o `LandingLead` inteiro — conferir se já usa
   `phone` pra melhorar o match do Conversions API (`em`/`ph` hash) ou se precisa de ajuste pontual;
   se já usa, o ganho de qualidade de match vem de graça com esta task.
5. **QA manual**: submeter o form com e sem telefone, confirmar lead aparecendo em
   `/private/admin/leads` com telefone preenchido/normalizado, e testar telefone inválido (deve
   dar erro claro, não 500).

## Decisão em aberto (produto)
Campo obrigatório ou opcional? Recomendação: **opcional**, seguindo o padrão de menor fricção do
form atual (só e-mail é obrigatório hoje) — evita queda de conversão por campo extra obrigatório,
mas já resolve o problema de contato pra quem preencher. Se Douglas preferir obrigatório, é só trocar
a validação no passo 2/3.

## Critérios de Aceite
- [ ] `POST /landing/leads` aceita `phone` opcional e persiste normalizado (E.164) em `landing_leads.phone`
- [ ] Telefone inválido retorna 400 com mensagem clara (não 500, não silenciosamente ignorado)
- [ ] Formulário da landing tem campo de telefone com máscara BR, visualmente alinhado ao form atual
- [ ] Lead submetido com telefone aparece corretamente em `/private/admin/leads` (coluna já existe)
- [ ] Lead submetido sem telefone continua funcionando normalmente (regressão)
- [ ] Teste de regressão no backend (`LeadServiceTest` ou equivalente) cobrindo: telefone válido
      normalizado, telefone inválido rejeitado, ausência de telefone não quebra o fluxo
- [ ] `mvn clean test` e `npm run build`/`npm test` sem regressão

## Dependências
Nenhuma — reaproveita `PhoneNumberNormalizer` e `phoneMask.ts` já existentes.

## Riscos
- Baixo — aditivo, reaproveita padrão e componentes já validados em produção (`LeadAdminService`,
  `LeadFormModal`).
- Risco de conversão: campo extra no form, mesmo opcional, pode reduzir levemente a taxa de
  preenchimento — mitigado por ser opcional e por reaproveitar UX já usada em outros forms do app.

## Esforço
Pequeno (~2-3h): 1 campo de DTO + 1 normalização + 1 input de frontend + testes.

## Status
🔵 Pronto para implementar — plano definido em 23/09/2026, aguardando decisão do Douglas pra abrir
a branch.
