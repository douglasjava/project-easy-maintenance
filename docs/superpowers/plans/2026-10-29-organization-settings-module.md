# Módulo de Configurações da Organização — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a settings module where ADMIN/SYNDIC users configure SLA parameters for resident
tickets and register common areas with reservation rules — storage + API + UI only, no consumer
wired up yet.

**Architecture:** Two new backend entities under a new `settings` bounded context (same
layering as `resident_tickets`): `OrganizationSetting` (generic category→JSON parameter store,
starts with `TICKETS_SLA`) and `CommonArea` (CRUD list entity with a `rules` JSON column and a
first-class `fee_cents` column). One new frontend route `/configuracoes` with two tabs driven by
local state, plus a new entry in the user menu.

**Tech Stack:** Spring Boot 3.5 / Java 22 / MySQL (Flyway) / JUnit 5 + Mockito + AssertJ on the
backend; Next.js (App Router) / TypeScript / axios (`@/lib/apiClient`) / `react-hot-toast` on the
frontend.

**Spec:** `docs/superpowers/specs/2026-10-29-organization-settings-module-design.md`

## Global Constraints

- Multi-tenant: every query scoped by `organization_id` (Long), resolved from `TenantContext` →
  `OrganizationRepository.findByCode(...)` → `Organization.getId()` — the same resolution pattern
  as `ResidentTicketAdminService.resolveCurrentOrganization()`. Never the `@Filter`/`@FilterDef`
  pattern (`MaintenanceItem`) nor the `organizationCode` String-filter pattern (`FinancialEntry`).
- Permission: `ADMIN` or `SYNDIC` only, on every settings/common-area endpoint. `403` via
  `ForbiddenException` for anyone else (`TECH`, `READER`).
- Payload validation errors on `PUT`/`POST` throw `RuleException` (maps to `400` `ProblemDetail`
  via `GlobalExceptionHandler`) — never `@Valid`/Bean Validation, which this codebase maps to `422`.
- Money stored as integer cents (`fee_cents`), never decimal — matches `amount_cents`/`value_cents`
  convention used everywhere else in the schema.
- JSON columns: `columnDefinition = "json"` on a plain `String` field, serialized/deserialized with
  Jackson in the service layer — same pattern as `LandingLead.utmJson`, not the
  `@JdbcTypeCode(SqlTypes.JSON)` + `Object` pattern (`AuditLog`) which needs no manual
  (de)serialization but gives up compile-time shape checking we want here.
- Flyway migrations start at `V128__...` (confirm the actual highest existing version again at
  implementation time — `V127` is the highest as of this plan).
- No `version`/optimistic-lock column on either table (explicitly descoped).
- No consumer wiring in this plan: `ResidentTicket` gets no new field, no reservation/booking
  entity is created, no financial entry or Asaas charge is triggered by `fee_cents`.

## Review Focus

- **Unknown `category` path value** (e.g. `GET /organizations/settings/NOTIFICATIONS` before that
  category exists): must return a clean `400 RuleException` ("categoria desconhecida"), not a 500
  from a failed `Enum.valueOf`.
- **Malformed `prioritySla` map** (missing a key, extra key, non-integer value, negative value) on
  `PUT /organizations/settings/TICKETS_SLA`: must be rejected with `400`, not silently accepted or
  stored partially.
- **Cross-tenant access**: requesting/updating a `common_area` `id` that exists but belongs to a
  different organization must behave like "not found" (`404`), never leak another org's area or
  update it.
- **Deactivated common area still returned by `GET` list**: `active=false` must still appear in
  `GET /organizations/common-areas` (frontend decides display) — a filter that silently drops
  inactive areas from the API would make them look deleted.
- **First-time `GET` of settings for an org with no saved row**: must return the hardcoded defaults
  with HTTP 200, not 404 — the frontend form has nothing to render on a 404.

---

## Task 1: `OrganizationSetting` entity, migration, repository

**Files:**
- Create: `easy-maintenance-api/src/main/resources/db/migration/V128__create_organization_settings.sql`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/domain/OrganizationSetting.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/infrastructure/persistence/OrganizationSettingRepository.java`
- Test: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/settings/infrastructure/persistence/OrganizationSettingPersistenceTest.java`

**Interfaces:**
- Produces: entity `OrganizationSetting` — fields `Long id`, `Long organizationId`, `String
  category`, `String config` (JSON string), `Instant createdAt`, `Instant updatedAt`. Repository
  `OrganizationSettingRepository extends JpaRepository<OrganizationSetting, Long>` with
  `Optional<OrganizationSetting> findByOrganizationIdAndCategory(Long organizationId, String
  category)`.

- [ ] **Step 1: Write migration `V128__create_organization_settings.sql`**

```sql
CREATE TABLE organization_settings (
    id BIGINT NOT NULL AUTO_INCREMENT,
    organization_id BIGINT NOT NULL,
    category VARCHAR(50) NOT NULL,
    config JSON NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT uk_organization_settings_org_category UNIQUE (organization_id, category)
);
```

- [ ] **Step 2: Write `OrganizationSetting.java`**

