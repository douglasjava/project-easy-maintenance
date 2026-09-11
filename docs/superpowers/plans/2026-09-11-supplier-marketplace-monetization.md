# Marketplace de Fornecedores (Monetização) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fornecedor auto-cadastrado paga uma assinatura mensal via PIX (R$15,99) pra ficar visível
na busca por região pra outras organizações e receber "Solicitar Orçamento" — fornecedores
cadastrados por organização continuam de graça, mas ficam invisíveis pra outras organizações até
serem ativados (auto-cadastro pago ou ativação manual da equipe).

**Architecture:** Novo módulo `supplier_billing` (domínio de cobrança isolado, sem tocar em
`billing/`) reaproveitando só `AsaasClient`. `Supplier` (módulo `supplier` já existente) ganha
`document`/`email`/`marketplace_enabled`/`activated_at`/`activation_source`. Um único ponto de
integração com código existente: `PaymentReceivedHandler` (webhook Asaas) ganha um branch no topo
pra reconhecer `externalReference` com prefixo `SUPPLIER-` e delegar pro módulo novo, sem alterar
o resto do método.

**Tech Stack:** Spring Boot 3.5.7, Java 21, JPA/Hibernate 6.6, MySQL 8/Flyway, Asaas (PIX
detached), Next.js/React Query (frontend).

**Spec:** `docs/superpowers/specs/2026-09-11-supplier-marketplace-monetization-design.md`

## Global Constraints

- Cobrança mensal: **R$15,99**, só PIX no v1.
- Prazo de graça antes de suspender por atraso: **3 dias corridos** (mesmo valor de
  `billing.blocking.days-after-due`, TASK-236 — não reinventar o número).
- `Supplier.document` valida CPF **ou** CNPJ via `@Doc` (já existe, `commons/validation/Doc.java`)
  — nunca só `@CNPJ`.
- Nenhuma tabela/serviço de `billing/` (organização) é alterado, com uma única exceção documentada
  e testada: um branch condicional no topo de `PaymentReceivedHandler.handle()`.
- `externalReference` das cobranças de fornecedor usa o prefixo `SUPPLIER-<supplierId>` (mesmo
  padrão de `BILLING-<subscriptionId>` já usado pra organização) — é como o webhook único do Asaas
  distingue os dois fluxos.
- Toda rota pública nova segue o padrão já estabelecido: `/easy-maintenance/api/v1/public/...`,
  `@RateLimit("<chave>")` em cada endpoint, sem cookie/sessão.

---

## Task 1: Generalizar `Supplier` pra aceitar CPF/CNPJ + campos de marketplace

**Files:**
- Create: `src/main/resources/db/migration/V111__generalize_supplier_document_and_marketplace.sql`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier/domain/Supplier.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier/domain/enums/ActivationSource.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier/application/dto/RegisterSupplierRequest.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier/application/dto/SupplierRegistryResponse.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier/infrastructure/persistence/SupplierRepository.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierRegistryService.java`
- Modify: `src/test/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierRegistryServiceTest.java`

**Interfaces:**
- Produces: `Supplier.getDocument()/setDocument(String)`, `Supplier.getEmail()/setEmail(String)`,
  `Supplier.isMarketplaceEnabled()/setMarketplaceEnabled(boolean)`,
  `Supplier.getActivatedAt()/setActivatedAt(Instant)`,
  `Supplier.getActivationSource()/setActivationSource(ActivationSource)`.
  `SupplierRepository.findByDocument(String document): Optional<Supplier>` (substitui
  `findByCnpj`). Tasks 3, 5, 6, 9 dependem desses nomes exatos.

- [ ] **Step 1: Escrever a migration**

```sql
-- V111__generalize_supplier_document_and_marketplace.sql
ALTER TABLE suppliers
    CHANGE COLUMN cnpj document VARCHAR(20) NOT NULL,
    ADD COLUMN email VARCHAR(160) NULL AFTER document,
    ADD COLUMN marketplace_enabled BOOLEAN NOT NULL DEFAULT FALSE AFTER registration_count,
    ADD COLUMN activated_at TIMESTAMP NULL AFTER marketplace_enabled,
    ADD COLUMN activation_source VARCHAR(20) NULL AFTER activated_at;

ALTER TABLE suppliers DROP INDEX uk_suppliers_cnpj;
ALTER TABLE suppliers ADD CONSTRAINT uk_suppliers_document UNIQUE (document);
```

- [ ] **Step 2: Validar a migration contra o MySQL real do docker local**

Aplicar direto (mesmo padrão já usado nesta sessão pra toda migration nova — TASK-230/241/246):

```bash
docker cp src/main/resources/db/migration/V111__generalize_supplier_document_and_marketplace.sql easy_maintenance_mysql:/tmp/V111.sql
docker exec -i easy_maintenance_mysql sh -c "mysql -uroot -prootpass easy_maintenance < /tmp/V111.sql"
docker exec easy_maintenance_mysql mysql -uroot -prootpass easy_maintenance -e "DESCRIBE suppliers;"
```

Expected: `document` (não mais `cnpj`), `email`, `marketplace_enabled`, `activated_at`,
`activation_source` aparecem na saída. Depois, reverter (mesma disciplina de sempre — não deixar
migration aplicada fora do boot real do Flyway):

```bash
docker exec easy_maintenance_mysql mysql -uroot -prootpass easy_maintenance -e "
ALTER TABLE suppliers DROP INDEX uk_suppliers_document;
ALTER TABLE suppliers CHANGE COLUMN document cnpj VARCHAR(20) NOT NULL;
ALTER TABLE suppliers ADD CONSTRAINT uk_suppliers_cnpj UNIQUE (cnpj);
ALTER TABLE suppliers DROP COLUMN email, DROP COLUMN marketplace_enabled, DROP COLUMN activated_at, DROP COLUMN activation_source;
"
```

- [ ] **Step 3: `ActivationSource` enum**

```java
package com.brainbyte.easy_maintenance.supplier.domain.enums;

public enum ActivationSource {
    SELF_REGISTERED,
    MANUALLY_ACTIVATED
}
```

- [ ] **Step 4: Atualizar a entidade `Supplier`**

Substituir o campo `cnpj` e adicionar os novos, mantendo `@Data @Entity @Builder @Table(name =
"suppliers") @NoArgsConstructor @AllArgsConstructor` como já está:

```java
    @Column(nullable = false, unique = true, length = 20)
    private String document;

    @Column(length = 160)
    private String email;

    @Column(name = "marketplace_enabled", nullable = false)
    @Builder.Default
    private boolean marketplaceEnabled = false;

    @Column(name = "activated_at")
    private Instant activatedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "activation_source", length = 20)
    private ActivationSource activationSource;
```//
(remove o campo `cnpj` antigo; import `com.brainbyte.easy_maintenance.supplier.domain.enums.ActivationSource`)

- [ ] **Step 5: Escrever o teste que prova a troca de validação (falha primeiro)**

Em `RegisterSupplierRequestTest` — arquivo novo, `src/test/java/com/brainbyte/easy_maintenance/supplier/application/dto/RegisterSupplierRequestTest.java`:

```java
package com.brainbyte.easy_maintenance.supplier.application.dto;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class RegisterSupplierRequestTest {

    private final Validator validator;

    RegisterSupplierRequestTest() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        this.validator = factory.getValidator();
    }

    private RegisterSupplierRequest request(String document) {
        return new RegisterSupplierRequest(document, "Fornecedor Teste", "(11) 91234-5678", "EXTINTOR", "São Paulo", "SP");
    }

    @Test
    void validCnpj_noViolations() {
        Set<ConstraintViolation<RegisterSupplierRequest>> violations = validator.validate(request("11222333000181"));
        assertThat(violations).isEmpty();
    }

    @Test
    void validCpf_noViolations() {
        // CPF válido (dígito verificador correto) — mesmo usado nos testes de docMask do frontend
        Set<ConstraintViolation<RegisterSupplierRequest>> violations = validator.validate(request("52998224725"));
        assertThat(violations).isEmpty();
    }

    @Test
    void invalidDocument_hasViolation() {
        Set<ConstraintViolation<RegisterSupplierRequest>> violations = validator.validate(request("12345678901234"));
        assertThat(violations).isNotEmpty();
    }
}
```

- [ ] **Step 6: Rodar o teste novo pra confirmar que falha (compilação — `RegisterSupplierRequest` ainda tem `cnpj`/`@CNPJ`)**

Run: `mvn test -Dtest=RegisterSupplierRequestTest`
Expected: FAIL na compilação (`document` não existe no record ainda)

- [ ] **Step 7: Atualizar `RegisterSupplierRequest`**

```java
package com.brainbyte.easy_maintenance.supplier.application.dto;

