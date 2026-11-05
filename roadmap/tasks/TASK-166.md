# TASK-166 — Frontend: item "Leads" no menu + visão agregada

## Tipo
FRONTEND

## Categoria
Admin / Leads

## Prioridade
🟠 Alto

## Épico
[EPIC-021](../epics/EPIC-021.md) — Painel de Leads (visão agregada + mini-CRM de status)

## QA obrigatório
Sim — validar visualmente o gráfico empilhado e as tabelas de top fontes/referrers com dado real.

---

## Contexto

Não existe hoje nenhum item "Leads" no menu admin, nem nenhuma tela consumindo o endpoint agregado
da TASK-164. Reaproveita o Recharts já instalado no EPIC-020 (não precisa de lib nova).

---

## Objetivo

Nova rota `/private/admin/leads` com o bloco de visão agregada: gráfico empilhado + top
fontes/referrers.

---

## Escopo

### 1. Navegação
- `src/components/Sidebar.tsx` (`adminItems`): novo item `{ href: "/private/admin/leads", label:
  "Leads", section: "admin" }`, ao lado de "Faturamento" e "Afiliados".

### 2. `src/app/private/admin/leads/page.tsx`
- Busca `GET /private/admin/leads/summary?months=12` no mount.
- Gráfico Recharts empilhado (barras), 12 meses, 4 séries (uma por `LeadStatus`).
- Duas tabelas lado a lado: "Top fontes" e "Top referrers" (nome + contagem, ordenado
  decrescente).
- Mesmo padrão visual/estrutural das páginas de billing admin (`"use client"`, `isMounted` guard,
  skeleton no loading, paleta de cores local, `toast.error` em falha).

### 3. Testes
- Sem infraestrutura de teste de componente React neste projeto (limitação já registrada) —
  validar via build/lint + teste manual com dado real do endpoint.

---

## Critérios de Aceite

- [x] Item "Leads" aparece no menu admin
- [x] `/private/admin/leads` acessível só pelo admin (mesmo padrão de auth do resto de `/private/admin/*` — sem guard próprio na página, igual à página de afiliados: `BootstrapAdminFilter` no backend + interceptor do `apiClient` redireciona para `/private/login` em 401)
- [x] Gráfico mostra os 12 meses empilhados por status
- [x] Tabelas de top fontes/referrers mostram contagem correta
- [x] `npm run build` limpo

**QA manual**: não foi possível validar visualmente com dado real — mesmo bloqueio já registrado nas
TASK-161/162 (subir o backend local exige `OPENAI_API_KEY`/`DEEPSEEK_API_KEY` reais, além do
Postgres). Validado via `npm run build` (rota gerada como estática, sem erro de TypeScript) e
revisão de código contra o contrato da `LeadsSummaryDTO` (TASK-164). Fica pendente teste manual
com dado real por Douglas.

## Dependências
- **TASK-164** — precisa do endpoint agregado existir.

## Riscos
Baixo — Recharts já instalado (EPIC-020), mesmo padrão visual já validado.

## Esforço
Médio

## Status
Em Validação — branch `feature/EPIC-021-leads-dashboard`, commit `3a7a69a` (easy-maintenance-web). QA manual com dado real pendente.
