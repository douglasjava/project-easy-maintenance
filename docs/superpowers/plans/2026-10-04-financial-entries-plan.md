# EPIC-032 — Controle Financeiro Simples por Organização — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar ao síndico um livro-caixa simples por organização — lançar receitas e despesas não ligadas a manutenção, e ver isso combinado com o custo de manutenção (já automático) como um saldo real na Prestação de Contas.

**Architecture:** Módulo backend novo `finance` (domain/application/infrastructure, mesmo padrão de `billing`/`assets`/`supplier`), com uma única entidade (`FinancialEntry`) e endpoints REST sob `/easy-maintenance/api/v1/finance`. Frontend ganha uma tela nova (`/financeiro`) e integra o resumo na `PrestacaoContasSection`/PDF já existentes. Zero mudança em `Maintenance`/`MaintenanceItem` — o custo de manutenção continua exatamente como é hoje, só é somado ao lado dos lançamentos novos num endpoint de resumo.

**Tech Stack:** Spring Boot 3 / Java 21 / Hibernate / MySQL (prod) + H2 (`@DataJpaTest`) / Flyway / JUnit 5 + Mockito + AssertJ (backend). Next.js / React / TypeScript / Bootstrap classes / `@react-pdf/renderer` (frontend). Playwright (e2e).

**Spec:** `docs/superpowers/specs/2026-10-04-financial-entries-design.md` — este plano implementa essa spec; leia os dois juntos. Uma correção de nomenclatura feita neste plano em relação à spec: os campos de cancelamento usam a grafia `cancelled*` (duplo L), não `canceled*`, para bater com a convenção já estabelecida em `Maintenance` (`cancelledAt`/`cancelledBy`/`cancelReason`). Outra correção: os erros de validação de negócio (categoria incompatível, valor inválido, data futura) retornam **400** via `RuleException` — não 422 como a spec sugeria — porque é isso que `GlobalExceptionHandler` já faz para `RuleException` em todo o resto do projeto (ex.: `PaymentMethodTransitionService`).

## Global Constraints

- Tenant scoping: `organizationCode` explícito em toda query/método de serviço, vindo de `TenantContext.get().orElseThrow()` no controller — **não** existe filtro automático de Hibernate pra este módulo (o aspecto `TenantFilterAspect` é hard-coded só pra `MaintenanceItemRepository`; todo o resto do projeto, incluindo este módulo novo, passa `orgId` explicitamente, como `MaintenanceRepository` já faz).
- Toda rota do `FinancialEntryController` leva `@RequireTenant` (TASK-320 fez essa anotação valer de verdade via interceptor).
- Permissão de criar/cancelar: `Role.ADMIN` ou `Role.SYNDIC` apenas (enum real tem 4 valores: `ADMIN, SYNDIC, TECH, READER` — não existe `MEMBER`/`VIEWER`). Leitura (listar/resumo) é liberada pra qualquer papel autenticado da organização.
- Lançamento nunca é editado — só cancelado (soft-delete via `@SQLDelete`/`@SQLRestriction`, motivo obrigatório) e um novo é criado.
- Sem gate de plano de billing (`BillingPlanFeatures`) nesta v1 — liberado pra todas as organizações.
- Categoria é validada contra o tipo (`REVENUE`/`EXPENSE`) no service, nunca confiando só no enum vir "certo" do cliente.

## Review Focus

- **Lançamento com valor zero ou negativo** — `amountCents <= 0` precisa ser rejeitado antes de persistir (402/400), não silenciosamente salvo como lançamento "de graça". Testado no Task 2.
- **Categoria de receita usada num lançamento de despesa (e vice-versa)** — ex.: `type=EXPENSE` com `category=TAXA_CONDOMINIAL`. Sem essa checagem cruzada, o saldo fica com sinal errado sem nenhum erro visível. Testado no Task 2.
- **Cancelar o mesmo lançamento duas vezes** — segunda chamada precisa dar 409, não 200 silencioso nem erro genérico 500 (o soft-delete faria o `findById` simplesmente não achar mais, que sem o cuidado de `resolveCancelNotFoundOrConflict` viraria 404 incorretamente). Testado no Task 2.
- **Lançamento de uma organização aparecendo pra outra** — todo método precisa filtrar por `organizationCode`; um teste específico prova isolamento (não é suficiente confiar que "ninguém vai esquecer o WHERE"). Testado nos Tasks 1 e 2.
- **Organização sem nenhum `FinancialEntry` lançado** — a Prestação de Contas não pode quebrar nem mostrar `NaN`/`undefined`; precisa degradar pra "Receitas: R$ 0,00" e saldo = só despesa de manutenção, exatamente como hoje. Testado no Task 5.

---

## Task 1: Domain, Migration e Repository (`finance` module — camada de dados)

**Files:**
- Create: `easy-maintenance-api/src/main/resources/db/migration/V122__create_financial_entries.sql`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/domain/enums/FinancialEntryType.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/domain/enums/FinancialEntryCategory.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/domain/FinancialEntry.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/infrastructure/persistence/FinancialEntryRepository.java`
- Test: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/finance/infrastructure/persistence/FinancialEntryPersistenceTest.java`

**Interfaces:**
- Produces: `FinancialEntry` (entity, fields: `id, organizationCode, type, category, amountCents, description, entryDate, createdBy, createdAt, deletedAt, cancelledAt, cancelledBy, cancelReason`), `FinancialEntryType{REVENUE,EXPENSE}`, `FinancialEntryCategory{...}.getType(): FinancialEntryType`, `FinancialEntryRepository.findByOrgAndPeriod(String orgCode, LocalDate start, LocalDate end, FinancialEntryType type, Pageable pageable): Page<FinancialEntry>`, `FinancialEntryRepository.sumAmountByOrgAndTypeAndPeriod(String orgCode, FinancialEntryType type, LocalDate start, LocalDate end): long`, `FinancialEntryRepository.existsCancelledByIdAndOrgCode(Long id, String orgCode): boolean`.

- [ ] **Step 1: Write the failing persistence test**

Create `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/finance/infrastructure/persistence/FinancialEntryPersistenceTest.java`:

```java
package com.brainbyte.easy_maintenance.finance.infrastructure.persistence;

import com.brainbyte.easy_maintenance.finance.domain.FinancialEntry;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryCategory;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.test.context.TestPropertySource;

import java.time.Instant;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

// Mesmo padrão de MaintenanceCancelPersistenceTest: @DataJpaTest com H2 real, escopo restrito a
// este módulo (senão o contexto tenta validar as JPQL de todos os repositórios da aplicação).
@DataJpaTest
@EntityScan(basePackageClasses = FinancialEntry.class)
@EnableJpaRepositories(basePackageClasses = FinancialEntryRepository.class)
@TestPropertySource(properties = {
        "spring.flyway.enabled=false",
        "spring.jpa.hibernate.ddl-auto=create-drop"
})
class FinancialEntryPersistenceTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private FinancialEntryRepository repository;

    private FinancialEntry entry(String orgCode, FinancialEntryType type, FinancialEntryCategory category,
                                  int amountCents, LocalDate entryDate) {
        return FinancialEntry.builder()
                .organizationCode(orgCode)
                .type(type)
                .category(category)
                .amountCents(amountCents)
                .entryDate(entryDate)
                .createdBy(1L)
                .build();
    }

    @Test
    void cancel_persistsReasonAuthorAndTimestamp_thenHidesFromNormalQueries() {
        FinancialEntry saved = entityManager.persistAndFlush(
                entry("ORG-A", FinancialEntryType.REVENUE, FinancialEntryCategory.TAXA_CONDOMINIAL,
                        50000, LocalDate.now()));
        Long id = saved.getId();

        saved.setCancelledAt(Instant.now());
        saved.setCancelledBy(42L);
        saved.setCancelReason("Lançado em duplicidade");
        repository.saveAndFlush(saved);
        repository.delete(saved);

        entityManager.flush();
        entityManager.clear();

        EntityManager em = entityManager.getEntityManager();
        Object[] row = (Object[]) em.createNativeQuery(
                        "SELECT deleted_at, cancelled_at, cancelled_by, cancel_reason FROM financial_entries WHERE id = ?1")
                .setParameter(1, id)
                .getSingleResult();

        assertThat(row[0]).as("deleted_at deveria estar preenchido (soft-delete)").isNotNull();
        assertThat(row[1]).as("cancelled_at deveria ter sido persistido").isNotNull();
        assertThat(row[2]).as("cancelled_by deveria ter sido persistido").isNotNull();
        assertThat(row[3]).isEqualTo("Lançado em duplicidade");

        assertThat(repository.findById(id))
                .as("@SQLRestriction deveria esconder o lançamento cancelado de qualquer busca normal")
                .isEmpty();
    }

    @Test
    void existsCancelledByIdAndOrgCode_trueOnlyForCancelledEntryOfThatOrg() {
        FinancialEntry saved = entityManager.persistAndFlush(
                entry("ORG-A", FinancialEntryType.EXPENSE, FinancialEntryCategory.CONTA_CONSUMO,
                        12000, LocalDate.now()));
        Long id = saved.getId();

        assertThat(repository.existsCancelledByIdAndOrgCode(id, "ORG-A"))
                .as("ainda não foi cancelado")
                .isFalse();

        saved.setCancelledAt(Instant.now());
        saved.setCancelledBy(1L);
        saved.setCancelReason("teste");
        repository.saveAndFlush(saved);
        repository.delete(saved);
        entityManager.flush();
        entityManager.clear();

        assertThat(repository.existsCancelledByIdAndOrgCode(id, "ORG-A")).isTrue();
        assertThat(repository.existsCancelledByIdAndOrgCode(id, "ORG-B"))
                .as("não pode vazar existência pra outra organização")
                .isFalse();
    }

    @Test
    void findByOrgAndPeriod_isolatesByOrganizationAndRespectsTypeFilter() {
        entityManager.persistAndFlush(entry("ORG-A", FinancialEntryType.REVENUE,
                FinancialEntryCategory.TAXA_CONDOMINIAL, 50000, LocalDate.of(2026, 10, 5)));
        entityManager.persistAndFlush(entry("ORG-A", FinancialEntryType.EXPENSE,
                FinancialEntryCategory.CONTA_CONSUMO, 8000, LocalDate.of(2026, 10, 6)));
        entityManager.persistAndFlush(entry("ORG-B", FinancialEntryType.REVENUE,
                FinancialEntryCategory.TAXA_CONDOMINIAL, 50000, LocalDate.of(2026, 10, 5)));
        entityManager.persistAndFlush(entry("ORG-A", FinancialEntryType.REVENUE,
                FinancialEntryCategory.MULTA, 1000, LocalDate.of(2026, 1, 1))); // fora do período
        entityManager.clear();

        var page = repository.findByOrgAndPeriod("ORG-A",
                LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 31), null, PageRequest.of(0, 10));

        assertThat(page.getContent())
                .as("só os 2 lançamentos de ORG-A dentro do período")
                .hasSize(2);

        var revenueOnly = repository.findByOrgAndPeriod("ORG-A",
                LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 31), FinancialEntryType.REVENUE, PageRequest.of(0, 10));
        assertThat(revenueOnly.getContent()).hasSize(1);
        assertThat(revenueOnly.getContent().getFirst().getCategory()).isEqualTo(FinancialEntryCategory.TAXA_CONDOMINIAL);
    }

    @Test
    void sumAmountByOrgAndTypeAndPeriod_excludesCancelledAndOtherOrgs() {
        entityManager.persistAndFlush(entry("ORG-A", FinancialEntryType.EXPENSE,
                FinancialEntryCategory.FOLHA_PAGAMENTO, 100000, LocalDate.of(2026, 10, 10)));
        FinancialEntry cancelled = entityManager.persistAndFlush(entry("ORG-A", FinancialEntryType.EXPENSE,
                FinancialEntryCategory.FOLHA_PAGAMENTO, 999900, LocalDate.of(2026, 10, 11)));
        entityManager.persistAndFlush(entry("ORG-B", FinancialEntryType.EXPENSE,
                FinancialEntryCategory.FOLHA_PAGAMENTO, 50000, LocalDate.of(2026, 10, 10)));

        cancelled.setCancelledAt(Instant.now());
        cancelled.setCancelledBy(1L);
        cancelled.setCancelReason("teste");
        repository.saveAndFlush(cancelled);
        repository.delete(cancelled);
        entityManager.flush();
        entityManager.clear();

        long sum = repository.sumAmountByOrgAndTypeAndPeriod("ORG-A", FinancialEntryType.EXPENSE,
                LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 31));

        assertThat(sum)
                .as("deveria somar só o lançamento ativo de ORG-A (100000), ignorando o cancelado e o de ORG-B")
                .isEqualTo(100000L);
    }

    @Test
    void sumAmountByOrgAndTypeAndPeriod_returnsZero_whenNoEntries() {
        long sum = repository.sumAmountByOrgAndTypeAndPeriod("ORG-EMPTY", FinancialEntryType.REVENUE,
                LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 31));

        assertThat(sum).isZero();
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd easy-maintenance-api && mvn -o test -Dtest=FinancialEntryPersistenceTest`
Expected: FAIL — compile error, `FinancialEntry`/`FinancialEntryRepository`/`FinancialEntryType`/`FinancialEntryCategory` não existem ainda.