import com.brainbyte.easy_maintenance.commons.validation.Doc;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Cadastro de fornecedor pela organização autenticada")
public record RegisterSupplierRequest(

        @Schema(description = "CPF ou CNPJ do fornecedor — chave de deduplicação entre organizações", example = "11.222.333/0001-81")
        @NotBlank
        @Doc
        String document,

        @Schema(description = "Nome/razão social do fornecedor", example = "Extintores Silva Ltda")
        @NotBlank
        @Size(max = 200)
        String name,

        @Schema(description = "Telefone de contato", example = "(11) 91234-5678")
        @Size(max = 20)
        String phone,

        @Schema(description = "Categoria do fornecedor (mesma taxonomia usada pelos tipos de item)", example = "EXTINTOR")
        @Size(max = 60)
        String category,

        @Schema(description = "Cidade do fornecedor — opcional, herda da organização logada quando omitida", example = "São Paulo")
        @Size(max = 120)
        String city,

        @Schema(description = "Estado (UF) do fornecedor — opcional, herda da organização logada quando omitido", example = "SP")
        @Size(max = 2)
        String state
) {}
```

- [ ] **Step 8: Rodar o teste de novo — deve passar**

Run: `mvn test -Dtest=RegisterSupplierRequestTest`
Expected: PASS (3 testes)

- [ ] **Step 9: Atualizar `SupplierRegistryResponse`, `SupplierRepository`, `SupplierRegistryService`**

`SupplierRegistryResponse` — troca `cnpj` por `document`:

```java
public record SupplierRegistryResponse(
        Long id,
        String document,
        String name,
        String phone,
        String category,
        String city,
        String state,
        @Schema(description = "Pontuação — nº de organizações distintas que já cadastraram/vincularam esse fornecedor")
        Integer registrationCount,
        Instant createdAt
) {}
```

`SupplierRepository` — troca `findByCnpj` por `findByDocument`:

```java
Optional<Supplier> findByDocument(String document);
```

`SupplierRegistryService` — troca toda referência a `cnpj`/`getCnpj`/`findByCnpj` por
`document`/`getDocument`/`findByDocument` (3 ocorrências: `register`, `newSupplier`, `toResponse`,
mais os 2 `log.info` que citam `cnpj=`).

- [ ] **Step 10: Atualizar `SupplierRegistryServiceTest` (renomear `cnpj` por `document` nos testes existentes, sem mudar o que cada teste verifica)**

Substituir toda ocorrência de `.cnpj(` por `.document(`, `findByCnpj` por `findByDocument`,
`response.cnpj()` por `response.document()` no arquivo já existente
(`src/test/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierRegistryServiceTest.java`)
— nenhuma asserção muda de significado, só o nome do campo.

- [ ] **Step 11: Rodar a suíte completa de fornecedor**

Run: `mvn test -Dtest=Supplier*Test,RegisterSupplierRequestTest`
Expected: PASS — todos os testes de `SupplierRegistryServiceTest` (6), `SupplierPersistenceTest`,
`RegisterSupplierRequestTest` (3, novo)

- [ ] **Step 12: Commit**

```bash
git add src/main/resources/db/migration/V111__generalize_supplier_document_and_marketplace.sql \
  src/main/java/com/brainbyte/easy_maintenance/supplier/domain/Supplier.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier/domain/enums/ActivationSource.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier/application/dto/RegisterSupplierRequest.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier/application/dto/SupplierRegistryResponse.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier/infrastructure/persistence/SupplierRepository.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierRegistryService.java \
  src/test/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierRegistryServiceTest.java \
  src/test/java/com/brainbyte/easy_maintenance/supplier/application/dto/RegisterSupplierRequestTest.java
git commit -m "feat(supplier): TASK-260 - generaliza Supplier pra CPF/CNPJ + campos de marketplace"
```

---

## Task 2: Novas entidades — `SupplierSubscription`, `SupplierAccessToken`, `SupplierBudgetRequest`

**Files:**
- Create: `src/main/resources/db/migration/V112__create_supplier_billing_tables.sql`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/domain/SupplierSubscription.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/domain/enums/SupplierSubscriptionStatus.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/domain/SupplierAccessToken.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier/domain/SupplierBudgetRequest.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/persistence/SupplierSubscriptionRepository.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/persistence/SupplierAccessTokenRepository.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier/infrastructure/persistence/SupplierBudgetRequestRepository.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/persistence/SupplierBillingPersistenceTest.java`

**Interfaces:**
- Consumes: `Supplier` (Task 1) — `SupplierSubscription`/`SupplierAccessToken`/`SupplierBudgetRequest`
  todos referenciam `supplierId` (FK simples, sem `@ManyToOne`, mesmo padrão de
  `SupplierOrganizationLink` já existente).
- Produces: `SupplierSubscriptionRepository.findBySupplierId(Long): Optional<SupplierSubscription>`,
  `SupplierAccessTokenRepository.findByToken(String): Optional<SupplierAccessToken>`,
  `SupplierAccessTokenRepository.findBySupplierId(Long): Optional<SupplierAccessToken>`. Tasks 5,
  6, 7, 8 dependem desses nomes.

- [ ] **Step 1: Migration**

```sql
-- V112__create_supplier_billing_tables.sql
CREATE TABLE supplier_subscriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL,
    external_customer_id VARCHAR(60) NULL,
    external_payment_id VARCHAR(60) NULL,
    current_period_end DATE NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uk_supplier_subscriptions_supplier UNIQUE (supplier_id),
    CONSTRAINT fk_supplier_subscriptions_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
);

CREATE TABLE supplier_access_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    token VARCHAR(80) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_supplier_access_tokens_token UNIQUE (token),
    CONSTRAINT fk_supplier_access_tokens_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
);
CREATE INDEX idx_supplier_access_tokens_supplier ON supplier_access_tokens (supplier_id);

CREATE TABLE supplier_budget_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    organization_code CHAR(36) NOT NULL,
    requested_by_user_id BIGINT NOT NULL,
    summary VARCHAR(1000) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_supplier_budget_requests_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
    CONSTRAINT fk_supplier_budget_requests_organization FOREIGN KEY (organization_code) REFERENCES organizations (code)
);
CREATE INDEX idx_supplier_budget_requests_supplier ON supplier_budget_requests (supplier_id);
```

- [ ] **Step 2: Validar contra o MySQL real do docker, depois reverter**

```bash
docker cp src/main/resources/db/migration/V112__create_supplier_billing_tables.sql easy_maintenance_mysql:/tmp/V112.sql
docker exec -i easy_maintenance_mysql sh -c "mysql -uroot -prootpass easy_maintenance < /tmp/V112.sql"
docker exec easy_maintenance_mysql mysql -uroot -prootpass easy_maintenance -e "SHOW TABLES LIKE 'supplier_%';"
```

Expected: as 3 tabelas novas aparecem. Reverter:

```bash
docker exec easy_maintenance_mysql mysql -uroot -prootpass easy_maintenance -e "
DROP TABLE supplier_budget_requests;
DROP TABLE supplier_access_tokens;
DROP TABLE supplier_subscriptions;
"
```

(Nota: esta migration precisa da `V111` já aplicada nesse boot — como o docker de dev é revertido
a cada validação, aplique `V111` antes de validar esta, e reverta os dois juntos ao final.)

- [ ] **Step 3: `SupplierSubscriptionStatus` enum**

```java
package com.brainbyte.easy_maintenance.supplier_billing.domain.enums;

public enum SupplierSubscriptionStatus {
    ACTIVE,
    PAST_DUE,
    CANCELED
}
```

- [ ] **Step 4: `SupplierSubscription` entity**

```java
package com.brainbyte.easy_maintenance.supplier_billing.domain;

import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.time.LocalDate;

// Fase 2 EPIC-028: cobrança de fornecedor, dominio isolado do billing de organizacao de proposito
// (ver decisao de escopo #5 do spec 2026-09-11) -- reaproveita so o AsaasClient (HTTP puro).
@Data
@Entity
@Builder
@Table(name = "supplier_subscriptions")
@NoArgsConstructor
@AllArgsConstructor
public class SupplierSubscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "supplier_id", nullable = false, unique = true)
    private Long supplierId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SupplierSubscriptionStatus status;

    @Column(name = "external_customer_id", length = 60)
    private String externalCustomerId;

    @Column(name = "external_payment_id", length = 60)
    private String externalPaymentId;

    @Column(name = "current_period_end")
    private LocalDate currentPeriodEnd;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
```

- [ ] **Step 5: `SupplierAccessToken` entity**

```java
package com.brainbyte.easy_maintenance.supplier_billing.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

// Link magico -- sem expiracao por uso, revogavel manualmente se preciso (decisao de escopo #7).
@Data
@Entity
@Builder
@Table(name = "supplier_access_tokens")
@NoArgsConstructor
@AllArgsConstructor
public class SupplierAccessToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    @Column(nullable = false, unique = true, length = 80)
    private String token;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
```

- [ ] **Step 6: `SupplierBudgetRequest` entity** (dentro do módulo `supplier`, não `supplier_billing`
      — é dado de demanda do fornecedor, não de cobrança)

```java
package com.brainbyte.easy_maintenance.supplier.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

// "Solicitar Orcamento" (decisao de escopo #4) -- log de demanda real, base pra ranking futuro.
@Data
@Entity
@Builder
@Table(name = "supplier_budget_requests")
@NoArgsConstructor
@AllArgsConstructor
public class SupplierBudgetRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    @Column(name = "organization_code", nullable = false, length = 36)
    private String organizationCode;

    @Column(name = "requested_by_user_id", nullable = false)
    private Long requestedByUserId;

    @Column(nullable = false, length = 1000)
    private String summary;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
```

- [ ] **Step 7: Os 3 repositórios**

```java
package com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence;

import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface SupplierSubscriptionRepository extends JpaRepository<SupplierSubscription, Long> {
    Optional<SupplierSubscription> findBySupplierId(Long supplierId);
    List<SupplierSubscription> findByStatusAndCurrentPeriodEndLessThanEqual(
            SupplierSubscriptionStatus status, LocalDate date);
}
```

```java
package com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence;

import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierAccessToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SupplierAccessTokenRepository extends JpaRepository<SupplierAccessToken, Long> {
    Optional<SupplierAccessToken> findByToken(String token);
    Optional<SupplierAccessToken> findBySupplierId(Long supplierId);
}
```

```java
package com.brainbyte.easy_maintenance.supplier.infrastructure.persistence;

import com.brainbyte.easy_maintenance.supplier.domain.SupplierBudgetRequest;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SupplierBudgetRequestRepository extends JpaRepository<SupplierBudgetRequest, Long> {
}
```

- [ ] **Step 8: Teste de persistência (H2, `@DataJpaTest`) provando as constraints**

```java
package com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence;

import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.dao.DataIntegrityViolationException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DataJpaTest
class SupplierBillingPersistenceTest {

    @Autowired SupplierSubscriptionRepository subscriptionRepository;
    @Autowired SupplierRepository supplierRepository;
    @Autowired TestEntityManager entityManager;

    private Long persistSupplier() {
        Supplier s = supplierRepository.save(Supplier.builder()
                .document("11222333000181").name("Fornecedor Teste").registrationCount(0).build());
        return s.getId();
    }

    @Test
    void save_and_findBySupplierId_roundTrips() {
        Long supplierId = persistSupplier();
        subscriptionRepository.save(SupplierSubscription.builder()
                .supplierId(supplierId).status(SupplierSubscriptionStatus.PAST_DUE).build());
        entityManager.flush();
        entityManager.clear();

        var found = subscriptionRepository.findBySupplierId(supplierId);
        assertThat(found).isPresent();
        assertThat(found.get().getStatus()).isEqualTo(SupplierSubscriptionStatus.PAST_DUE);
    }

    @Test
    void save_secondSubscriptionForSameSupplier_violatesUniqueConstraint() {
        Long supplierId = persistSupplier();
        subscriptionRepository.saveAndFlush(SupplierSubscription.builder()
                .supplierId(supplierId).status(SupplierSubscriptionStatus.ACTIVE).build());

        assertThatThrownBy(() -> subscriptionRepository.saveAndFlush(SupplierSubscription.builder()
                .supplierId(supplierId).status(SupplierSubscriptionStatus.ACTIVE).build()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
```

- [ ] **Step 9: Rodar o teste**

Run: `mvn test -Dtest=SupplierBillingPersistenceTest`
Expected: PASS (2 testes)

- [ ] **Step 10: Commit**

```bash
git add src/main/resources/db/migration/V112__create_supplier_billing_tables.sql \
  src/main/java/com/brainbyte/easy_maintenance/supplier_billing/ \
  src/main/java/com/brainbyte/easy_maintenance/supplier/domain/SupplierBudgetRequest.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier/infrastructure/persistence/SupplierBudgetRequestRepository.java \
  src/test/java/com/brainbyte/easy_maintenance/supplier_billing/
git commit -m "feat(supplier-billing): TASK-261 - entidades SupplierSubscription/AccessToken/BudgetRequest"
```

---

## Task 3: Visibilidade — busca só mostra fornecedor `marketplace_enabled` pra outras organizações

**Files:**
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier/infrastructure/persistence/SupplierRepository.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierRegistryService.java`
- Modify: `src/test/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierRegistryServiceTest.java`

**Interfaces:**
- Consumes: `Supplier.isMarketplaceEnabled()` (Task 1), `SupplierOrganizationLinkRepository`
  (já existe).
- Produces: `SupplierRepository.findByRegionVisibleTo(city, state, category, organizationId)` —
  substitui `findByRegion` nas chamadas de `search()`.

- [ ] **Step 1: Escrever o teste que prova o gating (falha primeiro)**

Adicionar em `SupplierRegistryServiceTest.java`:

```java
    @Test
    void search_hidesNonMarketplaceSupplier_fromOtherOrganization() {
        TenantContext.set("ORG-A");
        when(organizationRepository.findByCode("ORG-A")).thenReturn(Optional.of(organizationA));
        when(supplierRepository.findByRegionVisibleTo("São Paulo", "SP", null, 1L)).thenReturn(List.of());

        List<SupplierRegistryResponse> result = service.search(null, null, null);

        assertThat(result).isEmpty();
        verify(supplierRepository).findByRegionVisibleTo("São Paulo", "SP", null, 1L);
    }
```

- [ ] **Step 2: Rodar — deve falhar (método não existe)**

Run: `mvn test -Dtest=SupplierRegistryServiceTest#search_hidesNonMarketplaceSupplier_fromOtherOrganization`
Expected: FAIL na compilação

- [ ] **Step 3: Trocar `findByRegion` por `findByRegionVisibleTo` no repositório**

```java
    // Fase 2 EPIC-028: so mostra fornecedor com marketplace_enabled=true pra outras organizacoes
    // -- exceto pra quem originalmente cadastrou (join com supplier_organization_links), que
    // sempre ve o proprio registro (decisao de escopo #1 do spec 2026-09-11).
    @Query("SELECT s FROM Supplier s WHERE s.city = :city AND s.state = :state "
            + "AND (:category IS NULL OR s.category = :category) "
            + "AND (s.marketplaceEnabled = true OR EXISTS ("
            + "  SELECT 1 FROM SupplierOrganizationLink l "
            + "  WHERE l.supplierId = s.id AND l.organizationId = :organizationId)) "
            + "ORDER BY s.registrationCount DESC, s.name ASC")
    List<Supplier> findByRegionVisibleTo(@Param("city") String city, @Param("state") String state,
                                          @Param("category") String category,
                                          @Param("organizationId") Long organizationId);
```

(Remove o método `findByRegion` antigo — nenhum outro chamador depende dele, confirmado por
`grep -rn "findByRegion\b"` antes de remover.)

- [ ] **Step 4: Atualizar `SupplierRegistryService.search()`**

```java
    public List<SupplierRegistryResponse> search(String city, String state, String category) {
        Organization organization = resolveCurrentOrganization();

        String effectiveCity = StringUtils.hasText(city) ? city : organization.getCity();
        String effectiveState = StringUtils.hasText(state) ? state : organization.getState();
        String effectiveCategory = StringUtils.hasText(category) ? category : null;

        return supplierRepository.findByRegionVisibleTo(effectiveCity, effectiveState, effectiveCategory, organization.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }
```

- [ ] **Step 5: Atualizar os 2 testes de `search` já existentes (`findByRegion` → `findByRegionVisibleTo`, mais o argumento `organizationId`)**

`search_usesOrganizationCityState_whenFiltersOmitted`:
```java
        when(supplierRepository.findByRegionVisibleTo("São Paulo", "SP", null, 1L)).thenReturn(List.of(supplier));
        ...
        verify(supplierRepository).findByRegionVisibleTo("São Paulo", "SP", null, 1L);
```

`search_usesExplicitFilters_whenProvided_overridingOrganizationDefaults`:
```java
        when(supplierRepository.findByRegionVisibleTo("Rio de Janeiro", "RJ", "SPDA", 1L)).thenReturn(List.of());
        ...
        verify(supplierRepository).findByRegionVisibleTo(eq("Rio de Janeiro"), eq("RJ"), eq("SPDA"), eq(1L));
```

- [ ] **Step 6: Rodar a suíte de fornecedor completa**

Run: `mvn test -Dtest=SupplierRegistryServiceTest`
Expected: PASS (8 testes — 6 originais + 1 novo de gating + os 2 ajustados já contam nos 6)

- [ ] **Step 7: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier/infrastructure/persistence/SupplierRepository.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierRegistryService.java \
  src/test/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierRegistryServiceTest.java
git commit -m "feat(supplier): TASK-262 - busca so mostra fornecedor marketplace_enabled pra outras organizacoes"
```

---

## Task 4: "Solicitar Orçamento" (autenticado)

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier/application/dto/CreateBudgetRequestRequest.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier/application/dto/BudgetRequestResponse.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierBudgetRequestService.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier/infrastructure/web/SupplierRegistryController.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierBudgetRequestServiceTest.java`

**Interfaces:**
- Consumes: `SupplierBudgetRequestRepository` (Task 2), `SupplierRepository.findById` (existente,
  JpaRepository), `TenantContext.get()`, `AuthenticationService.getCurrentUser()` (já usado em
  `DashboardActionsService`, mesmo padrão).
- Produces: `SupplierBudgetRequestService.create(Long supplierId, CreateBudgetRequestRequest):
  BudgetRequestResponse`. Frontend (Task 10) consome
  `POST /easy-maintenance/api/v1/suppliers/{id}/budget-request`.

- [ ] **Step 1: DTOs**

```java
package com.brainbyte.easy_maintenance.supplier.application.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateBudgetRequestRequest(
        @NotBlank @Size(max = 1000) String summary
) {}
```

```java
package com.brainbyte.easy_maintenance.supplier.application.dto;

public record BudgetRequestResponse(
        Long id,
        Long supplierId,
        String supplierPhone,
        String summary
) {}
```

- [ ] **Step 2: Escrever o teste do serviço (falha primeiro — classe não existe)**

```java
package com.brainbyte.easy_maintenance.supplier.application.service;

import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.commons.exceptions.TenantException;
import com.brainbyte.easy_maintenance.kernel.tenant.TenantContext;
import com.brainbyte.easy_maintenance.org_users.application.service.AuthenticationService;
import com.brainbyte.easy_maintenance.org_users.domain.User;
import com.brainbyte.easy_maintenance.supplier.application.dto.BudgetRequestResponse;
import com.brainbyte.easy_maintenance.supplier.application.dto.CreateBudgetRequestRequest;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.domain.SupplierBudgetRequest;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierBudgetRequestRepository;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SupplierBudgetRequestServiceTest {

    @Mock SupplierRepository supplierRepository;
    @Mock SupplierBudgetRequestRepository budgetRequestRepository;
    @Mock AuthenticationService authenticationService;
    @InjectMocks SupplierBudgetRequestService service;

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    void create_validSupplier_savesRequestAndReturnsSupplierPhone() {
        TenantContext.set("ORG-A");
        when(authenticationService.getCurrentUser()).thenReturn(User.builder().id(7L).build());
        Supplier supplier = Supplier.builder().id(100L).document("11222333000181")
                .name("Extintores Silva").phone("(11) 91234-5678").build();
        when(supplierRepository.findById(100L)).thenReturn(Optional.of(supplier));
        when(budgetRequestRepository.save(any(SupplierBudgetRequest.class))).thenAnswer(inv -> {
            SupplierBudgetRequest r = inv.getArgument(0);
            r.setId(1L);
            return r;
        });

        BudgetRequestResponse response = service.create(100L, new CreateBudgetRequestRequest("Preciso de recarga de 5 extintores"));

        assertThat(response.supplierId()).isEqualTo(100L);
        assertThat(response.supplierPhone()).isEqualTo("(11) 91234-5678");

        ArgumentCaptor<SupplierBudgetRequest> captor = ArgumentCaptor.forClass(SupplierBudgetRequest.class);
        verify(budgetRequestRepository).save(captor.capture());
        assertThat(captor.getValue().getOrganizationCode()).isEqualTo("ORG-A");
        assertThat(captor.getValue().getRequestedByUserId()).isEqualTo(7L);
        assertThat(captor.getValue().getSummary()).isEqualTo("Preciso de recarga de 5 extintores");
    }

    @Test
    void create_supplierNotFound_throwsNotFoundException() {
        TenantContext.set("ORG-A");
        when(supplierRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.create(999L, new CreateBudgetRequestRequest("Resumo")))
                .isInstanceOf(NotFoundException.class);
        verifyNoInteractions(budgetRequestRepository);
    }

    @Test
    void create_noTenantContext_throwsTenantException() {
        assertThatThrownBy(() -> service.create(100L, new CreateBudgetRequestRequest("Resumo")))
                .isInstanceOf(TenantException.class);
        verifyNoInteractions(supplierRepository, budgetRequestRepository);
    }
}
```

- [ ] **Step 3: Rodar — deve falhar (compilação)**

Run: `mvn test -Dtest=SupplierBudgetRequestServiceTest`
Expected: FAIL — `SupplierBudgetRequestService` não existe

- [ ] **Step 4: Implementar `SupplierBudgetRequestService`**

```java
package com.brainbyte.easy_maintenance.supplier.application.service;

import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.commons.exceptions.TenantException;
import com.brainbyte.easy_maintenance.kernel.tenant.TenantContext;
import com.brainbyte.easy_maintenance.org_users.application.service.AuthenticationService;
import com.brainbyte.easy_maintenance.supplier.application.dto.BudgetRequestResponse;
import com.brainbyte.easy_maintenance.supplier.application.dto.CreateBudgetRequestRequest;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.domain.SupplierBudgetRequest;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierBudgetRequestRepository;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Fase 2 EPIC-028/decisao de escopo #4: "Solicitar Orcamento" grava o pedido (base de demanda
// real) -- o envio de fato acontece no frontend via wa.me, aqui so registra.
@Service
@RequiredArgsConstructor
public class SupplierBudgetRequestService {

    private final SupplierRepository supplierRepository;
    private final SupplierBudgetRequestRepository budgetRequestRepository;
    private final AuthenticationService authenticationService;

    @Transactional
    public BudgetRequestResponse create(Long supplierId, CreateBudgetRequestRequest request) {
        String orgCode = TenantContext.get()
                .orElseThrow(() -> new TenantException(HttpStatus.FORBIDDEN,
                        "Contexto de organização obrigatório. Informe o header X-Org-Id."));

        Supplier supplier = supplierRepository.findById(supplierId)
                .orElseThrow(() -> new NotFoundException("Fornecedor não encontrado"));

        Long userId = authenticationService.getCurrentUser().getId();

        SupplierBudgetRequest saved = budgetRequestRepository.save(SupplierBudgetRequest.builder()
                .supplierId(supplierId)
                .organizationCode(orgCode)
                .requestedByUserId(userId)
                .summary(request.summary())
                .build());

        return new BudgetRequestResponse(saved.getId(), supplier.getId(), supplier.getPhone(), saved.getSummary());
    }
}
```

- [ ] **Step 5: Rodar — deve passar**

Run: `mvn test -Dtest=SupplierBudgetRequestServiceTest`
Expected: PASS (3 testes)

- [ ] **Step 6: Endpoint no controller existente**

Adicionar em `SupplierRegistryController.java`:

```java
    private final SupplierBudgetRequestService budgetRequestService;

    @PostMapping("/{id}/budget-request")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Registra uma solicitação de orçamento pra um fornecedor")
    public BudgetRequestResponse requestBudget(@PathVariable Long id, @RequestBody @Valid CreateBudgetRequestRequest request) {
        return budgetRequestService.create(id, request);
    }
```

(Ajustar o construtor gerado por `@RequiredArgsConstructor` — já inclui `budgetRequestService`
automaticamente ao adicionar o campo `final`. Adicionar os imports de
`CreateBudgetRequestRequest`/`BudgetRequestResponse`/`SupplierBudgetRequestService`.)

- [ ] **Step 7: Rodar a suíte completa de fornecedor de novo, confirmar sem regressão**

Run: `mvn test -Dtest=Supplier*Test`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier/application/dto/CreateBudgetRequestRequest.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier/application/dto/BudgetRequestResponse.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierBudgetRequestService.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier/infrastructure/web/SupplierRegistryController.java \
  src/test/java/com/brainbyte/easy_maintenance/supplier/application/service/SupplierBudgetRequestServiceTest.java
git commit -m "feat(supplier): TASK-263 - endpoint Solicitar Orcamento (POST /suppliers/{id}/budget-request)"
```

---

## Task 5: Auto-cadastro público + cobrança PIX inicial

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/SelfRegisterSupplierRequest.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/SelfRegisterSupplierResponse.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierRegistrationService.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/web/SupplierPublicController.java`
- Modify: `src/main/resources/application.properties` (rate limit novo)
- Test: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierRegistrationServiceTest.java`

**Interfaces:**
- Consumes: `SupplierRepository.findByDocument` (Task 1), `SupplierSubscriptionRepository` (Task
  2), `AsaasClient.createCustomer`/`createPayment` (existente).
- Produces: `SupplierRegistrationService.register(SelfRegisterSupplierRequest):
  SelfRegisterSupplierResponse` — `{ supplierId, paymentLink }`. Task 6 (webhook) consome
  `SupplierSubscription` com `status=PAST_DUE` criado aqui.

- [ ] **Step 1: DTOs**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.dto;

import com.brainbyte.easy_maintenance.commons.validation.Doc;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SelfRegisterSupplierRequest(
        @NotBlank @Doc String document,
        @NotBlank @Size(max = 200) String name,
        @NotBlank @Email @Size(max = 160) String email,
        @NotBlank @Size(max = 20) String phone,
        @Size(max = 60) String category,
        @Size(max = 120) String city,
        @Size(max = 2) String state
) {}
```

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.dto;

public record SelfRegisterSupplierResponse(
        Long supplierId,
        String paymentLink
) {}
```

- [ ] **Step 2: Escrever o teste do serviço (falha primeiro)**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.infrastructure.saas.client.AsaasClient;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SelfRegisterSupplierRequest;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SelfRegisterSupplierResponse;
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
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SupplierRegistrationServiceTest {

    @Mock SupplierRepository supplierRepository;
    @Mock SupplierSubscriptionRepository subscriptionRepository;
    @Mock AsaasClient asaasClient;
    @InjectMocks SupplierRegistrationService service;

    private SelfRegisterSupplierRequest request() {
        return new SelfRegisterSupplierRequest("11222333000181", "Extintores Silva", "silva@example.com",
                "(11) 91234-5678", "EXTINTOR", "São Paulo", "SP");
    }

    @Test
    void register_newDocument_createsSupplierSubscriptionAndAsaasCharge() {
        when(supplierRepository.findByDocument("11222333000181")).thenReturn(Optional.empty());
        when(supplierRepository.save(any(Supplier.class))).thenAnswer(inv -> {
            Supplier s = inv.getArgument(0);
            s.setId(100L);
            return s;
        });
        when(asaasClient.createCustomer(any())).thenReturn(
                new AsaasDTO.CustomerResponse("cus_123", "Extintores Silva", "11222333000181", "silva@example.com"));
        when(asaasClient.createPayment(any())).thenReturn(new AsaasDTO.PaymentResponse(
                "pay_123", "cus_123", AsaasDTO.BillingType.PIX, BigDecimal.valueOf(15.99),
                LocalDate.now().plusDays(3), "PENDING", "https://asaas.com/i/pay_123", null));
        when(subscriptionRepository.save(any(SupplierSubscription.class))).thenAnswer(inv -> inv.getArgument(0));

        SelfRegisterSupplierResponse response = service.register(request());

        assertThat(response.supplierId()).isEqualTo(100L);
        assertThat(response.paymentLink()).isEqualTo("https://asaas.com/i/pay_123");

        ArgumentCaptor<AsaasDTO.CreatePaymentRequest> paymentCaptor = ArgumentCaptor.forClass(AsaasDTO.CreatePaymentRequest.class);
        verify(asaasClient).createPayment(paymentCaptor.capture());
        assertThat(paymentCaptor.getValue().externalReference()).isEqualTo("SUPPLIER-100");
        assertThat(paymentCaptor.getValue().value()).isEqualByComparingTo("15.99");
        assertThat(paymentCaptor.getValue().billingType()).isEqualTo(AsaasDTO.BillingType.PIX);

        ArgumentCaptor<SupplierSubscription> subCaptor = ArgumentCaptor.forClass(SupplierSubscription.class);
        verify(subscriptionRepository).save(subCaptor.capture());
        assertThat(subCaptor.getValue().getSupplierId()).isEqualTo(100L);
        assertThat(subCaptor.getValue().getStatus()).isEqualTo(SupplierSubscriptionStatus.PAST_DUE);
        assertThat(subCaptor.getValue().getExternalCustomerId()).isEqualTo("cus_123");
        assertThat(subCaptor.getValue().getExternalPaymentId()).isEqualTo("pay_123");
    }

    @Test
    void register_existingDocument_reusesSupplier_doesNotCreateDuplicate() {
        Supplier existing = Supplier.builder().id(50L).document("11222333000181")
                .name("Extintores Silva Original").registrationCount(2).build();
        when(supplierRepository.findByDocument("11222333000181")).thenReturn(Optional.of(existing));
        when(asaasClient.createCustomer(any())).thenReturn(
                new AsaasDTO.CustomerResponse("cus_456", "Extintores Silva", "11222333000181", "silva@example.com"));
        when(asaasClient.createPayment(any())).thenReturn(new AsaasDTO.PaymentResponse(
                "pay_456", "cus_456", AsaasDTO.BillingType.PIX, BigDecimal.valueOf(15.99),
                LocalDate.now().plusDays(3), "PENDING", "https://asaas.com/i/pay_456", null));
        when(subscriptionRepository.save(any(SupplierSubscription.class))).thenAnswer(inv -> inv.getArgument(0));

        SelfRegisterSupplierResponse response = service.register(request());

        assertThat(response.supplierId()).isEqualTo(50L);
        verify(supplierRepository, never()).save(any());

        ArgumentCaptor<AsaasDTO.CreatePaymentRequest> paymentCaptor = ArgumentCaptor.forClass(AsaasDTO.CreatePaymentRequest.class);
        verify(asaasClient).createPayment(paymentCaptor.capture());
        assertThat(paymentCaptor.getValue().externalReference()).isEqualTo("SUPPLIER-50");
    }
}
```

- [ ] **Step 3: Rodar — deve falhar (compilação)**

Run: `mvn test -Dtest=SupplierRegistrationServiceTest`
Expected: FAIL — `SupplierRegistrationService` não existe

- [ ] **Step 4: Implementar `SupplierRegistrationService`**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.infrastructure.saas.client.AsaasClient;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SelfRegisterSupplierRequest;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SelfRegisterSupplierResponse;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierSubscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDate;

// Fase 2 EPIC-028/decisao de escopo #6: so PIX no v1. Cobranca "detached" (sem assinatura nativa
// Asaas, que so existe pra cartao) -- mesmo padrao ja usado em TrialExpirationService pra
// renovacao PIX de organizacao.
@Service
@RequiredArgsConstructor
public class SupplierRegistrationService {

    private static final BigDecimal MONTHLY_PRICE = BigDecimal.valueOf(15.99);
    private static final int PIX_DUE_DAYS = 3;

    private final SupplierRepository supplierRepository;
    private final SupplierSubscriptionRepository subscriptionRepository;
    private final AsaasClient asaasClient;

    @Transactional
    public SelfRegisterSupplierResponse register(SelfRegisterSupplierRequest request) {
        Supplier supplier = supplierRepository.findByDocument(request.document())
                .orElseGet(() -> supplierRepository.save(newSupplier(request)));

        AsaasDTO.CustomerResponse customer = asaasClient.createCustomer(new AsaasDTO.CreateCustomerRequest(
                request.name(), request.document(), request.email(), request.phone(), request.phone(),
                null, null, null, null, null, null, null, null));

        LocalDate dueDate = LocalDate.now().plusDays(PIX_DUE_DAYS);
        AsaasDTO.PaymentResponse payment = asaasClient.createPayment(new AsaasDTO.CreatePaymentRequest(
                customer.id(), AsaasDTO.BillingType.PIX, MONTHLY_PRICE, dueDate,
                "Assinatura marketplace de fornecedores — Easy Maintenance",
                "SUPPLIER-" + supplier.getId()));

        subscriptionRepository.save(SupplierSubscription.builder()
                .supplierId(supplier.getId())
                .status(SupplierSubscriptionStatus.PAST_DUE)
                .externalCustomerId(customer.id())
                .externalPaymentId(payment.id())
                .currentPeriodEnd(dueDate)
                .build());

        return new SelfRegisterSupplierResponse(supplier.getId(), payment.invoiceUrl());
    }

    private Supplier newSupplier(SelfRegisterSupplierRequest request) {
        return Supplier.builder()
                .document(request.document())
                .name(request.name())
                .email(request.email())
                .phone(request.phone())
                .category(request.category())
                .city(StringUtils.hasText(request.city()) ? request.city() : null)
                .state(StringUtils.hasText(request.state()) ? request.state() : null)
                .registrationCount(0)
                .build();
    }
}
```

- [ ] **Step 5: Rodar — deve passar**

Run: `mvn test -Dtest=SupplierRegistrationServiceTest`
Expected: PASS (2 testes)

- [ ] **Step 6: Rate limit novo em `application.properties`**

```properties
rate-limit.limits.supplier-self-register.capacity=5
rate-limit.limits.supplier-self-register.refill-period-seconds=3600
rate-limit.limits.supplier-self-register.key=IP
```

- [ ] **Step 7: Controller público**

```java
package com.brainbyte.easy_maintenance.supplier_billing.infrastructure.web;

import com.brainbyte.easy_maintenance.shared.ratelimit.RateLimit;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SelfRegisterSupplierRequest;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SelfRegisterSupplierResponse;
import com.brainbyte.easy_maintenance.supplier_billing.application.service.SupplierRegistrationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@Validated
@RequestMapping("/easy-maintenance/api/v1/public/suppliers")
@Tag(name = "Fornecedores — Marketplace (Público)", description = "Auto-cadastro e gestão de fornecedor pagante")
public class SupplierPublicController {

    private final SupplierRegistrationService registrationService;

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    @RateLimit("supplier-self-register")
    @Operation(summary = "Auto-cadastro de fornecedor + geração de cobrança PIX inicial")
    public SelfRegisterSupplierResponse register(@RequestBody @Valid SelfRegisterSupplierRequest request) {
        return registrationService.register(request);
    }
}
```

- [ ] **Step 8: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/ \
  src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/web/SupplierPublicController.java \
  src/main/resources/application.properties \
  src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/
git commit -m "feat(supplier-billing): TASK-264 - auto-cadastro publico + cobranca PIX inicial"
```

---

## Task 6: Ativação via webhook (`PAYMENT_RECEIVED`, prefixo `SUPPLIER-`)

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierPaymentActivationService.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/PaymentReceivedHandler.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/infrastructure/notification/enums/NotificationEventType.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierPaymentActivationServiceTest.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/PaymentReceivedHandlerSupplierBranchTest.java`

**Interfaces:**
- Consumes: `SupplierSubscriptionRepository`/`SupplierAccessTokenRepository` (Task 2),
  `SupplierRepository` (Task 1), `CriticalEmailDispatchService`/`EmailTemplateHelper` (existentes).
- Produces: `SupplierPaymentActivationService.activateFromWebhook(AsaasDTO.PaymentObject
  paymentObj)`. Chamado por `PaymentReceivedHandler`.

- [ ] **Step 1: Novo valor no enum `NotificationEventType`**

```java
    SUPPLIER_ACTIVATION
```
(adicionar no bloco "Critical transactional emails (managed by CriticalEmailDispatchService)")

- [ ] **Step 2: Novo template de e-mail em `EmailTemplateHelper`**

Adicionar seguindo exatamente o padrão de `generateSubscriptionExpirationHtml` (mesmo arquivo):

```java
    public String generateSupplierActivationHtml(String supplierName, String manageLink) {
        return "<html><body>"
                + "<h2>Bem-vindo ao marketplace de fornecedores — Easy Maintenance</h2>"
                + "<p>Olá, " + supplierName + "!</p>"
                + "<p>Seu pagamento foi confirmado e seu cadastro já está visível pras organizações "
                + "que usam o Easy Maintenance na sua região.</p>"
                + "<p><a href=\"" + manageLink + "\">Gerenciar meu cadastro</a></p>"
                + "<p>Guarde esse link — é assim que você atualiza seus dados e acompanha sua assinatura.</p>"
                + "</body></html>";
    }
```

- [ ] **Step 3: Escrever o teste do serviço de ativação (falha primeiro)**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.infrastructure.mail.utils.EmailTemplateHelper;
import com.brainbyte.easy_maintenance.infrastructure.notification.service.CriticalEmailDispatchService;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.domain.enums.ActivationSource;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierAccessTokenRepository;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierSubscriptionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SupplierPaymentActivationServiceTest {

    @Mock SupplierSubscriptionRepository subscriptionRepository;
    @Mock SupplierAccessTokenRepository accessTokenRepository;
    @Mock SupplierRepository supplierRepository;
    @Mock CriticalEmailDispatchService emailDispatchService;
    @Mock EmailTemplateHelper emailTemplateHelper;
    @InjectMocks SupplierPaymentActivationService service;

    @Test
    void activate_pendingSubscription_activatesSupplierAndSendsEmail() {
        SupplierSubscription subscription = SupplierSubscription.builder()
                .id(1L).supplierId(100L).status(SupplierSubscriptionStatus.PAST_DUE).build();
        when(subscriptionRepository.findBySupplierId(100L)).thenReturn(Optional.of(subscription));
        Supplier supplier = Supplier.builder().id(100L).name("Extintores Silva").email("silva@example.com")
                .marketplaceEnabled(false).build();
        when(supplierRepository.findById(100L)).thenReturn(Optional.of(supplier));
        when(accessTokenRepository.findBySupplierId(100L)).thenReturn(Optional.empty());
        when(emailTemplateHelper.generateSupplierActivationHtml(anyString(), anyString())).thenReturn("<html></html>");

        service.activateFromWebhook(100L);

        verify(subscriptionRepository).save(argThat(s -> s.getStatus() == SupplierSubscriptionStatus.ACTIVE));

        ArgumentCaptor<Supplier> supplierCaptor = ArgumentCaptor.forClass(Supplier.class);
        verify(supplierRepository).save(supplierCaptor.capture());
        assertThat(supplierCaptor.getValue().isMarketplaceEnabled()).isTrue();
        assertThat(supplierCaptor.getValue().getActivationSource()).isEqualTo(ActivationSource.SELF_REGISTERED);
        assertThat(supplierCaptor.getValue().getActivatedAt()).isNotNull();

        verify(accessTokenRepository).save(argThat(t -> t.getSupplierId().equals(100L) && t.getToken().length() >= 32));
        verify(emailDispatchService).send(eq("silva@example.com"), eq("Extintores Silva"), isNull(), any(), anyString(), anyString(), eq(true));
    }

    @Test
    void activate_alreadyActive_isIdempotent_doesNotResendEmail() {
        SupplierSubscription subscription = SupplierSubscription.builder()
                .id(1L).supplierId(100L).status(SupplierSubscriptionStatus.ACTIVE).build();
        when(subscriptionRepository.findBySupplierId(100L)).thenReturn(Optional.of(subscription));

        service.activateFromWebhook(100L);

        verify(subscriptionRepository, never()).save(any());
        verifyNoInteractions(supplierRepository, accessTokenRepository, emailDispatchService);
    }

    @Test
    void activate_reusesExistingAccessToken_whenSupplierAlreadyHasOne() {
        SupplierSubscription subscription = SupplierSubscription.builder()
                .id(1L).supplierId(100L).status(SupplierSubscriptionStatus.PAST_DUE).build();
        when(subscriptionRepository.findBySupplierId(100L)).thenReturn(Optional.of(subscription));
        Supplier supplier = Supplier.builder().id(100L).name("Extintores Silva").email("silva@example.com").build();
        when(supplierRepository.findById(100L)).thenReturn(Optional.of(supplier));
        var existingToken = com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierAccessToken.builder()
                .id(1L).supplierId(100L).token("token-existente-ja-enviado").build();
        when(accessTokenRepository.findBySupplierId(100L)).thenReturn(Optional.of(existingToken));
        when(emailTemplateHelper.generateSupplierActivationHtml(anyString(), anyString())).thenReturn("<html></html>");

        service.activateFromWebhook(100L);

        verify(accessTokenRepository, never()).save(any());
    }
}
```

- [ ] **Step 4: Rodar — deve falhar (compilação)**

Run: `mvn test -Dtest=SupplierPaymentActivationServiceTest`
Expected: FAIL — classe não existe

- [ ] **Step 5: Implementar `SupplierPaymentActivationService`**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.infrastructure.mail.utils.EmailTemplateHelper;
import com.brainbyte.easy_maintenance.infrastructure.notification.enums.NotificationEventType;
import com.brainbyte.easy_maintenance.infrastructure.notification.service.CriticalEmailDispatchService;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.domain.enums.ActivationSource;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierAccessToken;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierAccessTokenRepository;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierSubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

// Fase 2 EPIC-028/TASK-256-like: chamado pelo branch novo em PaymentReceivedHandler quando o
// externalReference comeca com "SUPPLIER-". Idempotente por design (igual ao resto dos handlers
// de webhook do projeto) -- se a subscription ja esta ACTIVE, no-op.
@Slf4j
@Service
@RequiredArgsConstructor
public class SupplierPaymentActivationService {

    private final SupplierSubscriptionRepository subscriptionRepository;
    private final SupplierAccessTokenRepository accessTokenRepository;
    private final SupplierRepository supplierRepository;
    private final CriticalEmailDispatchService emailDispatchService;
    private final EmailTemplateHelper emailTemplateHelper;

    @Transactional
    public void activateFromWebhook(Long supplierId) {
        SupplierSubscription subscription = subscriptionRepository.findBySupplierId(supplierId).orElse(null);
        if (subscription == null) {
            log.warn("[SupplierBilling] Webhook de pagamento recebido pra supplierId={} sem SupplierSubscription. Ignorado.", supplierId);
            return;
        }
        if (subscription.getStatus() == SupplierSubscriptionStatus.ACTIVE) {
            log.info("[SupplierBilling] SupplierSubscription {} já ACTIVE, ignorando (idempotente).", subscription.getId());
            return;
        }

        subscription.setStatus(SupplierSubscriptionStatus.ACTIVE);
        subscription.setCurrentPeriodEnd(java.time.LocalDate.now().plusMonths(1));
        subscriptionRepository.save(subscription);

        Supplier supplier = supplierRepository.findById(supplierId).orElseThrow();
        supplier.setMarketplaceEnabled(true);
        supplier.setActivatedAt(Instant.now());
        supplier.setActivationSource(ActivationSource.SELF_REGISTERED);
        supplierRepository.save(supplier);

        SupplierAccessToken token = accessTokenRepository.findBySupplierId(supplierId)
                .orElseGet(() -> accessTokenRepository.save(SupplierAccessToken.builder()
                        .supplierId(supplierId)
                        .token(generateToken())
                        .build()));

        String manageLink = "https://www.easymaintenance.com.br/fornecedores/gerenciar/" + token.getToken();
        String html = emailTemplateHelper.generateSupplierActivationHtml(supplier.getName(), manageLink);
        emailDispatchService.send(supplier.getEmail(), supplier.getName(), null,
                NotificationEventType.SUPPLIER_ACTIVATION, "Seu cadastro no marketplace está ativo", html, true);

        log.info("[SupplierBilling] Supplier {} ativado no marketplace via webhook.", supplierId);
    }

    private String generateToken() {
        return (UUID.randomUUID().toString() + UUID.randomUUID().toString()).replace("-", "");
    }
}
```

- [ ] **Step 6: Rodar — deve passar**

Run: `mvn test -Dtest=SupplierPaymentActivationServiceTest`
Expected: PASS (3 testes)

- [ ] **Step 7: Escrever o teste do branch novo em `PaymentReceivedHandler` (falha primeiro)**

Arquivo novo `PaymentReceivedHandlerSupplierBranchTest.java`, mesmo pacote da classe. Usa
`@InjectMocks` (Mockito resolve todos os parâmetros do construtor por tipo automaticamente — mesmo
padrão já usado em `PaymentReceivedHandlerTest.java` existente, evita ter que escrever os ~14
parâmetros do construtor na mão) mais um helper local de `PaymentObject`/`WebhookCheckoutEvent`
copiado dos helpers privados já existentes nesse mesmo teste (`buildPaymentObject`/o webhook event
— campos reais conferidos em `AsaasDTO.java`: `PaymentObject` tem 21 campos posicionais,
`WebhookCheckoutEvent` tem 7):

```java
package com.brainbyte.easy_maintenance.webhooks.asaas.strategy.impl;

import com.brainbyte.easy_maintenance.affiliates.application.service.CommissionService;
import com.brainbyte.easy_maintenance.affiliates.infrastructure.persistence.AffiliateRepository;
import com.brainbyte.easy_maintenance.billing.application.service.BillingSubscriptionService;
import com.brainbyte.easy_maintenance.billing.application.service.InvoiceService;
import com.brainbyte.easy_maintenance.billing.infrastructure.persistence.*;
import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.org_users.infrastructure.persistence.OrganizationRepository;
import com.brainbyte.easy_maintenance.org_users.infrastructure.persistence.UserRepository;
import com.brainbyte.easy_maintenance.payment.infrastructure.persistence.PaymentGatewayEventRepository;
import com.brainbyte.easy_maintenance.payment.infrastructure.persistence.PaymentRepository;
import com.brainbyte.easy_maintenance.supplier_billing.application.service.SupplierPaymentActivationService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

// Teste focado só no branch novo -- o resto do comportamento de PaymentReceivedHandler (fluxo de
// organização) já está coberto por PaymentReceivedHandlerTest.java existente e não muda aqui.
@ExtendWith(MockitoExtension.class)
class PaymentReceivedHandlerSupplierBranchTest {

    @Mock private InvoiceService invoiceService;
    @Mock private PaymentRepository paymentRepository;
    @Mock private PaymentGatewayEventRepository paymentGatewayEventRepository;
    @Mock private InvoiceRepository invoiceRepository;
    @Mock private BillingAccountRepository billingAccountRepository;
    @Mock private BillingSubscriptionRepository billingSubscriptionRepository;
    @Mock private BillingSubscriptionItemRepository billingSubscriptionItemRepository;
    @Mock private InvoiceItemRepository invoiceItemRepository;
    @Mock private OrganizationRepository organizationRepository;
    @Mock private ObjectMapper objectMapper;
    @Mock private BillingSubscriptionService billingSubscriptionService;
    @Mock private CommissionService commissionService;
    @Mock private AffiliateRepository affiliateRepository;
    @Mock private UserRepository userRepository;
    @Mock private SupplierPaymentActivationService supplierPaymentActivationService;

    @InjectMocks
    private PaymentReceivedHandler handler;

    @Test
    void handle_supplierExternalReference_delegatesToActivationService_skipsOrgFlow() {
        AsaasDTO.PaymentObject paymentObj = buildSupplierPaymentObject("SUPPLIER-100");
        AsaasDTO.WebhookCheckoutEvent event = new AsaasDTO.WebhookCheckoutEvent(
                "evt-supplier-1", "PAYMENT_RECEIVED", "2026-09-11T10:00:00", null, null, paymentObj, null);

        handler.handle(event);

        verify(supplierPaymentActivationService).activateFromWebhook(100L);
        verifyNoInteractions(paymentRepository, invoiceRepository, billingSubscriptionService);
    }

    private AsaasDTO.PaymentObject buildSupplierPaymentObject(String externalReference) {
        return new AsaasDTO.PaymentObject(
                "pay_supplier_1", "cus_supplier_1", null, "RECEIVED",
                new BigDecimal("15.99"), LocalDate.now(), LocalDate.now(),
                "Assinatura marketplace de fornecedores", null, "PIX",
                externalReference, "http://invoice/url", "http://receipt/url",
                null, "inv-supplier-001", new BigDecimal("15.50"),
                LocalDate.now(), LocalDate.now(), null, null, null, null);
    }
}
```

- [ ] **Step 8: Rodar — deve falhar (construtor ainda não aceita `SupplierPaymentActivationService`)**

Run: `mvn test -Dtest=PaymentReceivedHandlerSupplierBranchTest`
Expected: FAIL na compilação

- [ ] **Step 9: Adicionar o branch e o novo parâmetro em `PaymentReceivedHandler`**

No topo de `handle()`, antes de `var paymentObj = event.payment();` continuar como está — adicionar
logo depois de obter `paymentObj`:

```java
        var paymentObj = event.payment();
        if (paymentObj != null && paymentObj.externalReference() != null
                && paymentObj.externalReference().startsWith("SUPPLIER-")) {
            Long supplierId = Long.parseLong(paymentObj.externalReference().substring("SUPPLIER-".length()));
            supplierPaymentActivationService.activateFromWebhook(supplierId);
            log.info("[AsaasWebhook] Event {}/{} finished (delegated to supplier activation, supplierId={}).",
                    event.id(), event.event(), supplierId);
            return;
        }

        if (paymentObj == null) {
```

Adicionar o campo e o parâmetro do construtor:

```java
    private final SupplierPaymentActivationService supplierPaymentActivationService;

    public PaymentReceivedHandler(/* ...parâmetros existentes... */,
                                  SupplierPaymentActivationService supplierPaymentActivationService) {
        super(/* ... */);
        /* ...atribuições existentes... */
        this.supplierPaymentActivationService = supplierPaymentActivationService;
    }
```

- [ ] **Step 10: Rodar o teste do branch novo e a suíte completa de `PaymentReceivedHandler`**

Run: `mvn test -Dtest=PaymentReceivedHandlerSupplierBranchTest,PaymentReceivedHandlerTest`
Expected: PASS em todos — o teste novo confirma o branch; os testes já existentes confirmam que o
fluxo de organização continua idêntico (nenhuma asserção deles muda).

- [ ] **Step 11: Rodar a suíte completa do backend**

Run: `mvn test`
Expected: PASS, sem regressão em nenhum módulo

- [ ] **Step 12: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierPaymentActivationService.java \
  src/main/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/PaymentReceivedHandler.java \
  src/main/java/com/brainbyte/easy_maintenance/infrastructure/notification/enums/NotificationEventType.java \
  src/main/java/com/brainbyte/easy_maintenance/infrastructure/mail/utils/EmailTemplateHelper.java \
  src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierPaymentActivationServiceTest.java \
  src/test/java/com/brainbyte/easy_maintenance/webhooks/asaas/strategy/impl/
git commit -m "feat(supplier-billing): TASK-265 - ativacao de fornecedor via webhook PAYMENT_RECEIVED"
```

---

## Task 7: Gestão do cadastro via link mágico (público)

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/SupplierManageResponse.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/UpdateSupplierProfileRequest.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierSelfManageService.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/web/SupplierPublicController.java`
- Modify: `src/main/resources/application.properties` (rate limit novo)
- Test: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierSelfManageServiceTest.java`

**Interfaces:**
- Consumes: `SupplierAccessTokenRepository.findByToken` (Task 2), `SupplierRepository` (Task 1).
- Produces: `GET /easy-maintenance/api/v1/public/suppliers/manage/{token}`,
  `PUT /easy-maintenance/api/v1/public/suppliers/manage/{token}`. Frontend Task 12 consome.

- [ ] **Step 1: DTOs**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.dto;

public record SupplierManageResponse(
        Long supplierId,
        String name,
        String phone,
        String category,
        String city,
        String state,
        boolean marketplaceEnabled,
        String subscriptionStatus
) {}
```

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.dto;

import jakarta.validation.constraints.Size;

public record UpdateSupplierProfileRequest(
        @Size(max = 20) String phone,
        @Size(max = 60) String category
) {}
```

- [ ] **Step 2: Escrever o teste do serviço (falha primeiro)**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SupplierManageResponse;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.UpdateSupplierProfileRequest;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierAccessToken;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierAccessTokenRepository;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierSubscriptionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SupplierSelfManageServiceTest {

    @Mock SupplierAccessTokenRepository accessTokenRepository;
    @Mock SupplierRepository supplierRepository;
    @Mock SupplierSubscriptionRepository subscriptionRepository;
    @InjectMocks SupplierSelfManageService service;

    @Test
    void get_validToken_returnsProfileAndSubscriptionStatus() {
        var token = SupplierAccessToken.builder().id(1L).supplierId(100L).token("abc123").build();
        when(accessTokenRepository.findByToken("abc123")).thenReturn(Optional.of(token));
        var supplier = Supplier.builder().id(100L).name("Extintores Silva").phone("(11) 91234-5678")
                .category("EXTINTOR").marketplaceEnabled(true).build();
        when(supplierRepository.findById(100L)).thenReturn(Optional.of(supplier));
        var subscription = SupplierSubscription.builder().supplierId(100L).status(SupplierSubscriptionStatus.ACTIVE).build();
        when(subscriptionRepository.findBySupplierId(100L)).thenReturn(Optional.of(subscription));

        SupplierManageResponse response = service.get("abc123");

        assertThat(response.name()).isEqualTo("Extintores Silva");
        assertThat(response.marketplaceEnabled()).isTrue();
        assertThat(response.subscriptionStatus()).isEqualTo("ACTIVE");
    }

    @Test
    void get_invalidToken_throwsNotFoundException() {
        when(accessTokenRepository.findByToken("invalido")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.get("invalido")).isInstanceOf(NotFoundException.class);
    }

    @Test
    void update_validToken_updatesPhoneAndCategory() {
        var token = SupplierAccessToken.builder().id(1L).supplierId(100L).token("abc123").build();
        when(accessTokenRepository.findByToken("abc123")).thenReturn(Optional.of(token));
        var supplier = Supplier.builder().id(100L).name("Extintores Silva").phone("(11) 90000-0000")
                .category("EXTINTOR").marketplaceEnabled(true).build();
        when(supplierRepository.findById(100L)).thenReturn(Optional.of(supplier));
        when(supplierRepository.save(any(Supplier.class))).thenAnswer(inv -> inv.getArgument(0));
        when(subscriptionRepository.findBySupplierId(100L)).thenReturn(Optional.empty());

        SupplierManageResponse response = service.update("abc123", new UpdateSupplierProfileRequest("(11) 99999-9999", "SPDA"));

        assertThat(response.phone()).isEqualTo("(11) 99999-9999");
        assertThat(response.category()).isEqualTo("SPDA");
        verify(supplierRepository).save(supplier);
    }
}
```

- [ ] **Step 3: Rodar — deve falhar (compilação)**

Run: `mvn test -Dtest=SupplierSelfManageServiceTest`
Expected: FAIL — classe não existe

- [ ] **Step 4: Implementar `SupplierSelfManageService`**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SupplierManageResponse;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.UpdateSupplierProfileRequest;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierAccessToken;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierAccessTokenRepository;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierSubscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class SupplierSelfManageService {

    private final SupplierAccessTokenRepository accessTokenRepository;
    private final SupplierRepository supplierRepository;
    private final SupplierSubscriptionRepository subscriptionRepository;

    public SupplierManageResponse get(String token) {
        Supplier supplier = resolveSupplier(token);
        return toResponse(supplier);
    }

    @Transactional
    public SupplierManageResponse update(String token, UpdateSupplierProfileRequest request) {
        Supplier supplier = resolveSupplier(token);
        if (StringUtils.hasText(request.phone())) supplier.setPhone(request.phone());
        if (StringUtils.hasText(request.category())) supplier.setCategory(request.category());
        supplierRepository.save(supplier);
        return toResponse(supplier);
    }

    private Supplier resolveSupplier(String token) {
        SupplierAccessToken accessToken = accessTokenRepository.findByToken(token)
                .orElseThrow(() -> new NotFoundException("Link inválido ou expirado"));
        return supplierRepository.findById(accessToken.getSupplierId())
                .orElseThrow(() -> new NotFoundException("Fornecedor não encontrado"));
    }

    private SupplierManageResponse toResponse(Supplier supplier) {
        String status = subscriptionRepository.findBySupplierId(supplier.getId())
                .map(s -> s.getStatus().name())
                .orElse("SEM_ASSINATURA");
        return new SupplierManageResponse(supplier.getId(), supplier.getName(), supplier.getPhone(),
                supplier.getCategory(), supplier.getCity(), supplier.getState(),
                supplier.isMarketplaceEnabled(), status);
    }
}
```

- [ ] **Step 5: Rodar — deve passar**

Run: `mvn test -Dtest=SupplierSelfManageServiceTest`
Expected: PASS (3 testes)

- [ ] **Step 6: Rate limit + endpoints no controller público**

```properties
rate-limit.limits.supplier-manage.capacity=30
rate-limit.limits.supplier-manage.refill-period-seconds=60
rate-limit.limits.supplier-manage.key=IP
```

Adicionar em `SupplierPublicController.java`:

```java
    private final SupplierSelfManageService selfManageService;

    @GetMapping("/manage/{token}")
    @RateLimit("supplier-manage")
    @Operation(summary = "Consulta o cadastro do fornecedor via link mágico")
    public SupplierManageResponse getManaged(@PathVariable String token) {
        return selfManageService.get(token);
    }

    @PutMapping("/manage/{token}")
    @RateLimit("supplier-manage")
    @Operation(summary = "Atualiza telefone/categoria do fornecedor via link mágico")
    public SupplierManageResponse updateManaged(@PathVariable String token, @RequestBody @Valid UpdateSupplierProfileRequest request) {
        return selfManageService.update(token, request);
    }
```

- [ ] **Step 7: Rodar a suíte completa e commitar**

Run: `mvn test`
Expected: PASS, sem regressão

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/SupplierManageResponse.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/UpdateSupplierProfileRequest.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierSelfManageService.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/web/SupplierPublicController.java \
  src/main/resources/application.properties \
  src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierSelfManageServiceTest.java
git commit -m "feat(supplier-billing): TASK-266 - gestao do cadastro via link magico (publico)"
```

---

## Task 8: Job mensal de cobrança + suspensão por atraso

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierBillingService.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/jobs/SupplierBillingJob.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierBillingServiceTest.java`

**Interfaces:**
- Consumes: `SupplierSubscriptionRepository.findByStatusAndCurrentPeriodEndLessThanEqual` (Task 2),
  `AsaasClient.createPayment` (existente).
- Produces: `SupplierBillingService.processDueCycles()` — chamado por `SupplierBillingJob`
  (`@Scheduled`, mesmo padrão de `DailyTrialJob`).

- [ ] **Step 1: Escrever o teste do serviço (falha primeiro)**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.infrastructure.saas.client.AsaasClient;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierSubscriptionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
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
class SupplierBillingServiceTest {

    @Mock SupplierSubscriptionRepository subscriptionRepository;
    @Mock SupplierRepository supplierRepository;
    @Mock AsaasClient asaasClient;
    @InjectMocks SupplierBillingService service;

    @Test
    void processDueCycles_activeSubscriptionDue_generatesNewPixCharge() {
        var subscription = SupplierSubscription.builder().id(1L).supplierId(100L)
                .status(SupplierSubscriptionStatus.ACTIVE).externalCustomerId("cus_123")
                .currentPeriodEnd(LocalDate.now().minusDays(1)).build();
        when(subscriptionRepository.findByStatusAndCurrentPeriodEndLessThanEqual(
                eq(SupplierSubscriptionStatus.ACTIVE), any())).thenReturn(List.of(subscription));
        when(asaasClient.createPayment(any())).thenReturn(new AsaasDTO.PaymentResponse(
                "pay_789", "cus_123", AsaasDTO.BillingType.PIX, BigDecimal.valueOf(15.99),
                LocalDate.now().plusDays(3), "PENDING", "https://asaas.com/i/pay_789", null));

        service.processDueCycles();

        verify(subscriptionRepository).save(argThat(s ->
                "pay_789".equals(s.getExternalPaymentId()) && s.getCurrentPeriodEnd().equals(LocalDate.now().plusDays(3))));
        verify(supplierRepository, never()).save(any());
    }

    @Test
    void processDueCycles_pastDueBeyondGracePeriod_disablesMarketplace() {
        var subscription = SupplierSubscription.builder().id(1L).supplierId(100L)
                .status(SupplierSubscriptionStatus.PAST_DUE)
                .currentPeriodEnd(LocalDate.now().minusDays(4)).build(); // vencido há 4 dias, prazo é 3
        when(subscriptionRepository.findByStatusAndCurrentPeriodEndLessThanEqual(
                eq(SupplierSubscriptionStatus.PAST_DUE), any())).thenReturn(List.of(subscription));
        var supplier = Supplier.builder().id(100L).marketplaceEnabled(true).build();
        when(supplierRepository.findById(100L)).thenReturn(Optional.of(supplier));

        service.suspendOverdueSubscriptions();

        verify(supplierRepository).save(argThat(s -> !s.isMarketplaceEnabled()));
        verifyNoInteractions(asaasClient);
    }
}
```

- [ ] **Step 2: Rodar — deve falhar (compilação)**

Run: `mvn test -Dtest=SupplierBillingServiceTest`
Expected: FAIL — classe não existe

- [ ] **Step 3: Implementar `SupplierBillingService`**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.infrastructure.saas.application.dto.AsaasDTO;
import com.brainbyte.easy_maintenance.infrastructure.saas.client.AsaasClient;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierSubscription;
import com.brainbyte.easy_maintenance.supplier_billing.domain.enums.SupplierSubscriptionStatus;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierSubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;

// Fase 2 EPIC-028: mesmo padrao ja usado pra renovacao PIX de organizacao (TrialExpirationService)
// -- job diario, gera cobranca nova por ciclo, marca PAST_DUE se nao pagar dentro do prazo de
// graca (3 dias, mesmo valor de billing.blocking.days-after-due, TASK-236).
@Slf4j
@Service
@RequiredArgsConstructor
public class SupplierBillingService {

    private static final BigDecimal MONTHLY_PRICE = BigDecimal.valueOf(15.99);
    private static final int PIX_DUE_DAYS = 3;
    private static final int GRACE_PERIOD_DAYS = 3;

    private final SupplierSubscriptionRepository subscriptionRepository;
    private final SupplierRepository supplierRepository;
    private final AsaasClient asaasClient;

    @Transactional
    public void processDueCycles() {
        LocalDate today = LocalDate.now();
        var due = subscriptionRepository.findByStatusAndCurrentPeriodEndLessThanEqual(
                SupplierSubscriptionStatus.ACTIVE, today);

        for (SupplierSubscription subscription : due) {
            try {
                chargeNextCycle(subscription);
            } catch (Exception e) {
                log.error("[SupplierBilling] Falha ao gerar cobrança do ciclo pra supplierId={}: {}",
                        subscription.getSupplierId(), e.getMessage(), e);
            }
        }
    }

    @Transactional
    public void suspendOverdueSubscriptions() {
        LocalDate graceThreshold = LocalDate.now().minusDays(GRACE_PERIOD_DAYS);
        var overdue = subscriptionRepository.findByStatusAndCurrentPeriodEndLessThanEqual(
                SupplierSubscriptionStatus.PAST_DUE, graceThreshold);

        for (SupplierSubscription subscription : overdue) {
            supplierRepository.findById(subscription.getSupplierId()).ifPresent(supplier -> {
                supplier.setMarketplaceEnabled(false);
                supplierRepository.save(supplier);
                log.info("[SupplierBilling] Supplier {} suspenso do marketplace por atraso além do prazo de graça.",
                        supplier.getId());
            });
        }
    }

    private void chargeNextCycle(SupplierSubscription subscription) {
        LocalDate dueDate = LocalDate.now().plusDays(PIX_DUE_DAYS);
        AsaasDTO.PaymentResponse payment = asaasClient.createPayment(new AsaasDTO.CreatePaymentRequest(
                subscription.getExternalCustomerId(), AsaasDTO.BillingType.PIX, MONTHLY_PRICE, dueDate,
                "Assinatura marketplace de fornecedores — Easy Maintenance",
                "SUPPLIER-" + subscription.getSupplierId()));

        subscription.setExternalPaymentId(payment.id());
        subscription.setCurrentPeriodEnd(dueDate);
        subscriptionRepository.save(subscription);
    }
}
```

- [ ] **Step 4: Rodar — deve passar**

Run: `mvn test -Dtest=SupplierBillingServiceTest`
Expected: PASS (2 testes)

- [ ] **Step 5: Job agendado**

```java
package com.brainbyte.easy_maintenance.jobs;

import com.brainbyte.easy_maintenance.infrastructure.observability.service.JobHealthReporter;
import com.brainbyte.easy_maintenance.supplier_billing.application.service.SupplierBillingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.javacrumbs.shedlock.spring.annotation.SchedulerLock;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class SupplierBillingJob {

    private final SupplierBillingService billingService;
    private final JobHealthReporter jobHealthReporter;

    // Executa 1x por dia às 02:15 (depois do DailyTrialJob de organização, às 01:15)
    @Scheduled(cron = "0 15 2 * * *")
    @SchedulerLock(name = "SupplierBillingJob", lockAtMostFor = "PT30M", lockAtLeastFor = "PT15M")
    public void run() {
        log.info("[SupplierBillingJob] Lock adquirido. Iniciando execução.");
        billingService.processDueCycles();
        billingService.suspendOverdueSubscriptions();
        jobHealthReporter.markSuccess("supplier_billing");
        log.info("[SupplierBillingJob] Execução concluída.");
    }
}
```

- [ ] **Step 6: Rodar a suíte completa e commitar**

Run: `mvn test`
Expected: PASS, sem regressão

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierBillingService.java \
  src/main/java/com/brainbyte/easy_maintenance/jobs/SupplierBillingJob.java \
  src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierBillingServiceTest.java
git commit -m "feat(supplier-billing): TASK-267 - job mensal de cobranca PIX + suspensao por atraso"
```

---

## Task 9: Ativação/desativação manual (admin)

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierAdminService.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/web/AdminSupplierController.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierAdminServiceTest.java`

**Interfaces:**
- Consumes: `SupplierRepository` (Task 1).
- Produces: endpoint admin `POST /private/admin/suppliers/{id}/activate` e
  `POST /private/admin/suppliers/{id}/deactivate`.

- [ ] **Step 1: Criar `SupplierAdminService` dedicado (mais simples que encaixar em outro
      serviço — responsabilidade única, ativar/desativar)**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.domain.enums.ActivationSource;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

// Fase 2 EPIC-028/decisao de escopo #2: fornecedor cadastrado por organizacao vira lead --
// equipe pode ativar manualmente apos fechar por fora, sem checkout (decisao de escopo #5 do spec).
@Service
@RequiredArgsConstructor
public class SupplierAdminService {

    private final SupplierRepository supplierRepository;

    @Transactional
    public void activateManually(Long supplierId) {
        Supplier supplier = supplierRepository.findById(supplierId)
                .orElseThrow(() -> new NotFoundException("Fornecedor não encontrado"));
        supplier.setMarketplaceEnabled(true);
        supplier.setActivatedAt(Instant.now());
        supplier.setActivationSource(ActivationSource.MANUALLY_ACTIVATED);
        supplierRepository.save(supplier);
    }

    @Transactional
    public void deactivate(Long supplierId) {
        Supplier supplier = supplierRepository.findById(supplierId)
                .orElseThrow(() -> new NotFoundException("Fornecedor não encontrado"));
        supplier.setMarketplaceEnabled(false);
        supplierRepository.save(supplier);
    }
}
```

- [ ] **Step 2: Teste do serviço**

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.supplier.domain.Supplier;
import com.brainbyte.easy_maintenance.supplier.domain.enums.ActivationSource;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SupplierAdminServiceTest {

    @Mock SupplierRepository supplierRepository;
    @InjectMocks SupplierAdminService service;

    @Test
    void activateManually_existingSupplier_enablesMarketplaceWithManualSource() {
        var supplier = Supplier.builder().id(100L).marketplaceEnabled(false).build();
        when(supplierRepository.findById(100L)).thenReturn(Optional.of(supplier));
        when(supplierRepository.save(any(Supplier.class))).thenAnswer(inv -> inv.getArgument(0));

        service.activateManually(100L);

        verify(supplierRepository).save(argThat(s ->
                s.isMarketplaceEnabled() && s.getActivationSource() == ActivationSource.MANUALLY_ACTIVATED
                        && s.getActivatedAt() != null));
    }

    @Test
    void activateManually_supplierNotFound_throwsNotFoundException() {
        when(supplierRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.activateManually(999L)).isInstanceOf(NotFoundException.class);
    }

    @Test
    void deactivate_existingSupplier_disablesMarketplace() {
        var supplier = Supplier.builder().id(100L).marketplaceEnabled(true).build();
        when(supplierRepository.findById(100L)).thenReturn(Optional.of(supplier));
        when(supplierRepository.save(any(Supplier.class))).thenAnswer(inv -> inv.getArgument(0));

        service.deactivate(100L);

        verify(supplierRepository).save(argThat(s -> !s.isMarketplaceEnabled()));
    }
}
```

- [ ] **Step 3: Rodar**

Run: `mvn test -Dtest=SupplierAdminServiceTest`
Expected: PASS (3 testes)

- [ ] **Step 4: Controller admin novo**

Mesmo padrão de `AdminLeadController.java`/`AdminBillingController.java` — plano
`@RequestMapping("/easy-maintenance/api/v1/private/admin/...")`, sem anotação de auth por método
(o filtro de admin, `BootstrapAdminFilter`/`SecurityConfig`, já intercepta qualquer rota sob
`/private/` pelo prefixo do path, exigindo `X-Admin-Token`):

```java
package com.brainbyte.easy_maintenance.supplier_billing.infrastructure.web;

import com.brainbyte.easy_maintenance.supplier_billing.application.service.SupplierAdminService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RequiredArgsConstructor
@RestController
@RequestMapping("/easy-maintenance/api/v1/private/admin/suppliers")
@Tag(name = "Fornecedores Admin", description = "Ativação/desativação manual no marketplace")
public class AdminSupplierController {

    private final SupplierAdminService supplierAdminService;

    @PostMapping("/{id}/activate")
    @Operation(summary = "Ativa manualmente um fornecedor no marketplace (sem checkout)")
    public void activate(@PathVariable Long id) {
        supplierAdminService.activateManually(id);
    }

    @PostMapping("/{id}/deactivate")
    @Operation(summary = "Desativa um fornecedor do marketplace")
    public void deactivate(@PathVariable Long id) {
        supplierAdminService.deactivate(id);
    }
}
```

- [ ] **Step 5: Rodar a suíte completa e commitar**

Run: `mvn test`
Expected: PASS, sem regressão

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierAdminService.java \
  src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/web/ \
  src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierAdminServiceTest.java
git commit -m "feat(supplier-billing): TASK-268 - ativacao/desativacao manual de fornecedor (admin)"
```

---

## Task 10: Frontend — `/fornecedores`: CPF/CNPJ + "Solicitar Orçamento"

**Files:**
- Modify: `src/app/fornecedores/page.tsx`

**Interfaces:**
- Consumes: `POST easy-maintenance/api/v1/suppliers/{id}/budget-request` (Task 4), campo
  `document` no lugar de `cnpj` (Task 1), `maskCPFCNPJ`/`isValidCPFCNPJ` de `@/lib/docMask`
  (já existentes).

- [ ] **Step 1: Trocar `cnpj` por `document` no tipo e nas chamadas de API**

```typescript
type SupplierRegistryResponse = {
  id: number;
  document: string;
  name: string;
  phone: string | null;
  category: string | null;
  city: string | null;
  state: string | null;
  registrationCount: number;
  createdAt: string;
};
```

Trocar o import `maskCNPJ, isValidCNPJ` por `maskCPFCNPJ, isValidCPFCNPJ` (de
`@/lib/docMask`, já existem prontos). No form: `EMPTY_FORM = { document: "", name: "", phone: "",
category: "" }`, `updateForm`/`handleSubmit` usando `form.document`/`documentDigits` em vez de
`form.cnpj`/`cnpjDigits`, `isValidCPFCNPJ(documentDigits)` em vez de `isValidCNPJ(cnpjDigits)`, e
no payload do `api.post` trocar `cnpj: cnpjDigits` por `document: documentDigits`. No JSX das duas
listagens (tabela desktop e cards mobile), trocar `maskCNPJ(s.cnpj)` por `maskCPFCNPJ(s.document)`,
e o campo do formulário trocar `placeholder="00.000.000/0000-00"` por
`placeholder="CPF ou CNPJ"` e `maxLength={18}` continua servindo pros dois (CNPJ formatado tem 18
caracteres, CPF formatado tem 14 — `18` já cobre ambos sem cortar).

- [ ] **Step 2: Adicionar estado e handler do modal "Solicitar Orçamento"**

```typescript
  const [budgetModalSupplier, setBudgetModalSupplier] = useState<SupplierRegistryResponse | null>(null);
  const [budgetSummary, setBudgetSummary] = useState("");
  const [budgetSubmitting, setBudgetSubmitting] = useState(false);

  async function handleBudgetRequest(e: React.FormEvent) {
    e.preventDefault();
    if (!budgetModalSupplier || !budgetSummary.trim()) return;

    setBudgetSubmitting(true);
    try {
      await api.post(`suppliers/${budgetModalSupplier.id}/budget-request`, { summary: budgetSummary.trim() });
      if (budgetModalSupplier.phone) {
        const digits = budgetModalSupplier.phone.replace(/\D/g, "");
        const message = encodeURIComponent(`Olá! Vi seu cadastro no Easy Maintenance e gostaria de um orçamento: ${budgetSummary.trim()}`);
        window.open(`https://wa.me/55${digits}?text=${message}`, "_blank");
      }
      setBudgetModalSupplier(null);
      setBudgetSummary("");
    } catch (err) {
      toast.error(mapError(err).global ?? "Erro ao solicitar orçamento.");
    } finally {
      setBudgetSubmitting(false);
    }
  }
```

- [ ] **Step 3: Botão "Solicitar Orçamento" na tabela desktop e nos cards mobile**

Na tabela desktop, adicionar uma coluna nova `"Ações"` no array de headers e uma célula por linha:

```tsx
                          <td style={{ padding: "12px 16px" }}>
                            <button
                              type="button"
                              className="btn btn-sm btn-outline-success"
                              onClick={() => setBudgetModalSupplier(s)}
                            >
                              Solicitar Orçamento
                            </button>
                          </td>
```

Nos cards mobile, dentro do card de cada fornecedor, adicionar depois da linha de
categoria/telefone/cidade:

```tsx
                      <button
                        type="button"
                        className="btn btn-sm btn-outline-success w-100 mt-2"
                        onClick={() => setBudgetModalSupplier(s)}
                      >
                        Solicitar Orçamento
                      </button>
```

- [ ] **Step 4: Modal de "Solicitar Orçamento"**

Adicionar antes do `</section>` final:

```tsx
        {budgetModalSupplier && (
          <div
            className="position-fixed top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center"
            style={{ backgroundColor: "rgba(15,23,42,0.5)", zIndex: 1050 }}
            role="dialog"
            aria-modal="true"
          >
            <div className="card border-0 shadow-lg" style={{ borderRadius: 12, width: "min(420px, 92vw)" }}>
              <div className="card-body p-4">
                <h6 className="fw-bold mb-3">Solicitar orçamento — {budgetModalSupplier.name}</h6>
                <form onSubmit={handleBudgetRequest}>
                  <div className="mb-3">
                    <label className="form-label small fw-semibold">O que você precisa?</label>
                    <textarea
                      className="form-control"
                      rows={3}
                      value={budgetSummary}
                      onChange={(e) => setBudgetSummary(e.target.value)}
                      placeholder="Ex: recarga de 5 extintores até o fim do mês"
                      required
                    />
                  </div>
                  <div className="d-flex justify-content-end gap-2">
                    <button type="button" className="btn btn-outline-secondary btn-sm" onClick={() => setBudgetModalSupplier(null)} disabled={budgetSubmitting}>
                      Cancelar
                    </button>
                    <button type="submit" className="btn btn-primary btn-sm" disabled={budgetSubmitting || !budgetSummary.trim()}>
                      {budgetSubmitting ? "Enviando..." : "Enviar e abrir WhatsApp"}
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        )}
```

- [ ] **Step 5: `npm run build` + `npx eslint`**

Run: `npm run build && npx eslint src/app/fornecedores/page.tsx`
Expected: build limpo, eslint sem erro novo

- [ ] **Step 6: Commit**

```bash
git add src/app/fornecedores/page.tsx
git commit -m "feat(fornecedores): TASK-269 - CPF/CNPJ + botao Solicitar Orcamento"
```

---

## Task 11: Frontend — página pública de auto-cadastro

**Files:**
- Create: `src/app/fornecedores/cadastro/page.tsx`
- Create: `src/app/fornecedores/cadastro/_lib/publicSupplierApi.ts`

**Interfaces:**
- Consumes: `POST easy-maintenance/api/v1/public/suppliers/register` (Task 5).

- [ ] **Step 1: Cliente de API público** (mesmo padrão de `chamados/[orgCode]/_lib/publicApi.ts`)

```typescript
// src/app/fornecedores/cadastro/_lib/publicSupplierApi.ts
import axios from "axios";
import { ENV } from "@/lib/env";

// Auto-cadastro de fornecedor (Fase 2 EPIC-028) -- deliberadamente isolado do `api` compartilhado,
// mesmo espírito do publicApi.ts do fluxo de chamados de moradores (EPIC-027): sem X-Org-Id, sem
// cookie, sem redirect em 401/403.
function buildApiBaseURL() {
  const rawBase = (ENV.API_BASE_URL || "").replace(/\/+$/, "");
  let rawPath = (ENV.API_BASE_PATH || "").trim();
  if (!rawPath) rawPath = "/";
  rawPath = `/${rawPath.replace(/^\/+/, "").replace(/\/+$/, "")}`;
  if (!rawBase) return rawPath;
  return `${rawBase}${rawPath}`;
}

export const publicSupplierApi = axios.create({
  baseURL: buildApiBaseURL(),
  withCredentials: false,
});

export interface SelfRegisterPayload {
  document: string;
  name: string;
  email: string;
  phone: string;
  category?: string;
  city?: string;
  state?: string;
}

export interface SelfRegisterResponse {
  supplierId: number;
  paymentLink: string;
}

export async function registerSupplier(payload: SelfRegisterPayload): Promise<SelfRegisterResponse> {
  const { data } = await publicSupplierApi.post<SelfRegisterResponse>("public/suppliers/register", payload);
  return data;
}
```

- [ ] **Step 2: Página de cadastro**

```tsx
// src/app/fornecedores/cadastro/page.tsx
"use client";

import { useState } from "react";
import toast from "react-hot-toast";
import { maskCPFCNPJ, isValidCPFCNPJ } from "@/lib/docMask";
import { maskBRPhoneInput } from "@/lib/phoneMask";
import { registerSupplier, SelfRegisterResponse } from "./_lib/publicSupplierApi";

const EMPTY_FORM = { document: "", name: "", email: "", phone: "", category: "" };

export default function SupplierSelfRegisterPage() {
  const [form, setForm] = useState(EMPTY_FORM);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<SelfRegisterResponse | null>(null);

  function updateForm(field: keyof typeof EMPTY_FORM, value: string) {
    setForm((prev) => ({ ...prev, [field]: value }));
    setFieldErrors((prev) => ({ ...prev, [field]: "" }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const documentDigits = form.document.replace(/\D/g, "");
    const errors: Record<string, string> = {};
    if (!isValidCPFCNPJ(documentDigits)) errors.document = "CPF ou CNPJ inválido. Verifique os dígitos.";
    if (!form.name.trim()) errors.name = "Nome é obrigatório.";
    if (!form.email.trim()) errors.email = "E-mail é obrigatório.";
    if (!form.phone.trim()) errors.phone = "Telefone é obrigatório.";
    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors);
      return;
    }

    setSubmitting(true);
    try {
      const response = await registerSupplier({
        document: documentDigits,
        name: form.name.trim(),
        email: form.email.trim(),
        phone: form.phone,
        category: form.category || undefined,
      });
      setResult(response);
    } catch {
      toast.error("Erro ao cadastrar. Verifique os dados e tente novamente.");
    } finally {
      setSubmitting(false);
    }
  }

  if (result) {
    return (
      <section className="d-flex align-items-center justify-content-center" style={{ minHeight: "100vh", backgroundColor: "#f8f9fa" }}>
        <div className="card border-0 shadow-sm p-4" style={{ maxWidth: 440, borderRadius: 12 }}>
          <h5 className="fw-bold mb-3">Quase lá!</h5>
          <p className="text-muted" style={{ fontSize: "0.9rem" }}>
            Pague a cobrança PIX abaixo pra ativar seu cadastro. Assim que confirmado, você recebe
            por e-mail o link pra gerenciar seu perfil.
          </p>
          <a href={result.paymentLink} target="_blank" rel="noopener noreferrer" className="btn btn-primary">
            Pagar assinatura (R$ 15,99/mês)
          </a>
        </div>
      </section>
    );
  }

  return (
    <section className="d-flex align-items-center justify-content-center py-5" style={{ minHeight: "100vh", backgroundColor: "#f8f9fa" }}>
      <div className="card border-0 shadow-sm p-4" style={{ maxWidth: 480, width: "100%", borderRadius: 12 }}>
        <h5 className="fw-bold mb-1">Cadastre-se no marketplace de fornecedores</h5>
        <p className="text-muted mb-3" style={{ fontSize: "0.85rem" }}>
          R$ 15,99/mês pra aparecer pras organizações que usam o Easy Maintenance na sua região.
        </p>
        <form onSubmit={handleSubmit} noValidate>
          <div className="mb-2">
            <label className="form-label small fw-semibold">CPF ou CNPJ</label>
            <input
              className={`form-control ${fieldErrors.document ? "is-invalid" : ""}`}
              value={form.document}
              onChange={(e) => updateForm("document", maskCPFCNPJ(e.target.value))}
              placeholder="CPF ou CNPJ"
              disabled={submitting}
            />
            {fieldErrors.document && <div className="invalid-feedback">{fieldErrors.document}</div>}
          </div>
          <div className="mb-2">
            <label className="form-label small fw-semibold">Nome / razão social</label>
            <input
              className={`form-control ${fieldErrors.name ? "is-invalid" : ""}`}
              value={form.name}
              onChange={(e) => updateForm("name", e.target.value)}
              disabled={submitting}
            />
            {fieldErrors.name && <div className="invalid-feedback">{fieldErrors.name}</div>}
          </div>
          <div className="mb-2">
            <label className="form-label small fw-semibold">E-mail</label>
            <input
              type="email"
              className={`form-control ${fieldErrors.email ? "is-invalid" : ""}`}
              value={form.email}
              onChange={(e) => updateForm("email", e.target.value)}
              disabled={submitting}
            />
            {fieldErrors.email && <div className="invalid-feedback">{fieldErrors.email}</div>}
          </div>
          <div className="mb-2">
            <label className="form-label small fw-semibold">Telefone (WhatsApp)</label>
            <input
              className={`form-control ${fieldErrors.phone ? "is-invalid" : ""}`}
              value={form.phone}
              onChange={(e) => updateForm("phone", maskBRPhoneInput(e.target.value))}
              placeholder="(11) 91234-5678"
              disabled={submitting}
            />
            {fieldErrors.phone && <div className="invalid-feedback">{fieldErrors.phone}</div>}
          </div>
          <div className="mb-3">
            <label className="form-label small fw-semibold">Categoria</label>
            <input
              className="form-control"
              value={form.category}
              onChange={(e) => updateForm("category", e.target.value.toUpperCase())}
              placeholder="EXTINTOR, SPDA…"
              disabled={submitting}
            />
          </div>
          <button className="btn btn-primary w-100" type="submit" disabled={submitting}>
            {submitting ? "Cadastrando..." : "Continuar pro pagamento"}
          </button>
        </form>
      </div>
    </section>
  );
}
```

- [ ] **Step 2: `npm run build` + `npx eslint`**

Run: `npm run build && npx eslint src/app/fornecedores/cadastro/`
Expected: build limpo, sem erro novo

- [ ] **Step 3: Commit**

```bash
git add src/app/fornecedores/cadastro/
git commit -m "feat(fornecedores): TASK-270 - pagina publica de auto-cadastro de fornecedor"
```

---

## Task 12: Frontend — página pública de gestão via link mágico

**Files:**
- Create: `src/app/fornecedores/gerenciar/[token]/page.tsx`
- Modify: `src/app/fornecedores/cadastro/_lib/publicSupplierApi.ts` (adicionar `getManaged`/`updateManaged`)

**Interfaces:**
- Consumes: `GET`/`PUT easy-maintenance/api/v1/public/suppliers/manage/{token}` (Task 7).

- [ ] **Step 1: Adicionar funções no cliente de API público**

```typescript
export interface SupplierManageResponse {
  supplierId: number;
  name: string;
  phone: string | null;
  category: string | null;
  city: string | null;
  state: string | null;
  marketplaceEnabled: boolean;
  subscriptionStatus: string;
}

export async function getManagedSupplier(token: string): Promise<SupplierManageResponse> {
  const { data } = await publicSupplierApi.get<SupplierManageResponse>(`public/suppliers/manage/${token}`);
  return data;
}

export async function updateManagedSupplier(
  token: string,
  payload: { phone?: string; category?: string }
): Promise<SupplierManageResponse> {
  const { data } = await publicSupplierApi.put<SupplierManageResponse>(`public/suppliers/manage/${token}`, payload);
  return data;
}
```

- [ ] **Step 2: Página de gestão**

```tsx
// src/app/fornecedores/gerenciar/[token]/page.tsx
"use client";

import { use, useEffect, useState } from "react";
import toast from "react-hot-toast";
import { maskBRPhoneInput } from "@/lib/phoneMask";
import {
  getManagedSupplier,
  updateManagedSupplier,
  SupplierManageResponse,
} from "../../cadastro/_lib/publicSupplierApi";

const STATUS_LABEL: Record<string, string> = {
  ACTIVE: "Ativa",
  PAST_DUE: "Pagamento pendente",
  CANCELED: "Cancelada",
  SEM_ASSINATURA: "Sem assinatura",
};

export default function SupplierManagePage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = use(params);
  const [data, setData] = useState<SupplierManageResponse | null>(null);
  const [phone, setPhone] = useState("");
  const [category, setCategory] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(false);

  useEffect(() => {
    getManagedSupplier(token)
      .then((res) => {
        setData(res);
        setPhone(res.phone ?? "");
        setCategory(res.category ?? "");
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, [token]);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    try {
      const updated = await updateManagedSupplier(token, { phone, category });
      setData(updated);
      toast.success("Dados atualizados!");
    } catch {
      toast.error("Não foi possível salvar. Tente novamente.");
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <p className="p-4 text-center">Carregando…</p>;
  if (error || !data) return <p className="p-4 text-center text-danger">Link inválido ou expirado.</p>;

  return (
    <section className="d-flex align-items-center justify-content-center py-5" style={{ minHeight: "100vh", backgroundColor: "#f8f9fa" }}>
      <div className="card border-0 shadow-sm p-4" style={{ maxWidth: 480, width: "100%", borderRadius: 12 }}>
        <h5 className="fw-bold mb-1">{data.name}</h5>
        <p className="mb-3" style={{ fontSize: "0.85rem" }}>
          <span className={`badge rounded-pill ${data.marketplaceEnabled ? "bg-success" : "bg-secondary"}`}>
            {data.marketplaceEnabled ? "Visível no marketplace" : "Não visível"}
          </span>{" "}
          <span className="text-muted">— Assinatura: {STATUS_LABEL[data.subscriptionStatus] ?? data.subscriptionStatus}</span>
        </p>
        <form onSubmit={handleSave}>
          <div className="mb-2">
            <label className="form-label small fw-semibold">Telefone (WhatsApp)</label>
            <input
              className="form-control"
              value={phone}
              onChange={(e) => setPhone(maskBRPhoneInput(e.target.value))}
              disabled={saving}
            />
          </div>
          <div className="mb-3">
            <label className="form-label small fw-semibold">Categoria</label>
            <input
              className="form-control"
              value={category}
              onChange={(e) => setCategory(e.target.value.toUpperCase())}
              disabled={saving}
            />
          </div>
          <button className="btn btn-primary w-100" type="submit" disabled={saving}>
            {saving ? "Salvando..." : "Salvar alterações"}
          </button>
        </form>
      </div>
    </section>
  );
}
```

- [ ] **Step 3: `npm run build` + `npx eslint`**

Run: `npm run build && npx eslint src/app/fornecedores/gerenciar/`
Expected: build limpo, sem erro novo

- [ ] **Step 4: Commit**

```bash
git add src/app/fornecedores/gerenciar/ src/app/fornecedores/cadastro/_lib/publicSupplierApi.ts
git commit -m "feat(fornecedores): TASK-271 - pagina publica de gestao via link magico"
```

---

## Self-Review

**Cobertura do spec:**
- Fluxo 1 (auto-cadastro) → Task 5 (backend) + Task 11 (frontend). ✅
- Fluxo 2 (cobrança recorrente + grace period) → Task 8. ✅
- Fluxo 3 (busca gateada) → Task 3. ✅
- Fluxo 4 (Solicitar Orçamento) → Task 4 (backend) + Task 10 (frontend). ✅
- Fluxo 5 (ativação/desativação manual) → Task 9. ✅
- Fluxo 6 (gestão via link mágico) → Task 7 (backend) + Task 12 (frontend). ✅
- Decisão #3 (CPF/CNPJ) → Task 1. ✅
- Decisão #5 (domínio isolado) → Task 2 (tabelas próprias) + Task 6 (branch mínimo em
  `PaymentReceivedHandler`, documentado como a única exceção nos Global Constraints). ✅
- Risco "job precisa ser idempotente desde o desenho" → `SupplierBillingService.processDueCycles`
  usa o `external_payment_id` mais recente por ciclo (não duplica cobrança dentro do mesmo dia
  porque só processa quem `currentPeriodEnd <= hoje`, e o próprio `save` avança
  `currentPeriodEnd` antes de qualquer reprocessamento possível no mesmo dia).

**Placeholder scan:** A primeira versão desta plan tinha 3 notas de "conferir contra o código real
antes de codar" (assinatura de `CreateCustomerRequest` no Task 5; `PaymentObject`/
`WebhookCheckoutEvent` no Task 6; path do controller admin no Task 9) — resolvidas nesta revisão,
lendo `AsaasDTO.java` e `AdminLeadController.java` de verdade: `CreateCustomerRequest` tem 13
campos (não 11, corrigido no Task 5); `PaymentObject` tem 21 campos e `WebhookCheckoutEvent` tem 7
(o teste do Task 6 foi reescrito usando `@InjectMocks`, mesmo padrão do
`PaymentReceivedHandlerTest.java` já existente, em vez do factory manual que a primeira versão
propunha); o controller admin segue exatamente `AdminLeadController.java`
(`/private/admin/<recurso>`, sem anotação de auth por método — o filtro de admin intercepta pelo
prefixo do path). Nenhum placeholder restante.

**Consistência de tipos:** `Supplier.document`/`getDocument()` usado de forma consistente em Tasks
1, 3, 5, 6, 9. `SupplierSubscriptionStatus` (ACTIVE/PAST_DUE/CANCELED) usado de forma consistente
em Tasks 2, 6, 8. `externalReference = "SUPPLIER-" + supplierId` gerado em Task 5 e Task 8 (mesmo
formato) e consumido em Task 6 (mesmo parse).

**Escopo:** 12 tasks, backend-pesado (9) + frontend (3 páginas + 1 modificação). Cabe numa branch
única, mesmo padrão já usado nesta sessão pros épicos anteriores (EPIC-028/029/030) — não precisa
de decomposição em specs separados.
