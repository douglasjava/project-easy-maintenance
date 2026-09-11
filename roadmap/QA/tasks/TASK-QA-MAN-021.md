# TASK-QA-MAN-021 — QA Manual: EPIC-030 (Compliance Dashboard)

## Tipo
QA Manual

## Categoria
Full-Stack / Redesenho de tela existente (dashboard principal, `/`)

## Prioridade
🔴 Alto — é a home autenticada do produto inteiro

## Tasks cobertas
[TASK-246](../../tasks/TASK-246.md) (índice + summary) / [TASK-247](../../tasks/TASK-247.md)
(series) / [TASK-248](../../tasks/TASK-248.md) (fila de ações + adiar) /
[TASK-249](../../tasks/TASK-249.md) (shell) / [TASK-250](../../tasks/TASK-250.md) (hero + KPIs) /
[TASK-251](../../tasks/TASK-251.md) (fila de ações UI) / [TASK-252](../../tasks/TASK-252.md)
(gráficos) / [TASK-253](../../tasks/TASK-253.md) (ONBOARDING) / [TASK-254](../../tasks/TASK-254.md)
(E2E) — [EPIC-030](../../epics/EPIC-030.md)

---

## Descrição

Valida a reescrita completa do dashboard principal (`src/app/page.tsx`, rota `/`): 3 estados de
conta calculados no backend (`ONBOARDING`/`OPERATING`/`PORTFOLIO`), índice de conformidade
calculado em SQL, fila de ações priorizada com adiamento, 4 gráficos, e o job diário de snapshot
que alimenta o histórico. Toda a implementação está na branch
`feature/EPIC-030-compliance-dashboard` (nos dois repos, `easy-maintenance-api` e
`easy-maintenance-web`), sem PR aberta ainda — igual ao padrão do EPIC-028
([TASK-QA-MAN-020](TASK-QA-MAN-020.md)), esperando esta aprovação antes de abrir.

**Nada foi validado contra um ambiente rodando de verdade nesta sessão** (mesmo bloqueio de sempre:
`PushNotificationProvider` exige `FirebaseMessaging` real, sem `FIREBASE_SERVICE_ACCOUNT_JSON`
válida aqui). O que foi validado sem subir a aplicação:
- Backend: `mvn clean test` **984/984**, sem regressão (baseline era 949 antes do épico). A fórmula
  do índice (`ComplianceMetricsRepository`) e a query da fila de ações
  (`DashboardActionsRepository`) foram validadas com H2 **e** direto contra o MySQL real do seu
  docker local (aplicando a migration V110 temporariamente e revertendo depois) — inclusive com
  dados reais de uma das suas organizações (17 elegíveis/11 conformes, conferido à mão).
- Frontend: `npm run build`/`eslint` limpos; `npm test` sem regressão nova (107/110 — as 3 falhas
  de `middleware.test.ts` são pré-existentes).
- E2E: seed sintético (3 tenants, `easy-maintenance-e2e/seed/e2e-seed.sql` seção 10) + primeiro
  spec Playwright do projeto `ui` escritos, com `npx tsc --noEmit` limpo — mas o Playwright em si
  **não rodou** (sem MySQL de E2E ativo na porta 3307). Ver [TASK-254](../../tasks/TASK-254.md).

**Gaps reais, não escondidos** (documentados task a task, resumo aqui pra você não precisar abrir
todas):
1. Painel "Laudos e documentos" (TASK-251) **não foi implementado** — falta um `GET` de leitura
   pra `ItemDocument` que não existe no controller hoje. `ItemDocument`/`item_documents` só tem a
   entidade + migration, sem CRUD.
2. Filtro de período/categoria (protótipo original) **não existe** — só o filtro de empresa é real.
3. "Exportar PDF" foi removido da barra de filtro antes do merge (TASK-257) — não aparece mais na
   tela nesta v1, nem desabilitado. Volta junto com o endpoint real, em épico separado.
4. Sparklines de 6 meses / `previousComplianceIndex` só aparecem depois que o
   `ComplianceSnapshotJob` (novo, roda `02:45` por padrão) tiver acumulado histórico — numa conta
   nova ou logo após o deploy, aparecem como "sem histórico ainda" / zero-fill, não inventado.
5. `GET /dashboard` (endpoint antigo) continua no ar no backend, mas nenhuma tela do app o consome
   mais a partir desta task — decisão de removê-lo de vez ficou pra depois.

---

## Pré-condições

