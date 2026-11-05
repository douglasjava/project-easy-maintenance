# TASK-186 — Frontend: experiência mobile pra `/ai-onboarding` (Etapa 2 — cards em vez de tabela)

## Tipo
FRONTEND

## Categoria
Onboarding por IA / UX Mobile

## Prioridade
🟡 Médio

## Épico
[EPIC-025](../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas (Fase 2)

## QA obrigatório
Sim — QA manual em viewport mobile real (DevTools device toolbar +, se possível, celular real):
conferir os 3 cenários abaixo em telas pequenas (≤576px) e médias (768px, ponto de troca
tabela↔cards).

---

## Contexto

Achado de Douglas (21/08/2026), depois de aprovar a Fase 2 no desktop: a tabela da Etapa 2 tem 8
colunas (checkbox, Origem, Item, Categoria, Criticidade, Periodicidade, Norma, Ações) — inviável no
mobile mesmo com rolagem horizontal contida (já implementada no C12). Rolagem horizontal numa
tabela densa é um padrão de UX ruim em tela pequena, não só "meio apertado".

## Objetivo

Trocar a tabela por uma lista de cards compactos quando a viewport for menor que o breakpoint `md`
do Bootstrap (768px), mantendo a tabela atual intacta em telas maiores. Mesmo estado (`items`,
`toggleSelect`, `toggleSelectAll`, `handleEdit`, `removeItem`) alimenta os dois modos de exibição —
sem duplicar lógica, só a apresentação.

## Escopo

### 1. Lista de cards (mobile, `d-md-none`)

Card por item, layout compacto:
```
┌─────────────────────────────────────────┐
│ [x] EXTINTOR              [✅ Catálogo]  │
│     [ALTA]  12 MESES                     │
│     Norma: ABNT / Corpo de Bombeiros     │
│              [Editar]      [Remover]     │
└─────────────────────────────────────────┘
```
- Checkbox + nome do item + badge de origem na linha de topo (mesma prioridade visual da tabela).
- Badge de criticidade + periodicidade na segunda linha.
- Norma como texto pequeno/muted (mesma tratativa da coluna "Norma" hoje).
- Categoria **não** entra no card — é o campo menos essencial pra decisão do usuário (manter/
  remover/editar), evita poluir o card. Continua disponível na tabela desktop.
- Botões Editar/Remover mantêm o mesmo `onClick` já existente (`handleEdit(it)` / `removeItem(it.localId)`).

### 2. "Selecionar todos" equivalente pro mobile

Sem cabeçalho de tabela no modo card — adicionar uma linha compacta acima da lista de cards
(checkbox + label "Selecionar todos"), reaproveitando `toggleSelectAll()` já existente.

### 3. Tabela atual → `d-none d-md-block`

Sem mudança de conteúdo/lógica da tabela — só envolvida na classe que a esconde abaixo de `md`.

### 4. Modal de edição — ajuste pontual de responsividade

`col-6`/`col-6` (Qtd. Período / Unidade) viram `col-12 col-sm-6` — hoje ficam lado a lado até em
telas muito estreitas, o suficiente pra apertar em phones pequenos (< 400px).

## Critérios de Aceite

- [x] Viewport < 768px: lista de cards aparece, tabela não aparece (`d-md-none`/`d-none d-md-block`)
- [x] Viewport ≥ 768px: tabela aparece (comportamento atual, sem regressão), cards não aparecem
- [x] Selecionar/desmarcar item individual funciona igual nos dois modos (mesmo `toggleSelect`)
- [x] "Selecionar todos" funciona no modo card (mesmo `toggleSelectAll`)
- [x] Editar/Remover funcionam a partir do card, abrindo o mesmo modal já existente
- [x] Modal de edição não aperta os campos "Qtd. Período"/"Unidade" em telas < 400px (`col-12 col-sm-6`)
- [x] Badge de origem (Catálogo/IA) e criticidade visíveis no card sem precisar de interação extra
- [x] `npm run build` limpo
- [ ] **QA manual em navegador real/DevTools — pendente**: implementação não pôde ser validada
      visualmente por mim (tela exige login, sem credenciais de teste disponíveis) — só build e
      revisão de código. Douglas precisa confirmar visualmente antes de considerar concluída.

## Dependências
Nenhuma técnica — depende só da Fase 2 já implementada (TASK-181 a TASK-185), que introduziu os
campos (`source`, badges) que o card também precisa exibir.

## Riscos
Baixo — aditivo, não altera a lógica de estado nem os endpoints. Maior risco é de detalhe visual
(quebra de layout em algum tamanho de tela específico), mitigado testando em pelo menos 2 larguras
(≤576px e ~768px).

## Esforço
Baixo-Médio

## Status
✅ Implementada e commitada (21/08/2026) na branch `feature/ai-onboarding-catalog-filter`
(`easy-maintenance-web`, commit `d38e65d`). `npm run build` limpo. PR
[#46](https://github.com/douglasjava/easy-maintenance-web/pull/46) aberta em 21/08/2026 (mesma
branch reúne toda a Fase 2 do frontend). **Não validada visualmente por mim** — tentei abrir
`/ai-onboarding` no Chrome em viewport mobile pra conferir, mas a tela exige login e não tenho
credenciais de teste; não devo inserir/adivinhar credenciais. Aguardando Douglas testar em
navegador real (DevTools device toolbar ou celular).
