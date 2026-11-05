# TASK-198 — Frontend: edição de afiliado (%/recorrência), atribuição a cliente, breakdown na tela de financeiro

## Tipo
FRONTEND

## Categoria
Admin / Financeiro / Afiliados

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Revisão da Fase 2

## QA obrigatório
Sim — QA manual: editar % e recorrência de um afiliado existente, confirmar persistência; atribuir
um comissionado a um usuário via busca; conferir que a seção "Comissões manuais" sumiu da tela de
financeiro e a nova seção "Comissões por pessoa" mostra nome/%/recorrência/valor corretos.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-24-affiliate-commission-rework.md`.

Depende da TASK-195 (endpoint de edição de afiliado), TASK-196 (endpoint de atribuição a usuário) e
TASK-197 (endpoint de breakdown). Fecha a revisão da Fase 2: hoje `/private/admin/affiliates` só lê
(nenhuma edição possível), e a tela de financeiro ainda tem a seção "Comissões manuais" (TASK-194)
que precisa sair.

## Objetivo

Tela de afiliados ganha edição de %/recorrência e atribuição a cliente; tela de financeiro troca
"Comissões manuais" por "Comissões por pessoa".

## Escopo

### 1. `easy-maintenance-web/src/app/private/admin/affiliates/page.tsx` — ações novas

- Coluna "Recorrência" na tabela (badge "Único"/"Recorrente", mesmo `StatusBadge` já usado em outras
  telas admin).
- Ação "Editar" por linha → abre `AffiliateEditModal.tsx` (novo): percentual (input 0-100, convertido
  pra fração no payload, mesmo padrão de `CommissionRuleFormModal` que está sendo removido),
  recorrência (`<select>` Único/Recorrente).
- Ação "Atribuir cliente" por linha → abre `AssignCommissionedModal.tsx` (novo): busca de usuário por
  e-mail/nome (reaproveitar o componente de busca já usado em outra tela admin, se existir; senão,
  input simples com autocomplete via `GET /private/admin/users?search=`), confirma e chama
  `PATCH /private/admin/users/{userId}/referral-code`.

### 2. `easy-maintenance-web/src/app/private/admin/financials/page.tsx` — troca de seção

- Remove `<ManualCommissionRulesSection />` e o import de `ManualCommissionRuleFormModal.tsx`
  (arquivos deletados no backend/frontend, TASK-195 já removeu o backend).
- Adiciona `<CommissionsBreakdownSection />` (novo): tabela nome, e-mail, %, recorrência (badge),
  valor do mês, status (X pagas / Y pendentes) — consome
  `GET /private/admin/financials/commissions-breakdown?month=...`, mesmo mês selecionado nos cards.
- Card "Comissões" do resumo já soma só `affiliateCommissionCents` desde a TASK-197 (backend) — sem
  mudança de código aqui além de remover a referência a `manualCommissionCents` do type
  `MonthlyFinancials`.

### 3. Testes / verificação
- `npm run build` limpo.
- QA manual (ver "QA obrigatório").

## Critérios de Aceite

- [x] "Editar" em afiliado persiste % e recorrência corretamente
- [x] "Atribuir cliente" vincula um comissionado a um usuário via busca
- [x] Tabela de afiliados mostra recorrência (Único/Recorrente) por linha
- [x] Seção "Comissões manuais" removida da tela de financeiro, sem import quebrado
- [x] Seção "Comissões por pessoa" mostra nome/%/recorrência/valor do mês corretamente
- [x] `npm run build` limpo

## Dependências
**TASK-195** (edição de afiliado), **TASK-196** (atribuição a usuário), **TASK-197** (breakdown).

## Riscos
Baixo — extensão de telas admin já existentes (Afiliados, Financeiro), mesmo padrão de modal/tabela
já usado em Leads/Despesas, sem tocar em fluxo de cliente final.

## Esforço
Médio

## Status
✅ Implementada e commitada (24/08/2026) na branch `feature/financial-module-v2`
(`easy-maintenance-web`, commit `4a4ff78`) — última das 5 tasks da revisão da Fase 2
(TASK-195 a 198). `npm run build` limpo (52 rotas, sem erro de tipo). **Não validada
visualmente por mim** — mesma limitação já registrada em tasks anteriores desta leva (tela
exige login, sem credenciais de teste disponíveis pra automação); aguardando Douglas testar
em navegador real.

**Notas de implementação**:
- **Achado durante a implementação**: `/private/admin/affiliates/page.tsx` não era, como o
  escopo original da task presumia, uma tabela de afiliados editável — era só uma lista de
  transações de comissão (`GET .../commissions`), sem nenhuma listagem/edição do afiliado em
  si. A seção "Comissionados" (tabela com % , recorrência, "Editar", "Atribuir cliente") teve
  que ser criada do zero, consumindo `GET /private/admin/affiliates-commissions` (endpoint que
  já existia, mas sem consumidor no frontend).
- **Bug corrigido, fora do escopo original mas causado pela TASK-196**: a tabela de comissões
  geradas lia `c.organizationId`, campo que o backend não envia mais desde a TASK-196 (virou
  `userId`) — a coluna estava silenciosamente quebrada nesta branch. Renomeada pra refletir o
  contrato atual ("Cliente (ID)").
- `StatusBadge.tsx` (componente compartilhado) ganhou os casos `ONE_TIME`/`RECURRING` — decisão
  de reaproveitar o componente já existente em vez de criar um badge local, conforme pedido
  literal do escopo ("mesmo `StatusBadge` já usado em outras telas admin").
- `npm test`: 99/102 passando; as 3 falhas são em `middleware.test.ts`, pré-existentes e sem
  relação com esta task (nenhum arquivo de middleware foi tocado).
- Lint (`npx eslint`) acusa `no-explicit-any` em `AffiliateEditModal.tsx`/
  `AssignCommissionedModal.tsx` (`catch (err: any)`) — confirmado como padrão já existente em
  todo modal deste diretório (ex.: `ExpenseFormModal.tsx` tem o mesmo erro), não é regressão;
  `npm run build` não bloqueia por causa disso.

**Achado de QA (Douglas, 24/08/2026)**: "Marcar pago" na tabela de comissões usava `confirm()`
nativo do navegador — único lugar de todo o frontend fazendo isso, destoava do resto do admin
(modais Bootstrap consistentes). Criado `ConfirmModal` (`src/components/admin/ConfirmModal.tsx`,
genérico/reutilizável) e trocado nessa tela (commit `a30709e`).
