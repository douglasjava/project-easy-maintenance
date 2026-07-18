# TASK-121 — BUGFIX Full-Stack: botão "+ Novo Item" não bloqueava proativamente com pool esgotado

## Tipo
FULL_STACK / BUGFIX

## Categoria
Billing / QA (achado durante execução da TASK-117)

## Prioridade
🔴 Crítico

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

Reportado por Douglas durante a validação manual da TASK-117 (QA E2E): ao baixar o limite de itens da
conta para 20 e atingir 20/20 (via `/billing`), o backend corretamente bloqueava a criação de um novo
item (`400 rules-invalid`, "Limite de itens da conta atingido (20/20) somando todas as suas
organizações"). Porém, o botão **"+ Novo Item"** na tela `/items` continuava habilitado — o usuário só
descobria o bloqueio depois de preencher o formulário e tentar salvar.

### Causa raiz

`GET /me/access-context` (`FeatureAccessService.buildOrganizationAccess()`) calcula
`permissions.canCreateItem` comparando o uso de itens **só da organização atual**
(`maintenanceItemRepository.countByOrganizationCode(org.getCode())`) contra `maxItems` — o modelo
**antigo** de teto por organização, anterior à TASK-111. Com o pool compartilhado entre organizações
(TASK-111), uma organização isolada pode estar bem abaixo do seu "teto individual" (ex.: Brain com 4
itens) mesmo com o pool real da conta esgotado (ex.: Sofia 3 + Ricardo 2 + Brain 4 + outros = 20/20) —
então `canCreateItem` continuava `true` para a organização ativa, e o botão no frontend (que confia
nesse flag) continuava habilitado.

## Solução

### Backend
- `FeatureAccessService.buildOrganizationAccess()`: `itemLimitReached` agora soma itens de **todas** as
  organizações da mesma `BillingSubscription` (conta), via novo método privado
  `countAccountWideItems()` — mesmo padrão de `MaintenanceItemService.validateItemLimit` (TASK-111) e
  usando `TenantContext.runCrossOrg()` (TASK-120) para a soma cross-org funcionar corretamente.
- Como a soma agora independe do `TenantContext` da requisição, o cálculo passou a rodar para
  **qualquer** organização da lista (não só a organização ativa da sessão) — antes só era computado
  quando `TenantContext` batia com a org sendo processada, por causa do bug da TASK-120.

### Frontend (`app/items/page.tsx`)
- Passou a buscar `GET /me/billing/summary` (mesmos campos `itemsUsedTotalAccount`/`maxItems` da
  TASK-115/120) para calcular `atItemLimit` de forma independente no cliente também (defesa em
  profundidade, mesmo padrão já usado em `organizations/page.tsx`/`users/new/page.tsx`).
- Botão "+ Novo Item" trocou de `mode="hide"` para o padrão `disable` — agora fica visível porém
  desabilitado com tooltip explicando o motivo (limite do plano ou falta de acesso), igual às telas de
  empresas/usuários.
- Adicionado `<UsageMeter>` (componente já existente, só não estava sendo usado nesta tela) mostrando
  "Itens (conta): X/Y" ao lado do botão.

## Arquivos impactados

### Backend
- `infrastructure/access/application/service/FeatureAccessService.java`

### Frontend
- `app/items/page.tsx`

## Critérios de Aceite

- [x] `canCreateItem` no `/me/access-context` reflete o pool real da conta, não a contagem isolada da
      organização
- [x] Botão "+ Novo Item" fica desabilitado (com mensagem clara) quando o pool da conta está esgotado,
      mesmo que a organização ativa tenha poucos itens
- [x] `<UsageMeter>` mostra uso real da conta ao lado do botão
- [x] Testes unitários cobrindo o novo cálculo de `itemLimitReached` (pool esgotado bloqueia mesmo com
      org isolada abaixo do limite; pool com espaço permite; maxItems=0 é ilimitado)
- [x] 561/561 testes backend green

## Dependências
TASK-111, TASK-115, TASK-120

## Esforço
Médio (investigação + backend + frontend em ~1h30)

## Risco de não fazer
Usuário só descobre que atingiu o limite depois de preencher todo o formulário de criação de item —
fricção desnecessária, e a mensagem de erro só aparece após a tentativa de submit.

## Status
Em Validação — aguardando confirmação visual do Douglas (mesma ressalva de verificação visual das
tasks anteriores da EPIC-014)
