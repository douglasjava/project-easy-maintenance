# Emissão de NFS-e para Assinaturas (Asaas Nativo) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Emitir NFS-e automaticamente para cada cobrança paga de assinatura de organização (STARTER/BUSINESS/ENTERPRISE), usando a emissão nativa do Asaas (nosso provedor de pagamento atual), sem depender de um provedor fiscal terceiro.

**Architecture:** Na ativação de uma `BillingSubscription` (quando `SubscriptionCreatedHandler` recebe `SUBSCRIPTION_CREATED` e chama `activate()`), configuramos a emissão automática de NF uma única vez via `POST` na Asaas (`effectiveDatePeriod=ON_PAYMENT_CONFIRMATION`). A partir daí a Asaas emite a NFS-e sozinha a cada cobrança paga e nos avisa via webhook (`INVOICE_AUTHORIZED`/`INVOICE_ERROR`) em um endpoint novo e dedicado. Um job diário de reconciliação cobre falhas transitórias na configuração e sinaliza notas travadas para revisão manual.

**Tech Stack:** Spring Boot, JPA/Hibernate (MySQL), Flyway, WebClient (via `AsaasClient`), Resilience4j `@CircuitBreaker`, Shedlock (`@SchedulerLock`), JUnit 5 + Mockito + AssertJ.

**Spec:** `docs/superpowers/specs/2026-10-13-fiscal-invoice-nfse-design.md`

## Global Constraints

- Escopo é só assinatura de organização (STARTER/BUSINESS/ENTERPRISE) — módulo de fornecedores fica de fora.
- `effectiveDatePeriod` da configuração de NF é sempre `ON_PAYMENT_CONFIRMATION`.
- A entidade local do lado fiscal se chama `FiscalInvoice` (nunca `Invoice`, que já existe e significa cobrança).
- Falha ao configurar NF numa assinatura **nunca** pode bloquear ou revogar a ativação da assinatura em si.
- Nenhuma chamada real à API de produção da Asaas antes do certificado digital A1 (novo CNPJ) estar pronto — todo o trabalho deste plano é implementação/teste contra sandbox; ativação em produção é decisão manual posterior, fora deste plano.

## Review Focus

- Webhook `INVOICE_AUTHORIZED`/`INVOICE_ERROR` chegando para uma nota cujo `FiscalInvoice` local ainda não existe — deve criar o registro em vez de descartar o evento.
- `invoice.payment()` do webhook sem `Payment` local correspondente (correlação não resolvida) — deve salvar o `FiscalInvoice` com `payment=null` em vez de lançar exceção e perder o evento.
- Falha ao chamar `createInvoiceConfiguration` durante `SubscriptionCreatedHandler.handle()` — não pode impedir `billingSubscriptionRepository.save(subscription)` nem propagar exceção para o webhook de assinatura.
- Entrega duplicada do mesmo webhook de NF (mesmo `event.id()`) — não pode criar dois `FiscalInvoice` para a mesma nota.
- Job de reconciliação encontrando uma `BillingSubscription` ACTIVE sem `externalSubscriptionId` (ex.: PIX manual sem assinatura Asaas) — deve pular, não tentar configurar NF sem id de assinatura Asaas.

---

## Task 1: `FiscalInvoice` — entidade, enum, migration e repositório

**Files:**
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/domain/enums/FiscalInvoiceStatus.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/domain/FiscalInvoice.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/infrastructure/persistence/FiscalInvoiceRepository.java`
- Modify: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/domain/BillingSubscription.java`
- Create: `easy-maintenance-api/src/main/resources/db/migration/V124__create_fiscal_invoices.sql`
- Test: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/billing/infrastructure/persistence/FiscalInvoicePersistenceTest.java`

**Interfaces:**
- Produces: `FiscalInvoiceStatus` (enum: `PENDING, AUTHORIZED, ERROR, CANCELED`); `FiscalInvoice` entity with fields `id, payment (Payment, nullable), billingSubscription (BillingSubscription), externalFiscalInvoiceId (String), status (FiscalInvoiceStatus), pdfUrl (String), xmlUrl (String), errorMessage (String), authorizedAt (Instant), createdAt, updatedAt`; `FiscalInvoiceRepository.findByExternalFiscalInvoiceId(String)` → `Optional<FiscalInvoice>`; `FiscalInvoiceRepository.findByStatusInAndCreatedAtBefore(List<FiscalInvoiceStatus>, Instant)` → `List<FiscalInvoice>`; `BillingSubscription.isFiscalInvoiceConfigured()` / `BillingSubscription.setFiscalInvoiceConfigured(boolean)`.

- [ ] **Step 1: Write the failing persistence test**

```java
package com.brainbyte.easy_maintenance.billing.infrastructure.persistence;

import com.brainbyte.easy_maintenance.billing.domain.BillingAccount;
import com.brainbyte.easy_maintenance.billing.domain.BillingSubscription;
import com.brainbyte.easy_maintenance.billing.domain.FiscalInvoice;
import com.brainbyte.easy_maintenance.billing.domain.enums.BillingCycle;
import com.brainbyte.easy_maintenance.billing.domain.enums.FiscalInvoiceStatus;
import com.brainbyte.easy_maintenance.billing.domain.enums.SubscriptionStatus;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.test.context.TestPropertySource;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@EntityScan(basePackageClasses = FiscalInvoice.class)
@EnableJpaRepositories(basePackageClasses = FiscalInvoiceRepository.class)
@TestPropertySource(properties = {
        "spring.flyway.enabled=false",
        "spring.jpa.hibernate.ddl-auto=create-drop"
})
class FiscalInvoicePersistenceTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private FiscalInvoiceRepository repository;

    private BillingSubscription persistSubscription() {
        BillingAccount account = BillingAccount.builder().build();
        entityManager.persist(account);
        BillingSubscription sub = BillingSubscription.builder()
                .billingAccount(account)
                .status(SubscriptionStatus.ACTIVE)
                .cycle(BillingCycle.MONTHLY)
                .externalSubscriptionId("ext-sub-001")
                .fiscalInvoiceConfigured(false)
                .build();
        entityManager.persist(sub);
        return sub;
    }

    @Test
    void save_and_findByExternalFiscalInvoiceId_roundTrips() {
        BillingSubscription sub = persistSubscription();
        FiscalInvoice invoice = FiscalInvoice.builder()
                .billingSubscription(sub)
                .externalFiscalInvoiceId("inv_abc123")
                .status(FiscalInvoiceStatus.PENDING)
                .build();
        repository.save(invoice);
        entityManager.flush();
        entityManager.clear();

        var found = repository.findByExternalFiscalInvoiceId("inv_abc123");

        assertThat(found).isPresent();
        assertThat(found.get().getStatus()).isEqualTo(FiscalInvoiceStatus.PENDING);
        assertThat(found.get().getBillingSubscription().getId()).isEqualTo(sub.getId());
    }

    @Test
    void findByStatusInAndCreatedAtBefore_returnsOnlyMatching() {
        BillingSubscription sub = persistSubscription();
        FiscalInvoice old = FiscalInvoice.builder()
                .billingSubscription(sub)
                .externalFiscalInvoiceId("inv_old")
                .status(FiscalInvoiceStatus.ERROR)
                .build();
        repository.save(old);
        entityManager.flush();

        // createdAt é setado por @CreationTimestamp no flush — usamos um limite 1h no futuro
        // pra garantir que o registro recém-criado seja encontrado.
        Instant cutoff = Instant.now().plus(1, ChronoUnit.HOURS);

        List<FiscalInvoice> result = repository.findByStatusInAndCreatedAtBefore(
                List.of(FiscalInvoiceStatus.ERROR, FiscalInvoiceStatus.PENDING), cutoff);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getExternalFiscalInvoiceId()).isEqualTo("inv_old");
    }

    @Test
    void save_withoutBillingSubscription_isAllowed() {
        // Um webhook de NF pode chegar antes de resolvermos o Payment/BillingSubscription
        // correspondente (ver Task 4) — billingSubscription precisa aceitar null.
        FiscalInvoice invoice = FiscalInvoice.builder()
                .externalFiscalInvoiceId("inv_unresolved")
                .status(FiscalInvoiceStatus.AUTHORIZED)
                .build();

        repository.save(invoice);
        entityManager.flush();
        entityManager.clear();

        var found = repository.findByExternalFiscalInvoiceId("inv_unresolved");
        assertThat(found).isPresent();
        assertThat(found.get().getBillingSubscription()).isNull();
    }
}
```

- [ ] **Step 2: Run test to verify it fails (compile error — types don't exist yet)**

Run: `cd easy-maintenance-api && mvn test -Dtest=FiscalInvoicePersistenceTest`
Expected: FAIL — compilation error, `FiscalInvoice`/`FiscalInvoiceRepository`/`FiscalInvoiceStatus` don't exist.

- [ ] **Step 3: Create `FiscalInvoiceStatus`**

```java
package com.brainbyte.easy_maintenance.billing.domain.enums;

