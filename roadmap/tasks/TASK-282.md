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
   **Decisão confirmada por Douglas (23/09/2026): telefone é obrigatório** no formulário principal —
   sem ele, volta o problema original de lead sem contato viável. Regra: obrigatório só quando
   `hasEmail` for `true` (ou seja, é o formulário principal, `originType = WEBSITE_FORM`) — **não**
   se aplica ao ping de clique do WhatsApp (`originType = WHATSAPP_CLICK`, sem e-mail nem telefone,
   já coberto pelo teste `createLead_savesWithoutConsentCheck_whenEmailIsAbsent`), que continua
   funcionando exatamente como hoje. Telefone ausente no form principal → 400 "Telefone é
   obrigatório."; telefone preenchido mas inválido → 400 "Telefone inválido." (nunca 500, nunca
   ignorado silenciosamente).
3. **Frontend — `landing/page.tsx`**: adicionar `<input required>` de telefone no formulário do
   hero, com `maskBRPhoneInput` (mesmo padrão do `LeadFormModal.tsx`), e enviar `phone` no
   `handleSubmit`. Não mexer em `handleWhatsAppClick` (ping de clique, propositalmente sem contato).
4. **Meta CAPI**: `MetaCapiClient.sendEvent` já recebe o `LandingLead` inteiro — conferir se já usa
   `phone` pra melhorar o match do Conversions API (`em`/`ph` hash) ou se precisa de ajuste pontual;
   se já usa, o ganho de qualidade de match vem de graça com esta task.
5. **QA manual**: submeter o form com e sem telefone, confirmar lead aparecendo em
   `/private/admin/leads` com telefone preenchido/normalizado, e testar telefone inválido (deve
   dar erro claro, não 500).

## Decisão (produto) — RESOLVIDA
Telefone **obrigatório** no formulário principal da landing, confirmado por Douglas 23/09/2026:
"pode ser obrigatório pq senão vamos cair no mesmo problema". Não se aplica ao ping de clique do
WhatsApp (sem contato, tracking best-effort).

## Critérios de Aceite
- [x] `POST /landing/leads` exige `phone` quando `email` está presente (form principal); persiste
      normalizado (E.164) em `landing_leads.phone`
- [x] Telefone ausente ou inválido no form principal retorna 400 com mensagem clara (não 500)
- [x] Ping de clique do WhatsApp (sem e-mail, sem telefone) continua funcionando sem exigir contato
      (regressão do `originType = WHATSAPP_CLICK`) — coberto por
      `createLead_savesWithoutConsentCheck_whenEmailIsAbsent`
- [x] Formulário da landing tem campo de telefone `required` com máscara BR, visualmente alinhado ao
      form atual
- [~] Lead submetido com telefone aparece corretamente em `/private/admin/leads` (coluna já existe)
      — código pronto, pendente confirmação visual do Douglas após deploy
- [x] Teste de regressão no backend (`LeadServiceTest`) cobrindo: telefone válido normalizado,
      telefone ausente rejeitado quando há e-mail, telefone inválido rejeitado, ping de WhatsApp sem
      contato continua passando
- [x] `mvn clean test` (1062/1062) e `npm run build`/`npx tsc --noEmit` sem regressão; `npm test`
      107/110 (3 falhas pré-existentes em `middleware.test.ts`, não relacionadas)

## Dependências
Nenhuma — reaproveita `PhoneNumberNormalizer` e `phoneMask.ts` já existentes.

## Riscos
- Baixo — aditivo, reaproveita padrão e componentes já validados em produção (`LeadAdminService`,
  `LeadFormModal`).
- Risco de conversão: campo obrigatório a mais no form pode reduzir levemente a taxa de
  preenchimento — decisão consciente do Douglas ("senão vamos cair no mesmo problema"), prioriza
  qualidade de contato sobre volume bruto de leads.

## Esforço
Pequeno (~2-3h): 1 campo de DTO + 1 normalização + 1 input de frontend + testes.

## Implementação
- Branch: `feature/TASK-282-landing-lead-phone` (repos `api` e `web`, a partir de `staging`)
- Backend: `CreateLeadRequest.phone` (novo campo) + `LeadService.normalizePhone` (obrigatório só
  quando `hasEmail`) + `LeadServiceTest` com 2 testes novos + testes existentes ajustados pro novo
  campo posicional. `mvn clean test`: 1062/1062.
- Frontend: `landing/page.tsx` ganha `<input type="tel" required>` com `maskBRPhoneInput`, envia
  `phone` no `handleSubmit`, e o catch agora mostra `err.response.data.detail` (mensagem real do
  backend) em vez de alerta genérico.
- PRs: [api#112](https://github.com/douglasjava/easy-maintenance-api/pull/112) mergeada em
  `staging`, promoção pra `main` aberta: [api#113](https://github.com/douglasjava/easy-maintenance-api/pull/113).
  [web#88](https://github.com/douglasjava/easy-maintenance-web/pull/88) mergeada em `staging`
  (branch consolidada com TASK-283/284 — mesmo arquivo `landing/page.tsx`), promoção pra `main`
  aberta: [web#89](https://github.com/douglasjava/easy-maintenance-web/pull/89).

## Status
✅ **Done** — [api#113](https://github.com/douglasjava/easy-maintenance-api/pull/113) e
[web#89](https://github.com/douglasjava/easy-maintenance-web/pull/89) mergeadas em `main` por
Douglas (23/09/2026).
