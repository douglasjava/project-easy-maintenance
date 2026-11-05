# Pix Automático pra assinatura de fornecedor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir o PIX manual do billing de fornecedor (marketplace, EPIC-028) por Pix Automático
da Asaas (mandato regulamentado pelo BC), reduzindo o atrito que pode fazer o fornecedor parar de
pagar e sumir do marketplace.

**Architecture:** `supplier_billing` continua isolado do billing de organização (sem FK cruzada).
Cadastro cria uma **autorização** Pix Automático (que já cobra o primeiro ciclo via QR Code
imediato) em vez de uma cobrança PIX avulsa. Ciclos seguintes continuam sendo criados pelo
`SupplierBillingJob` existente, agora referenciando a autorização (`pixAutomaticAuthorizationId`) —
o banco do fornecedor debita sozinho, sem QR novo. Dois webhooks novos tratam mandato
cancelado/expirado, regenerando uma autorização nova automaticamente.

**Tech Stack:** Spring Boot, WebClient (Asaas API), MySQL/Flyway, JUnit 5 + Mockito, Next.js/React
(frontend `web`).

**Spec:** `docs/superpowers/specs/2026-09-20-supplier-pix-automatico-design.md`

## Global Constraints

- Modo `MANUAL` de cobrança recorrente (não `SUBSCRIPTION`) — a aplicação continua criando cada
  cobrança via `SupplierBillingJob`.
- Não migra fornecedores já em PIX manual — marketplace ainda não está em PRD.
- Substitui de vez o PIX manual — não mantém os dois caminhos em paralelo.
- Preço fixo: `MONTHLY_PRICE = BigDecimal.valueOf(15.99)` (já existe, não muda).
- `PIX_DUE_DAYS = 3` (já existe) — usado como janela de expiração do QR Code imediato em segundos
  (`PIX_DUE_DAYS * 86400`).
- Nenhum arquivo do billing de **organização** é modificado, exceto os 3 call-sites mecânicos do
  Task 2 (adição de campo opcional em `CreatePaymentRequest`, sem mudança de comportamento).

---

### Task 1: Migration + entidade + repositório (`supplier_subscriptions`)