- Checkout de `feature/EPIC-030-compliance-dashboard` nos dois repos, API e frontend rodando local
  (perfil `local`, com suas credenciais reais — inclusive Firebase, que bloqueou o boot nesta
  sessão).
- Migration `V110__create_item_documents_and_compliance_snapshots.sql` aplica sozinha no boot
  (Flyway) — já validada contra o MySQL real do seu docker nesta sessão, revertida depois pra não
  conflitar com o Flyway do boot real.
- Pra C2/C3/C4 (os 3 estados de conta) você pode usar suas organizações de teste de sempre
  **ajustando a quantidade de itens/manutenções conforme cada cenário pede**, ou — atalho mais
  rápido — rodar o bloco "seção 10" de `easy-maintenance-e2e/seed/e2e-seed.sql` direto no seu MySQL
  de dev (schema idêntico, já validado nesta sessão): ele cria 5 organizações/3 usuários prontos
  pros 3 estados (`tenant-c-admin@e2e.test`/`tenant-d-admin@e2e.test`/`tenant-e-admin@e2e.test`,
  todos com a senha `E2ePassA1!`). Ver o cabeçalho dessa seção no arquivo pra saber exatamente o
  que cada organização tem.

⚠️ Se criar dado novo manualmente (fora do seed acima), prefixe com `QA-EPIC030-*`. **Não rodar
contra staging/produção.**

---

## Cenários de Teste

### C1 — Suítes automatizadas, sem regressão

| Passo | Ação                                                                                     | Resultado esperado                                                                                           |
|-------|--------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| 1     | `mvn clean test` na branch `feature/EPIC-030-compliance-dashboard` (`easy-maintenance-api`) | **984/984**                                                                                                |
| 2     | `npm run build` e `npm test` na branch equivalente (`easy-maintenance-web`)                | Build limpo; jest sem regressão nova (3 falhas em `middleware.test.ts` pré-existentes, não relacionadas)  |
| 3     | `npx tsc --noEmit` em `easy-maintenance-e2e` (branch equivalente)                          | Limpo, incluindo o spec novo de `tests/frontend/compliance-dashboard.spec.ts`                             |

Já executado e confirmado durante a implementação (sem subir a API completa).

---

### C2 — Estado ONBOARDING (conta nova, < 5 itens ou 0 manutenções)

| Passo | Ação                                                                              | Resultado esperado                                                                                                  |
|-------|-------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| 1     | Logar com uma conta com 2 itens cadastrados e 0 manutenções registradas (ou `tenant-c-admin@e2e.test` do seed) | `/` mostra o card "Primeiros passos" (checklist de 4 passos), **nenhum** anel de conformidade, KPI ou fila de ações na tela |
| 2     | Conferir os passos do checklist                                                    | "Empresa cadastrada" já ✓; "Cadastre seus itens" ✓ (2 > 0); "Atinja 5 itens cadastrados" **não** ✓ (2 < 5); "Registre sua primeira manutenção" sempre não ✓ nesta v1 |
| 3     | Clicar "Gerar plano automático"                                                    | Leva pro fluxo de IA existente (`/ai-onboarding`)                                                                |
| 4     | Cadastrar itens até passar de 5 e registrar pelo menos 1 manutenção, recarregar `/` | Estado muda pra `OPERATING`/`PORTFOLIO` (deixa de mostrar o checklist)                                          |

---

### C3 — Estado OPERATING (uma empresa, com histórico real)

| Passo | Ação                                                                          | Resultado esperado                                                                                                               |
|-------|-----------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|
| 1     | Logar com uma conta de organização única, ≥ 5 itens e ≥ 1 manutenção (ou `tenant-d-admin@e2e.test` do seed — deve mostrar índice **60%**) | Hero escuro com anel do índice de conformidade, meta (95%), 3 linhas (em dia/vencido/sem evidência), 3 tiles de KPI (vencidos/vencendo em 30 dias/custo do mês) |
| 2     | Passar o mouse/inspecionar o `aria-label` do anel                                | `"Índice de conformidade: NN%"` — confirma acessibilidade                                                                       |
| 3     | Conferir a fila de ações abaixo                                                  | Itens vencidos/vencendo/sem evidência/documento vencido aparecem com o motivo certo em português, mais atrasado primeiro       |
| 4     | Conferir que o seletor de empresa **não aparece** no topo                        | Correto — só aparece com 2+ empresas acessíveis                                                                                 |

---

### C4 — Estado PORTFOLIO (múltiplas empresas)

