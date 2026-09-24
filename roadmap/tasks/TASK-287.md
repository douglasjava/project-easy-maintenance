# TASK-287 — Persistir UTM/origem no cadastro de fornecedor

## Tipo
FULL_STACK

## Categoria
Marketing / Marketplace de Fornecedores

## Prioridade
🟢 Baixo — backlog

## Épico
[EPIC-028](../epics/EPIC-028.md) — Marketplace de Fornecedores

## Problema

`SelfRegisterSupplierRequest` não recebe nem grava UTM/origem. Com a divulgação da
`/para-fornecedores` (TASK-285), a conversão por campanha só fica visível no Meta/GA, não no banco
— diferente de `landing_leads`, que já grava UTM/afiliado. Levantado no brainstorm da TASK-285
(24/09/2026), deixado fora pra manter aquela entrega 100% frontend.

## Ideia

Migration com colunas de UTM no fornecedor (ou assinatura), campos opcionais no
`SelfRegisterSupplierRequest`, e `/fornecedores/cadastro` enviando `getStoredUtm()` — mesmo padrão
do formulário da `/landing`.

## Status
Backlog (ideia registrada)