public enum FiscalInvoiceStatus {
    PENDING, AUTHORIZED, ERROR, CANCELED
}
```

- [ ] **Step 4: Create `FiscalInvoice` entity**

```java
package com.brainbyte.easy_maintenance.billing.domain;

import com.brainbyte.easy_maintenance.billing.domain.enums.FiscalInvoiceStatus;
import com.brainbyte.easy_maintenance.payment.domain.Payment;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "fiscal_invoices")
public class FiscalInvoice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payment_id")
    private Payment payment;

    // Nullable de propósito: um webhook de NF pode chegar antes de conseguirmos resolver o
    // Payment/BillingSubscription correspondente (ver Task 4, correlação por externalPaymentId).
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "billing_subscription_id")
    private BillingSubscription billingSubscription;

    @Column(name = "external_fiscal_invoice_id", length = 120, unique = true)
    private String externalFiscalInvoiceId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private FiscalInvoiceStatus status = FiscalInvoiceStatus.PENDING;

    @Column(name = "pdf_url", length = 500)
    private String pdfUrl;

    @Column(name = "xml_url", length = 500)
    private String xmlUrl;

    @Column(name = "error_message", length = 500)
    private String errorMessage;

    @Column(name = "authorized_at")
    private Instant authorizedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
```

- [ ] **Step 5: Create `FiscalInvoiceRepository`**

```java
package com.brainbyte.easy_maintenance.billing.infrastructure.persistence;

import com.brainbyte.easy_maintenance.billing.domain.FiscalInvoice;
import com.brainbyte.easy_maintenance.billing.domain.enums.FiscalInvoiceStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface FiscalInvoiceRepository extends JpaRepository<FiscalInvoice, Long> {

    Optional<FiscalInvoice> findByExternalFiscalInvoiceId(String externalFiscalInvoiceId);

    List<FiscalInvoice> findByStatusInAndCreatedAtBefore(List<FiscalInvoiceStatus> statuses, Instant createdBefore);
}
```

- [ ] **Step 6: Add `fiscalInvoiceConfigured` to `BillingSubscription`**

In `BillingSubscription.java`, add alongside the other `@Column` fields (after `cancelAtPeriodEnd`):

```java
    @Column(name = "fiscal_invoice_configured", nullable = false)
    @Builder.Default
    private boolean fiscalInvoiceConfigured = false;
```

- [ ] **Step 7: Create the Flyway migration**

```sql
-- Emissão de NFS-e via Asaas nativo (configuração por assinatura, não por pagamento). Ver
-- docs/superpowers/specs/2026-10-13-fiscal-invoice-nfse-design.md.
ALTER TABLE billing_subscriptions
    ADD COLUMN fiscal_invoice_configured BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE fiscal_invoices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_id BIGINT NULL,
    -- Nullable de propósito: um webhook de NF pode chegar antes de resolvermos o
    -- Payment/BillingSubscription correspondente (ver Task 4).
    billing_subscription_id BIGINT NULL,
    external_fiscal_invoice_id VARCHAR(120) UNIQUE,
    status VARCHAR(20) NOT NULL,
    pdf_url VARCHAR(500),
    xml_url VARCHAR(500),
    error_message VARCHAR(500),
    authorized_at DATETIME(6),
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT fk_fiscal_invoices_payment FOREIGN KEY (payment_id) REFERENCES payments(id),
    CONSTRAINT fk_fiscal_invoices_billing_subscription FOREIGN KEY (billing_subscription_id) REFERENCES billing_subscriptions(id)
);

CREATE INDEX idx_fiscal_invoices_billing_subscription ON fiscal_invoices (billing_subscription_id);
CREATE INDEX idx_fiscal_invoices_status_created_at ON fiscal_invoices (status, created_at);
```

- [ ] **Step 8: Run test to verify it passes**

Run: `cd easy-maintenance-api && mvn test -Dtest=FiscalInvoicePersistenceTest`
Expected: PASS (3 tests).

- [ ] **Step 9: Commit**

```bash
git add easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/domain/enums/FiscalInvoiceStatus.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/domain/FiscalInvoice.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/infrastructure/persistence/FiscalInvoiceRepository.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/domain/BillingSubscription.java \
        easy-maintenance-api/src/main/resources/db/migration/V124__create_fiscal_invoices.sql \
        easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/billing/infrastructure/persistence/FiscalInvoicePersistenceTest.java
