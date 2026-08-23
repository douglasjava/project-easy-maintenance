# TASK-190 — Backend: substitui `operating_expense_rates` por `expenses` + `manual_commission_rules`

## Tipo
BACKEND

## Categoria
Admin / Financeiro

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Fase 2

## QA obrigatório
Não precisa QA manual — é camada de dado + migration, coberta por teste automatizado. Validar com
query direta no banco pós-migration que `operating_expense_rates` não existe mais e as duas tabelas
novas foram criadas vazias.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-23-financial-module-design.md`.

Base pras TASK-191 (CRUD) e TASK-192 (cálculo financeiro). Hoje despesa é uma taxa mensal
recorrente por categoria (`operating_expense_rates`) — Douglas decidiu substituir por completo por
lançamento avulso (um registro por despesa, como numa planilha), e criar do zero um modelo pra
comissão manual (regra recorrente de % sobre o líquido), que não existe hoje. Decisão explícita:
**sem migrar os dados históricos** de `operating_expense_rates` — a tabela é derrubada.

## Objetivo

Migration substituindo `operating_expense_rates` pelas tabelas `expenses` e
`manual_commission_rules`, com as entidades JPA e enum correspondentes.

## Escopo

### 1. Migration (próximo número livre em `db/migration/`, confirmar V93 contra o estado real da
pasta antes de escrever)

```sql
DROP TABLE IF EXISTS operating_expense_rates;

CREATE TABLE expenses (
    id            BIGINT PRIMARY KEY AUTO_INCREMENT,
    category      VARCHAR(30) NOT NULL,
    description   VARCHAR(255) NOT NULL,
    amount_cents  BIGINT NOT NULL,
    expense_date  DATE NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE manual_commission_rules (
    id               BIGINT PRIMARY KEY AUTO_INCREMENT,
    payee_name       VARCHAR(120) NOT NULL,
    percentage       DECIMAL(5,4) NOT NULL,
    effective_from   DATE NOT NULL,
    effective_to     DATE NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 2. Enum novo — `ExpenseCategory` (substitui o atual)

```java
package com.brainbyte.easy_maintenance.billing.domain.enums;

public enum ExpenseCategory {
    FORNECEDOR, INFRA, MARKETING, IMPOSTOS_TAXAS, FOLHA_PROLABORE, JURIDICO_CONTABIL,
    FERRAMENTAS_SAAS, OUTROS
}
```

O enum atual (`RAILWAY, OPENAI, S3, ASAAS_FEES, OUTROS`) é removido junto com
`OperatingExpenseRate` — nenhum código deve mais referenciá-lo depois desta task.

### 3. Entidade `Expense` (nova)

```java
package com.brainbyte.easy_maintenance.billing.domain;

import com.brainbyte.easy_maintenance.billing.domain.enums.ExpenseCategory;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.time.LocalDate;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "expenses")
public class Expense {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private ExpenseCategory category;

    @Column(nullable = false)
    private String description;

    @Column(name = "amount_cents", nullable = false)
    private Long amountCents;

    @Column(name = "expense_date", nullable = false)
    private LocalDate expenseDate;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
```

### 4. Entidade `ManualCommissionRule` (nova)

```java
package com.brainbyte.easy_maintenance.billing.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "manual_commission_rules")
public class ManualCommissionRule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "payee_name", nullable = false, length = 120)
    private String payeeName;

    @Column(nullable = false, precision = 5, scale = 4)
    private BigDecimal percentage;

    @Column(name = "effective_from", nullable = false)
    private LocalDate effectiveFrom;

    @Column(name = "effective_to")
    private LocalDate effectiveTo;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
```

### 5. Repositórios

`ExpenseRepository extends JpaRepository<Expense, Long>, JpaSpecificationExecutor<Expense>` — vai
precisar de filtro por categoria/período na TASK-191, mesmo padrão `Specification` já usado em
`PaymentRepository`/`LandingLeadRepository`.

`ManualCommissionRuleRepository extends JpaRepository<ManualCommissionRule, Long>` — sem
`Specification` por ora, a listagem é simples (todas as regras).

### 6. Remover código morto

Deletar `OperatingExpenseRate.java`, `OperatingExpenseRateRepository.java`,
`OperatingExpenseRateDTO.java`, `OperatingExpenseRateService.java`, e o `ExpenseCategory` antigo —
nenhum resíduo órfão (pedido explícito de Douglas).

## Critérios de Aceite

- [ ] `operating_expense_rates` não existe mais no banco após a migration
- [ ] `expenses` e `manual_commission_rules` criadas conforme o schema acima
- [ ] `Expense`, `ManualCommissionRule` mapeadas corretamente, com repositórios básicos
- [ ] `OperatingExpenseRate` e todo código relacionado (entidade, repositório, DTO, serviço, enum
      antigo) removidos do projeto
- [ ] `mvn test` sem regressão

## Dependências
Nenhuma técnica. Precede TASK-191 e TASK-192 (usam as tabelas/entidades novas).

## Riscos
Baixo-Médio — `DROP TABLE` é destrutivo, mas foi decisão explícita de Douglas (sem migração de
histórico); nenhum outro módulo do sistema depende de `operating_expense_rates` além do próprio
`FinancialsService` (TASK-192 trata disso na mesma leva).

## Esforço
Baixo-Médio

## Status
🔵 Backlog
