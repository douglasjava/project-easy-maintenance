# TASK-201 — Backend+Frontend: ressincronização manual de cliente Asaas por usuário

## Tipo
FULL_STACK

## Categoria
Billing / Onboarding — Confiabilidade

## Prioridade
🟠 Alto

## Épico
[EPIC-002](../epics/EPIC-002.md) — Confiabilidade Operacional

## QA obrigatório
Sim — QA manual: corrigir o `doc` de uma conta sem `externalCustomerId` na aba Pagamento do admin,
clicar em "Ressincronizar com Asaas", confirmar que `externalCustomerId` passa a ser preenchido e
que o botão mostra erro claro se a Asaas rejeitar de novo (ex.: CPF ainda inválido).

---

## Contexto

Achado ao investigar o caso do Ricardo Cerqueira (25/08/2026, primeiro cliente pagante): o CPF dele
foi rejeitado pela Asaas no onboarding (`invalid_object` — dígito verificador não bate), o erro foi
engolido silenciosamente (`OnboardingService.createUser`, catch genérico por design — não deve travar
o cadastro se a Asaas cair) e a conta ficou com `billing_accounts.external_customer_id = NULL`.

Hoje existe:
- Um endpoint admin (`PUT /admin/users/{userId}/account`) pra corrigir o `doc` — já tem tela
  (`/private/users/[id]`, aba Pagamento).
- Um job diário (`ExternalCustomerSyncJob`, 6h da manhã) que tenta recriar o cliente na Asaas pra
  contas com `externalCustomerId` nulo.
- Um endpoint admin bulk (`POST /admin/billing/external-customer-sync`) que dispara esse job sob
  demanda — mas **sem nenhum botão no frontend** pra chamá-lo.

Resultado: corrigir o CPF de um cliente hoje não resolve na hora — fica esperando o job do dia
seguinte, sem confirmação nenhuma de que a correção funcionou.

## Objetivo

Botão "Ressincronizar com Asaas" na aba Pagamento do admin (`/private/users/[id]`), que tenta criar o
cliente na Asaas imediatamente pra aquela conta específica e mostra o resultado (sucesso ou o erro
exato retornado pela Asaas).

## Escopo

### 1. Backend — `easy-maintenance-api`

Novo endpoint, escopado a um usuário (não usar o bulk existente — evita reprocessar outras contas e
dá feedback direto sobre o resultado dessa conta específica):

```
POST /admin/users/{userId}/account/sync-external-customer
```

Reaproveita a mesma lógica já existente em `ExternalCustomerSyncService`/`AsaasProvider.createExternalCustomer`
(criar `CustomerDTO` via `IOnboardingMapper`, chamar `providerFactory.get(ASAAS).createExternalCustomer`,
salvar `externalCustomerId`), só que para uma conta específica e propagando o erro da Asaas pro
response (em vez de engolir e seguir, como o fluxo de onboarding faz de propósito).

- Se `externalCustomerId` já existe: erro de validação (nada a sincronizar).
- Se a Asaas aceitar: salva `externalCustomerId`, retorna sucesso.
- Se a Asaas rejeitar (ex.: CPF ainda inválido): retorna o erro da Asaas (`AsaasException.getMessage()`)
  como `ProblemDetail`, sem mascarar.

### 2. Frontend — `easy-maintenance-web`

`src/app/private/users/[id]/page.tsx`, aba Pagamento: botão "Ressincronizar com Asaas", visível
sempre (não só quando `externalCustomerId` está vazio — admin pode querer forçar retry mesmo com
erro anterior registrado). Ao clicar: chama o endpoint novo, toast de sucesso/erro com a mensagem
retornada, recarrega os dados da conta (`fetchUserPayment`) pra atualizar o indicador (ver TASK-205).

## Critérios de Aceite

- [ ] Endpoint `POST /admin/users/{userId}/account/sync-external-customer` cria o cliente na Asaas
      pra uma conta específica e salva `externalCustomerId`
- [ ] Endpoint retorna o erro real da Asaas quando a criação falha (não engole a exceção)
- [ ] Botão "Ressincronizar com Asaas" na aba Pagamento do admin, com feedback de sucesso/erro
- [ ] `mvn test` e `npm run build` sem regressão

## Fora de Escopo

- Alterar o comportamento do onboarding (que deve continuar não travando o cadastro se a Asaas
  falhar) — esse endpoint é só a ferramenta de correção manual, não muda o fluxo automático.
- Job noturno (`ExternalCustomerSyncJob`) — continua rodando como está, esse endpoint é
  complementar, não substituto.

## Dependências
Nenhuma. Pode ser feita em paralelo com TASK-205 (mesma tela) sem conflito real de escopo.

## Riscos
Baixo — endpoint aditivo, sem mudança em fluxo existente.

## Esforço
Baixo

## Status
🟡 Em validação — implementada em `feature/EPIC-002-fase3-asaas-sync` nos dois repos.

- api: `738d7a6` — `ExternalCustomerSyncService.syncOne`, endpoint
  `POST /admin/billing/users/{userId}/account/sync-external-customer`, novo handler de
  `AsaasException` no `GlobalExceptionHandler` (antes caía no genérico e mascarava a mensagem),
  4 testes novos (809/809 passando)
- web: `0620743` — botão "Ressincronizar com Asaas" na aba Pagamento do admin
