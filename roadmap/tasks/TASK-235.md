# TASK-235 — INFRA/CONFIG: Scripts k6 + execução + relatório de gargalos

## Tipo
INFRA/CONFIG

## Categoria
Performance / Teste de carga

## Prioridade
🟡 Médio

## Épico
[EPIC-029](../epics/EPIC-029.md) — Teste de Carga Estrutural

## QA obrigatório
Sim — cada script precisa rodar do início ao fim contra a API local (com o seed da TASK-233 e o
profile `loadtest` da TASK-234 ativos) e produzir saída utilizável (resumo de p50/p95/p99 + taxa de
erro) antes de virar achado no relatório.

---

## Contexto

Peça final do épico: com dado semeado (TASK-233) e instrumentação ligada (TASK-234), roda carga de
verdade contra os 3 fluxos priorizados no brainstorm (08/09/2026) e produz o relatório de achados —
o entregável do épico. Sem corrigir nada aqui: cada gargalo encontrado vira task própria depois,
priorizada por Douglas.

## Escopo

- Ferramenta: **k6** (JS, binário único, integra nativo com Prometheus remote-write — já há
  `/actuator/prometheus` exposto na API).
- Novo diretório `easy-maintenance-api/loadtest/` (só scripts + README, fora do build de produção):
  - `login.js`
  - `items-search.js`
  - `notification-detection.js` (aciona via o endpoint de disparo manual já existente,
    [TASK-132](TASK-132.md): `GET /run-jobs/execute-notification-detection`)
- Cada script sobe carga em rampa (ex.: 10 → 50 → 100 usuários virtuais, valor exato a afinar
  durante a execução) contra a API local rodando com o seed da TASK-233 e o profile `loadtest` da
  TASK-234 ativos.
- Saída: resumo k6 (texto/JSON) com p50/p95/p99 + taxa de erro por endpoint, cruzado com a contagem
  de query por request (log do profile `loadtest`) pra identificar causa raiz, não só sintoma.
- Relatório final (documento novo, ex. `docs/superpowers/reports/2026-XX-XX-load-test-findings.md`
  ou anexado à conclusão desta task) — cada achado com: sintoma (evidência numérica) + causa raiz +
  sugestão de correção, sem implementá-la.

## Critérios de Aceite

- [ ] 3 scripts k6 (login, `/items`, detecção de notificação) rodam do início ao fim contra a API
      local com seed + profile `loadtest` ativos
- [ ] Cada execução produz p50/p95/p99 + taxa de erro por endpoint
- [ ] Achados de gargalo (se houver) documentados com evidência (contagem de query, tempo, ponto de
      quebra de concorrência) — não é aceitável reportar "está lento" sem causa raiz
- [ ] Scripts versionados no repo com README de como rodar (pré-requisitos: seed da TASK-233,
      profile da TASK-234, API local rodando)
- [ ] Relatório final entregue, mesmo que a conclusão seja "nenhum gargalo relevante na escala
      testada" — resultado negativo também é informação válida

## Dependências
TASK-233 (seed) e TASK-234 (profile `loadtest`) — precisa das duas prontas antes de rodar de
verdade e conseguir atribuir causa raiz aos achados.

## Riscos
Baixo pro código de produção — roda só contra ambiente local. Risco real: a escala sintética
(média, definida na TASK-233) pode não bastar pra expor todo gargalo relevante — se o resultado for
"tudo dentro do esperado", pode ser sinal de escala insuficiente, não necessariamente ausência de
problema. Registrar essa limitação no relatório final se for o caso.

## Esforço
Médio

## Status
🔴 Não iniciada
