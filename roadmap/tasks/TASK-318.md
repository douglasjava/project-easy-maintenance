# TASK-318 — Segurança: reforçar a validação do webhook de pagamentos

## Tipo
BUGFIX (Backend / Segurança / Billing)

## Prioridade
🔴 Alto

## QA obrigatório
Sim — os webhooks reais do Asaas precisam continuar sendo processados depois da mudança.

## Contexto
Achado no regressivo da [TASK-317](TASK-317.md) (28/09/2026). Os detalhes técnicos ficam na issue privada
[api#137](https://github.com/douglasjava/easy-maintenance-api/issues/137).

Em 28/09/2026 o Douglas configurou em produção a variável do token de webhook (antes ela não existia).

## Pré-requisito (antes do deploy)
- O token de autenticação configurado no painel do Asaas (Integrações → Webhooks) precisa ser **igual** ao configurado
  em produção. Se forem diferentes, os pagamentos param de ser processados.

## Critérios de aceite
- [x] Requisições de webhook sem o token correto são rejeitadas.
- [x] A aplicação não sobe em produção sem o token configurado.
- [x] Os testes E2E de webhook (`billing/webhook-token.spec.ts`) voltam a passar.
- [x] Depois do deploy, os webhooks reais do Asaas continuam retornando 200 (conferir nos logs).

## Execução (28/09/2026)
PR [api#138](https://github.com/douglasjava/easy-maintenance-api/pull/138) — detalhes na PR/issue privadas. Antes de promover
para main: confirmar que o token do painel do Asaas é igual ao de produção.

## Status
Done — em produção desde 28/09/2026 (api#141 + web#107); validado por Douglas em 29/09/2026 (webhooks do Asaas respondendo 200).
