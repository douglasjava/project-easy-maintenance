# TASK-118 — BUGFIX Full-Stack: /organizations/new ainda pedia plano próprio para a organização

## Tipo
FULL_STACK / BUGFIX

## Categoria
Billing / Onboarding de Organizações

## Prioridade
🔴 Crítico

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

Reportado por Douglas em teste manual local: o fluxo `/organizations/new` (self-service, usuário já
logado adicionando 2ª/3ª organização) ainda tinha um **Step 2 "Configuração de Assinatura"**, com um
seletor de plano (STARTER/BUSINESS/ENTERPRISE) para a organização recém-criada — resquício direto do
modelo antigo de "1 plano por organização", que a EPIC-014 (TASK-110 a 117) eliminou em todo o resto do
sistema, mas não neste fluxo específico (não estava no escopo original de nenhuma das tasks 110-117).

Além do problema de UX, havia um bug latente mais profundo: `OrganizationsService.addOrganizationSubscription()`
sempre usava o `planCode` do request para o item ORGANIZATION, mesmo quando a conta já tinha um plano
diferente — ou seja, tecnicamente ainda era possível uma organização "ter" um plano diferente do plano
real da conta (só não custava nada a mais, por causa da TASK-110, mas o dado ficava inconsistente).

## Solução

> ⚠️ **Revisão pós-implementação**: a primeira versão desta task manteve uma chamada explícita
> `PUT /organizations/{code}/subscription` no frontend (só removeu o seletor de plano visível).
> Douglas observou, ainda testando localmente, que o frontend não deveria precisar chamar nada
> relacionado a "subscription" para criar uma organização — e ele está certo. A versão final move o
> provisionamento do item de billing para dentro do backend, no exato momento em que a organização é
> vinculada à conta (`UsersService.addOrganization`), eliminando a chamada do frontend por completo.

### Backend

**`OrganizationsService.addOrganizationSubscription()`** (usado pelo fluxo administrativo/bootstrap):
- Se a conta (usuário pagador) **já tem assinatura**: ignora o `planCode` do request e herda o plano do
  item USER existente. A organização nunca mais "escolhe" um plano — só herda o da conta.
- Se a conta **não tem assinatura ainda** (bootstrap raro via admin, usuário sem onboarding): usa o
  `planCode` do request, mas agora **também cria o item USER** com esse plano (antes só criava o item
  ORGANIZATION, deixando a subscription sem item USER — o que quebraria `validateItemLimit`/
  `getOrganizationSubscription` das TASK-111/113 para essa organização).

**`UsersService.addOrganization(userId, orgCode)`** (usado por `POST /organizations/{orgCode}/users/{userId}`,
o endpoint real de vincular uma organização à conta de um usuário — self-service e admin):
- Depois de vincular (`saveUserOrganization`), provisiona automaticamente o item `ORGANIZATION` na
  `BillingSubscription` do usuário, herdando o plano do item USER — **sem precisar de nenhuma chamada
  adicional do frontend**.
- Idempotente: se o item já existir para aquele `orgCode` (ex.: religação após remoção), não duplica.
- Defensivo: se por algum motivo não existir item USER (não deveria acontecer — `validateOrgLimit`,
  chamado antes, já barra esse caso com `RuleException`), loga um aviso e segue sem quebrar a
  vinculação da organização.
- Confirmado (por leitura de código) que isso **não conflita** com o fluxo de criação de organização via
  admin (`private/organizations/new`), que usa endpoints totalmente diferentes
  (`POST /private/admin/organizations` + `PUT .../subscription`) e nunca chama este método.

### Frontend (`app/organizations/new/page.tsx`)
- Removido o Step 2 "Configuração de Assinatura" (seletor de plano) por completo.
- Fluxo agora é um único passo: cria a empresa → vincula o usuário logado
  (`POST /organizations/{code}/users/{userId}`) → **backend provisiona o billing automaticamente** →
  frontend só redireciona. Nenhuma chamada relacionada a "subscription" resta no frontend.
- Indicador de progresso simplificado de 3 para 2 estágios (Faturamento ✓ → Empresa).

## Arquivos impactados

### Backend
- `org_users/application/service/OrganizationsService.java` — `addOrganizationSubscription()`
- `org_users/application/service/UsersService.java` — `addOrganization()` + novo método privado
  `provisionOrganizationBilling()`

### Frontend
- `app/organizations/new/page.tsx` — reescrito para fluxo de passo único, sem chamada de subscription

## Critérios de Aceite

- [x] Criar uma 2ª/3ª organização não exibe nenhum seletor de plano para o usuário
- [x] Criar uma 2ª/3ª organização não faz **nenhuma** chamada HTTP relacionada a "subscription" a
      partir do frontend — o billing é provisionado internamente pelo backend
- [x] A organização criada herda o plano real da conta, mesmo que o backend receba um `planCode`
      diferente na requisição (caminho `addOrganizationSubscription`, ainda usado pelo admin)
- [x] Bootstrap de usuário sem onboarding (admin) continua funcionando e agora também cria o item USER
      da subscription (antes só criava o item ORGANIZATION)
- [x] Provisionamento de billing em `addOrganization` é idempotente (não duplica item se já existir)
- [x] Testes unitários cobrindo todos os cenários acima

## Dependências
TASK-110, TASK-111, TASK-113 (reaproveita toda a infraestrutura já construída)

## Esforço
Baixo-médio (encontrado e corrigido em ~1h durante teste manual; revisado uma 2ª vez após feedback do
Douglas de que a chamada de subscription não deveria existir no frontend de forma alguma)

## Risco de não fazer
Usuário continua vendo uma tela de "escolha de plano" para organizações que não faz mais sentido no
modelo atual — confuso e contraditório com o resto do produto (tela `/billing` já consolidada na
TASK-115). Risco técnico adicional: inconsistência de dados (organização com plano diferente do real
da conta) se alguém escolhesse um plano diferente nesse seletor.

## Status
Em Validação
