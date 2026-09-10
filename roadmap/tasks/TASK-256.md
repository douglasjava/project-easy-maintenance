# TASK-256 — BUGFIX: fila de ações do PORTFOLIO navegava com organização ativa errada

## Tipo
BUGFIX

## Categoria
Full-Stack / Multi-tenant

## Prioridade
🔴 Alto — quebra as ações "Concluir"/"Anexar evidência" pra qualquer item que não seja da
organização atualmente ativa no storage

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Sim — confirmar num cenário `PORTFOLIO` real (3+ organizações) que clicar "Concluir"/"Anexar
evidência" num item de uma organização diferente da ativa não gera mais 403/"Item não pertence a
essa organização".

---

## Contexto
Reportado por Douglas testando o cenário `PORTFOLIO` real (`tenant-e-admin@e2e.test`, TASK-254): a
fila de ações mostra itens das 3 organizações corretamente (a query já filtra por
`organization_code IN (:orgs)`, sem passar pelo `TenantFilterAspect`), mas os botões "Concluir" e
"Anexar evidência" levam pra telas single-tenant (`/maintenances/new`, `/items/{id}`) que dependem
da organização ativa salva no `localStorage`/`sessionStorage` (`organizationCode`) pra montar o
header `X-Org-Id` (`apiClient.ts`). Se a organização ativa for diferente da organização real do
item clicado, a API rejeita com "Item não pertence a essa organização".

## Causa raiz
O dashboard em escopo `PORTFOLIO` é uma visão agregada cross-tenant por design (múltiplas
organizações na mesma tela), mas as telas de destino das ações (`/maintenances/new`, `/items/{id}`)
são fundamentalmente single-tenant, como o resto do app. `GET /dashboard/actions` nunca expunha o
`organization_code` real de cada item na resposta (só o nome, pra exibição) — o frontend não tinha
como saber pra qual organização trocar o contexto ativo antes de navegar.

## Escopo
- [x] Backend: `GET /dashboard/actions` passa a retornar `companyCode` (código real da organização
      do item) em cada linha da fila.
- [x] Frontend: antes de navegar pras ações "Concluir"/"Anexar evidência", troca a organização
      ativa no storage pra `action.companyCode` (só quando diferente da atual) — mesmo mecanismo
      que `/select-organization` já usa manualmente, não um jeito novo de contornar o tenant.
- [x] Ação "Adiar" (`POSTPONE`) **não precisava de ajuste** — já autoriza por item
      (`organizationRepository.findAllByUserId`) dentro do próprio endpoint do dashboard, sem
      depender do `X-Org-Id` da requisição (TASK-248).

## Viabilidade Técnica
Baixa complexidade — o dado (`i.organization_code`) já estava disponível na query nativa via join
com `organizations`, só não estava projetado na interface `ActionQueueRow`/no DTO de resposta.

## Dependências
TASK-248 (fila de ações), TASK-251 (UI da fila).

## Riscos
Baixo. A troca de organização ativa é exatamente o que o usuário já faz manualmente em
`/select-organization` — só antecipada aqui porque o item já diz de qual organização ele é.

## Esforço
Pequeno.

## Implementação

### Arquivos modificados
**Backend** (`easy-maintenance-api`, branch `feature/EPIC-030-compliance-dashboard`):
- `ActionQueueRow.java` — `getCompanyCode()`.
- `DashboardActionsRepository.java` — `i.organization_code AS companyCode` projetado nas 4 branches
  do `UNION ALL`.
- `DashboardActionResponse.java` — campo `companyCode`.
- `DashboardActionsService.java` — mapeia `row.getCompanyCode()` na resposta.

**Frontend** (`easy-maintenance-web`, branch `feature/EPIC-030-compliance-dashboard`):
- `useComplianceDashboard.ts` — `DashboardAction.companyCode`.
- `ActionQueue.tsx` — `switchActiveOrganizationIfNeeded(companyCode, companyName)`, chamada no
  `onClick` dos links "Concluir"/"Anexar evidência". Reaproveita o storage
  (`localStorage`/`sessionStorage`, decidido por `isLoggedIn`, mesmo critério de `/select-organization`)
  em vez de inventar um mecanismo novo.

### Verificação
Query nativa revalidada contra o MySQL real do docker (dados da TASK-254 já persistidos) —
`companyCode` retorna corretamente por linha. `mvn test` 985/985 (backend), `npx tsc --noEmit` +
`eslint` limpos e `npm test` sem regressão (107/110, mesmas 3 falhas pré-existentes) no frontend.
Não validado num navegador real nesta sessão (mesmo bloqueio de Firebase) — Douglas está validando
diretamente no ambiente dele, que foi exatamente quem encontrou o problema original.

## Status
🟢 Corrigido nas duas pontas, aguardando confirmação do Douglas no ambiente real dele.
