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

## Implementação

### Arquivos criados
- `loadtest/login.js`, `loadtest/items-search.js`, `loadtest/notification-detection.js` — scripts
  k6, rampa de carga (0→10→50→100 VUs pros dois primeiros; concorrência baixa de propósito pro
  terceiro, ver comentário no próprio arquivo).
- `loadtest/README.md` — pré-requisitos, como rodar, como cruzar com `loadtest.querycount`.
- `docs/superpowers/reports/2026-09-10-load-test-findings.md` — relatório final, 4 achados (1
  crítico real, 1 metodológico/rate-limit, 1 negativo válido, 1 correção na própria
  instrumentação da TASK-234).

### Bloqueio resolvido nesta sessão: boot local sem Firebase (TASK-258)
A API local nunca tinha subido de verdade nesta sessão inteira (bloqueou validação HTTP real de
EPIC-028 e EPIC-030 também) — `FirebaseConfig.firebaseMessaging()` retorna `null` sem credencial, e
o Spring recusava injetar um bean nulo no construtor obrigatório de `PushNotificationProvider`.
Corrigido (`Optional<FirebaseMessaging>`, TASK-258) — **desbloqueou rodar o k6 de verdade**, não só
escrever os scripts.

### Execução real (não simulada) — ambiente
MySQL 8.0.33 efêmero via Docker (porta 3308, schema copiado via `mysqldump --no-data` +
`flyway_schema_history` real, nunca tocando o banco de dev), semeado pela TASK-233 (500 orgs/50k
itens/150k manutenções). API local com `--spring.profiles.active=local,loadtest`, chave RSA gerada
via `RsaKeyGenerator` (já existia no projeto, só não tinha sido usada), `FIREBASE_SERVICE_ACCOUNT_JSON`
vazia. **Achado à parte, corrigido**: `application-local.properties` tem a URL do datasource fixa
em `localhost:3306` (não lê `${DB_HOST}`/`${DB_PORT}`) — pra apontar pro banco efêmero foi preciso
sobrescrever via `EASY_DATASOURCE_URL` (relaxed binding do Spring). Documentado no
`loadtest/README.md` pra não repetir a confusão.

### Achados (resumo — detalhes completos no relatório)
1. 🔴 **Crítico**: `NotificationOrchestratorService.dispatch()` processa 5.000 eventos
   sequencialmente, sem lote — 17.510 queries, ~5 minutos numa única execução.
2. ℹ️ Rate limit de login (10/min/IP) impede medir capacidade real de login a partir de uma
   máquina só — comportamento correto do rate limiter, não um bug.
3. ✅ `/items` sem gargalo nesta escala — 2-3 queries/request, p95 203ms sob 100 VUs.
4. 🔧 A própria instrumentação da TASK-234 tinha um bug sob concorrência (contador global vs.
   por-thread) — corrigido na mesma sessão, ver TASK-234.

### Verificação
`mvn test` 990/990. k6 realmente executado (não só escrito) contra a API local real, 3 rodadas de
`items-search.js` (uma inválida por sintaxe incompatível com o motor JS do k6, uma com o
instrumento ainda quebrado, uma final correta) + 1 rodada de `login.js` + 1 execução completa do
job de notificação. Container Docker e app derrubados ao final — nada persistiu.

## Status
🟢 Implementada e **executada de verdade** (não só escrita) — 1 achado crítico real, documentado
com causa raiz, evidência numérica e sugestão de correção (sem implementar, conforme escopo do
épico). Relatório final entregue.
