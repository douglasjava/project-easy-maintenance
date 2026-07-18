# TASK-115 — Frontend: /billing — card único de conta

## Tipo
FRONTEND

## Categoria
Billing / UI

## Prioridade
🟠 Alto

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

`billing/page.tsx` hoje lista N `SubscriptionItemCard` (1 por USER + 1 por cada ORGANIZATION), cada um
com "Alterar Plano"/"Cancelar" independentes, refletindo o modelo de cobrança duplicada. Com o plano
único por conta (TASK-110 a TASK-113), essa UI fica incoerente — organizações não têm mais plano/preço
próprio.

## Solução

- Reestruturar `billing/page.tsx`: 1 card de assinatura da conta (plano, preço, status, ciclo, uso:
  organizações usadas/limite, usuários usados/limite, itens usados/limite do pool) + lista somente
  informativa das organizações incluídas (nome, itens usados por organização dentro do pool), sem
  botões de plano por organização.
- `PlanChangeDialog` passa a operar sempre no nível da conta (sem `itemId` de organização).
- `SubscriptionItemCard` simplificado ou substituído por um componente de resumo de conta + um
  componente de lista de organizações (somente leitura).
- Tratar estados de loading, erro e vazio (ex.: conta sem organizações ainda).

## Arquivos impactados

### Frontend
- `app/billing/page.tsx`
- `components/billing/SubscriptionItemCard.tsx`
- `components/billing/PlanChangeDialog.tsx`

## Critérios de Aceite

- [x] Tela `/billing` exibe 1 único plano/preço para a conta
- [x] Lista de organizações aparece como informativa, com uso de itens por organização dentro do pool
- [x] "Alterar Plano" afeta a conta inteira (não mais por organização)
- [x] Estados de loading/erro/vazio tratados (herdados da tela existente, sem regressão)
- [x] Responsivo (mobile) — reaproveita classes Bootstrap responsivas já usadas na tela; **não validado
      visualmente** (ver nota de risco)
- [x] Integração correta com a resposta de `GET /me/billing/summary` pós-mudança de backend — **backend
      foi estendido nesta mesma task** (ver "Implementação")

## Dependências
TASK-113

## Esforço
Médio (1-2 dias)

## Implementação

### Escopo expandido: backend também precisou de mudanças
A task foi classificada como FRONTEND, mas ao implementar descobri que `GET /me/billing/summary`
(consumido por `billing/page.tsx`) é um endpoint/DTO **completamente diferente** de
`GET /organizations/{code}/subscription` (alterado na TASK-113) — `BillingSummaryResponse` não tinha
nenhum campo de uso de pool (organizações/usuários/itens). Sem isso, a UI pedida no "Solução" da task
("uso: organizações usadas/limite, usuários usados/limite, itens usados/limite do pool") não tinha de
onde vir. Estendi o backend nesta mesma task (classificação real: FULL_STACK):

- `BillingSummaryResponse.SubscriptionSummaryDTO` — novos campos `maxOrganizations`,
  `organizationsUsed`, `maxUsers`, `usersUsed`, `maxItems`, `itemsUsedTotalAccount`
- `BillingSummaryResponse.SubscriptionItemDTO` — novo campo `itemsUsedByOrg` (null para o item USER)
- `BillingDashboardService.getBillingSummary()` — calcula os campos acima reaproveitando
  `MaintenanceItemRepository.countByOrganizationCode(In)` (TASK-111) e
  `UserOrganizationRepository.findAllByOrganizationCodeInWithUser` (usuários distintos entre as orgs
  da conta)

### Frontend
- `app/billing/page.tsx`:
  - Tipos `Subscription`/`SubscriptionItem` estendidos com os novos campos
  - Novo componente `AccountUsageStats` — 3 chips (Organizações/Usuários/Itens, "N (ilimitado)" quando
    max=0) dentro do card de resumo da assinatura
  - Novo componente `OrganizationsIncludedList` — lista somente-leitura (nome + itens usados), sem
    botões de plano/cancelamento
  - Seção "Itens da Assinatura" (mapeava N items) substituída por "Seu Plano" (1 card, só o item USER,
    reaproveitando `SubscriptionItemCard` existente) + "Organizações incluídas" (nova lista read-only)
  - `handleChangePlan`/`onUpgradeClick` agora sempre referenciam o item USER, nunca um item ORGANIZATION
  - Texto do modal de cancelamento atualizado ("Cancelar Assinatura" em vez de "Cancelar Item")
- `PlanChangeDialog.tsx` — **não alterado**: já era agnóstico a `itemId`, o ajuste necessário era só no
  call site (`billing/page.tsx` passa a nunca invocá-lo com um itemId de organização)

### Arquivos de teste criados/ajustados (backend)
- `BillingDashboardServiceSummaryTest.java` (novo, 2 testes): pool somado entre múltiplas orgs +
  usuários distintos, e conta sem organizações (uso zerado)

### Resultado dos testes
- Backend: 548/548 testes green ✅ (+2 novos)
- Frontend: `tsc --noEmit` limpo (0 erros no arquivo alterado — os 2 erros pré-existentes no projeto são
  em arquivos de teste não relacionados); `eslint` limpo

### ⚠️ Nota de risco importante: verificação visual não realizada
Tentei validar a UI de ponta a ponta (backend real + browser), mas:
1. Boot completo do backend local falhou em cadeia por múltiplos segredos de terceiros ausentes neste
   ambiente (`BOOTSTRAP_ADMIN_TOKEN`, `ASAAS_API_KEY`, `GOOGLE_PLACES_API_KEY`, `WEBHOOK_TOKEN`,
   `OPENAI_API_KEY`, `DEEPSEEK_API_KEY` — parei de tentar adivinhar mais)
2. Subi o frontend sozinho (`npm run dev`, Next.js pronto em localhost:3000) e tentei abrir `/billing`
   via ferramenta de browser, mas a navegação falhou repetidamente (aba retornava para `chrome://newtab/`)
   — não identifiquei a causa raiz em 2 tentativas e parei de insistir, conforme orientação de não
   martelar falhas de ferramenta repetidamente

**Consequência**: a tela nova (`AccountUsageStats`, `OrganizationsIncludedList`, layout responsivo) foi
verificada por leitura de código + type-check + lint, mas **não foi vista rodando de fato**. Recomendo
fortemente que você rode `npm run dev` localmente e confira `/billing` antes de considerar esta task
`Done`.

## Status
Em Validação