Entity mapped to table `organization_settings`, `@Table(name = "organization_settings",
uniqueConstraints = @UniqueConstraint(name = "uk_organization_settings_org_category", columnNames =
{"organization_id", "category"}))`, `@Id`/`IDENTITY` on `id`, `config` column with
`@Column(columnDefinition = "json")`, `@CreationTimestamp`/`@UpdateTimestamp` on
`createdAt`/`updatedAt` — same Lombok annotations (`@Data`/`@Builder`/`@NoArgsConstructor`/
`@AllArgsConstructor`/`@Entity`) as `ResidentTicket`.

- [ ] **Step 3: Write `OrganizationSettingRepository.java`**

`@Repository interface OrganizationSettingRepository extends JpaRepository<OrganizationSetting,
Long>` with the one derived-query method from the Interfaces block above.

- [ ] **Step 4: Write the failing persistence test**

```java
@DataJpaTest
@EntityScan(basePackageClasses = OrganizationSetting.class)
@EnableJpaRepositories(basePackageClasses = OrganizationSettingRepository.class)
@TestPropertySource(properties = {
        "spring.flyway.enabled=false",
        "spring.jpa.hibernate.ddl-auto=create-drop"
})
class OrganizationSettingPersistenceTest {

    @Autowired TestEntityManager entityManager;
    @Autowired OrganizationSettingRepository repository;

    @Test
    void organizationIdAndCategory_isUnique_secondRowWithSamePairFailsToPersist() {
        repository.saveAndFlush(setting(1L, "TICKETS_SLA"));
        entityManager.clear();

        assertThrows(DataIntegrityViolationException.class,
                () -> repository.saveAndFlush(setting(1L, "TICKETS_SLA")));
    }

    @Test
    void findByOrganizationIdAndCategory_returnsEmpty_whenNoRowForThatOrg() {
        repository.saveAndFlush(setting(1L, "TICKETS_SLA"));

        assertThat(repository.findByOrganizationIdAndCategory(2L, "TICKETS_SLA")).isEmpty();
    }

    private OrganizationSetting setting(Long organizationId, String category) {
        return OrganizationSetting.builder()
                .organizationId(organizationId)
                .category(category)
                .config("{\"defaultSlaHours\":24}")
                .build();
    }
}
```

- [ ] **Step 5: Run `./mvnw test -Dtest=OrganizationSettingPersistenceTest`**

Expected: FAIL (class `OrganizationSetting`/repository not compiled yet, or table missing) — if it
somehow compiles and only the unique-constraint assertion fails, that also counts as the expected
failure for this step.

- [ ] **Step 6: Make the test pass** (it should already pass once Steps 1–3 are done correctly; this
step is the checkpoint, not new code)

Run: `./mvnw test -Dtest=OrganizationSettingPersistenceTest`
Expected: PASS (2/2)

- [ ] **Step 7: Commit**

```bash
git add easy-maintenance-api/src/main/resources/db/migration/V128__create_organization_settings.sql \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/domain/OrganizationSetting.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/infrastructure/persistence/OrganizationSettingRepository.java \
        easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/settings/infrastructure/persistence/OrganizationSettingPersistenceTest.java
git commit -m "feat(settings): add organization_settings entity, migration and repository"
```

---

## Task 2: `CommonArea` entity, migration, repository

**Files:**
- Create: `easy-maintenance-api/src/main/resources/db/migration/V129__create_common_area.sql`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/domain/CommonArea.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/infrastructure/persistence/CommonAreaRepository.java`
- Test: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/settings/infrastructure/persistence/CommonAreaPersistenceTest.java`

**Interfaces:**
- Produces: entity `CommonArea` — fields `Long id`, `Long organizationId`, `String name`, `Integer
  capacity`, `Boolean active` (default `true`), `Integer feeCents` (nullable), `String rules` (JSON
  string), `Instant createdAt`, `Instant updatedAt`. Repository `CommonAreaRepository extends
  JpaRepository<CommonArea, Long>` with `List<CommonArea> findAllByOrganizationIdOrderByNameAsc(Long
  organizationId)` and `Optional<CommonArea> findByIdAndOrganizationId(Long id, Long
  organizationId)`.

- [ ] **Step 1: Write migration `V129__create_common_area.sql`**

```sql
CREATE TABLE common_area (
    id BIGINT NOT NULL AUTO_INCREMENT,
    organization_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    capacity INT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    fee_cents INT NULL,
    rules JSON NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);
```

- [ ] **Step 2: Write `CommonArea.java`**

Same entity shape/annotations as `OrganizationSetting` (Step 2 of Task 1), with the fields listed
in Interfaces above. `rules` column: `@Column(columnDefinition = "json")`.

- [ ] **Step 3: Write `CommonAreaRepository.java`**

`@Repository interface CommonAreaRepository extends JpaRepository<CommonArea, Long>` with the two
derived-query methods from the Interfaces block above.

- [ ] **Step 4: Write the failing persistence test**

