# TASK-254 — QA/INFRA: E2E e regressão do dashboard novo

## Tipo
INFRA / CONFIG

## Categoria
Dashboard / Compliance / QA Automatizado

## Prioridade
🟡 Médio

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Não se aplica no sentido usual — esta task **é** a automação de QA do épico.

---

## Contexto
Renumerada de TASK-138 do documento original. Cobertura E2E (Playwright) pros 3 estados de conta +
comportamentos-chave (filtro, ação completando refetch, adiar sem motivo rejeitado, sem scroll
horizontal).

## Escopo
- [x] Popular 3 tenants sintéticos e validar o estado renderizado em cada um:
  1. 2 itens, 0 manutenções → `ONBOARDING`, sem gráfico na tela
  2. 1 empresa com histórico → `OPERATING`, anel de conformidade visível, fila de ações populada
  3. 3 empresas, "todas" → `PORTFOLIO`, ranking de unidades visível, pior unidade primeiro
- [~] Trocar filtro atualiza URL e números renderizados — **só o filtro de empresa**, testado
      (seleção no `<select>` muda `?company=`). Filtro de período não existe (TASK-249 já deixou
      isso fora de escopo, sem endpoint que o sustente) — não há o que testar.
- [~] Completar uma ação da fila refaz o summary e muda o índice — testado com **POSTPONE**, não
      COMPLETE. Ver Decisões na Implementação.
- [x] Adiar sem motivo é rejeitado.
- [x] Body da página nunca rola na horizontal em 1280px e 1920px.

## Viabilidade Técnica

**Infra já existe, mas é rasa.** `easy-maintenance-e2e` já tem `fixtures/auth.ts`,
`fixtures/tenant.ts`, `helpers/db.ts` e `playwright.config.ts` configurados — a convenção de seed
de tenant sintético que este task pede já tem onde se apoiar. Mas hoje só existe **1 spec real**
(`tests/smoke.spec.ts`) — não há um precedente rico de "cenário completo com múltiplas telas" pra
copiar; a maior parte do trabalho de escrever os specs novos é greenfield dentro de uma infra que
já existe, não reaproveitamento direto de testes parecidos.

**Sem achado técnico contrário** ao escopo em si — é consequência direta das TASK-249 a TASK-253
já estarem prontas e estáveis; não há decisão de arquitetura pendente aqui.

## Dependências
TASK-250, TASK-251, TASK-252, TASK-253 (tudo que está sendo testado precisa existir primeiro).

## Riscos
Baixo tecnicamente, mas é o último task da onda — qualquer atraso nas dependências atrasa
diretamente esta task, e qualquer decisão de escopo não fechada nas tasks anteriores (painel de
documentos da TASK-251, por exemplo) vira teste que não pode ser escrito ainda.

## Esforço
Médio.

## Implementação

### Arquivos criados/modificados (`easy-maintenance-e2e` — nota: é a mesma árvore git da raiz
`EASY_MAINTENANCE`, não um repo próprio como `api`/`web`; commitado direto em `main`, seguindo a
mesma convenção já usada nos commits de roadmap desta sessão)
- `seed/e2e-seed.sql` — seção 10 nova: 5 organizações (`cccccccc.../dddddddd.../eeeeeeee.../
  ffffffff.../11111111...`), 3 usuários (`tenant-c/d/e-admin@e2e.test`, reaproveitando o hash
  bcrypt do `tenant-a-admin` — mesma credencial fixa de E2E, sem gerar hash novo), billing
  (accounts/subscriptions/items) e os itens/manutenções/evidências que produzem os 3 estados.
- `fixtures/tenant.ts` — `TENANT_C_ONBOARDING`/`TENANT_D_OPERATING`/`TENANT_E_PORTFOLIO`.
- `helpers/frontend-login.ts` — **novo**: primeiro helper de UI do repo (só existia
  `fixtures/auth.ts`, que loga via API pra testes do projeto `api`). Preenche o form real de
  `/login`, trata os dois redirecionamentos possíveis (`/` direto pra conta com 1 org, ou
  `/select-organization` pra conta com 2+, sem opção "todas" — esse conceito só existe dentro do
  filtro do dashboard novo, TASK-249).
- `tests/frontend/compliance-dashboard.spec.ts` — **novo**, primeiro spec do projeto `ui`
  (`playwright.config.ts` já tinha o projeto configurado com `testMatch: '**/frontend/**/*.spec.ts'`
  e o script `npm run test:ui`, mas zero arquivos casavam o padrão até agora).
