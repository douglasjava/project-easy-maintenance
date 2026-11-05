# WhatsApp Financial Entry Registration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a user register a revenue or expense entry (EPIC-032's `FinancialEntry`) by chatting with the WhatsApp assistant (EPIC-031), the same way they already register a maintenance — and, before building it, replace the two near-duplicate "pending draft" pipeline steps (`RegistrationStep`, `NewOrganizationStep`) with one generic step, so a third capability does not mean a third copy of that logic.

**Architecture:** Two parts. (1) A refactor: a new `PendingActionHandler` interface, implemented by `AssistantRegistrationService` and `AssistantNewOrganizationService`, dispatched by one new `PendingActionStep` (`@Order(47)`) that replaces `RegistrationStep` (`@Order(48)`) and `NewOrganizationStep` (`@Order(47)`). (2) A new capability built on that interface: `AssistantFinancialEntryService`, wired into `IntentStep` under a new `AssistantIntent.REGISTRAR_LANCAMENTO_FINANCEIRO`, that collects type (receita/despesa) → category (4 buttons) → confirm, then calls the existing `FinancialEntryService.create(...)` — no backend change to the finance module itself.

**Tech Stack:** Spring Boot (Java), Spring beans auto-collected by interface (`List<PendingActionHandler>`), Jackson (records, no custom annotations needed — matches `RegistrationDraft`/`NewOrganizationDraft`), JUnit 5 + Mockito + AssertJ.

**Spec:** No written spec file — this is a Bounded change per `superpowers:brainstorming` (a well-scoped change to code that already exists: the EPIC-031 pipeline and the EPIC-032 finance module). The design was presented in chat and approved by the user on 2026-10-05; this plan is the executable form of that approval. Relevant prior docs for context: `docs/superpowers/specs/2026-10-04-financial-entries-design.md` (the finance module this reuses) and `roadmap/epics/EPIC-031.md` (the assistant epic this extends).

## Global Constraints