```java
@DataJpaTest
@EntityScan(basePackageClasses = CommonArea.class)
@EnableJpaRepositories(basePackageClasses = CommonAreaRepository.class)
@TestPropertySource(properties = {
        "spring.flyway.enabled=false",
        "spring.jpa.hibernate.ddl-auto=create-drop"
})
class CommonAreaPersistenceTest {

    @Autowired TestEntityManager entityManager;
    @Autowired CommonAreaRepository repository;

    @Test
    void findAllByOrganizationId_doesNotReturnOtherOrganizationAreas() {
        repository.saveAndFlush(area(1L, "Salão de festas"));
        repository.saveAndFlush(area(2L, "Churrasqueira"));

        List<CommonArea> result = repository.findAllByOrganizationIdOrderByNameAsc(1L);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Salão de festas");
    }

    @Test
    void findByIdAndOrganizationId_returnsEmpty_whenAreaBelongsToAnotherOrg() {
        CommonArea saved = repository.saveAndFlush(area(1L, "Salão de festas"));
        entityManager.clear();

        assertThat(repository.findByIdAndOrganizationId(saved.getId(), 2L)).isEmpty();
    }

    private CommonArea area(Long organizationId, String name) {
        return CommonArea.builder()
                .organizationId(organizationId)
                .name(name)
                .capacity(50)
                .rules("{\"requiresApproval\":true}")
                .build();
    }
}
```

- [ ] **Step 5: Run `./mvnw test -Dtest=CommonAreaPersistenceTest`**

Expected: FAIL (classes not implemented yet)

- [ ] **Step 6: Make the test pass**

Run: `./mvnw test -Dtest=CommonAreaPersistenceTest`
Expected: PASS (2/2)

- [ ] **Step 7: Commit**

```bash
git add easy-maintenance-api/src/main/resources/db/migration/V129__create_common_area.sql \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/domain/CommonArea.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/infrastructure/persistence/CommonAreaRepository.java \
        easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/settings/infrastructure/persistence/CommonAreaPersistenceTest.java
git commit -m "feat(settings): add common_area entity, migration and repository"
```

---

## Task 3: SLA settings — DTOs, service, controller

**Files:**
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/domain/enums/OrganizationSettingCategory.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/dto/TicketSlaSettings.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/service/SettingsAccessGuard.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/service/OrganizationSettingsService.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/infrastructure/web/OrganizationSettingsController.java`
- Test: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/settings/application/service/OrganizationSettingsServiceTest.java`

**Interfaces:**
- Consumes: `OrganizationSetting`/`OrganizationSettingRepository` (Task 1);
  `OrganizationRepository.findByCode(String)` and `Organization.getId()` (existing,
  `org_users` module); `TenantContext.get()` (existing, `kernel.tenant`); `AuthenticationService
  .getCurrentUser()` → `User.getRole()` (existing, `org_users`); `TenantException`,
  `NotFoundException`, `ForbiddenException`, `RuleException` (existing, `commons.exceptions`).
- Produces:
  - `enum OrganizationSettingCategory { TICKETS_SLA }` with a static `OrganizationSettingCategory
    fromPathValue(String value)` that throws `RuleException("Categoria de configuração
    desconhecida: " + value)` on an unmatched/invalid value (used by Task 4's controller too, if a
    second category is ever added — not needed by Task 4 as written, since common areas aren't a
    category).
  - `record TicketSlaSettings(Integer defaultSlaHours, Boolean businessHoursOnly, BusinessHours
    businessHours, Map<String, Integer> prioritySla)` and nested `record BusinessHours(String
    start, String end)`, both in the same file.
  - `SettingsAccessGuard.requireAdminOrSyndic(User user)` — `static void`, throws
    `ForbiddenException("Apenas ADMIN ou SYNDIC podem gerenciar as configurações da organização.")`
    when `user.getRole()` is neither `ADMIN` nor `SYNDIC`.
  - `OrganizationSettingsService.getSettings(String category) -> Map<String, Object>` and
    `.updateSettings(String category, Map<String, Object> payload) -> Map<String, Object>`, both
    resolving the organization via `TenantContext` exactly like
    `ResidentTicketAdminService.resolveCurrentOrganization()`, and both calling
    `SettingsAccessGuard.requireAdminOrSyndic` first.

- [ ] **Step 1: Write `OrganizationSettingCategory.java`**

```java
public enum OrganizationSettingCategory {
    TICKETS_SLA;

    public static OrganizationSettingCategory fromPathValue(String value) {
        try {
            return OrganizationSettingCategory.valueOf(value);
        } catch (IllegalArgumentException | NullPointerException e) {
            throw new RuleException("Categoria de configuração desconhecida: " + value);
        }
    }
}
```

- [ ] **Step 2: Write `TicketSlaSettings.java`**

Two records in one file:
```java
public record TicketSlaSettings(
        Integer defaultSlaHours,
        Boolean businessHoursOnly,
        BusinessHours businessHours,
        Map<String, Integer> prioritySla) {

    public record BusinessHours(String start, String end) {}
}
```

- [ ] **Step 3: Write `SettingsAccessGuard.java`** exactly as specified in Interfaces above.

- [ ] **Step 4: Write the failing test for `OrganizationSettingsService`**

