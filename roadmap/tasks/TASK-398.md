# TASK-398 — FRONTEND: botões "Prorrogar trial" / "Cortar acesso" no admin de billing (EPIC-041)

## Tipo
FRONTEND

## Categoria
Controle Administrativo de Acesso

## Prioridade
🟠 Alto

## Épico
[EPIC-041](../epics/EPIC-041.md) — Controle Administrativo de Acesso do Usuário

## QA obrigatório
Sim — fluxo manual completo pelo admin: prorrogar, confirmar nova data refletida; cortar somente
leitura; cortar bloqueio total; confirmar que motivo é obrigatório; confirmar estados de
loading/erro.

---

## Contexto
`/private/admin/billing/subscriptions` já tem ações rápidas (Upgrade/Downgrade/Cancelar) só para
itens tipo `USER`, e a aba Billing de `/private/users/[id]` tem um formulário hoje quebrado
(TASK-396 conserta o backend). Esta task cobre a parte de UI: dois botões novos de atalho, no
mesmo padrão visual dos já existentes, chamando os endpoints do TASK-396.

## Escopo
- Botão **"Prorrogar trial"** (visível só pra item tipo `USER`) → modal simples (nova data ou
  "+N dias"), chama `extendTrial`.
- Botão **"Cortar acesso"** → modal com seletor (Somente leitura / Bloquear login) + campo de
  motivo obrigatório, chama `restrictAccess`.
- Reaproveita componentes já existentes (`ConfirmModal`, padrão de `PlanChangeDialog`) em vez de
  criar modal do zero.
- Builder decide se os botões aparecem só em `/private/admin/billing/subscriptions`, só na aba
  Billing do usuário, ou nos dois — o que for mais simples de implementar reaproveitando o que já
  existe.

## Critérios de Aceite
- [ ] Prorrogar trial funciona ponta a ponta e reflete em `/me/access-context` do usuário afetado
- [ ] Cortar acesso (os dois níveis) funciona ponta a ponta
- [ ] Motivo vazio é bloqueado no front antes de chamar a API (mesma validação do backend)
- [ ] Estados de loading/erro tratados (sem crash, toast de erro claro)
- [ ] `tsc --noEmit`/`npm run build` sem regressão

## Dependências
TASK-396 (usa os endpoints consertados/novos).

## Riscos
Baixo — UI isolada em área administrativa interna, não afeta cliente final.

## Esforço
Pequeno

## Status
🟢 Implementado (03/11/2026) — branch `feature/EPIC-041-admin-access-control`
(`easy-maintenance-web`, commit `19b43af`). Botões adicionados em
`/private/admin/billing/subscriptions`, ao lado de Upgrade/Downgrade/Cancelar. `tsc --noEmit` e
`npm run build` sem erro. Branch ainda não mergeada em `staging`.
