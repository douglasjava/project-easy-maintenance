# TASK-277 — BACKLOG BUGFIX: customer Asaas criado sem e-mail fica permanentemente quebrado (sem `updateCustomer`)

## Tipo
BUGFIX

## Categoria
Backend / Billing (integração Asaas)

## Prioridade
🟡 Médio — não é urgente (achado isolado até agora, contornável manualmente pelo painel do Asaas
caso se repita), mas é uma armadilha permanente de dados: qualquer conta que já tenha
`external_customer_id` porém `billing_email` vazio segue quebrada para sempre em qualquer fluxo que
crie checkout/cobrança itemizada, mesmo depois do `billing_email` ser preenchido depois.

## Épico
Sem épico — achado durante o QA manual da TASK-276 (14/09/2026), reprocessando trials vencidos:
subscriptionId 7 (Sidnei Fernandes da Silva, payer 12) falhou com
`400 "O campo email deve existir para o customer informado."` ao criar checkout Asaas.

## QA obrigatório
Sim — QA manual: forçar um `billing_email` vazio num onboarding de teste, confirmar que o customer
nasce sem e-mail no Asaas sandbox, preencher o `billing_email` depois e confirmar que o fix
sincroniza o e-mail no Asaas (via chamada explícita ou automaticamente no próximo checkout).

---

## Contexto

`IOnboardingMapper.toCustomerDTO` (`onboarding/mapper/IOnboardingMapper.java:16`) mapeia o `email`
do customer Asaas a partir de `account.getBillingEmail()`. Se esse campo está vazio no momento em
que o customer é criado (`OnboardingService.java:61-66`, ou `ExternalCustomerSyncService`), o
customer nasce no Asaas sem e-mail.

`TrialExpirationService.resolveExternalCustomerId` (e equivalentes em outros serviços de billing)
só cria um customer novo quando `account.getExternalCustomerId()` está vazio — se já existe um ID,
a função devolve sem tocar no Asaas. Como o checkout (`CreateCheckoutRequest.customer`) manda só o
ID de referência, nunca o e-mail inline, um `billing_email` preenchido localmente depois **não se
propaga pro Asaas**. `AsaasClient` não tem nenhum método `updateCustomer`/PUT `/customers/{id}` —
não existe hoje nenhum caminho de código pra corrigir um customer já quebrado.

Caso real: subscriptionId 7, payer 12 (Sidnei) — `billing_email` estava vazio, confirmado por
Douglas via SQL (`SELECT billing_email FROM billing_accounts WHERE user_id = 12` → vazio). Contorno
aplicado manualmente por Douglas direto no painel do Asaas (edição do e-mail do customer). Depois
disso, reprocessar o job funcionou normalmente (checkout criado, e-mail `TRIAL_EXPIRING` enviado,
dispatch=46).

## Escopo (proposto, a confirmar no `/execute-task`)

- Adicionar `AsaasClient.updateCustomer(String customerId, AsaasDTO.CreateCustomerRequest req)` —
  PUT `/customers/{id}`.
- Decidir onde disparar a sincronização: opção A (mais simples) — sempre que
  `resolveExternalCustomerId`/equivalente encontrar `externalCustomerId` já setado, mas com
  `billing_email` local não-vazio, fazer um `updateCustomer` idempotente antes do checkout (custo:
  uma chamada Asaas a mais por cobrança). Opção B (mais cirúrgica) — só sincronizar sob demanda,
  reaproveitando o padrão de `ExternalCustomerSyncService.syncOne`, mas permitindo update em vez de
  só create-quando-nulo.
- Varredura de dados: identificar quantas contas em produção têm `external_customer_id` setado com
  `billing_email` vazio ou preenchido depois da criação do customer (indício indireto — confirmação
  real só dá pra fazer consultando o Asaas por conta).

## Critérios de Aceite
- [ ] Customer Asaas criado sem e-mail é corrigido automaticamente (ou via rota manual) quando
      `billing_email` local está preenchido, sem exigir edição manual no painel do Asaas
- [ ] Teste de regressão reproduzindo o caso real (customer sem e-mail, checkout falha, sync
      corrige, checkout funciona)
- [ ] `mvn clean test` sem regressão

## Dependências
Nenhuma. Relacionado à TASK-276 (achado durante o QA manual dela).

## Riscos
Baixo — aditivo (novo método de client + ponto de chamada), não muda comportamento existente para
contas já corretas.

## Esforço
Pequeno-médio (~2-4h: método de client + decisão de onde disparar + testes).

## Status
🔵 Backlog — registrado por decisão de Douglas (14/09/2026): não é urgente agora, sem próximos
passos definidos ainda.