```java
@ExtendWith(MockitoExtension.class)
class OrganizationSettingsServiceTest {

    @Mock OrganizationRepository organizationRepository;
    @Mock OrganizationSettingRepository settingRepository;
    @Mock AuthenticationService authenticationService;
    @InjectMocks OrganizationSettingsService service;

    private Organization organization;
    private User adminUser;

    @BeforeEach
    void setUp() {
        organization = Organization.builder().id(1L).code("ORG-ABC123").build();
        adminUser = User.builder().id(10L).role(Role.ADMIN).build();
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    void getSettings_returnsHardcodedDefaults_whenNoRowSavedYet() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(adminUser);
        when(settingRepository.findByOrganizationIdAndCategory(1L, "TICKETS_SLA")).thenReturn(Optional.empty());

        Map<String, Object> result = service.getSettings("TICKETS_SLA");

        assertThat(result.get("defaultSlaHours")).isEqualTo(24);
    }

    @Test
    void updateSettings_rejectsUnknownPrioritySlaKey_throwsRuleException() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(adminUser);
        Map<String, Object> payload = validSlaPayload();
        ((Map<String, Object>) payload.get("prioritySla")).put("EXTRA", 1);

        assertThatThrownBy(() -> service.updateSettings("TICKETS_SLA", payload))
                .isInstanceOf(RuleException.class);
        verifyNoInteractions(settingRepository);
    }

    @Test
    void updateSettings_rejectsRoleOtherThanAdminOrSyndic_throwsForbiddenException() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(User.builder().id(11L).role(Role.TECH).build());

        assertThatThrownBy(() -> service.updateSettings("TICKETS_SLA", validSlaPayload()))
                .isInstanceOf(ForbiddenException.class);
        verifyNoInteractions(settingRepository);
    }

    @Test
    void updateSettings_unknownCategory_throwsRuleException() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(adminUser);

        assertThatThrownBy(() -> service.updateSettings("NOTIFICATIONS", validSlaPayload()))
                .isInstanceOf(RuleException.class);
    }

    @Test
    void getSettings_unknownCategory_throwsRuleException() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(adminUser);

        assertThatThrownBy(() -> service.getSettings("NOTIFICATIONS"))
                .isInstanceOf(RuleException.class);
        verifyNoInteractions(settingRepository);
    }

    @Test
    void updateSettings_savesSerializedJson_andReturnsPayloadBack() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(adminUser);
        when(settingRepository.findByOrganizationIdAndCategory(1L, "TICKETS_SLA")).thenReturn(Optional.empty());
        when(settingRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Map<String, Object> result = service.updateSettings("TICKETS_SLA", validSlaPayload());

        assertThat(result.get("defaultSlaHours")).isEqualTo(48);
        verify(settingRepository).save(any());
    }

    private Map<String, Object> validSlaPayload() {
        Map<String, Object> prioritySla = new HashMap<>();
        prioritySla.put("LOW", 72);
        prioritySla.put("MEDIUM", 24);
        prioritySla.put("HIGH", 8);
        prioritySla.put("CRITICAL", 2);
        Map<String, Object> businessHours = new HashMap<>();
        businessHours.put("start", "08:00");
        businessHours.put("end", "18:00");
        Map<String, Object> payload = new HashMap<>();
        payload.put("defaultSlaHours", 48);
        payload.put("businessHoursOnly", true);
        payload.put("businessHours", businessHours);
        payload.put("prioritySla", prioritySla);
        return payload;
    }
}
```

- [ ] **Step 5: Run `./mvnw test -Dtest=OrganizationSettingsServiceTest`**

Expected: FAIL (`OrganizationSettingsService` not implemented)

- [ ] **Step 6: Implement `OrganizationSettingsService`**

```java
@Service
@RequiredArgsConstructor
public class OrganizationSettingsService {
    public Map<String, Object> getSettings(String category) { ... }
    public Map<String, Object> updateSettings(String category, Map<String, Object> payload) { ... }
}
```

Approach (not determined by the signature alone):
- Both methods: resolve `Organization` via `TenantContext` (same as
  `ResidentTicketAdminService.resolveCurrentOrganization()`), call
  `SettingsAccessGuard.requireAdminOrSyndic(authenticationService.getCurrentUser())`, then
  `OrganizationSettingCategory.fromPathValue(category)` to validate the category exists.
- `getSettings`: look up the row by `(organizationId, "TICKETS_SLA")`. If present, deserialize
  `config` (Jackson `ObjectMapper`, injected as a field) into `Map<String, Object>` and return it.
  If absent, return the hardcoded defaults as a `Map` built from the literal values in the spec
  (`defaultSlaHours=24`, `businessHoursOnly=true`, `businessHours={start:"08:00",end:"18:00"}`,
  `prioritySla={LOW:72,MEDIUM:24,HIGH:8,CRITICAL:2}`) — build this map with
  `objectMapper.convertValue(new TicketSlaSettings(...), Map.class)` so there is one source of
  truth for the shape, not two hand-written literals.
