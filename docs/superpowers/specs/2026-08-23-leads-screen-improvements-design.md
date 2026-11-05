# Melhorias na tela de Leads — registro manual + telefone

**Data:** 23/08/2026
**Status:** Aprovado por Douglas (brainstorm conduzido nesta data)

## Motivação

Douglas (dono do produto) pediu melhorias pontuais na tela `/private/admin/leads` a partir de dois problemas reais que vem enfrentando:

1. **Leads de outras fontes.** Ele recebe leads que não vêm do fluxo de tráfego pago/ADS (indicação, evento, boca a boca) e hoje não tem onde registrá-los — a única forma de criar um lead é via `POST /landing/leads`, endpoint público usado pelo form da landing e pelo clique no botão de WhatsApp. Não existe criação manual pela tela admin.
2. **Telefone ausente nos leads de WhatsApp.** O botão flutuante de WhatsApp da landing (`handleWhatsAppClick` em `src/app/landing/page.tsx`) grava um lead só com UTM/referrer, sem nome/e-mail/telefone, antes de abrir o `wa.me` — o número do visitante só é conhecido quando ele efetivamente manda mensagem pro WhatsApp de Douglas, fora do sistema. Hoje não existe campo de telefone na tabela `landing_leads` nem forma de editar um lead depois de criado (o único endpoint de update existente é `PATCH /admin/leads/{id}/status`, só pra status).

## Estado atual (confirmado por leitura de código)

- `LandingLead` (`easy-maintenance-api`): `id, email, name, source, medium, campaign, referrer, affiliateCode, landingPath, utmJson, ip, userAgent, status, consentAcceptedAt, createdAt`. Sem telefone, sem campo de origem/canal explícito.
- `LeadService.createLead()`: único ponto de criação, público, usado pelos dois fluxos da landing (form de e-mail e clique de WhatsApp).
- `AdminLeadController` / `LeadAdminService`: só listagem com filtros (status/fonte/campanha/período) e `updateStatus()`. Nenhuma criação ou edição completa.
- `LeadListSection.tsx` (frontend): tabela com colunas Canal/Nome/E-mail/Fonte/Referrer/Status/Criado em. A coluna **Canal** é inferida (`lead.email ? "E-mail" : "WhatsApp"`) — não é um dado real gravado, só uma dedução visual.

## Decisões de escopo (brainstorm, 23/08/2026)

1. **Edição completa do lead** (nome, e-mail, telefone, fonte), não só telefone — já que a capacidade de editar precisa ser criada do zero de qualquer forma, não faz sentido limitar a um campo só.
2. **Fonte do lead manual via lista fixa** (Indicação, Evento, Boca a boca, Outro) em vez de texto livre — evita poluir o relatório de "Top fontes" com variações do mesmo valor digitadas à mão.
3. **Canal de origem explícito**, gravado no momento da criação (`WEBSITE_FORM`, `WHATSAPP_CLICK`, `MANUAL`) — substitui a inferência atual por e-mail, que quebra assim que um lead manual pode ter e-mail, telefone, os dois ou nenhum.
4. **UI: modal único reutilizado** pra criar e editar (em vez de edição inline na tabela ou telas separadas) — menos superfície de UI pra manter, mesmo padrão dos modais já existentes no produto (`CancelMaintenanceModal`, modal de edição do `/ai-onboarding`).

## Modelo de dados

Migration `V92__add_lead_manual_registration.sql` (`easy-maintenance-api`):

```sql
ALTER TABLE landing_leads
    ADD COLUMN phone VARCHAR(20) NULL,
    ADD COLUMN origin_type VARCHAR(20) NOT NULL DEFAULT 'WEBSITE_FORM';

-- Backfill dos leads existentes: quem nunca teve e-mail veio do clique do WhatsApp
UPDATE landing_leads SET origin_type = 'WHATSAPP_CLICK' WHERE email IS NULL;
```

- `phone`: telefone normalizado em E.164 (`+5531999999999`) via `PhoneNumberNormalizer.toE164BR()` (utilitário já existente, usado hoje por `User.phoneNumber`). Nullable — nem todo lead terá telefone.
- `origin_type`: novo enum `LeadOriginType { WEBSITE_FORM, WHATSAPP_CLICK, MANUAL }`. Sempre definido pelo backend na criação, nunca escolhido pelo usuário.
- `source` (já existente, texto livre): sem mudança de schema. Continua guardando `utm_source` pra leads rastreados; pra leads `MANUAL`, guarda um dos 4 valores fixos do novo enum `ManualLeadSource { REFERRAL, EVENT, WORD_OF_MOUTH, OTHER }`, escolhido via `<select>` no formulário — não é uma coluna nova, é só a UI restringindo o que é enviado nesse caso.

Campos novos são opcionais/com default — nenhuma mudança de comportamento nos fluxos de criação pública existentes.

`medium`, `campaign` e `referrer` (já existentes na entidade) não entram em `CreateManualLeadRequest`/`UpdateLeadRequest` — são conceitos de rastreio UTM que não se aplicam a um lead registrado manualmente; ficam `null` nesses registros, sem necessidade de exibi-los como campo vazio no formulário.

## Backend

**`LeadService.createLead()`** (`POST /landing/leads`, já existente): passa a setar `originType` automaticamente — `WEBSITE_FORM` se `email` vier preenchido, senão `WHATSAPP_CLICK`.