- [ ] **Step 3: Create `FinancialEntryType`**

Create `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/domain/enums/FinancialEntryType.java`:

```java
package com.brainbyte.easy_maintenance.finance.domain.enums;

public enum FinancialEntryType {
    REVENUE,
    EXPENSE
}
```

- [ ] **Step 4: Create `FinancialEntryCategory`**

Create `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/domain/enums/FinancialEntryCategory.java`:

```java
package com.brainbyte.easy_maintenance.finance.domain.enums;

// EPIC-032: categoria fixa e definida pelo backend (não customizável pelo usuário nesta v1).
// Cada categoria já carrega o tipo a que pertence -- é isso que o service usa pra validar que
// "TAXA_CONDOMINIAL" nunca seja usada num lançamento EXPENSE, por exemplo.
public enum FinancialEntryCategory {
    TAXA_CONDOMINIAL(FinancialEntryType.REVENUE),
    MULTA(FinancialEntryType.REVENUE),
    ALUGUEL_ESPACO(FinancialEntryType.REVENUE),
    OUTRAS_RECEITAS(FinancialEntryType.REVENUE),

    FOLHA_PAGAMENTO(FinancialEntryType.EXPENSE),
    CONTA_CONSUMO(FinancialEntryType.EXPENSE),
    SERVICO_TERCEIRO(FinancialEntryType.EXPENSE),
    OUTRAS_DESPESAS(FinancialEntryType.EXPENSE);

    private final FinancialEntryType type;

    FinancialEntryCategory(FinancialEntryType type) {
        this.type = type;
    }

    public FinancialEntryType getType() {
        return type;
    }
}
```

- [ ] **Step 5: Create the migration**

Create `easy-maintenance-api/src/main/resources/db/migration/V122__create_financial_entries.sql`:

```sql
-- EPIC-032: lançamentos financeiros manuais (receita/despesa) por organização. Custo de manutenção
-- continua exclusivamente em `maintenances.cost_cents` -- nunca duplicado aqui.
CREATE TABLE financial_entries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    organization_code VARCHAR(255) NOT NULL,
    type VARCHAR(20) NOT NULL,
    category VARCHAR(40) NOT NULL,
    amount_cents INT NOT NULL,
    description VARCHAR(500),
    entry_date DATE NOT NULL,
    created_by BIGINT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    deleted_at DATETIME(6),
    cancelled_at DATETIME(6),
    cancelled_by BIGINT,
    cancel_reason VARCHAR(1000)
);

CREATE INDEX idx_financial_entries_org_period ON financial_entries (organization_code, entry_date);
```

- [ ] **Step 6: Create the `FinancialEntry` entity**

Create `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/domain/FinancialEntry.java`:

```java
package com.brainbyte.easy_maintenance.finance.domain;

import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryCategory;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;

import java.time.Instant;
import java.time.LocalDate;

// EPIC-032: nunca editado depois de criado -- só cancelado (soft-delete via @SQLDelete, motivo
// obrigatório) e um novo lançamento é feito pra corrigir. Mesmo padrão de assets.domain.Maintenance
// (TASK-137), sem o truque de activeDedupKey porque esta tabela não tem constraint de unicidade.
@SQLDelete(sql = "UPDATE financial_entries SET deleted_at = now() WHERE id = ?")
@SQLRestriction("deleted_at IS NULL")
@Data
@Entity
@Builder
@Table(name = "financial_entries")
@NoArgsConstructor
@AllArgsConstructor
public class FinancialEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "organization_code", nullable = false)
    private String organizationCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    private FinancialEntryType type;

    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 40)
    private FinancialEntryCategory category;

    @Column(name = "amount_cents", nullable = false)
    private Integer amountCents;

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "entry_date", nullable = false)
    private LocalDate entryDate;

    @Column(name = "created_by", nullable = false)
    private Long createdBy;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Column(name = "cancelled_at")
    private Instant cancelledAt;

    @Column(name = "cancelled_by")
    private Long cancelledBy;

    @Column(name = "cancel_reason")
    private String cancelReason;
}
```

- [ ] **Step 7: Create the repository**

Create `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/infrastructure/persistence/FinancialEntryRepository.java`:

```java
package com.brainbyte.easy_maintenance.finance.infrastructure.persistence;

import com.brainbyte.easy_maintenance.finance.domain.FinancialEntry;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;

public interface FinancialEntryRepository extends JpaRepository<FinancialEntry, Long> {

    // :type null = sem filtro de tipo (lista receita + despesa juntas).
    @Query("select fe from FinancialEntry fe where fe.organizationCode = :orgCode " +
            "and fe.entryDate between :start and :end " +
            "and (:type is null or fe.type = :type) " +
            "order by fe.entryDate desc, fe.id desc")
    Page<FinancialEntry> findByOrgAndPeriod(@Param("orgCode") String orgCode,
                                             @Param("start") LocalDate start,
                                             @Param("end") LocalDate end,
                                             @Param("type") FinancialEntryType type,
                                             Pageable pageable);

    // @SQLRestriction já garante que lançamentos cancelados nunca entram nessa soma.
    @Query("select coalesce(sum(fe.amountCents), 0) from FinancialEntry fe " +
            "where fe.organizationCode = :orgCode and fe.type = :type " +
            "and fe.entryDate between :start and :end")
    long sumAmountByOrgAndTypeAndPeriod(@Param("orgCode") String orgCode,
                                         @Param("type") FinancialEntryType type,
                                         @Param("start") LocalDate start,
                                         @Param("end") LocalDate end);

    // Query nativa de propósito: @SQLRestriction esconderia o lançamento cancelado de uma busca
    // JPQL normal. Checa a organização junto pra não vazar existência de ID cross-tenant (mesmo
    // cuidado de MaintenanceRepository.existsCancelledByIdAndOrgCode).
    @Query(value = "SELECT COUNT(*) > 0 FROM financial_entries " +
            "WHERE id = :id AND deleted_at IS NOT NULL AND organization_code = :orgCode",
            nativeQuery = true)
    boolean existsCancelledByIdAndOrgCode(@Param("id") Long id, @Param("orgCode") String orgCode);
}
```

- [ ] **Step 8: Run the test to verify it passes**

Run: `cd easy-maintenance-api && mvn -o test -Dtest=FinancialEntryPersistenceTest`
Expected: PASS — 5/5 testes.

- [ ] **Step 9: Commit**