- `updateSettings`: convert `payload` into `TicketSlaSettings` via
  `objectMapper.convertValue(payload, TicketSlaSettings.class)`, wrapped in try/catch rethrowing
  `IllegalArgumentException` as `RuleException("Formato de configuração inválido.")`. Then validate
  by hand: `defaultSlaHours != null && > 0`; `businessHoursOnly != null`; `businessHours != null &&
  businessHours.start() != null && businessHours.end() != null`; `prioritySla != null &&
  prioritySla.keySet().equals(Set.of("LOW","MEDIUM","HIGH","CRITICAL")) && prioritySla.values()
  .stream().allMatch(v -> v != null && v > 0)` — each failing check throws `RuleException` with a
  message naming the field. Serialize the validated `TicketSlaSettings` back to a JSON string
  (`objectMapper.writeValueAsString(...)`), upsert the `OrganizationSetting` row (find-or-build,
  `category = "TICKETS_SLA"`, `config = <json>`, save), and return `payload` (or re-parse the saved
  JSON back to a `Map`) to the caller.

- [ ] **Step 7: Run `./mvnw test -Dtest=OrganizationSettingsServiceTest`**

Expected: PASS (6/6)

- [ ] **Step 8: Write `OrganizationSettingsController.java`**

```java
@RestController
@RequestMapping("/easy-maintenance/api/v1/organizations/settings")
@RequiredArgsConstructor
public class OrganizationSettingsController {

    private final OrganizationSettingsService service;

    @GetMapping("/{category}")
    public Map<String, Object> get(@PathVariable String category) {
        return service.getSettings(category);
    }

    @PutMapping("/{category}")
    public Map<String, Object> put(@PathVariable String category, @RequestBody Map<String, Object> body) {
        return service.updateSettings(category, body);
    }
}
```

