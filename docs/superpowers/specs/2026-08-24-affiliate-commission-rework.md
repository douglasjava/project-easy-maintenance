# Comissionado atribuído — estende `Affiliate`/`ReferralCommission`, remove comissão manual

**Data:** 24/08/2026
**Status:** Aprovado por Douglas (conversa conduzida nesta data, durante teste local da Fase 2 do
EPIC-020)

## Motivação

Testando a tela de financeiro nova (Fase 2, EPIC-020), Douglas observou que a estrutura antiga de
comissão de afiliado (`Affiliate`/`ReferralCommission`) já resolvia — quase por completo — o problema
que `manual_commission_rules` (criada há um dia, TASK-190/191) tentou resolver do zero: registrar
quem recebe comissão, quanto (%, individual por pessoa) e com que recorrência. Levantada a hipótese
de que as duas estruturas fariam a mesma coisa com nomes diferentes — investigação de código confirmou.

## Estado atual (confirmado por leitura de código, 24/08/2026)

- `ManualCommissionRule`/`manual_commission_rules` (TASK-190) calcula comissão como % da receita
  líquida **total** da empresa no mês (`FinancialsService`, `rule.percentage × revenueNetCents`),
  sem nenhum vínculo com cliente específico — não é o caso de negócio real (confirmado com Douglas:
  comissão é sempre por cliente atribuído a um comissionado, nunca fatia do total).
- `Affiliate.commissionRate` + `ReferralCommission` já é, estruturalmente, o mesmo conceito de
  "pessoa + percentual + vínculo com pagamento" — só falta: (a) endpoint de edição de
  `commissionRate` (hoje só existe criação), e (b) um conceito de recorrência (hoje toda comissão de
  afiliado é sempre um evento único).
- A trava de "único por cliente, pra sempre" está em 3 camadas:
  1. `PaymentReceivedHandler.java:121-124` — só dispara `triggerCommissionIfApplicable` quando
     `payment.getCycleNumber() == 1` (comentário no código: *"One-time commission trigger — only on
     first payment"*).
  2. `CommissionService.java:32-35` — `commissionRepository.existsByOrganizationId(organizationId)`,
     idempotência por organização.
  3. `V72__create_affiliates_tables.sql:27` — `UNIQUE KEY uk_referral_commissions_org
     (organization_id)`, trava física no banco.
- **Achado à parte, mesma análise**: desde a EPIC-014 (13/07/2026, commit `48cc214`), a cobrança é só
  por `USER` — `BillingSubscriptionItem` do tipo `ORGANIZATION` sempre vale `0`
  (`BillingSubscriptionService.java:378-380`, migration `V79`), vira só registro de vínculo pra
  limite de pool de organizações da conta. Isso **não afeta o valor da comissão** — `PaymentReceivedHandler`
  usa `Payment.amountCents`/`netAmountCents` (o valor real cobrado do gateway), não
  `item.getValueCents()`. Mas a **atribuição** continua 100% organizada por organização
  (`Organization.referralCode` → `Affiliate` via `item.getSourceType() == ORGANIZATION`), enquanto
  quem paga de fato é o `User`. `User.referralCode` já existe (`User.java:46-47`) mas só é copiado
  pra `Organization.referralCode` uma vez, no momento da criação da org (`OnboardingService.java:109-111`)
  — se aplicado depois (ex.: admin atribui comissionado a um cliente já existente), nunca propaga.
  Numa conta com múltiplas organizações, o `PaymentReceivedHandler` escolhe a organização
  arbitrariamente pela ordem de iteração dos itens da assinatura (linhas 150-151) — a comissão pode
  prender no lugar errado. Esse descompasso nunca foi documentado: EPIC-012 (referral, 21/06/2026)
  nunca foi revisitada quando a EPIC-014 mudou o modelo de cobrança (13/07/2026).

## Decisões de escopo (conversa, 24/08/2026)

1. **`manual_commission_rules` é removida por completo** (entidade, service, controller, migration,
   frontend) — não é mantida como caso alternativo. O único caso de negócio real é comissão por
   cliente atribuído.
2. **`Affiliate` ganha `recurrenceType`** (`ONE_TIME` | `RECURRING`), decidido por comissionado, não
   global. `ONE_TIME` mantém o comportamento atual (uma comissão, no primeiro ciclo de pagamento do
   cliente). `RECURRING` gera uma comissão a cada ciclo de pagamento do cliente atribuído, enquanto
   o afiliado estiver `ACTIVE`.
3. **`Affiliate` ganha endpoint de edição admin** (`commissionRate`, `recurrenceType`) — hoje só
   existe criação (autocadastro público ou admin), nunca update. Percentual e recorrência **nunca**
   ficam expostos/editáveis fora de `/private/admin/**` — decisão reafirmada por Douglas
   (nada muda aqui, já era assim).
4. **Um cliente tem no máximo um comissionado ativo por vez** (confirmado por Douglas) — não é
   necessário modelar N:N. Reatribuir um cliente pra outro comissionado é uma troca de
   `referralCode`/`user_id` vinculado, com histórico preservado (comissões já geradas continuam
   apontando pro comissionado que as gerou).
5. **`referral_commissions.organization_id` vira `user_id`.** A atribuição passa a ser resolvida via
   o item `USER` da assinatura (`item.getSourceId()` já é `user.getId().toString()` pra esse tipo) e
   `User.referralCode`, não mais via item `ORGANIZATION` + `Organization.referralCode`. Isso resolve
   os dois achados juntos: elimina a ambiguidade de múltiplas organizações por conta, e é pré-requisito
   pra `RECURRING` funcionar sem herdar a mesma ambiguidade a cada ciclo.
6. **`Organization.referralCode` deixa de ser lido** pelo fluxo de comissão (`PaymentReceivedHandler`
   passa a ler `User.referralCode` direto) — o campo na tabela `organizations` fica órfão após esta
   mudança; não é removido nesta rodada (fora de escopo, ver abaixo), só deixa de ser a fonte usada.
7. **Atribuir/reatribuir um afiliado a um usuário já existente precisa de rota nova** — hoje
   `User.referralCode` só é setado na criação do usuário via admin (`AdminService.createUser`), sem
   jeito de editar depois.
8. **Tela de financeiro**: o detalhamento por comissionado (nome, %, recorrência, valor do período)
   passa a ter uma fonte só — `ReferralCommission` agregada por afiliado — cobrindo afiliado público
   (indicador) e comissionado interno ao mesmo tempo, sem misturar dois modelos de dado.

## Modelo de dados

### Migration (`easy-maintenance-api`, próximo número livre em `db/migration/`, confirmar contra o
estado real da pasta antes de escrever — TASK-190 usou V93, então esta é a próxima disponível)

