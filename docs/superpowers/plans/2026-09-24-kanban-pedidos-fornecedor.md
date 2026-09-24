# Kanban de pedidos do fornecedor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** O fornecedor vê, pelo link mágico, os pedidos de orçamento que recebeu (com contato de quem pediu) num kanban Novo → Em contato → Orçamento enviado → Fechado / Perdido e move os pedidos entre colunas.

**Architecture:** Backend adiciona `status`/`status_updated_at` em `supplier_budget_requests` (V115) e um serviço `SupplierBudgetInboxService` (resolve fornecedor pelo token, lista com lookup em lote de organização/usuário, atualiza status escopado por `supplierId`) exposto em `GET`/`PATCH /public/suppliers/manage/{token}/budget-requests`. Frontend adiciona abas "Pedidos"/"Meus dados" em `/fornecedores/gerenciar/[token]`, com lógica pura do quadro num módulo `.ts` testável e componentes de quadro/card; o modal de `/fornecedores` ganha o aviso LGPD.

**Tech Stack:** Spring Boot 3 / JPA / Flyway (MySQL 8) / JUnit 5 + Mockito + AssertJ; Next.js App Router / React / TypeScript / Bootstrap 5 / axios / react-hot-toast / Jest (`ts-jest`, `testEnvironment: node`, só `src/**/*.test.ts`).

**Spec:** `docs/superpowers/specs/2026-09-24-kanban-pedidos-fornecedor-design.md`

## Global Constraints

- Repos: `D:\workpaces\EASY_MAINTENANCE\easy-maintenance-api` e `D:\workpaces\EASY_MAINTENANCE\easy-maintenance-web`. Em **cada** repo, branch `feature/TASK-280-kanban-pedidos-fornecedor` criada a partir de `origin/staging`. PRs contra `staging`.
- Todo commit termina com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Status: `NEW`, `CONTACTED`, `QUOTED`, `WON`, `LOST` — rótulos "Novo", "Em contato", "Orçamento enviado", "Fechado", "Perdido", nessa ordem. Qualquer status → qualquer status.
- Fornecedor vê: nome da organização, bairro, cidade/UF, nome + e-mail + WhatsApp de quem pediu, resumo, data, status. Nunca `organizationCode`, ids de usuário/organização nem dados de outros fornecedores.
- Token inválido **e** pedido de outro fornecedor → **404** idêntico (`NotFoundException`); `status` nulo/inválido → **400** (`ProblemDetail`).
- Endpoints novos com `@RateLimit("supplier-manage")`, sem `X-Org-Id` (rota `/public/suppliers/**` já liberada).
- Organização/usuário não encontrado (inclui usuário soft-deleted — `User` tem `@SQLRestriction("deleted_at IS NULL")`) → `"—"` no nome e contato nulo; nunca quebra a listagem.
- Aviso LGPD no modal "Solicitar orçamento": exatamente *"Seu nome, e-mail e WhatsApp serão compartilhados com o fornecedor pra ele retornar o contato."*
- Sem drag-and-drop. Mobile: filtros por coluna + lista; desktop (≥ 992px): 5 colunas.
- Sem tratamento de pedidos antigos (não existem em produção).
- Gate de lint no `web`: nenhum erro **novo** nos arquivos tocados (repo já tem 137 problemas pré-existentes). `npm test` tem 3 falhas pré-existentes em `middleware.test.ts`.
- Testes de persistência do `api` rodam em H2 com Flyway desligado → a **V115 não é validada pelo `mvn test`**; validar contra o MySQL do Docker local (`easy_maintenance_mysql`) subindo a API (Task 3).

## Review Focus

1. **IDOR no PATCH** — token do fornecedor A com `id` de pedido do fornecedor B deve dar 404 e não alterar nada. Coberto em Task 2 (`updateStatus_requestOfAnotherSupplier_throwsNotFoundAndDoesNotSave`) e smoke `curl` na Task 3.
2. **Organização/usuário ausente ou soft-deleted** — listagem não quebra, mostra `"—"`. Coberto em Task 2 (`list_missingOrganizationAndUser_usesPlaceholderAndNullContact`).
3. **Telefone do solicitante ausente ou malformado** — card sem botão WhatsApp, sem link quebrado. Coberto em Task 4 (`whatsappLink` casos null/curto/com máscara/com 55).
4. **Falha de rede ao mover card** — card volta pra coluna anterior + toast. Coberto em Task 4 (`applyStatusChange` + reversão) e QA na Task 7 (API parada).
5. **Fornecedor com zero pedidos / erro só na listagem de pedidos** — aba "Meus dados" continua funcionando e o pagamento pendente continua visível. Coberto no QA da Task 7 (sem DOM nos testes Jest).

---

## File Structure

**api**
| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `src/main/resources/db/migration/V115__add_status_to_supplier_budget_requests.sql` | Create | Colunas `status`, `status_updated_at` |
| `src/main/java/.../supplier/domain/enums/BudgetRequestStatus.java` | Create | Enum dos 5 status |
| `src/main/java/.../supplier/domain/SupplierBudgetRequest.java` | Modify | Campos `status` (default NEW), `statusUpdatedAt` |
| `src/main/java/.../supplier/infrastructure/persistence/SupplierBudgetRequestRepository.java` | Modify | `findAllBySupplierIdOrderByCreatedAtDescIdDesc`, `findByIdAndSupplierId` |
| `src/test/java/.../supplier/infrastructure/persistence/SupplierBudgetRequestPersistenceTest.java` | Create | Finders escopados por fornecedor + ordem + default NEW |
| `src/main/java/.../supplier_billing/application/dto/SupplierBudgetRequestView.java` | Create | DTO de resposta |
| `src/main/java/.../supplier_billing/application/dto/UpdateBudgetRequestStatusRequest.java` | Create | `{ @NotNull status }` |
| `src/main/java/.../supplier_billing/application/service/SupplierBudgetInboxService.java` | Create | `list(token)`, `updateStatus(token, id, status)` |
| `src/test/java/.../supplier_billing/application/service/SupplierBudgetInboxServiceTest.java` | Create | Unit tests do serviço |
| `src/test/java/.../supplier_billing/application/dto/UpdateBudgetRequestStatusRequestTest.java` | Create | `status` nulo → violação |
| `src/main/java/.../supplier_billing/infrastructure/web/SupplierPublicController.java` | Modify | `GET`/`PATCH` novos |

(`...` = `com/brainbyte/easy_maintenance`)

**web**
| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `src/lib/supplierBudgetBoard.ts` | Create | Colunas, agrupamento, link WhatsApp, "há X dias", mudança otimista |
| `src/lib/supplierBudgetBoard.test.ts` | Create | Testes da lógica pura |
| `src/app/fornecedores/cadastro/_lib/publicSupplierApi.ts` | Modify | Tipos + `getSupplierBudgetRequests`, `updateSupplierBudgetRequestStatus` |
| `src/components/supplier/BudgetRequestCard.tsx` | Create | Card de um pedido |
| `src/components/supplier/BudgetRequestBoard.tsx` | Create | Quadro (desktop colunas / mobile filtros), estados vazio |
| `src/app/fornecedores/gerenciar/[token]/page.tsx` | Modify | Abas, carga dos pedidos, estados loading/erro |
| `src/app/fornecedores/page.tsx` | Modify (~L472-484) | Aviso LGPD no modal |

---

### Task 1: Migration, enum, entidade e finders escopados

**Files:**
- Create: `src/main/resources/db/migration/V115__add_status_to_supplier_budget_requests.sql`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier/domain/enums/BudgetRequestStatus.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier/domain/SupplierBudgetRequest.java`
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier/infrastructure/persistence/SupplierBudgetRequestRepository.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/supplier/infrastructure/persistence/SupplierBudgetRequestPersistenceTest.java`

