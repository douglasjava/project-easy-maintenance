# TASK-203 — Backend: validação de dígito verificador de CPF/CNPJ (defesa em profundidade)

## Tipo
BACKEND

## Categoria
Billing / Onboarding — Confiabilidade

## Prioridade
🟡 Médio

## Épico
[EPIC-002](../epics/EPIC-002.md) — Confiabilidade Operacional

## QA obrigatório
Sim — QA manual: chamar `POST /me/onboarding/user` e `PUT /admin/users/{id}/account` diretamente
(fora do formulário, ex. via Postman) com CPF/CNPJ de dígito verificador inválido e confirmar 400
com mensagem clara; confirmar que CPF/CNPJ válidos continuam funcionando normalmente.

---

## Contexto

TASK-202 bloqueia o CPF/CNPJ inválido no formulário de onboarding, mas isso é validação de UX, não
de segurança/integridade de dado — qualquer chamada direta à API (`POST /me/onboarding/user`,
`PUT /me/billing-account` se vier a existir, `PUT /admin/users/{id}/account`) ainda aceita qualquer
string no campo `doc`, sem validação nenhuma hoje.

Hoje `OnboardingDTO.AccountUserRequest.doc` e `BillingAccountDTO.UpdateBillingAccountRequest.doc`
são `String doc` sem nenhuma anotação de validação — nem `@NotBlank`, nem `@Pattern`, nem checagem
de dígito verificador.

## Objetivo

Validar dígito verificador de CPF/CNPJ no backend, nos dois pontos de entrada que gravam
`billing_accounts.doc`: onboarding e edição admin.

## Escopo

- Criar `DocumentValidator` (utilitário, `commons/utils` — mesmo pacote de `PhoneNumberNormalizerTest`
  hoje) com o algoritmo padrão de dígito verificador (mod 11) pra CPF (11 dígitos) e CNPJ (14
  dígitos), incluindo rejeição de sequências repetidas — mesma lógica de TASK-202, só que em Java.
- Criar anotação de bean validation `@ValidCpfCnpj` (com validator próprio usando o utilitário
  acima), aplicável a campo `String`. Padrão Jakarta Validation já usado no projeto (`@Size`,
  `@NotNull` etc. — ver `RegisterMaintenanceRequest` como referência de convenção).
- Aplicar `@ValidCpfCnpj` em `OnboardingDTO.AccountUserRequest.doc` e
  `BillingAccountDTO.UpdateBillingAccountRequest.doc`. Campo continua opcional (sem `@NotBlank`) —
  só valida formato quando preenchido.

## Critérios de Aceite

- [ ] `DocumentValidator` valida corretamente CPF e CNPJ reais (dígito verificador) e rejeita
      sequências repetidas
- [ ] `@ValidCpfCnpj` aplicado em `AccountUserRequest.doc` e `UpdateBillingAccountRequest.doc`
- [ ] Request com CPF/CNPJ inválido retorna 400 com mensagem clara (`ProblemDetail`)
- [ ] Request com `doc` vazio/nulo continua passando (campo opcional)
- [ ] Testes de unidade cobrindo `DocumentValidator` (CPF/CNPJ válidos, inválidos, sequências
      repetidas, vazio)
- [ ] `mvn test` sem regressão

## Fora de Escopo

- Validação em `OnboardingDTO.AccountOrganizationRequest.doc` (documento da organização) — mesma
  lógica poderia se aplicar, mas fica fora por ora pra manter o escopo pequeno; avaliar depois se
  fizer sentido estender.

## Dependências
Nenhuma — pode ser feita em paralelo com TASK-202 (mesmo algoritmo, implementações independentes).

## Riscos
Baixo — validação aditiva em campo já opcional, sem mudança de contrato pra quem já envia CPF/CNPJ
válido.

## Esforço
Baixo

## Status
🟡 Em validação — implementada em `feature/EPIC-002-fase3-asaas-sync` (api), commit `2e6e15a`.
Achado ao investigar: `@Doc`/`DocumentValidator` (Hibernate Validator `@CPF`/`@CNPJ`) já existiam no
projeto e já eram usados em `OrganizationDTO`, mas o import ficou órfão em `OnboardingDTO` — nunca
foi aplicado em `AccountUserRequest.doc` nem `AccountOrganizationRequest.doc`. Escopo reduzido a
aplicar `@Doc` nesses dois campos + `UpdateBillingAccountRequest.doc` (edição admin), em vez de
criar validador do zero. 5 testes novos cobrindo o CPF real do caso do Ricardo (rejeitado) e
CPF/CNPJ/null válidos (aceitos), 809/809 passando.