- Never duplicate business logic already in `FinancialEntryService`/`MaintenanceService` — the assistant only calls the existing service, inside `AssistantUserContext.runAs(user, orgCode, ...)`, same as `AssistantRegistrationService.commit()` and `AssistantNewOrganizationService.commit()`.
- `AssistantAccessGuard.checkWrite` is checked at `start()` AND again at the moment of commit (plan/role may have changed in between) — same double-check pattern as the two existing capabilities.
- No text from the AI ever reaches the user — replies only come from `AssistantMessages` constants (per `IntentStep`'s class comment).
- Every pending draft lives in `assistant_conversations.pending_action_json` with a 30-minute TTL (`PENDING_TTL`), discarded (not silently kept) across an organization switch.
- The AI classifier's intent list is closed (`AssistantIntent` enum) and the JSON contract (`{"intent": ..., "fields": {...}}`) does not change shape — only a new enum value and one new prompt bullet are added.
- No new database column: reuse `AssistantConversation.awaiting` / `pendingActionJson` / `pendingExpiresAt`, exactly as `NEW_ORG` already does.
- Every write into `FinancialEntry` goes through `FinancialEntryService.create`, so its own validation (`validateAmount`, `validateCategoryMatchesType`, `validateEntryDate`, `requireFinancePermission`) is the single source of truth — the assistant never re-validates those rules itself.

## Review Focus

- **Org switch mid-draft**: a financial-entry draft started in org A, then the user switches to org B before confirming — the existing `pendingOrgCode()` mismatch check (mirroring `RegistrationStep`'s `draft.get().orgCode()` comparison) must discard it, not let it commit against the wrong org. Covered in Task 3's `PendingActionStepTest` and Task 6's service test.
- **Role downgraded between start and confirm**: `FinancialEntryService.create` only allows `ADMIN`/`SYNDIC` (not `TECH`, which `AssistantAccessGuard.checkWrite` *does* allow) — a `TECH` user can reach the confirm screen and only then get rejected. The reply must be the generic `FIN_FAILED` with the service's own message, not a crash. Covered in Task 6.
- **Ambiguous or missing amount at the very first message**: "lancei uma despesa" (no number at all) must not create a draft with a null amount that later fails at commit — it must ask for the value immediately and create nothing. Covered in Task 6.
- **Keyword collision between "receita"/"despesa" and neither present**: "paguei a conta de luz" must resolve to EXPENSE (via "paguei"), but plain "200 reais" with no verb must stay ambiguous and ask via buttons, never guess. Covered in Task 5.
- **Expired draft discarded silently vs with notice**: unlike `RegistrationStep`'s per-capability expiry message, the generic `PendingActionStep` must still send the *correct* capability-specific expiry text (`FIN_EXPIRED` vs `REGISTER_EXPIRED` vs `NEWORG_EXPIRED`) — a wrong shared message would be confusing. Covered in Task 3.

---

### Task 1: `PendingActionHandler` interface + `AssistantRegistrationService` implements it

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/PendingActionHandler.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/assistant/domain/AssistantConversation.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/registration/AssistantRegistrationService.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/assistant/application/registration/AssistantRegistrationServiceTest.java`

**Interfaces:**
- Produces: `PendingActionHandler` with methods `String type()`, `boolean isExpired(AssistantConversation conversation)`, `void discard(AssistantConversation conversation)`, `Optional<String> pendingOrgCode(AssistantConversation conversation)`, `String expiredMessage()`, `StepOutcome continuePending(AssistantTurn turn, AssistantConversation conversation)`.
- Produces: `AssistantConversation.AWAITING_REGISTRATION` (new `public static final String` constant, value `"REGISTRATION"`).
- Consumes (unchanged): `AssistantConversation.AWAITING_NEW_ORG` (already exists).

- [ ] **Step 1: Write the failing test — registration now sets `awaiting` explicitly**

Add to `AssistantRegistrationServiceTest.java` (same file, same `@BeforeEach` fixtures already in the file):

```java
@Test
void start_setsAwaitingToRegistration_soPendingActionStepCanRouteToIt() {
    when(guard.checkWrite(identity.user(), ORG)).thenReturn(Optional.empty());
    when(items.findAll(eq(ORG), any(), any(), any(), any())).thenReturn(new PageImpl<>(List.of()));

    service.start(turn("Troquei uma lâmpada hoje"), Map.of());

    assertThat(conversation.getAwaiting()).isEqualTo(AssistantConversation.AWAITING_REGISTRATION);
}

@Test
void commit_clearsAwaiting() {
    conversation.setAwaiting(AssistantConversation.AWAITING_REGISTRATION);
    RegistrationDraft draft = new RegistrationDraft(RegistrationDraft.Stage.CONFIRM, ORG, 1L, "Caixa d'água", null,
            List.of(), TODAY, false, MaintenanceType.PREVENTIVA, false, 5000, null, "troca", List.of(), null);
    when(guard.checkWrite(identity.user(), ORG)).thenReturn(Optional.empty());
    when(maintenances.register(eq(ORG), eq(1L), any(), eq(RecordSource.WHATSAPP)))
            .thenReturn(new MaintenanceResponse(9L, 1L, MaintenanceType.PREVENTIVA, TODAY, null, 5000, null, null, null, null, null));
    when(items.findById(ORG, 1L)).thenReturn(itemResponse(1L, "Caixa d'água", null));

    service.continuePending(turn("confirmar"), conversation, draft);

    assertThat(conversation.getAwaiting()).isNull();
}
```

Use whatever existing helper the file already has for building an `ItemResponse` (check the file for an `itemResponse(...)` helper before adding a new one — the file already builds `ItemResponse` instances in several tests for `commit` scenarios; reuse that helper verbatim rather than inlining the constructor).

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd easy-maintenance-api && mvn -q -Dtest=AssistantRegistrationServiceTest test`
Expected: both new tests FAIL — `start_setsAwaitingToRegistration...` fails because `conversation.getAwaiting()` is `null` (nothing sets it today); `commit_clearsAwaiting` fails with a `NoSuchFieldError`-style compile error on `AssistantConversation.AWAITING_REGISTRATION` not existing yet.

- [ ] **Step 3: Add the constant and implement the interface**

In `AssistantConversation.java`, add next to the existing constants:

```java
    public static final String AWAITING_ORG_SELECTION = "ORG_SELECTION";
    /** TASK-308: cadastro de empresa nova em andamento (rascunho em pending_action_json). */
    public static final String AWAITING_NEW_ORG = "NEW_ORG";
    /** EPIC-031 Onda 2 (TASK-330): registro de manutenção aguardando confirmação. */
    public static final String AWAITING_REGISTRATION = "REGISTRATION";
```

Create `PendingActionHandler.java`:

```java
package com.brainbyte.easy_maintenance.assistant.application.pipeline;

import com.brainbyte.easy_maintenance.assistant.domain.AssistantConversation;

import java.util.Optional;

/**
 * EPIC-031 (TASK-330): uma capacidade do assistente que fica aguardando confirmação em múltiplos
 * turnos (registro de manutenção, cadastro de empresa nova, lançamento financeiro...). Cada
 * capacidade tem seu próprio rascunho (JSON) e sua própria máquina de estados — esta interface só
 * padroniza "tem pendência? expirou? é de qual organização? continue". {@link PendingActionStep}
 * é a ÚNICA etapa de pipeline que precisa existir por capacidade pendente: ela despacha para o
 * handler certo pelo valor de {@link AssistantConversation#getAwaiting()}.
 */
public interface PendingActionHandler {

    /** Valor de {@link AssistantConversation#getAwaiting()} que este handler possui. */
    String type();

    boolean isExpired(AssistantConversation conversation);

    /** Descarta o rascunho (sem responder nada — quem chama decide a mensagem). */
    void discard(AssistantConversation conversation);

    /**
     * Organização do rascunho pendente, se a capacidade for presa a uma organização (registro,
     * lançamento financeiro). {@link Optional#empty()} quando a capacidade não é de uma
     * organização específica (cadastro de empresa nova) — nesse caso {@link PendingActionStep}
     * não faz a checagem de troca de organização.
     */
    Optional<String> pendingOrgCode(AssistantConversation conversation);

    /** Mensagem a enviar quando {@link #isExpired} for true e o rascunho for descartado. */
    String expiredMessage();

    StepOutcome continuePending(AssistantTurn turn, AssistantConversation conversation);
}
```

In `AssistantRegistrationService.java`:
1. Add `implements PendingActionHandler` to the class declaration.
2. Replace the `pending`/`isExpired`/`discard` block (lines 240-268) with:

```java
    @Override
    public String type() {
        return AssistantConversation.AWAITING_REGISTRATION;
    }

    public Optional<RegistrationDraft> pending(AssistantConversation conversation) {
        if (!type().equals(conversation.getAwaiting()) || conversation.getPendingActionJson() == null || isExpired(conversation)) {
            return Optional.empty();
        }
        try {
            return Optional.of(objectMapper.readValue(conversation.getPendingActionJson(), RegistrationDraft.class));
        } catch (Exception e) {
            log.warn("[Assistant] Rascunho de registro ilegível — descartado: {}", e.getMessage());
            clearPending(conversation);
            return Optional.empty();
        }
    }

    @Override
    public boolean isExpired(AssistantConversation conversation) {
        return type().equals(conversation.getAwaiting()) && conversation.getPendingExpiresAt() != null
                && conversation.getPendingExpiresAt().isBefore(Instant.now(clock));
    }

    @Override
    public void discard(AssistantConversation conversation) {
        clearPending(conversation);
    }

    @Override
    public Optional<String> pendingOrgCode(AssistantConversation conversation) {
        return pending(conversation).map(RegistrationDraft::orgCode);
    }

    @Override
    public String expiredMessage() {
        return AssistantMessages.REGISTER_EXPIRED;
    }
```

3. Remove the now-unused `newOrganizationInProgress(...)` private method entirely (its job is now `type().equals(conversation.getAwaiting())`, inlined above).
4. In `savePending(...)`, set the discriminator before saving:

```java
    private void savePending(AssistantConversation conversation, RegistrationDraft draft) {
        try {
            conversation.setPendingActionJson(objectMapper.writeValueAsString(draft));
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao serializar o rascunho do registro", e);
        }
        conversation.setAwaiting(AssistantConversation.AWAITING_REGISTRATION);
        conversation.setPendingExpiresAt(Instant.now(clock).plus(PENDING_TTL));
        conversations.save(conversation);
    }
```

5. In `clearPending(...)`, clear it too:

```java
    private void clearPending(AssistantConversation conversation) {
        conversation.setAwaiting(null);
        conversation.setPendingActionJson(null);
        conversation.setPendingExpiresAt(null);
        conversations.save(conversation);
    }
```

6. `continuePending(AssistantTurn turn, AssistantConversation conversation, RegistrationDraft draft)` already exists with this exact signature — it does NOT need to change, but it does not yet satisfy the interface's `continuePending(AssistantTurn, AssistantConversation)` (two-arg) signature. Add a second, interface-satisfying overload right next to it:

```java
    @Override
    public StepOutcome continuePending(AssistantTurn turn, AssistantConversation conversation) {
        Optional<RegistrationDraft> draft = pending(conversation);
        if (draft.isEmpty()) {
            return StepOutcome.next();
        }
        return continuePending(turn, conversation, draft.get());
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd easy-maintenance-api && mvn -q -Dtest=AssistantRegistrationServiceTest test`
Expected: all tests in the file PASS, including the two new ones. The pre-existing `pendingNewOrganization_isNotARegistrationDraft` test (line ~505) must still pass unmodified — it sets `conversation.setAwaiting(AssistantConversation.AWAITING_NEW_ORG)` and asserts `service.pending(conversation)` is empty, which now holds because `AWAITING_NEW_ORG != AWAITING_REGISTRATION`.

- [ ] **Step 5: Commit**

```bash
cd easy-maintenance-api
git add src/main/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/PendingActionHandler.java src/main/java/com/brainbyte/easy_maintenance/assistant/domain/AssistantConversation.java src/main/java/com/brainbyte/easy_maintenance/assistant/application/registration/AssistantRegistrationService.java src/test/java/com/brainbyte/easy_maintenance/assistant/application/registration/AssistantRegistrationServiceTest.java
git commit -m "feat(assistant): PendingActionHandler interface; registration implements it (EPIC-031 TASK-330)"
```

---

### Task 2: `AssistantNewOrganizationService` implements `PendingActionHandler`

**Files:**
- Modify: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/organization/AssistantNewOrganizationService.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/assistant/application/organization/AssistantNewOrganizationServiceTest.java`

**Interfaces:**
- Consumes: `PendingActionHandler` (Task 1).
- Produces: `AssistantNewOrganizationService` now satisfies `PendingActionHandler`; `pendingOrgCode()` always returns `Optional.empty()` (new-organization is an account-level draft, not tied to an existing org — matches today's `NewOrganizationStep`, which never checks org).

- [ ] **Step 1: Write the failing test**

Add to `AssistantNewOrganizationServiceTest.java`:

```java
@Test
void type_isNewOrgConstant() {
    assertThat(service.type()).isEqualTo(AssistantConversation.AWAITING_NEW_ORG);
}

@Test
void pendingOrgCode_isAlwaysEmpty_becauseNewOrgIsNotTiedToAnOrganization() {
    AssistantConversation conversation = AssistantConversation.builder().userId(24L).build();
    conversation.setAwaiting(AssistantConversation.AWAITING_NEW_ORG);
    conversation.setPendingActionJson("{\"stage\":\"NAME\",\"name\":null}");

    assertThat(service.pendingOrgCode(conversation)).isEmpty();
}

@Test
void expiredMessage_isNeworgExpired() {
    assertThat(service.expiredMessage()).isEqualTo(AssistantMessages.NEWORG_EXPIRED);
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd easy-maintenance-api && mvn -q -Dtest=AssistantNewOrganizationServiceTest test`
Expected: FAIL to compile — `service.type()`, `service.pendingOrgCode(...)`, `service.expiredMessage()` do not exist yet.

- [ ] **Step 3: Implement the interface**

In `AssistantNewOrganizationService.java`:
1. Add `implements PendingActionHandler` to the class declaration (import `com.brainbyte.easy_maintenance.assistant.application.pipeline.PendingActionHandler`).
2. Add three methods and one overload next to the existing `isActive`/`isExpired`/`discard`/`pending`:

```java
    @Override
    public String type() {
        return AssistantConversation.AWAITING_NEW_ORG;
    }

    @Override
    public Optional<String> pendingOrgCode(AssistantConversation conversation) {
        return Optional.empty();
    }

    @Override
    public String expiredMessage() {
        return AssistantMessages.NEWORG_EXPIRED;
    }

    @Override
    public StepOutcome continuePending(AssistantTurn turn, AssistantConversation conversation) {
        Optional<NewOrganizationDraft> draft = pending(conversation);
        if (draft.isEmpty()) {
            return StepOutcome.next();
        }
        return continuePending(turn, conversation, draft.get());
    }
```

3. Leave `isExpired(AssistantConversation)` as-is — it already has the exact signature the interface requires and already returns correctly (`@Override` annotation can be added to it for clarity, no behavior change).
4. Leave `discard(AssistantConversation)` as-is for the same reason.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd easy-maintenance-api && mvn -q -Dtest=AssistantNewOrganizationServiceTest test`
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
cd easy-maintenance-api
git add src/main/java/com/brainbyte/easy_maintenance/assistant/application/organization/AssistantNewOrganizationService.java src/test/java/com/brainbyte/easy_maintenance/assistant/application/organization/AssistantNewOrganizationServiceTest.java
git commit -m "feat(assistant): AssistantNewOrganizationService implements PendingActionHandler (EPIC-031 TASK-330)"
```

---

### Task 3: `PendingActionStep` replaces `RegistrationStep` + `NewOrganizationStep`

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/PendingActionStep.java`
- Create: `src/test/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/PendingActionStepTest.java`
- Delete: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/RegistrationStep.java`
- Delete: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/NewOrganizationStep.java`
- Delete: `src/test/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/RegistrationStepTest.java`
- Delete: `src/test/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/NewOrganizationStepTest.java`

**Interfaces:**
- Consumes: `PendingActionHandler` (Task 1), with `AssistantRegistrationService`/`AssistantNewOrganizationService` as its two current implementations (Spring collects every `PendingActionHandler` bean into `List<PendingActionHandler>` automatically).
- Produces: `PendingActionStep`, `@Order(47)` — the single pipeline step occupying the order range that `NewOrganizationStep` (47) and `RegistrationStep` (48) used to split between them. `IntentStep` (still `@Order(50)`) is unaffected.

- [ ] **Step 1: Write the failing test**

Create `PendingActionStepTest.java`:

```java
package com.brainbyte.easy_maintenance.assistant.application.pipeline;

import com.brainbyte.easy_maintenance.assistant.application.conversation.AssistantConversationService;
import com.brainbyte.easy_maintenance.assistant.application.identity.AssistantIdentity;
import com.brainbyte.easy_maintenance.assistant.application.reply.AssistantReplyPort;
import com.brainbyte.easy_maintenance.assistant.application.worker.MergedInbound;
import com.brainbyte.easy_maintenance.assistant.domain.AssistantConversation;
import com.brainbyte.easy_maintenance.org_users.domain.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class PendingActionStepTest {

    private final AssistantConversationService conversations = mock(AssistantConversationService.class);
    private final AssistantReplyPort reply = mock(AssistantReplyPort.class);
    private final PendingActionHandler registration = mock(PendingActionHandler.class);
    private final PendingActionHandler newOrg = mock(PendingActionHandler.class);
    private final PendingActionStep step = new PendingActionStep(conversations, List.of(registration, newOrg), reply);
    private final AssistantConversation conversation = AssistantConversation.builder().userId(24L).build();

    @BeforeEach
    void setUp() {
        when(conversations.getOrCreate(24L)).thenReturn(conversation);
        when(registration.type()).thenReturn("REGISTRATION");
        when(newOrg.type()).thenReturn("NEW_ORG");
    }

    private AssistantTurn turn() {
        AssistantTurn t = new AssistantTurn(new MergedInbound("5531", List.of(1L), "w.1", "sim", null, List.of(), false));
        User u = new User();
        u.setId(24L);
        t.setIdentity(new AssistantIdentity(u, List.of()));
        t.setOrganization("ORG-1", "Acácias");
        return t;
    }

    @Test
    void noAwaiting_goesOnToIntent() {
        assertThat(step.apply(turn()).stop()).isFalse();
        verifyNoInteractions(registration, newOrg);
    }

    @Test
    void awaitingRegistration_routesToTheRegistrationHandler_notNewOrg() {
        conversation.setAwaiting("REGISTRATION");
        when(registration.isExpired(conversation)).thenReturn(false);
        when(registration.pendingOrgCode(conversation)).thenReturn(Optional.of("ORG-1"));
        when(registration.continuePending(any(), any())).thenReturn(StepOutcome.done());

        assertThat(step.apply(turn()).stop()).isTrue();
        verify(registration).continuePending(any(), eq(conversation));
        verifyNoInteractions(newOrg);
    }

    @Test
    void expired_discardsAndSendsTheHandlersOwnExpiredMessage() {
        conversation.setAwaiting("REGISTRATION");
        when(registration.isExpired(conversation)).thenReturn(true);
        when(registration.expiredMessage()).thenReturn("expirou o registro");

        assertThat(step.apply(turn()).stop()).isFalse();
        verify(registration).discard(conversation);
        verify(reply).sendText("5531", "expirou o registro");
        verify(registration, never()).continuePending(any(), any());
    }

    @Test
    void pendingFromAnotherOrganization_isDiscarded_withoutContinuing() {
        conversation.setAwaiting("REGISTRATION");
        when(registration.isExpired(conversation)).thenReturn(false);
        when(registration.pendingOrgCode(conversation)).thenReturn(Optional.of("ORG-2"));

        assertThat(step.apply(turn()).stop()).isFalse();
        verify(registration).discard(conversation);
        verify(registration, never()).continuePending(any(), any());
    }

    @Test
    void handlerWithNoOrgAffinity_skipsTheOrgCheck() {
        conversation.setAwaiting("NEW_ORG");
        when(newOrg.isExpired(conversation)).thenReturn(false);
        when(newOrg.pendingOrgCode(conversation)).thenReturn(Optional.empty());
        when(newOrg.continuePending(any(), any())).thenReturn(StepOutcome.done());

        assertThat(step.apply(turn()).stop()).isTrue();
        verify(newOrg).continuePending(any(), eq(conversation));
    }

    private static <T> T eq(T value) {
        return org.mockito.ArgumentMatchers.eq(value);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd easy-maintenance-api && mvn -q -Dtest=PendingActionStepTest test`
Expected: FAIL to compile — `PendingActionStep` class does not exist yet.

- [ ] **Step 3: Implement `PendingActionStep` and delete the two old steps**

Create `PendingActionStep.java`:

```java
package com.brainbyte.easy_maintenance.assistant.application.pipeline;

import com.brainbyte.easy_maintenance.assistant.application.conversation.AssistantConversationService;
import com.brainbyte.easy_maintenance.assistant.application.reply.AssistantReplyPort;
import com.brainbyte.easy_maintenance.assistant.domain.AssistantConversation;
import lombok.RequiredArgsConstructor;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

/**
 * Etapa 47 (EPIC-031, TASK-330): com uma capacidade aguardando confirmação (registro de
 * manutenção, cadastro de empresa nova, lançamento financeiro...), a mensagem é tratada aqui —
 * antes da IA, sem gastar crédito. Despacha pelo {@link AssistantConversation#getAwaiting()} para
 * o {@link PendingActionHandler} certo; cada capacidade nova só precisa implementar a interface e
 * virar um bean — nenhuma classe de pipeline nova. Substitui RegistrationStep + NewOrganizationStep.
 */
@Component
@Order(47)
@RequiredArgsConstructor
public class PendingActionStep implements AssistantStep {

    private final AssistantConversationService conversations;
    private final List<PendingActionHandler> handlers;
    private final AssistantReplyPort reply;

    @Override
    public StepOutcome apply(AssistantTurn turn) {
        if (!turn.hasIdentity() || turn.orgCode() == null) {
            return StepOutcome.next();
        }
        AssistantConversation conversation = conversations.getOrCreate(turn.identity().userId());
        String awaiting = conversation.getAwaiting();
        if (awaiting == null) {
            return StepOutcome.next();
        }
        PendingActionHandler handler = handlers.stream()
                .filter(h -> h.type().equals(awaiting))
                .findFirst()
                .orElse(null);
        if (handler == null) {
            // awaiting de algo que não é uma pendência deste tipo (ex.: ORG_SELECTION) — segue normalmente.
            return StepOutcome.next();
        }
        if (handler.isExpired(conversation)) {
            handler.discard(conversation);
            reply.sendText(turn.inbound().waId(), handler.expiredMessage());
            return StepOutcome.next();
        }
        Optional<String> draftOrg = handler.pendingOrgCode(conversation);
        if (draftOrg.isPresent() && !turn.orgCode().equals(draftOrg.get())) {
            handler.discard(conversation);
            return StepOutcome.next();
        }
        return handler.continuePending(turn, conversation);
    }
}
```

Delete `RegistrationStep.java`, `NewOrganizationStep.java`, `RegistrationStepTest.java`, `NewOrganizationStepTest.java`.

In `IntentStepTest.java`, remove the now-dead `runsBeforeRegistration` test if one exists checking `@Order` of `NewOrganizationStep`/`RegistrationStep` (search the test sources: `grep -rn "RegistrationStep.class\|NewOrganizationStep.class" src/test` and delete any test method referencing either class — they no longer exist).

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd easy-maintenance-api && mvn -q -Dtest=PendingActionStepTest,AssistantRegistrationServiceTest,AssistantNewOrganizationServiceTest,IntentStepTest test`
Expected: all PASS. Then run `mvn -q -Dtest=com.brainbyte.easy_maintenance.assistant.** test` to confirm nothing else in the assistant package references the deleted classes.

- [ ] **Step 5: Commit**

```bash
cd easy-maintenance-api
git add -A src/main/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/ src/test/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/
git commit -m "refactor(assistant): PendingActionStep replaces RegistrationStep+NewOrganizationStep (EPIC-031 TASK-330)"
```

---

### Task 4: `AssistantIntent.REGISTRAR_LANCAMENTO_FINANCEIRO` + AI prompt + messages

**Files:**
- Modify: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/intent/AssistantIntent.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/intent/AiIntentClassifier.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/reply/AssistantMessages.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/assistant/application/intent/AiIntentClassifierTest.java`

**Interfaces:**
- Produces: `AssistantIntent.REGISTRAR_LANCAMENTO_FINANCEIRO` (new enum value, consumed by Task 7's `IntentStep` case).
- Produces: message constants `AssistantMessages.FIN_HOW`, `FIN_CHOOSE_TYPE`, `FIN_CHOOSE_CATEGORY`, `FIN_SUMMARY_TITLE`, `FIN_CONFIRM_FIRST`, `FIN_FIX_PROMPT`, `FIN_CANCELLED`, `FIN_EXPIRED`, `FIN_FAILED`, `FIN_DONE`, `FIN_SEE` (consumed by Task 6).

- [ ] **Step 1: Write the failing test**

Add to `AiIntentClassifierTest.java` (find the existing test that asserts parsing of a known intent's JSON, e.g. for `REGISTRAR_MANUTENCAO`, and add a sibling):

```java
@Test
void parse_registrarLancamentoFinanceiro_isRecognized() {
    String raw = "{\"intent\": \"REGISTRAR_LANCAMENTO_FINANCEIRO\", \"fields\": {\"tipo\": \"despesa\", \"custo\": \"200\"}}";

    ClassifiedIntent result = classifier.parse(raw);

    assertThat(result.intent()).isEqualTo(AssistantIntent.REGISTRAR_LANCAMENTO_FINANCEIRO);
    assertThat(result.fields()).containsEntry("tipo", "despesa").containsEntry("custo", "200");
}
```

(Match the exact field/variable names already used by the neighboring test in that file — e.g. if the existing tests call the field `classifier` vs construct one locally, follow that file's own pattern rather than this snippet's name.)

- [ ] **Step 2: Run test to verify it fails**

Run: `cd easy-maintenance-api && mvn -q -Dtest=AiIntentClassifierTest test`
Expected: FAIL to compile — `AssistantIntent.REGISTRAR_LANCAMENTO_FINANCEIRO` does not exist yet.

- [ ] **Step 3: Add the enum value, prompt bullet, and messages**

In `AssistantIntent.java`, add one value to the closed list:

```java
public enum AssistantIntent {
    CONSULTAR_VENCIMENTOS,
    CONSULTAR_VENCIDOS,
    HISTORICO_ITEM,
    INDICE_CONFORMIDADE,
    REGISTRAR_MANUTENCAO,
    REGISTRAR_LANCAMENTO_FINANCEIRO,
    NOVO_CONDOMINIO,
    RELATORIO,
    TROCAR_ORGANIZACAO,
    AJUDA,
    FORA_DO_ESCOPO
}
```

In `AiIntentClassifier.java`'s `SYSTEM_PROMPT`, add one bullet right after the `REGISTRAR_MANUTENCAO` line:

```
            - REGISTRAR_MANUTENCAO: informa uma manutenção feita (o que foi feito, quando, custo)
            - REGISTRAR_LANCAMENTO_FINANCEIRO: informa uma receita ou despesa do condomínio não ligada a manutenção (ex.: taxa recebida, conta de luz, salário de funcionário)
            - NOVO_CONDOMINIO: quer cadastrar um condomínio ou empresa novo
```

No change to `FIELD_KEYS` or the "Campos permitidos" line — this intent reuses the existing `tipo`, `custo`, `data` field keys (interpreted as receita/despesa, valor, and data do lançamento respectively by Task 5/6's own parser, independently of what `REGISTRAR_MANUTENCAO` does with the same keys).

In `AssistantMessages.java`, add a new block (after the existing `NEWORG_*` block, following the same `public static final String` + doc-comment-above-block style already used for the `REGISTER_*`/`NEWORG_*` sections):

```java
    // EPIC-031 Onda 2 (TASK-330): lançamento financeiro (receita/despesa) pelo WhatsApp.
    public static final String FIN_HOW =
            "Me diga o valor e se é receita ou despesa (ex.: \"gastei 200 com a conta de luz\" ou \"recebi 500 de taxa\").";
    public static final String FIN_CHOOSE_TYPE = "É receita ou despesa?";
    public static final String FIN_CHOOSE_CATEGORY = "Qual categoria?";
    public static final String FIN_SUMMARY_TITLE = "Confere o lançamento? 📝";
    public static final String FIN_CONFIRM_FIRST = "Antes, confirme (ou corrija/cancele) o lançamento acima 👆";
    public static final String FIN_FIX_PROMPT = "Me diga o que corrigir (valor, data, tipo ou categoria).";
    public static final String FIN_CANCELLED = "Lançamento cancelado. Nada foi salvo.";
    public static final String FIN_EXPIRED = "O lançamento que estava aguardando confirmação expirou e foi descartado.";
    public static final String FIN_FAILED = "Não consegui lançar: %s";
    public static final String FIN_DONE = "✅ Lançado! %s de %s em %s.";
    public static final String FIN_SEE = "Ver no sistema: %s";
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd easy-maintenance-api && mvn -q -Dtest=AiIntentClassifierTest test`
Expected: PASS, including the new test and every pre-existing one in the file (the closed-list `default -> FORA_DO_ESCOPO` fallback in `parse()` is unaffected by adding one more valid name to match against).

- [ ] **Step 5: Commit**

```bash
cd easy-maintenance-api
git add src/main/java/com/brainbyte/easy_maintenance/assistant/application/intent/AssistantIntent.java src/main/java/com/brainbyte/easy_maintenance/assistant/application/intent/AiIntentClassifier.java src/main/java/com/brainbyte/easy_maintenance/assistant/application/reply/AssistantMessages.java src/test/java/com/brainbyte/easy_maintenance/assistant/application/intent/AiIntentClassifierTest.java
git commit -m "feat(assistant): REGISTRAR_LANCAMENTO_FINANCEIRO intent + prompt bullet + messages (EPIC-031 TASK-330)"
```

---

### Task 5: `AssistantFinancialEntryParser` (type keyword parsing)

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/finance/AssistantFinancialEntryParser.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/assistant/application/finance/AssistantFinancialEntryParserTest.java`

**Interfaces:**
- Produces: `AssistantFinancialEntryParser.parseType(String text)` → `FinancialEntryType` or `null`.
- Consumes (unchanged, reused directly by Task 6, not by this task): `com.brainbyte.easy_maintenance.assistant.application.registration.RegistrationParser.parseDate(String, LocalDate)` and `.parseCostCents(String)` — both already `public static`, importable across packages.

- [ ] **Step 1: Write the failing test**

Create `AssistantFinancialEntryParserTest.java`:

```java
package com.brainbyte.easy_maintenance.assistant.application.finance;

import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AssistantFinancialEntryParserTest {

    @Test
    void recognizesExpenseVerbs() {
        assertThat(AssistantFinancialEntryParser.parseType("paguei a conta de luz, 200 reais")).isEqualTo(FinancialEntryType.EXPENSE);
        assertThat(AssistantFinancialEntryParser.parseType("gastei 50 com material")).isEqualTo(FinancialEntryType.EXPENSE);
        assertThat(AssistantFinancialEntryParser.parseType("é uma despesa de 30")).isEqualTo(FinancialEntryType.EXPENSE);
    }

    @Test
    void recognizesRevenueVerbs() {
        assertThat(AssistantFinancialEntryParser.parseType("recebi 500 de taxa condominial")).isEqualTo(FinancialEntryType.REVENUE);
        assertThat(AssistantFinancialEntryParser.parseType("entrou uma receita de 100")).isEqualTo(FinancialEntryType.REVENUE);
    }

    @Test
    void ambiguousOrNeitherKeyword_returnsNull() {
        assertThat(AssistantFinancialEntryParser.parseType("200 reais")).isNull();
        assertThat(AssistantFinancialEntryParser.parseType("")).isNull();
        assertThat(AssistantFinancialEntryParser.parseType(null)).isNull();
    }

    @Test
    void bothKeywordsPresent_isAmbiguous_returnsNull() {
        assertThat(AssistantFinancialEntryParser.parseType("foi receita ou despesa, não lembro")).isNull();
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd easy-maintenance-api && mvn -q -Dtest=AssistantFinancialEntryParserTest test`
Expected: FAIL to compile — `AssistantFinancialEntryParser` does not exist yet.

- [ ] **Step 3: Implement the parser**

```java
package com.brainbyte.easy_maintenance.assistant.application.finance;

import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;

import java.text.Normalizer;
import java.util.Locale;
import java.util.Set;

/**
 * EPIC-031 Onda 2 (TASK-330): leitura determinística de "é receita ou despesa" em linguagem
 * natural — mesmo espírito de RegistrationParser (nada aqui chama IA). Valor e data do
 * lançamento reaproveitam RegistrationParser.parseCostCents/parseDate diretamente (genéricos,
 * não específicos de manutenção).
 */
public final class AssistantFinancialEntryParser {

    private static final Set<String> EXPENSE_WORDS = Set.of(
            "despesa", "gastei", "gasto", "paguei", "pago", "saiu", "custou");
    private static final Set<String> REVENUE_WORDS = Set.of(
            "receita", "recebi", "recebimento", "entrou", "entrada");

    private AssistantFinancialEntryParser() {
    }

    public static FinancialEntryType parseType(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }
        String t = normalize(text);
        boolean expense = EXPENSE_WORDS.stream().anyMatch(t::contains);
        boolean revenue = REVENUE_WORDS.stream().anyMatch(t::contains);
        if (expense && !revenue) {
            return FinancialEntryType.EXPENSE;
        }
        if (revenue && !expense) {
            return FinancialEntryType.REVENUE;
        }
        return null;
    }

    private static String normalize(String value) {
        return Normalizer.normalize(value, Normalizer.Form.NFD).replaceAll("\\p{M}", "").toLowerCase(Locale.ROOT);
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd easy-maintenance-api && mvn -q -Dtest=AssistantFinancialEntryParserTest test`
Expected: PASS, 4/4.

- [ ] **Step 5: Commit**

```bash
cd easy-maintenance-api
git add src/main/java/com/brainbyte/easy_maintenance/assistant/application/finance/AssistantFinancialEntryParser.java src/test/java/com/brainbyte/easy_maintenance/assistant/application/finance/AssistantFinancialEntryParserTest.java
git commit -m "feat(assistant): AssistantFinancialEntryParser - receita/despesa por palavra-chave (EPIC-031 TASK-330)"
```

---

### Task 6: `FinancialEntryDraft` + `AssistantFinancialEntryService`

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/finance/FinancialEntryDraft.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/finance/AssistantFinancialEntryService.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/reply/AssistantLinks.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/assistant/application/finance/AssistantFinancialEntryServiceTest.java`

**Interfaces:**
- Consumes: `PendingActionHandler` (Task 1), `AssistantFinancialEntryParser.parseType` (Task 5), `RegistrationParser.parseDate`/`.parseCostCents` (existing, `assistant.application.registration` package), `FinancialEntryService.create(String orgId, CreateFinancialEntryRequest req)` (existing, throws `RuleException`/`ForbiddenException`), `AssistantMessages.FIN_*` (Task 4), `AssistantConversation.AWAITING_FINANCIAL_ENTRY` (new constant, this task).
- Produces: `AssistantFinancialEntryService.start(AssistantTurn turn, Map<String, String> fields)` → `StepOutcome` (consumed by Task 7's `IntentStep`).

- [ ] **Step 1: Write the failing tests**

Create `FinancialEntryDraft.java` test coverage is folded into the service test below (the record has no behavior worth testing in isolation beyond what the service test already exercises through `start`/`continuePending`/`commit`).

Create `AssistantFinancialEntryServiceTest.java`:

```java
package com.brainbyte.easy_maintenance.assistant.application.finance;

import com.brainbyte.easy_maintenance.assistant.AssistantTestFixtures;
import com.brainbyte.easy_maintenance.assistant.application.access.AssistantAccessGuard;
import com.brainbyte.easy_maintenance.assistant.application.access.AssistantUserContext;
import com.brainbyte.easy_maintenance.assistant.application.conversation.AssistantConversationService;
import com.brainbyte.easy_maintenance.assistant.application.identity.AssistantIdentity;
import com.brainbyte.easy_maintenance.assistant.application.identity.AssistantOrg;
import com.brainbyte.easy_maintenance.assistant.application.pipeline.AssistantTurn;
import com.brainbyte.easy_maintenance.assistant.application.pipeline.StepOutcome;
import com.brainbyte.easy_maintenance.assistant.application.reply.AssistantMessages;
import com.brainbyte.easy_maintenance.assistant.application.reply.AssistantOption;
import com.brainbyte.easy_maintenance.assistant.application.reply.AssistantReplyPort;
import com.brainbyte.easy_maintenance.assistant.application.worker.MergedInbound;
import com.brainbyte.easy_maintenance.assistant.domain.AssistantConversation;
import com.brainbyte.easy_maintenance.commons.exceptions.ForbiddenException;
import com.brainbyte.easy_maintenance.finance.application.dto.CreateFinancialEntryRequest;
import com.brainbyte.easy_maintenance.finance.application.dto.FinancialEntryResponse;
import com.brainbyte.easy_maintenance.finance.application.service.FinancialEntryService;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryCategory;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;
import com.brainbyte.easy_maintenance.infrastructure.audit.AuditService;
import com.brainbyte.easy_maintenance.org_users.domain.User;
import com.brainbyte.easy_maintenance.org_users.domain.enums.Role;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.transaction.PlatformTransactionManager;

import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class AssistantFinancialEntryServiceTest {

    private static final String ORG = "ORG-1";
    private static final ZoneId SP = ZoneId.of("America/Sao_Paulo");
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 5);

    private final AssistantConversationService conversations = mock(AssistantConversationService.class);
    private final AssistantAccessGuard guard = mock(AssistantAccessGuard.class);
    private final FinancialEntryService financialEntryService = mock(FinancialEntryService.class);
    private final AssistantReplyPort reply = mock(AssistantReplyPort.class);
    private final AuditService audit = mock(AuditService.class);
    private final Clock clock = Clock.fixed(ZonedDateTime.of(TODAY.atTime(10, 0), SP).toInstant(), SP);

    private final AssistantFinancialEntryService service = new AssistantFinancialEntryService(conversations, guard,
            new AssistantUserContext(), financialEntryService, reply, audit, AssistantTestFixtures.enabledFor(24L),
            new ObjectMapper().findAndRegisterModules(), mock(PlatformTransactionManager.class), clock);

    private AssistantConversation conversation;
    private AssistantIdentity identity;

    @BeforeEach
    void setUp() {
        User u = new User();
        u.setId(24L);
        u.setRole(Role.SYNDIC);
        identity = new AssistantIdentity(u, List.of(new AssistantOrg(ORG, "Acácias")));
        conversation = AssistantConversation.builder().userId(24L).build();
        when(conversations.getOrCreate(24L)).thenReturn(conversation);
        when(guard.checkWrite(u, ORG)).thenReturn(Optional.empty());
    }

    private AssistantTurn turn(String text) {
        AssistantTurn t = new AssistantTurn(new MergedInbound("5531", List.of(1L), "w.1", text, null, List.of(), false));
        t.setIdentity(identity);
        t.setOrganization(ORG, "Acácias");
        return t;
    }

    @Test
    void start_withNoAmount_asksForItAndSavesNoDraft() {
        StepOutcome outcome = service.start(turn("lancei uma despesa"), Map.of());

        assertThat(outcome.stop()).isTrue();
        verify(reply).sendText("5531", AssistantMessages.FIN_HOW);
        assertThat(conversation.getPendingActionJson()).isNull();
    }

    @Test
    void start_withAmountButNoType_asksTypeViaButtons_andSavesDraft() {
        service.start(turn("paguei 200 reais"), Map.of());

        assertThat(conversation.getAwaiting()).isEqualTo(AssistantConversation.AWAITING_FINANCIAL_ENTRY);
        verify(reply).sendOptions(eq("5531"), eq(AssistantMessages.FIN_HOW.equals(AssistantMessages.FIN_HOW) ? AssistantMessages.FIN_CHOOSE_TYPE : null), any());
    }

    @Test
    void start_withAmountAndType_goesStraightToChooseCategory() {
        service.start(turn("gastei 200 com a conta de luz"), Map.of());

        assertThat(conversation.getAwaiting()).isEqualTo(AssistantConversation.AWAITING_FINANCIAL_ENTRY);
        verify(reply).sendOptions(eq("5531"), eq(AssistantMessages.FIN_CHOOSE_CATEGORY), argThat(options ->
                ((List<AssistantOption>) options).stream().anyMatch(o -> o.id().contains("CONTA_CONSUMO"))));
    }

    @Test
    void chooseCategory_thenConfirm_commitsThroughFinancialEntryService() {
        FinancialEntryDraft draft = new FinancialEntryDraft(FinancialEntryDraft.Stage.CONFIRM, ORG,
                FinancialEntryType.EXPENSE, FinancialEntryCategory.CONTA_CONSUMO, 20000, "conta de luz", TODAY);
        when(financialEntryService.create(eq(ORG), any(CreateFinancialEntryRequest.class)))
                .thenReturn(new FinancialEntryResponse(99L, FinancialEntryType.EXPENSE, FinancialEntryCategory.CONTA_CONSUMO,
                        20000, "conta de luz", TODAY, 24L, java.time.Instant.now(clock)));

        StepOutcome outcome = service.continuePending(turn("confirmar"), conversation, draft);

        assertThat(outcome.stop()).isTrue();
        verify(financialEntryService).create(ORG, new CreateFinancialEntryRequest(
                FinancialEntryType.EXPENSE, FinancialEntryCategory.CONTA_CONSUMO, 20000, "conta de luz", TODAY));
        verify(audit).log(eq("FINANCIAL_ENTRY"), eq("99"), any(), any());
        assertThat(conversation.getAwaiting()).isNull();
    }

    @Test
    void confirm_whenServiceRejectsRole_sendsFinFailed_withoutCrashing() {
        FinancialEntryDraft draft = new FinancialEntryDraft(FinancialEntryDraft.Stage.CONFIRM, ORG,
                FinancialEntryType.EXPENSE, FinancialEntryCategory.CONTA_CONSUMO, 20000, "conta de luz", TODAY);
        when(financialEntryService.create(eq(ORG), any()))
                .thenThrow(new ForbiddenException("Apenas ADMIN ou SYNDIC podem lançar ou cancelar movimentações financeiras."));

        StepOutcome outcome = service.continuePending(turn("confirmar"), conversation, draft);

        assertThat(outcome.stop()).isTrue();
        verify(reply).sendText("5531", String.format(AssistantMessages.FIN_FAILED,
                "Apenas ADMIN ou SYNDIC podem lançar ou cancelar movimentações financeiras."));
    }

    @Test
    void cancelWord_discardsWithoutCalling_theService() {
        FinancialEntryDraft draft = new FinancialEntryDraft(FinancialEntryDraft.Stage.CONFIRM, ORG,
                FinancialEntryType.EXPENSE, FinancialEntryCategory.CONTA_CONSUMO, 20000, "conta de luz", TODAY);

        service.continuePending(turn("cancelar"), conversation, draft);

        verifyNoInteractions(financialEntryService);
        assertThat(conversation.getAwaiting()).isNull();
        verify(reply).sendText("5531", AssistantMessages.FIN_CANCELLED);
    }

    @Test
    void type_isFinancialEntryConstant() {
        assertThat(service.type()).isEqualTo(AssistantConversation.AWAITING_FINANCIAL_ENTRY);
    }

    @Test
    void pendingOrgCode_returnsTheDraftsOrg() {
        FinancialEntryDraft draft = new FinancialEntryDraft(FinancialEntryDraft.Stage.CONFIRM, ORG,
                FinancialEntryType.EXPENSE, FinancialEntryCategory.CONTA_CONSUMO, 20000, "x", TODAY);
        conversation.setAwaiting(AssistantConversation.AWAITING_FINANCIAL_ENTRY);
        try {
            conversation.setPendingActionJson(new ObjectMapper().findAndRegisterModules().writeValueAsString(draft));
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        assertThat(service.pendingOrgCode(conversation)).contains(ORG);
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd easy-maintenance-api && mvn -q -Dtest=AssistantFinancialEntryServiceTest test`
Expected: FAIL to compile — `FinancialEntryDraft` and `AssistantFinancialEntryService` do not exist yet.

- [ ] **Step 3: Implement `FinancialEntryDraft`**

```java
package com.brainbyte.easy_maintenance.assistant.application.finance;

import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryCategory;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;

import java.time.LocalDate;

/**
 * EPIC-031 Onda 2 (TASK-330): lançamento financeiro aguardando confirmação. Vive em
 * assistant_conversations.pending_action_json com validade de 30 minutos — mesmo contrato de
 * RegistrationDraft. Nada é gravado no domínio antes do "Confirmar".
 */
public record FinancialEntryDraft(
        Stage stage,
        String orgCode,
        FinancialEntryType type,
        FinancialEntryCategory category,
        Integer amountCents,
        String description,
        LocalDate entryDate
) {
    public enum Stage { CHOOSE_TYPE, CHOOSE_CATEGORY, CONFIRM }

    public FinancialEntryDraft withType(FinancialEntryType newType) {
        return new FinancialEntryDraft(Stage.CHOOSE_CATEGORY, orgCode, newType, null, amountCents, description, entryDate);
    }

    public FinancialEntryDraft withCategory(FinancialEntryCategory newCategory) {
        return new FinancialEntryDraft(Stage.CONFIRM, orgCode, type, newCategory, amountCents, description, entryDate);
    }
}
```

- [ ] **Step 4: Add `AssistantLinks.finance(...)`**

In `AssistantLinks.java`, add next to `reports(...)`:

```java
    public static String finance(String base, String org) {
        return url(base, "/financeiro", org);
    }
```

- [ ] **Step 5: Implement `AssistantFinancialEntryService`**

```java
package com.brainbyte.easy_maintenance.assistant.application.finance;

import com.brainbyte.easy_maintenance.assistant.application.access.AssistantAccessGuard;
import com.brainbyte.easy_maintenance.assistant.application.access.AssistantUserContext;
import com.brainbyte.easy_maintenance.assistant.application.conversation.AssistantConversationService;
import com.brainbyte.easy_maintenance.assistant.application.identity.AssistantIdentity;
import com.brainbyte.easy_maintenance.assistant.application.pipeline.AssistantTurn;
import com.brainbyte.easy_maintenance.assistant.application.pipeline.PendingActionHandler;
import com.brainbyte.easy_maintenance.assistant.application.pipeline.StepOutcome;
import com.brainbyte.easy_maintenance.assistant.application.query.ItemMatcher;
import com.brainbyte.easy_maintenance.assistant.application.registration.RegistrationParser;
import com.brainbyte.easy_maintenance.assistant.application.reply.AssistantLinks;
import com.brainbyte.easy_maintenance.assistant.application.reply.AssistantMessages;
import com.brainbyte.easy_maintenance.assistant.application.reply.AssistantOption;
import com.brainbyte.easy_maintenance.assistant.application.reply.AssistantReplyPort;
import com.brainbyte.easy_maintenance.assistant.config.AssistantProperties;
import com.brainbyte.easy_maintenance.assistant.domain.AssistantConversation;
import com.brainbyte.easy_maintenance.commons.exceptions.ConflictException;
import com.brainbyte.easy_maintenance.commons.exceptions.ForbiddenException;
import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.commons.exceptions.RuleException;
import com.brainbyte.easy_maintenance.commons.exceptions.TenantException;
import com.brainbyte.easy_maintenance.finance.application.dto.CreateFinancialEntryRequest;
import com.brainbyte.easy_maintenance.finance.application.dto.FinancialEntryResponse;
import com.brainbyte.easy_maintenance.finance.application.service.FinancialEntryService;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryCategory;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;
import com.brainbyte.easy_maintenance.infrastructure.audit.AuditAction;
import com.brainbyte.easy_maintenance.infrastructure.audit.AuditService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * EPIC-031 Onda 2 (TASK-330): lançamento financeiro (receita/despesa) pelo WhatsApp. Mesmo
 * desenho de AssistantRegistrationService: {@link #start} monta um rascunho e mostra
 * Confirmar/Corrigir/Cancelar — nada é gravado antes do "Confirmar". Só chama
 * {@link FinancialEntryService#create}, nunca reimplementa suas regras.
 */
@Slf4j
@Service
public class AssistantFinancialEntryService implements PendingActionHandler {

    public static final String BTN_CONFIRM = "fin:confirm";
    public static final String BTN_FIX = "fin:fix";
    public static final String BTN_CANCEL = "fin:cancel";
    public static final String BTN_TYPE_REVENUE = "fin:type:revenue";
    public static final String BTN_TYPE_EXPENSE = "fin:type:expense";
    public static final String CATEGORY_PREFIX = "fin-cat:";

    private static final Duration PENDING_TTL = Duration.ofMinutes(30);
    private static final int DESCRIPTION_MAX = 500;
    private static final ZoneId SAO_PAULO = ZoneId.of("America/Sao_Paulo");
    private static final Locale PT_BR = Locale.of("pt", "BR");
    private static final DateTimeFormatter FULL_DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final Set<String> CONFIRM_WORDS = Set.of("sim", "s", "confirmar", "confirmo", "confirma", "ok",
            "pode", "pode lancar", "isso", "certo", "pode salvar", "salvar");
    private static final Set<String> CANCEL_WORDS = Set.of("cancelar", "cancela", "cancelado", "nao", "n", "desistir",
            "deixa", "deixa pra la");
    private static final Set<String> FIX_WORDS = Set.of("corrigir", "corrige", "errado", "esta errado", "alterar", "mudar");
    private static final Map<FinancialEntryCategory, String> CATEGORY_LABEL = Map.of(
            FinancialEntryCategory.TAXA_CONDOMINIAL, "Taxa condominial",
            FinancialEntryCategory.MULTA, "Multa",
            FinancialEntryCategory.ALUGUEL_ESPACO, "Aluguel de espaço",
            FinancialEntryCategory.OUTRAS_RECEITAS, "Outras receitas",
            FinancialEntryCategory.FOLHA_PAGAMENTO, "Folha de pagamento",
            FinancialEntryCategory.CONTA_CONSUMO, "Conta de consumo",
            FinancialEntryCategory.SERVICO_TERCEIRO, "Serviço de terceiro",
            FinancialEntryCategory.OUTRAS_DESPESAS, "Outras despesas");

    private final AssistantConversationService conversations;
    private final AssistantAccessGuard guard;
    private final AssistantUserContext userContext;
    private final FinancialEntryService financialEntryService;
    private final AssistantReplyPort reply;
    private final AuditService auditService;
    private final AssistantProperties properties;
    private final ObjectMapper objectMapper;
    private final TransactionTemplate transaction;
    private final Clock clock;

    @Autowired
    public AssistantFinancialEntryService(AssistantConversationService conversations, AssistantAccessGuard guard,
                                          AssistantUserContext userContext, FinancialEntryService financialEntryService,
                                          AssistantReplyPort reply, AuditService auditService, AssistantProperties properties,
                                          ObjectMapper objectMapper, PlatformTransactionManager transactionManager) {
        this(conversations, guard, userContext, financialEntryService, reply, auditService, properties, objectMapper,
                transactionManager, Clock.system(SAO_PAULO));
    }

    AssistantFinancialEntryService(AssistantConversationService conversations, AssistantAccessGuard guard,
                                   AssistantUserContext userContext, FinancialEntryService financialEntryService,
                                   AssistantReplyPort reply, AuditService auditService, AssistantProperties properties,
                                   ObjectMapper objectMapper, PlatformTransactionManager transactionManager, Clock clock) {
        this.conversations = conversations;
        this.guard = guard;
        this.userContext = userContext;
        this.financialEntryService = financialEntryService;
        this.reply = reply;
        this.auditService = auditService;
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.transaction = new TransactionTemplate(transactionManager);
        this.clock = clock;
    }

    // ===================================================================== início

    public StepOutcome start(AssistantTurn turn, Map<String, String> fields) {
        AssistantIdentity identity = turn.identity();
        String waId = turn.inbound().waId();
        String orgCode = turn.orgCode();

        if (denied(identity, orgCode, waId)) {
            return StepOutcome.done();
        }

        String text = turn.text() == null ? "" : turn.text().trim();
        Integer amountCents = firstNonNull(RegistrationParser.parseCostCents(fields.get("custo")), RegistrationParser.parseCostCents(text));
        if (amountCents == null) {
            reply.sendText(waId, AssistantMessages.FIN_HOW);
            return StepOutcome.done();
        }
        LocalDate today = LocalDate.now(clock);
        LocalDate date = firstNonNull(RegistrationParser.parseDate(fields.get("data"), today), RegistrationParser.parseDate(text, today), today);
        FinancialEntryType type = firstNonNull(parseFieldType(fields.get("tipo")), AssistantFinancialEntryParser.parseType(text));
        String description = text.length() > DESCRIPTION_MAX ? text.substring(0, DESCRIPTION_MAX) : text;

        AssistantConversation conversation = conversations.getOrCreate(identity.userId());
        FinancialEntryDraft draft = new FinancialEntryDraft(FinancialEntryDraft.Stage.CHOOSE_TYPE, orgCode, null, null,
                amountCents, description, date);
        if (type == null) {
            return askType(waId, conversation, draft);
        }
        return askCategory(waId, conversation, draft.withType(type));
    }

    private static FinancialEntryType parseFieldType(String raw) {
        return AssistantFinancialEntryParser.parseType(raw);
    }

    // ===================================================================== pendência

    public Optional<FinancialEntryDraft> pending(AssistantConversation conversation) {
        if (!type().equals(conversation.getAwaiting()) || conversation.getPendingActionJson() == null || isExpired(conversation)) {
            return Optional.empty();
        }
        try {
            return Optional.of(objectMapper.readValue(conversation.getPendingActionJson(), FinancialEntryDraft.class));
        } catch (Exception e) {
            log.warn("[Assistant] Rascunho de lançamento financeiro ilegível — descartado: {}", e.getMessage());
            clearPending(conversation);
            return Optional.empty();
        }
    }

    @Override
    public String type() {
        return AssistantConversation.AWAITING_FINANCIAL_ENTRY;
    }

    @Override
    public boolean isExpired(AssistantConversation conversation) {
        return type().equals(conversation.getAwaiting()) && conversation.getPendingExpiresAt() != null
                && conversation.getPendingExpiresAt().isBefore(Instant.now(clock));
    }

    @Override
    public void discard(AssistantConversation conversation) {
        clearPending(conversation);
    }

    @Override
    public Optional<String> pendingOrgCode(AssistantConversation conversation) {
        return pending(conversation).map(FinancialEntryDraft::orgCode);
    }

    @Override
    public String expiredMessage() {
        return AssistantMessages.FIN_EXPIRED;
    }

    @Override
    public StepOutcome continuePending(AssistantTurn turn, AssistantConversation conversation) {
        Optional<FinancialEntryDraft> draft = pending(conversation);
        if (draft.isEmpty()) {
            return StepOutcome.next();
        }
        return continuePending(turn, conversation, draft.get());
    }

    public StepOutcome continuePending(AssistantTurn turn, AssistantConversation conversation, FinancialEntryDraft draft) {
        String waId = turn.inbound().waId();
        String interactiveId = turn.inbound().interactiveId();
        String text = turn.text() == null ? "" : turn.text().trim();
        String command = ItemMatcher.normalize(text);

        if (BTN_CANCEL.equals(interactiveId) || CANCEL_WORDS.contains(command)) {
            clearPending(conversation);
            reply.sendText(waId, AssistantMessages.FIN_CANCELLED);
            return StepOutcome.done();
        }

        if (draft.stage() == FinancialEntryDraft.Stage.CHOOSE_TYPE) {
            return continueChoosingType(waId, conversation, draft, interactiveId, command);
        }
        if (draft.stage() == FinancialEntryDraft.Stage.CHOOSE_CATEGORY) {
            return continueChoosingCategory(waId, conversation, draft, interactiveId);
        }

        if (BTN_CONFIRM.equals(interactiveId) || CONFIRM_WORDS.contains(command)) {
            return commit(turn, conversation, draft);
        }
        if (BTN_FIX.equals(interactiveId) || FIX_WORDS.contains(command)) {
            reply.sendText(waId, AssistantMessages.FIN_FIX_PROMPT);
            return StepOutcome.done();
        }
        reply.sendOptions(waId, AssistantMessages.FIN_CONFIRM_FIRST, confirmButtons());
        return StepOutcome.done();
    }

    private StepOutcome continueChoosingType(String waId, AssistantConversation conversation, FinancialEntryDraft draft,
                                              String interactiveId, String command) {
        FinancialEntryType chosen = BTN_TYPE_REVENUE.equals(interactiveId) ? FinancialEntryType.REVENUE
                : BTN_TYPE_EXPENSE.equals(interactiveId) ? FinancialEntryType.EXPENSE
                : AssistantFinancialEntryParser.parseType(command);
        if (chosen == null) {
            return askType(waId, conversation, draft);
        }
        return askCategory(waId, conversation, draft.withType(chosen));
    }

    private StepOutcome continueChoosingCategory(String waId, AssistantConversation conversation, FinancialEntryDraft draft,
                                                  String interactiveId) {
        if (interactiveId == null || !interactiveId.startsWith(CATEGORY_PREFIX)) {
            return askCategory(waId, conversation, draft);
        }
        FinancialEntryCategory chosen;
        try {
            chosen = FinancialEntryCategory.valueOf(interactiveId.substring(CATEGORY_PREFIX.length()));
        } catch (IllegalArgumentException e) {
            return askCategory(waId, conversation, draft);
        }
        if (chosen.getType() != draft.type()) {
            return askCategory(waId, conversation, draft);
        }
        return savePendingAndShowSummary(waId, conversation, draft.withCategory(chosen));
    }

    // ===================================================================== gravação

    private StepOutcome commit(AssistantTurn turn, AssistantConversation conversation, FinancialEntryDraft draft) {
        AssistantIdentity identity = turn.identity();
        String waId = turn.inbound().waId();
        String orgCode = draft.orgCode();

        if (denied(identity, orgCode, waId)) {
            clearPending(conversation);
            return StepOutcome.done();
        }

        String wamid = turn.inbound().lastWamid();
        FinancialEntryResponse created;
        MDC.put("requestId", wamid);
        try {
            created = transaction.execute(status -> userContext.runAs(identity.user(), orgCode, () ->
                    financialEntryService.create(orgCode, new CreateFinancialEntryRequest(
                            draft.type(), draft.category(), draft.amountCents(), draft.description(), draft.entryDate()))));
            auditService.log("FINANCIAL_ENTRY", String.valueOf(created.id()), AuditAction.CREATE,
                    Map.of("source", "WHATSAPP", "wamid", String.valueOf(wamid), "type", draft.type().name()));
        } catch (RuleException | ConflictException | NotFoundException | ForbiddenException | TenantException e) {
            reply.sendText(waId, String.format(AssistantMessages.FIN_FAILED, e.getMessage()));
            return StepOutcome.done();
        } finally {
            MDC.remove("requestId");
        }

        clearPending(conversation);
        reply.sendText(waId, String.format(AssistantMessages.FIN_DONE, typeLabel(draft.type()),
                money(draft.amountCents()), draft.entryDate().format(FULL_DATE))
                + "\n" + String.format(AssistantMessages.FIN_SEE, AssistantLinks.finance(properties.webBaseUrl(), orgCode)));
        return StepOutcome.done();
    }

    // ===================================================================== apoio

    private boolean denied(AssistantIdentity identity, String orgCode, String waId) {
        Optional<AssistantAccessGuard.Denial> denial = guard.checkWrite(identity.user(), orgCode);
        if (denial.isEmpty()) {
            return false;
        }
        reply.sendText(waId, denial.get() == AssistantAccessGuard.Denial.READER_ROLE
                ? AssistantMessages.WRITE_DENIED_READER
                : AssistantMessages.WRITE_DENIED_READ_ONLY);
        return true;
    }

    private StepOutcome askType(String waId, AssistantConversation conversation, FinancialEntryDraft draft) {
        savePending(conversation, draft);
        reply.sendOptions(waId, AssistantMessages.FIN_CHOOSE_TYPE, List.of(
                AssistantOption.of(BTN_TYPE_REVENUE, "Receita"), AssistantOption.of(BTN_TYPE_EXPENSE, "Despesa"),
                AssistantOption.of(BTN_CANCEL, "Cancelar")));
        return StepOutcome.done();
    }

    private StepOutcome askCategory(String waId, AssistantConversation conversation, FinancialEntryDraft draft) {
        savePending(conversation, draft);
        List<AssistantOption> options = new ArrayList<>(Arrays.stream(FinancialEntryCategory.values())
                .filter(c -> c.getType() == draft.type())
                .map(c -> AssistantOption.of(CATEGORY_PREFIX + c.name(), CATEGORY_LABEL.get(c)))
                .toList());
        options.add(AssistantOption.of(BTN_CANCEL, "Cancelar"));
        reply.sendOptions(waId, AssistantMessages.FIN_CHOOSE_CATEGORY, options);
        return StepOutcome.done();
    }

    private StepOutcome savePendingAndShowSummary(String waId, AssistantConversation conversation, FinancialEntryDraft draft) {
        savePending(conversation, draft);
        reply.sendOptions(waId, summary(draft), confirmButtons());
        return StepOutcome.done();
    }

    private String summary(FinancialEntryDraft d) {
        StringBuilder s = new StringBuilder(AssistantMessages.FIN_SUMMARY_TITLE);
        s.append("\n").append(d.type() == FinancialEntryType.REVENUE ? "📈 Receita" : "📉 Despesa");
        s.append("\n🏷 ").append(CATEGORY_LABEL.get(d.category()));
        s.append("\n💰 ").append(money(d.amountCents()));
        s.append("\n📅 ").append(d.entryDate().format(FULL_DATE));
        if (d.description() != null && !d.description().isBlank()) {
            String desc = d.description().length() > 120 ? d.description().substring(0, 120) + "…" : d.description();
            s.append("\n📝 ").append(desc);
        }
        return s.toString();
    }

    private static List<AssistantOption> confirmButtons() {
        return List.of(AssistantOption.of(BTN_CONFIRM, "Confirmar"), AssistantOption.of(BTN_FIX, "Corrigir"),
                AssistantOption.of(BTN_CANCEL, "Cancelar"));
    }

    private void savePending(AssistantConversation conversation, FinancialEntryDraft draft) {
        try {
            conversation.setPendingActionJson(objectMapper.writeValueAsString(draft));
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao serializar o rascunho do lançamento financeiro", e);
        }
        conversation.setAwaiting(type());
        conversation.setPendingExpiresAt(Instant.now(clock).plus(PENDING_TTL));
        conversations.save(conversation);
    }

    private void clearPending(AssistantConversation conversation) {
        conversation.setAwaiting(null);
        conversation.setPendingActionJson(null);
        conversation.setPendingExpiresAt(null);
        conversations.save(conversation);
    }

    private static String typeLabel(FinancialEntryType type) {
        return type == FinancialEntryType.REVENUE ? "Receita" : "Despesa";
    }

    private static String money(int cents) {
        return "R$ " + String.format(PT_BR, "%,.2f", cents / 100.0);
    }

    @SafeVarargs
    private static <T> T firstNonNull(T... values) {
        for (T v : values) {
            if (v != null) {
                return v;
            }
        }
        return null;
    }
}
```

Add `AWAITING_FINANCIAL_ENTRY` to `AssistantConversation.java`, next to `AWAITING_REGISTRATION` added in Task 1:

```java
    /** EPIC-031 Onda 2 (TASK-330): lançamento financeiro aguardando confirmação. */
    public static final String AWAITING_FINANCIAL_ENTRY = "FINANCIAL_ENTRY";
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd easy-maintenance-api && mvn -q -Dtest=AssistantFinancialEntryServiceTest test`
Expected: all tests PASS. If `start_withAmountButNoType_asksTypeViaButtons_andSavesDraft`'s assertion on the exact `sendOptions` text looks awkward (it was written defensively to avoid a second near-duplicate constant name) — simplify it in this step to a direct `verify(reply).sendOptions(eq("5531"), eq(AssistantMessages.FIN_CHOOSE_TYPE), any());` once the test compiles, since by then `FIN_CHOOSE_TYPE` unambiguously exists; keep the test's INTENT (type is asked via buttons) rather than its literal text above.

- [ ] **Step 7: Commit**

```bash
cd easy-maintenance-api
git add src/main/java/com/brainbyte/easy_maintenance/assistant/application/finance/ src/main/java/com/brainbyte/easy_maintenance/assistant/application/reply/AssistantLinks.java src/main/java/com/brainbyte/easy_maintenance/assistant/domain/AssistantConversation.java src/test/java/com/brainbyte/easy_maintenance/assistant/application/finance/
git commit -m "feat(assistant): registra receita/despesa pelo WhatsApp - AssistantFinancialEntryService (EPIC-031 TASK-330)"
```

---

### Task 7: Wire into `IntentStep`

**Files:**
- Modify: `src/main/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/IntentStep.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/IntentStepTest.java`

**Interfaces:**
- Consumes: `AssistantFinancialEntryService.start(AssistantTurn, Map<String, String>)` (Task 6), `AssistantIntent.REGISTRAR_LANCAMENTO_FINANCEIRO` (Task 4).

- [ ] **Step 1: Write the failing test**

Add to `IntentStepTest.java`, mirroring the existing `REGISTRAR_MANUTENCAO` test in the same file (same constructor call site must gain one more mocked argument — see Step 3):

```java
@Test
void registrarLancamentoFinanceiro_delegatesToTheFinancialEntryService() {
    Map<String, String> fields = Map.of("tipo", "despesa", "custo", "200");
    when(classifier.classify("gastei 200 com a conta de luz", 24L))
            .thenReturn(new ClassifiedIntent(AssistantIntent.REGISTRAR_LANCAMENTO_FINANCEIRO, fields));
    when(financialEntry.start(any(), eq(fields))).thenReturn(StepOutcome.done());

    AssistantTurn turn = turnWithText("gastei 200 com a conta de luz");
    assertThat(step.apply(turn).stop()).isTrue();

    verify(financialEntry).start(any(), eq(fields));
}
```

(Use whichever helper the file already has for building a turn with free text and an identified org — the existing `REGISTRAR_MANUTENCAO` test right above it builds one; call it the same way rather than inventing a new helper name.)

- [ ] **Step 2: Run test to verify it fails**

Run: `cd easy-maintenance-api && mvn -q -Dtest=IntentStepTest test`
Expected: FAIL to compile — the test file's `IntentStep` constructor call does not yet accept a `financialEntry` argument, and `financialEntry` field/mock does not exist yet.

- [ ] **Step 3: Wire the dependency and the case**

In `IntentStep.java`:
1. Add the import and field:

```java
import com.brainbyte.easy_maintenance.assistant.application.finance.AssistantFinancialEntryService;
```
```java
    private final AssistantFinancialEntryService financialEntry;
```
2. Add it as the last constructor parameter (Lombok `@RequiredArgsConstructor` generates the constructor from field order, so this becomes the last positional argument — every call site, including the test, passes it last).
3. Add the case, right after `REGISTRAR_MANUTENCAO`'s case block:

```java
            case REGISTRAR_LANCAMENTO_FINANCEIRO -> {
                if (fromShortcut || text == null || text.isBlank()) {
                    reply.sendText(waId, AssistantMessages.FIN_HOW);
                } else {
                    return financialEntry.start(turn, fields);
                }
            }
```

In `IntentStepTest.java`:
1. Add `private final AssistantFinancialEntryService financialEntry = mock(AssistantFinancialEntryService.class);` next to the existing `newOrganization` mock field.
2. Add `financialEntry` as the last argument to the existing `new IntentStep(...)` call.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd easy-maintenance-api && mvn -q -Dtest=IntentStepTest test`
Expected: all tests in the file PASS, including the new one and every pre-existing one (the constructor signature change is mechanical — every other test in the file keeps using the same `step` field, unaffected by the new case).

- [ ] **Step 5: Run the full assistant test package and the full suite**

Run: `cd easy-maintenance-api && mvn -q -Dtest=com.brainbyte.easy_maintenance.assistant.** test`
Expected: all PASS — this is the point where Task 1-7's combined effect on the whole `assistant` package is verified together for the first time.

Run: `cd easy-maintenance-api && mvn -q test`
Expected: full suite PASS (no regression outside the `assistant` package — nothing outside it was touched, so this is a sanity check, not expected to surface anything new).

- [ ] **Step 6: Commit**

```bash
cd easy-maintenance-api
git add src/main/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/IntentStep.java src/test/java/com/brainbyte/easy_maintenance/assistant/application/pipeline/IntentStepTest.java
git commit -m "feat(assistant): liga REGISTRAR_LANCAMENTO_FINANCEIRO ao IntentStep (EPIC-031 TASK-330)"
```

---

## Self-Review

**Spec coverage:** every element of the in-chat design the user approved is covered — the `PendingActionHandler` refactor (Tasks 1-3), the new intent + prompt + messages (Task 4), the type parser (Task 5), the draft + service (Task 6), and the `IntentStep` wiring (Task 7). No backend change to the finance module itself, as agreed (`FinancialEntryService` is only called, never modified).

**Placeholder scan:** no task contains "TBD"/"add error handling"/"similar to Task N" — every step has the literal code or the literal file edit. Where a step tells the implementer to follow a neighboring test's exact field/helper name (Tasks 4, 6, 7) instead of inlining it, that is because the neighboring file was read during planning and its exact style could not be fully captured without quoting the whole file — the instruction names exactly which existing test and which existing pattern to copy, not a vague "write tests for this."

**Type consistency:** `FinancialEntryDraft`'s field names (`type`, `category`, `amountCents`, `description`, `entryDate`, `orgCode`) match `CreateFinancialEntryRequest`'s exactly, so Task 6's `commit()` constructs it positionally without renaming anything. `PendingActionHandler`'s five methods (Task 1) are implemented identically by `AssistantRegistrationService` (Task 1), `AssistantNewOrganizationService` (Task 2), and `AssistantFinancialEntryService` (Task 6) — same method names, same `Optional<String> pendingOrgCode(...)` contract used identically by `PendingActionStep` (Task 3).

**Review Focus coverage:** all five lines have an owning task and test, as cross-referenced above (org switch → Task 3/6; role downgrade → Task 6; missing amount → Task 6; keyword ambiguity → Task 5; correct per-capability expiry text → Task 3).
