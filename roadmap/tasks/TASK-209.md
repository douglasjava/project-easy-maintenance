# TASK-209 — BUGFIX Backend: `generateInvoiceForPayer` desiste quando a fatura já existe (idempotência confundida com falha)

## Tipo
BUGFIX

## Categoria
Backend / Billing (jobs de renovação PIX, transição de cartão, recuperação de pagamento)

## Prioridade
🔴 Crítico

## Épico
Sem épico — achado em uso real (conta de teste de Douglas em produção), 28/08/2026.

## QA obrigatório
Sim — QA manual: reprocessar a assinatura travada de Douglas (subscriptionId=2) e confirmar que o
checkout da Asaas é criado; conferir que os outros 3 fluxos afetados (renovação PIX, atualização de
cartão pelo usuário, recuperação de pagamento) continuam funcionando sem regressão.

---

## Contexto

Douglas está testando os fluxos em produção com a própria conta (onboarding com PIX, depois trocou
pra cartão de crédito no meio do ciclo). O job `PixRenewalJob` (roda diariamente às 01:30) processa
transições CC pendentes via `CardTransitionService`, e o log mostrou:

```
[CardTransition] Found 1 subscription(s) pending CC checkout creation
Generating invoice for payer 2 and period 2026-08-31 to 2026-09-29
Invoice already exists for payer 2 and period 2026-08-31 to 2026-09-29. Skipping.
[CardTransition] No invoice generated for subscription 2 (userId=2). Skipping.
```

A tela do usuário mostra "Pagamento pendente — R$ 299,00" (a fatura existe, `invoices` id=2, OPEN),
mas **sem link da Asaas pra pagar** — o checkout nunca foi criado.

## Causa raiz

`InvoiceService.processPayerInvoice` retorna `Optional.empty()` em dois cenários com significados
opostos:
1. Não há nada pra faturar (caso de erro real — não acontece na prática hoje, ver "Notas" abaixo).
2. A fatura do período **já existe** (idempotência — não é erro, só "não precisa criar de novo"),
   usado corretamente pelo job em lote `generateInvoices` (só quer saber quantas foram criadas
   *novas* naquele lote).

O método público `generateInvoiceForPayer` (`InvoiceService.java:111`) repassa esse mesmo
`Optional.empty()` ambíguo pra **4 chamadores diferentes**, todos os quais precisam da fatura de
qualquer forma (pra anexar um pagamento/checkout novo nela) — nenhum deles quer só "saber se foi
criada agora":

1. `CardTransitionService.processTransition` (`CardTransitionService.java:73-79`) —
   `.orElse(null)` → `WARN` + `return` (o bug relatado por Douglas).
2. `PixRenewalService.renewSubscription` (`PixRenewalService.java:91-98`) — mesmo padrão,
   `.orElse(null)` → `WARN` + `return`. **Mais grave**: se a fatura do próximo ciclo já existir por
   qualquer motivo antes do job de renovação PIX rodar, a renovação de um cliente pagante real trava
   do mesmo jeito, sem gerar cobrança nova e sem alerta visível.
3. `PaymentMethodTransitionService.initiateCardUpdate` (`PaymentMethodTransitionService.java:99-101`)
   — ação síncrona do usuário ("atualizar cartão") — `.orElseThrow(RuleException("Não foi possível
   gerar a fatura. Verifique se existem itens ativos na assinatura."))` → usuário vê uma mensagem
   **enganosa** (parece falta de plano ativo, quando na real é só idempotência).
4. `BillingRecoveryService.generateRecoveryInvoice` (`BillingRecoveryService.java:201-205`) — mesmo
   padrão `.orElseThrow(...)`, no fluxo de recuperação de pagamento em atraso.

## Objetivo

`generateInvoiceForPayer` passa a devolver a fatura do período **sempre que a assinatura for
válida** — seja ela recém-criada ou já existente — resolvendo os 4 pontos de chamada de uma vez, sem
tocar no contrato de `processPayerInvoice`/`generateInvoices` (job em lote continua contando só
faturas novas, sem mudança de comportamento ali).

## Escopo

### `InvoiceService.generateInvoiceForPayer` — desambiguar o retorno

