# TASK-321 — BUGFIX: assinatura CARD nasce com `endDate` = primeiro vencimento (Asaas encerra sozinha)

## Tipo
BUGFIX / FULL_STACK (Backend crítico + Frontend de autoatendimento)

## Prioridade
🔴 Crítico — corta recorrência de cobrança sem aviso pro cliente nem pro time.

## QA obrigatório
Sim — mexe no fluxo de criação/transição de assinatura de pagamento.

## Contexto
Investigado em 02/10/2026 a partir de um caso real em PRD: usuário douglasmarquesdias@gmail.com (`billing_subscription.id=2`,
`external_subscription_id=sub_691xr4oh1yugsv5u`) tinha "Próxima cobrança: 30/09/2026" no nosso painel, mas no portal da
Asaas a assinatura aparecia com **"Data de fim da assinatura: 31/08/2026"** e status encerrado — nenhuma cobrança foi
gerada em 30/09, sem nenhum webhook, sem nenhum alerta.

Causa raiz confirmada no código: `PaymentMethodTransitionService.buildCheckoutRequest` monta o
`AsaasDTO.CheckoutSubscription`, cujos campos são `(cycle, endDate, nextDueDate)` — mas o método passa o mesmo valor
(`nextDueDate.toString()`) **duas vezes**, preenchendo `endDate` com a data do primeiro vencimento em vez de deixá-lo
em branco:

```java
var subscriptionPlan = new AsaasDTO.CheckoutSubscription(
        cycle,
        nextDueDate.toString(),   // vai pro campo endDate (!)
        nextDueDate.toString()    // nextDueDate correto
);
```

Resultado: toda assinatura CARD criada por esse checkout (usado tanto no onboarding quanto na transição PIX→CARD via
`CardTransitionService`) nasce programada pra se encerrar sozinha logo após cobrar o primeiro ciclo. A Asaas ainda
calcula e devolve um `nextDueDate` futuro (por isso nosso painel mostra uma data "válida"), mas nunca chega a cobrar
porque o `endDate` já passou.

Agravante: `AsaasDTO.SubscriptionResponse` nem deserializa o campo `endDate` hoje
(`@JsonIgnoreProperties(ignoreUnknown = true)` descarta), então `BillingReconciliationService.checkAndFixCanceledSubscription`
não tem como enxergar esse estado — ele só reage quando a Asaas devolve `status == "INACTIVE"`, e uma assinatura
"encerrada por endDate" pode ficar em outro status (ex.: `EXPIRED`) sem ser pega.

## Escopo (aprovado por Douglas em 02/10/2026)

1. **Fix do bug** — `PaymentMethodTransitionService.buildCheckoutRequest`: `endDate` deve ser `null` (recorrência sem
   data de encerramento).
2. **Rede de segurança** — adicionar `endDate` em `AsaasDTO.SubscriptionResponse` e fazer
   `BillingReconciliationService.checkAndFixCanceledSubscription` tratar como divergência qualquer assinatura local
   `ACTIVE`/`PAST_DUE` cujo `endDate` remoto esteja preenchido e no passado (não só `status == "INACTIVE"`).
3. **Botão de autoatendimento** no painel de billing ("Atualizar forma de pagamento" / "Reativar assinatura"): novo
   endpoint que permite ao usuário disparar manualmente um novo checkout CARD quando a assinatura atual está
   encerrada/expirada, reaproveitando a lógica já existente em `CardTransitionService.processTransition`.

## Fora de escopo (nesta task)
- Remediar a assinatura já afetada (`subscription_id=2`) — será feita manualmente, depois do deploy, usando o próprio
  botão/endpoint novo da task.
- Qualquer mudança no fluxo PIX (DETACHED/`PixRenewalService`) — não é afetado por esse bug.

## Critérios de aceite
- [ ] `CheckoutSubscription` montado por `buildCheckoutRequest` tem `endDate() == null`, com teste de regressão cobrindo isso.
- [ ] `SubscriptionResponse` deserializa `endDate` e `BillingReconciliationService` sinaliza/corrige divergência de
      `endDate` no passado, com teste cobrindo o cenário.
- [ ] Endpoint novo de autoatendimento (reabrir checkout) funciona para uma assinatura em estado "quebrado" (CARD sem
      cobrança futura válida), reaproveitando validações existentes (dono da conta, status da assinatura).
- [ ] Botão no painel de billing (frontend) chama esse endpoint, com estados de loading/erro/sucesso e mensagem clara
      pro usuário.
- [ ] Regressivo E2E de billing sem regressão.

## Execução (02/10/2026)

**Branches:** `bugfix/TASK-321-asaas-subscription-enddate` (api e web, a partir de `staging`).

**Backend:**
- `endDate` corrigido (removido, antes duplicava `nextDueDate`) em `PaymentMethodTransitionService.buildCheckoutRequest`
  (usado por `update-card`/CC→CC), `BillingRecoveryService` (recuperação PAST_DUE) e `TrialExpirationService`
  (conversão trial→pago) — os três lugares que montavam `AsaasDTO.CheckoutSubscription` tinham o mesmo bug.
- `AsaasDTO.SubscriptionResponse` passou a deserializar `endDate`.
- `BillingReconciliationService.checkAndFixCanceledSubscription` agora também cancela localmente quando a Asaas
  devolve `endDate` preenchido no passado, não só quando `status == "INACTIVE"` (métrica com tag
  `subscription_expired_enddate` separada de `subscription_canceled`).
- Endpoint de autoatendimento: **já existia** (`POST /me/billing/update-card`, `PaymentMethodTransitionService.initiateCardUpdate`)
  — não precisou de endpoint novo, só não estava exposto no frontend.

**Frontend:**
- Botão "Atualizar cartão" adicionado em `PaymentMethodCard` (`/billing`), visível quando `paymentMethod === "CARD"`,
  chama `/me/billing/update-card` e abre o checkout retornado em nova aba.

**Testes:**
- `PaymentMethodTransitionServiceTest`, `BillingRecoveryServiceTest`, `TrialExpirationServiceTest`: novo teste/asserção
  por serviço garantindo `CheckoutSubscription.endDate() == null`.
- `BillingReconciliationServiceTest`: 2 novos testes (endDate passado → cancela; endDate futuro → noop, não é a
  mesma divergência).
- `mvn test` nos 5 arquivos afetados: **71/71 passando**.
- Frontend: `tsc --noEmit` e `eslint` limpos no arquivo alterado.
- **Não testado via browser contra PRD** — criaria um checkout real na conta do Douglas (ação financeira), decisão
  deliberada de não executar sem confirmação explícita.

**Pendente:**
- Push das branches + abertura de PR (api e web) — aguardando autorização.
- Remediação manual da assinatura já afetada (`subscription_id=2`, `sub_691xr4oh1yugsv5u`), via o próprio botão
  "Atualizar cartão" depois do deploy.

## Status
Em validação (implementação + testes completos; falta push/PR e aprovação humana).
