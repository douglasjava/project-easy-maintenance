# TASK-289 — Onboarding trava no passo 2 quando o CNPJ/CPF (opcional) da organização fica em branco

## Tipo
BUGFIX (Full-stack)

## Categoria
Onboarding / Aquisição

## Prioridade
🔴 Crítico — bloqueia o cadastro de cliente novo em produção

## QA obrigatório
Sim — teste de regressão automatizado (backend + frontend) + reprodução no browser.

---

## Problema (PRD, 24/09/2026)

Cliente fez o onboarding e ficou travado na tela de criação da organização, "sem nenhum feedback".
Log de produção: 5 `POST /me/onboarding/organization` em ~2 min, todos rejeitados com
`Field error … on field 'doc': rejected value []; … Documento inválido` (422).

## Causa raiz (confirmada)

1. **Contrato**: o campo "CNPJ / CPF (opcional)" do passo 2 envia `doc: ""` quando fica em branco
   (`onlyNumbers("")`). No backend, `AccountOrganizationRequest.doc` tem `@Doc` (composição
   `@CPF` OR `@CNPJ`, TASK-202/203, 25/08/2026) sem `@NotBlank` — `null` passa, mas `""` falha nas
   duas validações. Desde 25/08, todo onboarding sem documento da organização fica bloqueado.
2. **UX**: o 422 vira `fieldErrors.doc` ("CPF ou CNPJ inválido") no próprio campo, sem toast e sem
   rolar até ele. No celular (390px) o campo fica ~145px acima da área visível depois do clique em
   "Criar minha conta" — o usuário não vê nada acontecer. Reproduzido no browser com o mesmo 422.

## Correção

- **api**: `AccountOrganizationRequest` normaliza `doc` em branco pra `null` (compact constructor do
  record) — documento opcional volta a ser opcional pra qualquer cliente (inclusive bundles antigos
  do front em cache).
- **web**: passo 2 não envia `doc` quando vazio; erros de campo (validação local ou 422) rolam até o
  primeiro campo inválido e mostram toast "Revise os campos destacados".

## Critérios de Aceite
- [x] Onboarding com CNPJ/CPF da organização em branco cria a organização — browser 390px (API
      simulada): `doc` ausente no corpo, organização criada; backend aceita `""`/`"   "` como não informado
- [x] CNPJ/CPF preenchido e inválido continua sendo rejeitado, com mensagem visível no celular
- [x] Erro de campo no onboarding sempre fica visível (scroll até o campo + toast)
- [x] Testes de regressão: `AccountOrganizationRequestTest` (6, falhavam antes) e
      `optionalDocument.test.ts` (7)
- [x] `mvn test` 1101/1101; `npm test` 177/180 (3 pré-existentes de `middleware.test.ts`)

## Implementação
- Branch `bugfix/TASK-289-onboarding-optional-org-doc` (api e web, a partir de `staging`)
- PRs: [api#118](https://github.com/douglasjava/easy-maintenance-api/pull/118) ·
  [web#97](https://github.com/douglasjava/easy-maintenance-web/pull/97) (`staging`)

## Ponto de atenção
O bug existe desde 25/08/2026 (TASK-202/203). Vale checar no banco de PRD quantas contas passaram do
passo 1 (billing account/usuário criados) sem organização desde então — são cadastros perdidos que
podem ser recuperados com contato ativo.

## Status
🟡 Em Validação — PRs abertas contra `staging`; entra na próxima promoção pra `main` junto com
TASK-285/280/288.
