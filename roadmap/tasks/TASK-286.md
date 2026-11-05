# TASK-286 — Fornecedor continua visível até o fim do período pago após cancelar

## Tipo
BACKEND

## Categoria
Marketplace de Fornecedores / Cobrança

## Prioridade
🟢 Baixo — backlog

## Épico
[EPIC-028](../epics/EPIC-028.md) — Marketplace de Fornecedores

## Problema

`PixAutomaticAuthorizationCancelledHandler` seta `marketplaceEnabled=false` imediatamente quando o
fornecedor revoga o Pix Automático — mesmo que ele já tenha pago o mês corrente
(`currentPeriodEnd` no futuro). Levantado no brainstorm da TASK-285 (24/09/2026); Douglas optou por
manter o comportamento atual e descrevê-lo com honestidade na página de políticas.

## Ideia

Ao cancelar com período pago em aberto, manter visível até `currentPeriodEnd` e desligar via job
(mesmo padrão de `SupplierBillingService`).

## ⚠️ Ao implementar
Atualizar o texto de cancelamento da seção de políticas e do FAQ em `/para-fornecedores`
(TASK-285) e a tabela de rastreabilidade do spec `2026-09-24-pagina-para-fornecedores-design.md`.

## Status
Backlog (ideia registrada)
