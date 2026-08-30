# TASK-212 — FULL_STACK: categoria do item deixa de ser escolha livre, passa a ser derivada do tipo

## Tipo
FULL_STACK

## Categoria
Backend + Frontend / Cadastro de itens (compliance, EPIC-025)

## Prioridade
🔴 Crítico

## Épico
Sem épico — comportamento incorreto encontrado por Douglas, 30/08/2026: a tela de cadastro de itens
permitia registrar um item regulatório como operacional e vice-versa.

## QA obrigatório
Sim — QA manual: confirmar que um tipo de item curado (ex.: EXTINTOR, se existir em `item_types` em
produção) força Regulatória automaticamente na tela e no backend, e que um tipo sem norma vinculada
nunca vira Regulatória mesmo manipulando o payload diretamente.

---

## Contexto

Na tela `/items/new`, "Tipo do item" (texto livre, autocomplete contra `item_types`) e "Categoria"
(REGULATORY/OPERATIONAL, dropdown livre) eram campos totalmente independentes — nada impedia
digitar "EXTINTOR" e marcar Operacional (perdendo o prazo legal real da norma), ou o inverso.

## Causa raiz

- `item_types` (catálogo do autocomplete) e `norms` (catálogo curado no EPIC-025) eram dois
  vocabulários livres sem nenhuma relação estrutural entre si.
- `MaintenanceItemService.validateCreate` só validava consistência *interna* do request
  (REGULATORY exige normId; OPERATIONAL exige customPeriod*) — nunca comparava o `itemType`
  digitado com a norma escolhida.
- `MaintenanceItemService.update()` não tinha **nenhuma** validação (nem a interna) — um bug
  encontrado durante a investigação, corrigido junto.

## Objetivo

A categoria de um item passa a ser **derivada** do tipo escolhido, nunca uma escolha independente:
tipo com norma vinculada (`ItemTypes.normId`) → sempre REGULATORY com aquela norma; tipo sem norma
vinculada → sempre OPERATIONAL. O backend é autoritativo (ignora `itemCategory`/`normId` do
request), a tela só reflete o que vai ser salvo de fato.

## Escopo

### Backend
- `V100`: `item_types.norm_id` (FK nullable pra `norms`).
- `V101`: vincula automaticamente os `item_types` cujo `normalized_name` bate exatamente com um dos
  ~27 `item_type` já confirmados no EPIC-025 (lista reaproveitada da V91/`norm_segments`, não uma
  adivinhação nova), mais o caso `LIMPEZA CAIXA DAGUA` confirmado por Douglas (ver abaixo) — no-op
  onde não existir essa linha exata em `item_types` hoje. Testado em H2 real
  (`ItemTypesNormLinkingMigrationTest`) — pegou dois problemas antes do deploy: (1) o join precisa
  ignorar `_` dos dois lados (`normalized_name` nunca tem, os slugs de `norms.item_type` sempre têm),
  e (2) a sintaxe `UPDATE ... JOIN ... SET` (MySQL) nem parseia no H2 — a migration usa `UPDATE` com
  subquery correlacionada em vez disso, portável e testável nos dois.
  **Terceiro problema, só reproduzível em MySQL real** (H2 não modela collation): `item_types` (V6) e
  `norms` (V1) foram criadas sem `COLLATE` explícito, herdando o default do schema no momento em que
  cada uma rodou — no MySQL local de Douglas, `item_types` ficou `utf8mb4_unicode_ci` e `norms`
  `utf8mb4_0900_ai_ci`, e comparar as duas direto quebra com `Illegal mix of collations` (MySQL
  1267) ao tentar subir a aplicação local. Corrigido com `COLLATE utf8mb4_unicode_ci` explícito na
  comparação; validado contra o MySQL real local dele (transação com `ROLLBACK`, sem side effect) —
  27/27 `item_types` REGULATORY vinculados corretamente com o fix, erro reproduzido sem ele.
- `MaintenanceItemService`: `resolveClassification(itemType)` substitui `validateCreate` — resolve
  `ItemTypes` pelo nome normalizado e deriva categoria/normId; `create()` e `update()` aplicam a
  mesma regra (fechando também o gap do `update()` sem validação nenhuma).
- `ItemTypes`/`ItemTypesResponse`: expõem `normId`.

### Frontend (`items/new/page.tsx`)
- Removido o dropdown "Categoria" e o dropdown "Norma" — substituídos por indicadores derivados
  (categoria muda sozinha ao escolher/criar o tipo; norma aplicável aparece automaticamente,
  read-only).
- `AsyncCreatableSelect`/`/item-types` passam a carregar `normId` junto de cada opção.

## ⚠️ Efeito colateral imediato — leia antes de mergear/deployar

Assim que isso for deployado, **só os `item_types` já vinculados a uma norma podem ser Regulatória**
— qualquer tipo ainda não curado vira Operacional, mesmo que já existisse como Regulatória no banco.
Dois cenários concretos:

1. **Cadastrar novo item de um tipo ainda não curado**: só sai como Operacional (esperado, é o
   comportamento seguro por padrão).
