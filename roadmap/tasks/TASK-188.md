# TASK-188 — Backend: criação manual (`POST /admin/leads`) e edição completa (`PUT /admin/leads/{id}`)

## Tipo
BACKEND

## Categoria
Admin / Leads

## Prioridade
🟠 Alto

## Épico
[EPIC-021](../epics/EPIC-021.md) — Painel de Leads (visão agregada + mini-CRM de status), Fase 2

## QA obrigatório
Sim — QA manual: criar lead manual com cada combinação válida de contato (só e-mail, só telefone,
os dois), confirmar rejeição sem nenhum dos dois; editar um lead antigo do WhatsApp e verificar que
o telefone persiste.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-23-leads-screen-improvements-design.md`.

Depende da TASK-187 (`phone`, `origin_type`, enums). Hoje o único jeito de criar um lead é o
endpoint público `POST /landing/leads` (usado pela landing), e o único update possível é
`PATCH /admin/leads/{id}/status`. Esta task dá ao admin a capacidade de registrar leads de fontes
que não passam pela landing (indicação, evento, boca a boca) e de corrigir/completar dados de
qualquer lead já existente — em especial acrescentar o telefone que os leads de clique de WhatsApp
nunca tiveram.

## Objetivo

Dois endpoints novos em `AdminLeadController`: criação manual e edição completa (nome, e-mail,
telefone, fonte).

## Escopo

### 1. DTOs — `LeadAdminDTO`

```java
public record CreateManualLeadRequest(
        @NotBlank String name,
        String email,
        String phone,
        @NotNull ManualLeadSource source
) {}

public record UpdateLeadRequest(
        @NotBlank String name,
        String email,
        String phone,
        String source
) {}
```

`CreateManualLeadRequest.source` usa o enum fechado `ManualLeadSource` (TASK-187) — só faz sentido
pra leads manuais. `UpdateLeadRequest.source` é texto livre porque também precisa aceitar editar um
lead que já tem `utm_source` real vindo de tráfego pago (ex.: corrigir "google" pra "Google Ads").

`LeadAdminDTO.LeadListResponse` ganha `phone` e `originType`:

```java
public record LeadListResponse(
        Long id, String email, String name, String phone, LeadOriginType originType,
        String source, String medium, String campaign, String referrer,
        LeadStatus status, Instant createdAt
) {}
```

### 2. `LeadAdminService` — dois métodos novos

```java
@Transactional
public LeadAdminDTO.LeadListResponse createManual(LeadAdminDTO.CreateManualLeadRequest request) {
    validateHasContact(request.email(), request.phone());
    String normalizedPhone = normalizePhone(request.phone());

    LandingLead lead = LandingLead.builder()
            .name(request.name())
            .email(request.email())
            .phone(normalizedPhone)
            .source(request.source().name())
            .originType(LeadOriginType.MANUAL)
            .status(LeadStatus.NEW)
            .build();

    return toResponse(repository.save(lead));
}

@Transactional
public LeadAdminDTO.LeadListResponse update(Long id, LeadAdminDTO.UpdateLeadRequest request) {
    LandingLead lead = repository.findById(id)
            .orElseThrow(() -> new NotFoundException("Lead não encontrado: " + id));

    validateHasContact(request.email(), request.phone());

    lead.setName(request.name());
    lead.setEmail(request.email());
    lead.setPhone(normalizePhone(request.phone()));
    lead.setSource(request.source());

    return toResponse(repository.save(lead));
}

private void validateHasContact(String email, String phone) {
    boolean hasEmail = email != null && !email.isBlank();
    boolean hasPhone = phone != null && !phone.isBlank();
    if (!hasEmail && !hasPhone) {
        throw new RuleException("Informe pelo menos um contato (e-mail ou telefone).");
    }
}

private String normalizePhone(String rawPhone) {
    if (rawPhone == null || rawPhone.isBlank()) {
        return null;
    }
    return PhoneNumberNormalizer.toE164BR(rawPhone)
            .orElseThrow(() -> new RuleException("Telefone inválido."));
}
```

`toResponse()` (já existente) ganha `phone`/`originType` no mapeamento.

### 3. `AdminLeadController` — dois endpoints novos

```java
@PostMapping
@ResponseStatus(HttpStatus.CREATED)
@Operation(summary = "Registra um lead manualmente (fonte fora do fluxo de captura da landing)")
public LeadAdminDTO.LeadListResponse create(@Valid @RequestBody LeadAdminDTO.CreateManualLeadRequest request) {
    return leadAdminService.createManual(request);
}

@PutMapping("/{id}")
@Operation(summary = "Edita nome/e-mail/telefone/fonte de um lead existente")
public LeadAdminDTO.LeadListResponse update(
        @PathVariable Long id, @Valid @RequestBody LeadAdminDTO.UpdateLeadRequest request) {
    return leadAdminService.update(id, request);
}
```

Mesmo `@RequestMapping`/autenticação já existente de `/private/admin/leads`.

### 4. Testes (`LeadAdminServiceTest`)

- `createManual()`: feliz (com e-mail, com telefone, com os dois); rejeita sem nome; rejeita sem
  nenhum contato; grava `originType = MANUAL` e `source` = nome do enum.
- `update()`: feliz; rejeita telefone inválido (`RuleException`); id inexistente lança
  `NotFoundException`; edição preserva `originType`/`status` (não são alterados por este endpoint).

## Critérios de Aceite

- [x] `POST /admin/leads` cria lead com `originType = MANUAL`, `status = NEW`
- [x] `PUT /admin/leads/{id}` atualiza nome/e-mail/telefone/fonte sem alterar `originType`/`status`
- [x] Ambos rejeitam (400) quando não há nome, ou quando não há nem e-mail nem telefone
- [x] Telefone inválido retorna 400 com mensagem clara, telefone válido é normalizado pra E.164
- [x] Id inexistente em `PUT` retorna 404
- [x] `mvn test` sem regressão

## Dependências
**TASK-187** — precisa de `phone`, `origin_type`, `LeadOriginType`, `ManualLeadSource`.

## Riscos
Baixo — CRUD aditivo sobre uma tabela já existente, endpoints novos não tocam nos fluxos públicos
(`POST /landing/leads`) nem no `PATCH .../status` já existente.

## Esforço
Médio

## Status
✅ Implementada e commitada (23/08/2026) na branch `feature/leads-manual-registration`
(`easy-maintenance-api`, commit `1577bf5`). 8 testes novos em `LeadAdminServiceTest` (11 no total),
0 falhas. PR [#42](https://github.com/douglasjava/easy-maintenance-api/pull/42) aberta em
23/08/2026 (mesma branch reúne toda a Fase 2), validada localmente por Douglas.
