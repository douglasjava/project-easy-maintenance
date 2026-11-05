# TASK-317 — Segurança: endurecer a autorização das rotas do usuário

## Tipo
BUGFIX (Backend / Segurança)

## Prioridade
🔴 Alto

## QA obrigatório
Sim — regressivo antes × depois (API + telas) e teste de isolamento entre clientes.

## Contexto
Achado ao investigar a [TASK-292](TASK-292.md) em 28/09/2026: algumas rotas do app não verificavam se o usuário
logado era o dono do recurso pedido. Os detalhes técnicos ficam no repositório privado da API
(PR [api#136](https://github.com/douglasjava/easy-maintenance-api/pull/136)).

## Entrega
- Autorização por rota (dono do recurso / membro da organização), checada no banco.
- Rotas sem consumidor removidas; painel admin (`/private/admin`) inalterado.
- Rota inexistente passa a responder 404/405 em vez de 500.
- Regressivo local antes × depois: fluxos do app e do admin iguais; acessos indevidos bloqueados.

## Pendências
- Validar em staging (login, nova empresa, editar empresa, perfil, equipe) antes de promover.
- Após o deploy em produção: revisar logs de acesso.
- Os testes E2E novos vão para o repositório só depois do deploy em produção.

## Status
Done — em produção desde 28/09/2026 (api#141 + web#107); validado por Douglas em 29/09/2026 (webhooks do Asaas respondendo 200).
