# TASK-196 — Backend: rekey `referral_commissions.organization_id` → `user_id`; corrige atribuição; suporta comissão recorrente

## Tipo
BUGFIX / BACKEND

## Categoria
Admin / Financeiro / Afiliados

## Prioridade
🔴 Crítico

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Revisão da Fase 2

## QA obrigatório
Sim — QA manual: simular pagamento de ciclo 1 pra um usuário com `referralCode` de afiliado
`ONE_TIME`, confirmar comissão única gerada; simular ciclos 1, 2, 3 pra afiliado `RECURRING`,
confirmar uma comissão por ciclo; confirmar que reprocessar o mesmo webhook não duplica comissão.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-24-affiliate-commission-rework.md`.

**Achado de código, confirmado**: desde a EPIC-014 (13/07/2026, commit `48cc214`), a cobrança é só
por `USER` — itens `BillingSubscriptionItem` do tipo `ORGANIZATION` valem sempre `0`
(`BillingSubscriptionService.java:378-380`, migration `V79`). O valor da comissão não é afetado
(`PaymentReceivedHandler` já usa `Payment.amountCents`/`netAmountCents`, não `item.getValueCents()`),
mas a atribuição continua 100% organizada por organização (`Organization.referralCode` → `Affiliate`,
`ReferralCommission.organizationId` com `UNIQUE`), enquanto quem paga de fato é o `User`.
`User.referralCode` já existe (`User.java:46-47`) mas só é copiado pra `Organization.referralCode`
uma vez, na criação da org (`OnboardingService.java:109-111`) — se aplicado depois, nunca propaga.
Numa conta com múltiplas organizações, a comissão hoje prende na organização escolhida
arbitrariamente pela ordem de iteração dos itens da assinatura. Esse descompasso entre EPIC-012
(referral, 21/06/2026) e EPIC-014 (billing por usuário, 13/07/2026) nunca foi documentado antes desta
análise (24/08/2026).

Depende da TASK-195 (`Affiliate.recurrenceType`) — esta task usa o campo pra decidir se gera uma
comissão (`ONE_TIME`) ou uma por ciclo (`RECURRING`).

## Objetivo

`referral_commissions` passa a vincular por `user_id`; `PaymentReceivedHandler` resolve o afiliado
via item `USER` da assinatura + `User.referralCode`; comissão `RECURRING` gera uma linha por ciclo de
pagamento.

## Escopo

### 1. Migration

```sql
ALTER TABLE referral_commissions
    ADD COLUMN user_id BIGINT NULL,
    ADD COLUMN cycle_number INT NOT NULL DEFAULT 1;

-- Sem dado real em produção (0 clientes pagantes) — sem linha existente pra backfillar. Se isso
-- mudar antes do deploy, adicionar backfill de user_id aqui antes do NOT NULL abaixo.
ALTER TABLE referral_commissions
    MODIFY COLUMN user_id BIGINT NOT NULL,
    DROP COLUMN organization_id;

ALTER TABLE referral_commissions
    DROP INDEX uk_referral_commissions_org,
    ADD UNIQUE KEY uk_referral_commissions_user_cycle (user_id, cycle_number);
```

### 2. `ReferralCommission` — campo trocado

```java
@Column(name = "user_id", nullable = false)
private Long userId; // era organizationId