**Interfaces:**
- Produces: `enum BudgetRequestStatus { NEW, CONTACTED, QUOTED, WON, LOST }`; `SupplierBudgetRequest#getStatus()/setStatus(BudgetRequestStatus)`, `getStatusUpdatedAt()/setStatusUpdatedAt(Instant)`; `List<SupplierBudgetRequest> findAllBySupplierIdOrderByCreatedAtDescIdDesc(Long supplierId)`; `Optional<SupplierBudgetRequest> findByIdAndSupplierId(Long id, Long supplierId)`

- [ ] **Step 0: Branch**

```bash
cd /d/workpaces/EASY_MAINTENANCE/easy-maintenance-api
git fetch origin && git checkout -b feature/TASK-280-kanban-pedidos-fornecedor origin/staging
```

- [ ] **Step 1: Teste de persistência (falha)** — `SupplierBudgetRequestPersistenceTest.java`

```java
package com.brainbyte.easy_maintenance.supplier.infrastructure.persistence;

import com.brainbyte.easy_maintenance.supplier.domain.SupplierBudgetRequest;
import com.brainbyte.easy_maintenance.supplier.domain.enums.BudgetRequestStatus;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

// TASK-280: H2 com schema das anotações (Flyway desligado, mesmo padrão de SupplierPersistenceTest).
// A V115 em si é validada contra o MySQL do Docker local na Task 3 do plano.
@DataJpaTest
@EntityScan(basePackageClasses = SupplierBudgetRequest.class)
@EnableJpaRepositories(
        basePackageClasses = SupplierBudgetRequestRepository.class,
        includeFilters = @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE,
                classes = SupplierBudgetRequestRepository.class)
)
@TestPropertySource(properties = {
        "spring.flyway.enabled=false",
        "spring.jpa.hibernate.ddl-auto=create-drop"
})
class SupplierBudgetRequestPersistenceTest {

    @Autowired
    private SupplierBudgetRequestRepository repository;

    private SupplierBudgetRequest request(Long supplierId, String summary) {
        return SupplierBudgetRequest.builder()
                .supplierId(supplierId)
                .organizationCode("00000000-0000-0000-0000-000000000001")
                .requestedByUserId(7L)
                .summary(summary)
                .build();
    }

    @Test
    void newRequest_defaultsToStatusNew() {
        SupplierBudgetRequest saved = repository.saveAndFlush(request(1L, "Recarga de extintores"));
        assertThat(saved.getStatus()).isEqualTo(BudgetRequestStatus.NEW);
        assertThat(saved.getStatusUpdatedAt()).isNull();
    }

    @Test
    void findAllBySupplierId_returnsOnlyThatSupplier_newestFirst() {
        SupplierBudgetRequest older = repository.saveAndFlush(request(1L, "primeiro"));
        repository.saveAndFlush(request(2L, "de outro fornecedor"));
        SupplierBudgetRequest newer = repository.saveAndFlush(request(1L, "segundo"));

        var result = repository.findAllBySupplierIdOrderByCreatedAtDescIdDesc(1L);

        assertThat(result).extracting(SupplierBudgetRequest::getId).containsExactly(newer.getId(), older.getId());
    }

    @Test
    void findByIdAndSupplierId_otherSupplier_returnsEmpty() {
        SupplierBudgetRequest saved = repository.saveAndFlush(request(1L, "pedido"));

        assertThat(repository.findByIdAndSupplierId(saved.getId(), 1L)).isPresent();
        assertThat(repository.findByIdAndSupplierId(saved.getId(), 2L)).isEmpty();
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `./mvnw -q test -Dtest=SupplierBudgetRequestPersistenceTest`
Expected: FAIL de compilação — `BudgetRequestStatus` não existe / métodos do repositório inexistentes.

- [ ] **Step 3: Migration** — `V115__add_status_to_supplier_budget_requests.sql`

```sql
-- TASK-280 (EPIC-028): status do kanban de pedidos de orçamento do fornecedor.
ALTER TABLE supplier_budget_requests
    ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'NEW',
    ADD COLUMN status_updated_at TIMESTAMP NULL;
```

- [ ] **Step 4: Enum** — `BudgetRequestStatus.java`

```java
package com.brainbyte.easy_maintenance.supplier.domain.enums;

// TASK-280: coluna do kanban do fornecedor. Só o fornecedor vê/muda; qualquer status -> qualquer status.
public enum BudgetRequestStatus {
    NEW,
    CONTACTED,
    QUOTED,
    WON,
    LOST
}
```

- [ ] **Step 5: Entidade** — em `SupplierBudgetRequest.java`, adicionar imports `com.brainbyte.easy_maintenance.supplier.domain.enums.BudgetRequestStatus` e `jakarta.persistence.EnumType`/`Enumerated` (se não cobertos por `jakarta.persistence.*`), e após o campo `summary`:

```java
    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private BudgetRequestStatus status = BudgetRequestStatus.NEW;

    @Column(name = "status_updated_at")
    private Instant statusUpdatedAt;
```

- [ ] **Step 6: Repositório** — corpo de `SupplierBudgetRequestRepository`:

```java
public interface SupplierBudgetRequestRepository extends JpaRepository<SupplierBudgetRequest, Long> {

    // TASK-280: kanban do fornecedor -- mais recente primeiro; id desempata pedidos no mesmo instante.
    List<SupplierBudgetRequest> findAllBySupplierIdOrderByCreatedAtDescIdDesc(Long supplierId);

    // TASK-280: escopo por fornecedor no PATCH -- pedido de outro fornecedor = vazio (404, sem IDOR).
    Optional<SupplierBudgetRequest> findByIdAndSupplierId(Long id, Long supplierId);
}
```

com imports `java.util.List` e `java.util.Optional`.

- [ ] **Step 7: Rodar e ver passar**

Run: `./mvnw -q test -Dtest=SupplierBudgetRequestPersistenceTest,SupplierBudgetRequestServiceTest`
Expected: PASS (inclui o teste existente do `create`, que não pode regredir com o `@Builder.Default`).

- [ ] **Step 8: Commit**

```bash
git add src/main/resources/db/migration/V115__add_status_to_supplier_budget_requests.sql src/main/java/com/brainbyte/easy_maintenance/supplier src/test/java/com/brainbyte/easy_maintenance/supplier/infrastructure/persistence/SupplierBudgetRequestPersistenceTest.java
git commit -m "feat(supplier): status do pedido de orcamento + finders escopados por fornecedor (TASK-280)"
```

---

### Task 2: `SupplierBudgetInboxService` + DTOs

**Files:**
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/SupplierBudgetRequestView.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/UpdateBudgetRequestStatusRequest.java`
- Create: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierBudgetInboxService.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/service/SupplierBudgetInboxServiceTest.java`
- Test: `src/test/java/com/brainbyte/easy_maintenance/supplier_billing/application/dto/UpdateBudgetRequestStatusRequestTest.java`

**Interfaces:**
- Consumes: Task 1 (`BudgetRequestStatus`, finders, getters/setters); `SupplierAccessTokenRepository#findByToken(String): Optional<SupplierAccessToken>`; `OrganizationRepository#findAllByCodeIn(Collection<String>): List<Organization>` e `#findByCode(String): Optional<Organization>`; `UserRepository#findAllById(Iterable<Long>)`/`#findById(Long)`.
- Produces:
  - `record SupplierBudgetRequestView(Long id, String organizationName, String neighborhood, String city, String state, String requesterName, String requesterEmail, String requesterPhone, String summary, Instant createdAt, BudgetRequestStatus status, Instant statusUpdatedAt)`
  - `record UpdateBudgetRequestStatusRequest(@NotNull BudgetRequestStatus status)`
  - `List<SupplierBudgetRequestView> SupplierBudgetInboxService#list(String token)`
  - `SupplierBudgetRequestView SupplierBudgetInboxService#updateStatus(String token, Long requestId, BudgetRequestStatus status)`