**`AdminLeadController`** (`/private/admin/leads`) ganha dois endpoints:

```java
@PostMapping
public LeadAdminDTO.LeadListResponse create(@Valid @RequestBody LeadAdminDTO.CreateManualLeadRequest request);

@PutMapping("/{id}")
public LeadAdminDTO.LeadListResponse update(@PathVariable Long id, @Valid @RequestBody LeadAdminDTO.UpdateLeadRequest request);
```

**`LeadAdminDTO`** ganha:

```java
public record CreateManualLeadRequest(
        @NotBlank String name, String email, String phone,
        @NotNull ManualLeadSource source) {}

public record UpdateLeadRequest(
        @NotBlank String name, String email, String phone, String source) {}
```

- `CreateManualLeadRequest.source`: enum fechado (`ManualLeadSource`), só pra criação manual.
- `UpdateLeadRequest.source`: texto livre — precisa continuar aceitando editar um lead que já tem `utm_source` real (ex.: corrigir "google" para "Google Ads"), não faz sentido restringir a um enum fechado nesse caso.
- Validação (`CreateManualLeadRequest` e `UpdateLeadRequest`): `name` obrigatório; pelo menos um de `email`/`phone` preenchido (validação customizada no service — `@NotBlank`/`@NotNull` sozinhos não expressam "pelo menos um de dois campos"). Sem isso, 400 "Informe pelo menos um contato (e-mail ou telefone)".
- `phone`, quando informado, passa por `PhoneNumberNormalizer.toE164BR()`; se não normalizar, 400 "Telefone inválido".
- Editar lead inexistente: mesma `NotFoundException` já usada em `updateStatus()`.

**`LeadAdminService`** ganha `createManual()` e `update()`, seguindo o padrão já existente de `updateStatus()` (busca por id quando aplicável, aplica mudanças, salva, mapeia pra `LeadListResponse`).

**`LeadAdminDTO.LeadListResponse`** ganha `phone` e `originType`.

## Frontend

**`LeadFormModal.tsx`** (novo, `src/app/private/admin/leads/`), reutilizado pra criar e editar:
- Campos: Nome (obrigatório), E-mail, Telefone (mascarado com `maskBRPhoneInput`, já usado em `profile`/`maintenances/new`/`onboarding`), Fonte.
- Fonte é um `<select>` fechado (4 opções) quando é criação manual ou edição de um lead já `MANUAL`; vira texto livre quando é edição de um lead `WEBSITE_FORM`/`WHATSAPP_CLICK` (pode ter `utm_source` real).
- Validação no cliente espelhando a do backend: nome obrigatório, pelo menos um de e-mail/telefone.

**`LeadListSection.tsx`**:
- Botão "+ Novo lead" ao lado do título, abre o modal em modo criação.
- Nova coluna **Telefone** (formatada com `e164ToDisplayMask`).
- Coluna **Canal** passa a usar `originType` direto (não mais inferência por e-mail).
- Nova ação **Editar** por linha, abre o modal pré-preenchido.
- `Lead` (tipo local) ganha `phone: string | null` e `originType: "WEBSITE_FORM" | "WHATSAPP_CLICK" | "MANUAL"`.

**`labels.ts`** ganha `leadOriginTypeLabelMap` (`WEBSITE_FORM` → "Formulário", `WHATSAPP_CLICK` → "WhatsApp", `MANUAL` → "Manual") e `manualLeadSourceLabelMap` (`REFERRAL` → "Indicação", `EVENT` → "Evento", `WORD_OF_MOUTH` → "Boca a boca", `OTHER` → "Outro"), seguindo o padrão do `leadStatusLabelMap` já existente.

Sem mudança nos filtros existentes (status/fonte/campanha/data) nem no gráfico/top-fontes/top-referrers — leads manuais entram normalmente nesses relatórios, já que continuam usando a mesma coluna `source`.

## Fora de escopo

- Exclusão de lead (não foi pedido).
- Histórico/auditoria de alterações (quem editou o quê e quando) — se vier a ser necessário, é uma extensão futura, não bloqueia esta entrega.
- Import em massa de leads manuais (CSV etc.) — registro é individual, via modal.
- Qualquer mudança nos endpoints/fluxos públicos além de gravar `originType` automaticamente.

## Testes

- Backend: `LeadAdminServiceTest` ganha casos para `createManual()` (feliz, nome ausente, sem contato) e `update()` (feliz, telefone inválido, id inexistente). Teste garantindo que `LeadService.createLead()` grava o `originType` certo nos dois cenários (com e sem e-mail).
- Frontend: `npm run build` limpo + QA manual cobrindo: criar lead manual, editar lead existente (incluindo adicionar telefone a um lead antigo do WhatsApp), coluna Canal/Telefone corretas, filtro e relatório de Top Fontes não quebrando com fonte manual.

## Riscos

Baixo — é uma extensão aditiva de uma tela administrativa já existente, sem tocar em fluxos públicos de captação além de um campo novo (`originType`) preenchido automaticamente. Maior cuidado é validar que o backfill do `origin_type` na migration reflita corretamente os leads antigos (todo lead sem e-mail histórico vira `WHATSAPP_CLICK`, coerente com o único fluxo que hoje cria lead sem e-mail).
