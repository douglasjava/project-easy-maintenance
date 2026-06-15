# TASK-087 — Trial de 14 dias + Planos Anuais com desconto de 17%

## Tipo
FULL_STACK

## Categoria
Billing / Monetização / Growth

## Prioridade
🟠 Alto

## Fase
2 — Pós-lançamento / Go-to-market

## Épico
EPIC-010 — Billing Flow

---

## Contexto

Análise de pricing (2026-06-15) identificou dois gaps de monetização:

**Trial curto demais para B2B:**
O trial atual dura 7 dias. O ciclo de decisão de uma administradora de condomínio ou síndico
é de 10–21 dias (precisa consultar conselho, comparar, testar com o responsável técnico).
Com 7 dias, o usuário é forçado a escolher antes de estar convencido.

O trial já usa o nível BUSINESS (`OnboardingService.java:76`, `Duration.ofDays(7)`) — a decisão
de usar BUSINESS como trial é correta e foi mantida. Só aumentar o prazo.

**Ausência de plano anual:**
Todo cliente é potencial churn mensal. O plano anual (17% de desconto = 2 meses grátis)
é padrão SaaS: o cliente compromete 12 meses, você ganha previsibilidade de caixa e reduz churn.

---

## Solução

### Parte 1 — Trial 7 → 14 dias

**Backend:**
- `OnboardingService.java` linha 76: `Duration.ofDays(7)` → `Duration.ofDays(14)`
- `EmailTemplateHelper.java`: atualizar texto "7 dias" → "14 dias" no e-mail de boas-vindas do trial
- Atualizar constante/comentário no log da linha 74 se existir

**Sem mudança de banco:** trial não tem registro de duração no schema, é calculado em runtime.

### Parte 2 — Planos anuais

**Backend — migration SQL (V70):**
Criar 3 novos planos com `billing_cycle = 'YEARLY'` e preço = mensal × 10 (equivale a 17% off / 2 meses grátis):

| Código | Nome | Preço anual | Equivalente mensal |
|--------|------|-------------|-------------------|
| `STARTER_ANNUAL` | Starter Anual | R$1.490/ano (149.000 cents) | R$124/mês |
| `BUSINESS_ANNUAL` | Business Anual | R$2.990/ano (299.000 cents) | R$249/mês |
| `ENTERPRISE_ANNUAL` | Enterprise Anual | R$8.990/ano (899.000 cents) | R$749/mês |

Features idênticas ao plano mensal equivalente (mesmo `features_json`).

**Backend — `BillingCycle.java`:**
Verificar se `YEARLY` já existe no enum. Se não, adicionar.

**Backend — Asaas (confirmado: suporte nativo a `YEARLY`):**
A API de checkout com assinatura recorrente do Asaas aceita `cycle = YEARLY` nativamente.
Campo `cycle` (enum) suporta: `WEEKLY`, `BIWEEKLY`, `MONTHLY`, `BIMONTHLY`, `QUARTERLY`,
`SEMIANNUALLY`, `YEARLY` — ref: https://docs.asaas.com/docs/checkout-com-assinatura-recorrente.md

Portanto o fluxo de cobrança anual segue o **mesmo path do mensal** (checkout recorrente),
apenas passando `cycle: "YEARLY"` ao criar a assinatura no Asaas. Não é necessário tratar
como cobrança avulsa DETACHED. Verificar se o provider local (`AsaasSubscriptionProvider` ou
equivalente) já aceita o campo `billingCycle` e mapeia para o `cycle` da API, ou se precisa
de ajuste no DTO de criação.

**Frontend — `PlanChangeDialog.tsx`:**
Adicionar toggle Mensal / Anual acima da lista de planos:
- Quando "Anual" selecionado, exibir planos `*_ANNUAL` com badge "Economize 2 meses"
- Quando "Mensal" selecionado, exibir planos `STARTER`, `BUSINESS`, `ENTERPRISE`
- Mostrar preço por mês equivalente no plano anual (ex: "R$124/mês • cobrado R$1.490/ano")

**Frontend — `PlanComparisonSection.tsx`:**
Adicionar toggle Mensal/Anual na tabela de comparação da tela `/billing`.

---

## Critérios de Aceite

### Trial
- [ ] Novo usuário que finaliza onboarding tem trial de 14 dias (verificar `currentPeriodEnd` no banco)
- [ ] E-mail de boas-vindas exibe "14 dias" (não "7 dias")
- [ ] Jobs de expiração e notificação de trial funcionam corretamente com 14 dias
- [ ] Log do `OnboardingService` reflete o novo prazo

### Planos anuais
- [ ] Migration V70 cria 3 planos anuais com preços corretos e features iguais aos mensais
- [ ] `PlanChangeDialog` exibe toggle Mensal / Anual funcional
- [ ] Seleção de plano anual inicia fluxo de pagamento com billing correto
- [ ] Tela `/billing` exibe plano anual do cliente com ciclo "anual" identificado
- [ ] `PlanComparisonSection` mostra opções anuais ao alternar toggle
- [ ] Preço por mês equivalente visível no card do plano anual

---

## Dependências

- TASK-061 (seleção de método de pagamento) — deve funcionar com plano anual
- TASK-058/059/060 (ciclo PIX) — verificar compatibilidade com billing anual

---

## Arquivos a modificar

### Backend
- `billing/domain/enums/BillingCycle.java` — verificar/adicionar `YEARLY`
- `onboarding/application/service/OnboardingService.java` — `Duration.ofDays(7)` → `Duration.ofDays(14)`
- `infrastructure/mail/utils/EmailTemplateHelper.java` — "7 dias" → "14 dias"
- `V70__seed_annual_plans.sql` — criar planos anuais

### Frontend
- `components/billing/PlanChangeDialog.tsx` — toggle mensal/anual
- `components/billing/PlanComparisonSection.tsx` — toggle na tabela de comparação

---

## Esforço
Médio (2–3 dias)

## Risco
- **Trial:** baixíssimo — 1 linha de código + 1 string no template
- **Planos anuais:** baixo — Asaas suporta `cycle: YEARLY` nativamente no checkout recorrente (confirmado na doc)
  - Risco residual: verificar se o DTO de criação de assinatura no provider local já expõe o campo `cycle`/`billingCycle`; se não, adicionar antes de qualquer outra coisa

## Testes a criar/ajustar
- Ajustar testes que assumem `Duration.ofDays(7)` no `OnboardingService` ou jobs de expiração
- Teste unitário: `BillingPlanService` lista planos anuais corretamente por ciclo

## Status
Backlog
