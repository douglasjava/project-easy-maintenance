# TASK-116 — Frontend: painel admin billing/subscriptions — mesma consolidação

## Tipo
FRONTEND

## Categoria
Billing / Admin

## Prioridade
🟡 Médio

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

`private/admin/billing/subscriptions/` trata os itens (USER/ORGANIZATION) de forma unificada, com
coluna `sourceType` — reflete o modelo antigo de N itens cobráveis por conta.

## Solução

- Atualizar listagem/telas admin para refletir 1 plano por conta + organizações incluídas (sem
  `sourceType=ORGANIZATION` cobrável), mantendo visibilidade operacional (quantas organizações, quantos
  itens usados no pool) para suporte/administração.
- Remover ações administrativas de troca de plano/cancelamento no nível de organização isolada (TASK-112
  já remove o suporte no backend).

## Arquivos impactados

### Frontend
- `app/private/admin/billing/` (`BillingAdminLayout.tsx`, `subscriptions/`, `plans/`)

## Critérios de Aceite

- [x] Painel admin exibe 1 assinatura por conta com lista de organizações incluídas — parcial (ver nota
      de escopo abaixo: listagem continua flat/paginada por item, não agrupada visualmente por conta)
- [x] Suporte consegue ver uso do pool de itens por conta e por organização
- [x] Nenhuma ação administrativa (cancelamento, troca de plano) restante no nível de organização
      isolada

## Dependências
TASK-113, TASK-115

## Esforço
Baixo-médio (1 dia)

## Implementação

### Escopo expandido: backend também precisou de mudanças (mesmo padrão da TASK-115)
`GET /private/admin/billing/subscriptions` (`BillingSubscriptionService.listSubscriptions()`) não tinha
`sourceId` (para identificar QUAL organização é cada linha) nem nenhum campo de uso de pool. Estendi:

- `BillingAdminDTO.SubscriptionResponse` — novos campos `sourceId`, `itemsUsedByOrg`,
  `itemsUsedTotalAccount`, `maxItems`
- `BillingSubscriptionService.listSubscriptions()` — calcula os campos acima por linha, buscando os
  itens irmãos da mesma `BillingSubscription` (item USER para `maxItems`, itens ORGANIZATION para
  `itemsUsedTotalAccount`). Custo: +1-2 queries por linha (aceitável para uma tela admin de baixo
  volume) — mesmo padrão de trade-off já usado na TASK-115

### Frontend (`app/private/admin/billing/subscriptions/page.tsx`)
- Tipo `Subscription` atualizado (`sourceId`, `itemsUsedByOrg`, `itemsUsedTotalAccount`, `maxItems`;
  removidos `organizationCode`/`organizationName`, que nunca foram populados pelo backend — dead code)
- `actionBtns()`: linhas `ORGANIZATION` não têm mais Upgrade/Downgrade/Cancelar — mostram "Incluída na
  conta". Ações continuam só para linhas `USER`
- `typeLabel()`: linhas de organização mostram `sourceId` junto do label (antes era impossível
  distinguir duas organizações da mesma conta na tabela)
- `valueCell()`: linhas `ORGANIZATION` não mostram mais `totalCents` (sempre 0, e mostrar o valor da
  assinatura ali sugeria cobrança duplicada) — mostram itens usados na org. Linha `USER` mostra o valor
  real da conta + indicador do pool (`X/Y itens (conta)`)

### Nota de escopo: agrupamento visual não implementado
O critério "exibe 1 assinatura por conta com lista de organizações incluídas" foi atendido
**parcialmente**: a tabela continua paginada por item (herda a paginação de
`BillingSubscriptionItemRepository`, que pagina sobre `BillingSubscriptionItem`, não sobre
`BillingSubscription`) — não agrupei visualmente conta+orgs porque isso exigiria mudar a paginação de
nível de item para nível de conta (reescrever a query/Specification), escopo real bem maior que o
"Baixo-médio (1 dia)" desta task. Como a maioria das contas hoje tem poucas organizações, o efeito
prático é pequeno, mas registro como gap conhecido caso o suporte peça uma visão agrupada de verdade.

### Fora do escopo (decisão consciente)
`app/private/admin/billing/page.tsx` (dashboard overview) já tem uma estrutura `payers[].organizations[]`
agrupada por conta — não tem ações de plano/cancelamento por organização, então já atende ao espírito
da consolidação sem precisar de mudança. Não toquei nele.

### Resultado dos testes
- Backend: 550/550 testes green ✅ (+2 novos: `listSubscriptions_exposesPoolUsage_forUserAndOrganizationRows`,
  `listSubscriptions_zeroesItemsUsedTotalAccount_whenAccountHasNoOrganizations`)
- Frontend: `tsc --noEmit` e `eslint` limpos (mesmo warning pré-existente de `useEffect` não relacionado)

### ⚠️ Mesma limitação de verificação visual da TASK-115
Não consegui validar esta tela rodando de verdade, pelos mesmos motivos documentados na TASK-115 (boot
completo do backend bloqueado por segredos de terceiros ausentes; navegação via browser falhando). A
implementação foi verificada por leitura de código + type-check + lint, não por uso real.

## Status
Em Validação
