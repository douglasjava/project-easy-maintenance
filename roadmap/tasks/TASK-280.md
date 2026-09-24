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

## Critérios de Aceite
- [x] Fornecedor vê os pedidos recebidos pelo link mágico, com organização e contato de quem pediu
- [x] Kanban Novo → Em contato → Orçamento enviado → Fechado / Perdido; mover persiste
- [x] Pedido de outro fornecedor → 404 sem alteração (teste unitário + smoke em MySQL real)
- [x] Organização/usuário removido não quebra a listagem ("—")
- [x] Mobile 390px sem scroll horizontal; desktop 5 colunas
- [x] Falha ao mover → card volta + aviso
- [x] "Meus dados" e QR de pagamento pendente continuam funcionando
- [~] Aviso LGPD no modal "Solicitar orçamento" — conferido por código, falta QA visual logado como organização

## Implementação
- Branch `feature/TASK-280-kanban-pedidos-fornecedor` em `api` e `web` (a partir de `staging`)
- api: V115 (`status`, `status_updated_at`), `BudgetRequestStatus`, finders escopados, `SupplierBudgetInboxService`,
  `GET`/`PATCH /public/suppliers/manage/{token}/budget-requests` — `mvn test` 1088/1088, V115 validada no
  MySQL do Docker local
- web: `src/lib/supplierBudgetBoard.ts` (+15 testes), `BudgetRequestBoard`/`BudgetRequestCard`, abas em
  `/fornecedores/gerenciar/[token]`, aviso LGPD em `/fornecedores` — `npm test` 170/173 (3 pré-existentes)
- Revisão final independente: 0 crítico/importante; 1 menor reclassificado e corrigido (skeleton no
  carregamento); 8 menores registrados (duplo movimento rápido + falha, setas do teclado no select,
  ARIA das abas, rate limit compartilhado, "há X dias" por 24h, sem teste de controller, save redundante,
  indentação)
- Validação de campo inválido responde **422** (padrão do `GlobalExceptionHandler`), não 400 como o spec dizia
- PRs: [api#116](https://github.com/douglasjava/easy-maintenance-api/pull/116) ·
  [web#95](https://github.com/douglasjava/easy-maintenance-web/pull/95) (`staging`)

## Status
🟡 Em Validação — implementado, testado, PRs abertas contra `staging`.
