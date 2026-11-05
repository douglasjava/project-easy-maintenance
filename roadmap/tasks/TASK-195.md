# TASK-195 — Backend: `Affiliate` ganha `recurrenceType`; CRUD admin de edição; remove `ManualCommissionRule`

## Tipo
BACKEND

## Categoria
Admin / Financeiro / Afiliados

## Prioridade
🔴 Crítico

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Revisão da Fase 2

## QA obrigatório
Não precisa QA manual isolado — é camada de dado + endpoint de edição, coberta por teste
automatizado. QA manual de ponta a ponta acontece na TASK-198 (frontend), quando editar um afiliado
de verdade na tela é possível.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-24-affiliate-commission-rework.md`.

Substitui o que TASK-190/191 construíram (`manual_commission_rules`) — identificado como modelagem
errada: calculava % da receita **total** da empresa, sem vínculo com cliente, quando o caso de
negócio real é comissão por cliente atribuído a um comissionado específico. `Affiliate`/
`ReferralCommission` já resolve o vínculo com cliente e pagamento; faltava só percentual editável
(endpoint não existe) e recorrência (`ONE_TIME`/`RECURRING`, conceito novo).

## Objetivo

`Affiliate` ganha `recurrenceType`; endpoint admin de edição (`commissionRate`, `recurrenceType`);
`ManualCommissionRule` e tudo relacionado é removido.

## Escopo

### 1. Migration — adiciona `recurrence_type`, remove `manual_commission_rules`

```sql
DROP TABLE IF EXISTS manual_commission_rules;

ALTER TABLE affiliates
    ADD COLUMN recurrence_type VARCHAR(20) NOT NULL DEFAULT 'ONE_TIME';
```

Confirmar o próximo número livre em `db/migration/` contra o estado real da pasta antes de escrever
(TASK-190 usou V93).

### 2. Enum novo

```java
package com.brainbyte.easy_maintenance.affiliates.domain;

public enum AffiliateRecurrenceType { ONE_TIME, RECURRING }
```

### 3. `Affiliate` — campo novo

```java
@Enumerated(EnumType.STRING)
@Column(name = "recurrence_type", nullable = false, length = 20)
@Builder.Default
private AffiliateRecurrenceType recurrenceType = AffiliateRecurrenceType.ONE_TIME;
```

Default `ONE_TIME` preserva o comportamento de todo afiliado já cadastrado sem exigir migração de
dado.

### 4. Endpoint de edição — `AffiliateAdminController` (ou controller admin de afiliados já
existente, confirmar nome exato no código antes de criar um novo)

```java
public record UpdateAffiliateRequest(
        @NotNull @DecimalMin("0.0001") @DecimalMax("1.0") BigDecimal commissionRate,
        @NotNull AffiliateRecurrenceType recurrenceType
) {}

@PatchMapping("/private/admin/affiliates/{id}")
public AffiliateAdminResponse update(@PathVariable Long id, @Valid @RequestBody UpdateAffiliateRequest request);
```

`AffiliateService.update(Long id, BigDecimal commissionRate, AffiliateRecurrenceType recurrenceType)`
— 404 se não existir. Sem restrição adicional de quem pode editar além da autenticação admin já
existente (mesmo padrão do resto de `/private/admin/**`).

### 5. Remover código morto

Deletar `ManualCommissionRule.java`, `ManualCommissionRuleRepository.java`,
`ManualCommissionRuleDTO.java`, `ManualCommissionRuleService.java`, e os endpoints
`/private/admin/financials/commission-rules` (`GET`/`POST`/`PATCH .../close`/`DELETE`) do
`AdminFinancialsController` — nenhum resíduo órfão.

## Critérios de Aceite

- [x] `manual_commission_rules` não existe mais no banco após a migration (`V94`)
- [x] `affiliates.recurrence_type` existe, default `ONE_TIME`, todo afiliado pré-existente preserva
      comportamento atual
- [x] `PATCH /private/admin/affiliates-commissions/{id}` edita `commissionRate` e `recurrenceType`,
      404 se não existir (rota real: o endpoint de admin de afiliados já existente é
      `CommissionAdminController` em `/private/admin/affiliates-commissions`, não
      `/private/admin/affiliates` como o rascunho original da task citava)
- [x] `ManualCommissionRule` e todo código relacionado (entidade, repositório, DTO, serviço,
      endpoints) removidos do projeto
- [x] `mvn test` sem regressão

## Dependências
Nenhuma técnica. Precede TASK-196 (usa `recurrenceType` pra decidir geração de comissão) e TASK-198
(frontend consome o endpoint de edição).

## Riscos
Baixo — `DROP TABLE` de uma tabela criada há 1 dia, sem dado real usado em produção (0 clientes
pagantes); extensão aditiva de `Affiliate`, sem alterar campos existentes.

## Esforço
Baixo-Médio

## Status
✅ Implementada e commitada (24/08/2026) na branch `feature/financial-module-v2`
(`easy-maintenance-api`, commit `02417bf`) — mesma branch das TASK-190 a 194 (revisão em cima da
mesma leva, sem PR ainda). Suíte completa: 786 testes, 0 falhas.

**Notas de implementação**:
- `GET /private/admin/affiliates-commissions` (listagem de afiliados, `CommissionAdminController`)
  passou a retornar `AffiliateAdminResponse` (inclui `whatsapp`, `recurrenceType`, `status`,
  `createdAt`) em vez de `AffiliateResponse` (usado nos endpoints públicos, que não muda) — decisão
  tomada durante a implementação porque o endpoint de edição não teria utilidade em admin sem a
  listagem já expor `recurrenceType`. A TASK-198 (frontend) precisa consumir o novo formato.
- `FinancialsService` manteve `manualCommissionCents` no contrato do DTO, sempre zerado, e removeu
  a dependência de `ManualCommissionRuleRepository` — mesmo padrão de ajuste mínimo já usado na
  TASK-190 pra não quebrar `mvn test` fora do escopo desta task. Remoção definitiva do campo é
  escopo da TASK-197.
- `AffiliateServiceTest` ganhou cobertura para `update` (sucesso + 404) e `listAllActiveAdmin`.
  `FinancialsServiceTest` perdeu os 2 testes específicos de `manual_commission_rules` (removidos
  junto com o conceito), mantendo os demais sem alteração de comportamento esperado.