@Column(name = "cycle_number", nullable = false)
@Builder.Default
private Integer cycleNumber = 1;
```

### 3. `ReferralCommissionRepository` — métodos novos/trocados

```java
boolean existsByUserId(Long userId);
boolean existsByUserIdAndCycleNumber(Long userId, Integer cycleNumber);
```
Remove `existsByOrganizationId`.

### 4. `CommissionService.createCommission()` — assinatura e lógica

```java
@Transactional
public ReferralCommission createCommission(Affiliate affiliate, Long userId, Integer cycleNumber,
                                           String planName, BigDecimal planPrice, BigDecimal netAmount) {
    if (commissionRepository.existsByUserIdAndCycleNumber(userId, cycleNumber)) {
        log.info("[Commission] Already exists for userId={}, cycle={}, skipping (idempotent).", userId, cycleNumber);
        return null;
    }
    if (affiliate.getRecurrenceType() == AffiliateRecurrenceType.ONE_TIME
            && commissionRepository.existsByUserId(userId)) {
        log.info("[Commission] ONE_TIME affiliate already paid for userId={}, skipping.", userId);
        return null;
    }
    BigDecimal amount = netAmount.multiply(affiliate.getCommissionRate())
            .setScale(2, RoundingMode.HALF_UP);
    ReferralCommission commission = ReferralCommission.builder()
            .affiliateId(affiliate.getId())
            .userId(userId)
            .cycleNumber(cycleNumber)
            .planName(planName)
            .planPrice(planPrice)
            .commissionRate(affiliate.getCommissionRate())
            .commissionAmount(amount)
            .build();
    return commissionRepository.save(commission);
}
```

O segundo `if` (checagem por `existsByUserId` sem filtro de ciclo, só pra `ONE_TIME`) é o que impede
um afiliado `ONE_TIME` de gerar uma segunda comissão caso o ciclo 1 seja reprocessado como um número
de ciclo diferente por qualquer motivo — a constraint única `(user_id, cycle_number)` sozinha não
cobre esse caso.

### 5. `PaymentReceivedHandler` — resolve via item `USER`

```java
// Remove o gate "if (cycleNumber == 1)" — dispara sempre; ONE_TIME/RECURRING é decidido dentro de
// CommissionService, por afiliado.
triggerCommissionIfApplicable(payment, subscription);
```

```java
private void triggerCommissionIfApplicable(Payment payment, BillingSubscription subscription) {
    BillingSubscriptionItem userItem = subscription.getItems().stream()
            .filter(item -> item.getSourceType() == BillingSubscriptionItemSourceType.USER)
            .findFirst()
            .orElse(null);
    if (userItem == null) return;

    Long userId = Long.valueOf(userItem.getSourceId());
    User user = userRepository.findById(userId).orElse(null);
    if (user == null || user.getReferralCode() == null) return;

    Affiliate affiliate = affiliateRepository.findByCode(user.getReferralCode()).orElse(null);
    if (affiliate == null || affiliate.getStatus() != AffiliateStatus.ACTIVE) return;

    // planName/planPrice/netAmount calculados como hoje, a partir de Payment
    commissionService.createCommission(affiliate, userId, payment.getCycleNumber(), planName, planPrice, netAmount);
}
```

Remove por completo a dependência do item `ORGANIZATION`/`Organization.referralCode` neste fluxo.
`Organization.referralCode` fica órfão (fora de escopo remover a coluna nesta rodada).

### 6. Endpoint novo — atribuir/reatribuir comissionado a um usuário existente

```java
@PatchMapping("/private/admin/users/{userId}/referral-code")
public UserAdminResponse updateReferralCode(@PathVariable Long userId, @Valid @RequestBody UpdateReferralCodeRequest request);
```
`UsersService.applyReferralCode` já existe e faz o `set`/`save` — só falta a rota admin pra chamá-lo
fora do fluxo de criação de usuário. Sem recálculo retroativo de comissões já geradas.

### 7. `CommissionAdminResponse`/`CommissionAdminController` — troca `organizationId` por `userId`

Ajustar o DTO e o `listAll()` de `CommissionService` pra expor `userId` (e nome/e-mail do usuário via
`userRepository`, no lugar do que hoje vem de `Organization`).

### 8. Testes

- `CommissionServiceTest`: `ONE_TIME` gera uma vez só mesmo com múltiplos ciclos processados;
  `RECURRING` gera uma comissão por ciclo; reprocessar o mesmo `(userId, cycleNumber)` não duplica.
- `PaymentReceivedHandlerTest`: resolve afiliado via item `USER` + `User.referralCode`; ignora
  quando não há item `USER` ou `referralCode` nulo; não usa mais `Organization.referralCode`.

## Critérios de Aceite

- [x] `referral_commissions.user_id` substitui `organization_id`; `cycle_number` existe (`V95`)
- [x] Afiliado `ONE_TIME` gera comissão só no primeiro pagamento do usuário atribuído, igual ao
      comportamento atual
- [x] Afiliado `RECURRING` gera uma comissão a cada ciclo de pagamento do usuário atribuído
- [x] Reprocessar o mesmo webhook não duplica comissão (idempotência por `user_id` + `cycle_number`,
      e por `user_id` sozinho pra `ONE_TIME`)
- [x] `PATCH /private/admin/users/{userId}/referral-code` atribui/reatribui comissionado
- [x] `mvn test` sem regressão

## Dependências
**TASK-195** — precisa de `Affiliate.recurrenceType`.

## Riscos
Médio — rekey de coluna com `UNIQUE` em tabela já consumida por `CommissionAdminController`; sem
dado real em produção hoje (0 clientes pagantes), risco de migração é baixo, mas o contrato da API
muda (`organizationId` → `userId` em `CommissionAdminResponse`) — nenhum consumidor externo
conhecido além do próprio frontend admin (TASK-198 atualiza).

## Esforço
Alto

## Status
✅ Implementada e commitada (24/08/2026) na branch `feature/financial-module-v2`
(`easy-maintenance-api`, commits `506e529` + `175906f` + `28416b1`) — mesma branch das TASK-190 a
195, sem PR ainda. Suíte completa: 796 testes, 0 falhas.

**Bug na migration, achado e corrigido durante o teste local de Douglas**: `V95` derruba
`organization_id` num `ALTER TABLE` e, no `ALTER` seguinte, tentava um `DROP INDEX
uk_referral_commissions_org` explícito — mas essa unique key era só sobre `organization_id`, e o
MySQL já a remove sozinho ao dropar a coluna. O `DROP INDEX` explícito falhava sempre (`ER_CANT_
DROP_FIELD_OR_KEY`), em qualquer ambiente, não só no do Douglas — não era drift de schema.
Corrigido removendo esse `DROP INDEX` (commit `175906f`); verificado rodando a migration de ponta a
ponta contra o MySQL local dele (via Docker) após reverter o estado parcial deixado pela tentativa
que falhou (0 linhas na tabela, reversão sem risco).

**Achado de QA (mock, não bug de produção)**: testando o Fluxo 4 do roteiro de QA, Douglas notou
que a comissão simulada via `POST /dev/simulate/affiliate-flow` era calculada sobre o valor bruto,
não o líquido, e que a tela de financeiro mostrava taxa Asaas zerada. Causa: quem grava
`Payment.netAmountCents`/`gatewayFeeCents` é o webhook `PAYMENT_CREATED`
(`PaymentCreatedHandler.java:95-100`), não o `PAYMENT_RECEIVED` que a simulação disparava sozinho —
o `PaymentReceivedHandler` cai no fallback documentado desde a TASK-192 (usa o bruto quando o
líquido está ausente), então a comissão calculada estava consistente com o dado disponível, só que
o dado em si faltava por causa da simulação incompleta, não da lógica de comissão. Corrigido no
`SimulationController` (commit `28416b1`): passa a disparar `PAYMENT_CREATED` (status `PENDING`,
netValue simulado com uma taxa PIX de R$1,99) antes do `PAYMENT_RECEIVED`, igual à ordem real do
Asaas — reaproveita `PaymentCreatedHandler` de verdade, não duplica a lógica.

**Extensão de QA, a pedido de Douglas** (commit `582eb1f`): `SimulationRequest` ganhou
`existingUserId` opcional — a simulação sempre criava um usuário sintético novo a cada chamada, sem
jeito de gerar uma comissão de teste pra um usuário real já criado/atribuído via fluxo normal da
aplicação. Quando informado, pula a captura de lead (step 2) e reaproveita o usuário/`BillingAccount`
existentes em vez de criar novos, sem sobrescrever o `referralCode` já salvo.

**Notas de implementação**:
- O gate "só dispara no primeiro pagamento" foi removido de `PaymentReceivedHandler` por completo —
  `triggerCommissionIfApplicable` agora roda em todo `PAYMENT_RECEIVED`; toda a decisão
  `ONE_TIME`/`RECURRING` fica dentro de `CommissionService.createCommission`, com duas checagens de
  idempotência: por `(userId, cycleNumber)` (evita duplicar o mesmo ciclo reprocessado) e, só pra
  `ONE_TIME`, por `userId` sozinho (evita uma segunda comissão se o número de ciclo mudar entre
  tentativas).
- `SimulationController` (ferramenta dev/staging de QA do fluxo de indicação) precisou de ajuste:
  criava só um item `BillingSubscriptionItem` do tipo `ORGANIZATION`, que a nova lógica ignora por
  completo. Passou a criar também o item `USER` (com o valor real, espelhando o modelo de produção
  da EPIC-014) e o item `ORGANIZATION` passou a ir com `valueCents=0`. Sem esse ajuste a ferramenta
  de simulação pararia de gerar comissão silenciosamente.
- Achado durante a implementação, fora do escopo desta task: o fluxo de autocadastro público (cookie
  `em_ref` → onboarding) não estava sendo testado aqui porque a atribuição de comissionado sempre é
  manual via admin — confirma o que já estava registrado na spec como "fora de escopo".
- `CommissionAdminResponse.organizationId` virou `userId` — TASK-198 (frontend) precisa atualizar o
  consumo desse campo na tela de afiliados/comissões.
