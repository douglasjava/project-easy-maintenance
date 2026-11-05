# TASK-164 — Backend: endpoint agregado `GET /admin/leads/summary`

## Tipo
BACKEND

## Categoria
Admin / Leads

## Prioridade
🟠 Alto

## Épico
[EPIC-021](../epics/EPIC-021.md) — Painel de Leads (visão agregada + mini-CRM de status)

## QA obrigatório
Sim — validar que a contagem mensal por status e o top de fontes/referrers batem com os dados
reais da tabela.

---

## Contexto

A visão agregada da página `/leads` precisa de: contagem de leads por mês (últimos 12) quebrada
por status, e top fontes/referrers do período. Segue o mesmo raciocínio do EPIC-020 (Financeiro):
volume de leads é baixo o suficiente pra buscar tudo numa query e agregar em Java, em vez de várias
queries agrupadas por mês em SQL.

---

## Objetivo

`GET /admin/leads/summary?months=12` retornando a série mensal por status + top fontes/referrers.

---

## Escopo

### 1. Repositório
- `LandingLeadRepository`: novo método `findAllByCreatedAtBetween(Instant start, Instant end)`.

### 2. Serviço `LeadsSummaryService` (ou equivalente)
- Busca todos os leads da janela de N meses (uma query).
- Agrega em Java: contagem por mês × status (preenchendo mês sem lead com zero em todos os
  status, mesmo cuidado da TASK-160 do EPIC-020); contagem por `source` (top N, ex. 10); contagem
  por `referrer` (top N, ex. 10).

### 3. Controller
- `GET /easy-maintenance/api/v1/private/admin/leads/summary?months=12` (default 12, mesmo clamp
  1-24 do endpoint de financeiro).
- Resposta: `{ monthly: [{ month, NEW, CONTACTED, CONVERTED, LOST }], topSources: [{ source,
  count }], topReferrers: [{ referrer, count }] }`.
- Mesmo padrão de autenticação do resto de `/admin/*`.

### 4. Testes
- Mês sem nenhum lead retorna zero em todos os status (não quebra, não pula o mês).
- Contagem por status bate com os dados de teste.
- Top fontes/referrers ordenados corretamente por contagem decrescente.

---

## Critérios de Aceite

- [x] Endpoint retorna 12 meses por padrão, ordenados do mais antigo ao mais recente
- [x] Contagem por status correta em cada mês
- [x] Top fontes e top referrers ordenados por contagem
- [x] Suíte de testes backend passa, sem regressão

**Desvio documentado**: campos do JSON viraram `newCount/contactedCount/convertedCount/lostCount`
em vez do literal `NEW/CONTACTED/CONVERTED/LOST` da descrição original — consistência de estilo
com `FinancialsDTO` (EPIC-020). Sem consumidor ainda (TASK-166 é a próxima), não quebra nada.

**Achado no teste**: `source`/`referrer` nulos ou em branco agora caem no bucket
"(direto/não informado)" em vez de aparecer como `null` na resposta.

## Dependências
- **TASK-163** — precisa do enum `LeadStatus` existir.

## Riscos
Baixo — mesmo padrão já validado no EPIC-020 (TASK-160).

## Esforço
Médio

## Status
Em Validação — implementado em `feature/EPIC-021-leads-dashboard`, commit `9360caa`. Falta QA
manual/PR.