- [ ] **Step 1: Testes (falham)** — `SupplierBudgetInboxServiceTest.java`

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.org_users.domain.Organization;
import com.brainbyte.easy_maintenance.org_users.domain.User;
import com.brainbyte.easy_maintenance.org_users.infrastructure.persistence.OrganizationRepository;
import com.brainbyte.easy_maintenance.org_users.infrastructure.persistence.UserRepository;
import com.brainbyte.easy_maintenance.supplier.domain.SupplierBudgetRequest;
import com.brainbyte.easy_maintenance.supplier.domain.enums.BudgetRequestStatus;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierBudgetRequestRepository;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SupplierBudgetRequestView;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierAccessToken;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierAccessTokenRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SupplierBudgetInboxServiceTest {

    private static final String ORG_CODE = "11111111-1111-1111-1111-111111111111";

    @Mock SupplierAccessTokenRepository accessTokenRepository;
    @Mock SupplierBudgetRequestRepository budgetRequestRepository;
    @Mock OrganizationRepository organizationRepository;
    @Mock UserRepository userRepository;
    @InjectMocks SupplierBudgetInboxService service;

    private void tokenFor(Long supplierId) {
        when(accessTokenRepository.findByToken("tok"))
                .thenReturn(Optional.of(SupplierAccessToken.builder().supplierId(supplierId).token("tok").build()));
    }

    private SupplierBudgetRequest request(Long id, Long supplierId) {
        return SupplierBudgetRequest.builder().id(id).supplierId(supplierId).organizationCode(ORG_CODE)
                .requestedByUserId(7L).summary("Recarga de 5 extintores").createdAt(Instant.parse("2026-09-20T10:00:00Z"))
                .build();
    }

    private Organization org() {
        return Organization.builder().code(ORG_CODE).name("Condomínio Jardins").neighborhood("Centro")
                .city("Belo Horizonte").state("MG").build();
    }

    private User user(String phone) {
        return User.builder().id(7L).name("Ana Síndica").email("ana@condominio.com").phoneNumber(phone).build();
    }

    @Test
    void list_returnsSupplierRequestsWithOrganizationAndRequesterContact() {
        tokenFor(100L);
        when(budgetRequestRepository.findAllBySupplierIdOrderByCreatedAtDescIdDesc(100L)).thenReturn(List.of(request(1L, 100L)));
        when(organizationRepository.findAllByCodeIn(any())).thenReturn(List.of(org()));
        when(userRepository.findAllById(any())).thenReturn(List.of(user("(31) 99876-5432")));

        List<SupplierBudgetRequestView> result = service.list("tok");

        assertThat(result).hasSize(1);
        SupplierBudgetRequestView view = result.get(0);
        assertThat(view.organizationName()).isEqualTo("Condomínio Jardins");
        assertThat(view.neighborhood()).isEqualTo("Centro");
        assertThat(view.city()).isEqualTo("Belo Horizonte");
        assertThat(view.state()).isEqualTo("MG");
        assertThat(view.requesterName()).isEqualTo("Ana Síndica");
        assertThat(view.requesterEmail()).isEqualTo("ana@condominio.com");
        assertThat(view.requesterPhone()).isEqualTo("(31) 99876-5432");
        assertThat(view.status()).isEqualTo(BudgetRequestStatus.NEW);
    }

    @Test
    void list_requesterWithoutPhone_returnsNullPhone() {
        tokenFor(100L);
        when(budgetRequestRepository.findAllBySupplierIdOrderByCreatedAtDescIdDesc(100L)).thenReturn(List.of(request(1L, 100L)));
        when(organizationRepository.findAllByCodeIn(any())).thenReturn(List.of(org()));
        when(userRepository.findAllById(any())).thenReturn(List.of(user(null)));

        assertThat(service.list("tok").get(0).requesterPhone()).isNull();
    }

    @Test
    void list_missingOrganizationAndUser_usesPlaceholderAndNullContact() {
        tokenFor(100L);
        when(budgetRequestRepository.findAllBySupplierIdOrderByCreatedAtDescIdDesc(100L)).thenReturn(List.of(request(1L, 100L)));
        when(organizationRepository.findAllByCodeIn(any())).thenReturn(List.of());
        when(userRepository.findAllById(any())).thenReturn(List.of());

        SupplierBudgetRequestView view = service.list("tok").get(0);

        assertThat(view.organizationName()).isEqualTo("—");
        assertThat(view.requesterName()).isEqualTo("—");
        assertThat(view.requesterEmail()).isNull();
        assertThat(view.requesterPhone()).isNull();
        assertThat(view.summary()).isEqualTo("Recarga de 5 extintores");
    }

    @Test
    void list_noRequests_returnsEmptyWithoutLookups() {
        tokenFor(100L);
        when(budgetRequestRepository.findAllBySupplierIdOrderByCreatedAtDescIdDesc(100L)).thenReturn(List.of());

        assertThat(service.list("tok")).isEmpty();
        verify(organizationRepository, never()).findAllByCodeIn(any());
    }

    @Test
    void list_invalidToken_throwsNotFound() {
        when(accessTokenRepository.findByToken("tok")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.list("tok")).isInstanceOf(NotFoundException.class);
    }

    @Test
    void updateStatus_ownRequest_updatesStatusAndTimestamp() {
        tokenFor(100L);
        SupplierBudgetRequest existing = request(1L, 100L);
        when(budgetRequestRepository.findByIdAndSupplierId(1L, 100L)).thenReturn(Optional.of(existing));
        when(budgetRequestRepository.save(existing)).thenReturn(existing);
        when(organizationRepository.findByCode(ORG_CODE)).thenReturn(Optional.of(org()));
        when(userRepository.findById(7L)).thenReturn(Optional.of(user("(31) 99876-5432")));

        SupplierBudgetRequestView view = service.updateStatus("tok", 1L, BudgetRequestStatus.QUOTED);

        assertThat(view.status()).isEqualTo(BudgetRequestStatus.QUOTED);
        assertThat(view.statusUpdatedAt()).isNotNull();
        assertThat(existing.getStatus()).isEqualTo(BudgetRequestStatus.QUOTED);
        verify(budgetRequestRepository).save(existing);
    }

    @Test
    void updateStatus_requestOfAnotherSupplier_throwsNotFoundAndDoesNotSave() {
        tokenFor(100L);
        when(budgetRequestRepository.findByIdAndSupplierId(1L, 100L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.updateStatus("tok", 1L, BudgetRequestStatus.WON))
                .isInstanceOf(NotFoundException.class);
        verify(budgetRequestRepository, never()).save(any());
    }

    @Test
    void updateStatus_invalidToken_throwsNotFoundAndDoesNotSave() {
        when(accessTokenRepository.findByToken("tok")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.updateStatus("tok", 1L, BudgetRequestStatus.WON))
                .isInstanceOf(NotFoundException.class);
        verify(budgetRequestRepository, never()).findByIdAndSupplierId(anyLong(), anyLong());
        verify(budgetRequestRepository, never()).save(any());
    }
}
```

e `UpdateBudgetRequestStatusRequestTest.java`:

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.dto;

import com.brainbyte.easy_maintenance.supplier.domain.enums.BudgetRequestStatus;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class UpdateBudgetRequestStatusRequestTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void nullStatus_hasViolation() {
        assertThat(validator.validate(new UpdateBudgetRequestStatusRequest(null))).isNotEmpty();
    }

    @Test
    void validStatus_noViolations() {
        assertThat(validator.validate(new UpdateBudgetRequestStatusRequest(BudgetRequestStatus.CONTACTED))).isEmpty();
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `./mvnw -q test -Dtest=SupplierBudgetInboxServiceTest,UpdateBudgetRequestStatusRequestTest`
Expected: FAIL de compilação — classes inexistentes. (Se `Organization`/`User` não tiverem `@Builder`, ajustar os helpers do teste pra construtor/setters — `User` tem `@Builder`; conferir `Organization` e ledger a ruling.)

- [ ] **Step 3: DTOs**

`SupplierBudgetRequestView.java`:

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.dto;

import com.brainbyte.easy_maintenance.supplier.domain.enums.BudgetRequestStatus;

import java.time.Instant;

// TASK-280: pedido de orçamento como o fornecedor vê no kanban (link mágico). Nunca expõe
// organizationCode nem ids de usuário/organização.
public record SupplierBudgetRequestView(
        Long id,
        String organizationName,
        String neighborhood,
        String city,
        String state,
        String requesterName,
        String requesterEmail,
        String requesterPhone,
        String summary,
        Instant createdAt,
        BudgetRequestStatus status,
        Instant statusUpdatedAt
) {}
```

`UpdateBudgetRequestStatusRequest.java`:

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.dto;

import com.brainbyte.easy_maintenance.supplier.domain.enums.BudgetRequestStatus;
import jakarta.validation.constraints.NotNull;

public record UpdateBudgetRequestStatusRequest(@NotNull BudgetRequestStatus status) {}
```

- [ ] **Step 4: Serviço** — `SupplierBudgetInboxService.java`

```java
package com.brainbyte.easy_maintenance.supplier_billing.application.service;

import com.brainbyte.easy_maintenance.commons.exceptions.NotFoundException;
import com.brainbyte.easy_maintenance.org_users.domain.Organization;
import com.brainbyte.easy_maintenance.org_users.domain.User;
import com.brainbyte.easy_maintenance.org_users.infrastructure.persistence.OrganizationRepository;
import com.brainbyte.easy_maintenance.org_users.infrastructure.persistence.UserRepository;
import com.brainbyte.easy_maintenance.supplier.domain.SupplierBudgetRequest;
import com.brainbyte.easy_maintenance.supplier.domain.enums.BudgetRequestStatus;
import com.brainbyte.easy_maintenance.supplier.infrastructure.persistence.SupplierBudgetRequestRepository;
import com.brainbyte.easy_maintenance.supplier_billing.application.dto.SupplierBudgetRequestView;
import com.brainbyte.easy_maintenance.supplier_billing.domain.SupplierAccessToken;
import com.brainbyte.easy_maintenance.supplier_billing.infrastructure.persistence.SupplierAccessTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * TASK-280 (EPIC-028): pedidos de orçamento recebidos pelo fornecedor, via link mágico. O token
 * resolve o fornecedor; todo acesso a pedido é escopado por supplierId -- pedido de outro
 * fornecedor responde 404 idêntico a inexistente (sem IDOR). Contato de quem pediu é exposto
 * porque o modal "Solicitar orçamento" avisa o compartilhamento (spec 2026-09-24).
 */
@Service
@RequiredArgsConstructor
public class SupplierBudgetInboxService {

    private static final String UNKNOWN = "—";

    private final SupplierAccessTokenRepository accessTokenRepository;
    private final SupplierBudgetRequestRepository budgetRequestRepository;
    private final OrganizationRepository organizationRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<SupplierBudgetRequestView> list(String token) {
        Long supplierId = resolveSupplierId(token);
        List<SupplierBudgetRequest> requests = budgetRequestRepository.findAllBySupplierIdOrderByCreatedAtDescIdDesc(supplierId);
        if (requests.isEmpty()) {
            return List.of();
        }

        Map<String, Organization> organizations = organizationRepository.findAllByCodeIn(
                        requests.stream().map(SupplierBudgetRequest::getOrganizationCode).collect(Collectors.toSet()))
                .stream()
                .collect(Collectors.toMap(Organization::getCode, Function.identity(), (a, b) -> a));
        Map<Long, User> users = userRepository.findAllById(
                        requests.stream().map(SupplierBudgetRequest::getRequestedByUserId).collect(Collectors.toSet()))
                .stream()
                .collect(Collectors.toMap(User::getId, Function.identity(), (a, b) -> a));

        return requests.stream()
                .map(r -> toView(r, organizations.get(r.getOrganizationCode()), users.get(r.getRequestedByUserId())))
                .toList();
    }

    @Transactional
    public SupplierBudgetRequestView updateStatus(String token, Long requestId, BudgetRequestStatus status) {
        Long supplierId = resolveSupplierId(token);
        SupplierBudgetRequest request = budgetRequestRepository.findByIdAndSupplierId(requestId, supplierId)
                .orElseThrow(() -> new NotFoundException("Pedido não encontrado"));

        request.setStatus(status);
        request.setStatusUpdatedAt(Instant.now());
        SupplierBudgetRequest saved = budgetRequestRepository.save(request);

        Organization organization = organizationRepository.findByCode(saved.getOrganizationCode()).orElse(null);
        User user = userRepository.findById(saved.getRequestedByUserId()).orElse(null);
        return toView(saved, organization, user);
    }

    private Long resolveSupplierId(String token) {
        return accessTokenRepository.findByToken(token)
                .map(SupplierAccessToken::getSupplierId)
                .orElseThrow(() -> new NotFoundException("Link inválido ou expirado"));
    }

    private SupplierBudgetRequestView toView(SupplierBudgetRequest r, Organization organization, User user) {
        return new SupplierBudgetRequestView(
                r.getId(),
                organization != null ? organization.getName() : UNKNOWN,
                organization != null ? organization.getNeighborhood() : null,
                organization != null ? organization.getCity() : null,
                organization != null ? organization.getState() : null,
                user != null ? user.getName() : UNKNOWN,
                user != null ? user.getEmail() : null,
                user != null ? user.getPhoneNumber() : null,
                r.getSummary(),
                r.getCreatedAt(),
                r.getStatus(),
                r.getStatusUpdatedAt()
        );
    }
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `./mvnw -q test -Dtest=SupplierBudgetInboxServiceTest,UpdateBudgetRequestStatusRequestTest`
Expected: PASS (10 testes).

- [ ] **Step 6: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier_billing src/test/java/com/brainbyte/easy_maintenance/supplier_billing
git commit -m "feat(supplier): servico de pedidos de orcamento do fornecedor via link magico (TASK-280)"
```

---

### Task 3: Endpoints + validação da V115 no MySQL + smoke

**Files:**
- Modify: `src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/web/SupplierPublicController.java`

**Interfaces:**
- Consumes: `SupplierBudgetInboxService#list`, `#updateStatus`; `UpdateBudgetRequestStatusRequest`; `SupplierBudgetRequestView` (Task 2)
- Produces: `GET /easy-maintenance/api/v1/public/suppliers/manage/{token}/budget-requests` → `SupplierBudgetRequestView[]`; `PATCH /easy-maintenance/api/v1/public/suppliers/manage/{token}/budget-requests/{id}` body `{"status": "NEW|CONTACTED|QUOTED|WON|LOST"}` → `SupplierBudgetRequestView`

- [ ] **Step 1: Endpoints** — em `SupplierPublicController`, adicionar o campo `private final SupplierBudgetInboxService budgetInboxService;` (junto dos demais, `@RequiredArgsConstructor` já existe), imports dos DTOs/serviço/`PatchMapping`/`java.util.List` se faltarem, e após `updateManaged`:

```java
    @GetMapping("/manage/{token}/budget-requests")
    @RateLimit("supplier-manage")
    @Operation(summary = "Lista os pedidos de orçamento recebidos pelo fornecedor via link mágico")
    public List<SupplierBudgetRequestView> listBudgetRequests(@PathVariable String token) {
        return budgetInboxService.list(token);
    }

    @PatchMapping("/manage/{token}/budget-requests/{id}")
    @RateLimit("supplier-manage")
    @Operation(summary = "Move um pedido de orçamento do fornecedor para outra coluna do kanban")
    public SupplierBudgetRequestView updateBudgetRequestStatus(@PathVariable String token, @PathVariable Long id,
                                                               @RequestBody @Valid UpdateBudgetRequestStatusRequest request) {
        return budgetInboxService.updateStatus(token, id, request.status());
    }
```

- [ ] **Step 2: Suíte completa**

Run: `./mvnw -q test > ../.mvn-test-task3.log 2>&1; tail -30 ../.mvn-test-task3.log` (depois apagar o log)
Expected: BUILD SUCCESS, sem falha nova (último baseline registrado: 1075/1075 + testes novos).

- [ ] **Step 3: Subir a API local contra o MySQL do Docker (valida a V115 de verdade)**

Garantir `easy_maintenance_mysql` rodando (`docker ps`). Subir a API com o profile local usado no dia a dia (ex.: `./mvnw spring-boot:run` — conferir no README/`application-*.properties` o profile/porta; o front local aponta pra `localhost:9000`). Expected no log: `Migrating schema ... to version "115 - add status to supplier budget requests"` e `Started ...`. Conferir no banco:

```bash
docker exec easy_maintenance_mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW COLUMNS FROM supplier_budget_requests LIKE 'status%'" <database>
```

Expected: `status varchar(20) NO NEW` e `status_updated_at timestamp YES NULL`. (Credenciais/banco: as do `docker-compose`/`.env` local — não commitar.)

- [ ] **Step 4: Smoke com `curl`** (dados locais: um fornecedor auto-cadastrado com token, um pedido criado por usuário de organização via `/fornecedores` — ou `INSERT` manual em `supplier_budget_requests` pro fornecedor do token; e um segundo fornecedor com pedido próprio)

```bash
BASE=http://localhost:9000/easy-maintenance/api/v1/public/suppliers/manage
curl -s $BASE/<TOKEN_A>/budget-requests                                   # 200, só pedidos do A, com contato
curl -s -o /dev/null -w "%{http_code}\n" -X PATCH -H "Content-Type: application/json" -d '{"status":"QUOTED"}' $BASE/<TOKEN_A>/budget-requests/<ID_DO_A>   # 200
curl -s -o /dev/null -w "%{http_code}\n" -X PATCH -H "Content-Type: application/json" -d '{"status":"WON"}' $BASE/<TOKEN_A>/budget-requests/<ID_DO_B>      # 404
curl -s -o /dev/null -w "%{http_code}\n" -X PATCH -H "Content-Type: application/json" -d '{"status":"XYZ"}' $BASE/<TOKEN_A>/budget-requests/<ID_DO_A>      # 400
curl -s -o /dev/null -w "%{http_code}\n" -X PATCH -H "Content-Type: application/json" -d '{}' $BASE/<TOKEN_A>/budget-requests/<ID_DO_A>                   # 400
curl -s -o /dev/null -w "%{http_code}\n" $BASE/token-invalido/budget-requests                                                                                # 404
```

Expected: exatamente os códigos comentados; pedido do B continua com o status original (conferir via `GET` com `TOKEN_B`). Manter a API rodando pra Task 7.

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/brainbyte/easy_maintenance/supplier_billing/infrastructure/web/SupplierPublicController.java
git commit -m "feat(supplier): endpoints GET/PATCH de pedidos de orcamento do fornecedor (TASK-280)"
```

---

### Task 4: Lógica pura do quadro + cliente da API (web)

**Files:**
- Create: `src/lib/supplierBudgetBoard.ts`
- Test: `src/lib/supplierBudgetBoard.test.ts`
- Modify: `src/app/fornecedores/cadastro/_lib/publicSupplierApi.ts`

**Interfaces:**
- Consumes: contrato HTTP da Task 3.
- Produces (`src/lib/supplierBudgetBoard.ts`):
  - `type BudgetRequestStatus = "NEW" | "CONTACTED" | "QUOTED" | "WON" | "LOST"`
  - `interface SupplierBudgetRequest { id: number; organizationName: string; neighborhood: string | null; city: string | null; state: string | null; requesterName: string; requesterEmail: string | null; requesterPhone: string | null; summary: string; createdAt: string; status: BudgetRequestStatus; statusUpdatedAt: string | null }`
  - `const BOARD_COLUMNS: { status: BudgetRequestStatus; label: string }[]`
  - `groupByStatus(requests: SupplierBudgetRequest[]): Record<BudgetRequestStatus, SupplierBudgetRequest[]>`
  - `whatsappLink(phone: string | null, requesterName: string, supplierName: string): string | null`
  - `timeAgo(iso: string, now?: Date): string`
  - `applyStatusChange(requests: SupplierBudgetRequest[], id: number, status: BudgetRequestStatus): { next: SupplierBudgetRequest[]; previous: BudgetRequestStatus | null }`
- Produces (`publicSupplierApi.ts`): `getSupplierBudgetRequests(token: string): Promise<SupplierBudgetRequest[]>`, `updateSupplierBudgetRequestStatus(token: string, id: number, status: BudgetRequestStatus): Promise<SupplierBudgetRequest>`

- [ ] **Step 0: Branch**

```bash
cd /d/workpaces/EASY_MAINTENANCE/easy-maintenance-web
git fetch origin && git checkout -b feature/TASK-280-kanban-pedidos-fornecedor origin/staging
```

- [ ] **Step 1: Testes (falham)** — `src/lib/supplierBudgetBoard.test.ts`

```ts
import {
    BOARD_COLUMNS, groupByStatus, whatsappLink, timeAgo, applyStatusChange, SupplierBudgetRequest,
} from "./supplierBudgetBoard";

const req = (id: number, status: SupplierBudgetRequest["status"] = "NEW"): SupplierBudgetRequest => ({
    id, organizationName: "Condomínio Jardins", neighborhood: "Centro", city: "Belo Horizonte", state: "MG",
    requesterName: "Ana", requesterEmail: "ana@x.com", requesterPhone: "(31) 99876-5432",
    summary: "Recarga de extintores", createdAt: "2026-09-20T10:00:00Z", status, statusUpdatedAt: null,
});

describe("BOARD_COLUMNS", () => {
    it("tem as 5 colunas na ordem do funil com os rótulos do spec", () => {
        expect(BOARD_COLUMNS).toEqual([
            { status: "NEW", label: "Novo" },
            { status: "CONTACTED", label: "Em contato" },
            { status: "QUOTED", label: "Orçamento enviado" },
            { status: "WON", label: "Fechado" },
            { status: "LOST", label: "Perdido" },
        ]);
    });
});

describe("groupByStatus", () => {
    it("agrupa preservando a ordem de entrada e cria colunas vazias", () => {
        const grouped = groupByStatus([req(3, "QUOTED"), req(2), req(1)]);
        expect(grouped.NEW.map((r) => r.id)).toEqual([2, 1]);
        expect(grouped.QUOTED.map((r) => r.id)).toEqual([3]);
        expect(grouped.CONTACTED).toEqual([]);
        expect(grouped.WON).toEqual([]);
        expect(grouped.LOST).toEqual([]);
    });
});

describe("whatsappLink", () => {
    it("normaliza telefone com máscara e prefixa 55", () => {
        const link = whatsappLink("(31) 99876-5432", "Ana", "Extintores Silva");
        expect(link).toMatch(/^https:\/\/wa\.me\/5531998765432\?text=/);
        expect(decodeURIComponent(link!.split("text=")[1])).toContain("Ana");
        expect(decodeURIComponent(link!.split("text=")[1])).toContain("Extintores Silva");
    });

    it("não duplica o 55 quando já vem com DDI", () => {
        expect(whatsappLink("+55 31 99876-5432", "Ana", "X")).toMatch(/^https:\/\/wa\.me\/5531998765432\?/);
    });

    it("aceita fixo com DDD (10 dígitos)", () => {
        expect(whatsappLink("(31) 3222-1111", "Ana", "X")).toMatch(/^https:\/\/wa\.me\/553132221111\?/);
    });

    it.each([null, "", "12345", "abc"])("retorna null pra telefone ausente/inválido (%p)", (phone) => {
        expect(whatsappLink(phone as string | null, "Ana", "X")).toBeNull();
    });
});

describe("timeAgo", () => {
    const now = new Date("2026-09-24T12:00:00Z");
    it.each([
        ["2026-09-24T08:00:00Z", "hoje"],
        ["2026-09-23T10:00:00Z", "ontem"],
        ["2026-09-21T12:00:00Z", "há 3 dias"],
    ])("%s → %s", (iso, expected) => {
        expect(timeAgo(iso, now)).toBe(expected);
    });
});

describe("applyStatusChange", () => {
    it("muda o status do pedido e devolve o anterior sem mutar a lista original", () => {
        const original = [req(1), req(2, "CONTACTED")];
        const { next, previous } = applyStatusChange(original, 2, "WON");
        expect(previous).toBe("CONTACTED");
        expect(next.find((r) => r.id === 2)!.status).toBe("WON");
        expect(original[1].status).toBe("CONTACTED");
    });

    it("reverter com o status anterior restaura o estado", () => {
        const { next, previous } = applyStatusChange([req(1)], 1, "LOST");
        const reverted = applyStatusChange(next, 1, previous!).next;
        expect(reverted[0].status).toBe("NEW");
    });

    it("id inexistente não altera nada e previous é null", () => {
        const original = [req(1)];
        const { next, previous } = applyStatusChange(original, 99, "WON");
        expect(previous).toBeNull();
        expect(next).toEqual(original);
    });
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `npx jest supplierBudgetBoard`
Expected: FAIL — `Cannot find module './supplierBudgetBoard'`

- [ ] **Step 3: Implementar** — `src/lib/supplierBudgetBoard.ts`

```ts
/**
 * TASK-280 (EPIC-028): lógica pura do kanban de pedidos de orçamento do fornecedor
 * (/fornecedores/gerenciar/[token]). Sem React -- testável no Jest `node`.
 */

export type BudgetRequestStatus = "NEW" | "CONTACTED" | "QUOTED" | "WON" | "LOST";

export interface SupplierBudgetRequest {
    id: number;
    organizationName: string;
    neighborhood: string | null;
    city: string | null;
    state: string | null;
    requesterName: string;
    requesterEmail: string | null;
    requesterPhone: string | null;
    summary: string;
    createdAt: string;
    status: BudgetRequestStatus;
    statusUpdatedAt: string | null;
}

export const BOARD_COLUMNS: { status: BudgetRequestStatus; label: string }[] = [
    { status: "NEW", label: "Novo" },
    { status: "CONTACTED", label: "Em contato" },
    { status: "QUOTED", label: "Orçamento enviado" },
    { status: "WON", label: "Fechado" },
    { status: "LOST", label: "Perdido" },
];

export function groupByStatus(requests: SupplierBudgetRequest[]): Record<BudgetRequestStatus, SupplierBudgetRequest[]> {
    const grouped = { NEW: [], CONTACTED: [], QUOTED: [], WON: [], LOST: [] } as Record<BudgetRequestStatus, SupplierBudgetRequest[]>;
    for (const r of requests) grouped[r.status].push(r);
    return grouped;
}

export function whatsappLink(phone: string | null, requesterName: string, supplierName: string): string | null {
    if (!phone) return null;
    let digits = phone.replace(/\D/g, "");
    if ((digits.length === 12 || digits.length === 13) && digits.startsWith("55")) {
        // já com DDI
    } else if (digits.length === 10 || digits.length === 11) {
        digits = `55${digits}`;
    } else {
        return null;
    }
    const message = `Olá, ${requesterName}! Aqui é ${supplierName}. Recebi seu pedido de orçamento pelo Easy Maintenance.`;
    return `https://wa.me/${digits}?text=${encodeURIComponent(message)}`;
}

const DAY_MS = 24 * 60 * 60 * 1000;

export function timeAgo(iso: string, now: Date = new Date()): string {
    const days = Math.floor((now.getTime() - new Date(iso).getTime()) / DAY_MS);
    if (days <= 0) return "hoje";
    if (days === 1) return "ontem";
    return `há ${days} dias`;
}

export function applyStatusChange(
    requests: SupplierBudgetRequest[],
    id: number,
    status: BudgetRequestStatus,
): { next: SupplierBudgetRequest[]; previous: BudgetRequestStatus | null } {
    const current = requests.find((r) => r.id === id);
    if (!current) return { next: requests, previous: null };
    return {
        next: requests.map((r) => (r.id === id ? { ...r, status } : r)),
        previous: current.status,
    };
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `npx jest supplierBudgetBoard`
Expected: PASS.

- [ ] **Step 5: Cliente da API** — ao fim de `src/app/fornecedores/cadastro/_lib/publicSupplierApi.ts`:

```ts
import type { BudgetRequestStatus, SupplierBudgetRequest } from "@/lib/supplierBudgetBoard";

// TASK-280: kanban de pedidos de orçamento do fornecedor (mesmo token do link mágico).
export async function getSupplierBudgetRequests(token: string): Promise<SupplierBudgetRequest[]> {
  const { data } = await publicSupplierApi.get<SupplierBudgetRequest[]>(`public/suppliers/manage/${token}/budget-requests`);
  return data;
}

export async function updateSupplierBudgetRequestStatus(
  token: string,
  id: number,
  status: BudgetRequestStatus
): Promise<SupplierBudgetRequest> {
  const { data } = await publicSupplierApi.patch<SupplierBudgetRequest>(
    `public/suppliers/manage/${token}/budget-requests/${id}`,
    { status }
  );
  return data;
}
```

(mover o `import type` pro topo do arquivo, junto dos outros imports).

- [ ] **Step 6: Verificar e commit**

Run: `npx tsc --noEmit && npx eslint src/lib/supplierBudgetBoard.ts src/lib/supplierBudgetBoard.test.ts src/app/fornecedores/cadastro/_lib/publicSupplierApi.ts && npx jest supplierBudgetBoard`
Expected: limpo; PASS.

```bash
git add src/lib/supplierBudgetBoard.ts src/lib/supplierBudgetBoard.test.ts src/app/fornecedores/cadastro/_lib/publicSupplierApi.ts
git commit -m "feat(fornecedores): logica do kanban de pedidos + cliente da API (TASK-280)"
```

---

### Task 5: Componentes do quadro + abas na tela do link mágico

**Files:**
- Create: `src/components/supplier/BudgetRequestCard.tsx`
- Create: `src/components/supplier/BudgetRequestBoard.tsx`
- Modify: `src/app/fornecedores/gerenciar/[token]/page.tsx`

**Interfaces:**
- Consumes: Task 4 (tipos, `BOARD_COLUMNS`, `groupByStatus`, `whatsappLink`, `timeAgo`, `applyStatusChange`, `getSupplierBudgetRequests`, `updateSupplierBudgetRequestStatus`)
- Produces: `BudgetRequestCard({ request, supplierName, onMove }: { request: SupplierBudgetRequest; supplierName: string; onMove: (status: BudgetRequestStatus) => void })`; `BudgetRequestBoard({ requests, supplierName, onMove, onGoToProfile }: { requests: SupplierBudgetRequest[]; supplierName: string; onMove: (id: number, status: BudgetRequestStatus) => void; onGoToProfile: () => void })`

Sem teste de componente (Jest `node`, sem DOM) — gate: `tsc` + eslint + `build` + QA da Task 7.

- [ ] **Step 1: Card** — `src/components/supplier/BudgetRequestCard.tsx`

```tsx
"use client";

import { Mail, MapPin, MessageCircle, User } from "lucide-react";
import {
  BOARD_COLUMNS, BudgetRequestStatus, SupplierBudgetRequest, timeAgo, whatsappLink,
} from "@/lib/supplierBudgetBoard";

export default function BudgetRequestCard({
  request,
  supplierName,
  onMove,
}: {
  request: SupplierBudgetRequest;
  supplierName: string;
  onMove: (status: BudgetRequestStatus) => void;
}) {
  const wa = whatsappLink(request.requesterPhone, request.requesterName, supplierName);
  const place = [request.neighborhood, request.city && request.state ? `${request.city}/${request.state}` : request.city]
    .filter(Boolean)
    .join(" · ");

  return (
    <div className="card border-0 shadow-sm mb-2" style={{ borderRadius: 12 }}>
      <div className="card-body p-3">
        <div className="d-flex justify-content-between align-items-start gap-2">
          <div className="fw-semibold small text-break">{request.organizationName}</div>
          <span className="text-muted flex-shrink-0" style={{ fontSize: "0.72rem" }}>{timeAgo(request.createdAt)}</span>
        </div>
        {place && (
          <div className="text-muted d-flex align-items-center gap-1" style={{ fontSize: "0.75rem" }}>
            <MapPin size={12} /> {place}
          </div>
        )}
        <p className="small mt-2 mb-2 text-break">{request.summary}</p>
        <div className="text-muted d-flex align-items-center gap-1 mb-2" style={{ fontSize: "0.75rem" }}>
          <User size={12} /> {request.requesterName}
        </div>
        <div className="d-flex flex-wrap gap-2 mb-2">
          {wa && (
            <a href={wa} target="_blank" rel="noopener noreferrer" className="btn btn-success btn-sm rounded-pill d-inline-flex align-items-center gap-1">
              <MessageCircle size={14} /> WhatsApp
            </a>
          )}
          {request.requesterEmail && (
            <a href={`mailto:${request.requesterEmail}`} className="btn btn-outline-secondary btn-sm rounded-pill d-inline-flex align-items-center gap-1">
              <Mail size={14} /> E-mail
            </a>
          )}
        </div>
        <select
          className="form-select form-select-sm"
          aria-label={`Mover pedido de ${request.organizationName} para outra coluna`}
          value=""
          onChange={(e) => {
            if (e.target.value) onMove(e.target.value as BudgetRequestStatus);
          }}
        >
          <option value="">Mover para…</option>
          {BOARD_COLUMNS.filter((c) => c.status !== request.status).map((c) => (
            <option key={c.status} value={c.status}>{c.label}</option>
          ))}
        </select>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Quadro** — `src/components/supplier/BudgetRequestBoard.tsx`

```tsx
"use client";

import { useState } from "react";
import { Inbox } from "lucide-react";
import BudgetRequestCard from "./BudgetRequestCard";
import {
  BOARD_COLUMNS, BudgetRequestStatus, SupplierBudgetRequest, groupByStatus,
} from "@/lib/supplierBudgetBoard";

export default function BudgetRequestBoard({
  requests,
  supplierName,
  onMove,
  onGoToProfile,
}: {
  requests: SupplierBudgetRequest[];
  supplierName: string;
  onMove: (id: number, status: BudgetRequestStatus) => void;
  onGoToProfile: () => void;
}) {
  const [mobileColumn, setMobileColumn] = useState<BudgetRequestStatus>("NEW");
  const grouped = groupByStatus(requests);

  if (requests.length === 0) {
    return (
      <div className="card border-0 shadow-sm p-4 text-center mx-auto" style={{ maxWidth: 520, borderRadius: 16 }}>
        <Inbox className="text-muted mx-auto mb-2" size={32} />
        <h6 className="fw-bold">Nenhum pedido de orçamento ainda</h6>
        <p className="text-muted small mb-3">
          Os pedidos aparecem aqui quando um gestor da sua cidade solicitar orçamento pelo Easy Maintenance.
          Manter suas categorias e serviços atualizados ajuda você a ser encontrado.
        </p>
        <button type="button" className="btn btn-outline-primary btn-sm rounded-pill mx-auto" onClick={onGoToProfile}>
          Revisar meus dados
        </button>
      </div>
    );
  }

  const renderColumn = (status: BudgetRequestStatus) =>
    grouped[status].length === 0 ? (
      <p className="text-muted small text-center py-3 mb-0">Nenhum pedido aqui</p>
    ) : (
      grouped[status].map((r) => (
        <BudgetRequestCard key={r.id} request={r} supplierName={supplierName} onMove={(s) => onMove(r.id, s)} />
      ))
    );

  return (
    <>
      <style>{`
        .budget-board { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 12px; }
        .budget-filters { overflow-x: auto; white-space: nowrap; -webkit-overflow-scrolling: touch; }
      `}</style>

      {/* Mobile: filtro por coluna + lista */}
      <div className="d-lg-none">
        <div className="budget-filters d-flex gap-2 pb-2 mb-2" role="tablist" aria-label="Colunas do quadro">
          {BOARD_COLUMNS.map((c) => (
            <button
              key={c.status}
              type="button"
              role="tab"
              aria-selected={mobileColumn === c.status}
              className={`btn btn-sm rounded-pill flex-shrink-0 ${mobileColumn === c.status ? "btn-primary" : "btn-outline-secondary"}`}
              onClick={() => setMobileColumn(c.status)}
            >
              {c.label} {grouped[c.status].length}
            </button>
          ))}
        </div>
        {renderColumn(mobileColumn)}
      </div>

      {/* Desktop: 5 colunas */}
      <div className="budget-board d-none d-lg-grid">
        {BOARD_COLUMNS.map((c) => (
          <section key={c.status} className="bg-light rounded-3 p-2" aria-label={c.label}>
            <h2 className="h6 fw-bold px-1 d-flex justify-content-between">
              <span>{c.label}</span>
              <span className="badge bg-secondary-subtle text-secondary-emphasis rounded-pill">{grouped[c.status].length}</span>
            </h2>
            {renderColumn(c.status)}
          </section>
        ))}
      </div>
    </>
  );
}
```

- [ ] **Step 3: Página — estado dos pedidos e mudança otimista** — em `src/app/fornecedores/gerenciar/[token]/page.tsx`:
  - imports: `import BudgetRequestBoard from "@/components/supplier/BudgetRequestBoard";`, `import { applyStatusChange, BudgetRequestStatus, SupplierBudgetRequest } from "@/lib/supplierBudgetBoard";` e `getSupplierBudgetRequests, updateSupplierBudgetRequestStatus` no import de `publicSupplierApi`.
  - novos estados (após `const [error, setError] = useState(false);`):

```tsx
  const [tab, setTab] = useState<"pedidos" | "dados" | null>(null);
  const [requests, setRequests] = useState<SupplierBudgetRequest[]>([]);
  const [requestsLoading, setRequestsLoading] = useState(true);
  const [requestsError, setRequestsError] = useState(false);
```

  - função de carga + efeito (após o `useEffect` existente):

```tsx
  function loadRequests() {
    setRequestsLoading(true);
    setRequestsError(false);
    getSupplierBudgetRequests(token)
      .then((list) => {
        setRequests(list);
        setTab((current) => current ?? (list.length > 0 ? "pedidos" : "dados"));
      })
      .catch(() => {
        setRequestsError(true);
        setTab((current) => current ?? "dados");
      })
      .finally(() => setRequestsLoading(false));
  }

  useEffect(loadRequests, [token]); // eslint-disable-line react-hooks/exhaustive-deps

  async function handleMove(id: number, status: BudgetRequestStatus) {
    const { next, previous } = applyStatusChange(requests, id, status);
    if (previous === null) return;
    setRequests(next);
    try {
      await updateSupplierBudgetRequestStatus(token, id, status);
    } catch {
      setRequests((current) => applyStatusChange(current, id, previous).next);
      toast.error("Não foi possível mover o pedido. Tente novamente.");
    }
  }
```

  Se o eslint acusar `react-hooks/set-state-in-effect` no `useEffect(loadRequests…)` (regra ativa no repo), trocar por `useEffect(() => { loadRequests(); }, [token]);` mantendo o disable de `exhaustive-deps`; se ainda acusar, ledger a ruling (mesmo padrão já presente no `useEffect` de carga da página, que faz `setState` em `.then`).

- [ ] **Step 4: Página — layout com abas** — no JSX:
  - o wrapper `<div className="d-flex align-items-center justify-content-center py-5 px-3">` passa a `<div className="container py-4 py-md-5">`, e o bloco de loading/erro fica centralizado (`<div className="text-center">…`).
  - no bloco `{!loading && !error && data && ( … )}`, envolver o conteúdo assim (o card existente — com nome, badges, QR pendente e o form — vira o conteúdo da aba "dados"; o **QR pendente** sai do card e sobe pra antes das abas, com `mx-auto` e `maxWidth: 520`):

```tsx
          <>
            {data.qrCodePayload && (
              /* bloco do QR Code pendente existente, sem mudanças internas, dentro de: */
              <div className="mx-auto mb-3" style={{ maxWidth: 520 }}>{/* …bloco atual… */}</div>
            )}

            <div className="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
              <h1 className="h5 fw-bold mb-0">{data.name}</h1>
              <ul className="nav nav-pills" role="tablist">
                <li className="nav-item">
                  <button type="button" role="tab" aria-selected={tab === "pedidos"}
                    className={`nav-link ${tab === "pedidos" ? "active" : ""}`} onClick={() => setTab("pedidos")}>
                    Pedidos{!requestsLoading && !requestsError ? ` (${requests.length})` : ""}
                  </button>
                </li>
                <li className="nav-item">
                  <button type="button" role="tab" aria-selected={tab === "dados"}
                    className={`nav-link ${tab === "dados" ? "active" : ""}`} onClick={() => setTab("dados")}>
                    Meus dados
                  </button>
                </li>
              </ul>
            </div>

            {tab === "pedidos" && (
              requestsLoading ? (
                <div className="row g-3" aria-busy="true">
                  {[0, 1, 2].map((i) => (
                    <div className="col-12 col-lg-4" key={i}>
                      <div className="placeholder-glow"><span className="placeholder col-12 rounded-3" style={{ height: 120 }} /></div>
                    </div>
                  ))}
                </div>
              ) : requestsError ? (
                <div className="card border-0 shadow-sm p-4 text-center mx-auto" style={{ maxWidth: 520, borderRadius: 16 }}>
                  <p className="text-danger fw-semibold mb-2">Não foi possível carregar seus pedidos.</p>
                  <button type="button" className="btn btn-outline-primary btn-sm rounded-pill mx-auto" onClick={loadRequests}>
                    Tentar de novo
                  </button>
                </div>
              ) : (
                <BudgetRequestBoard requests={requests} supplierName={data.name} onMove={handleMove} onGoToProfile={() => setTab("dados")} />
              )
            )}

            {tab === "dados" && (
              /* card existente (h5 do nome pode sair — já está no título acima), com badges e o <form> atuais, dentro de: */
              <div className="mx-auto" style={{ maxWidth: 520 }}>{/* …card atual sem o bloco do QR… */}</div>
            )}
          </>
```

  Manter intactos: handlers `handleSave`/`copyPixCode`, campos do form, badges de visibilidade/assinatura.

- [ ] **Step 5: Verificar**

Run: `npx tsc --noEmit && npx eslint src/components/supplier/BudgetRequestCard.tsx src/components/supplier/BudgetRequestBoard.tsx "src/app/fornecedores/gerenciar/[token]/page.tsx" && npm run build`
Expected: sem erros novos (comparar com `git stash` se aparecer erro de lint na página — o `<img>` do logo/QR já gera warnings pré-existentes); build lista `/fornecedores/gerenciar/[token]`.

- [ ] **Step 6: Commit**

```bash
git add src/components/supplier/BudgetRequestCard.tsx src/components/supplier/BudgetRequestBoard.tsx "src/app/fornecedores/gerenciar/[token]/page.tsx"
git commit -m "feat(fornecedores): kanban de pedidos de orcamento na tela do link magico (TASK-280)"
```

---

### Task 6: Aviso LGPD no modal "Solicitar orçamento"

**Files:**
- Modify: `src/app/fornecedores/page.tsx` (bloco do `<textarea>` do modal, ~L474-484)

**Interfaces:** nenhuma (texto estático).

- [ ] **Step 1: Texto** — logo após o `<textarea … required />` e antes do `</div>` que fecha o `mb-3`:

```tsx
                    <div className="form-text" style={{ fontSize: "0.75rem" }}>
                      Seu nome, e-mail e WhatsApp serão compartilhados com o fornecedor pra ele retornar o contato.
                    </div>
```

- [ ] **Step 2: Verificar e commit**

Run: `npx tsc --noEmit && npx eslint src/app/fornecedores/page.tsx`
Expected: sem erro novo.

```bash
git add src/app/fornecedores/page.tsx
git commit -m "feat(fornecedores): aviso LGPD de compartilhamento de contato no pedido de orcamento (TASK-280)"
```

---

### Task 7: QA ponta a ponta, PRs e roadmap

- [ ] **Step 1: Suítes**

Run (web): `npm test` → só as 3 falhas pré-existentes de `middleware.test.ts`. Run (api): `./mvnw -q test` → BUILD SUCCESS.

- [ ] **Step 2: QA manual (API local da Task 3 rodando + `npm run dev` no web)**
  1. Logado como usuário de organização em `/fornecedores`: abrir "Solicitar orçamento" de um fornecedor auto-cadastrado → aviso LGPD visível → enviar.
  2. `/fornecedores/gerenciar/<token>` desse fornecedor (deslogado): aba "Pedidos (N)" aberta por padrão; pedido em "Novo" com organização, bairro/cidade, nome, resumo, "hoje".
  3. Mover pelas 5 colunas pelo "Mover para…"; recarregar → status persistido.
  4. Botão WhatsApp abre `wa.me/55…` com mensagem; E-mail abre `mailto:`.
  5. Parar a API e mover um card → card volta + toast de erro; reiniciar a API.
  6. 390px: filtros por coluna, `document.documentElement.scrollWidth === document.documentElement.clientWidth`; 1366px: 5 colunas.
  7. Fornecedor sem pedidos → abre em "Meus dados"; aba "Pedidos (0)" mostra o estado vazio com "Revisar meus dados".
  8. Aba "Meus dados": salvar alteração funciona; fornecedor com pagamento pendente mostra o QR acima das abas.
  9. Token inválido → "Link inválido ou expirado." (comportamento atual).

- [ ] **Step 3: Push + PRs contra `staging`** (api e web), corpo com resumo, validação do QA acima e o risco do token sem expiração (spec).

- [ ] **Step 4: Roadmap** (repo raiz) — `roadmap/tasks/TASK-280.md` (critérios, implementação, PRs, status `🟡 Em Validação`), entrada no topo de `roadmap/kanban.md`, linha no `roadmap/epics/EPIC-028.md`; commit `chore(roadmap): TASK-280 - implementada, PRs abertas contra staging`.
