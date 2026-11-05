# TASK-250 — FRONTEND: Hero de conformidade + tiles de KPI

## Tipo
FRONTEND

## Categoria
Dashboard / Compliance

## Prioridade
🟠 Alto

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Sim — confirmar `aria-label` do anel, `tabular-nums` nos números, cor semântica correta dos deltas
(queda de `overdue` é verde), e tema claro/escuro.

---

## Contexto
Renumerada de TASK-134 do documento original. Card hero (único com fundo escuro e anel) + 3 tiles
de KPI com sparkline.

## Escopo
- Hero: anel do `complianceIndex` com meta, delta em pontos percentuais vs. mês anterior, 3 linhas
  de fato (em dia / vencido / sem evidência).
- 3 tiles de KPI: label, número grande, delta vs. período anterior, sparkline de 6 meses.
- Direção semântica dos deltas — `overdue` caindo é bom (verde), não colorir só pelo sinal
  aritmético.

## Critérios de Aceite
- [x] `font-variant-numeric: tabular-nums` em todo número
- [x] Sparklines vêm só do array da API; nenhum dado aleatório/placeholder
- [x] Anel com `role="img"` e `aria-label` com o percentual
- [x] Cores semânticas (crítico/atenção/ok) são tokens separados do azul da marca
- [~] Tema claro/escuro — **não aplicável**: achado durante a implementação — `globals.css` do
      projeto não trata `prefers-color-scheme` em lugar nenhum, o app inteiro não tem suporte a
      dark mode hoje (mesmo achado já registrado em memória de sessão anterior, demo Rogerio
      Dantas). Cores fixas (hex direto), consistente com o resto do app — não é uma regressão
      desta task, é o estado atual de todo o produto.

## Viabilidade Técnica

**Já existe algo parecido:** `KPIGrid.tsx` (141 linhas) hoje já renderiza os KPIs do dashboard
atual — este task substitui esse componente, não cria o conceito do zero. Vale revisar os tokens de
cor que ele já usa antes de criar novos, pra manter consistência com o resto do app (ex. os badges
de `registrationCount` em `fornecedores/page.tsx`, EPIC-028, usam `#eff6ff`/`#1d4ed8` pro tom
"confiável" — bom ponto de partida pros tokens semânticos daqui).

**Bloqueado por dado que ainda não existe:**
- Sparkline de 6 meses e delta vs. "mês anterior" — mesma pendência de histórico/snapshot da
  TASK-246 (decisão #6 do épico). Sem isso, esta task não tem dado real pra desenhar — e a própria
  regra do protótipo proíbe placeholder.

**Sem achado técnico contrário** ao resto do escopo (anel SVG, tabular-nums, aria-label são
implementação de UI padrão, sem dependência de dado que não exista).

## Dependências
TASK-249 (shell). TASK-246 (dado real do índice + histórico).

## Riscos
Baixo em implementação, alto em ficar bloqueado esperando o snapshot histórico existir de verdade.

## Esforço
Médio.

## Implementação
`src/components/dashboard/compliance/ComplianceHero.tsx` (anel) + `KpiTiles.tsx` (3 tiles +
sparkline). Cor semântica dos KPIs via flag `lowerIsBetter` explícita (não pelo sinal aritmético
cru) — os 3 KPIs desta v1 (vencidos/vencendo em 30 dias/custo) são todos "quanto menor, melhor".
`previousComplianceIndex`/`previous`/`spark` ficam `null`/zero-fill quando a TASK-246 ainda não tem
snapshot acumulado (conta nova ou job rodando há pouco tempo) — nunca inventado.

`npm run build`/`eslint` limpos, sem regressão em `npm test`.

## Status
🟢 Implementado — dark mode não aplicável (ver critério acima). Validação num navegador real fica
pendente (mesmo bloqueio de Firebase do EPIC-030).
