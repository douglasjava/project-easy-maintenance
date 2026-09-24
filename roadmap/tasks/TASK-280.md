# TASK-280 — Fornecedor consegue ver os orçamentos solicitados a ele

## Tipo
FULL_STACK

## Categoria
Backend / Frontend / Marketplace de Fornecedores

## Prioridade
🟠 Alto — valor percebido pelo fornecedor pagante

## Épico
[EPIC-028](../epics/EPIC-028.md) — Marketplace de Fornecedores

## Problema

`supplier_budget_requests` (TASK-263, "Solicitar Orçamento", Fase 2) já grava cada pedido de
orçamento feito a um fornecedor (`supplierId`, `organizationCode`, `requestedByUserId`, `summary`,
`createdAt`) — mas nada lê essa tabela de volta hoje. `SupplierBudgetRequestRepository` não tem
nenhum finder além do CRUD padrão do Spring Data, e não existe controller/endpoint que liste esses
pedidos pro fornecedor.

Resultado: o fornecedor paga R$ 15,99/mês (Pix Automático, TASK-278) pra aparecer no marketplace e
receber pedidos de orçamento, mas nunca vê os pedidos que já foram feitos a ele — o dado é
coletado e pago, sem entregar valor nenhum de volta.

Levantado por Douglas durante o QA do Pix Automático em produção (22/09/2026), no mesmo contexto da
pergunta sobre busca por raio (ver [TASK-279](TASK-279.md)).

## Ideia (não desenhada ainda)

Adicionar um finder em `SupplierBudgetRequestRepository` (por `supplierId`) + endpoint de listagem,
e exibir a lista na tela pública `/fornecedores/gerenciar/[token]` (já existe, sem login/token de
acesso) — ganho direto de percepção de valor pro fornecedor assinante, relevante dado que o motivo
original do Pix Automático foi reduzir churn/atrito do fornecedor pagante.

## Desenho (brainstorm 24/09/2026)

Spec aprovado: `docs/superpowers/specs/2026-09-24-kanban-pedidos-fornecedor-design.md`. Resumo:
aba "Pedidos" em `/fornecedores/gerenciar/[token]` com kanban Novo → Em contato → Orçamento
enviado → Fechado / Perdido (sem drag-and-drop; abas por coluna no mobile); fornecedor vê
organização, bairro/cidade, nome + WhatsApp + e-mail de quem pediu; aviso LGPD no modal "Solicitar
orçamento"; backend com migration V115 (`status`, `status_updated_at`) + `GET`/`PATCH`
`/public/suppliers/manage/{token}/budget-requests` com 404 uniforme contra IDOR.

## Status
Backlog — spec aprovado, aguardando plano de implementação
