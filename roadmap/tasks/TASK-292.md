# TASK-292 — Segurança: `GET /me/billing/accounts` parece listar contas de faturamento de todos os clientes

## Tipo
BUGFIX (Backend / Segurança / LGPD)

## Categoria
Segurança

## Prioridade
🔴 Alto — possível exposição de dado pessoal (nome, e-mail, CPF/CNPJ) entre clientes

## QA obrigatório
Sim — teste automatizado de autorização + verificação em staging com usuário comum.

---

## Achado (24/09/2026, durante a TASK-291 — **não confirmado em runtime**)

`BillingController` (`/easy-maintenance/api/v1/me/billing`) expõe `GET accounts`, que chama
`BillingAccountService.findAll(email, name, doc, status, pageable)` — busca **em todas** as
`billing_accounts`, com filtros `LIKE` por e-mail, nome e documento.

- Não há `@PreAuthorize`/`hasRole` no controller nem regra para essa rota no `SecurityConfig`.
- O front **não usa** essa rota — o painel admin usa `/private/admin/billing/accounts`
  (`admin-billing.service.ts`). Parece ser uma rota esquecida.

Se confirmado, qualquer usuário autenticado consegue listar/filtrar dados de faturamento de todos
os clientes.

## Próximos passos
1. Confirmar em staging com um usuário comum (sem papel admin): `GET /me/billing/accounts`.
2. Se confirmado: remover a rota (não tem consumidor) ou restringir a admin; teste de autorização.
3. Avaliar se houve acesso indevido (logs de acesso à rota em PRD).

## Status
Backlog — prioridade alta, investigar antes da próxima release