2. **Editar um item REGULATORY existente cujo tipo não está em `item_types.norm_id`**: o `update()`
   vai **rebaixar esse item pra OPERATIONAL** na próxima edição, porque a categoria passa a ser
   sempre re-derivada do tipo. Isso só afeta itens que forem *editados* depois do deploy — itens
   parados no banco sem edição continuam com a categoria antiga.

A `V101` cobre automaticamente os ~27 tipos do EPIC-025 **se e somente se** existir hoje em
`item_types` uma linha com nome exatamente igual ao `item_type` da norma (ex.: uma linha chamada
literalmente `EXTINTOR`). Os ~150 `item_types` semeados nas V7/V8 usam nomes tipo
"verbo + substantivo" (ex.: `INSPECAO DE EXTINTORES`) que **não** batem por igualdade — esses (e
qualquer `item_types` criado ad-hoc por uso real que não seja um nome exato) continuam sem norma até
curadoria manual.

**Atualização 30/08:** Douglas rodou `SELECT DISTINCT item_type FROM maintenance_items WHERE
item_category = 'REGULATORY'` em produção — 26 dos 27 tipos batem exatamente com o slug de uma
norma (cobertos pela V101). O único que não batia, `LIMPEZA CAIXA DAGUA` (nome livre "verbo +
substantivo", V7), foi confirmado por ele como o tipo usado pra itens da norma `CAIXA_DAGUA` — a
V101 agora vincula esse caso explicitamente também. Ou seja: **nenhum item REGULATORY real de
produção fica exposto ao rebaixamento** com o estado atual da migration.

Se novos `item_types` REGULATORY aparecerem depois (uso normal do produto), a query acima continua
válida pra auditoria antes de editar itens antigos.

## Achado relacionado (não corrigido aqui, fora de escopo)

`AiBootstrapService.processItem` (fluxo de onboarding por IA, TASK-182/184) já tinha sua própria
proteção contra esse mesmo problema — mas por um mecanismo diferente: casa `itemType` direto contra
`Norm.itemType` (sem passar por `ItemTypes.normId`), ignorando normas com `authority = 'AI_BOOTSTRAP'`.
Não é o mesmo caminho de código do formulário manual, não estava quebrado, e não foi tocado aqui.
Vale unificar os dois mecanismos num follow-up, mas misturar agora fugiria do escopo (regra de "um
fix por vez").

## Critérios de Aceite

- [x] `item_types.norm_id` existe e é usado como fonte de verdade da categoria
- [x] `MaintenanceItemService.create`/`update` derivam categoria/normId do tipo, ignorando o que o
      request pediu em `itemCategory`/`normId`
- [x] Teste novo (`MaintenanceItemClassificationTest`) comprova os dois lados do bug fechados:
      tipo curado não vira OPERATIONAL, tipo não-curado não vira REGULATORY com normId inventado
- [x] Teste novo (`ItemTypesNormLinkingMigrationTest`) comprova a lógica de vinculação da V101 em
      H2 real — falha sem o `REPLACE(..., '_', '')`, passa com ele
- [x] `mvn clean test` sem regressão (853/853, 0 falhas — confirmado após o fix de collation na
      V101)
- [x] Frontend: categoria/norma na tela `items/new` são derivadas, não escolhas livres
- [ ] QA manual em produção pós-deploy (pendente)

## Dependências
Nenhuma (relacionado à curadoria já feita no EPIC-025, mas não depende de nenhuma task aberta).

## Riscos
Médio — muda o comportamento de `update()` pra qualquer item cujo tipo não esteja curado (ver seção
"Efeito colateral imediato" acima). Mitigado pela V101 (cobertura automática dos tipos já
confirmados no EPIC-025 onde o nome bate exato) e pela recomendação de auditoria manual antes de
editar itens regulatórios existentes.

## Esforço
Médio

## Status
✅ Implementado, PRs abertas contra `staging`:
[api#60](https://github.com/douglasjava/easy-maintenance-api/pull/60) e
[web#60](https://github.com/douglasjava/easy-maintenance-web/pull/60). Branch
`feature/TASK-212-item-category-derived-from-type` nos dois repos. Suíte completa da API
(`mvn clean test`): 853/853, 0 falhas. Typecheck e lint do frontend sem regressão (mesmos 4 avisos
pré-existentes de `no-explicit-any`, não introduzidos por esta task). Curadoria ampla dos ~150
`item_types` (além dos 27 já cobertos pela V101, confirmados 27/27 contra produção) fica com
Douglas, fora desta task.

**30/08, correção pós-push:** subir a API localmente falhou no boot — V101 quebrava com
`Illegal mix of collations` (MySQL 1267) porque `item_types` e `norms` foram criadas em migrations
diferentes sem `COLLATE` explícito e ficaram com collations diferentes no MySQL local
(`utf8mb4_unicode_ci` vs. `utf8mb4_0900_ai_ci`). Corrigido com `COLLATE utf8mb4_unicode_ci`
explícito na comparação; validado contra o MySQL real local de Douglas (transação com `ROLLBACK`,
sem alterar dado real) — 27/27 vinculados corretamente com o fix. Commit `4d4553c`, já no PR #60.
