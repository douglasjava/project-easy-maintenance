# Kanban de pedidos de orçamento do fornecedor — Design

**Data**: 2026-09-24
**Status**: Aprovado por Douglas (via diálogo de brainstorm)
**Épico**: [EPIC-028](../../../roadmap/epics/EPIC-028.md) — Marketplace de Fornecedores
**Task**: [TASK-280](../../../roadmap/tasks/TASK-280.md)

## Contexto

Subprojeto B do pedido de 24/09/2026 (o A foi a página `/para-fornecedores`, TASK-285).

Quando um usuário de organização clica em "Solicitar orçamento" em `/fornecedores`, o backend grava
um `supplier_budget_requests` (`supplierId`, `organizationCode`, `requestedByUserId`, `summary`,
`createdAt`) e o front abre o `wa.me` do fornecedor **no navegador de quem pediu**, com a mensagem
pronta. Nada lê essa tabela de volta. Consequências:

- O fornecedor paga R$ 15,99/mês e não enxerga quantos pedidos recebeu — valor entregue invisível.
- Se quem pediu fechar o WhatsApp sem enviar, o pedido fica gravado e o fornecedor **nunca sabe que
  ele existiu**.

O fornecedor não tem login: acessa `/fornecedores/gerenciar/[token]` (link mágico, token de 64
hex, sem expiração, `SupplierAccessToken`). Só fornecedores auto-cadastrados têm token.

## Decisões de escopo (confirmadas com Douglas)

