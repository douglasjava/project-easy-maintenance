# EPIC-025 — Conteúdo e Governança das Normas Técnicas (ABNT/NR/RDC)

## Status
Auditoria norma-a-norma concluída (22 normas analisadas), pendências técnicas resolvidas com
Douglas em 19/08/2026. Lista consolidada e quebrada em 4 tasks, prontas para implementar
(19/08/2026). Antes de escrever as tasks, o estado real das migrations do banco foi conferido
diretamente contra um select do banco de produção fornecido por Douglas — isso corrigiu duas
suposições erradas do levantamento original (ver TASK-177) e revelou que **`TASK-088` (EPIC-004)
já estava concluída** (`V71`/`V75`), só não tinha sido movida de "Em Validação" para "Concluído"
no kanban — corrigido nesta mesma rodada.

## Objetivo
Corrigir e manter coerente o conteúdo de normas técnicas do produto (catálogo `norms` no banco,
página estática `/norms`, referências normativas no blog) com o que a empresa efetivamente
anuncia — sem citações erradas, sem prazos inventados, sem normas canceladas apresentadas como
vigentes.

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

## Tasks Relacionadas

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-177](../tasks/TASK-177.md) | Backend: corrigir/completar citações de normas no catálogo (`norms`) | BACKEND | 🟠 Alto |
| [TASK-178](../tasks/TASK-178.md) | Backend: novo item de catálogo para instalação de gás combustível | BACKEND | 🟡 Médio |
| [TASK-179](../tasks/TASK-179.md) | Frontend: atualizar página `/norms` com os achados do levantamento | FRONTEND | 🟠 Alto |
| [TASK-180](../tasks/TASK-180.md) | Conteúdo: revisar post do blog sobre NBR 5674 | FRONTEND (conteúdo) | 🔵 Baixo |

Ordem sugerida: TASK-177 e TASK-179 primeiro (maior valor, menor esforço), TASK-178 em seguida
(precisa de decisão de nomenclatura), TASK-180 por último (baixa prioridade, conteúdo pontual).

## Critério de Conclusão do Épico
- [ ] Todas as correções de citação identificadas na auditoria aplicadas no banco (`norms`)
- [ ] Página estática `/norms` revisada e coerente com o levantamento (sem normas canceladas, sem
      prazos inventados, com as normas novas relevantes adicionadas)
- [ ] Blog revisado onde cita normas específicas (ex.: post NBR 5674)
- [ ] Decisão registrada sobre `periodicidadeNormativa` vs. `periodicidadeRecomendada`

## Riscos
Baixo-Médio — é trabalho de correção de conteúdo/dado, não de infraestrutura crítica. Risco
principal é volume (muitos pontos de correção pequenos) e a necessidade de não recalcular
`nextDueAt` de itens já existentes sem intenção (mesmo cuidado já registrado na TASK-088).
