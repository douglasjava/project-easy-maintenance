# TASK-291 — Onboarding retoma do passo pendente (passo 2) quando o passo 1 já foi concluído

## Tipo
FULL_STACK

## Categoria
Onboarding / Aquisição

## Prioridade
🔴 Alto — destrava clientes que pararam no meio do cadastro sem precisar limpar a base

## QA obrigatório
Sim — testes de serviço + QA no browser.

---

## Contexto

Após o bug da [TASK-289](TASK-289.md), o cliente que travou no passo 2 já tinha o passo 1 gravado
(conta de cobrança, cliente no Asaas, trial BUSINESS). Douglas decidiu (24/09/2026) **não** limpar a
base: o certo é o onboarding abrir direto no passo pendente. Hoje a tela sempre começa no passo 1.

## Escopo

- **api**: `GET /me/onboarding/status` → `{ "billingStepCompleted": true|false }` para o usuário
  logado (conta de cobrança **e** assinatura já existem). Liberado no `TenantFilter` (usuário ainda
  não tem organização), mesmo padrão dos `POST /me/onboarding/*`.
- **web**: `/onboarding` consulta o status ao abrir; com o passo 1 concluído, abre direto no passo 2
  com aviso "Seus dados de faturamento já estão salvos". Falha na consulta → segue no passo 1 (o
  passo 1 é idempotente com a [TASK-245](TASK-245.md)).

## Dependência
[TASK-245](TASK-245.md) (api#119) — garante que voltar/refazer o passo 1 não duplica o item USER.

## Critérios de Aceite
- [x] Usuário com passo 1 concluído e sem organização abre o `/onboarding` direto no passo 2 (browser,
      API simulada) com aviso "Seus dados de faturamento já estão salvos"
- [x] Usuário novo continua começando no passo 1
- [x] Endpoint acessível sem organização (sem `X-Org-Id`) e só com usuário autenticado
      (`TenantFilterTest`)
- [x] Erro na consulta não trava a tela (cai no passo 1)
- [x] `OnboardingStatusTest` (3) + teste do filtro + `onboardingResume.test.ts` (4); `mvn test`
      1105/1105; `npm test` 185/188 (3 pré-existentes)

## Implementação
- Branch `feature/TASK-291-onboarding-resume-step` (api e web, a partir de `staging`)
- PRs: [api#120](https://github.com/douglasjava/easy-maintenance-api/pull/120) ·
  [web#99](https://github.com/douglasjava/easy-maintenance-web/pull/99) — mergear **depois** da
  [api#119](https://github.com/douglasjava/easy-maintenance-api/pull/119) (TASK-245)
- Cliente afetado pela TASK-289 (conta de cobrança 8): **não precisa limpar a base** — ao entrar de
  novo, cai direto no passo 2.

## Status
🟡 Em Validação — PRs abertas contra `staging`.
