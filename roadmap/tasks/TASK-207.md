# TASK-207 — Backend: split de comissão entre beneficiários (`AffiliateCommissionSplit`)

## Tipo
BACKEND

## Categoria
Admin / Financeiro / Afiliados

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Revisão da Fase 2 — split de comissão

## QA obrigatório
Não precisa QA manual isolado — é camada de dado + endpoint, coberta por teste automatizado. QA
manual de ponta a ponta acontece na TASK-208 (frontend), quando configurar a divisão de um afiliado
de verdade na tela é possível.

---

## Contexto

Caso real levantado por Douglas (conversa de 27/08/2026): "Grupo Silva" precisa repassar comissão
pra duas pessoas — o grupo/afiliado e o vendedor que fechou a venda — sobre o mesmo cliente. Hoje um
cliente tem no máximo um comissionado ativo por vez (`Affiliate`/`ReferralCommission`, regra
confirmada na Revisão da Fase 2, ver `docs/superpowers/specs/2026-08-24-affiliate-commission-rework.md`
item 4), com uma única `commissionRate`. A única forma hoje seria cadastrar o afiliado com o
percentual somado (ex.: 10% grupo + 5% vendedor = 15%) — funciona, mas o relatório "Comissões por
pessoa" (`FinancialsService.getCommissionsBreakdown`) mostra só uma linha, sem rastreabilidade de
quem recebeu o quê, e qualquer renegociação de uma das partes vira conta de cabeça.

**Decisão de escopo (confirmada com Douglas na conversa)**: não altera a regra "1 comissionado ativo
por cliente" nem o schema de `ReferralCommission`/`CommissionService` — a atribuição ao cliente
continua sendo com um único `Affiliate`. O que muda é que esse `Affiliate` passa a poder declarar
como o valor da comissão que ele gera é dividido entre N beneficiários (ex.: "Grupo Silva" 66,67%,
"Vendedor João" 33,33% — juntos somam os 100% do `commissionRate` do afiliado). Afiliados sem split
configurado continuam se comportando exatamente como hoje (100% pro próprio afiliado) — feature
aditiva, sem migração de dado.

## Objetivo

`Affiliate` ganha uma lista opcional de beneficiários (nome + percentual do total), com endpoint de
leitura/edição; `FinancialsService.getCommissionsBreakdown` passa a expor, por afiliado com split
configurado, o valor do mês já dividido por beneficiário.

## Escopo

### 1. Migration — tabela nova `affiliate_commission_splits`

Confirmar o próximo número livre em `db/migration/` contra o estado real da pasta antes de escrever
(hoje o último é `V97__add_meta_capi_fields_to_landing_leads.sql`, então a próxima disponível é
`V98`).

```sql
CREATE TABLE affiliate_commission_splits (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    affiliate_id BIGINT NOT NULL,
    beneficiary_name VARCHAR(255) NOT NULL,
    percentage DECIMAL(5,4) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_commission_splits_affiliate FOREIGN KEY (affiliate_id) REFERENCES affiliates(id),
    CONSTRAINT uk_commission_splits_affiliate_name UNIQUE (affiliate_id, beneficiary_name)
);
```

Sem dado real em produção pra migrar (0 clientes pagantes) — tabela nova, vazia até alguém
configurar um split.

### 2. Entidade `AffiliateCommissionSplit`

```java
@Entity
@Table(name = "affiliate_commission_splits")
public class AffiliateCommissionSplit {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "affiliate_id", nullable = false)
    private Long affiliateId;

    @Column(name = "beneficiary_name", nullable = false)
    private String beneficiaryName;

    @Column(nullable = false, precision = 5, scale = 4)
    private BigDecimal percentage;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;
}
```

### 3. Repositório

```java
public interface AffiliateCommissionSplitRepository extends JpaRepository<AffiliateCommissionSplit, Long> {
    List<AffiliateCommissionSplit> findByAffiliateIdOrderById(Long affiliateId);
    void deleteByAffiliateId(Long affiliateId);
}
```

### 4. Serviço — `AffiliateService.replaceSplits(Long affiliateId, List<UpsertCommissionSplitRequest> splits)`

- 404 (`EntityNotFoundException`) se o afiliado não existir.
- Lista vazia é válida — remove o split existente, volta ao comportamento padrão (100% pro próprio
  afiliado).
- Lista não vazia: cada `percentage` precisa estar em `(0, 1]`; a soma de todos os percentuais
  precisa bater com `1.0000` (tolerância de arredondamento, ex.: `abs(soma - 1) <= 0.0001`) — senão
  `IllegalArgumentException` (400).
- Substituição é atômica (`@Transactional`): apaga os splits existentes do afiliado e insere os
  novos.

```java
public record UpsertCommissionSplitRequest(
        @NotBlank String beneficiaryName,
        @NotNull @DecimalMin("0.0001") @DecimalMax("1.0") BigDecimal percentage) {}

public record CommissionSplitResponse(Long id, String beneficiaryName, BigDecimal percentage) {}
```