| Passo | Ação                                                                                                  | Resultado esperado                                                                                            |
|-------|------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| 1     | Logar com uma conta com acesso a 3+ organizações (ou `tenant-e-admin@e2e.test` do seed — deve mostrar índice **83%**) | Seletor "Todas as unidades (N)" aparece no topo; índice é a soma eligible/compliant de todas as unidades, **não** a média dos índices individuais |
| 2     | Selecionar uma unidade específica no seletor                                                         | URL vira `/?company=<code>`; hero/KPIs/fila recalculam só pra essa unidade                                 |
| 3     | Voltar pra "Todas as unidades"                                                                       | URL perde o `?company=`; volta a mostrar o agregado                                                        |
| 4     | Rolar até o gráfico de ranking de unidades                                                           | Só aparece em `PORTFOLIO`; pior unidade (menor índice) aparece primeiro                                    |
| 5     | Usar o botão voltar/avançar do navegador depois de trocar de unidade algumas vezes                   | Funciona — filtro é 100% via URL, sem estado escondido no cliente                                          |

---

### C5 — Fila de ações: adiar (com validação de motivo obrigatório)

| Passo | Ação                                                                                     | Resultado esperado                                                                          |
|-------|----------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| 1     | Na fila de ações (C3 ou C4), clicar "Adiar" num item vencido                               | Modal abre pedindo nova data e motivo                                                      |
| 2     | Preencher só a data, deixar o motivo vazio, tentar confirmar                                | Botão "Confirmar" fica desabilitado — não dá nem pra clicar                                |
| 3     | Preencher o motivo, confirmar                                                              | Toast de sucesso, modal fecha, item some da fila, índice de conformidade sobe (refetch automático do summary/series) |
| 4     | Conferir o log de auditoria do item (`AuditLog` / tela de histórico do item, se existir)    | Ação `POSTPONE` registrada com data antiga/nova e o motivo digitado                        |

---

### C6 — Fila de ações: completar e anexar evidência

| Passo | Ação                                                                          | Resultado esperado                                                                 |
|-------|-------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| 1     | Clicar "Concluir" num item com ação `COMPLETE` disponível                    | Leva pra `/maintenances/new?itemId=<id>&origin=dashboard` com o item pré-selecionado |
| 2     | Registrar a manutenção normalmente, voltar pro dashboard                     | Item some da fila (ou muda de motivo), índice recalcula                             |
| 3     | Clicar "Anexar evidência" num item com esse motivo                           | Leva pro detalhe do item (`/items/{id}`) — **não** existe uma tela dedicada de anexar evidência numa manutenção já concluída, esse é o destino mais próximo real (gap conhecido, ver Descrição) |

---

### C7 — Gráficos

| Passo | Ação                                                                          | Resultado esperado                                                                                     |
|-------|--------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| 1     | Conferir "Próximos 90 dias" (13 barras semanais)                             | Semana atual destacada com contorno; severidade por cor (crítico/atenção/agendado)                  |
| 2     | Conferir "Planejado × Realizado" (12 meses)                                  | Mês em curso com opacidade reduzida + "mês em curso"; **atenção**: `planned` pode ficar quase zero — `Maintenance.nextDueAt` é majoritariamente NULL nos dados reais hoje (achado da TASK-247, não é bug desta tela) |
| 3     | Conferir "Custo do mês por categoria"                                        | Barras horizontais + total; categorias vêm da taxonomia fixa (Incêndio/Hidráulica/Climatização/etc.) |
| 4     | Redimensionar a janela até ficar estreita (mobile)                           | Cada gráfico rola horizontalmente **dentro do próprio card** — o body da página nunca rola na horizontal |

---

### C8 — Job de snapshot diário

| Passo | Ação                                                                                                    | Resultado esperado                                                                          |
|-------|---------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| 1     | `SELECT * FROM compliance_snapshots WHERE organization_code = '<sua org>' ORDER BY snapshot_date DESC`  | Vazio no primeiro dia — normal, o job roda `02:45` (config `compliance.snapshot.cron`)      |
| 2     | Disparar o job manualmente (endpoint de admin de jobs, se existir, ou aguardar a próxima janela)        | Uma linha nova por organização, idempotente se rodar de novo no mesmo dia (não duplica)     |
| 3     | Com pelo menos 1 snapshot de "ontem", recarregar `/`                                                    | `previousComplianceIndex`/delta em p.p. no hero passam a aparecer (deixam de ser "sem histórico ainda") |

---

### C9 — Regressão: banners e estados de conta existentes