**Files:**
- Create: `src/main/resources/db/migration/V114__add_pix_automatico_to_supplier_subscriptions.sql`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/domain/SupplierSubscription.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/persistence/SupplierSubscriptionRepository.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/persistence/SupplierBillingPersistenceTest.java`

**Interfaces:**
- Produces: `SupplierSubscription.getExternalAuthorizationId()/setExternalAuthorizationId(String)`,
  `.getAuthorizationStatus()/.setAuthorizationStatus(String)`, `.getQrCodePayload()/.setQrCodePayload(String)`,
  `.getQrCodeImage()/.setQrCodeImage(String)`. `SupplierSubscriptionRepository.findByExternalAuthorizationId(String): Optional<SupplierSubscription>`.
  `payment_link`/`getPaymentLink()`/`setPaymentLink(String)` **removidos**.

- [ ] **Step 1: Write the failing test**

Adicionar ao final de `SupplierBillingPersistenceTest.java` (antes do último `}`):

```java
    @Test
    void save_and_findByExternalAuthorizationId_roundTrips() {
        Long supplierId = persistSupplier();
        subscriptionRepository.save(SupplierSubscription.builder()
                .supplierId(supplierId).status(SupplierSubscriptionStatus.PAST_DUE)
                .externalAuthorizationId("auth_123").authorizationStatus("CREATED")
                .qrCodePayload("00020126...").qrCodeImage("iVBORw0KGgo...").build());
        entityManager.flush();
        entityManager.clear();

        var found = subscriptionRepository.findByExternalAuthorizationId("auth_123");
        assertThat(found).isPresent();
        assertThat(found.get().getAuthorizationStatus()).isEqualTo("CREATED");
        assertThat(found.get().getQrCodePayload()).isEqualTo("00020126...");
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn test -Dtest=SupplierBillingPersistenceTest`
Expected: FAIL — compilation error (`findByExternalAuthorizationId`, `externalAuthorizationId` etc. não existem ainda).

- [ ] **Step 3: Criar a migration**

```sql
-- V114: TASK-278 (EPIC-028 Fase 2) -- substitui o PIX manual do fornecedor por Pix Automático
-- (mandato regulamentado pelo BC). external_authorization_id/authorization_status rastreiam o
-- mandato no Asaas; qr_code_payload/qr_code_image guardam o QR pendente (primeiro ciclo ou
-- reautorização após CANCELLED/EXPIRED) -- ciclos recorrentes com mandato ACTIVE debitam sozinhos,
-- sem QR novo. Marketplace ainda não está em PRD -- sem necessidade de backfill/compatibilidade.

ALTER TABLE supplier_subscriptions
    ADD COLUMN external_authorization_id VARCHAR(60) NULL,
    ADD COLUMN authorization_status VARCHAR(20) NULL,
    ADD COLUMN qr_code_payload TEXT NULL,
    ADD COLUMN qr_code_image MEDIUMTEXT NULL,
    DROP COLUMN payment_link;
```

- [ ] **Step 4: Atualizar a entidade `SupplierSubscription`**

Substituir o bloco do campo `paymentLink` por:

```java
    @Column(name = "external_authorization_id", length = 60)
    private String externalAuthorizationId;

    // Espelha o status bruto da autorização no Asaas (CREATED/ACTIVE/CANCELLED/REFUSED/EXPIRED) --
    // só observabilidade/debug, o campo de negócio que o resto do sistema lê continua sendo `status`.
    @Column(name = "authorization_status", length = 20)
    private String authorizationStatus;

    // QR do primeiro ciclo (antes do mandato ativar) ou de uma reautorização após CANCELLED/EXPIRED.
    // Ciclos recorrentes com mandato ACTIVE não geram QR novo -- o banco debita sozinho.
    @Column(name = "qr_code_payload", columnDefinition = "TEXT")
    private String qrCodePayload;

    @Column(name = "qr_code_image", columnDefinition = "MEDIUMTEXT")
    private String qrCodeImage;
```

- [ ] **Step 5: Adicionar o método no repositório**

Em `SupplierSubscriptionRepository.java`, adicionar:

```java
    Optional<SupplierSubscription> findByExternalAuthorizationId(String externalAuthorizationId);
```

- [ ] **Step 6: Run test to verify it passes**

Run: `mvn test -Dtest=SupplierBillingPersistenceTest`
Expected: PASS (as 3 tests do arquivo, incluindo os 2 já existentes).

- [ ] **Step 7: Commit**

```bash
git add src/main/resources/db/migration/V114__add_pix_automatico_to_supplier_subscriptions.sql \
        src/main/java/com/brainbyte/easy_maintenance/supplier_billing/domain/SupplierSubscription.java \
        src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/persistence/SupplierSubscriptionRepository.java \
        src/test/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/persistence/SupplierBillingPersistenceTest.java
git commit -m "feat(supplier-billing): TASK-278 - schema pro mandato Pix Automatico (V114)"
```

---

### Task 2: DTOs e cliente Asaas (`AsaasDTO`, `AsaasClient`)

**Files:**
- Modify: `src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/application/dto/AsaasDTO.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/client/AsaasClient.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/billing/application/service/BillingRecoveryService.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/jobs/service/TrialExpirationService.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/jobs/service/PixRenewalService.java`

**Interfaces:**
- Consumes: nenhuma interface de task anterior.
- Produces: `AsaasDTO.CreatePixAuthorizationRequest`, `AsaasDTO.PixAuthorizationResponse`,
  `AsaasDTO.ImmediateQrCode`, `AsaasDTO.PixAuthorizationFrequency`,
  `AsaasDTO.PixAuthorizationPaymentCreationMode`. `AsaasClient.createPixAuthorization(AsaasDTO.CreatePixAuthorizationRequest): AsaasDTO.PixAuthorizationResponse`.
  `AsaasDTO.CreatePaymentRequest` ganha um 7º campo `pixAutomaticAuthorizationId` (String, nullable,
  último da lista).

- [ ] **Step 1: Adicionar os novos tipos em `AsaasDTO.java`**

Logo após o `enum ChargeTypes { RECURRENT, INSTALLMENT, DETACHED }` (linha 41):

```java
    public enum PixAuthorizationFrequency { WEEKLY, MONTHLY, QUARTERLY, SEMIANNUALLY, ANNUALLY }
    public enum PixAuthorizationPaymentCreationMode { MANUAL, SUBSCRIPTION }
```

Substituir o record `CreatePaymentRequest` (linhas 71-78) por:

```java
    public record CreatePaymentRequest(
            String customer,
            BillingType billingType,
            BigDecimal value,
            LocalDate dueDate,
            String description,
            String externalReference,
            String pixAutomaticAuthorizationId
    ) {}

    public record ImmediateQrCode(
            Integer expirationSeconds,
            BigDecimal originalValue
    ) {}

    public record CreatePixAuthorizationRequest(
            PixAuthorizationFrequency frequency,
            String contractId,
            LocalDate startDate,
            String customerId,
            ImmediateQrCode immediateQrCode,
            BigDecimal value,
            String description,
            PixAuthorizationPaymentCreationMode paymentCreationMode
    ) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record PixAuthorizationResponse(
            String id,
            String status,
            String customerId,
            BigDecimal value,
            String payload,
            String encodedImage
    ) {}
```

No final do arquivo, logo antes do fechamento da classe (depois do record `WebhookCheckoutSubscription`,
linha 231), adicionar:

```java
    // Payload real do webhook PIX_AUTOMATIC_RECURRING_AUTHORIZATION_* (fetch direto da doc Asaas,
    // 20/09/2026): {"event": "...", "authorization": {"id", "status", "customerId", "frequency",
    // "value", "startDate", "finishDate", "immediateQrCode"}} -- não reenvia contractId, resolução
    // do supplierId é feita batendo authorization.id() contra external_authorization_id.
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record PixAutomaticAuthorizationObject(
            String id,
            String status
    ) {}
```

- [ ] **Step 2: Adicionar o método no `AsaasClient`**

Logo após `createSubscription` (depois da linha 62, antes de `getSubscription`):

```java
    @CircuitBreaker(name = "asaas")
    public AsaasDTO.PixAuthorizationResponse createPixAuthorization(AsaasDTO.CreatePixAuthorizationRequest req) {
        return webClient.post()
                .uri("/pix/automatic/authorizations")
                .bodyValue(req)
                .retrieve()
                .onStatus(HttpStatusCode::isError, this::mapError)
                .bodyToMono(AsaasDTO.PixAuthorizationResponse.class)
                .timeout(ASAAS_TIMEOUT)
                .block();
    }
```

- [ ] **Step 3: Corrigir os 3 call-sites de `CreatePaymentRequest` fora do supplier_billing**

Em `BillingRecoveryService.java` (linha 65-72):

```java
        AsaasDTO.CreatePaymentRequest req = new AsaasDTO.CreatePaymentRequest(
                account.getExternalCustomerId(),
                AsaasDTO.BillingType.PIX,
                BigDecimal.valueOf(invoice.getTotalCents(), 2),
                today,
                "Recuperação de assinatura - Easy Maintenance",
                externalReference,
                null
        );
```

Em `TrialExpirationService.java` (linha 177-184):

```java
            AsaasDTO.CreatePaymentRequest req = new AsaasDTO.CreatePaymentRequest(
                    account.getExternalCustomerId(),
                    AsaasDTO.BillingType.PIX,
                    BigDecimal.valueOf(invoice.getTotalCents(), 2),
                    nextDueDate,
                    plan.getName(),
                    "BILLING-" + billingSubscriptionId,
                    null
            );
```

Em `PixRenewalService.java` (linha 139-146):

```java
            AsaasDTO.CreatePaymentRequest req = new AsaasDTO.CreatePaymentRequest(
                    account.getExternalCustomerId(),
                    AsaasDTO.BillingType.PIX,
                    BigDecimal.valueOf(invoice.getTotalCents(), 2),
                    dueDate,
                    "Renovação mensal - Easy Maintenance",
                    externalReference,
                    null
            );
```

(Os 2 call-sites dentro de `supplier_billing` — `SupplierRegistrationService`/`SupplierBillingService`
— são corrigidos nos Tasks 4 e 5, não aqui.)

- [ ] **Step 4: Run full test suite to verify only the intended breakage**

Run: `mvn -q test-compile`
Expected: FAIL só em `SupplierRegistrationService.java`/`SupplierBillingService.java` (ainda não
corrigidos — Tasks 4/5). Nenhum outro erro de compilação.

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/application/dto/AsaasDTO.java \
        src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/client/AsaasClient.java \
        src/main/java/com/brainbyte/easy_maintenance/billing/application/service/BillingRecoveryService.java \
        src/main/java/com/brainbyte/easy_maintenance/jobs/service/TrialExpirationService.java \
        src/main/java/com/brainbyte/easy_maintenance/jobs/service/PixRenewalService.java
git commit -m "feat(asaas): TASK-278 - DTOs e client pro Pix Automatico (autorizacao de mandato)"
```

---

### Task 3: Campo `authorization` no `WebhookCheckoutEvent`

**Files:**
- Modify: `src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/application/dto/AsaasDTO.java`
- Modify (mecânico, só adicionar `null` ao final de cada chamada): `SubscriptionCreatedHandlerTest.java`,
  `PaymentRefusedHandlerTest.java`, `PaymentReceivedHandlerTest.java`,
  `PaymentReceivedHandlerSupplierBranchTest.java`, `PaymentReceivedHandlerCommissionTest.java`,
  `PaymentOverdueHandlerPixTest.java`, `CheckoutPaidHandlerTest.java`, `CheckoutExpiredHandlerTest.java`,
  `AsaasWebhookServiceTest.java`, `SimulationController.java` (3 call-sites)

**Interfaces:**
- Produces: `AsaasDTO.WebhookCheckoutEvent.authorization(): PixAutomaticAuthorizationObject` (8º
  campo do record, `null` em todos os eventos que não são de Pix Automático).

⚠️ **Atenção**: `WebhookCheckoutEvent` é um `record` — adicionar um campo muda a assinatura do
construtor posicional. **Todo** call-site precisa do `null` extra ou o projeto não compila. A lista
acima foi levantada via `grep -rn "new AsaasDTO.WebhookCheckoutEvent("` — se a implementação real
encontrar mais algum call-site que não está nesta lista, corrija-o também antes do Step 3.

- [ ] **Step 1: Adicionar o campo no record**

Em `AsaasDTO.java`, o record `WebhookCheckoutEvent` (linhas 176-185) passa de 7 pra 8 campos:

```java
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record WebhookCheckoutEvent(
            String id,
            String event,
            @JsonProperty("dateCreated") String dateCreated,
            WebhookAccount account,
            WebhookCheckout checkout,
            PaymentObject payment,
            WebhookSubscription subscription,
            PixAutomaticAuthorizationObject authorization
    ) {}
```

(O record `PixAutomaticAuthorizationObject` referenciado aqui foi criado no Task 2, Step 1 — deve
já existir no arquivo antes deste step.)

- [ ] **Step 2: Corrigir cada call-site (adicionar `null` como 8º argumento)**

`SubscriptionCreatedHandlerTest.java:175-178`:

```java
        var event = new AsaasDTO.WebhookCheckoutEvent(
                "evt-005", "SUBSCRIPTION_CREATED", "2026-04-30T10:00:00",
                null, null, null, null, null
        );
```

`SubscriptionCreatedHandlerTest.java:244-247`:

```java
        return new AsaasDTO.WebhookCheckoutEvent(
                eventId, "SUBSCRIPTION_CREATED", "2026-04-30T10:00:00",
                null, null, null, subscription, null
        );
```

`PaymentRefusedHandlerTest.java:234-235`:

```java
        var event = new AsaasDTO.WebhookCheckoutEvent(
                "evt-1", "PAYMENT_REFUSED", "2026-05-16T10:00:00", null, null, null, null, null);
```

`PaymentRefusedHandlerTest.java:263-266`:

```java
        return new AsaasDTO.WebhookCheckoutEvent(
                "evt-refused-1", "PAYMENT_REFUSED", "2026-05-16T10:00:00",
                null, null, paymentObj, null, null
        );
```

`PaymentReceivedHandlerTest.java:258-259`:

```java
        AsaasDTO.WebhookCheckoutEvent event = new AsaasDTO.WebhookCheckoutEvent(
                "evt-1", "PAYMENT_RECEIVED", "2026-05-16T10:00:00", null, null, null, null, null);
```

`PaymentReceivedHandlerTest.java:299-307`:

```java
        return new AsaasDTO.WebhookCheckoutEvent(
                "evt-pay-recv-1",
                "PAYMENT_RECEIVED",
                "2026-05-16T10:00:00",
                null,
                null,
                paymentObj,
                null,
                null
        );
```

`PaymentReceivedHandlerSupplierBranchTest.java:54-55`:

```java
        AsaasDTO.WebhookCheckoutEvent event = new AsaasDTO.WebhookCheckoutEvent(
                "evt-supplier-1", "PAYMENT_RECEIVED", "2026-09-11T10:00:00", null, null, paymentObj, null, null);
```

`PaymentReceivedHandlerCommissionTest.java:259-261`:

```java
        return new AsaasDTO.WebhookCheckoutEvent(
                "evt-1", "PAYMENT_RECEIVED", "2026-06-21T10:00:00",
                null, null, paymentObj, null, null);
```

`PaymentOverdueHandlerPixTest.java:166-169`:

```java
        var event = new AsaasDTO.WebhookCheckoutEvent(
                "evt-null", "PAYMENT_OVERDUE", "2026-05-01T10:00:00",
                null, null, null, null, null
        );
```

`PaymentOverdueHandlerPixTest.java:233-236`:

```java
        return new AsaasDTO.WebhookCheckoutEvent(
                "evt-001", "PAYMENT_OVERDUE", "2026-05-01T10:00:00",
                null, null, paymentObj, null, null
        );
```

`CheckoutPaidHandlerTest.java:171-174`:

```java
        return new AsaasDTO.WebhookCheckoutEvent(
                eventId, "CHECKOUT_PAID", "2026-04-30T10:00:00",
                null, checkout, null, null, null
        );
```

`CheckoutExpiredHandlerTest.java:173-176`:

```java
        return new AsaasDTO.WebhookCheckoutEvent(
                eventId, "CHECKOUT_EXPIRED", "2026-04-30T10:00:00",
                null, checkout, null, null, null
        );
```

`AsaasWebhookServiceTest.java:47-49`:

```java
        event = new AsaasDTO.WebhookCheckoutEvent(
                "evt-001", "CHECKOUT_COMPLETED", "2026-04-07", null, null, null, null, null
        );
```

`AsaasWebhookServiceTest.java:127-129`:

```java
        AsaasDTO.WebhookCheckoutEvent unknownEvent = new AsaasDTO.WebhookCheckoutEvent(
                "evt-002", "UNKNOWN_EVENT", "2026-04-07", null, null, null, null, null
        );
```

`SimulationController.java:329-332`:

```java
        AsaasDTO.WebhookCheckoutEvent createdEvent = new AsaasDTO.WebhookCheckoutEvent(
                "sim-evt-created-" + runId, "PAYMENT_CREATED",
                java.time.LocalDateTime.now().toString(),
                null, null, createdObj, null, null);
```

`SimulationController.java:346-349`:

```java
        AsaasDTO.WebhookCheckoutEvent event = new AsaasDTO.WebhookCheckoutEvent(
                "sim-evt-" + runId, "PAYMENT_RECEIVED",
                java.time.LocalDateTime.now().toString(),
                null, null, paymentObj, null, null);
```

`SimulationController.java:596-600`:

```java
        return new AsaasDTO.WebhookCheckoutEvent(
                "bsim-evt-" + UUID.randomUUID().toString().substring(0, 8),
                eventType,
                java.time.LocalDateTime.now().toString(),
                null, null, paymentObj, null, null);
```

- [ ] **Step 3: Run the full test suite**

Run: `mvn test`
Expected: PASS, sem nenhuma regressão. Se algum call-site não listado acima aparecer como erro de
compilação, corrija-o do mesmo jeito (adicionar `null` como último argumento) antes de prosseguir.

- [ ] **Step 4: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/application/dto/AsaasDTO.java \
        src/main/java/com/brainbyte/easy_maintenance/dev/SimulationController.java \
        src/test/java/com/brainbyte/easy_maintenance/webhooks/
git commit -m "feat(asaas): TASK-278 - campo authorization no WebhookCheckoutEvent"
```

---

### Task 4: `SupplierRegistrationService` — criar autorização em vez de PIX avulso

**Files:**
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/SelfRegisterSupplierResponse.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierRegistrationService.java`
- Modify: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierRegistrationServiceTest.java`

**Interfaces:**
- Consumes: `AsaasClient.createPixAuthorization` (Task 2), `SupplierSubscription.getExternalAuthorizationId/setExternalAuthorizationId` etc (Task 1).
- Produces: `SelfRegisterSupplierResponse(Long supplierId, String qrCodePayload, String qrCodeImage, String manageToken)`.
  `SupplierRegistrationService.regenerateAuthorization(Long supplierId): void` (usado pelo Task 8).

- [ ] **Step 1: Write the failing test — reescrever `SupplierRegistrationServiceTest.java`**

Substituir o conteúdo completo do arquivo:

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.infrastructure.saas.client.AsaasClient;
import com.brainbyte.easy_maintenance.supplier.application.service.SupplierCategoryAssembler;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SelfRegisterSupplierRequest;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SelfRegisterSupplierResponse;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierAccessToken;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierSubscriptionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SupplierRegistrationServiceTest {

    @Mock SupplierRepository supplierRepository;
    @Mock SupplierSubscriptionRepository subscriptionRepository;
    @Mock AsaasClient asaasClient;
    @Mock SupplierCategoryAssembler categoryAssembler;
    @Mock SupplierAccessTokenService accessTokenService;
    @InjectMocks SupplierRegistrationService service;

    private SelfRegisterSupplierRequest request() {
        return new SelfRegisterSupplierRequest("11222333000181", "Extintores Silva", "silva@example.com",
                "(11) 91234-5678", List.of(10L), List.of(30L), "São Paulo", "SP");
    }

    private void stubToken() {
        when(accessTokenService.ensureToken(any())).thenReturn(
                SupplierAccessToken.builder().id(1L).supplierId(100L).token("abc123").build());
    }

    private AsaasDTO.PixAuthorizationResponse authorizationResponse(String id, String customerId) {
        return new AsaasDTO.PixAuthorizationResponse(id, "CREATED", customerId,
                BigDecimal.valueOf(15.99), "00020126-payload", "iVBORw0-image");
    }

    @Test
    void register_newSupplier_createsSupplierLinksCategoriesAndCreatesAuthorization() {
        when(supplierRepository.findByDocument("11222333000181")).thenReturn(Optional.empty());
        when(supplierRepository.save(any(Supplier.class))).thenAnswer(inv -> {
            Supplier s = inv.getArgument(0);
            s.setId(100L);
            return s;
        });
        stubToken();
        when(subscriptionRepository.findBySupplierId(100L)).thenReturn(Optional.empty());
        when(asaasClient.createCustomer(any())).thenReturn(
                new AsaasDTO.CustomerResponse("cus_123", "Extintores Silva", "11222333000181", "silva@example.com"));
        when(asaasClient.createPixAuthorization(any())).thenReturn(authorizationResponse("auth_123", "cus_123"));
        when(subscriptionRepository.save(any(SupplierSubscription.class))).thenAnswer(inv -> inv.getArgument(0));

        SelfRegisterSupplierResponse response = service.register(request());

        assertThat(response.supplierId()).isEqualTo(100L);
        assertThat(response.qrCodePayload()).isEqualTo("00020126-payload");
        assertThat(response.qrCodeImage()).isEqualTo("iVBORw0-image");
        assertThat(response.manageToken()).isEqualTo("abc123");

        verify(categoryAssembler).setCategories(100L, List.of(10L));
        verify(categoryAssembler).setServices(100L, List.of(30L));

        ArgumentCaptor<AsaasDTO.CreatePixAuthorizationRequest> authCaptor =
                ArgumentCaptor.forClass(AsaasDTO.CreatePixAuthorizationRequest.class);
        verify(asaasClient).createPixAuthorization(authCaptor.capture());
        assertThat(authCaptor.getValue().contractId()).isEqualTo("SUPPLIER-100");
        assertThat(authCaptor.getValue().frequency()).isEqualTo(AsaasDTO.PixAuthorizationFrequency.MONTHLY);
        assertThat(authCaptor.getValue().paymentCreationMode()).isEqualTo(AsaasDTO.PixAuthorizationPaymentCreationMode.MANUAL);

        ArgumentCaptor<SupplierSubscription> subCaptor = ArgumentCaptor.forClass(SupplierSubscription.class);
        verify(subscriptionRepository).save(subCaptor.capture());
        assertThat(subCaptor.getValue().getId()).isNull(); // insert, não update
        assertThat(subCaptor.getValue().getStatus()).isEqualTo(SupplierSubscriptionStatus.PAST_DUE);
        assertThat(subCaptor.getValue().getExternalAuthorizationId()).isEqualTo("auth_123");
        assertThat(subCaptor.getValue().getAuthorizationStatus()).isEqualTo("CREATED");
    }

    @Test
    void register_existingDocument_reusesSupplier_doesNotCreateDuplicateSupplier() {
        Supplier existing = Supplier.builder().id(50L).document("11222333000181")
                .name("Extintores Silva Original").registrationCount(2).build();
        when(supplierRepository.findByDocument("11222333000181")).thenReturn(Optional.of(existing));
        when(accessTokenService.ensureToken(50L)).thenReturn(
                SupplierAccessToken.builder().id(1L).supplierId(50L).token("abc123").build());
        when(subscriptionRepository.findBySupplierId(50L)).thenReturn(Optional.empty());
        when(asaasClient.createCustomer(any())).thenReturn(
                new AsaasDTO.CustomerResponse("cus_456", "Extintores Silva", "11222333000181", "silva@example.com"));
        when(asaasClient.createPixAuthorization(any())).thenReturn(authorizationResponse("auth_456", "cus_456"));
        when(subscriptionRepository.save(any(SupplierSubscription.class))).thenAnswer(inv -> inv.getArgument(0));

        SelfRegisterSupplierResponse response = service.register(request());

        assertThat(response.supplierId()).isEqualTo(50L);
        verify(supplierRepository, never()).save(any());
        verifyNoInteractions(categoryAssembler);
    }

    @Test
    void register_pendingUnexpiredSubscription_reusesStoredQrCode_doesNotCallAsaas() {
        Supplier existing = Supplier.builder().id(50L).document("11222333000181").name("Extintores Silva").build();
        when(supplierRepository.findByDocument("11222333000181")).thenReturn(Optional.of(existing));
        when(accessTokenService.ensureToken(50L)).thenReturn(
                SupplierAccessToken.builder().id(1L).supplierId(50L).token("abc123").build());
        SupplierSubscription pending = SupplierSubscription.builder().id(9L).supplierId(50L)
                .status(SupplierSubscriptionStatus.PAST_DUE).externalCustomerId("cus_old")
                .qrCodePayload("payload-old").qrCodeImage("image-old")
                .currentPeriodEnd(LocalDate.now().plusDays(2)).build();
        when(subscriptionRepository.findBySupplierId(50L)).thenReturn(Optional.of(pending));

        SelfRegisterSupplierResponse response = service.register(request());

        assertThat(response.qrCodePayload()).isEqualTo("payload-old");
        assertThat(response.qrCodeImage()).isEqualTo("image-old");
        verifyNoInteractions(asaasClient);
        verify(subscriptionRepository, never()).save(any());
    }

    @Test
    void register_pendingExpiredSubscription_regeneratesAuthorization_updatesSameRow() {
        Supplier existing = Supplier.builder().id(50L).document("11222333000181").name("Extintores Silva")
                .email("silva@example.com").phone("(11) 91234-5678").build();
        when(supplierRepository.findByDocument("11222333000181")).thenReturn(Optional.of(existing));
        when(accessTokenService.ensureToken(50L)).thenReturn(
                SupplierAccessToken.builder().id(1L).supplierId(50L).token("abc123").build());
        SupplierSubscription expired = SupplierSubscription.builder().id(9L).supplierId(50L)
                .status(SupplierSubscriptionStatus.PAST_DUE).externalCustomerId("cus_old")
                .qrCodePayload("payload-old").currentPeriodEnd(LocalDate.now().minusDays(1)).build();
        when(subscriptionRepository.findBySupplierId(50L)).thenReturn(Optional.of(expired));
        when(asaasClient.createPixAuthorization(any())).thenReturn(authorizationResponse("auth_new", "cus_old"));
        when(subscriptionRepository.save(any(SupplierSubscription.class))).thenAnswer(inv -> inv.getArgument(0));

        SelfRegisterSupplierResponse response = service.register(request());

        assertThat(response.qrCodePayload()).isEqualTo("00020126-payload");
        verify(asaasClient, never()).createCustomer(any()); // reaproveita externalCustomerId já salvo
        ArgumentCaptor<SupplierSubscription> subCaptor = ArgumentCaptor.forClass(SupplierSubscription.class);
        verify(subscriptionRepository).save(subCaptor.capture());
        assertThat(subCaptor.getValue().getId()).isEqualTo(9L); // update, não insert
    }

    @Test
    void register_alreadyActiveSubscription_doesNotCreateAuthorization_returnsNullQrCode() {
        Supplier existing = Supplier.builder().id(50L).document("11222333000181").name("Extintores Silva").build();
        when(supplierRepository.findByDocument("11222333000181")).thenReturn(Optional.of(existing));
        when(accessTokenService.ensureToken(50L)).thenReturn(
                SupplierAccessToken.builder().id(1L).supplierId(50L).token("abc123").build());
        SupplierSubscription active = SupplierSubscription.builder().id(9L).supplierId(50L)
                .status(SupplierSubscriptionStatus.ACTIVE).build();
        when(subscriptionRepository.findBySupplierId(50L)).thenReturn(Optional.of(active));

        SelfRegisterSupplierResponse response = service.register(request());

        assertThat(response.qrCodePayload()).isNull();
        assertThat(response.qrCodeImage()).isNull();
        assertThat(response.manageToken()).isEqualTo("abc123");
        verifyNoInteractions(asaasClient);
        verify(subscriptionRepository, never()).save(any());
    }

    @Test
    void regenerateAuthorization_existingSupplierAndSubscription_createsNewAuthorization() {
        Supplier supplier = Supplier.builder().id(70L).document("11222333000181").name("Extintores Silva")
                .email("silva@example.com").phone("(11) 91234-5678").build();
        when(supplierRepository.findById(70L)).thenReturn(Optional.of(supplier));
        SupplierSubscription subscription = SupplierSubscription.builder().id(20L).supplierId(70L)
                .status(SupplierSubscriptionStatus.PAST_DUE).externalCustomerId("cus_existing").build();
        when(subscriptionRepository.findBySupplierId(70L)).thenReturn(Optional.of(subscription));
        when(asaasClient.createPixAuthorization(any())).thenReturn(authorizationResponse("auth_regen", "cus_existing"));
        when(subscriptionRepository.save(any(SupplierSubscription.class))).thenAnswer(inv -> inv.getArgument(0));

        service.regenerateAuthorization(70L);

        verify(asaasClient, never()).createCustomer(any());
        ArgumentCaptor<SupplierSubscription> subCaptor = ArgumentCaptor.forClass(SupplierSubscription.class);
        verify(subscriptionRepository).save(subCaptor.capture());
        assertThat(subCaptor.getValue().getExternalAuthorizationId()).isEqualTo("auth_regen");
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn test -Dtest=SupplierRegistrationServiceTest`
Expected: FAIL — compilação (`createPixAuthorization` não é chamado ainda, `regenerateAuthorization`
não existe, `SelfRegisterSupplierResponse` ainda tem `paymentLink` em vez de `qrCodePayload`/`qrCodeImage`).

- [ ] **Step 3: Atualizar `SelfRegisterSupplierResponse`**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.dto;

public record SelfRegisterSupplierResponse(
        Long supplierId,
        String qrCodePayload,
        String qrCodeImage,
        String manageToken
) {}
```

- [ ] **Step 4: Reescrever `SupplierRegistrationService.java`**

Substituir o conteúdo completo do arquivo:

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.infrastructure.saas.client.AsaasClient;
import com.brainbyte.easy_maintenance.supplier.application.service.SupplierCategoryAssembler;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SelfRegisterSupplierRequest;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SelfRegisterSupplierResponse;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierAccessToken;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierSubscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

// Fase 2 EPIC-028/TASK-278: Pix Automatico substitui o PIX avulso (DETACHED) do v1 -- a
// autorizacao ja cobra o primeiro ciclo via QR Code imediato e ativa o mandato ao mesmo tempo.
// Achado de QA (13/09/2026, mantido): reaproveita a autorizacao pendente em vez de gerar uma nova
// a cada tentativa de auto-cadastro. Token de acesso e gerado aqui (nao so na ativacao), pra o
// fornecedor ja sair do cadastro com um link permanente pra acompanhar a conta.
@Service
@RequiredArgsConstructor
public class SupplierRegistrationService {

    private static final BigDecimal MONTHLY_PRICE = BigDecimal.valueOf(15.99);
    private static final int PIX_DUE_DAYS = 3;

    private final SupplierRepository supplierRepository;
    private final SupplierSubscriptionRepository subscriptionRepository;
    private final AsaasClient asaasClient;
    private final SupplierCategoryAssembler categoryAssembler;
    private final SupplierAccessTokenService accessTokenService;

    @Transactional
    public SelfRegisterSupplierResponse register(SelfRegisterSupplierRequest request) {
        Optional<Supplier> existingSupplier = supplierRepository.findByDocument(request.document());
        Supplier supplier;
        if (existingSupplier.isPresent()) {
            supplier = existingSupplier.get();
        } else {
            supplier = supplierRepository.save(newSupplier(request));
            categoryAssembler.setCategories(supplier.getId(), request.categoryIds());
            categoryAssembler.setServices(supplier.getId(), request.serviceIds());
        }

        SupplierAccessToken token = accessTokenService.ensureToken(supplier.getId());

        SupplierSubscription subscription = subscriptionRepository.findBySupplierId(supplier.getId())
                .orElseGet(() -> SupplierSubscription.builder()
                        .supplierId(supplier.getId())
                        .status(SupplierSubscriptionStatus.PAST_DUE)
                        .build());

        String qrCodePayload;
        String qrCodeImage;
        if (subscription.getStatus() == SupplierSubscriptionStatus.ACTIVE) {
            qrCodePayload = null;
            qrCodeImage = null;
        } else if (subscription.getId() != null && hasUnexpiredPendingCharge(subscription)) {
            qrCodePayload = subscription.getQrCodePayload();
            qrCodeImage = subscription.getQrCodeImage();
        } else {
            chargeNewCycle(supplier, subscription);
            qrCodePayload = subscription.getQrCodePayload();
            qrCodeImage = subscription.getQrCodeImage();
        }

        return new SelfRegisterSupplierResponse(supplier.getId(), qrCodePayload, qrCodeImage, token.getToken());
    }

    // Chamado pelos handlers de PIX_AUTOMATIC_RECURRING_AUTHORIZATION_CANCELLED/EXPIRED (Task 8) --
    // o mandato cancelado nao pode ser "reativado", precisa de uma autorizacao nova.
    @Transactional
    public void regenerateAuthorization(Long supplierId) {
        Supplier supplier = supplierRepository.findById(supplierId)
                .orElseThrow(() -> new NotFoundException("Fornecedor não encontrado: " + supplierId));
        SupplierSubscription subscription = subscriptionRepository.findBySupplierId(supplierId)
                .orElseThrow(() -> new NotFoundException("Fornecedor sem assinatura: " + supplierId));
        chargeNewCycle(supplier, subscription);
    }

    private boolean hasUnexpiredPendingCharge(SupplierSubscription subscription) {
        return subscription.getQrCodePayload() != null
                && subscription.getCurrentPeriodEnd() != null
                && !subscription.getCurrentPeriodEnd().isBefore(LocalDate.now());
    }

    private void chargeNewCycle(Supplier supplier, SupplierSubscription subscription) {
        String customerId = subscription.getExternalCustomerId();
        if (customerId == null) {
            AsaasDTO.CustomerResponse customer = asaasClient.createCustomer(new AsaasDTO.CreateCustomerRequest(
                    supplier.getName(), supplier.getDocument(), supplier.getEmail(), supplier.getPhone(), supplier.getPhone(),
                    null, null, null, null, null, null, null, null));
            customerId = customer.id();
        }

        LocalDate dueDate = LocalDate.now().plusDays(PIX_DUE_DAYS);
        AsaasDTO.PixAuthorizationResponse authorization = asaasClient.createPixAuthorization(
                new AsaasDTO.CreatePixAuthorizationRequest(
                        AsaasDTO.PixAuthorizationFrequency.MONTHLY, "SUPPLIER-" + supplier.getId(), LocalDate.now(),
                        customerId, new AsaasDTO.ImmediateQrCode(PIX_DUE_DAYS * 86400, MONTHLY_PRICE),
                        MONTHLY_PRICE, "Assinatura marketplace de fornecedores — Easy Maintenance",
                        AsaasDTO.PixAuthorizationPaymentCreationMode.MANUAL));

        subscription.setStatus(SupplierSubscriptionStatus.PAST_DUE);
        subscription.setExternalCustomerId(customerId);
        subscription.setExternalAuthorizationId(authorization.id());
        subscription.setAuthorizationStatus(authorization.status());
        subscription.setQrCodePayload(authorization.payload());
        subscription.setQrCodeImage(authorization.encodedImage());
        subscription.setCurrentPeriodEnd(dueDate);
        subscriptionRepository.save(subscription);
    }

    private Supplier newSupplier(SelfRegisterSupplierRequest request) {
        return Supplier.builder()
                .document(request.document())
                .name(request.name())
                .email(request.email())
                .phone(request.phone())
                .city(StringUtils.hasText(request.city()) ? request.city() : null)
                .state(StringUtils.hasText(request.state()) ? request.state() : null)
                .registrationCount(0)
                .build();
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `mvn test -Dtest=SupplierRegistrationServiceTest`
Expected: PASS (6 testes).

- [ ] **Step 6: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/SelfRegisterSupplierResponse.java \
        src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierRegistrationService.java \
        src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierRegistrationServiceTest.java
git commit -m "feat(supplier-billing): TASK-278 - cadastro cria autorizacao Pix Automatico"
```

---

### Task 5: `SupplierBillingService` — ciclos recorrentes referenciam a autorização

**Files:**
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierBillingService.java`
- Modify: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierBillingServiceTest.java`

**Interfaces:**
- Consumes: `AsaasDTO.CreatePaymentRequest` (7 campos, Task 2), `SupplierSubscription.getExternalAuthorizationId()` (Task 1).

- [ ] **Step 1: Write the failing test**

Substituir o primeiro teste de `SupplierBillingServiceTest.java`:

```java
    @Test
    void processDueCycles_activeSubscriptionDue_generatesNewPixChargeReferencingAuthorization() {
        var subscription = SupplierSubscription.builder().id(1L).supplierId(100L)
                .status(SupplierSubscriptionStatus.ACTIVE).externalCustomerId("cus_123")
                .externalAuthorizationId("auth_123")
                .currentPeriodEnd(LocalDate.now().minusDays(1)).build();
        when(subscriptionRepository.findByStatusAndCurrentPeriodEndLessThanEqual(
                eq(SupplierSubscriptionStatus.ACTIVE), any())).thenReturn(List.of(subscription));
        when(asaasClient.createPayment(any())).thenReturn(new AsaasDTO.PaymentResponse(
                "pay_789", "cus_123", AsaasDTO.BillingType.PIX, BigDecimal.valueOf(15.99),
                LocalDate.now().plusDays(3), "PENDING", "https://asaas.com/i/pay_789", null));

        service.processDueCycles();

        ArgumentCaptor<AsaasDTO.CreatePaymentRequest> captor = ArgumentCaptor.forClass(AsaasDTO.CreatePaymentRequest.class);
        verify(asaasClient).createPayment(captor.capture());
        assertThat(captor.getValue().pixAutomaticAuthorizationId()).isEqualTo("auth_123");

        verify(subscriptionRepository).save(argThat(s ->
                "pay_789".equals(s.getExternalPaymentId()) && s.getCurrentPeriodEnd().equals(LocalDate.now().plusDays(3))));
        verify(supplierRepository, never()).save(any());
    }
```

(adicionar `import org.mockito.ArgumentCaptor;` no topo do arquivo, junto dos outros imports do
`org.mockito`; o segundo teste do arquivo — `processDueCycles_pastDueBeyondGracePeriod_disablesMarketplace`
— fica sem mudança.)

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn test -Dtest=SupplierBillingServiceTest`
Expected: FAIL — `pixAutomaticAuthorizationId()` ainda não é preenchido no request real (o método
`chargeNextCycle` ainda não passa `subscription.getExternalAuthorizationId()`).

- [ ] **Step 3: Atualizar `chargeNextCycle` em `SupplierBillingService.java`**

Substituir o método (linhas 65-76):

```java
    private void chargeNextCycle(SupplierSubscription subscription) {
        LocalDate dueDate = LocalDate.now().plusDays(PIX_DUE_DAYS);
        AsaasDTO.PaymentResponse payment = asaasClient.createPayment(new AsaasDTO.CreatePaymentRequest(
                subscription.getExternalCustomerId(), AsaasDTO.BillingType.PIX, MONTHLY_PRICE, dueDate,
                "Assinatura marketplace de fornecedores — Easy Maintenance",
                "SUPPLIER-" + subscription.getSupplierId(), subscription.getExternalAuthorizationId()));

        subscription.setExternalPaymentId(payment.id());
        subscription.setCurrentPeriodEnd(dueDate);
        subscriptionRepository.save(subscription);
    }
```

(`setPaymentLink` removido — coluna não existe mais, e ciclo recorrente com mandato `ACTIVE` não
gera QR novo, o débito é automático.)

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn test -Dtest=SupplierBillingServiceTest`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierBillingService.java \
        src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierBillingServiceTest.java
git commit -m "feat(supplier-billing): TASK-278 - ciclo recorrente referencia a autorizacao Pix Automatico"
```

---

### Task 6: `SupplierPaymentActivationService` — limpa QR ao ativar

**Files:**
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierPaymentActivationService.java`
- Modify: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierPaymentActivationServiceTest.java`

**Interfaces:**
- Consumes: `SupplierSubscription.setAuthorizationStatus/setQrCodePayload/setQrCodeImage` (Task 1).

- [ ] **Step 1: Write the failing test**

Adicionar ao teste `activate_pendingSubscription_activatesSupplierAndSendsEmail` (depois da linha
`verify(subscriptionRepository).save(argThat(s -> s.getStatus() == SupplierSubscriptionStatus.ACTIVE));`),
trocando essa linha por:

```java
        verify(subscriptionRepository).save(argThat(s ->
                s.getStatus() == SupplierSubscriptionStatus.ACTIVE
                        && "ACTIVE".equals(s.getAuthorizationStatus())
                        && s.getQrCodePayload() == null
                        && s.getQrCodeImage() == null));
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn test -Dtest=SupplierPaymentActivationServiceTest`
Expected: FAIL — `getAuthorizationStatus()` continua `null` (serviço ainda não seta).

- [ ] **Step 3: Atualizar `activateFromWebhook`**

Em `SupplierPaymentActivationService.java`, substituir:

```java
        subscription.setStatus(SupplierSubscriptionStatus.ACTIVE);
        subscription.setCurrentPeriodEnd(java.time.LocalDate.now().plusMonths(1));
        subscriptionRepository.save(subscription);
```

por:

```java
        subscription.setStatus(SupplierSubscriptionStatus.ACTIVE);
        subscription.setCurrentPeriodEnd(java.time.LocalDate.now().plusMonths(1));
        subscription.setAuthorizationStatus("ACTIVE");
        subscription.setQrCodePayload(null);
        subscription.setQrCodeImage(null);
        subscriptionRepository.save(subscription);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn test -Dtest=SupplierPaymentActivationServiceTest`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierPaymentActivationService.java \
        src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierPaymentActivationServiceTest.java
git commit -m "feat(supplier-billing): TASK-278 - limpa QR pendente ao ativar mandato"
```

---

### Task 7: `SupplierSelfManageService`/`SupplierManageResponse` — QR em vez de link

**Files:**
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/SupplierManageResponse.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierSelfManageService.java`
- Modify: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierSelfManageServiceTest.java`

**Interfaces:**
- Produces: `SupplierManageResponse` troca `paymentLink` por `qrCodePayload`/`qrCodeImage`.

- [ ] **Step 1: Write the failing test**

Em `SupplierSelfManageServiceTest.java`, atualizar `get_pastDueSubscription_exposesPendingPaymentLink`:

```java
    @Test
    void get_pastDueSubscription_exposesPendingQrCode() {
        var token = SupplierAccessToken.builder().id(1L).supplierId(100L).token("abc123").build();
        when(accessTokenRepository.findByToken("abc123")).thenReturn(Optional.of(token));
        var supplier = Supplier.builder().id(100L).name("Extintores Silva").build();
        when(supplierRepository.findById(100L)).thenReturn(Optional.of(supplier));
        var subscription = SupplierSubscription.builder().supplierId(100L).status(SupplierSubscriptionStatus.PAST_DUE)
                .qrCodePayload("payload-pendente").qrCodeImage("image-pendente").build();
        when(subscriptionRepository.findBySupplierId(100L)).thenReturn(Optional.of(subscription));
        when(categoryAssembler.categoriesFor(100L)).thenReturn(List.of());
        when(categoryAssembler.servicesFor(100L)).thenReturn(List.of());

        SupplierManageResponse response = service.get("abc123");

        assertThat(response.qrCodePayload()).isEqualTo("payload-pendente");
        assertThat(response.qrCodeImage()).isEqualTo("image-pendente");
    }
```

(o teste `get_validToken_returnsProfileAndSubscriptionStatus` já não referencia `paymentLink`
diretamente além do `assertThat(response.paymentLink()).isNull();` — trocar essa linha por
`assertThat(response.qrCodePayload()).isNull();`.)

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn test -Dtest=SupplierSelfManageServiceTest`
Expected: FAIL — compilação (`SupplierManageResponse.qrCodePayload()` não existe ainda).

- [ ] **Step 3: Atualizar `SupplierManageResponse`**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.dto;

import com.brainbyte.easy_maintenance.supplier.application.dto.CategoryTag;
import com.brainbyte.easy_maintenance.supplier.application.dto.ServiceTag;

import java.util.List;

public record SupplierManageResponse(
        Long supplierId,
        String document,
        String name,
        String email,
        String phone,
        List<CategoryTag> categories,
        List<ServiceTag> services,
        String city,
        String state,
        boolean marketplaceEnabled,
        String subscriptionStatus,
        String qrCodePayload,
        String qrCodeImage
) {}
```

- [ ] **Step 4: Atualizar `SupplierSelfManageService.toResponse`**

Substituir:

```java
    private SupplierManageResponse toResponse(Supplier supplier) {
        SupplierSubscription subscription = subscriptionRepository.findBySupplierId(supplier.getId()).orElse(null);
        String status = subscription != null ? subscription.getStatus().name() : "SEM_ASSINATURA";
        String paymentLink = (subscription != null && subscription.getStatus() != SupplierSubscriptionStatus.ACTIVE)
                ? subscription.getPaymentLink() : null;

        return new SupplierManageResponse(supplier.getId(), supplier.getDocument(), supplier.getName(),
                supplier.getEmail(), supplier.getPhone(),
                categoryAssembler.categoriesFor(supplier.getId()), categoryAssembler.servicesFor(supplier.getId()),
                supplier.getCity(), supplier.getState(),
                supplier.isMarketplaceEnabled(), status, paymentLink);
    }
```

por:

```java
    private SupplierManageResponse toResponse(Supplier supplier) {
        SupplierSubscription subscription = subscriptionRepository.findBySupplierId(supplier.getId()).orElse(null);
        String status = subscription != null ? subscription.getStatus().name() : "SEM_ASSINATURA";
        boolean showQrCode = subscription != null && subscription.getStatus() != SupplierSubscriptionStatus.ACTIVE;
        String qrCodePayload = showQrCode ? subscription.getQrCodePayload() : null;
        String qrCodeImage = showQrCode ? subscription.getQrCodeImage() : null;

        return new SupplierManageResponse(supplier.getId(), supplier.getDocument(), supplier.getName(),
                supplier.getEmail(), supplier.getPhone(),
                categoryAssembler.categoriesFor(supplier.getId()), categoryAssembler.servicesFor(supplier.getId()),
                supplier.getCity(), supplier.getState(),
                supplier.isMarketplaceEnabled(), status, qrCodePayload, qrCodeImage);
    }
```

- [ ] **Step 5: Run test to verify it passes**

Run: `mvn test -Dtest=SupplierSelfManageServiceTest`
Expected: PASS (6 testes).

- [ ] **Step 6: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/SupplierManageResponse.java \
        src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierSelfManageService.java \
        src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierSelfManageServiceTest.java
git commit -m "feat(supplier-billing): TASK-278 - tela de gestao expoe QR Code em vez de link"
```

---

### Task 8: Webhooks de mandato cancelado/expirado

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/PixAutomaticAuthorizationCancelledHandler.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/PixAutomaticAuthorizationExpiredHandler.java`
- Create: `src/test/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/PixAutomaticAuthorizationCancelledHandlerTest.java`
- Create: `src/test/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/PixAutomaticAuthorizationExpiredHandlerTest.java`

**Interfaces:**
- Consumes: `SupplierSubscriptionRepository.findByExternalAuthorizationId` (Task 1),
  `SupplierRegistrationService.regenerateAuthorization` (Task 4), `AsaasDTO.WebhookCheckoutEvent.authorization()` (Task 3).
- Produces: dois novos `AsaasWebhookStrategy` beans, auto-registrados no `AsaasWebhookService`
  (injeção via `List<AsaasWebhookStrategy>`, sem mudança de fiação necessária).

- [ ] **Step 1: Write the failing test — `PixAutomaticAuthorizationCancelledHandlerTest.java`**

```java
package com.brainbyte.easy_maintenance.webhooks.asaas.strategy.impl;

import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.supplier_billing.application.service.SupplierRegistrationService;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierSubscriptionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PixAutomaticAuthorizationCancelledHandlerTest {

    @Mock SupplierSubscriptionRepository subscriptionRepository;
    @Mock SupplierRegistrationService registrationService;
    @InjectMocks PixAutomaticAuthorizationCancelledHandler handler;

    @Test
    void shouldReturnCorrectEventType() {
        assertThat(handler.getEventType()).isEqualTo("PIX_AUTOMATIC_RECURRING_AUTHORIZATION_CANCELLED");
    }

    @Test
    void handle_activeSubscription_marksPastDueAndRegeneratesAuthorization() {
        var subscription = SupplierSubscription.builder().id(1L).supplierId(100L)
                .status(SupplierSubscriptionStatus.ACTIVE).externalAuthorizationId("auth_123").build();
        when(subscriptionRepository.findByExternalAuthorizationId("auth_123")).thenReturn(Optional.of(subscription));
        when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        var authorization = new AsaasDTO.PixAutomaticAuthorizationObject("auth_123", "CANCELLED");
        var event = new AsaasDTO.WebhookCheckoutEvent(
                "evt-1", "PIX_AUTOMATIC_RECURRING_AUTHORIZATION_CANCELLED", "2026-09-20T10:00:00",
                null, null, null, null, authorization);

        handler.handle(event);

        verify(subscriptionRepository).save(argThat(s ->
                s.getStatus() == SupplierSubscriptionStatus.PAST_DUE && "CANCELLED".equals(s.getAuthorizationStatus())));
        verify(registrationService).regenerateAuthorization(100L);
    }

    @Test
    void handle_alreadyPastDue_isIdempotent_doesNotRegenerateTwice() {
        var subscription = SupplierSubscription.builder().id(1L).supplierId(100L)
                .status(SupplierSubscriptionStatus.PAST_DUE).externalAuthorizationId("auth_123").build();
        when(subscriptionRepository.findByExternalAuthorizationId("auth_123")).thenReturn(Optional.of(subscription));
        var authorization = new AsaasDTO.PixAutomaticAuthorizationObject("auth_123", "CANCELLED");
        var event = new AsaasDTO.WebhookCheckoutEvent(
                "evt-1", "PIX_AUTOMATIC_RECURRING_AUTHORIZATION_CANCELLED", "2026-09-20T10:00:00",
                null, null, null, null, authorization);

        handler.handle(event);

        verify(subscriptionRepository, never()).save(any());
        verifyNoInteractions(registrationService);
    }

    @Test
    void handle_noMatchingSubscription_logsAndReturns() {
        when(subscriptionRepository.findByExternalAuthorizationId("auth_unknown")).thenReturn(Optional.empty());
        var authorization = new AsaasDTO.PixAutomaticAuthorizationObject("auth_unknown", "CANCELLED");
        var event = new AsaasDTO.WebhookCheckoutEvent(
                "evt-1", "PIX_AUTOMATIC_RECURRING_AUTHORIZATION_CANCELLED", "2026-09-20T10:00:00",
                null, null, null, null, authorization);

        handler.handle(event);

        verify(subscriptionRepository, never()).save(any());
        verifyNoInteractions(registrationService);
    }

    @Test
    void handle_nullAuthorization_logsAndReturns() {
        var event = new AsaasDTO.WebhookCheckoutEvent(
                "evt-1", "PIX_AUTOMATIC_RECURRING_AUTHORIZATION_CANCELLED", "2026-09-20T10:00:00",
                null, null, null, null, null);

        handler.handle(event);

        verifyNoInteractions(subscriptionRepository, registrationService);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn test -Dtest=PixAutomaticAuthorizationCancelledHandlerTest`
Expected: FAIL — a classe `PixAutomaticAuthorizationCancelledHandler` ainda não existe.

- [ ] **Step 3: Implementar `PixAutomaticAuthorizationCancelledHandler.java`**

```java
package com.brainbyte.easy_maintenance.webhooks.asaas.strategy.impl;

import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.supplier_billing.application.service.SupplierRegistrationService;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierSubscriptionRepository;
import com.brainbyte.easy_maintenance.webhooks.asaas.strategy.AsaasWebhookStrategy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

// TASK-278: mandato Pix Automatico cancelado (pelo Asaas ou, presumivelmente, pelo pagador direto
// no banco dele -- a doc nao especifica um evento distinto pra esse segundo caso, ver risco
// registrado no spec 2026-09-20). O mandato cancelado nao pode ser "reativado": marca a
// SupplierSubscription como PAST_DUE e dispara a geracao de uma autorizacao nova pro fornecedor
// reautorizar. Handler leve, sem estender AbstractAsaasWebhookStrategy de proposito -- mesmo
// principio de isolamento do dominio supplier_billing ja usado no resto do modulo.
@Slf4j
@Component
@RequiredArgsConstructor
public class PixAutomaticAuthorizationCancelledHandler implements AsaasWebhookStrategy {

    private final SupplierSubscriptionRepository subscriptionRepository;
    private final SupplierRegistrationService registrationService;

    @Override
    public String getEventType() {
        return "PIX_AUTOMATIC_RECURRING_AUTHORIZATION_CANCELLED";
    }

    @Override
    public void handle(AsaasDTO.WebhookCheckoutEvent event) {
        var authorization = event.authorization();
        if (authorization == null) {
            log.warn("[AsaasWebhook] {} sem objeto authorization -- ignorado.", getEventType());
            return;
        }

        SupplierSubscription subscription = subscriptionRepository
                .findByExternalAuthorizationId(authorization.id()).orElse(null);
        if (subscription == null) {
            log.warn("[AsaasWebhook] {} authorizationId={} sem SupplierSubscription correspondente -- ignorado.",
                    getEventType(), authorization.id());
            return;
        }
        if (subscription.getStatus() == SupplierSubscriptionStatus.PAST_DUE) {
            log.info("[AsaasWebhook] SupplierSubscription {} já PAST_DUE, ignorando (idempotente).", subscription.getId());
            return;
        }

        subscription.setStatus(SupplierSubscriptionStatus.PAST_DUE);
        subscription.setAuthorizationStatus(authorization.status());
        subscriptionRepository.save(subscription);

        registrationService.regenerateAuthorization(subscription.getSupplierId());

        log.info("[AsaasWebhook] Mandato Pix Automático cancelado pro supplierId={} -- nova autorização gerada, assinatura em PAST_DUE.",
                subscription.getSupplierId());
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn test -Dtest=PixAutomaticAuthorizationCancelledHandlerTest`
Expected: PASS (4 testes).

- [ ] **Step 5: Repetir Steps 1-4 pro `EXPIRED`**

Criar `PixAutomaticAuthorizationExpiredHandlerTest.java` — mesmo conteúdo do teste do Step 1, com
`s/CANCELLED/EXPIRED/g` e `s/PixAutomaticAuthorizationCancelledHandler/PixAutomaticAuthorizationExpiredHandler/g`
em todo o arquivo (classe de teste, imports, nome do handler injetado, `getEventType()` esperado e
o `status`/`event` usados na construção do `WebhookCheckoutEvent`/`PixAutomaticAuthorizationObject`).

Criar `PixAutomaticAuthorizationExpiredHandler.java` — mesmo conteúdo de
`PixAutomaticAuthorizationCancelledHandler.java`, trocando:
- Nome da classe pra `PixAutomaticAuthorizationExpiredHandler`
- `getEventType()` retorna `"PIX_AUTOMATIC_RECURRING_AUTHORIZATION_EXPIRED"`
- Comentário de topo: `// TASK-278: mandato Pix Automatico expirado (finishDate atingido, se a autorizacao tinha prazo definido).`

Run: `mvn test -Dtest=PixAutomaticAuthorizationExpiredHandlerTest`
Expected: PASS (4 testes).

- [ ] **Step 6: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/PixAutomaticAuthorizationCancelledHandler.java \
        src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/PixAutomaticAuthorizationExpiredHandler.java \
        src/test/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/PixAutomaticAuthorizationCancelledHandlerTest.java \
        src/test/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/PixAutomaticAuthorizationExpiredHandlerTest.java
git commit -m "feat(supplier-billing): TASK-278 - webhooks de mandato cancelado/expirado"
```

- [ ] **Step 7: Rodar a suíte completa (checkpoint de integração dos Tasks 1-8)**

Run: `mvn test`
Expected: PASS, sem nenhuma regressão em nenhum módulo (backend inteiro).

---

### Task 9: Frontend — QR Code em vez de link de pagamento

**Repo:** `easy-maintenance-web`

**Files:**
- Modify: `src/app/fornecedores/cadastro/_lib/publicSupplierApi.ts`
- Modify: `src/app/fornecedores/cadastro/page.tsx`
- Modify: `src/app/fornecedores/gerenciar/[token]/page.tsx`

**Interfaces:**
- Consumes: `SelfRegisterSupplierResponse`/`SupplierManageResponse` do backend (Tasks 4/7) —
  `qrCodePayload: string | null`, `qrCodeImage: string | null` no lugar de `paymentLink`.

Sem suíte de teste automatizado pra componente React nesse módulo (mesmo padrão já usado nos
arquivos existentes — validado por `npm run build`/`eslint`, sem Jest pra essas páginas). Passos
diretos:

- [ ] **Step 1: Atualizar os tipos em `publicSupplierApi.ts`**

Substituir:

```ts
export interface SelfRegisterResponse {
  supplierId: number;
  paymentLink: string | null;
  manageToken: string;
}
```

por:

```ts
export interface SelfRegisterResponse {
  supplierId: number;
  qrCodePayload: string | null;
  qrCodeImage: string | null;
  manageToken: string;
}
```

Substituir:

```ts
export interface SupplierManageResponse {
  supplierId: number;
  document: string | null;
  name: string;
  email: string | null;
  phone: string | null;
  categories: SupplierServiceTag[];
  services: SupplierServiceTag[];
  city: string | null;
  state: string | null;
  marketplaceEnabled: boolean;
  subscriptionStatus: string;
  paymentLink: string | null;
}
```

por:

```ts
export interface SupplierManageResponse {
  supplierId: number;
  document: string | null;
  name: string;
  email: string | null;
  phone: string | null;
  categories: SupplierServiceTag[];
  services: SupplierServiceTag[];
  city: string | null;
  state: string | null;
  marketplaceEnabled: boolean;
  subscriptionStatus: string;
  qrCodePayload: string | null;
  qrCodeImage: string | null;
}
```

- [ ] **Step 2: Atualizar a tela de sucesso do cadastro (`cadastro/page.tsx`)**

Substituir:

```tsx
            <div className="text-center mb-3">
              <CheckCircle2 size={40} className="text-success mb-2" />
              <h5 className="fw-bold mb-1">Cadastro recebido!</h5>
              <p className="text-muted mb-0" style={{ fontSize: "0.9rem" }}>
                {result.paymentLink
                  ? "Falta só confirmar o pagamento pra ativar seu cadastro no marketplace."
                  : "Sua assinatura já está ativa."}
              </p>
            </div>

            {result.paymentLink && (
              <a href={result.paymentLink} target="_blank" rel="noopener noreferrer" className="btn btn-primary w-100 mb-3">
                Pagar assinatura (R$ 15,99/mês)
              </a>
            )}
```

por:

```tsx
            <div className="text-center mb-3">
              <CheckCircle2 size={40} className="text-success mb-2" />
              <h5 className="fw-bold mb-1">Cadastro recebido!</h5>
              <p className="text-muted mb-0" style={{ fontSize: "0.9rem" }}>
                {result.qrCodePayload
                  ? "Escaneie o QR Code ou copie o código Pix pra autorizar o débito automático mensal."
                  : "Sua assinatura já está ativa."}
              </p>
            </div>

            {result.qrCodePayload && (
              <div className="text-center mb-3">
                {result.qrCodeImage && (
                  <img
                    src={`data:image/png;base64,${result.qrCodeImage}`}
                    alt="QR Code Pix Automático"
                    style={{ width: 200, height: 200, margin: "0 auto" }}
                  />
                )}
                <button
                  type="button"
                  className="btn btn-outline-primary w-100 mt-2"
                  onClick={() => {
                    navigator.clipboard.writeText(result.qrCodePayload!);
                    toast.success("Código Pix copiado!");
                  }}
                >
                  Copiar código Pix (R$ 15,99/mês)
                </button>
              </div>
            )}
```

- [ ] **Step 3: Atualizar a tela de gestão (`gerenciar/[token]/page.tsx`)**

Substituir:

```tsx
            {data.paymentLink && (
              <div className="p-3 mb-3" style={{ backgroundColor: "#fff7ed", borderRadius: 10, border: "1px solid #fed7aa" }}>
                <div className="fw-semibold small mb-1" style={{ color: "#c2410c" }}>Pagamento pendente</div>
                <p className="text-muted mb-2" style={{ fontSize: "0.8rem" }}>
                  Seu cadastro fica visível pras organizações assim que o pagamento for confirmado.
                </p>
                <a href={data.paymentLink} target="_blank" rel="noopener noreferrer" className="btn btn-sm btn-primary">
                  Pagar assinatura (R$ 15,99/mês)
                </a>
              </div>
            )}
```

por:

```tsx
            {data.qrCodePayload && (
              <div className="p-3 mb-3" style={{ backgroundColor: "#fff7ed", borderRadius: 10, border: "1px solid #fed7aa" }}>
                <div className="fw-semibold small mb-1" style={{ color: "#c2410c" }}>Autorização pendente</div>
                <p className="text-muted mb-2" style={{ fontSize: "0.8rem" }}>
                  Escaneie o QR Code ou copie o código Pix pra autorizar o débito automático mensal.
                  Seu cadastro fica visível pras organizações assim que a autorização for confirmada.
                </p>
                {data.qrCodeImage && (
                  <img
                    src={`data:image/png;base64,${data.qrCodeImage}`}
                    alt="QR Code Pix Automático"
                    style={{ width: 160, height: 160, display: "block", margin: "0 auto 8px" }}
                  />
                )}
                <button
                  type="button"
                  className="btn btn-sm btn-primary w-100"
                  onClick={() => {
                    navigator.clipboard.writeText(data.qrCodePayload!);
                    toast.success("Código Pix copiado!");
                  }}
                >
                  Copiar código Pix (R$ 15,99/mês)
                </button>
              </div>
            )}
```

- [ ] **Step 4: Rodar build e lint**

Run: `npm run build`
Expected: Build limpo, sem erro de tipo.

Run: `npx eslint src/app/fornecedores/`
Expected: Sem erros novos (warnings pré-existentes de `<img>` são esperados, mesmo padrão já
aceito nas páginas existentes).

- [ ] **Step 5: Commit**

```bash
git add src/app/fornecedores/cadastro/_lib/publicSupplierApi.ts \
        src/app/fornecedores/cadastro/page.tsx \
        "src/app/fornecedores/gerenciar/[token]/page.tsx"
git commit -m "feat(fornecedores): TASK-278 - QR Code Pix Automatico em vez de link de pagamento"
```

---

## Fora de escopo deste plano (ver spec)

- Migração de fornecedores já em PIX manual (não existem em PRD).
- Modo `SUBSCRIPTION` da Asaas.
- Pix Automático pro billing de organização (TASK-066, continua adiado).
- Confirmação real, em sandbox, do evento de revogação feita direto no banco do pagador (tratado
  como `CANCELLED` — validar durante QA manual em staging, não faz parte deste plano de código).
- Ajuste fino da janela "2-10 dias úteis antes do vencimento" pra criação da instrução de cobrança
  recorrente — `PIX_DUE_DAYS = 3` (dias corridos) mantido como está; revisar depois de observar o
  comportamento real em sandbox.