```sql
DROP TABLE IF EXISTS manual_commission_rules;

ALTER TABLE affiliates
    ADD COLUMN recurrence_type VARCHAR(20) NOT NULL DEFAULT 'ONE_TIME';

ALTER TABLE referral_commissions
    ADD COLUMN user_id BIGINT NULL,
    ADD COLUMN cycle_number INT NOT NULL DEFAULT 1;

-- Sem dado real em produção (0 clientes pagantes) — não há linha existente pra migrar/backfillar.
-- Se isso mudar antes do deploy, backfill de user_id a partir de organization_id/organization
-- precisa ser adicionado aqui antes do NOT NULL abaixo.
ALTER TABLE referral_commissions
    MODIFY COLUMN user_id BIGINT NOT NULL,
    DROP COLUMN organization_id;

ALTER TABLE referral_commissions
    DROP INDEX uk_referral_commissions_org,
    ADD UNIQUE KEY uk_referral_commissions_user_cycle (user_id, cycle_number);
```

- `recurrence_type`: `ONE_TIME` (default, preserva o comportamento de todo afiliado já cadastrado) ou
  `RECURRING`.
- `referral_commissions.user_id` substitui `organization_id` — vínculo com o pagador real.
- `cycle_number` (copiado de `Payment.cycleNumber`) — pra `ONE_TIME` é sempre `1` (mesma semântica de
  hoje); pra `RECURRING` varia a cada comissão gerada. A unique key `(user_id, cycle_number)`
  substitui `uk_referral_commissions_org`, preservando idempotência (não gera duas comissões pro
  mesmo ciclo do mesmo usuário) mas permitindo múltiplas linhas por usuário ao longo do tempo.

### `Affiliate` — campo novo

```java
@Enumerated(EnumType.STRING)
@Column(name = "recurrence_type", nullable = false, length = 20)
@Builder.Default
private AffiliateRecurrenceType recurrenceType = AffiliateRecurrenceType.ONE_TIME;
```

```java
public enum AffiliateRecurrenceType { ONE_TIME, RECURRING }
```

### `ReferralCommission` — campo trocado

```java
@Column(name = "user_id", nullable = false)
private Long userId; // era organizationId

@Column(name = "cycle_number", nullable = false)
@Builder.Default
private Integer cycleNumber = 1;
```

## Backend

### `CommissionService.createCommission()` — assinatura e lógica

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

`existsByUserId` (sem filtro de ciclo) é o que impede um afiliado `ONE_TIME` de gerar uma segunda
comissão se o ciclo 1 falhar e for reprocessado como ciclo 2 por qualquer motivo — mantém a garantia
que a constraint única sozinha (`user_id, cycle_number`) não cobre.

### `PaymentReceivedHandler.triggerCommissionIfApplicable()` — resolve via item `USER`