1. **Abordagem**: aba **"Pedidos"** dentro de `/fornecedores/gerenciar/[token]` (ao lado de "Meus
   dados"). Rejeitadas: página separada (dois links pro fornecedor; pode vir depois sem retrabalho)
   e drag-and-drop (dependência nova, ruim no celular, difícil de tornar acessível).
2. **Dados visíveis ao fornecedor**: nome da organização, bairro, cidade/UF, nome + WhatsApp +
   e-mail de quem pediu, resumo, data e status. Contato completo porque o WhatsApp pode nunca ter
   sido enviado.
3. **LGPD**: o modal "Solicitar orçamento" passa a avisar *"Seu nome, e-mail e WhatsApp serão
   compartilhados com o fornecedor pra ele retornar o contato."* — base clara pro compartilhamento.
4. **Pedidos antigos**: não existem em produção (confirmado por Douglas) — sem tratamento de
   compatibilidade, todo pedido exibe contato.
5. **Colunas**: Novo → Em contato → Orçamento enviado → Fechado / Perdido.
6. **Status é só do fornecedor**: a organização não vê o status marcado.

## Backend (`easy-maintenance-api`)

### Dados
Migration **`V115__add_status_to_supplier_budget_requests.sql`**:
- `status VARCHAR(20) NOT NULL DEFAULT 'NEW'`
- `status_updated_at TIMESTAMP NULL`

Enum `BudgetRequestStatus { NEW, CONTACTED, QUOTED, WON, LOST }` (persistido como string). Sem
tabela de histórico (YAGNI).

### Endpoints (em `SupplierPublicController`, base `/easy-maintenance/api/v1/public/suppliers`)
Mesmo `@RateLimit("supplier-manage")` (30 req/min por IP) e mesma resolução de token do
`SupplierSelfManageService`. Rota já pública (`/public/suppliers/**` liberada em
`SecurityConfig`/`TenantFilter` desde TASK-273/274) — sem `X-Org-Id`.

- **`GET /manage/{token}/budget-requests`** → `List<SupplierBudgetRequestView>`, mais recente
  primeiro. Campos: `id`, `organizationName`, `neighborhood`, `city`, `state`, `requesterName`,
  `requesterEmail`, `requesterPhone` (nullable), `summary`, `createdAt`, `status`,
  `statusUpdatedAt`.
- **`PATCH /manage/{token}/budget-requests/{id}`** body `{ "status": "QUOTED" }` →
  `SupplierBudgetRequestView` atualizado. Qualquer status → qualquer status (desfaz clique errado).
  Grava `status_updated_at = now`.

### Segurança
- Token resolve o fornecedor; token inválido → **404** (mensagem atual "Link inválido ou expirado").
- `PATCH` busca o pedido por `id` **e** `supplierId` do token; pedido de outro fornecedor ou
  inexistente → **404** idêntico (não revela existência — sem IDOR).
- `status` ausente/inválido → **400** `ProblemDetail` (`GlobalExceptionHandler` já trata
  `HttpMessageNotReadableException`; `status` nulo validado com `@NotNull`).
- Nunca expõe `organizationCode`, ids de usuário/organização nem dados de outros fornecedores.

### Performance
1 query de pedidos por `supplierId` (índice `idx_supplier_budget_requests_supplier` já existe, V112) + busca em lote das organizações (`code IN`) e usuários
(`id IN`). Sem N+1.

### Organização/usuário removidos
Se a organização ou o usuário não for encontrado (soft delete), o pedido ainda é listado com
`organizationName`/`requesterName` = `"—"` e contato nulo — não quebra a listagem.

## Frontend (`easy-maintenance-web`)

### `/fornecedores/gerenciar/[token]`
- Abas no topo: **"Pedidos (N)"** e **"Meus dados"** (conteúdo atual, inalterado). Aba inicial:
  "Pedidos" se N ≥ 1, senão "Meus dados". Card de QR Code de pagamento pendente continua aparecendo
  antes de tudo, como hoje.
- **Desktop (≥ 992px)**: 5 colunas lado a lado com contador no título.
- **Mobile**: barra de filtros com scroll horizontal ("Novo 3 · Em contato 1 · …") + lista da
  coluna selecionada.
- **Card do pedido**: organização + bairro/cidade, resumo, "há 2 dias", nome de quem pediu, botões
  **WhatsApp** (`wa.me/55…` com mensagem de retorno; oculto se telefone ausente/inválido) e
  **E-mail** (`mailto:`), menu **"Mover para…"** com os outros 4 status.
- **Mudança de status otimista**: card muda de coluna na hora; se o `PATCH` falhar, volta pro status
  anterior + `toast.error`.
- **Estados**: skeleton ao carregar; erro com "Tentar de novo"; zero pedidos → explicação ("os
  pedidos aparecem aqui quando um gestor da sua cidade solicitar orçamento") + dica de manter as
  categorias atualizadas (link pra aba "Meus dados"); coluna vazia → "Nenhum pedido aqui".

### Lógica pura em `.ts` (testável no Jest `node`)
Agrupamento por status + contadores; rótulos/ordem das colunas; link do WhatsApp (normaliza dígitos,
prefixo 55, trata ausente/inválido); "há X dias"; aplicar/reverter mudança otimista.

### `/fornecedores` (lado da organização)
Texto do aviso LGPD abaixo do campo de resumo no modal "Solicitar orçamento". Sem mudança de
request/comportamento.

## Testes e critérios de aceite

**Backend (JUnit)**
- Lista só pedidos do fornecedor do token, ordem decrescente, com dados de organização e solicitante.
- Solicitante sem telefone → `requesterPhone` nulo, sem erro; organização/usuário ausente → `"—"`.
- Token inválido → 404 (GET e PATCH).
- `PATCH` válido → status e `status_updated_at` atualizados.
- `PATCH` em pedido de outro fornecedor → 404 e **nada alterado** (teste de segurança).
- `status` inválido/nulo → 400.
- `mvn test` sem regressão. A suíte roda em H2 com Flyway desligado, então a V115 é validada à
  parte subindo a API contra o MySQL do Docker local (mesmo padrão da V109).

**Frontend (Jest)**: testes das funções puras acima. `tsc`, lint dos arquivos tocados e `npm run
build` limpos; `npm test` sem falha nova (as 3 de `middleware.test.ts` são pré-existentes).

**QA manual**
- Usuário de organização cria pedido em `/fornecedores` (aviso LGPD visível) → aparece no kanban do
  fornecedor via link mágico, com contato.
- Mover entre as 5 colunas; recarregar a página mantém o status.
- Botões WhatsApp/E-mail abrem com o contato certo.
- 390px sem scroll horizontal (`scrollWidth === clientWidth`); 1366px com 5 colunas.
- `PATCH` com token de um fornecedor num pedido de outro → 404.
- Aba "Meus dados" e pagamento pendente continuam funcionando (regressão).

## Fora de escopo
- Organização ver o status marcado pelo fornecedor.
- Notificar o fornecedor (e-mail/WhatsApp) quando chega pedido novo — candidato natural a próxima
  task, com link direto pra aba "Pedidos".
- Histórico de mudanças de status; métricas agregadas de conversão.
- Drag-and-drop.

## Riscos
- **Médio** — superfície pública nova com dado pessoal: mitigado por escopo por token + 404 uniforme
  + teste de IDOR + aviso LGPD.
- Token sem expiração: quem tiver o link vê os contatos. Já era verdade pros dados do próprio
  fornecedor; agora inclui dados de terceiros. Aceito neste escopo (mesma premissa do link mágico da
  Fase 2); rotação/expiração de token fica como melhoria futura.