No new test for the controller — same convention as `ResidentTicketsController` (covered by the
service's unit tests; the controller itself has no logic beyond delegation).

- [ ] **Step 9: Run the full backend suite to check for regressions**

Run: `./mvnw test`
Expected: PASS, same count as before Task 3 plus the 5 new tests, 0 failures.

- [ ] **Step 10: Commit**

```bash
git add easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/domain/enums/OrganizationSettingCategory.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/dto/TicketSlaSettings.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/service/SettingsAccessGuard.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/service/OrganizationSettingsService.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/infrastructure/web/OrganizationSettingsController.java \
        easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/settings/application/service/OrganizationSettingsServiceTest.java
git commit -m "feat(settings): add TICKETS_SLA settings service, controller and validation"
```

---

## Task 4: Common areas — DTOs, service, controller

**Files:**
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/dto/CommonAreaRules.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/dto/CommonAreaResponse.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/dto/CreateCommonAreaRequest.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/dto/UpdateCommonAreaRequest.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/service/CommonAreaService.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/infrastructure/web/CommonAreasController.java`
- Test: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/settings/application/service/CommonAreaServiceTest.java`

**Interfaces:**
- Consumes: `CommonArea`/`CommonAreaRepository` (Task 2); `SettingsAccessGuard
  .requireAdminOrSyndic` (Task 3); same tenant-resolution and exception classes as Task 3.
- Produces:
  - `record CommonAreaRules(Boolean requiresApproval, Integer minAdvanceHours, Integer
    maxAdvanceDays, Integer maxDurationHours)`.
  - `record CommonAreaResponse(Long id, String name, Integer capacity, Boolean active, Integer
    feeCents, CommonAreaRules rules)`.
  - `record CreateCommonAreaRequest(String name, Integer capacity, Integer feeCents,
    CommonAreaRules rules)`.
  - `record UpdateCommonAreaRequest(String name, Integer capacity, Boolean active, Integer
    feeCents, CommonAreaRules rules)`.
  - `CommonAreaService.findAllForCurrentOrganization() -> List<CommonAreaResponse>`,
    `.create(CreateCommonAreaRequest) -> CommonAreaResponse`, `.update(Long id,
    UpdateCommonAreaRequest) -> CommonAreaResponse` (throws `NotFoundException` if the id doesn't
    belong to the current organization).

- [ ] **Step 1: Write the four DTO files** exactly as specified in Interfaces above (plain records,
  one per file, `CommonAreaRules` imported by the other three).

- [ ] **Step 2: Write the failing test for `CommonAreaService`**

```java
@ExtendWith(MockitoExtension.class)
class CommonAreaServiceTest {

    @Mock OrganizationRepository organizationRepository;
    @Mock CommonAreaRepository areaRepository;
    @Mock AuthenticationService authenticationService;
    @InjectMocks CommonAreaService service;

    private Organization organization;
    private User syndicUser;

    @BeforeEach
    void setUp() {
        organization = Organization.builder().id(1L).code("ORG-ABC123").build();
        syndicUser = User.builder().id(10L).role(Role.SYNDIC).build();
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    void create_rejectsNonPositiveCapacity_throwsRuleException() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(syndicUser);

        CreateCommonAreaRequest request = new CreateCommonAreaRequest(
                "Salão", 0, null, new CommonAreaRules(true, 24, 30, 6));

        assertThatThrownBy(() -> service.create(request)).isInstanceOf(RuleException.class);
        verifyNoInteractions(areaRepository);
    }

    @Test
    void create_rejectsRoleOtherThanAdminOrSyndic_throwsForbiddenException() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(User.builder().id(11L).role(Role.READER).build());

        CreateCommonAreaRequest request = new CreateCommonAreaRequest(
                "Salão", 50, null, new CommonAreaRules(true, 24, 30, 6));

        assertThatThrownBy(() -> service.create(request)).isInstanceOf(ForbiddenException.class);
    }

    @Test
    void create_savesAreaScopedToCurrentOrganization() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(syndicUser);
        when(areaRepository.save(any())).thenAnswer(inv -> {
            CommonArea a = inv.getArgument(0);
            a.setId(99L);
            return a;
        });

        CommonAreaResponse result = service.create(new CreateCommonAreaRequest(
                "Salão", 50, 15000, new CommonAreaRules(true, 24, 30, 6)));

        assertThat(result.id()).isEqualTo(99L);
        assertThat(result.feeCents()).isEqualTo(15000);
        ArgumentCaptor<CommonArea> captor = ArgumentCaptor.forClass(CommonArea.class);
        verify(areaRepository).save(captor.capture());
        assertThat(captor.getValue().getOrganizationId()).isEqualTo(1L);
    }

    @Test
    void update_throwsNotFoundException_whenAreaBelongsToAnotherOrganization() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(syndicUser);
        when(areaRepository.findByIdAndOrganizationId(5L, 1L)).thenReturn(Optional.empty());

        UpdateCommonAreaRequest request = new UpdateCommonAreaRequest(
                "Salão", 50, false, null, new CommonAreaRules(true, 24, 30, 6));

        assertThatThrownBy(() -> service.update(5L, request)).isInstanceOf(NotFoundException.class);
    }

    @Test
    void findAllForCurrentOrganization_mapsEntitiesToResponses() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(syndicUser);
        CommonArea entity = CommonArea.builder().id(1L).organizationId(1L).name("Salão")
                .capacity(50).active(true).feeCents(null)
                .rules("{\"requiresApproval\":true,\"minAdvanceHours\":24,\"maxAdvanceDays\":30,\"maxDurationHours\":6}")
                .build();
        when(areaRepository.findAllByOrganizationIdOrderByNameAsc(1L)).thenReturn(List.of(entity));

        List<CommonAreaResponse> result = service.findAllForCurrentOrganization();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).rules().requiresApproval()).isTrue();
    }

    @Test
    void findAllForCurrentOrganization_includesInactiveAreas() {
        TenantContext.set("ORG-ABC123");
        when(organizationRepository.findByCode("ORG-ABC123")).thenReturn(Optional.of(organization));
        when(authenticationService.getCurrentUser()).thenReturn(syndicUser);
        CommonArea inactive = CommonArea.builder().id(2L).organizationId(1L).name("Quadra")
                .capacity(10).active(false)
                .rules("{\"requiresApproval\":false,\"minAdvanceHours\":1,\"maxAdvanceDays\":7,\"maxDurationHours\":2}")
                .build();
        when(areaRepository.findAllByOrganizationIdOrderByNameAsc(1L)).thenReturn(List.of(inactive));

        List<CommonAreaResponse> result = service.findAllForCurrentOrganization();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).active()).isFalse();
    }
}
```

- [ ] **Step 3: Run `./mvnw test -Dtest=CommonAreaServiceTest`**

Expected: FAIL (`CommonAreaService` not implemented)

- [ ] **Step 4: Implement `CommonAreaService`**

```java
@Service
@RequiredArgsConstructor
public class CommonAreaService {
    public List<CommonAreaResponse> findAllForCurrentOrganization() { ... }
    public CommonAreaResponse create(CreateCommonAreaRequest request) { ... }
    public CommonAreaResponse update(Long id, UpdateCommonAreaRequest request) { ... }
}
```

Approach: every method resolves the organization via `TenantContext` (same pattern as Task 3) and
calls `SettingsAccessGuard.requireAdminOrSyndic`. Validation (both `create` and `update`, applied to
the `CommonAreaRules` + top-level fields): `name` non-blank; `capacity != null && > 0`; `feeCents ==
null || feeCents >= 0`; `rules != null`; `rules.requiresApproval() != null`;
`rules.minAdvanceHours() != null && >= 0`; `rules.maxAdvanceDays() != null && >= 1`;
`rules.maxDurationHours() != null && >= 1` — each failing check throws `RuleException`. `create`
serializes `rules` to JSON (Jackson `ObjectMapper`, injected field, same as Task 3) and saves a new
`CommonArea` with `active = true`. `update` loads via `findByIdAndOrganizationId` (→
`NotFoundException` if absent), overwrites all fields including `active` from the request, and
saves. `findAllForCurrentOrganization` lists via `findAllByOrganizationIdOrderByNameAsc` and maps
each entity to a `CommonAreaResponse` (deserializing `rules` back into `CommonAreaRules`).

- [ ] **Step 5: Run `./mvnw test -Dtest=CommonAreaServiceTest`**

Expected: PASS (6/6)

- [ ] **Step 6: Write `CommonAreasController.java`**

```java
@RestController
@RequestMapping("/easy-maintenance/api/v1/organizations/common-areas")
@RequiredArgsConstructor
public class CommonAreasController {

    private final CommonAreaService service;

    @GetMapping
    public List<CommonAreaResponse> findAll() {
        return service.findAllForCurrentOrganization();
    }

    @PostMapping
    public CommonAreaResponse create(@RequestBody CreateCommonAreaRequest request) {
        return service.create(request);
    }

    @PutMapping("/{id}")
    public CommonAreaResponse update(@PathVariable Long id, @RequestBody UpdateCommonAreaRequest request) {
        return service.update(id, request);
    }
}
```

- [ ] **Step 7: Run the full backend suite**

Run: `./mvnw test`
Expected: PASS, 0 failures.

- [ ] **Step 8: Commit**

```bash
git add easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/dto/CommonAreaRules.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/dto/CommonAreaResponse.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/dto/CreateCommonAreaRequest.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/dto/UpdateCommonAreaRequest.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/application/service/CommonAreaService.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/settings/infrastructure/web/CommonAreasController.java \
        easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/settings/application/service/CommonAreaServiceTest.java
git commit -m "feat(settings): add common area CRUD service, controller and validation"
```

---

## Task 5: Frontend — `/configuracoes` page shell + SLA tab

**Files:**
- Create: `easy-maintenance-web/src/app/configuracoes/page.tsx`
- Create: `easy-maintenance-web/src/components/settings/SlaSettingsTab.tsx`

**Interfaces:**
- Consumes: `api` from `@/lib/apiClient` (`api.get`/`api.put`, relative paths, `X-Org-Id` and auth
  handled by the existing interceptor); `mapError` from `@/lib/errorMapper`; `toast` from
  `react-hot-toast` — same imports as `financeiro/page.tsx`.
- Produces: default export `ConfiguracoesPage` rendering a tab switcher (`activeTab` local state,
  values `"sla" | "areas-comuns"`, same hand-rolled button-group pattern as `reports/page.tsx`'s
  `activeTab`) that currently only renders `<SlaSettingsTab />` for `"sla"` (the `"areas-comuns"`
  tab button exists and is clickable, rendering nothing yet — Task 6 fills it in). Role guard:
  redirect to `/` (or render nothing) when `localStorage`/`sessionStorage` `userRole` is neither
  `"ADMIN"` nor `"SYNDIC"`, same check as `financeiro/page.tsx:65-67`. Default export
  `SlaSettingsTab` — a controlled form bound to the `TICKETS_SLA` JSON shape (`defaultSlaHours`,
  `businessHoursOnly`, `businessHours.start`/`.end`, `prioritySla.LOW/MEDIUM/HIGH/CRITICAL`), with a
  "Salvar" button.

- [ ] **Step 1: Write `SlaSettingsTab.tsx`**

State: one `useState` per form field (mirroring `financeiro/page.tsx`'s flat field-state style, not
a single nested object, to keep each input's `onChange` trivial), plus `loading`/`saving`. On mount
(`useEffect`), `GET /organizations/settings/TICKETS_SLA` via `api.get(...)` and populate the
fields; on failure, `toast.error("Não foi possível carregar a configuração de SLA.")`. On submit,
build the payload object from the field states and call `PUT
/organizations/settings/TICKETS_SLA` via `api.put(...)`; on success,
`toast.success("Configuração de SLA salva.")`; on failure, use `mapError(error)` and show
`mapped.global` via `toast.error`, same pattern as the create-entry handler in
`financeiro/page.tsx`.

No client-side field validation beyond disabling "Salvar" while any required field is empty
(mirrors `isCreateInvalid` in `financeiro/page.tsx`) — the backend is the source of truth for
validation (Task 3).

- [ ] **Step 2: Write `page.tsx`**

```tsx
"use client";

export default function ConfiguracoesPage() {
  const [activeTab, setActiveTab] = useState<"sla" | "areas-comuns">("sla");
  const [canManageSettings, setCanManageSettings] = useState(false);
  // role check effect, same shape as financeiro/page.tsx:64-67

  return (
    <div>
      {/* tab buttons: "SLA de Chamados" / "Áreas Comuns", same hand-rolled pattern as reports/page.tsx */}
      {activeTab === "sla" && <SlaSettingsTab />}
    </div>
  );
}
```

- [ ] **Step 3: Run `cd easy-maintenance-web && npx tsc --noEmit`**

Expected: no new errors.

- [ ] **Step 4: Run `cd easy-maintenance-web && npm run build`**

Expected: build succeeds, `/configuracoes` listed as a route.

- [ ] **Step 5: Manual check** — with the backend running (Tasks 1–4 deployed/migrated locally) and
  logged in as an `ADMIN`/`SYNDIC` user, open `/configuracoes`, confirm the SLA tab loads the
  defaults (`defaultSlaHours=24`, etc.), edit a value, save, reload the page, confirm the edited
  value persists.

- [ ] **Step 6: Commit**

```bash
git add easy-maintenance-web/src/app/configuracoes/page.tsx \
        easy-maintenance-web/src/components/settings/SlaSettingsTab.tsx
git commit -m "feat(settings): add /configuracoes page with SLA settings tab"
```

---

## Task 6: Frontend — Áreas Comuns tab

**Files:**
- Create: `easy-maintenance-web/src/components/settings/CommonAreasTab.tsx`
- Create: `easy-maintenance-web/src/components/settings/CommonAreaFormModal.tsx`
- Modify: `easy-maintenance-web/src/app/configuracoes/page.tsx` (render `<CommonAreasTab />` for
  `activeTab === "areas-comuns"`, from Task 5)

**Interfaces:**
- Consumes: same `api`/`mapError`/`toast` as Task 5; `formatCurrencyInput`/
  `parseCurrencyInputToCents` from `@/lib/formatters` (same money-input helpers already used by
  `financeiro/page.tsx` for `fee_cents`/`formAmount`).
- Produces: default export `CommonAreasTab` — lists areas (`GET
  /organizations/common-areas`), each row shows name/capacity/active + "Editar" button, plus a
  "Nova área" button. Default export `CommonAreaFormModal` — takes `props: { area?:
  CommonAreaResponse; onClose: () => void; onSaved: () => void }`; when `area` is undefined it's a
  create form (`POST`), when defined it's an edit form pre-filled from `area` (`PUT .../{id}`,
  including an `active` toggle).

- [ ] **Step 1: Write `CommonAreaFormModal.tsx`**

Controlled form (name, capacity, fee — optional, using the currency-input helpers above — and the
four `rules` fields: `requiresApproval` checkbox, `minAdvanceHours`, `maxAdvanceDays`,
`maxDurationHours`), plus `active` toggle shown only in edit mode. On submit, calls `api.post` or
`api.put` depending on whether `area` was passed, then calls `props.onSaved()` and `props.onClose()`
on success; on failure, `mapError` + `toast.error`, same pattern as Task 5.

- [ ] **Step 2: Write `CommonAreasTab.tsx`**

`useState` list of `CommonAreaResponse`, `loading`, and modal open/edit-target state. On mount,
fetch the list; render a table/list of areas; "Nova área" opens `CommonAreaFormModal` with no
`area` prop; clicking a row's "Editar" opens it with that row's `area`; `onSaved` re-fetches the
list.

- [ ] **Step 3: Modify `page.tsx`** — import `CommonAreasTab`, add `{activeTab === "areas-comuns"
  && <CommonAreasTab />}` next to the existing SLA branch from Task 5.

- [ ] **Step 4: Run `cd easy-maintenance-web && npx tsc --noEmit`**

Expected: no new errors.

- [ ] **Step 5: Run `cd easy-maintenance-web && npm run build`**

Expected: build succeeds.

- [ ] **Step 6: Manual check** — on `/configuracoes`, switch to "Áreas Comuns", create an area with
  a fee and reservation rules, confirm it appears in the list, edit it (including toggling
  `active`), confirm the change persists after reload.

- [ ] **Step 7: Commit**

```bash
git add easy-maintenance-web/src/components/settings/CommonAreasTab.tsx \
        easy-maintenance-web/src/components/settings/CommonAreaFormModal.tsx \
        easy-maintenance-web/src/app/configuracoes/page.tsx
git commit -m "feat(settings): add common areas tab (list, create, edit)"
```

---

## Task 7: Frontend — nav entry

**Files:**
- Modify: `easy-maintenance-web/src/components/layout/app/UserTopBar.tsx`

**Interfaces:**
- Consumes: existing `storedUserRole` read in the mount effect (`UserTopBar.tsx:49-50`, where
  `isAdmin` is set) and the existing `dropdown-item` `<li>` pattern used for "Financeiro"
  (`UserTopBar.tsx:188-193`).

- [ ] **Step 1: Add a `canManageSettings` flag**

In the same mount effect that sets `isAdmin` (`UserTopBar.tsx:49-50`), also compute
`setCanManageSettings(storedUserRole === "ADMIN" || storedUserRole === "SYNDIC")` (new `useState`
`canManageSettings`, declared next to `isAdmin`).

- [ ] **Step 2: Add the menu item**

Right after the "Financeiro" `<li>` (`UserTopBar.tsx:188-193`), add:
```tsx
{canManageSettings && (
  <li>
    <button className="dropdown-item d-flex align-items-center gap-2 py-2" onClick={() => router.push("/configuracoes")} disabled={isBlocked}>
      <Settings size={18} className="text-muted" />
      Configurações
    </button>
  </li>
)}
```
Add `Settings` to the `lucide-react` import on line 9.

- [ ] **Step 3: Run `cd easy-maintenance-web && npx tsc --noEmit`**

Expected: no new errors.

- [ ] **Step 4: Manual check** — log in as `TECH`/`READER`, confirm "Configurações" is absent from
  the user menu and that navigating to `/configuracoes` directly still respects the page-level
  guard from Task 5. Log in as `ADMIN`/`SYNDIC`, confirm the menu item is present and navigates
  correctly.

- [ ] **Step 5: Commit**

```bash
git add easy-maintenance-web/src/components/layout/app/UserTopBar.tsx
git commit -m "feat(settings): add Configurações entry to the user menu"
```
