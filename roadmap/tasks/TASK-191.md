# TASK-191 — Backend: CRUD de despesas e regras de comissão manual

## Tipo
BACKEND

## Categoria
Admin / Financeiro

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Fase 2

## QA obrigatório
Sim — QA manual: cadastrar despesa em cada categoria, remover, cadastrar regra de comissão manual,
encerrar, confirmar que regra encerrada continua listada (não some) e que `DELETE` remove de fato.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-23-financial-module-design.md`.

Depende da TASK-190 (`expenses`, `manual_commission_rules`). É a camada de gestão manual — sem
isso, Douglas não tem como registrar nada, só a leitura calculada (TASK-192) existiria.

## Objetivo

Endpoints de listar/criar/remover despesa, e listar/criar/encerrar/remover regra de comissão
manual, sob o novo prefixo `/private/admin/financials`.

## Escopo

### 1. DTOs

```java
public record CreateExpenseRequest(
        @NotNull ExpenseCategory category,
        @NotBlank String description,
        @NotNull @Positive Long amountCents,
        @NotNull LocalDate expenseDate
) {}

public record ExpenseResponse(
        Long id, ExpenseCategory category, String description, Long amountCents,
        LocalDate expenseDate, Instant createdAt
) {}

public record CreateManualCommissionRuleRequest(
        @NotBlank String payeeName,
        @NotNull @DecimalMin("0.0001") @DecimalMax("1.0") BigDecimal percentage,
        @NotNull LocalDate effectiveFrom
) {}

public record ManualCommissionRuleResponse(
        Long id, String payeeName, BigDecimal percentage,
        LocalDate effectiveFrom, LocalDate effectiveTo, boolean active
) {}
```

`active` em `ManualCommissionRuleResponse` é derivado (`effectiveTo == null`), não uma coluna —
evita duplicar estado que já é expresso por `effectiveTo`.

### 2. `ExpenseService`

```java
public PageResponse<ExpenseResponse> list(ExpenseCategory category, LocalDate from, LocalDate to, Pageable pageable);
public ExpenseResponse create(CreateExpenseRequest request);
public void delete(Long id); // 404 se não existir
```

Filtro por categoria e período via `Specification` (mesmo padrão de `hasStatus`/`createdBetween` já
usado em `LandingLeadRepository`), aplicado sobre `expenseDate`.

### 3. `ManualCommissionRuleService`

```java
public List<ManualCommissionRuleResponse> listAll(); // ativas e encerradas, sem paginação (volume baixo)
public ManualCommissionRuleResponse create(CreateManualCommissionRuleRequest request);
public ManualCommissionRuleResponse close(Long id); // seta effectiveTo = LocalDate.now(); 404 se não existir; erro se já encerrada
public void delete(Long id); // 404 se não existir
```

`close()` lança `RuleException` se a regra já tiver `effectiveTo` preenchido — encerrar uma regra
já encerrada não faz sentido e provavelmente é erro de clique duplo na tela.

### 4. Controller (novo, dedicado — `AdminFinancialsController` reaproveita o que a TASK-192 também
usa, mas os métodos desta task são independentes)

```java
@RequestMapping("/easy-maintenance/api/v1/private/admin/financials")
public class AdminFinancialsController {

    @GetMapping("/expenses")
    public PageResponse<ExpenseResponse> listExpenses(...);

    @PostMapping("/expenses")
    @ResponseStatus(HttpStatus.CREATED)
    public ExpenseResponse createExpense(@Valid @RequestBody CreateExpenseRequest request);

    @DeleteMapping("/expenses/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteExpense(@PathVariable Long id);

    @GetMapping("/commission-rules")
    public List<ManualCommissionRuleResponse> listCommissionRules();

    @PostMapping("/commission-rules")
    @ResponseStatus(HttpStatus.CREATED)
    public ManualCommissionRuleResponse createCommissionRule(@Valid @RequestBody CreateManualCommissionRuleRequest request);

    @PatchMapping("/commission-rules/{id}/close")
    public ManualCommissionRuleResponse closeCommissionRule(@PathVariable Long id);

    @DeleteMapping("/commission-rules/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteCommissionRule(@PathVariable Long id);
}
```

Mesma autenticação admin já usada em `AdminLeadController`/`AdminBillingController`.

### 5. Testes

- `ExpenseServiceTest`: criar, listar filtrado por categoria/período isolado e combinado, remover
  existente, remover inexistente (404).
- `ManualCommissionRuleServiceTest`: criar, listar (ativas + encerradas juntas), encerrar (seta
  `effectiveTo`), encerrar já encerrada (erro), remover existente, remover inexistente (404).

## Critérios de Aceite

- [x] `POST/GET/DELETE /private/admin/financials/expenses` funcionam conforme o escopo
- [x] `POST/GET/PATCH .../close/DELETE /private/admin/financials/commission-rules` funcionam
      conforme o escopo
- [x] Filtro de despesas por categoria e período (isolado e combinado) funciona
- [x] Encerrar regra já encerrada retorna erro, não sobrescreve `effectiveTo`
- [x] `mvn test` sem regressão

**Nota de implementação**: `Expense`/`ManualCommissionRule` e seus repositórios foram movidos para
um subpacote `financials/` isolado (dentro de `billing.domain`/`billing.infrastructure.persistence`)
— sem isso, o `@DataJpaTest` do teste de filtro (`ExpenseFilterPersistenceTest`) tentava inicializar
`BillingAccount`/`BillingAccountRepository` e outras entidades não relacionadas que vivem no mesmo
pacote, e falhava por associação fora do escopo do scan. Mesmo problema/solução já documentado em
`LandingLeadFilterPersistenceTest` (EPIC-021 Fase 2), aqui um pouco mais severo por `billing.domain`
ter muito mais entidades do que `leads.domain`.

## Dependências
**TASK-190** — precisa de `Expense`, `ManualCommissionRule` e seus repositórios.

## Riscos
Baixo — CRUD aditivo sobre tabelas novas, sem tocar em fluxo existente.

## Esforço
Médio

## Status
✅ Implementada e commitada (23/08/2026) na branch `feature/financial-module-v2`
(`easy-maintenance-api`, commit `e735f78`) — mesma branch reúne toda a Fase 2. Suíte completa: 787
testes, 0 falhas. Ainda sem PR — mesma branch reúne toda a Fase 2.