```bash
cd easy-maintenance-api
git add src/main/resources/db/migration/V122__create_financial_entries.sql \
        src/main/java/com/brainbyte/easy_maintenance/finance/domain/FinancialEntry.java \
        src/main/java/com/brainbyte/easy_maintenance/finance/domain/enums/FinancialEntryType.java \
        src/main/java/com/brainbyte/easy_maintenance/finance/domain/enums/FinancialEntryCategory.java \
        src/main/java/com/brainbyte/easy_maintenance/finance/infrastructure/persistence/FinancialEntryRepository.java \
        src/test/java/com/brainbyte/easy_maintenance/finance/infrastructure/persistence/FinancialEntryPersistenceTest.java
git commit -m "feat(finance): FinancialEntry entity, migration V122 e repository (EPIC-032)"
```

---

## Task 2: Service layer — criar, cancelar, listar, resumir

**Files:**
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/application/dto/CreateFinancialEntryRequest.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/application/dto/CancelFinancialEntryRequest.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/application/dto/FinancialEntryResponse.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/application/dto/FinancialSummaryResponse.java`
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/application/service/FinancialEntryService.java`
- Test: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/finance/application/service/FinancialEntryServiceTest.java`

**Interfaces:**
- Consumes: `FinancialEntryRepository` (Task 1), `MaintenanceRepository.sumCostCentsByOrgsInAndPerformedBetween(Collection<String>, LocalDate, LocalDate): long` (já existe, `assets` module), `AuthenticationService.getCurrentUser(): User` (já existe).
- Produces: `FinancialEntryService.create(String orgId, CreateFinancialEntryRequest req): FinancialEntryResponse`, `.cancel(String orgId, Long entryId, String reason): void`, `.listByPeriod(String orgId, LocalDate start, LocalDate end, FinancialEntryType type, Pageable pageable): PageResponse<FinancialEntryResponse>`, `.summarize(String orgId, LocalDate start, LocalDate end): FinancialSummaryResponse`.

- [ ] **Step 1: Create the DTOs**

Create `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/application/dto/CreateFinancialEntryRequest.java`:

```java
package com.brainbyte.easy_maintenance.finance.application.dto;

import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryCategory;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

// "amountCents > 0" é checado no FinancialEntryService (RuleException, 400), não aqui com
// @Positive -- mesmo critério de validateEntryDate: regra de negócio fica no service, pra ficar
// coberta pelos testes de FinancialEntryServiceTest em vez de só confiar em bean validation.
@Schema(description = "Requisição para criar um lançamento financeiro (receita ou despesa)")
public record CreateFinancialEntryRequest(
        @NotNull(message = "O tipo é obrigatório") FinancialEntryType type,
        @NotNull(message = "A categoria é obrigatória") FinancialEntryCategory category,
        @NotNull(message = "O valor é obrigatório") Integer amountCents,
        @Size(max = 500, message = "A descrição deve ter no máximo 500 caracteres")
        String description,
        @NotNull(message = "A data é obrigatória") LocalDate entryDate
) {}
```

Create `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/application/dto/CancelFinancialEntryRequest.java`:

```java
package com.brainbyte.easy_maintenance.finance.application.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Requisição para cancelar um lançamento financeiro, com motivo obrigatório")
public record CancelFinancialEntryRequest(
        @NotBlank(message = "O motivo do cancelamento é obrigatório")
        @Size(min = 5, max = 1000, message = "O motivo deve ter entre 5 e 1000 caracteres")
        String reason
) {}
```

Create `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/application/dto/FinancialEntryResponse.java`:

```java
package com.brainbyte.easy_maintenance.finance.application.dto;

import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryCategory;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;

import java.time.Instant;
import java.time.LocalDate;

public record FinancialEntryResponse(
        Long id,
        FinancialEntryType type,
        FinancialEntryCategory category,
        Integer amountCents,
        String description,
        LocalDate entryDate,
        Long createdBy,
        Instant createdAt
) {}
```

Create `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/application/dto/FinancialSummaryResponse.java`:

```java
package com.brainbyte.easy_maintenance.finance.application.dto;

public record FinancialSummaryResponse(
        long totalRevenueCents,
        long totalManualExpenseCents,
        long totalMaintenanceExpenseCents,
        long balanceCents
) {}
```

- [ ] **Step 2: Write the failing service test**

Create `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/finance/application/service/FinancialEntryServiceTest.java`:

```java
package com.brainbyte.easy_maintenance.finance.application.service;