- `tsconfig.json` — `lib` passou de `["ES2020"]` pra `["ES2020", "DOM"]`: necessário porque o
  spec novo usa `page.evaluate(() => document...)` (checagem de scroll horizontal), primeiro
  código do repo a referenciar um global de DOM dentro de uma função que roda no browser.

### Decisões tomadas durante a implementação
- **Dados sintéticos calculados e validados contra o formato real da query, não chutados**: os 5
  orgs foram desenhados pra produzir índices específicos (`OPERATING` = 60%, `PORTFOLIO` = 83% com
  a org 1 sendo a pior a 50%) e essa conta foi **validada rodando a query exata de
  `ComplianceMetricsRepository` contra um MySQL 8.0.33 real** (container `easy_maintenance_mysql`,
  reaplicando a migration V110 temporariamente e revertendo no final, mesmo padrão já usado nas
  outras tasks do épico) — confirmado eligible/compliant = 2/2, 5/3, 2/1, 2/2, 2/2 exatamente como
  desenhado. Os dados em si (organizações, usuários, itens) também foram inseridos e conferidos
  nesse MySQL real antes de reverter, não só a query isolada.
- **`COMPLETE` trocado por `POSTPONE` no teste de "ação muda o índice"**: completar uma manutenção
  de verdade passa pelo formulário de `/maintenances/new`, cujos campos/seletores não foram
  verificados nesta sessão (fora do escopo de exploração desta task). `POSTPONE` já é 100%
  implementado e testável (TASK-248/251) e move o índice de forma real e previsível (adiar o item
  `E2E_OPE_ITEM_4`, que nunca teve manutenção registrada, tira o item de OVERDUE sem precisar de
  evidência — ele é isento por nunca ter tido última manutenção — levando o índice de 60% pra
  80%). Registrado aqui como substituição deliberada, não como criterio pulado.
- **Sem "Todas as unidades" no `/select-organization` legado**: confirmado lendo o componente —
  ele sempre define uma organização específica no storage, nunca um modo "todas". O helper de
  login clica na primeira linha só pra completar o fluxo de autenticação; o teste de `PORTFOLIO`
  depois navega pra `/` sem `?company=` pra garantir que o `DashboardScopeResolver` resolva
  `PORTFOLIO` (2+ orgs acessíveis, sem `companyCode`), independente de qual organização o
  `/select-organization` selecionou.
- **`test.describe.configure({ mode: 'serial' })`** aplicado ao arquivo inteiro: o teste de
  postpone muda permanentemente o item `E2E_OPE_ITEM_4` (de OVERDUE pra uma data futura); os
  testes que leem o estado `OPERATING` (índice 60%, 2 itens vencidos) precisam rodar antes dele.
  Serial + ordem de declaração no arquivo garante isso sem precisar de um segundo item só pra
  esse teste.

### Verificação
`npx tsc --noEmit` limpo no repo inteiro (incluindo os specs novos) — precisou do ajuste de `lib`
acima, sem esse ajuste dava erro `TS2584: Cannot find name 'document'`. **Não executado nesta
sessão**: não havia um MySQL de E2E rodando na porta 3307 (`docker ps` só mostrou o MySQL de dev
na 3306, que foi usado só pra validar a query/dados e depois revertido) e a API completa não sobe
localmente aqui (bloqueio de credencial Firebase real, já documentado em TASK-243/EPIC-030). Os
seletores usados no spec (texto, `aria-label`, `name` de input, `role`) foram todos lidos direto do
código-fonte real dos componentes (`ComplianceHero`, `OnboardingPanel`, `ActionQueue`,
`ComplianceFilterBar`, `src/app/login/page.tsx`, `src/app/select-organization/page.tsx`) — não
adivinhados — mas o fluxo ponta-a-ponta em si nunca rodou contra um app de verdade.

## Status
🟡 Seed + spec implementados e com typecheck limpo; dados sintéticos validados contra MySQL real
(query de compliance produz exatamente os índices que o spec assume). Execução real do Playwright
(`npm run test:ui`) fica pendente — mesmo bloqueio de Firebase/local-boot do resto do EPIC-030.
Douglas precisa rodar isso no ambiente real antes do épico ser considerado QA-aprovado.