```java
@Transactional
public Optional<Invoice> generateInvoiceForPayer(Long payerId, LocalDate start, LocalDate end) {
    log.info("Generating invoice for payer {} and period {} to {}", payerId, start, end);

    var billingSubscription = billingSubscriptionRepository.findByBillingAccountUserId(payerId)
            .orElseThrow(() -> new NotFoundException("Billing subscription not found for payer: " + payerId));

    Optional<Invoice> generated = processPayerInvoice(billingSubscription, start, end);
    if (generated.isPresent()) {
        return generated;
    }
    // processPayerInvoice devolve vazio quando a fatura do período já existe (idempotência) --
    // diferente de generateInvoices (job em lote, só quer contar faturas NOVAS), os chamadores
    // deste método precisam da fatura de qualquer forma, pra anexar um pagamento/checkout novo.
    return repository.findByPayerIdAndPeriodStartAndPeriodEnd(payerId, start, end);
}
```

Nenhuma mudança nos 4 pontos de chamada (`CardTransitionService`, `PixRenewalService`,
`PaymentMethodTransitionService`, `BillingRecoveryService`) — todos passam a receber a fatura
correta automaticamente, sem precisar alterar `.orElse(null)`/`.orElseThrow(...)`.

### Reprocessar a assinatura travada de Douglas (subscriptionId=2)

Depois do fix e deploy, o job `PixRenewalJob` roda diariamente às 01:30 e vai encontrar essa
assinatura de novo (ainda elegível: `ACTIVE`, `CARD`, sem `externalSubscriptionId`) — deve se
autocorrigir no próximo run, sem intervenção manual. Se Douglas quiser validar sem esperar até
amanhã, pode disparar o job manualmente (endpoint/trigger já existente, confirmar no código de
`PixRenewalJob` antes de instruir).

## Critérios de Aceite

- [x] `generateInvoiceForPayer` retorna a fatura já existente (não `Optional.empty()`) quando ela já
      foi criada pro período pedido
- [x] `generateInvoiceForPayer` continua criando a fatura normalmente quando ela não existe (sem
      regressão do caminho feliz)
- [x] `generateInvoices` (job em lote) continua contando só faturas novas no log — sem mudança de
      comportamento (não tocado, `processPayerInvoice` intacto)
- [x] `CardTransitionService`/`PixRenewalService`/`PaymentMethodTransitionService`/
      `BillingRecoveryService`: corrigidos automaticamente, sem alteração de código nesses 4
      arquivos (fix isolado em `generateInvoiceForPayer`)
- [x] `mvn test` sem regressão (844/844)
- [ ] QA manual: assinatura travada de Douglas (subscriptionId=2) gera checkout/link de pagamento
      após reprocessamento — pendente de deploy em produção e próximo run do job (01:30) ou
      trigger manual

## Dependências
Nenhuma.

## Riscos
Médio — toca lógica central de faturamento usada por 4 fluxos de billing em produção
(renovação PIX, transição PIX→Cartão, atualização de cartão, recuperação de atraso). Mitigado por
ser uma mudança cirúrgica de uma linha (`return Optional.empty()` → busca da fatura existente),
sem alterar o contrato do job em lote nem a lógica de criação de fatura nova.

## Esforço
Baixo

## Status
✅ Implementada e commitada (28/08/2026) na branch `bugfix/TASK-209-invoice-already-exists-silent-skip`
(`easy-maintenance-api`, commit `0d3851c`, a partir de `staging`). Suíte completa: 844 testes, 0
falhas (inclui `InvoiceServiceTest.generateInvoiceForPayer_invoiceAlreadyExists_shouldReturnExistingInvoiceNotEmpty`,
caso novo que reproduz o bug relatado). Sem PR aberta ainda — Douglas está com um usuário de teste
travado em produção (`subscriptionId=2`) por causa deste bug; assim que o fix for promovido
(`staging` → `main` → deploy), o job `PixRenewalJob` (roda diariamente às 01:30) deve reprocessar e
gerar o checkout automaticamente, sem intervenção manual — não existe endpoint de trigger manual
pra esse job específico hoje (`/run-jobs/**` cobre outros jobs, não este).