```java
// Antes: só disparava no cycleNumber == 1. Agora dispara sempre — a decisão ONE_TIME/RECURRING
// fica inteira dentro de CommissionService, por afiliado.
triggerCommissionIfApplicable(payment, subscription);

// dentro do método:
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

// planPrice/netAmount calculados como hoje, a partir de Payment
commissionService.createCommission(affiliate, userId, payment.getCycleNumber(), planName, planPrice, netAmount);
```

Remove a dependência do item `ORGANIZATION` e de `Organization.referralCode` neste fluxo por
completo.

### Endpoint novo — atribuir/reatribuir comissionado a um usuário existente

`PATCH /private/admin/users/{userId}/referral-code` (ou dentro de `AdminUserController` já
existente, se fizer mais sentido arquiteturalmente na revisão de código) — seta/troca
`User.referralCode`. Não propaga retroativamente pras comissões já geradas (regra já estabelecida:
sem recálculo retroativo).

### Endpoint novo — editar afiliado

```
PATCH /private/admin/affiliates/{id}
{ "commissionRate": 0.15, "recurrenceType": "RECURRING" }
```

### `FinancialsService` — remove comissão manual, comissão de afiliado cobre os dois casos

- Remove `manualCommissionRuleRepository`, `manualCommissionCents`, o cálculo `isActiveInMonth`.
- `affiliateCommissionCents` continua vindo de `referralCommissionRepository.sumCommissionAmountByCreatedAtBetween`
  — sem mudança de lógica agregada, só o que alimenta a tabela por baixo muda.
- `monthlyBalanceCents = revenueNetCents - affiliateCommissionCents - expenseCents` (sem o termo de
  comissão manual).
- `MonthlyFinancialsResponse` perde o campo `manualCommissionCents`.

### Endpoint novo — breakdown por comissionado

```
GET /private/admin/financials/commissions-breakdown?month=2026-08
```
Retorna, por afiliado com pelo menos uma `ReferralCommission` no mês: nome, e-mail, `commissionRate`,
`recurrenceType`, soma de `commissionAmount` no mês, status agregado (quantas pagas/pendentes).

## Frontend

- `easy-maintenance-web/src/app/private/admin/affiliates/page.tsx`: ganha ação "Editar" por linha
  (modal com `commissionRate` e `recurrenceType`) e ação "Atribuir cliente" (busca usuário por
  e-mail/nome, chama o endpoint de atribuição).
- `easy-maintenance-web/src/app/private/admin/financials/page.tsx`: remove `<ManualCommissionRulesSection />`
  e `CommissionRuleFormModal.tsx` por completo; adiciona seção "Comissões por pessoa" — tabela nome,
  %, recorrência (badge "Único"/"Recorrente"), valor do mês — consumindo o endpoint de breakdown.
  Card "Comissões" no resumo perde o termo `manualCommissionCents` da soma (só `affiliateCommissionCents`
  agora, que já cobre tudo).
- `labels.ts`: remove qualquer label residual de `manual_commission_rules` se existir.

## Fora de Escopo

- Recálculo retroativo de comissões `referral_commissions` já geradas — só as novas (pós-deploy)
  usam `user_id`/`cycle_number`/recorrência.
- Suporte a mais de um comissionado ativo por cliente ao mesmo tempo.
- Corrigir a propagação automática de `referralCode` no fluxo de autocadastro público (cookie
  `em_ref` → onboarding) — bug pré-existente e independente, achado na mesma análise; comissionado
  interno é sempre atribuído manualmente por Douglas, então não bloqueia esta rodada.
- Remover a coluna `Organization.referralCode` do schema — fica órfã, mas removê-la é limpeza
  separada, sem urgência.

## Testes

- Backend: `CommissionServiceTest` cobrindo `ONE_TIME` (comportamento idêntico ao atual, comissão
  única mesmo se reprocessado), `RECURRING` (gera uma comissão por ciclo, idempotente por
  `(user_id, cycle_number)`). `PaymentReceivedHandlerTest` cobrindo resolução via item `USER` +
  `User.referralCode` (não mais via `ORGANIZATION`). `FinancialsServiceTest` sem o termo de comissão
  manual, breakdown por comissionado agregando corretamente por afiliado/mês.
- Frontend: `npm run build` limpo + QA manual (editar afiliado, trocar recorrência, atribuir cliente
  a um comissionado, conferir breakdown na tela de financeiro).

## Riscos

- **Médio** — rekey de `organization_id` para `user_id` em tabela já usada por `AdminFinancialsController`/
  `CommissionAdminController`; sem dado real em produção hoje (0 clientes pagantes), risco de
  migração de dados é baixo, mas a mudança de contrato da API (`CommissionAdminResponse` perde
  `organizationId`, ganha `userId`) precisa de atenção se algum consumidor externo existir (nenhum
  conhecido além do próprio frontend admin).
- **Baixo** — resto é extensão aditiva de `Affiliate`/tela administrativa já existente, sem tocar em
  fluxo de cliente final.
