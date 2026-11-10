# TASK-346 — Vínculo item ↔ fornecedor + tipo de contrato

## Tipo
FULL_STACK

## Prioridade
🟠 Alto

## Épico
[EPIC-034](../epics/EPIC-034.md) — Leitura de documentos por IA no WhatsApp + fornecedor e contrato por item · **Fase 2**

## Depende de
—

## QA obrigatório
Sim.

## Contexto
Hoje o fornecedor é ligado à organização e `performedBy` é texto. Precisamos do fornecedor de referência por item e do tipo de contrato.
Base: `staging` · branch `feature/TASK-346-<descricao-curta>`.

## Escopo
> **10/11/2026 (D15 da matriz):** este vínculo é o fornecedor **habitual** do item, usado como sugestão ("Acionar
> fornecedor", cartão do registro, "serviços que vencem para mim" do fornecedor). O fornecedor **responsável** de cada
> execução fica na manutenção ([TASK-423](TASK-423.md)).

- Migration: vínculo (item, fornecedor, origem `OCR|MANUAL|STATEMENT`, `contract_type` `RECURRING|ON_DEMAND|INTERNAL`, início, fim, valor mensal opcional).
- Endpoints com isolamento por `X-Org-Id`.
- Web: coluna "fornecedor" na lista de itens e bloco no detalhe.

## Critérios de aceite
- [ ] Vincular/desvincular fornecedor a um item
- [ ] Coluna aparece na lista (mobile ok)
- [ ] Acesso cross-tenant bloqueado (teste)

## Status
Backlog
