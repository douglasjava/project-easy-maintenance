# TASK-189 — Frontend: registro manual de lead + edição (nome/e-mail/telefone/fonte) na tela de leads

## Tipo
FRONTEND

## Categoria
Admin / Leads

## Prioridade
🟠 Alto

## Épico
[EPIC-021](../epics/EPIC-021.md) — Painel de Leads (visão agregada + mini-CRM de status), Fase 2

## QA obrigatório
Sim — QA manual: criar lead manual (cada fonte da lista), editar um lead antigo do WhatsApp
acrescentando telefone, editar um lead de tráfego pago mantendo a fonte como texto livre, conferir
colunas Canal/Telefone na tabela e que o relatório de Top Fontes não quebra com fonte manual.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-23-leads-screen-improvements-design.md`.

Depende da TASK-188 (`POST /admin/leads`, `PUT /admin/leads/{id}`). É a parte visível da feature:
sem isso, os endpoints novos não têm como ser usados. A coluna "Canal" hoje é inferida
(`lead.email ? "E-mail" : "WhatsApp"`) — deixa de fazer sentido assim que um lead manual pode ter
e-mail, telefone, os dois ou nenhum, então passa a usar o campo `originType` real.

## Objetivo

Modal único de criar/editar lead (`LeadFormModal`), botão "Novo lead", coluna Telefone na tabela,
coluna Canal usando `originType`, e ação "Editar" por linha.

## Escopo

### 1. `labels.ts` — dois label maps novos

```typescript
export const leadOriginTypeLabelMap: Record<string, string> = {
    WEBSITE_FORM: "Formulário",
    WHATSAPP_CLICK: "WhatsApp",
    MANUAL: "Manual",
};

export const manualLeadSourceLabelMap: Record<string, string> = {
    REFERRAL: "Indicação",
    EVENT: "Evento",
    WORD_OF_MOUTH: "Boca a boca",
    OTHER: "Outro",
};
```

Mesmo padrão do `leadStatusLabelMap` já existente no mesmo arquivo.

### 2. `LeadFormModal.tsx` (novo, `src/app/private/admin/leads/`)

Modal Bootstrap controlado por state (mesmo padrão de `CancelMaintenanceModal.tsx` e do modal de
edição do `/ai-onboarding`), reaproveitado pra criar e editar:

```typescript
type LeadFormModalProps = {
  show: boolean;
  onClose: () => void;
  onSaved: () => void;
  lead?: Lead | null; // null/undefined = modo criação; presente = modo edição
};
```

- Campos: Nome (obrigatório), E-mail, Telefone (mascarado com `maskBRPhoneInput`, importado de
  `@/lib/phoneMask` — mesmo input já usado em `profile`/`maintenances/new`/`onboarding`), Fonte.
- Telefone pré-preenchido em modo edição via `e164ToDisplayMask(lead.phone)`.
- Fonte: `<select>` com as 4 opções de `manualLeadSourceLabelMap` quando `!lead` (criação) ou
  `lead.originType === "MANUAL"`; input de texto livre quando `lead.originType !== "MANUAL"`.
- Validação no cliente antes do submit: nome obrigatório; pelo menos um de e-mail/telefone
  preenchido (mesma regra do backend, só pra dar feedback sem esperar o 400).
- Submit: `POST /private/admin/leads` (criação, mandando `source` como o enum selecionado) ou
  `PUT /private/admin/leads/{id}` (edição, mandando `source` como veio do campo, seja select ou
  texto livre) — telefone enviado como veio da máscara, normalização final é backend
  (`PhoneNumberNormalizer`).
- `onSaved()` fecha o modal e recarrega a lista (mesmo padrão de callback já usado em outros
  formulários do admin).

### 3. `LeadListSection.tsx` — mudanças

- `Lead` type ganha `phone: string | null` e
  `originType: "WEBSITE_FORM" | "WHATSAPP_CLICK" | "MANUAL"`.
- Botão **"+ Novo lead"** ao lado do título "Lista de leads", abre `LeadFormModal` sem `lead` (modo
  criação).
- Nova coluna **Telefone**, entre E-mail e Fonte, formatada com `e164ToDisplayMask(lead.phone)`
  (`"-"` quando `null`).
- Coluna **Canal**: `leadOriginTypeLabelMap[lead.originType]` no lugar da inferência atual por
  e-mail.
- Nova coluna **Ações** com botão "Editar" por linha, abre `LeadFormModal` com `lead={row}` (modo
  edição).
- State novo: `editingLead: Lead | null` e `showModal: boolean`, seguindo o mesmo padrão de
  `savingId` já usado pro dropdown de status.

### 4. Testes / verificação
- `npm run build` limpo.
- QA manual (ver "QA obrigatório" acima).

## Critérios de Aceite

- [ ] Botão "Novo lead" abre o modal em modo criação, campos vazios
- [ ] Criar lead manual funciona pras 4 fontes, com só e-mail, só telefone, e os dois
- [ ] Botão "Editar" por linha abre o modal pré-preenchido, incluindo telefone existente
- [ ] Editar um lead `WHATSAPP_CLICK` antigo pra acrescentar telefone funciona e persiste
- [ ] Fonte aparece como `<select>` fechado só quando `originType === "MANUAL"` (ou criação);
      texto livre nos demais casos
- [ ] Coluna Telefone exibe o número mascarado ou "-"
- [ ] Coluna Canal reflete `originType` real, não mais inferência por e-mail
- [x] `npm run build` limpo

**Nota**: os 7 itens acima (exceto build) dependem de clicar de verdade na tela — não pude validar
visualmente, mesma limitação já registrada em tasks anteriores (tela exige login, sem credenciais
de teste disponíveis pra automação). Implementação segue a spec e o código dos endpoints da
TASK-188 (que esses fluxos consomem) já está com teste automatizado cobrindo o contrato. Aguardando
Douglas testar em navegador real.

## Dependências
**TASK-188** — precisa de `POST /admin/leads` e `PUT /admin/leads/{id}` existirem.

## Riscos
Baixo — extensão aditiva de uma tela admin já existente (EPIC-021), sem alterar filtros, gráfico ou
relatórios de top fontes/referrers já implementados.

## Esforço
Médio

## Status
✅ Implementada e commitada (23/08/2026) na branch `feature/leads-manual-registration`
(`easy-maintenance-web`, commit `5e5e7c6`). `npm run build` limpo. **Não validada visualmente por
mim** — mesma limitação já registrada em TASK-186 (tela exige login, sem credenciais de teste); a
validação foi 100% do Douglas. PR [#48](https://github.com/douglasjava/easy-maintenance-web/pull/48)
aberta em 23/08/2026.