import com.brainbyte.easy_maintenance.assets.infrastructure.persistence.MaintenanceRepository;
import com.brainbyte.easy_maintenance.commons.dto.PageResponse;
import com.brainbyte.easy_maintenance.commons.exceptions.ConflictException;
import com.brainbyte.easy_maintenance.commons.exceptions.ForbiddenException;
import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.commons.exceptions.RuleException;
import com.brainbyte.easy_maintenance.commons.exceptions.TenantException;
import com.brainbyte.easy_maintenance.finance.application.dto.CreateFinancialEntryRequest;
import com.brainbyte.easy_maintenance.finance.application.dto.FinancialSummaryResponse;
import com.brainbyte.easy_maintenance.finance.domain.FinancialEntry;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryCategory;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;
import com.brainbyte.easy_maintenance.finance.infrastructure.persistence.FinancialEntryRepository;
import com.brainbyte.easy_maintenance.org_users.application.service.AuthenticationService;
import com.brainbyte.easy_maintenance.org_users.domain.User;
import com.brainbyte.easy_maintenance.org_users.domain.enums.Role;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FinancialEntryServiceTest {

    @Mock FinancialEntryRepository repository;
    @Mock MaintenanceRepository maintenanceRepository;
    @Mock AuthenticationService authenticationService;

    @InjectMocks FinancialEntryService service;

    private static final String ORG = "ORG-FIN";
    private static final Long USER_ID = 7L;
    private static final Long ENTRY_ID = 99L;

    private User user(Role role) {
        User u = new User();
        u.setId(USER_ID);
        u.setRole(role);
        return u;
    }

    private CreateFinancialEntryRequest validRevenueRequest() {
        return new CreateFinancialEntryRequest(
                FinancialEntryType.REVENUE, FinancialEntryCategory.TAXA_CONDOMINIAL,
                50000, "Taxa de outubro", LocalDate.now());
    }

    private FinancialEntry entry(Long id, String orgCode) {
        return FinancialEntry.builder()
                .id(id)
                .organizationCode(orgCode)
                .type(FinancialEntryType.REVENUE)
                .category(FinancialEntryCategory.TAXA_CONDOMINIAL)
                .amountCents(50000)
                .entryDate(LocalDate.now())
                .createdBy(USER_ID)
                .build();
    }

    // ── create ──────────────────────────────────────────────────────────────

    @Test
    void create_asAdmin_savesEntryAndReturnsResponse() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.ADMIN));
        when(repository.save(any())).thenAnswer(inv -> {
            FinancialEntry e = inv.getArgument(0);
            e.setId(ENTRY_ID);
            return e;
        });

        var response = service.create(ORG, validRevenueRequest());

        assertThat(response.id()).isEqualTo(ENTRY_ID);
        assertThat(response.type()).isEqualTo(FinancialEntryType.REVENUE);
        assertThat(response.amountCents()).isEqualTo(50000);

        ArgumentCaptor<FinancialEntry> captor = ArgumentCaptor.forClass(FinancialEntry.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getOrganizationCode()).isEqualTo(ORG);
        assertThat(captor.getValue().getCreatedBy()).isEqualTo(USER_ID);
    }

    @Test
    void create_asSyndic_isAllowed() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.SYNDIC));
        when(repository.save(any())).thenAnswer(inv -> {
            FinancialEntry e = inv.getArgument(0);
            e.setId(ENTRY_ID);
            return e;
        });

        var response = service.create(ORG, validRevenueRequest());

        assertThat(response.type()).isEqualTo(FinancialEntryType.REVENUE);
        verify(repository).save(any());
    }

    @Test
    void create_asTech_throwsForbidden() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.TECH));

        assertThatThrownBy(() -> service.create(ORG, validRevenueRequest()))
                .isInstanceOf(ForbiddenException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void create_asReader_throwsForbidden() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.READER));

        assertThatThrownBy(() -> service.create(ORG, validRevenueRequest()))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void create_amountZeroOrNegative_throwsRuleException() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.ADMIN));
        var zeroAmount = new CreateFinancialEntryRequest(
                FinancialEntryType.REVENUE, FinancialEntryCategory.TAXA_CONDOMINIAL,
                0, null, LocalDate.now());

        assertThatThrownBy(() -> service.create(ORG, zeroAmount))
                .isInstanceOf(RuleException.class)
                .hasMessageContaining("maior que zero");

        var negativeAmount = new CreateFinancialEntryRequest(
                FinancialEntryType.REVENUE, FinancialEntryCategory.TAXA_CONDOMINIAL,
                -500, null, LocalDate.now());

        assertThatThrownBy(() -> service.create(ORG, negativeAmount))
                .isInstanceOf(RuleException.class)
                .hasMessageContaining("maior que zero");

        verify(repository, never()).save(any());
    }

    @Test
    void create_categoryDoesNotMatchType_throwsRuleException() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.ADMIN));
        var mismatched = new CreateFinancialEntryRequest(
                FinancialEntryType.EXPENSE, FinancialEntryCategory.TAXA_CONDOMINIAL,
                50000, null, LocalDate.now());

        assertThatThrownBy(() -> service.create(ORG, mismatched))
                .isInstanceOf(RuleException.class)
                .hasMessageContaining("TAXA_CONDOMINIAL");

        verify(repository, never()).save(any());
    }

    @Test
    void create_entryDateInTheFuture_throwsRuleException() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.ADMIN));
        var futureDated = new CreateFinancialEntryRequest(
                FinancialEntryType.REVENUE, FinancialEntryCategory.TAXA_CONDOMINIAL,
                50000, null, LocalDate.now().plusDays(1));

        assertThatThrownBy(() -> service.create(ORG, futureDated))
                .isInstanceOf(RuleException.class)
                .hasMessageContaining("futura");

        verify(repository, never()).save(any());
    }

    // ── cancel ──────────────────────────────────────────────────────────────

    @Test
    void cancel_asAdmin_persistsReasonAuthorAndTimestamp_thenSoftDeletes() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.ADMIN));
        when(repository.findById(ENTRY_ID)).thenReturn(Optional.of(entry(ENTRY_ID, ORG)));

        service.cancel(ORG, ENTRY_ID, "Lançado em duplicidade");

        ArgumentCaptor<FinancialEntry> captor = ArgumentCaptor.forClass(FinancialEntry.class);
        verify(repository).saveAndFlush(captor.capture());
        FinancialEntry saved = captor.getValue();
        assertThat(saved.getCancelReason()).isEqualTo("Lançado em duplicidade");
        assertThat(saved.getCancelledBy()).isEqualTo(USER_ID);
        assertThat(saved.getCancelledAt()).isNotNull();

        verify(repository).delete(saved);
    }

    @Test
    void cancel_asTech_throwsForbidden() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.TECH));

        assertThatThrownBy(() -> service.cancel(ORG, ENTRY_ID, "motivo qualquer"))
                .isInstanceOf(ForbiddenException.class);

        verify(repository, never()).findById(any());
    }

    @Test
    void cancel_entryFromAnotherOrganization_throwsTenantException() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.ADMIN));
        when(repository.findById(ENTRY_ID)).thenReturn(Optional.of(entry(ENTRY_ID, "ORG-OUTRA")));

        assertThatThrownBy(() -> service.cancel(ORG, ENTRY_ID, "motivo qualquer"))
                .isInstanceOf(TenantException.class);

        verify(repository, never()).delete(any());
    }

    @Test
    void cancel_alreadyCancelled_throwsConflict() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.ADMIN));
        when(repository.findById(ENTRY_ID)).thenReturn(Optional.empty());
        when(repository.existsCancelledByIdAndOrgCode(ENTRY_ID, ORG)).thenReturn(true);

        assertThatThrownBy(() -> service.cancel(ORG, ENTRY_ID, "motivo qualquer"))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void cancel_notFound_throwsNotFound() {
        when(authenticationService.getCurrentUser()).thenReturn(user(Role.ADMIN));
        when(repository.findById(ENTRY_ID)).thenReturn(Optional.empty());
        when(repository.existsCancelledByIdAndOrgCode(ENTRY_ID, ORG)).thenReturn(false);

        assertThatThrownBy(() -> service.cancel(ORG, ENTRY_ID, "motivo qualquer"))
                .isInstanceOf(NotFoundException.class);
    }

    // ── listByPeriod ────────────────────────────────────────────────────────

    @Test
    void listByPeriod_mapsPageOfEntriesToResponses() {
        Pageable pageable = PageRequest.of(0, 20);
        Page<FinancialEntry> page = new PageImpl<>(List.of(entry(ENTRY_ID, ORG)), pageable, 1);
        when(repository.findByOrgAndPeriod(eq(ORG), any(), any(), eq(null), eq(pageable)))
                .thenReturn(page);

        PageResponse<?> result = service.listByPeriod(ORG, LocalDate.now().minusDays(30), LocalDate.now(), null, pageable);

        assertThat(result.totalElements()).isEqualTo(1);
        assertThat(result.content()).hasSize(1);
    }

    // ── summarize ───────────────────────────────────────────────────────────

    @Test
    void summarize_combinesManualEntriesWithAutomaticMaintenanceCost() {
        LocalDate start = LocalDate.of(2026, 10, 1);
        LocalDate end = LocalDate.of(2026, 10, 31);

        when(repository.sumAmountByOrgAndTypeAndPeriod(ORG, FinancialEntryType.REVENUE, start, end))
                .thenReturn(100000L);
        when(repository.sumAmountByOrgAndTypeAndPeriod(ORG, FinancialEntryType.EXPENSE, start, end))
                .thenReturn(20000L);
        when(maintenanceRepository.sumCostCentsByOrgsInAndPerformedBetween(List.of(ORG), start, end))
                .thenReturn(15000L);

        FinancialSummaryResponse summary = service.summarize(ORG, start, end);

        assertThat(summary.totalRevenueCents()).isEqualTo(100000L);
        assertThat(summary.totalManualExpenseCents()).isEqualTo(20000L);
        assertThat(summary.totalMaintenanceExpenseCents()).isEqualTo(15000L);
        assertThat(summary.balanceCents()).isEqualTo(100000L - 20000L - 15000L);
    }

    @Test
    void summarize_noEntriesAtAll_returnsAllZeroes() {
        LocalDate start = LocalDate.of(2026, 10, 1);
        LocalDate end = LocalDate.of(2026, 10, 31);

        when(repository.sumAmountByOrgAndTypeAndPeriod(eq(ORG), any(), eq(start), eq(end))).thenReturn(0L);
        when(maintenanceRepository.sumCostCentsByOrgsInAndPerformedBetween(anyList(), eq(start), eq(end)))
                .thenReturn(0L);

        FinancialSummaryResponse summary = service.summarize(ORG, start, end);

        assertThat(summary.totalRevenueCents()).isZero();
        assertThat(summary.totalManualExpenseCents()).isZero();
        assertThat(summary.totalMaintenanceExpenseCents()).isZero();
        assertThat(summary.balanceCents()).isZero();
    }
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd easy-maintenance-api && mvn -o test -Dtest=FinancialEntryServiceTest`
Expected: FAIL — compile error, `FinancialEntryService` não existe.

- [ ] **Step 4: Implement the service**

Create `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/application/service/FinancialEntryService.java`:

```java
package com.brainbyte.easy_maintenance.finance.application.service;