| Passo | Ação                                                                                     | Resultado esperado                                                          |
|-------|--------------------------------------------------------------------------------------------|------------------------------------------------------------------------|
| 1     | Conta em trial ativo                                                                     | `TrialBanner` continua aparecendo normalmente no topo                    |
| 2     | Conta com trial expirado / bloqueada                                                     | `DashboardBlockedBanner` continua aparecendo, dashboard continua acessível (whitelisted) |
| 3     | Conta com pagamento em atraso                                                            | `PastDueBanner` continua aparecendo                                      |
| 4     | Usuário sem nenhuma organização                                                          | `DashboardNoOrganizationState` continua aparecendo (não quebrou com a reescrita) |
| 5     | Forçar um 403 do backend (ex.: `?company=<código de org de outro usuário>`)              | `DashboardAccessDeniedState` aparece, sem vazar dado de outra organização (mensagem genérica, `NotFoundException`) |

---

## Limpeza (dados sintéticos do seed, se usados)

```sql
DELETE FROM maintenance_attachments WHERE maintenance_id IN (
  SELECT m.id FROM maintenances m JOIN maintenance_items i ON i.id = m.item_id
  WHERE i.organization_code IN (
    'cccccccc-cccc-cccc-cccc-cccccccccccc','dddddddd-dddd-dddd-dddd-dddddddddddd',
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee','ffffffff-ffff-ffff-ffff-ffffffffffff',
    '11111111-1111-1111-1111-111111111111'));
DELETE FROM maintenances WHERE item_id IN (
  SELECT id FROM maintenance_items WHERE organization_code IN (
    'cccccccc-cccc-cccc-cccc-cccccccccccc','dddddddd-dddd-dddd-dddd-dddddddddddd',
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee','ffffffff-ffff-ffff-ffff-ffffffffffff',
    '11111111-1111-1111-1111-111111111111'));
DELETE FROM maintenance_items WHERE organization_code IN (
  'cccccccc-cccc-cccc-cccc-cccccccccccc','dddddddd-dddd-dddd-dddd-dddddddddddd',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee','ffffffff-ffff-ffff-ffff-ffffffffffff',
  '11111111-1111-1111-1111-111111111111');
DELETE FROM users WHERE email IN ('tenant-c-admin@e2e.test','tenant-d-admin@e2e.test','tenant-e-admin@e2e.test');
DELETE FROM organizations WHERE code IN (
  'cccccccc-cccc-cccc-cccc-cccccccccccc','dddddddd-dddd-dddd-dddd-dddddddddddd',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee','ffffffff-ffff-ffff-ffff-ffffffffffff',
  '11111111-1111-1111-1111-111111111111');
```
(Billing accounts/subscriptions/items dessas orgs caem em cascata ou ficam órfãos inofensivos —
confira sua FK antes de rodar se estiver num banco que você não pode recriar do zero.)

---

## Critérios de Aceite da Suíte

- [X] C1: suítes automatizadas sem regressão (backend 984/984 + frontend build/test + e2e typecheck)
- [X] C2: estado ONBOARDING renderiza corretamente, sem gráfico/índice fabricado
- [X] C3: estado OPERATING — hero, KPIs, fila de ações, `aria-label` do anel
- [X] C4: estado PORTFOLIO — seletor de unidades, índice agregado (soma, não média), filtro via URL
- [X] C5: adiar sem motivo é bloqueado no cliente; adiar com motivo funciona e recalcula o índice
- [X] C6: completar e anexar evidência levam pros destinos certos
- [X] C7: os 4 gráficos renderizam com dado real, sem overflow no body
- [X] C8: job de snapshot roda, é idempotente, alimenta o histórico
- [X] C9: banners e estados de conta existentes não regrediram

## Status
✅ Aprovado por Douglas (11/09/2026) — testado contra o ambiente real dele (com
Firebase/credenciais verdadeiras). Achados durante a execução, todos corrigidos na própria branch
antes do merge: [TASK-255](../../tasks/TASK-255.md) (cache `norms` faltando nos profiles),
[TASK-256](../../tasks/TASK-256.md) (fila de ações do PORTFOLIO navegava com organização ativa
errada), [TASK-257](../../tasks/TASK-257.md) (botão "Exportar PDF" desabilitado removido). PRs
`api`/`web` pra `staging` abertas e mergeadas ([api#90](https://github.com/douglasjava/easy-maintenance-api/pull/90),
[web#77](https://github.com/douglasjava/easy-maintenance-web/pull/77)), promovidas pra `main`
([api#91](https://github.com/douglasjava/easy-maintenance-api/pull/91),
[web#78](https://github.com/douglasjava/easy-maintenance-web/pull/78)) — EPIC-030 concluído.