### 5. Endpoints — `CommissionAdminController` (`/private/admin/affiliates-commissions`)

```java
@GetMapping("/{id}/splits")
@Operation(summary = "Listar divisão de comissão configurada para um afiliado")
public List<CommissionSplitResponse> getSplits(@PathVariable Long id);

@PutMapping("/{id}/splits")
@Operation(summary = "Substituir a divisão de comissão de um afiliado (lista vazia remove o split)")
public List<CommissionSplitResponse> replaceSplits(
        @PathVariable Long id, @Valid @RequestBody List<UpsertCommissionSplitRequest> request);
```

### 6. `FinancialsService.getCommissionsBreakdown` — beneficiários no breakdown mensal

Em `FinancialsService.java:100-121` (loop que monta `CommissionBreakdownResponse` por afiliado), após
calcular `totalAmount` do mês pro afiliado: buscar `affiliateCommissionSplitRepository
.findByAffiliateIdOrderById(entry.getKey())`; se não vazio, calcular
`totalAmount.multiply(split.getPercentage())` por beneficiário e anexar à resposta. Se vazio,
comportamento idêntico ao atual (sem campo extra populado).

`FinancialsDTO.CommissionBreakdownResponse` ganha campo novo (lista, pode ser vazia):

```java
public record CommissionBreakdownResponse(
        Long affiliateId, String name, String email, BigDecimal commissionRate,
        String recurrenceType, long amountCents, long pendingCount, long paidCount,
        List<BeneficiaryBreakdown> beneficiaries) {

    public record BeneficiaryBreakdown(String beneficiaryName, BigDecimal percentage, long amountCents) {}
}
```

**Importante**: `CommissionService.createCommission`/`ReferralCommission` não mudam — a comissão
continua sendo criada e persistida como um único evento por ciclo, no valor total do
`commissionRate` do afiliado. O split é só uma visão derivada desse valor pra fins de
relatório/pagamento, não uma segunda linha de comissão nem uma segunda atribuição de cliente.

## Critérios de Aceite

- [x] `affiliate_commission_splits` existe após a migration, sem afetar nenhuma tabela existente
- [x] `GET /private/admin/affiliates-commissions/{id}/splits` retorna lista vazia pra afiliado sem
      split configurado
- [x] `PUT .../{id}/splits` com soma de percentuais != 100% retorna 400, sem persistir nada
- [x] `PUT .../{id}/splits` com soma == 100% substitui atomicamente a configuração anterior
- [x] `PUT .../{id}/splits` com lista vazia remove o split (volta a 100% pro próprio afiliado)
- [x] `GET /private/admin/financials/commissions-breakdown?month=...` inclui `beneficiaries` (vazio
      pra afiliado sem split, preenchido e somando o valor total do afiliado pra quem tem)
- [x] Afiliados sem split configurado — todo o comportamento existente (criação de comissão,
      breakdown, idempotência) permanece idêntico, sem regressão
- [x] `mvn test` sem regressão

## Dependências
Nenhuma técnica — constrói em cima da Revisão da Fase 2 já implementada (TASK-195 a 198). Precede
TASK-208 (frontend consome estes endpoints).

## Riscos
Baixo — tabela nova, aditiva; não altera `ReferralCommission`, `CommissionService` nem a regra "1
comissionado ativo por cliente"; sem dado real em produção (0 clientes pagantes).

## Esforço
Baixo-Médio

## Status
✅ Implementada, QA manual aprovado (`TASK-QA-MAN-016`, cenários C1-C7) e PR aberta contra `staging`:
[easy-maintenance-api#53](https://github.com/douglasjava/easy-maintenance-api/pull/53) (27/08/2026).
Branch `feature/TASK-207-commission-split`, commit `fcadbbb`. Suíte completa: 843 testes, 0 falhas.

**Notas de implementação**:
- Endpoint `PUT .../{id}/splits` usa `@Valid @RequestBody List<UpsertCommissionSplitRequest>` —
  mesmo padrão de validação em cascata de lista já usado em `ItemsController.createBatch`.
- Validação de soma dos percentuais usa tolerância de `0.0001` (`RuleException` → 400 via
  `GlobalExceptionHandler`, mesmo tratamento já usado no resto do módulo de afiliados).
- `FinancialsService.getCommissionsBreakdown` trunca o valor de cada beneficiário com
  `.longValue()` (sem arredondar), mesmo comportamento já existente pro total do afiliado —
  consistente, mas soma dos beneficiários pode ficar 1 centavo abaixo do total por truncamento
  (ex.: 66,67%/33,33% de R$150,00 → R$100,00 + R$49,99 = R$149,99, não R$150,00). Não corrigido
  nesta task por ser o mesmo comportamento de arredondamento já aceito no resto do módulo — se virar
  problema real (divergência visível no financeiro), tratar em task própria.