import com.brainbyte.easy_maintenance.assets.infrastructure.persistence.MaintenanceRepository;
import com.brainbyte.easy_maintenance.commons.dto.PageResponse;
import com.brainbyte.easy_maintenance.commons.exceptions.ConflictException;
import com.brainbyte.easy_maintenance.commons.exceptions.ForbiddenException;
import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.commons.exceptions.RuleException;
import com.brainbyte.easy_maintenance.commons.exceptions.TenantException;
import com.brainbyte.easy_maintenance.finance.application.dto.CreateFinancialEntryRequest;
import com.brainbyte.easy_maintenance.finance.application.dto.FinancialEntryResponse;
import com.brainbyte.easy_maintenance.finance.application.dto.FinancialSummaryResponse;
import com.brainbyte.easy_maintenance.finance.domain.FinancialEntry;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;
import com.brainbyte.easy_maintenance.finance.infrastructure.persistence.FinancialEntryRepository;
import com.brainbyte.easy_maintenance.org_users.application.service.AuthenticationService;
import com.brainbyte.easy_maintenance.org_users.domain.User;
import com.brainbyte.easy_maintenance.org_users.domain.enums.Role;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class FinancialEntryService {

    private final FinancialEntryRepository repository;
    private final MaintenanceRepository maintenanceRepository;
    private final AuthenticationService authenticationService;

    @Transactional
    public FinancialEntryResponse create(String orgId, CreateFinancialEntryRequest req) {
        User currentUser = authenticationService.getCurrentUser();
        requireFinancePermission(currentUser);
        validateAmount(req.amountCents());
        validateCategoryMatchesType(req.type(), req.category());
        validateEntryDate(req.entryDate());

        FinancialEntry entry = FinancialEntry.builder()
                .organizationCode(orgId)
                .type(req.type())
                .category(req.category())
                .amountCents(req.amountCents())
                .description(req.description())
                .entryDate(req.entryDate())
                .createdBy(currentUser.getId())
                .build();

        FinancialEntry saved = repository.save(entry);
        log.info("Financial entry {} created for org {}: type={}, category={}, amountCents={}",
                saved.getId(), orgId, saved.getType(), saved.getCategory(), saved.getAmountCents());

        return toResponse(saved);
    }

    @Transactional
    public void cancel(String orgId, Long entryId, String reason) {
        User currentUser = authenticationService.getCurrentUser();
        requireFinancePermission(currentUser);

        FinancialEntry entry = repository.findById(entryId)
                .orElseThrow(() -> resolveCancelNotFoundOrConflict(orgId, entryId));

        if (!orgId.equals(entry.getOrganizationCode())) {
            throw new TenantException(HttpStatus.FORBIDDEN, "Lançamento não pertence a essa organização");
        }

        entry.setCancelledAt(Instant.now());
        entry.setCancelledBy(currentUser.getId());
        entry.setCancelReason(reason);
        repository.saveAndFlush(entry);
        repository.delete(entry);

        log.info("Financial entry {} cancelled for org {} by user {}", entryId, orgId, currentUser.getId());
    }

    public PageResponse<FinancialEntryResponse> listByPeriod(String orgId, LocalDate start, LocalDate end,
                                                              FinancialEntryType type, Pageable pageable) {
        Page<FinancialEntryResponse> page = repository
                .findByOrgAndPeriod(orgId, start, end, type, pageable)
                .map(this::toResponse);
        return PageResponse.of(page);
    }

    public FinancialSummaryResponse summarize(String orgId, LocalDate start, LocalDate end) {
        long totalRevenueCents = repository.sumAmountByOrgAndTypeAndPeriod(orgId, FinancialEntryType.REVENUE, start, end);
        long totalManualExpenseCents = repository.sumAmountByOrgAndTypeAndPeriod(orgId, FinancialEntryType.EXPENSE, start, end);
        long totalMaintenanceExpenseCents = maintenanceRepository
                .sumCostCentsByOrgsInAndPerformedBetween(List.of(orgId), start, end);

        long balanceCents = totalRevenueCents - totalManualExpenseCents - totalMaintenanceExpenseCents;

        return new FinancialSummaryResponse(
                totalRevenueCents, totalManualExpenseCents, totalMaintenanceExpenseCents, balanceCents);
    }

    private FinancialEntryResponse toResponse(FinancialEntry entry) {
        return new FinancialEntryResponse(
                entry.getId(), entry.getType(), entry.getCategory(), entry.getAmountCents(),
                entry.getDescription(), entry.getEntryDate(), entry.getCreatedBy(), entry.getCreatedAt());
    }

    private static void requireFinancePermission(User user) {
        if (user.getRole() != Role.ADMIN && user.getRole() != Role.SYNDIC) {
            throw new ForbiddenException("Apenas ADMIN ou SYNDIC podem lançar ou cancelar movimentações financeiras.");
        }
    }

    private static void validateAmount(Integer amountCents) {
        if (amountCents <= 0) {
            throw new RuleException("O valor do lançamento deve ser maior que zero.");
        }
    }

    private static void validateCategoryMatchesType(FinancialEntryType type,
                                                      com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryCategory category) {
        if (category.getType() != type) {
            throw new RuleException("Categoria '" + category + "' não é compatível com o tipo " + type + ".");
        }
    }

    private static void validateEntryDate(LocalDate entryDate) {
        if (entryDate.isAfter(LocalDate.now())) {
            throw new RuleException("A data do lançamento não pode ser futura.");
        }
    }

    private RuntimeException resolveCancelNotFoundOrConflict(String orgId, Long entryId) {
        if (repository.existsCancelledByIdAndOrgCode(entryId, orgId)) {
            return new ConflictException("Este lançamento já foi cancelado");
        }
        return new NotFoundException("Lançamento não encontrado: " + entryId);
    }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd easy-maintenance-api && mvn -o test -Dtest=FinancialEntryServiceTest`
Expected: PASS — 15/15 testes.

- [ ] **Step 6: Commit**

```bash
cd easy-maintenance-api
git add src/main/java/com/brainbyte/easy_maintenance/finance/application/ \
        src/test/java/com/brainbyte/easy_maintenance/finance/application/
git commit -m "feat(finance): FinancialEntryService (criar/cancelar/listar/resumir) (EPIC-032)"
```

---

## Task 3: Controller REST

**Files:**
- Create: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/infrastructure/web/FinancialEntryController.java`

**Interfaces:**
- Consumes: `FinancialEntryService` (Task 2), `TenantContext.get(): Optional<String>` (já existe), `@RequireTenant` (já existe), `PageableAsQueryParam` (já existe).
- Produces: rotas HTTP `POST/GET /easy-maintenance/api/v1/finance/entries`, `POST /easy-maintenance/api/v1/finance/entries/{id}/cancel`, `GET /easy-maintenance/api/v1/finance/summary`.

- [ ] **Step 1: Create the controller**

Create `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/finance/infrastructure/web/FinancialEntryController.java`:

```java
package com.brainbyte.easy_maintenance.finance.infrastructure.web;

import com.brainbyte.easy_maintenance.commons.dto.PageResponse;
import com.brainbyte.easy_maintenance.finance.application.dto.CancelFinancialEntryRequest;
import com.brainbyte.easy_maintenance.finance.application.dto.CreateFinancialEntryRequest;
import com.brainbyte.easy_maintenance.finance.application.dto.FinancialEntryResponse;
import com.brainbyte.easy_maintenance.finance.application.dto.FinancialSummaryResponse;
import com.brainbyte.easy_maintenance.finance.application.service.FinancialEntryService;
import com.brainbyte.easy_maintenance.finance.domain.enums.FinancialEntryType;
import com.brainbyte.easy_maintenance.kernel.tenant.RequireTenant;
import com.brainbyte.easy_maintenance.kernel.tenant.TenantContext;
import com.brainbyte.easy_maintenance.shared.web.openapi.PageableAsQueryParam;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RequiredArgsConstructor
@RestController
@RequestMapping("/easy-maintenance/api/v1/finance")
@Tag(name = "Finance", description = "Controle financeiro simples por organização (EPIC-032)")
public class FinancialEntryController {

    private final FinancialEntryService service;

    @PostMapping("/entries")
    @RequireTenant
    @Operation(summary = "Lança uma receita ou despesa manual (não vinculada a manutenção)",
            responses = {
                    @ApiResponse(responseCode = "201", description = "Lançamento criado"),
                    @ApiResponse(responseCode = "400", description = "Categoria incompatível com o tipo, ou data futura"),
                    @ApiResponse(responseCode = "403", description = "Usuário sem papel ADMIN/SYNDIC")
            })
    public ResponseEntity<FinancialEntryResponse> create(@Valid @RequestBody CreateFinancialEntryRequest req) {
        String orgId = TenantContext.get().orElseThrow();
        FinancialEntryResponse response = service.create(orgId, req);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/entries")
    @RequireTenant
    @PageableAsQueryParam
    @Operation(summary = "Lista lançamentos financeiros do período, paginado")
    public PageResponse<FinancialEntryResponse> list(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end,
            @RequestParam(required = false) FinancialEntryType type,
            @Parameter(hidden = true) Pageable pageable) {
        String orgId = TenantContext.get().orElseThrow();
        return service.listByPeriod(orgId, start, end, type, pageable);
    }

    @PostMapping("/entries/{id}/cancel")
    @RequireTenant
    @Operation(summary = "Cancela um lançamento financeiro (nunca editado — só cancelado com motivo)",
            responses = {
                    @ApiResponse(responseCode = "204", description = "Cancelado com sucesso"),
                    @ApiResponse(responseCode = "403", description = "Sem permissão, ou lançamento de outra organização"),
                    @ApiResponse(responseCode = "404", description = "Lançamento não encontrado"),
                    @ApiResponse(responseCode = "409", description = "Lançamento já cancelado")
            })
    public void cancel(@PathVariable Long id, @Valid @RequestBody CancelFinancialEntryRequest req) {
        String orgId = TenantContext.get().orElseThrow();
        service.cancel(orgId, id, req.reason());
    }

    @GetMapping("/summary")
    @RequireTenant
    @Operation(summary = "Resumo financeiro do período: receita, despesa manual, despesa de manutenção e saldo")
    public FinancialSummaryResponse summary(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end) {
        String orgId = TenantContext.get().orElseThrow();
        return service.summarize(orgId, start, end);
    }
}
```

- [ ] **Step 2: Compile and run the full backend test suite**

Run: `cd easy-maintenance-api && mvn -o test`
Expected: PASS — nenhuma regressão no restante da suíte; os testes novos de `finance` continuam passando.

- [ ] **Step 3: Commit**

```bash
cd easy-maintenance-api
git add src/main/java/com/brainbyte/easy_maintenance/finance/infrastructure/web/
git commit -m "feat(finance): endpoints REST /finance/entries e /finance/summary (EPIC-032)"
```

---

## Task 4: Frontend — tela `/financeiro`

**Files:**
- Create: `easy-maintenance-web/src/app/financeiro/page.tsx`

**Interfaces:**
- Consumes: `api` (axios client, `@/lib/apiClient`), `ConfirmModal` (`@/components/ConfirmModal`), `formatMoney`/`formatDate` (`@/lib/formatters`), backend `GET/POST /finance/entries`, `POST /finance/entries/{id}/cancel`.

- [ ] **Step 1: Create the page**

Create `easy-maintenance-web/src/app/financeiro/page.tsx`:

```tsx
"use client";

import { useEffect, useState } from "react";
import { api } from "@/lib/apiClient";
import { formatMoney, formatDate } from "@/lib/formatters";
import ConfirmModal from "@/components/ConfirmModal";
import toast from "react-hot-toast";
import { Plus, TrendingUp, TrendingDown } from "lucide-react";

type EntryType = "REVENUE" | "EXPENSE";

const REVENUE_CATEGORIES = ["TAXA_CONDOMINIAL", "MULTA", "ALUGUEL_ESPACO", "OUTRAS_RECEITAS"] as const;
const EXPENSE_CATEGORIES = ["FOLHA_PAGAMENTO", "CONTA_CONSUMO", "SERVICO_TERCEIRO", "OUTRAS_DESPESAS"] as const;

const CATEGORY_LABEL: Record<string, string> = {
  TAXA_CONDOMINIAL: "Taxa condominial",
  MULTA: "Multa",
  ALUGUEL_ESPACO: "Aluguel de espaço",
  OUTRAS_RECEITAS: "Outras receitas",
  FOLHA_PAGAMENTO: "Folha de pagamento",
  CONTA_CONSUMO: "Conta de consumo",
  SERVICO_TERCEIRO: "Serviço de terceiro",
  OUTRAS_DESPESAS: "Outras despesas",
};

interface FinancialEntry {
  id: number;
  type: EntryType;
  category: string;
  amountCents: number;
  description: string | null;
  entryDate: string;
}

function isoDaysAgo(days: number) {
  const d = new Date();
  d.setDate(d.getDate() - days);
  return d.toISOString().split("T")[0];
}

function todayIso() {
  return new Date().toISOString().split("T")[0];
}

export default function FinanceiroPage() {
  const [entries, setEntries] = useState<FinancialEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [start, setStart] = useState(isoDaysAgo(30));
  const [end, setEnd] = useState(todayIso());
  const [canManageFinance, setCanManageFinance] = useState(false);

  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [creating, setCreating] = useState(false);
  const [formType, setFormType] = useState<EntryType>("REVENUE");
  const [formCategory, setFormCategory] = useState<string>(REVENUE_CATEGORIES[0]);
  const [formAmount, setFormAmount] = useState("");
  const [formDescription, setFormDescription] = useState("");
  const [formDate, setFormDate] = useState(todayIso());

  const [entryToCancel, setEntryToCancel] = useState<number | null>(null);
  const [cancelReason, setCancelReason] = useState("");
  const [cancelling, setCancelling] = useState(false);

  useEffect(() => {
    const role = window.localStorage.getItem("userRole") || window.sessionStorage.getItem("userRole");
    setCanManageFinance(role === "ADMIN" || role === "SYNDIC");
  }, []);

  useEffect(() => {
    fetchEntries();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [start, end]);

  async function fetchEntries() {
    try {
      setLoading(true);
      const { data } = await api.get("/finance/entries", { params: { start, end, size: 100 } });
      setEntries(data.content ?? []);
    } catch {
      toast.error("Não foi possível carregar os lançamentos financeiros.");
    } finally {
      setLoading(false);
    }
  }

  function openCreateModal(type: EntryType) {
    setFormType(type);
    setFormCategory(type === "REVENUE" ? REVENUE_CATEGORIES[0] : EXPENSE_CATEGORIES[0]);
    setFormAmount("");
    setFormDescription("");
    setFormDate(todayIso());
    setIsCreateOpen(true);
  }

  async function handleCreate() {
    const amountCents = Math.round(parseFloat(formAmount.replace(",", ".")) * 100);
    if (!amountCents || amountCents <= 0) {
      toast.error("Informe um valor maior que zero.");
      return;
    }
    try {
      setCreating(true);
      await api.post("/finance/entries", {
        type: formType,
        category: formCategory,
        amountCents,
        description: formDescription || null,
        entryDate: formDate,
      });
      toast.success("Lançamento criado com sucesso!");
      setIsCreateOpen(false);
      fetchEntries();
    } catch (err: any) {
      toast.error(err?.response?.data?.detail ?? "Erro ao criar lançamento.");
    } finally {
      setCreating(false);
    }
  }

  async function handleCancelEntry() {
    if (!entryToCancel || cancelReason.trim().length < 5) {
      toast.error("Informe um motivo com pelo menos 5 caracteres.");
      return;
    }
    try {
      setCancelling(true);
      await api.post(`/finance/entries/${entryToCancel}/cancel`, { reason: cancelReason });
      toast.success("Lançamento cancelado.");
      setEntryToCancel(null);
      setCancelReason("");
      fetchEntries();
    } catch (err: any) {
      toast.error(err?.response?.data?.detail ?? "Erro ao cancelar lançamento.");
    } finally {
      setCancelling(false);
    }
  }

  const categoriesForForm = formType === "REVENUE" ? REVENUE_CATEGORIES : EXPENSE_CATEGORIES;

  return (
    <section style={{ backgroundColor: "#f8f9fa", minHeight: "100vh" }} className="pb-5">
      <div className="container px-3 px-md-4">
        <div className="pt-4 pb-3">
          <h1 style={{ fontSize: "clamp(1.25rem, 3vw, 1.6rem)", fontWeight: 700, color: "#0f172a" }}>
            Financeiro
          </h1>
          <p className="text-muted mb-0 mt-1" style={{ fontSize: "0.85rem" }}>
            Receitas e despesas não vinculadas a manutenção
          </p>
        </div>

        <div className="card border-0 shadow-sm rounded-4 mb-3">
          <div className="card-body p-3 p-md-4">
            <div className="row g-3 align-items-end">
              <div className="col-6 col-md-3">
                <label className="form-label small fw-medium text-muted text-uppercase mb-1" style={{ fontSize: "0.68rem" }}>
                  Início
                </label>
                <input type="date" className="form-control form-control-sm" value={start} onChange={(e) => setStart(e.target.value)} />
              </div>
              <div className="col-6 col-md-3">
                <label className="form-label small fw-medium text-muted text-uppercase mb-1" style={{ fontSize: "0.68rem" }}>
                  Fim
                </label>
                <input type="date" className="form-control form-control-sm" value={end} onChange={(e) => setEnd(e.target.value)} />
              </div>
              {canManageFinance && (
                <div className="col-12 col-md-6 d-flex gap-2 justify-content-md-end">
                  <button className="btn btn-success btn-sm d-flex align-items-center gap-1" onClick={() => openCreateModal("REVENUE")}>
                    <TrendingUp size={14} /> Nova receita
                  </button>
                  <button className="btn btn-danger btn-sm d-flex align-items-center gap-1" onClick={() => openCreateModal("EXPENSE")}>
                    <TrendingDown size={14} /> Nova despesa
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="card border-0 shadow-sm rounded-4">
          <div className="card-body p-3 p-md-4">
            {loading ? (
              <p className="text-muted small mb-0">Carregando...</p>
            ) : entries.length === 0 ? (
              <p className="text-muted small mb-0">Nenhum lançamento neste período.</p>
            ) : (
              <div className="table-responsive">
                <table className="table table-sm">
                  <thead>
                    <tr>
                      <th>Data</th>
                      <th>Tipo</th>
                      <th>Categoria</th>
                      <th>Descrição</th>
                      <th>Valor</th>
                      {canManageFinance && <th></th>}
                    </tr>
                  </thead>
                  <tbody>
                    {entries.map((e) => (
                      <tr key={e.id}>
                        <td>{formatDate(e.entryDate)}</td>
                        <td>
                          <span className={`badge ${e.type === "REVENUE" ? "bg-success-subtle text-success" : "bg-danger-subtle text-danger"}`}>
                            {e.type === "REVENUE" ? "Receita" : "Despesa"}
                          </span>
                        </td>
                        <td>{CATEGORY_LABEL[e.category] ?? e.category}</td>
                        <td>{e.description || "—"}</td>
                        <td>{formatMoney(e.amountCents)}</td>
                        {canManageFinance && (
                          <td>
                            <button className="btn btn-sm btn-outline-danger" onClick={() => setEntryToCancel(e.id)}>
                              Cancelar
                            </button>
                          </td>
                        )}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      </div>

      {isCreateOpen && (
        <ConfirmModal
          show={isCreateOpen}
          title={formType === "REVENUE" ? "Nova receita" : "Nova despesa"}
          message={
            <div className="d-flex flex-column gap-2 text-start">
              <div>
                <label className="form-label small fw-medium">Categoria</label>
                <select className="form-select form-select-sm" value={formCategory} onChange={(e) => setFormCategory(e.target.value)}>
                  {categoriesForForm.map((c) => (
                    <option key={c} value={c}>{CATEGORY_LABEL[c]}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="form-label small fw-medium">Valor (R$)</label>
                <input type="text" inputMode="decimal" className="form-control form-control-sm" placeholder="0,00"
                       value={formAmount} onChange={(e) => setFormAmount(e.target.value)} />
              </div>
              <div>
                <label className="form-label small fw-medium">Data</label>
                <input type="date" className="form-control form-control-sm" value={formDate} onChange={(e) => setFormDate(e.target.value)} />
              </div>
              <div>
                <label className="form-label small fw-medium">Descrição (opcional)</label>
                <input type="text" className="form-control form-control-sm" value={formDescription}
                       onChange={(e) => setFormDescription(e.target.value)} />
              </div>
            </div>
          }
          confirmLabel={creating ? "Salvando..." : "Lançar"}
          cancelLabel="Cancelar"
          loading={creating}
          onConfirm={handleCreate}
          onCancel={() => !creating && setIsCreateOpen(false)}
        />
      )}

      <ConfirmModal
        show={!!entryToCancel}
        title="Cancelar lançamento"
        message={
          <div className="d-flex flex-column gap-2 text-start">
            <p className="mb-0">Informe o motivo do cancelamento (mínimo 5 caracteres):</p>
            <textarea className="form-control form-control-sm" rows={2} value={cancelReason}
                      onChange={(e) => setCancelReason(e.target.value)} />
          </div>
        }
        confirmLabel={cancelling ? "Cancelando..." : "Confirmar cancelamento"}
        cancelLabel="Voltar"
        loading={cancelling}
        onConfirm={handleCancelEntry}
        onCancel={() => { if (!cancelling) { setEntryToCancel(null); setCancelReason(""); } }}
      />
    </section>
  );
}
```

- [ ] **Step 2: Type-check and lint**

Run: `cd easy-maintenance-web && npx tsc --noEmit && npx eslint src/app/financeiro/page.tsx`
Expected: sem erros.

- [ ] **Step 3: Commit**

```bash
cd easy-maintenance-web
git add src/app/financeiro/page.tsx
git commit -m "feat(financeiro): tela de lançamentos de receita/despesa (EPIC-032)"
```

---

## Task 5: Integração com a Prestação de Contas

**Files:**
- Modify: `easy-maintenance-web/src/components/reports/PrestacaoContasSection.tsx`
- Modify: `easy-maintenance-web/src/components/reports/PrestacaoContasPdfDocument.tsx`

**Interfaces:**
- Consumes: `GET /finance/summary?start=&end=` (Task 3) → `{ totalRevenueCents, totalManualExpenseCents, totalMaintenanceExpenseCents, balanceCents }`.

- [ ] **Step 1: Extend `PrestacaoContasData` and the PDF document**

In `easy-maintenance-web/src/components/reports/PrestacaoContasPdfDocument.tsx`, add the new fields to the interface (find the `PrestacaoContasData` interface and add after `complianceIndex`):

```tsx
export interface PrestacaoContasData {
  organizationName: string;
  performedAtFrom: string;
  performedAtTo: string;
  totalMaintenances: number;
  totalCostCents: number;
  itemsOk: number;
  itemsNearDue: number;
  itemsOverdue: number;
  totalItems: number;
  complianceIndex: number | null;
  // EPIC-032: resumo financeiro (receitas/despesas manuais + saldo), null quando o endpoint
  // /finance/summary falhar -- relatório continua funcionando sem essa seção (mesmo princípio do
  // complianceIndex, TASK-294).
  financialSummary: {
    totalRevenueCents: number;
    totalManualExpenseCents: number;
    totalMaintenanceExpenseCents: number;
    balanceCents: number;
  } | null;
  maintenances: MaintenanceRow[];
  cancelled: CancelledRow[];
  pendingItems: PendingItemRow[];
}
```

Add a new KPI row right after the existing "Itens em dia / Próximos / Vencidos" `kpiRow` block (find that block — it has 3 `kpiCard`s for `itemsOk`/`itemsNearDue`/`itemsOverdue` — add this new `View` immediately after its closing `</View>`):

```tsx
          {data.financialSummary && (
            <View style={styles.kpiRow}>
              <View style={styles.kpiCard}>
                <Text style={styles.kpiLabel}>Receitas</Text>
                <Text style={styles.kpiValue}>{formatMoney(data.financialSummary.totalRevenueCents)}</Text>
              </View>
              <View style={styles.kpiCard}>
                <Text style={styles.kpiLabel}>Despesas manuais</Text>
                <Text style={styles.kpiValue}>{formatMoney(data.financialSummary.totalManualExpenseCents)}</Text>
              </View>
              <View style={styles.kpiCard}>
                <Text style={styles.kpiLabel}>Saldo do período</Text>
                <Text style={styles.kpiValue}>{formatMoney(data.financialSummary.balanceCents)}</Text>
              </View>
            </View>
          )}
```

- [ ] **Step 2: Fetch the summary in `PrestacaoContasSection.tsx`**

In `easy-maintenance-web/src/components/reports/PrestacaoContasSection.tsx`, inside `generatePreview()`, find this block:

```tsx
      const [maintenancesRes, cancelledRes, itemsRes, summaryRes] = await Promise.all([
        api.get("/items/maintenances", { params: { performedAtFrom, performedAtTo, size: 1000 }, ...orgHeaders }),
        api.get("/items/maintenances/cancelled", { params: { performedAtFrom, performedAtTo }, ...orgHeaders }),
        api.get("/items", { params: { size: 1000 }, ...orgHeaders }),
        // TASK-294: mesmo índice de conformidade do dashboard. Falha aqui não derruba o relatório --
        // o índice só aparece como "—".
        api.get("/dashboard/summary", { params: { companyCode: selectedOrgCode }, ...orgHeaders }).catch(() => ({ data: null })),
      ]);
      const complianceIndex: number | null = summaryRes.data?.complianceIndex ?? null;
```

Replace with:

```tsx
      const [maintenancesRes, cancelledRes, itemsRes, summaryRes, financeRes] = await Promise.all([
        api.get("/items/maintenances", { params: { performedAtFrom, performedAtTo, size: 1000 }, ...orgHeaders }),
        api.get("/items/maintenances/cancelled", { params: { performedAtFrom, performedAtTo }, ...orgHeaders }),
        api.get("/items", { params: { size: 1000 }, ...orgHeaders }),
        // TASK-294: mesmo índice de conformidade do dashboard. Falha aqui não derruba o relatório --
        // o índice só aparece como "—".
        api.get("/dashboard/summary", { params: { companyCode: selectedOrgCode }, ...orgHeaders }).catch(() => ({ data: null })),
        // EPIC-032: resumo financeiro (receitas/despesas manuais). Falha aqui não derruba o
        // relatório -- a seção financeira só não aparece (mesmo princípio do complianceIndex).
        api.get("/finance/summary", { params: { start: performedAtFrom, end: performedAtTo }, ...orgHeaders }).catch(() => ({ data: null })),
      ]);
      const complianceIndex: number | null = summaryRes.data?.complianceIndex ?? null;
      const financialSummary = financeRes.data
        ? {
            totalRevenueCents: financeRes.data.totalRevenueCents,
            totalManualExpenseCents: financeRes.data.totalManualExpenseCents,
            totalMaintenanceExpenseCents: financeRes.data.totalMaintenanceExpenseCents,
            balanceCents: financeRes.data.balanceCents,
          }
        : null;
```

Then find the `setData({...})` call a few lines below and add `financialSummary,` right after `complianceIndex,`:

```tsx
      setData({
        organizationName: selectedOrg?.organizationName || "—",
        performedAtFrom,
        performedAtTo,
        totalMaintenances: maintenances.length,
        totalCostCents,
        itemsOk,
        itemsNearDue,
        itemsOverdue,
        totalItems: items.length,
        complianceIndex,
        financialSummary,
        maintenances,
        cancelled,
        pendingItems,
      });
```

- [ ] **Step 3: Show the financial KPIs in the on-screen preview**

In the same file, find the KPI array passed to the "Resumo do período" section:

```tsx
            <div className="row g-2 mb-4">
              {[
                { label: "Manutenções realizadas", value: data.totalMaintenances },
                { label: "Custo total", value: formatMoney(data.totalCostCents) },
                { label: "Índice de conformidade", value: formatComplianceIndex(data.complianceIndex) },
                { label: "Itens em dia", value: data.itemsOk },
                { label: "Próximos do vencimento", value: data.itemsNearDue },
                { label: "Vencidos", value: data.itemsOverdue },
              ].map((kpi) => (
```

Replace with:

```tsx
            <div className="row g-2 mb-4">
              {[
                { label: "Manutenções realizadas", value: data.totalMaintenances },
                { label: "Custo total", value: formatMoney(data.totalCostCents) },
                { label: "Índice de conformidade", value: formatComplianceIndex(data.complianceIndex) },
                { label: "Itens em dia", value: data.itemsOk },
                { label: "Próximos do vencimento", value: data.itemsNearDue },
                { label: "Vencidos", value: data.itemsOverdue },
                ...(data.financialSummary
                  ? [
                      { label: "Receitas", value: formatMoney(data.financialSummary.totalRevenueCents) },
                      { label: "Despesas manuais", value: formatMoney(data.financialSummary.totalManualExpenseCents) },
                      { label: "Saldo do período", value: formatMoney(data.financialSummary.balanceCents) },
                    ]
                  : []),
              ].map((kpi) => (
```

- [ ] **Step 4: Type-check and lint**

Run: `cd easy-maintenance-web && npx tsc --noEmit && npx eslint src/components/reports/PrestacaoContasSection.tsx src/components/reports/PrestacaoContasPdfDocument.tsx`
Expected: sem erros.

- [ ] **Step 5: Commit**

```bash
cd easy-maintenance-web
git add src/components/reports/PrestacaoContasSection.tsx src/components/reports/PrestacaoContasPdfDocument.tsx
git commit -m "feat(reports): Prestação de Contas exibe receitas/despesas manuais e saldo (EPIC-032)"
```

---

## Task 6: Entrada no menu de navegação

**Files:**
- Modify: `easy-maintenance-web/src/components/layout/app/UserTopBar.tsx`

**Interfaces:**
- Consumes: `router.push` (já usado no arquivo), ícone `Wallet` de `lucide-react`.

- [ ] **Step 1: Add the "Financeiro" menu item**

In `easy-maintenance-web/src/components/layout/app/UserTopBar.tsx`, find the import line that brings in `BarChart2` (or the lucide-react import block) and add `Wallet`:

Find:
```tsx
import { ..., BarChart2, ... } from "lucide-react";
```
Add `Wallet` to that same import list.

Then find this block (the "Relatórios" menu item):

```tsx
          {reportsEnabled && (
            <li>
              <button className="dropdown-item d-flex align-items-center gap-2 py-2" onClick={() => router.push("/reports")} disabled={isBlocked}>
                <BarChart2 size={18} className="text-muted" />
                Relatórios
              </button>
            </li>
          )}
```

Replace with (adds the new item right after, unconditional — no plan gate, EPIC-032 decision):

```tsx
          {reportsEnabled && (
            <li>
              <button className="dropdown-item d-flex align-items-center gap-2 py-2" onClick={() => router.push("/reports")} disabled={isBlocked}>
                <BarChart2 size={18} className="text-muted" />
                Relatórios
              </button>
            </li>
          )}
          <li>
            <button className="dropdown-item d-flex align-items-center gap-2 py-2" onClick={() => router.push("/financeiro")} disabled={isBlocked}>
              <Wallet size={18} className="text-muted" />
              Financeiro
            </button>
          </li>
```

- [ ] **Step 2: Type-check and lint**

Run: `cd easy-maintenance-web && npx tsc --noEmit && npx eslint src/components/layout/app/UserTopBar.tsx`
Expected: sem erros.

- [ ] **Step 3: Commit**

```bash
cd easy-maintenance-web
git add src/components/layout/app/UserTopBar.tsx
git commit -m "feat(nav): item 'Financeiro' no menu do usuário (EPIC-032)"
```

---

## Task 7: E2E — fluxo completo

**Files:**
- Create: `easy-maintenance-e2e/tests/frontend/finance-entries.spec.ts`

**Interfaces:**
- Consumes: `loginViaUi` (`../../helpers/frontend-login`), uma tenant fixture existente com papel ADMIN (`../../fixtures/tenant`) — reaproveitar `TENANT_D_OPERATING` (já usada em `compliance-dashboard.spec.ts`) em vez de criar seed novo.

- [ ] **Step 1: Confirm the fixture's role**

Run: `cd easy-maintenance-e2e && grep -n "TENANT_D_OPERATING" fixtures/tenant.ts`
Verifique que o usuário dessa fixture tem papel `ADMIN` ou `SYNDIC` (necessário pra criar/cancelar lançamento). Se não tiver, troque `TENANT_D_OPERATING` por outra fixture existente que tenha — ajuste o nome usado nos steps seguintes de acordo com o que for encontrado.

- [ ] **Step 2: Write the e2e spec**

Create `easy-maintenance-e2e/tests/frontend/finance-entries.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';
import { TENANT_D_OPERATING } from '../../fixtures/tenant';
import { loginViaUi } from '../../helpers/frontend-login';

// EPIC-032: fluxo completo do módulo financeiro -- lançar receita, lançar despesa, ver refletido
// na lista e na Prestação de Contas, cancelar um lançamento e confirmar que some do saldo.
// Depende de uma API/MySQL e2e rodando (mesmo requisito dos demais specs de frontend/).
test.describe.configure({ mode: 'serial' });

test.describe('Financeiro — EPIC-032', () => {
  test('cria receita e despesa, reflete na lista e na Prestação de Contas', async ({ page }) => {
    await loginViaUi(page, TENANT_D_OPERATING);
    await page.goto('/financeiro');

    await expect(page.getByRole('heading', { name: 'Financeiro' })).toBeVisible({ timeout: 15_000 });

    // Lança receita
    await page.getByRole('button', { name: 'Nova receita' }).click();
    await page.locator('select').first().selectOption('TAXA_CONDOMINIAL');
    await page.getByPlaceholder('0,00').fill('500,00');
    await page.getByRole('button', { name: 'Lançar' }).click();
    await expect(page.getByText('Lançamento criado com sucesso!')).toBeVisible();

    // Lança despesa
    await page.getByRole('button', { name: 'Nova despesa' }).click();
    await page.locator('select').first().selectOption('CONTA_CONSUMO');
    await page.getByPlaceholder('0,00').fill('80,00');
    await page.getByRole('button', { name: 'Lançar' }).click();
    await expect(page.getByText('Lançamento criado com sucesso!')).toBeVisible();

    // Ambos aparecem na lista
    await expect(page.getByText('R$ 500,00')).toBeVisible();
    await expect(page.getByText('R$ 80,00')).toBeVisible();

    // Prestação de Contas reflete o saldo
    await page.goto('/reports');
    await page.getByRole('button', { name: 'Visualizar relatório' }).click();
    await expect(page.getByText('Receitas')).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText('R$ 500,00')).toBeVisible();
  });

  test('cancelar lançamento remove da lista ativa', async ({ page }) => {
    await loginViaUi(page, TENANT_D_OPERATING);
    await page.goto('/financeiro');

    await page.getByRole('button', { name: 'Nova receita' }).click();
    await page.locator('select').first().selectOption('MULTA');
    await page.getByPlaceholder('0,00').fill('30,00');
    await page.getByRole('button', { name: 'Lançar' }).click();
    await expect(page.getByText('Lançamento criado com sucesso!')).toBeVisible();

    const row = page.locator('tr', { hasText: 'R$ 30,00' });
    await row.getByRole('button', { name: 'Cancelar' }).click();
    await page.getByRole('textbox').last().fill('Lançado em duplicidade por engano');
    await page.getByRole('button', { name: 'Confirmar cancelamento' }).click();

    await expect(page.getByText('Lançamento cancelado.')).toBeVisible();
    await expect(page.locator('tr', { hasText: 'R$ 30,00' })).toHaveCount(0);
  });
});
```

- [ ] **Step 3: Commit**

```bash
cd easy-maintenance-e2e
git add tests/frontend/finance-entries.spec.ts
git commit -m "test(e2e): fluxo completo do modulo financeiro (EPIC-032)"
```

Nota de execução: este spec não foi rodado nesta sessão (requer MySQL e2e + API local de pé, mesmo
caveat documentado em `compliance-dashboard.spec.ts`) — rode com `npm run setup:db` seguido de
`npx playwright test tests/frontend/finance-entries.spec.ts` antes de considerar a task concluída.

---

## Task 8: Documentação do roadmap (`EPIC-032` + tasks + kanban)

**Files:**
- Create: `roadmap/epics/EPIC-032.md`
- Create: `roadmap/tasks/TASK-322.md` até `TASK-329.md` (uma por task deste plano, 1→8)
- Modify: `roadmap/kanban.md`

**Interfaces:** nenhuma (documentação).

- [ ] **Step 1: Create `roadmap/epics/EPIC-032.md`**

Espelhe a estrutura de `roadmap/epics/EPIC-028.md` (Objetivo / Descrição / Contexto Técnico / Tasks / Critério de Conclusão / Fora de Escopo / Riscos), usando o conteúdo de `docs/superpowers/specs/2026-10-04-financial-entries-design.md` como fonte. Tabela de tasks:

```markdown
| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-322](../tasks/TASK-322.md) | Backend: FinancialEntry — domain, migration V122, repository | BACKEND | 🟠 Alto |
| [TASK-323](../tasks/TASK-323.md) | Backend: FinancialEntryService (criar/cancelar/listar/resumir) | BACKEND | 🟠 Alto |
| [TASK-324](../tasks/TASK-324.md) | Backend: endpoints REST /finance | BACKEND | 🟠 Alto |
| [TASK-325](../tasks/TASK-325.md) | Frontend: tela /financeiro | FRONTEND | 🟠 Alto |
| [TASK-326](../tasks/TASK-326.md) | Frontend: integração com Prestação de Contas | FRONTEND | 🟠 Alto |
| [TASK-327](../tasks/TASK-327.md) | Frontend: item "Financeiro" no menu | FRONTEND | 🟡 Médio |
| [TASK-328](../tasks/TASK-328.md) | QA: E2E fluxo completo do módulo financeiro | QA | 🟠 Alto |
| [TASK-329](../tasks/TASK-329.md) | Roadmap: documentação do épico | INFRA / CONFIG | 🔵 Baixo |
```

- [ ] **Step 2: Create the 8 task files**

Para cada `TASK-322` a `TASK-329`, crie um arquivo seguindo exatamente o formato de `roadmap/tasks/TASK-308.md` (Tipo / Prioridade / Épico / QA obrigatório / Contexto / Critérios de aceite / Status). O conteúdo de cada uma é a seção correspondente deste plano (Task 1 → TASK-322, Task 2 → TASK-323, ..., Task 7 → TASK-328, Task 8 → TASK-329). Todas apontam `## Épico` para `[EPIC-032](../epics/EPIC-032.md)` e `## Status` como `Backlog` até serem executadas.

Exemplo concreto para `roadmap/tasks/TASK-322.md`:

```markdown
# TASK-322 — Backend: FinancialEntry — domain, migration V122, repository

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-032](../epics/EPIC-032.md) — Controle Financeiro Simples por Organização

## QA obrigatório
Sim — nova tabela/entidade, isolamento multi-tenant precisa de teste real (não só mockado).

## Contexto
Desenho completo em [`docs/superpowers/specs/2026-10-04-financial-entries-design.md`](../../docs/superpowers/specs/2026-10-04-financial-entries-design.md)
e plano de implementação em [`docs/superpowers/plans/2026-10-04-financial-entries-plan.md`](../../docs/superpowers/plans/2026-10-04-financial-entries-plan.md) (Task 1).

Entidade `FinancialEntry` (migration V122), enums `FinancialEntryType`/`FinancialEntryCategory`,
repository com soft-delete (`@SQLDelete`/`@SQLRestriction`, mesmo padrão de `Maintenance`/TASK-137).

**Prompt**: `execute a TASK-322 (EPIC-032): FinancialEntry entity, migration V122 e repository,
seguindo a Task 1 do plano docs/superpowers/plans/2026-10-04-financial-entries-plan.md.`

## Critérios de aceite
- [ ] `FinancialEntryPersistenceTest` (H2 real) prova soft-delete + isolamento por organização.
- [ ] `mvn test` sem regressão.

## Status
Backlog
```

As demais 7 seguem o mesmo padrão, usando a task correspondente do plano como conteúdo de "Contexto"/"Prompt".

- [ ] **Step 3: Update `roadmap/kanban.md`**

Adicione uma seção nova pro épico, no mesmo estilo de `## 💳 EPIC-028` já existente no arquivo (procure por `## 💰 EPIC-028` ou similar pra copiar o cabeçalho de formatação):

```markdown
## 💰 EPIC-032 — Controle Financeiro Simples por Organização

> Adicionado em 04/10/2026 — feedback de clientes reais pedindo lugar pra lançar receita/despesa não
> vinculada a manutenção (custo de manutenção já é automático). Desenhado via brainstorm com Douglas
> (04/10/2026). Spec em `docs/superpowers/specs/2026-10-04-financial-entries-design.md`, plano em
> `docs/superpowers/plans/2026-10-04-financial-entries-plan.md`.

| ID | Título | Prioridade | Fase | Tipo |
|---|---|---|---|---|
| [TASK-322](tasks/TASK-322.md) | Backend: FinancialEntry — domain, migration V122, repository | 🟠 Alto | 1 | BACKEND |
| [TASK-323](tasks/TASK-323.md) | Backend: FinancialEntryService | 🟠 Alto | 1 | BACKEND |
| [TASK-324](tasks/TASK-324.md) | Backend: endpoints REST /finance | 🟠 Alto | 1 | BACKEND |
| [TASK-325](tasks/TASK-325.md) | Frontend: tela /financeiro | 🟠 Alto | 1 | FRONTEND |
| [TASK-326](tasks/TASK-326.md) | Frontend: integração com Prestação de Contas | 🟠 Alto | 1 | FRONTEND |
| [TASK-327](tasks/TASK-327.md) | Frontend: item "Financeiro" no menu | 🟡 Médio | 1 | FRONTEND |
| [TASK-328](tasks/TASK-328.md) | QA: E2E fluxo completo | 🟠 Alto | 1 | QA |
| [TASK-329](tasks/TASK-329.md) | Roadmap: documentação do épico | 🔵 Baixo | 1 | INFRA / CONFIG |
```

- [ ] **Step 4: Commit (repositório raiz, público — sem detalhe técnico sensível aqui, só o que já está na spec/plano que também são públicos neste caso)**

```bash
cd /d/workpaces/EASY_MAINTENANCE
git add roadmap/epics/EPIC-032.md roadmap/tasks/TASK-322.md roadmap/tasks/TASK-323.md \
        roadmap/tasks/TASK-324.md roadmap/tasks/TASK-325.md roadmap/tasks/TASK-326.md \
        roadmap/tasks/TASK-327.md roadmap/tasks/TASK-328.md roadmap/tasks/TASK-329.md \
        roadmap/kanban.md
git commit -m "chore(roadmap): EPIC-032 -- controle financeiro simples por organizacao"
git push origin main
```
