# TASK-315 — Assistente: item operacional novo pelo catálogo padronizado + periodicidade por botão

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 2** (extensão da TASK-306)

## Depende de
TASK-306, TASK-314

## QA obrigatório
Sim.

## Contexto
No piloto de 28/09/2026, "Limpeza de piscina no dia 10/08/2026, executado pelo Augusto da empresa Piscinas Azuis"
caiu em "não encontrei esse item". Pela regra da TASK-306, o bot só cria item **regulatório**, porque a periodicidade vem
da norma. Item operacional precisa de periodicidade, e o bot não pode inventá-la.

Douglas quer que o bot também cadastre o item operacional, com **um padrão mínimo de nome**: nada de itens como
"bananinha" criados pelo WhatsApp.

## Decisão de desenho
- **O nome vem só do catálogo `item_types`** (cerca de 180 tipos operacionais padronizados da V7/V8, ex.: MANUTENCAO DE PISCINA,
  LIMPEZA FILTRO PISCINA, TRATAMENTO QUIMICO PISCINA). O texto do usuário nunca vira nome de item.
  - Sem correspondência no catálogo → mantém a resposta atual (lista de itens + link `/items/new`). "Bananinha" nunca é criado.
- **Correspondência determinística primeiro:** pontuação por palavras do texto contra o nome legível do tipo
  (`ItemTypeLabels`), ignorando palavras vazias ("de", "da", "o"…). Se houver 1 candidato forte, ele é usado; se houver
  2 ou mais, o bot mostra os 3 melhores numa lista mais a opção "Nenhum desses".
- **IA só como alternativa e só escolhendo:** se a correspondência determinística não achar nada, o classificador pode devolver
  um `item_type_id` de uma **lista fechada** de ids do catálogo (mesma regra do EPIC-031: a IA classifica, não escreve).
  Id fora da lista → é ignorado. É opcional nesta task e só entra se o custo de tokens for aceitável.
- **Periodicidade por botão (lista):** 1 mês · 3 meses · 6 meses · 1 ano · Cancelar. Não gasta IA.
- **Resumo** com "🆕 Item novo: Manutenção de piscina (Operacional — a cada 3 meses)" e os botões Confirmar/Corrigir/Cancelar
  de sempre. "Corrigir" permite trocar a periodicidade ("a cada 6 meses").
- Gravação: `MaintenanceItemService.create` com `customPeriodUnit`/`customPeriodQty` + manutenção, na mesma transação
  da TASK-306 (`source = WHATSAPP`, auditoria com o wamid). O limite de itens do plano continua valendo.

## Estratégia de consulta (sem gargalo no banco) — definida em 28/09/2026
- **Snapshot do catálogo em memória** (Caffeine, que já está no projeto): tipos ATIVOS + nome legível normalizado + palavras
  pré-calculadas + mapa norma→rótulo. É 1 carga (~200 linhas de `item_types` + ~35 de `norms`) a cada 10 min por instância,
  e a entrada é invalidada no `POST /item-types`. A comparação roda em memória (~200 × poucas palavras = microssegundos).
  Em regime normal, **nenhuma consulta ao banco por mensagem**.
- O fluxo de catálogo regulatório da TASK-314 (`listAll(null)` + `findAllByIdsAsMap` a cada registro sem item) passa a
  usar o mesmo snapshot.
- Nada de `LIKE '%…%'`/full-text no MySQL. Os itens da organização continuam vindo do `findAll` paginado (ITEMS_SCAN) que já existe.
- O volume já é limitado: o caminho só roda quando o item não é encontrado, e há limite de 20 mensagens/10 min por usuário.

## Achado: catálogo global aberto a qualquer usuário
`/items/new` (web) faz `POST /item-types` com o texto digitado. **Qualquer usuário grava no catálogo global**, que é
compartilhado entre todas as organizações e não guarda autor. Um "BANANINHA" digitado no web já entra no catálogo e
aparece para os outros clientes.
- Nesta task: o bot só oferece tipos **curados** = seeds (id ≤ 186, V7/V8) ou com `norm_id`. Os tipos criados pelo web ou pela
  IA Onboarding (ids 187–231 em 28/09) ficam de fora até serem curados. Flag `curated` via migration (ou `origin = SEED`, se a
  TASK-316 vier antes).
- A separação global × tipos da organização e a curadoria ficam na [TASK-316](TASK-316.md).

## Critérios de aceite
- [x] "limpeza de piscina…" propõe um tipo do catálogo (ou pede escolha entre até 3) e depois pergunta a periodicidade.
- [x] Texto sem correspondência no catálogo ("bananinha") nunca cria item: a resposta continua sendo o link de cadastro.
- [x] O item criado usa o `normalized_name` do catálogo, categoria OPERATIONAL e a periodicidade escolhida.
- [x] Item regulatório continua com prioridade (se casar com norma, segue o fluxo da TASK-314).
- [x] Limite de itens do plano, perfil só leitura e somente leitura da assinatura continuam barrando.
- [x] Escolha de tipo e de periodicidade não consome crédito de IA.
- [x] Nenhuma consulta a `item_types`/`norms` por mensagem com o snapshot já carregado (teste com contagem de chamadas ao repositório).
- [x] Só tipos `curated = true` são oferecidos pelo bot.

**Prompt**: `execute a TASK-315 (EPIC-031): item operacional novo pelo WhatsApp só com nome do catálogo item_types e
periodicidade escolhida por botão.`

## Notas de execução (28/09/2026)
- Branch `feature/TASK-315-assistente-item-operacional-catalogo` · PR [api#134](https://github.com/douglasjava/easy-maintenance-api/pull/134) → staging.
- `AssistantCatalog` (Caffeine, 10 min) + `CatalogMatcher`/`CatalogTokens`: comparação em memória, sem IA. Palavras de objeto
  são obrigatórias; palavras de ação só desempatam. O nome de quem fez é tirado do texto antes da comparação.
- V121 `item_types.curated`: seeds (primeiro dia do catálogo) + tipos vinculados a norma. Validada no H2 (o arquivo roda no
  teste) e no MySQL 8 local, numa cópia descartável (218/222 curados).
- **Decisão:** a IA como alternativa (escolha em lista fechada de ids) **não** entrou. A comparação determinística cobriu os
  casos do piloto sem gastar crédito. Reavaliar se o piloto mostrar muitos "Nenhum desses".
- **Decisão:** periodicidade só em meses (1–24), gravada como `MESES` (sem dias, sem `ANUAL`).
- Suíte: 1305/1305.

## Status
Done — validada no piloto em produção em 28/09/2026: piscina (lista de tipos + periodicidade → item Operacional no web),
extintores (regulatório, vencimento anual pela norma) e "bananinha" (nada criado).
