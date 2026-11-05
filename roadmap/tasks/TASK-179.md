# TASK-179 — Frontend: atualizar página `/norms` com os achados do levantamento

## Tipo
FRONTEND

## Categoria
Conteúdo Regulatório / Compliance

## Prioridade
🟠 Alto

## Épico
[EPIC-025](../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas

## QA obrigatório
Sim — QA manual: abrir `/norms` logado, conferir que todas as entradas novas renderizam certo no
accordion (sem quebrar layout com texto mais longo) e que nada foi duplicado.

---

## Contexto

`easy-maintenance-web/src/app/norms/page.tsx` é uma página **privada** (dentro de `PrivateRoute`),
conteúdo 100% hardcoded no array `NORMS` (13 entradas hoje), sem consultar o banco. O levantamento
norma-a-norma (`docs/produto/levantamento-normas-abnt.md`) identificou adições e uma correção
pontual. Conteúdo atual já conferido diretamente no arquivo antes de escrever esta task — evitar
duplicar entradas já existentes.

## Objetivo

Adicionar as entradas novas e aplicar a correção pontual, seguindo exatamente o formato já usado
(`code`, `name`, `description`, `importance`).

## Escopo

### 1. Adicionar 5 entradas novas ao array `NORMS`

**NBR 16747** (Inspeção Predial):
```js
{
  code: "NBR 16747",
  name: "Inspeção Predial — Diretrizes, Conceitos, Terminologia e Procedimento",
  description: "Estabelece a metodologia para avaliação sistêmica e sensorial das condições de uso, operação, manutenção e funcionalidade do edifício, classificando anomalias por grau de risco (crítico, médio, mínimo).",
  importance: "Fundamenta o laudo de inspeção predial exigido por lei em diversos municípios (ex.: São Paulo) para edifícios acima de determinada idade — reforça a responsabilidade legal do síndico."
}
```

**NBR 9050** (Acessibilidade):
```js
{
  code: "NBR 9050",
  name: "Acessibilidade a Edificações, Mobiliário, Espaços e Equipamentos Urbanos",
  description: "Estabelece critérios técnicos para tornar edificações e espaços urbanos acessíveis — rampas, rotas acessíveis, sinalização tátil/visual, vagas exclusivas.",
  importance: "Diferente da maioria das normas ABNT, tem força de lei direta (Lei Brasileira de Inclusão 13.146/2015 e Decreto 5.296/2004) — obrigatória, não apenas recomendada, inclusive para edificações já existentes."
}
```

**NBR 9077** (Saídas de Emergência):
```js
{
  code: "NBR 9077",
  name: "Saídas de Emergência em Edifícios — Projeto",
  description: "Define os requisitos de projeto das rotas de fuga em caso de incêndio — dimensionamento, distância máxima a percorrer, iluminação e sinalização de emergência.",
  importance: "Aplica-se a qualquer tipo de edificação — a rota de fuga desobstruída e sinalizada é responsabilidade contínua do síndico/administrador, com risco de responsabilização civil e criminal em caso de omissão."
}
```

**NBR 17240** (Detecção e Alarme de Incêndio):
```js
{
  code: "NBR 17240",
  name: "Sistemas de Detecção e Alarme de Incêndio",
  description: "Requisitos de projeto, instalação, comissionamento e manutenção de sistemas manuais e automáticos de detecção e alarme de incêndio, incluindo exigência de fonte de alimentação redundante.",
  importance: "Base técnica nacional do sistema de alarme de incêndio — complementa (não substitui) as instruções técnicas do Corpo de Bombeiros de cada estado."
}
```

**Instalação de Gás Combustível** (par de normas, acompanha o item de catálogo da TASK-178):
```js
{
  code: "NBR 13103 / NBR 15923",
  name: "Instalação e Inspeção de Aparelhos a Gás",
  description: "NBR 13103 define os requisitos do aparelho a gás; NBR 15923 define o procedimento de inspeção da rede e do aparelho. Juntas, cobrem manutenção preventiva anual obrigatória.",
  importance: "Manutenção anual (ou conforme fabricante, o que for mais curto) evita vazamentos e perda de garantia do aparelho — item comum em condomínios sem cobertura normativa clara até agora."
}
```

### 2. Correção pontual — entrada `RDC 50 (Anvisa)`
Adicionar ao final da `description` atual: *"Parcialmente revogada pela RDC 51/2011 (itens de
projeto básico de arquitetura, responsabilidades e avaliação de projetos) — o restante do
regulamento permanece em vigor."*

### 3. Não alterar
`NBR 5410`, `NBR 16083`, `RDC 63`, `NBR 5674`, `NBR 16280`, `NBR 15575` — já corretas conforme o
levantamento (nenhuma citava prazo inventado ou norma cancelada). `NBR 5674` recebe ajuste de texto
separado (menção à manutenção preditiva) — ver TASK-180, que trata do mesmo post/família de
conteúdo; se for mais simples, aplicar aqui também já que é a mesma página. Decisão de quem
implementa: se a mudança do `NBR 5674` for trivial (uma frase), pode ser incluída nesta task em vez
de abrir escopo extra na TASK-180.

## Critérios de Aceite

- [ ] 5 entradas novas adicionadas, renderizando corretamente no accordion
- [ ] Entrada `RDC 50` menciona a revogação parcial pela RDC 51/2011
- [ ] Nenhuma entrada existente duplicada ou removida
- [ ] `npm run build` limpo

## Dependências
Nenhuma técnica. A entrada de gás combustível faz mais sentido publicada junto com a TASK-178 (item
de catálogo), mas não é bloqueante — pode ir mesmo se a TASK-178 ainda não tiver sido feita.

## Riscos
Baixo — página estática, sem lógica de negócio, aditiva.

## Esforço
Baixo

## Status
✅ Concluída — PR [#44](https://github.com/douglasjava/easy-maintenance-web/pull/44) mergeada em
`staging` em 19/08/2026. `npm run build` limpo. Ajuste da NBR 5674 (menção à preditiva) foi
incluído aqui, já que era trivial — não precisa ser repetido na TASK-180 (que trata só do post do
blog).
