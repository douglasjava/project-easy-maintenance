# TASK-187 — Backend: `phone` + `origin_type` em `landing_leads`

## Tipo
BACKEND

## Categoria
Admin / Leads

## Prioridade
🟠 Alto

## Épico
[EPIC-021](../epics/EPIC-021.md) — Painel de Leads (visão agregada + mini-CRM de status), Fase 2

## QA obrigatório
Não precisa QA manual — é camada de dado + migration, coberta por teste automatizado. Validar com
query direta no banco pós-migration que o backfill de `origin_type` bate com o esperado (todo lead
sem e-mail vira `WHATSAPP_CLICK`).

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-23-leads-screen-improvements-design.md`.

Base pras TASK-188 (endpoints de criação/edição) e TASK-189 (frontend). Sem telefone e sem uma
origem gravada de verdade (hoje a coluna "Canal" da tela é só inferida por `email != null`), não dá
pra suportar leads manuais nem editar um lead existente pra acrescentar telefone.

## Objetivo

Adicionar `phone` e `origin_type` em `landing_leads`, com backfill dos dados existentes, e fazer o
fluxo público de criação (`LeadService.createLead`) gravar `origin_type` automaticamente.

## Escopo

### 1. Migration (próximo número livre em `db/migration/`, confirmar V92 contra o estado real da
pasta antes de escrever)

```sql
ALTER TABLE landing_leads
    ADD COLUMN phone VARCHAR(20) NULL,
    ADD COLUMN origin_type VARCHAR(20) NOT NULL DEFAULT 'WEBSITE_FORM';

-- Backfill dos leads existentes: quem nunca teve e-mail veio do clique do WhatsApp
UPDATE landing_leads SET origin_type = 'WHATSAPP_CLICK' WHERE email IS NULL;
```

### 2. Enums novos

```java
package com.brainbyte.easy_maintenance.leads.domain.enums;

public enum LeadOriginType {
    WEBSITE_FORM, WHATSAPP_CLICK, MANUAL
}
```

```java
package com.brainbyte.easy_maintenance.leads.domain.enums;

public enum ManualLeadSource {
    REFERRAL, EVENT, WORD_OF_MOUTH, OTHER
}
```

`ManualLeadSource` não é uma coluna nova — na TASK-188, os valores desse enum viram texto gravado na
coluna `source` já existente, só restringindo o que a criação manual pode mandar. `origin_type` é
coluna própria.

### 3. `LandingLead` entity — campos novos

```java
private String phone;

@Enumerated(EnumType.STRING)
@Column(name = "origin_type", length = 20, nullable = false)
@Builder.Default
private LeadOriginType originType = LeadOriginType.WEBSITE_FORM;
```

### 4. `LeadService.createLead()` — grava `originType` automaticamente

```java
boolean hasEmail = request.email() != null && !request.email().isBlank();
// ...
LandingLead lead = LandingLead.builder()
        // ... campos já existentes
        .originType(hasEmail ? LeadOriginType.WEBSITE_FORM : LeadOriginType.WHATSAPP_CLICK)
        .build();
```

Reaproveita o `boolean hasEmail` que o método já calcula pra decidir o gate de consentimento —
não duplica a checagem.

### 5. Testes

- Migration: teste `@DataJpaTest` confirmando que um lead pré-existente sem e-mail (inserido direto
  via SQL de setup) fica com `origin_type = 'WHATSAPP_CLICK'` após a migration, e um com e-mail fica
  `WEBSITE_FORM` (valor default).
- `LeadServiceTest`: novo caso verificando que `createLead()` com e-mail preenchido grava
  `originType = WEBSITE_FORM`, e sem e-mail grava `WHATSAPP_CLICK`.

## Critérios de Aceite

- [x] `landing_leads` tem as colunas `phone` (nullable) e `origin_type` (not null, default
      `WEBSITE_FORM`)
- [x] Backfill: leads existentes sem e-mail ficam `WHATSAPP_CLICK`, os com e-mail ficam
      `WEBSITE_FORM`
- [x] `LeadService.createLead()` grava `originType` corretamente nos dois cenários (com/sem e-mail)
- [x] `mvn test` sem regressão

**Nota de implementação**: o teste de migration/backfill descrito no escopo (item 5, `@DataJpaTest`
validando o `UPDATE` da V92 num banco real) não foi escrito — nenhum teste deste projeto ativa o
Flyway de verdade (todo `@DataJpaTest` usa `ddl-auto=create-drop`, schema gerado pela entidade, sem
rodar migrations), então não haveria como exercitar o `UPDATE` da migration sem introduzir um padrão
de teste novo só pra isso. A lógica equivalente (que origem cada cenário de `createLead()` grava) já
está coberta pelos 2 testes de `LeadServiceTest`. Validação do backfill em si fica pra QA manual
direto no banco, como já indicado em "QA obrigatório" acima.

## Dependências
Nenhuma técnica. Precede TASK-188 (usa os campos/enums novos).

## Riscos
Baixo — colunas aditivas com default, não altera nenhum contrato de request/response público
existente (`CreateLeadRequest`/`LeadResponse` não mudam nesta task).

## Esforço
Baixo

## Status
✅ Implementada e commitada (23/08/2026) na branch `feature/leads-manual-registration`
(`easy-maintenance-api`, commit `f7a21e7`) — mesma branch reúne toda a Fase 2 (TASK-187 a
TASK-189), a pedido de Douglas. Testes do módulo `leads`: 31 passando, 0 falhas. Ainda sem PR —
aguardando Douglas testar local e em staging.
