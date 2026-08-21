# EPIC-025 — Conteúdo e Governança das Normas Técnicas (ABNT/NR/RDC)

## Status
🟡 **Fase 2 implementada, aguardando teste local/staging de Douglas antes do PR** (20/08/2026) — as
5 tasks (TASK-181 a TASK-185) estão todas commitadas na branch `feature/ai-onboarding-catalog-filter`
(mesmo nome nos dois repos, `easy-maintenance-api` e `easy-maintenance-web`, a pedido de Douglas —
sem PR por task, tudo testado junto no final antes de abrir a(s) PR(s)). Backend: 775 testes, 0
falhas. Frontend: `npm run build` limpo. Plano de teste manual em
[TASK-QA-MAN-013](../QA/tasks/TASK-QA-MAN-013.md) (9 cenários). Fase 1 (auditoria e correção de
conteúdo) está ✅ concluída desde 19/08/2026.

### Fase 1 — Auditoria e correção de conteúdo (concluída 19/08/2026)

Auditoria norma-a-norma (22 normas analisadas) → 4 tasks → todas
implementadas e mergeadas em `staging` no mesmo dia:
- [TASK-177](../tasks/TASK-177.md) — PR [#38](https://github.com/douglasjava/easy-maintenance-api/pull/38) (api)
- [TASK-178](../tasks/TASK-178.md) — PR [#39](https://github.com/douglasjava/easy-maintenance-api/pull/39) (api)
- [TASK-179](../tasks/TASK-179.md) — PR [#44](https://github.com/douglasjava/easy-maintenance-web/pull/44) (web)
- [TASK-180](../tasks/TASK-180.md) — PR [#45](https://github.com/douglasjava/easy-maintenance-web/pull/45) (web)

Antes de escrever as tasks, o estado real das migrations do banco foi conferido diretamente contra
um select do banco de produção fornecido por Douglas — isso corrigiu duas suposições erradas do
levantamento original (ver TASK-177) e revelou que **`TASK-088` (EPIC-004) já estava concluída**
(`V71`/`V75`), só não tinha sido movida de "Em Validação" para "Concluído" no kanban — corrigido na
mesma rodada.

Único item que não virou task na Fase 1, registrado como pendência de design pra retomar depois: a
distinção `periodicidadeNormativa` vs. `periodicidadeRecomendada` sugerida por Douglas (ver
"Achados" abaixo) e a regionalização (achados #2/#3, decisão de escopo #3) — ambos ficam como
trabalho futuro, fora do escopo do que foi consolidado em tasks na Fase 1.

### Fase 2 — Filtro determinístico de catálogo no onboarding por IA (em andamento, 20/08/2026)

Aproveitando a classificação de normas por segmento feita na Fase 1, Douglas pediu pra validar o
fluxo de onboarding assistido por IA (`/ai-onboarding`, `AiBootstrapService`) — se dava pra reduzir
custo de IA e melhorar a precisão usando o catálogo já curado, em vez de deixar a IA adivinhar tudo
do zero a cada vez. Brainstorm formal conduzido em 20/08/2026, spec aprovada:
`docs/superpowers/specs/2026-08-20-onboarding-catalog-filter-design.md`.

**Achados que motivaram esta fase:**
1. A IA gera todo item do zero (tipo, norma, período, criticidade) sem saber quais normas já
   existem curadas — gastando tokens à toa quando o resultado é descartado.
2. `apply()` casa o `itemType` da IA contra `norms.item_type` por igualdade exata de string —
   divergência de nome perde cobertura regulatória que já existe no catálogo.
3. **Bug de dado**: quando o match acontece, o `nextDueAt` do item é calculado a partir do período
   que a IA inventou no JSON, não do período real da norma vinculada — diverge do fluxo manual de
   criação de item (`ServiceBase.resolvePeriod()`). Autocorrige na primeira manutenção registrada,
   mas até lá o dashboard mostra vencimento errado logo na primeira experiência do cliente novo.

**Desenho aprovado**: filtro determinístico (nova tabela `norm_segments`, relação N-pra-N entre
`norms` e `company_type`) responde a maior parte do checklist por segmento **sem IA nenhuma**,
instantâneo. IA vira complemento opcional só pro que o texto livre do usuário descreve além do
catálogo — instruída (e filtrada em código, não só confiando no prompt) a não repetir o que o
catálogo já trouxe. Bug do `nextDueAt` corrigido convergindo pro mesmo `ServiceBase.resolvePeriod()`
já usado no fluxo manual.

**Tasks da Fase 2:**

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-181](../tasks/TASK-181.md) | Backend: tabela `norm_segments` + filtro por segmento no `NormRepository` | BACKEND | 🟠 Alto |
| [TASK-182](../tasks/TASK-182.md) | Backend: endpoint síncrono `POST /ai/bootstrap/catalog-preview` | BACKEND | 🟠 Alto |
| [TASK-183](../tasks/TASK-183.md) | Backend: corrige `nextDueAt`/`customPeriod*` divergente em itens REGULATORY | BUGFIX | 🔴 Crítico |
| [TASK-184](../tasks/TASK-184.md) | Backend: IA como complemento — evita duplicata, aceita `normId` explícito | BACKEND | 🟡 Médio |
| [TASK-185](../tasks/TASK-185.md) | Frontend: `/ai-onboarding` — filtro instantâneo + IA progressiva | FRONTEND | 🟠 Alto |
| [TASK-186](../tasks/TASK-186.md) | Frontend: experiência mobile pra `/ai-onboarding` (cards no lugar da tabela) | FRONTEND | 🟡 Médio |

**TASK-186** (21/08/2026): achado de Douglas depois de aprovar a Fase 2 no desktop — a tabela de 8
colunas é inviável no mobile mesmo com rolagem horizontal contida (C12). Card list abaixo do
breakpoint `md` do Bootstrap, mesma lógica de estado, sem duplicar comportamento.

Ordem sugerida: TASK-183 primeiro (bugfix isolado, sem dependência, maior urgência); TASK-181 →
TASK-182 → TASK-184 → TASK-185 depois, nessa sequência (cada uma depende da anterior). **Ordem
seguida à risca na implementação (20/08/2026) — as 5 tasks estão prontas, mesma branch nos dois
repos, aguardando Douglas testar local e em staging antes de abrir PR.**

## Objetivo
Corrigir e manter coerente o conteúdo de normas técnicas do produto (catálogo `norms` no banco,
página estática `/norms`, referências normativas no blog) com o que a empresa efetivamente
anuncia — sem citações erradas, sem prazos inventados, sem normas canceladas apresentadas como
vigentes (Fase 1). Estendido na Fase 2 pra também garantir que o catálogo já curado seja
**funcionalmente aproveitado** onde faz sentido — reduzindo dependência de IA (custo) e eliminando
divergência de dado no fluxo de onboarding assistido.

## Contexto

Motivado por uma auditoria de compliance fria e sistemática: levantar todas as normas ABNT/NR/RDC
teoricamente relevantes aos 4 segmentos do produto (condomínios, hospitais, escolas, indústrias),
cruzar contra o que o catálogo funcional e a página estática realmente cobrem, e então analisar
norma a norma o que cada uma exige de fato — em vez de confiar em citações herdadas ou snippets de
busca genérica. Documento de trabalho completo em `docs/produto/levantamento-normas-abnt.md`
(root repo).

**Por que um épico separado**: o levantamento identificou que hoje nenhum épico é dono do
*conteúdo* das normas — `TASK-088` (EPIC-004) trata de governança de *schema/dado* (curated-first,
`pendingReview`, correção de `period_qty = 0`), não de *qual norma é citada onde e se essa citação
está correta*. São preocupações distintas; `TASK-088` permanece no EPIC-004.

## Decisões de escopo confirmadas com Douglas (19/08/2026)

1. **Segmento hospitalar**: produto **não** vai dar suporte a equipamento clínico (ex.: autoclave,
   calibração de esterilização) — fora do escopo. As RDCs hospitalares (15/2012, 50/2002, 63/2011)
   continuam servindo de base legal pra conteúdo/marketing, mas não geram feature de rastreio de
   equipamento clínico.
2. **Segmento indústria**: mesma lógica do item 1 — se for sobre equipamento (não predial), não é
   escopo do produto.
3. **Achados #2/#3 (regionalização — Corpo de Bombeiros IT por estado, vigilância sanitária por
   município)**: viável tratar por região, já que o produto tem o endereço da organização
   disponível. Fica registrado como direção futura — desenho de como isso afeta o catálogo ainda
   não foi feito.
4. Épico dedicado criado (este) — normas deixam de viver soltas dentro do EPIC-004.

## Achados que geraram tasks (ver detalhe completo em `docs/produto/levantamento-normas-abnt.md`)

- Item `AR_CONDICIONADO` cita só `ANVISA RE 09` — correto mas incompleto, falta Lei 13.589/2018 +
  Portaria GM/MS 3.523/1998 → **TASK-177**.
- Item `CAIXA_DAGUA` não cita NR-33 — a limpeza do reservatório vazio é, ela mesma, trabalho em
  espaço confinado → **TASK-177**.
- `SAIDAS_EMERGENCIA_ROTAS`/`SINALIZACAO_EMERGENCIA`/`HIDRANTES_MANGOTINHOS_SISTEMA`/
  `BOMBAS_INCENDIO_SISTEMA` citam só CBMMG IT regional — falta a base ABNT nacional (NBR 9077 /
  NBR 13714) → **TASK-177**.
- **Correção de premissa**: `ALARME_DE_INCENDIO` e `BOTOEIRA_DE_INCENDIO` **já citam** NBR 17240
  corretamente desde a V78 (dedupe) — o levantamento inicial estava desatualizado nesse ponto, sem
  ação necessária.
- Gás combustível: gap total, já especificado por completo (NBR 13103 + NBR 15923, periodicidade
  12 meses; NBR 15526 complementar) → **TASK-178**.
- Página estática `/norms`: faltam NBR 16747, NBR 9050, NBR 9077, NBR 17240, e o par
  NBR 13103/15923 (gás); RDC 50 precisa nota sobre revogação parcial pela RDC 51/2011 → **TASK-179**.
- NBR 15575 estava marcada erroneamente como ausente da página estática no levantamento inicial —
  na verdade já está presente (autocorreção já registrada no documento de trabalho, nenhuma ação).
- NBR 12177/NBR 12228: confirmado que **não estão** na página estática nem no banco — nenhuma ação
  de remoção necessária, só confirmação (feita).
- NBR 5410 na página estática: já não cita "5 anos" — nenhuma correção necessária, pendência
  fechada sem ação.
- Blog post NBR 5674: falta menção à manutenção preditiva, aos artigos 937/938 do Código Civil, e
  à reserva orçamentária anual → **TASK-180**.
- **Sugestão de modelo de dados (Douglas, 19/08/2026)**: distinguir `periodicidadeNormativa`
  (valor que a norma efetivamente exige, quando existe) de `periodicidadeRecomendada` (prática de
  mercado/fabricante) no catálogo — evita que uma recomendação vire, na tela do usuário, "a norma
  exige X". **Não virou task** — precisa de decisão de design (schema vs. só texto) antes de ser
  escopada.

## Tasks Relacionadas — Fase 1

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-177](../tasks/TASK-177.md) | Backend: corrigir/completar citações de normas no catálogo (`norms`) | BACKEND | 🟠 Alto |
| [TASK-178](../tasks/TASK-178.md) | Backend: novo item de catálogo para instalação de gás combustível | BACKEND | 🟡 Médio |
| [TASK-179](../tasks/TASK-179.md) | Frontend: atualizar página `/norms` com os achados do levantamento | FRONTEND | 🟠 Alto |
| [TASK-180](../tasks/TASK-180.md) | Conteúdo: revisar post do blog sobre NBR 5674 | FRONTEND (conteúdo) | 🔵 Baixo |

Ordem sugerida: TASK-177 e TASK-179 primeiro (maior valor, menor esforço), TASK-178 em seguida
(precisa de decisão de nomenclatura), TASK-180 por último (baixa prioridade, conteúdo pontual).

## Critério de Conclusão do Épico

**Fase 1:**
- [x] Todas as correções de citação identificadas na auditoria aplicadas no banco (`norms`)
- [x] Página estática `/norms` revisada e coerente com o levantamento (sem normas canceladas, sem
      prazos inventados, com as normas novas relevantes adicionadas)
- [x] Blog revisado onde cita normas específicas (ex.: post NBR 5674)
- [ ] Decisão registrada sobre `periodicidadeNormativa` vs. `periodicidadeRecomendada` — **não
      concluído**, fica como trabalho futuro (precisa de decisão de design antes de virar task)

**Fase 2:**
- [ ] `norm_segments` criada e populada (TASK-181)
- [ ] `POST /ai/bootstrap/catalog-preview` em produção, sem custo de IA (TASK-182)
- [ ] Bug de `nextDueAt`/`customPeriod*` divergente corrigido (TASK-183)
- [ ] IA não repete itens já cobertos pelo catálogo, `apply()` aceita `normId` explícito (TASK-184)
- [ ] `/ai-onboarding` usa o fluxo em duas camadas (catálogo instantâneo + IA progressiva) (TASK-185)

## Riscos
Baixo-Médio — é trabalho de correção de conteúdo/dado, não de infraestrutura crítica. Risco
principal é volume (muitos pontos de correção pequenos) e a necessidade de não recalcular
`nextDueAt` de itens já existentes sem intenção (mesmo cuidado já registrado na TASK-088). Na Fase
2, risco adicional é a superfície de mudança em `AiBootstrapService`/`apply()` — código sensível
por criar itens de cliente novo — mitigado por convergir pro mesmo caminho já testado do fluxo
manual de criação de item, em vez de introduzir lógica de cálculo nova.