git commit -m "feat(billing): add FiscalInvoice entity and fiscal_invoice_configured flag"
```

---

## Task 2: Configuração de NF na Asaas — DTOs, `AsaasClient` e `FiscalInvoiceConfigurationService`

**Files:**
- Modify: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/application/dto/AsaasDTO.java`
- Modify: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/client/AsaasClient.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/properties/AsaasFiscalInvoiceProperties.java`
- Modify: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/EasyMaintenanceApplication.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/application/service/FiscalInvoiceConfigurationService.java`
- Modify: `easy-maintenance-api/src/main/resources/application-local.properties`
- Modify: `easy-maintenance-api/src/main/resources/application.properties`
- Test: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/billing/application/service/FiscalInvoiceConfigurationServiceTest.java`

**Interfaces:**
- Consumes: `FiscalInvoiceRepository` (Task 1, not used here directly but same package), `BillingSubscription.setFiscalInvoiceConfigured(boolean)` (Task 1), `BillingSubscriptionRepository` (existing, `save(BillingSubscription)`).
- Produces: `AsaasClient.createInvoiceConfiguration(String subscriptionId, AsaasDTO.CreateFiscalInvoiceConfigurationRequest req)` → `AsaasDTO.FiscalInvoiceConfigurationResponse`; `FiscalInvoiceConfigurationService.configureForSubscription(BillingSubscription subscription)` → `void` (never throws; logs and returns on failure).

- [ ] **Step 1: Write the failing test for `FiscalInvoiceConfigurationService`**

```java
package com.brainbyte.easy_maintenance.billing.application.service;

