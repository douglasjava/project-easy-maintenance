# TASK-252 — FRONTEND: Gráficos (90 dias, planejado×realizado, custo, ranking)

## Tipo
FRONTEND

## Categoria
Dashboard / Compliance

## Prioridade
🟡 Médio

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Sim — conferir os 4 gráficos em tema claro/escuro e em telas estreitas (scroll horizontal contido
no próprio card, nunca no body da página).

---

## Contexto
Renumerada de TASK-136 do documento original. 4 gráficos: próximos 90 dias (barras semanais
empilhadas), planejado×realizado (12 meses), custo do mês (barras horizontais por categoria),
conformidade por unidade (só `PORTFOLIO`, pior primeiro).

## Critérios de Aceite
- [ ] Gráficos herdam tokens de tema pra texto/grade; nada fixo num tema só
- [ ] Todo rótulo de eixo nomeia um valor que o gráfico realmente alcança; rótulos nunca sobrepõem
      barras
- [ ] Cada gráfico no seu próprio container `overflow-x: auto`; o body da página nunca rola na
      horizontal
- [ ] Sem biblioteca de gráficos nova — SVG inline é suficiente pros 4

## Viabilidade Técnica

Sem achado técnico contrário direto — os 4 gráficos são consumo puro dos dados que a TASK-247
retorna, e SVG inline é uma escolha de implementação razoável (o projeto não tem uma dependência de
charting já instalada, então a recomendação do documento original de não adicionar uma nova é
coerente com o resto do stack).

**Dependência real de dado, não de código:**
- Os 4 gráficos são só tão bons quanto o dado que `/dashboard/series` (TASK-247) consegue
  entregar — `costByCategory` usa a taxonomia de categoria já definida (decisão #7 do épico,
  respondida) e `unitsRanking` depende do índice por organização (TASK-246) já existir. Sem a
  TASK-247 pronta, os gráficos de custo e ranking renderizam vazios/incorretos mesmo com o
  componente de UI pronto.

## Dependências
TASK-247 (dado), TASK-249 (shell).

## Riscos
Baixo em implementação de UI; risco real herdado das dependências de dado (mesmas do TASK-247).

## Esforço
Médio.

## Status
🔴 Não iniciada — bloqueada por TASK-247/249.