import com.brainbyte.easy_maintenance.billing.domain.BillingSubscription;
import com.brainbyte.easy_maintenance.billing.domain.enums.BillingCycle;
import com.brainbyte.easy_maintenance.billing.domain.enums.SubscriptionStatus;
import com.brainbyte.easy_maintenance.billing.infrastructure.persistence.BillingSubscriptionRepository;
import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.infrastructure.saas.client.AsaasClient;
import com.brainbyte.easy_maintenance.infrastructure.saas.properties.AsaasFiscalInvoiceProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FiscalInvoiceConfigurationServiceTest {

    @Mock private AsaasClient asaasClient;
    @Mock private BillingSubscriptionRepository billingSubscriptionRepository;
    private AsaasFiscalInvoiceProperties properties;

    private FiscalInvoiceConfigurationService service;

    @BeforeEach
    void setUp() {
        properties = new AsaasFiscalInvoiceProperties(
                new BigDecimal("5.00"), new BigDecimal("0.65"), new BigDecimal("3.00"),
                new BigDecimal("1.00"), BigDecimal.ZERO, BigDecimal.ZERO,
                true, "0107"
        );
        service = new FiscalInvoiceConfigurationService(asaasClient, billingSubscriptionRepository, properties);
    }

    private BillingSubscription subscription() {
        return BillingSubscription.builder()
                .id(1L)
                .status(SubscriptionStatus.ACTIVE)
                .cycle(BillingCycle.MONTHLY)
                .externalSubscriptionId("sub_ext_123")
                .fiscalInvoiceConfigured(false)
                .build();
    }

    @Test
    void configureForSubscription_success_setsFlagAndSavesSubscription() {
        BillingSubscription sub = subscription();
        when(asaasClient.createInvoiceConfiguration(eq("sub_ext_123"), any()))
                .thenReturn(new AsaasDTO.FiscalInvoiceConfigurationResponse("config_1", "sub_ext_123"));

        service.configureForSubscription(sub);

        assertThat(sub.isFiscalInvoiceConfigured()).isTrue();
        verify(billingSubscriptionRepository).save(sub);
    }

    @Test
    void configureForSubscription_buildsRequestWithConfiguredRatesAndPeriod() {
        BillingSubscription sub = subscription();
        ArgumentCaptor<AsaasDTO.CreateFiscalInvoiceConfigurationRequest> captor =
                ArgumentCaptor.forClass(AsaasDTO.CreateFiscalInvoiceConfigurationRequest.class);
        when(asaasClient.createInvoiceConfiguration(eq("sub_ext_123"), captor.capture()))
                .thenReturn(new AsaasDTO.FiscalInvoiceConfigurationResponse("config_1", "sub_ext_123"));

        service.configureForSubscription(sub);

        var req = captor.getValue();
        assertThat(req.effectiveDatePeriod()).isEqualTo("ON_PAYMENT_CONFIRMATION");
        assertThat(req.municipalServiceCode()).isEqualTo("0107");
        assertThat(req.taxes().iss()).isEqualTo(new BigDecimal("5.00"));
        assertThat(req.taxes().retainIss()).isTrue();
    }

    @Test
    void configureForSubscription_missingExternalSubscriptionId_doesNothing() {
        BillingSubscription sub = subscription();
        sub.setExternalSubscriptionId(null);

        service.configureForSubscription(sub);

        verify(asaasClient, never()).createInvoiceConfiguration(any(), any());
        verify(billingSubscriptionRepository, never()).save(any());
    }

    @Test
    void configureForSubscription_asaasCallFails_doesNotThrowAndFlagStaysFalse() {
        BillingSubscription sub = subscription();
        when(asaasClient.createInvoiceConfiguration(eq("sub_ext_123"), any()))
                .thenThrow(new RuntimeException("Asaas 500"));

        service.configureForSubscription(sub);

        assertThat(sub.isFiscalInvoiceConfigured()).isFalse();
        verify(billingSubscriptionRepository, never()).save(any());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd easy-maintenance-api && mvn test -Dtest=FiscalInvoiceConfigurationServiceTest`
Expected: FAIL — compilation error, types don't exist yet.

- [ ] **Step 3: Add DTOs to `AsaasDTO`**

Add inside `AsaasDTO` (same style as the other nested records, near `CreateSubscriptionRequest`):

```java
    public record FiscalInvoiceTaxes(
            Boolean retainIss,
            BigDecimal iss,
            BigDecimal pis,
            BigDecimal cofins,
            BigDecimal csll,
            BigDecimal inss,
            BigDecimal ir
    ) {}

    public record CreateFiscalInvoiceConfigurationRequest(
            FiscalInvoiceTaxes taxes,
            String municipalServiceCode,
            String effectiveDatePeriod,
            String observations
    ) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record FiscalInvoiceConfigurationResponse(
            String id,
            String subscription
    ) {}
```

(`BigDecimal` and `@JsonIgnoreProperties` are already imported in this file — no new imports needed.)

- [ ] **Step 4: Add `createInvoiceConfiguration` to `AsaasClient`**

Add alongside the other subscription methods:

```java
    @CircuitBreaker(name = "asaas")
    public AsaasDTO.FiscalInvoiceConfigurationResponse createInvoiceConfiguration(
            String subscriptionId, AsaasDTO.CreateFiscalInvoiceConfigurationRequest req) {
        return webClient.post()
                .uri("/subscriptions/{id}/invoiceConfig", subscriptionId)
                .bodyValue(req)
                .retrieve()
                .onStatus(HttpStatusCode::isError, this::mapError)
                .bodyToMono(AsaasDTO.FiscalInvoiceConfigurationResponse.class)
                .timeout(ASAAS_TIMEOUT)
                .block();
    }
```

- [ ] **Step 5: Create `AsaasFiscalInvoiceProperties`**

```java
package com.brainbyte.easy_maintenance.infrastructure.saas.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.math.BigDecimal;

@ConfigurationProperties(prefix = "asaas.fiscal-invoice")
public record AsaasFiscalInvoiceProperties(
        BigDecimal iss,
        BigDecimal pis,
        BigDecimal cofins,
        BigDecimal csll,
        BigDecimal inss,
        BigDecimal ir,
        boolean retainIss,
        String municipalServiceCode
) {}
```

`AsaasProperties` is registered in `EasyMaintenanceApplication.java` via `@EnableConfigurationProperties({DashboardProperties.class, AsaasProperties.class})`. Add `AsaasFiscalInvoiceProperties.class` to that same annotation:

```java
@EnableConfigurationProperties({DashboardProperties.class, AsaasProperties.class, AsaasFiscalInvoiceProperties.class})
```

(add the import `com.brainbyte.easy_maintenance.infrastructure.saas.properties.AsaasFiscalInvoiceProperties` alongside the existing one for `AsaasProperties`.)

- [ ] **Step 6: Create `FiscalInvoiceConfigurationService`**

```java
package com.brainbyte.easy_maintenance.billing.application.service;

import com.brainbyte.easy_maintenance.billing.domain.BillingSubscription;
import com.brainbyte.easy_maintenance.billing.infrastructure.persistence.BillingSubscriptionRepository;
import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.infrastructure.saas.client.AsaasClient;
import com.brainbyte.easy_maintenance.infrastructure.saas.properties.AsaasFiscalInvoiceProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class FiscalInvoiceConfigurationService {

    private final AsaasClient asaasClient;
    private final BillingSubscriptionRepository billingSubscriptionRepository;
    private final AsaasFiscalInvoiceProperties fiscalInvoiceProperties;

    /**
     * Configura a emissão automática de NFS-e para a assinatura na Asaas. Nunca lança — uma falha
     * aqui não pode bloquear a ativação da assinatura (ver spec, seção "Tratamento de erro"). O job
     * de reconciliação (Task 5) tenta de novo mais tarde se isFiscalInvoiceConfigured() continuar
     * false.
     */
    public void configureForSubscription(BillingSubscription subscription) {
        if (subscription.getExternalSubscriptionId() == null) {
            log.warn("[FiscalInvoice] BillingSubscription {} sem externalSubscriptionId — não é possível configurar NF ainda.",
                    subscription.getId());
            return;
        }

        var req = new AsaasDTO.CreateFiscalInvoiceConfigurationRequest(
                new AsaasDTO.FiscalInvoiceTaxes(
                        fiscalInvoiceProperties.retainIss(),
                        fiscalInvoiceProperties.iss(),
                        fiscalInvoiceProperties.pis(),
                        fiscalInvoiceProperties.cofins(),
                        fiscalInvoiceProperties.csll(),
                        fiscalInvoiceProperties.inss(),
                        fiscalInvoiceProperties.ir()
                ),
                fiscalInvoiceProperties.municipalServiceCode(),
                "ON_PAYMENT_CONFIRMATION",
                "Assinatura Easy Maintenance"
        );

        try {
            asaasClient.createInvoiceConfiguration(subscription.getExternalSubscriptionId(), req);
            subscription.setFiscalInvoiceConfigured(true);
            billingSubscriptionRepository.save(subscription);
            log.info("[FiscalInvoice] Configuração de NF criada para BillingSubscription {} (externalSubscriptionId={}).",
                    subscription.getId(), subscription.getExternalSubscriptionId());
        } catch (Exception e) {
            log.error("[FiscalInvoice] Falha ao configurar NF para BillingSubscription {} (externalSubscriptionId={}): {}",
                    subscription.getId(), subscription.getExternalSubscriptionId(), e.getMessage());
        }
    }
}
```

- [ ] **Step 7: Run test to verify it passes**

Run: `cd easy-maintenance-api && mvn test -Dtest=FiscalInvoiceConfigurationServiceTest`
Expected: PASS (4 tests).

- [ ] **Step 8: Add sandbox config values to `application-local.properties`**

Add after the existing `asaas.*` lines:

```properties
asaas.fiscal-invoice.iss=5.00
asaas.fiscal-invoice.pis=0.65
asaas.fiscal-invoice.cofins=3.00
asaas.fiscal-invoice.csll=1.00
asaas.fiscal-invoice.inss=0.00
asaas.fiscal-invoice.ir=0.00
asaas.fiscal-invoice.retain-iss=true
asaas.fiscal-invoice.municipal-service-code=${ASAAS_MUNICIPAL_SERVICE_CODE:0000}
```

Add the same block to `application.properties` (defaults; real alíquotas/código municipal confirmados com o contábil antes do rollout — ver dependência externa na spec).

- [ ] **Step 9: Commit**

```bash
git add easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/application/dto/AsaasDTO.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/client/AsaasClient.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/properties/AsaasFiscalInvoiceProperties.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/EasyMaintenanceApplication.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/application/service/FiscalInvoiceConfigurationService.java \
        easy-maintenance-api/src/main/resources/application-local.properties \
        easy-maintenance-api/src/main/resources/application.properties \
        easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/billing/application/service/FiscalInvoiceConfigurationServiceTest.java
git commit -m "feat(billing): add Asaas invoice configuration client call and FiscalInvoiceConfigurationService"
```

---

## Task 3: Acionar a configuração de NF na ativação da assinatura

**Files:**
- Modify: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/SubscriptionCreatedHandler.java`
- Modify: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/SubscriptionCreatedHandlerTest.java`

**Interfaces:**
- Consumes: `FiscalInvoiceConfigurationService.configureForSubscription(BillingSubscription)` (Task 2).

- [ ] **Step 1: Update `SubscriptionCreatedHandlerTest` — add the new mock and a failing assertion**

In the existing test class, add the new mock field and inject it, then add a new test method:

```java
    @Mock private FiscalInvoiceConfigurationService fiscalInvoiceConfigurationService;
```

(add this `@Mock` field next to the existing `@Mock private AsaasClient asaasClient;` line — Mockito's `@InjectMocks` picks it up automatically once the constructor parameter exists in Step 3 below)

Add this new test method to the class:

```java
    @Test
    void handle_happyPath_configuresFiscalInvoiceAfterActivation() {
        var asaasSub = buildSubscription("ext-sub-001", "checkout-session-001", "ACTIVE", false,
                LocalDate.of(2026, 5, 30));
        var event = buildEvent("evt-001", asaasSub);

        when(paymentRepository.findByExternalPaymentId("checkout-session-001")).thenReturn(Optional.of(payment));

        handler.handle(event);

        verify(fiscalInvoiceConfigurationService).configureForSubscription(subscription);
    }
```

Also add the required import at the top of the test file:

```java
import com.brainbyte.easy_maintenance.billing.application.service.FiscalInvoiceConfigurationService;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd easy-maintenance-api && mvn test -Dtest=SubscriptionCreatedHandlerTest`
Expected: FAIL — `SubscriptionCreatedHandler` constructor doesn't accept `FiscalInvoiceConfigurationService` yet, and the new test's `verify()` has nothing to match.

- [ ] **Step 3: Wire the service into `SubscriptionCreatedHandler`**

Add the field, constructor parameter, and call at both `activate()` sites:

```java
    private final AsaasClient asaasClient;
    private final FiscalInvoiceConfigurationService fiscalInvoiceConfigurationService;

    public SubscriptionCreatedHandler(InvoiceService invoiceService, PaymentRepository paymentRepository,
                                     PaymentGatewayEventRepository paymentGatewayEventRepository,
                                     InvoiceRepository invoiceRepository, BillingAccountRepository billingAccountRepository,
                                     BillingSubscriptionRepository billingSubscriptionRepository,
                                     BillingSubscriptionItemRepository billingSubscriptionItemRepository,
                                     InvoiceItemRepository invoiceItemRepository,
                                     OrganizationRepository organizationRepository,
                                     ObjectMapper objectMapper,
                                     AsaasClient asaasClient,
                                     FiscalInvoiceConfigurationService fiscalInvoiceConfigurationService) {
        super(invoiceService, paymentRepository, paymentGatewayEventRepository, invoiceRepository, billingAccountRepository,
                billingSubscriptionRepository, billingSubscriptionItemRepository, invoiceItemRepository,
                organizationRepository, objectMapper);
        this.asaasClient = asaasClient;
        this.fiscalInvoiceConfigurationService = fiscalInvoiceConfigurationService;
    }
```

Add the import:

```java
import com.brainbyte.easy_maintenance.billing.application.service.FiscalInvoiceConfigurationService;
```

In the main `handle()` method, right after the line `billingSubscriptionRepository.save(subscription);` inside the `paymentOpt.ifPresentOrElse(...)` lambda (the one that follows `subscription.activate(asaasSub.id(), asaasSub.nextDueDate());` / `subscription.setStatus(SubscriptionStatus.ACTIVE);`), add:

```java
            fiscalInvoiceConfigurationService.configureForSubscription(subscription);
```

In `handleCardUpdate(...)`, right after its own `billingSubscriptionRepository.save(subscription);` line, add the same call:

```java
        fiscalInvoiceConfigurationService.configureForSubscription(subscription);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd easy-maintenance-api && mvn test -Dtest=SubscriptionCreatedHandlerTest`
Expected: PASS (all existing tests + the new one).

- [ ] **Step 5: Commit**

```bash
git add easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/SubscriptionCreatedHandler.java \
        easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/SubscriptionCreatedHandlerTest.java
git commit -m "feat(billing): configure Asaas fiscal invoice when a subscription activates"
```

---

## Task 4: Webhook de nota fiscal — endpoint e processamento (`INVOICE_AUTHORIZED` / `INVOICE_ERROR`)

**Files:**
- Modify: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/application/dto/AsaasDTO.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/controller/AsaasFiscalInvoiceWebhookController.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/service/AsaasFiscalInvoiceWebhookService.java`
- Test: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/webhooks/asaas/service/AsaasFiscalInvoiceWebhookServiceTest.java`

**Interfaces:**
- Consumes: `FiscalInvoiceRepository` (Task 1), `PaymentRepository.findByExternalPaymentId(String)` (existing), `WebhookEventService.findByProviderEventId(String)` / `.save(WebhookEvent)` (existing, same as `AsaasWebhookService` uses).
- Produces: `AsaasDTO.FiscalInvoiceWebhookEvent(String id, String event, FiscalInvoiceObject invoice)`; `AsaasDTO.FiscalInvoiceObject(String id, String status, String payment, String pdfUrl, String xmlUrl, String number, String validationCode, String statusDescription)`; `AsaasFiscalInvoiceWebhookService.processEvent(AsaasDTO.FiscalInvoiceWebhookEvent event)` → `void`.

This is a **separate endpoint** from the existing `AsaasWebhookController` (which handles `WebhookCheckoutEvent` — payments/subscriptions/checkout). The Asaas dashboard (Integrações → Webhooks) lets you register a distinct webhook URL for the "Notas Fiscais" event group, so this keeps the new, unrelated payload shape out of the already-16-call-site `WebhookCheckoutEvent` record instead of adding a field there.

- [ ] **Step 1: Write the failing test for `AsaasFiscalInvoiceWebhookService`**

```java
package com.brainbyte.easy_maintenance.webhooks.asaas.service;

import com.brainbyte.easy_maintenance.billing.domain.BillingSubscription;
import com.brainbyte.easy_maintenance.billing.domain.FiscalInvoice;
import com.brainbyte.easy_maintenance.billing.domain.enums.FiscalInvoiceStatus;
import com.brainbyte.easy_maintenance.billing.infrastructure.persistence.FiscalInvoiceRepository;
import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.payment.domain.Payment;
import com.brainbyte.easy_maintenance.payment.infrastructure.persistence.PaymentRepository;
import com.brainbyte.easy_maintenance.webhooks.commons.domain.WebhookEvent;
import com.brainbyte.easy_maintenance.webhooks.commons.service.WebhookEventService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

// @MockitoSettings(strictness = Strictness.LENIENT): o stub de objectMapper.writeValueAsString no
// @BeforeEach não é usado pelos testes que retornam antes de chamar serialize() (duplicado, evento
// desconhecido) — mesmo padrão já usado em SubscriptionCreatedHandlerTest.
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AsaasFiscalInvoiceWebhookServiceTest {

    @Mock private FiscalInvoiceRepository fiscalInvoiceRepository;
    @Mock private PaymentRepository paymentRepository;
    @Mock private WebhookEventService webhookEventService;
    @Mock private com.fasterxml.jackson.databind.ObjectMapper objectMapper;

    @InjectMocks
    private AsaasFiscalInvoiceWebhookService service;

    @BeforeEach
    void setUp() throws Exception {
        when(webhookEventService.findByProviderEventId(any())).thenReturn(Optional.empty());
        when(webhookEventService.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(objectMapper.writeValueAsString(any())).thenReturn("{}");
    }

    @Test
    void processEvent_invoiceAuthorized_newInvoice_createsAuthorizedRecord() {
        var invoiceObj = new AsaasDTO.FiscalInvoiceObject(
                "inv_abc", "AUTHORIZED", "pay_xyz", "http://pdf", "http://xml", "123", "VALCODE", null);
        var event = new AsaasDTO.FiscalInvoiceWebhookEvent("evt_1", "INVOICE_AUTHORIZED", invoiceObj);

        when(fiscalInvoiceRepository.findByExternalFiscalInvoiceId("inv_abc")).thenReturn(Optional.empty());
        when(paymentRepository.findByExternalPaymentId("pay_xyz")).thenReturn(Optional.empty());

        service.processEvent(event);

        ArgumentCaptor<FiscalInvoice> captor = ArgumentCaptor.forClass(FiscalInvoice.class);
        verify(fiscalInvoiceRepository).save(captor.capture());
        FiscalInvoice saved = captor.getValue();
        assertThat(saved.getExternalFiscalInvoiceId()).isEqualTo("inv_abc");
        assertThat(saved.getStatus()).isEqualTo(FiscalInvoiceStatus.AUTHORIZED);
        assertThat(saved.getPdfUrl()).isEqualTo("http://pdf");
        assertThat(saved.getXmlUrl()).isEqualTo("http://xml");
        assertThat(saved.getAuthorizedAt()).isNotNull();
    }

    @Test
    void processEvent_invoiceAuthorized_resolvesPaymentWhenFound() {
        var invoiceObj = new AsaasDTO.FiscalInvoiceObject(
                "inv_abc", "AUTHORIZED", "pay_xyz", "http://pdf", "http://xml", "123", "VALCODE", null);
        var event = new AsaasDTO.FiscalInvoiceWebhookEvent("evt_1", "INVOICE_AUTHORIZED", invoiceObj);
        Payment payment = Payment.builder().id(99L)
                .billingSubscription(BillingSubscription.builder().id(5L).build())
                .build();

        when(fiscalInvoiceRepository.findByExternalFiscalInvoiceId("inv_abc")).thenReturn(Optional.empty());
        when(paymentRepository.findByExternalPaymentId("pay_xyz")).thenReturn(Optional.of(payment));

        service.processEvent(event);

        ArgumentCaptor<FiscalInvoice> captor = ArgumentCaptor.forClass(FiscalInvoice.class);
        verify(fiscalInvoiceRepository).save(captor.capture());
        assertThat(captor.getValue().getPayment()).isEqualTo(payment);
        assertThat(captor.getValue().getBillingSubscription()).isEqualTo(payment.getBillingSubscription());
    }

    @Test
    void processEvent_invoiceError_existingInvoice_updatesToErrorWithMessage() {
        FiscalInvoice existing = FiscalInvoice.builder().id(1L).externalFiscalInvoiceId("inv_abc")
                .status(FiscalInvoiceStatus.PENDING).build();
        var invoiceObj = new AsaasDTO.FiscalInvoiceObject(
                "inv_abc", "ERROR", "pay_xyz", null, null, null, null, "CNPJ não habilitado na prefeitura");
        var event = new AsaasDTO.FiscalInvoiceWebhookEvent("evt_2", "INVOICE_ERROR", invoiceObj);

        when(fiscalInvoiceRepository.findByExternalFiscalInvoiceId("inv_abc")).thenReturn(Optional.of(existing));

        service.processEvent(event);

        ArgumentCaptor<FiscalInvoice> captor = ArgumentCaptor.forClass(FiscalInvoice.class);
        verify(fiscalInvoiceRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(FiscalInvoiceStatus.ERROR);
        assertThat(captor.getValue().getErrorMessage()).isEqualTo("CNPJ não habilitado na prefeitura");
    }

    @Test
    void processEvent_duplicateEventId_isIgnored() {
        var invoiceObj = new AsaasDTO.FiscalInvoiceObject(
                "inv_abc", "AUTHORIZED", "pay_xyz", "http://pdf", "http://xml", "123", "VALCODE", null);
        var event = new AsaasDTO.FiscalInvoiceWebhookEvent("evt_dup", "INVOICE_AUTHORIZED", invoiceObj);

        when(webhookEventService.findByProviderEventId("evt_dup"))
                .thenReturn(Optional.of(WebhookEvent.builder().providerEventId("evt_dup").build()));

        service.processEvent(event);

        verify(fiscalInvoiceRepository, never()).save(any());
    }

    @Test
    void processEvent_unknownEventType_isIgnoredWithoutError() {
        var invoiceObj = new AsaasDTO.FiscalInvoiceObject(
                "inv_abc", "CANCELED", "pay_xyz", null, null, null, null, null);
        var event = new AsaasDTO.FiscalInvoiceWebhookEvent("evt_3", "INVOICE_CANCELED", invoiceObj);

        service.processEvent(event);

        verify(fiscalInvoiceRepository, never()).save(any());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd easy-maintenance-api && mvn test -Dtest=AsaasFiscalInvoiceWebhookServiceTest`
Expected: FAIL — compilation error, types don't exist yet.

- [ ] **Step 3: Add the webhook DTOs to `AsaasDTO`**

```java
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record FiscalInvoiceObject(
            String id,
            String status,
            String payment,
            String pdfUrl,
            String xmlUrl,
            String number,
            String validationCode,
            String statusDescription
    ) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record FiscalInvoiceWebhookEvent(
            String id,
            String event,
            FiscalInvoiceObject invoice
    ) {}
```

- [ ] **Step 4: Create `AsaasFiscalInvoiceWebhookService`**

```java
package com.brainbyte.easy_maintenance.webhooks.asaas.service;

import com.brainbyte.easy_maintenance.billing.domain.FiscalInvoice;
import com.brainbyte.easy_maintenance.billing.domain.enums.FiscalInvoiceStatus;
import com.brainbyte.easy_maintenance.billing.infrastructure.persistence.FiscalInvoiceRepository;
import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.payment.domain.Payment;
import com.brainbyte.easy_maintenance.payment.infrastructure.persistence.PaymentRepository;
import com.brainbyte.easy_maintenance.webhooks.commons.domain.WebhookEvent;
import com.brainbyte.easy_maintenance.webhooks.commons.domain.enums.WebhookEventStatus;
import com.brainbyte.easy_maintenance.webhooks.commons.service.WebhookEventService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class AsaasFiscalInvoiceWebhookService {

    private static final Set<String> KNOWN_EVENTS = Set.of("INVOICE_AUTHORIZED", "INVOICE_ERROR");

    private final FiscalInvoiceRepository fiscalInvoiceRepository;
    private final PaymentRepository paymentRepository;
    private final WebhookEventService webhookEventService;
    private final ObjectMapper objectMapper;

    @Transactional
    public void processEvent(AsaasDTO.FiscalInvoiceWebhookEvent event) {
        if (event == null || event.invoice() == null) {
            log.warn("[AsaasFiscalInvoiceWebhook] Evento nulo ou sem invoice — ignorado.");
            return;
        }

        if (webhookEventService.findByProviderEventId(event.id()).isPresent()) {
            log.info("[AsaasFiscalInvoiceWebhook] Evento {} já processado anteriormente. Ignorando.", event.id());
            return;
        }
        webhookEventService.save(WebhookEvent.builder()
                .providerEventId(event.id())
                .eventType(event.event())
                .eventCreatedAt(Instant.now())
                .payload(serialize(event))
                .status(WebhookEventStatus.PROCESSED)
                .processedAt(Instant.now())
                .build());

        if (!KNOWN_EVENTS.contains(event.event())) {
            log.info("[AsaasFiscalInvoiceWebhook] Tipo de evento {} sem tratamento específico — ignorado.", event.event());
            return;
        }

        var invoiceObj = event.invoice();
        FiscalInvoice fiscalInvoice = fiscalInvoiceRepository.findByExternalFiscalInvoiceId(invoiceObj.id())
                .orElseGet(() -> FiscalInvoice.builder().externalFiscalInvoiceId(invoiceObj.id()).build());

        Optional<Payment> paymentOpt = invoiceObj.payment() != null
                ? paymentRepository.findByExternalPaymentId(invoiceObj.payment())
                : Optional.empty();
        paymentOpt.ifPresent(payment -> {
            fiscalInvoice.setPayment(payment);
            fiscalInvoice.setBillingSubscription(payment.getBillingSubscription());
        });

        if (fiscalInvoice.getBillingSubscription() == null && paymentOpt.isEmpty()) {
            log.warn("[AsaasFiscalInvoiceWebhook] Payment não resolvido para fiscalInvoiceId={} (externalPaymentId={}) — salvando sem vínculo de assinatura.",
                    invoiceObj.id(), invoiceObj.payment());
        }

        if ("INVOICE_AUTHORIZED".equals(event.event())) {
            fiscalInvoice.setStatus(FiscalInvoiceStatus.AUTHORIZED);
            fiscalInvoice.setPdfUrl(invoiceObj.pdfUrl());
            fiscalInvoice.setXmlUrl(invoiceObj.xmlUrl());
            fiscalInvoice.setAuthorizedAt(Instant.now());
        } else {
            fiscalInvoice.setStatus(FiscalInvoiceStatus.ERROR);
            fiscalInvoice.setErrorMessage(invoiceObj.statusDescription());
            log.warn("[AsaasFiscalInvoiceWebhook] NF {} em ERROR: {}", invoiceObj.id(), invoiceObj.statusDescription());
        }

        fiscalInvoiceRepository.save(fiscalInvoice);
        log.info("[AsaasFiscalInvoiceWebhook] FiscalInvoice {} atualizado para status {}.",
                invoiceObj.id(), fiscalInvoice.getStatus());
    }

    private String serialize(AsaasDTO.FiscalInvoiceWebhookEvent event) {
        try {
            return objectMapper.writeValueAsString(event);
        } catch (Exception e) {
            log.error("[AsaasFiscalInvoiceWebhook] Erro ao serializar payload do evento {}", event.id(), e);
            return "{}";
        }
    }
}
```

**Note:** `billing_subscription_id` is nullable on `fiscal_invoices` (Task 1) exactly for this path — when no `Payment` is resolved, `fiscalInvoice.getBillingSubscription()` stays `null` and the save still succeeds.

- [ ] **Step 5: Create `AsaasFiscalInvoiceWebhookController`**

```java
package com.brainbyte.easy_maintenance.webhooks.asaas.controller;

import com.brainbyte.easy_maintenance.commons.helper.HttpUtils;
import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.infrastructure.saas.properties.AsaasProperties;
import com.brainbyte.easy_maintenance.webhooks.asaas.service.AsaasFiscalInvoiceWebhookService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/easy-maintenance/api/v1/public/webhooks/asaas/fiscal-invoices")
public class AsaasFiscalInvoiceWebhookController {

    private final AsaasFiscalInvoiceWebhookService webhookService;
    private final AsaasProperties asaasProperties;

    @PostMapping
    public ResponseEntity<String> handleEvent(@RequestHeader(value = "asaas-access-token", required = false) String token,
                                              @RequestBody AsaasDTO.FiscalInvoiceWebhookEvent payload,
                                              HttpServletRequest request) {
        String clientIp = HttpUtils.getClientIp(request);

        if (!asaasProperties.webhookTokenConfigured()) {
            log.error("[AsaasFiscalInvoiceWebhook] Token não configurado — requisição rejeitada. IP={}", clientIp);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("webhook token not configured");
        }

        if (!matches(asaasProperties.webhookToken(), token)) {
            log.warn("[AsaasFiscalInvoiceWebhook] Token inválido rejeitado. IP={}, eventId={}", clientIp,
                    payload != null ? payload.id() : "null");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("invalid token");
        }

        webhookService.processEvent(payload);

        return ResponseEntity.ok("ok");
    }

    private static boolean matches(String expected, String received) {
        if (received == null || received.isBlank()) {
            return false;
        }
        return MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), received.getBytes(StandardCharsets.UTF_8));
    }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd easy-maintenance-api && mvn test -Dtest=AsaasFiscalInvoiceWebhookServiceTest`
Expected: PASS (5 tests).

- [ ] **Step 7: Commit**

```bash
git add easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/infrastructure/saas/application/dto/AsaasDTO.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/controller/AsaasFiscalInvoiceWebhookController.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/service/AsaasFiscalInvoiceWebhookService.java \
        easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/webhooks/asaas/service/AsaasFiscalInvoiceWebhookServiceTest.java
git commit -m "feat(billing): handle Asaas INVOICE_AUTHORIZED/INVOICE_ERROR webhooks on a dedicated endpoint"
```

---

## Task 5: Job de reconciliação fiscal

**Files:**
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/jobs/service/FiscalInvoiceReconciliationService.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/jobs/FiscalInvoiceReconciliationJob.java`
- Modify: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/infrastructure/persistence/BillingSubscriptionRepository.java`
- Test: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/jobs/service/FiscalInvoiceReconciliationServiceTest.java`

**Interfaces:**
- Consumes: `FiscalInvoiceConfigurationService.configureForSubscription(BillingSubscription)` (Task 2), `FiscalInvoiceRepository.findByStatusInAndCreatedAtBefore(List<FiscalInvoiceStatus>, Instant)` (Task 1), `JobHealthReporter.markSuccess(String)` (existing).
- Produces: `BillingSubscriptionRepository.findByStatusAndFiscalInvoiceConfiguredFalseAndExternalSubscriptionIdIsNotNull(SubscriptionStatus)` → `List<BillingSubscription>`; `FiscalInvoiceReconciliationService.reconcile()` → `void`.

- [ ] **Step 1: Write the failing test**

```java
package com.brainbyte.easy_maintenance.jobs.service;

import com.brainbyte.easy_maintenance.billing.application.service.FiscalInvoiceConfigurationService;
import com.brainbyte.easy_maintenance.billing.domain.BillingSubscription;
import com.brainbyte.easy_maintenance.billing.domain.FiscalInvoice;
import com.brainbyte.easy_maintenance.billing.domain.enums.FiscalInvoiceStatus;
import com.brainbyte.easy_maintenance.billing.domain.enums.SubscriptionStatus;
import com.brainbyte.easy_maintenance.billing.infrastructure.persistence.BillingSubscriptionRepository;
import com.brainbyte.easy_maintenance.billing.infrastructure.persistence.FiscalInvoiceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FiscalInvoiceReconciliationServiceTest {

    @Mock private BillingSubscriptionRepository billingSubscriptionRepository;
    @Mock private FiscalInvoiceRepository fiscalInvoiceRepository;
    @Mock private FiscalInvoiceConfigurationService fiscalInvoiceConfigurationService;

    @InjectMocks
    private FiscalInvoiceReconciliationService service;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(service, "stuckThresholdDays", 3);
    }

    @Test
    void reconcile_subscriptionMissingConfig_retriesConfiguration() {
        BillingSubscription sub = BillingSubscription.builder()
                .id(1L).status(SubscriptionStatus.ACTIVE)
                .externalSubscriptionId("ext-sub-1").fiscalInvoiceConfigured(false)
                .build();
        when(billingSubscriptionRepository
                .findByStatusAndFiscalInvoiceConfiguredFalseAndExternalSubscriptionIdIsNotNull(SubscriptionStatus.ACTIVE))
                .thenReturn(List.of(sub));
        when(fiscalInvoiceRepository.findByStatusInAndCreatedAtBefore(anyList(), any())).thenReturn(List.of());

        service.reconcile();

        verify(fiscalInvoiceConfigurationService).configureForSubscription(sub);
    }

    @Test
    void reconcile_noMissingConfigSubscriptions_doesNotCallConfigurationService() {
        when(billingSubscriptionRepository
                .findByStatusAndFiscalInvoiceConfiguredFalseAndExternalSubscriptionIdIsNotNull(SubscriptionStatus.ACTIVE))
                .thenReturn(List.of());
        when(fiscalInvoiceRepository.findByStatusInAndCreatedAtBefore(anyList(), any())).thenReturn(List.of());

        service.reconcile();

        verify(fiscalInvoiceConfigurationService, never()).configureForSubscription(any());
    }

    @Test
    void reconcile_stuckErrorInvoice_logsAlertWithoutRetryingEmission() {
        FiscalInvoice stuck = FiscalInvoice.builder().id(10L).externalFiscalInvoiceId("inv_stuck")
                .status(FiscalInvoiceStatus.ERROR).build();
        when(billingSubscriptionRepository
                .findByStatusAndFiscalInvoiceConfiguredFalseAndExternalSubscriptionIdIsNotNull(SubscriptionStatus.ACTIVE))
                .thenReturn(List.of());
        when(fiscalInvoiceRepository.findByStatusInAndCreatedAtBefore(
                List.of(FiscalInvoiceStatus.ERROR, FiscalInvoiceStatus.PENDING), any()))
                .thenReturn(List.of(stuck));

        service.reconcile();

        // Não há retry automático de emissão — nenhuma chamada deve alterar o FiscalInvoice.
        verifyNoInteractions(fiscalInvoiceConfigurationService);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd easy-maintenance-api && mvn test -Dtest=FiscalInvoiceReconciliationServiceTest`
Expected: FAIL — `FiscalInvoiceReconciliationService` and the new repository method don't exist yet.

- [ ] **Step 3: Add the repository method**

In `BillingSubscriptionRepository`, add:

```java
    List<BillingSubscription> findByStatusAndFiscalInvoiceConfiguredFalseAndExternalSubscriptionIdIsNotNull(SubscriptionStatus status);
```

- [ ] **Step 4: Create `FiscalInvoiceReconciliationService`**

```java
package com.brainbyte.easy_maintenance.jobs.service;

import com.brainbyte.easy_maintenance.billing.application.service.FiscalInvoiceConfigurationService;
import com.brainbyte.easy_maintenance.billing.domain.FiscalInvoice;
import com.brainbyte.easy_maintenance.billing.domain.enums.FiscalInvoiceStatus;
import com.brainbyte.easy_maintenance.billing.domain.enums.SubscriptionStatus;
import com.brainbyte.easy_maintenance.billing.infrastructure.persistence.BillingSubscriptionRepository;
import com.brainbyte.easy_maintenance.billing.infrastructure.persistence.FiscalInvoiceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class FiscalInvoiceReconciliationService {

    private final BillingSubscriptionRepository billingSubscriptionRepository;
    private final FiscalInvoiceRepository fiscalInvoiceRepository;
    private final FiscalInvoiceConfigurationService fiscalInvoiceConfigurationService;

    @Value("${billing.fiscal-invoice.stuck-threshold-days:3}")
    private int stuckThresholdDays;

    public void reconcile() {
        List<com.brainbyte.easy_maintenance.billing.domain.BillingSubscription> missingConfig =
                billingSubscriptionRepository.findByStatusAndFiscalInvoiceConfiguredFalseAndExternalSubscriptionIdIsNotNull(
                        SubscriptionStatus.ACTIVE);

        log.info("[FiscalInvoiceReconciliation] Subscriptions sem configuração de NF: {}", missingConfig.size());
        for (var sub : missingConfig) {
            fiscalInvoiceConfigurationService.configureForSubscription(sub);
        }

        Instant cutoff = Instant.now().minus(stuckThresholdDays, ChronoUnit.DAYS);
        List<FiscalInvoice> stuck = fiscalInvoiceRepository.findByStatusInAndCreatedAtBefore(
                List.of(FiscalInvoiceStatus.ERROR, FiscalInvoiceStatus.PENDING), cutoff);

        for (FiscalInvoice invoice : stuck) {
            log.warn("[FiscalInvoiceReconciliation] FiscalInvoice {} travado em {} há mais de {} dias — revisão manual necessária (errorMessage={}).",
                    invoice.getExternalFiscalInvoiceId(), invoice.getStatus(), stuckThresholdDays, invoice.getErrorMessage());
        }

        log.info("[FiscalInvoiceReconciliation] Done. configRetried={}, stuckAlerted={}", missingConfig.size(), stuck.size());
    }
}
```

- [ ] **Step 5: Create `FiscalInvoiceReconciliationJob`**

```java
package com.brainbyte.easy_maintenance.jobs;

import com.brainbyte.easy_maintenance.infrastructure.observability.service.JobHealthReporter;
import com.brainbyte.easy_maintenance.jobs.service.FiscalInvoiceReconciliationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.javacrumbs.shedlock.spring.annotation.SchedulerLock;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class FiscalInvoiceReconciliationJob {

    private final FiscalInvoiceReconciliationService reconciliationService;
    private final JobHealthReporter jobHealthReporter;

    @Scheduled(cron = "${billing.fiscal-invoice.reconciliation.cron:0 30 3 * * *}")
    @SchedulerLock(name = "FiscalInvoiceReconciliationJob", lockAtMostFor = "PT1H", lockAtLeastFor = "PT5M")
    public void run() {
        log.info("[FiscalInvoiceReconciliationJob] Lock adquirido. Iniciando reconciliação fiscal.");
        try {
            reconciliationService.reconcile();
            jobHealthReporter.markSuccess("fiscal_invoice_reconciliation");
            log.info("[FiscalInvoiceReconciliationJob] Execução concluída com sucesso.");
        } catch (Exception e) {
            log.error("[FiscalInvoiceReconciliationJob] Erro inesperado: {}", e.getMessage(), e);
        }
    }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd easy-maintenance-api && mvn test -Dtest=FiscalInvoiceReconciliationServiceTest`
Expected: PASS (3 tests).

- [ ] **Step 7: Run the full billing/webhooks/jobs test suite to confirm no regressions**

Run: `cd easy-maintenance-api && mvn test -Dtest="com.brainbyte.easy_maintenance.billing.**,com.brainbyte.easy_maintenance.webhooks.**,com.brainbyte.easy_maintenance.jobs.**"`
Expected: PASS, no failures in previously-passing tests (especially `SubscriptionCreatedHandlerTest`, `BillingReconciliationServiceTest`, `FiscalInvoicePersistenceTest`).

- [ ] **Step 8: Commit**

```bash
git add easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/jobs/service/FiscalInvoiceReconciliationService.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/jobs/FiscalInvoiceReconciliationJob.java \
        easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/billing/infrastructure/persistence/BillingSubscriptionRepository.java \
        easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/jobs/service/FiscalInvoiceReconciliationServiceTest.java
git commit -m "feat(billing): add daily fiscal invoice reconciliation job"
```
