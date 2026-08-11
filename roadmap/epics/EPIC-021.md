# EPIC-021 — Painel de Leads (visão agregada + mini-CRM de status)

## Status
Em Validação — todas as 5 tasks implementadas (TASK-163 a TASK-167), branches
`feature/EPIC-021-leads-dashboard` em ambos os repos, ainda não abertas PRs pra `staging`. QA
manual com dado real pendente por Douglas (mesmo bloqueio de secrets locais registrado nas
TASK-166/167). Desenhado via brainstorm com Douglas em 11/08/2026, spec aprovada em
`docs/superpowers/specs/2026-08-11-painel-leads-design.md`.

## Objetivo
Dar visibilidade de quantos leads chegam pela landing, de onde vêm (fonte/referrer), e um fluxo
mínimo de status pra acompanhar o funil manualmente — hoje o EPIC-018 captura o lead
(`landing_leads`) mas não existe nenhuma tela de admin pra ver isso, e o campo `status` é uma
`String` livre sem workflow: todo lead nasce e fica `"NEW"` pra sempre.

## Descrição

Novo item de topo **"Leads"** no menu admin (mesmo nível de Faturamento/Afiliados),
`/private/admin/leads`, com dois blocos:

1. **Visão agregada**: gráfico empilhado dos últimos 12 meses, contagem de leads por status
   (mesmo padrão visual Recharts do EPIC-020). Abaixo, duas tabelas — top fontes (`source`) e top
   referrers por contagem no período (tabela, não gráfico, porque `referrer` pode ter muitos
   valores distintos e um gráfico com muitas séries fica ilegível).
2. **Lista individual de leads**: tabela paginada e filtrável (status, fonte, campanha — todos por
   **igualdade exata**, sem `LIKE`; e período), com um seletor de status por linha que salva na
   hora — é o que torna a troca de status possível na prática (vira um mini-CRM básico, não só
   dashboard).

**Mudança de modelo**: `LandingLead.status` (hoje `String` livre) vira um enum de verdade —
`NEW → CONTACTED → CONVERTED / LOST`. Migração sem transformação de dado necessária, porque todo
valor existente já é `"NEW"`, um valor válido do novo enum.

---

## Contexto Técnico

- `LandingLead` (`leads/domain/LandingLead.java`) já tem `source`, `medium`, `campaign`,
  `referrer`, `affiliateCode`, `landingPath`, `utmJson`, `status`, `consentAcceptedAt`,
  `createdAt` — captura pronta desde o EPIC-018, só falta a visualização/gestão admin.
- `LandingLeadRepository` hoje só tem 2 métodos (`findFirstByEmailAndAffiliateCodeIsNotNull`,
  `findAllByAffiliateCode`), usados pelo fluxo de afiliados — nenhuma consulta agregada ou
  paginada existe ainda.
- Nenhum controller admin de leads existe hoje — é 100% capacidade nova, não uma extensão de algo
  existente.
- Mesmo padrão de `Specification` já usado em `PaymentRepository` (`hasStatus`, `hasProvider`,
  `createdBetween`) deve ser reaproveitado pros filtros da lista (`hasStatus`, `hasSource`,
  `hasCampaign`, `createdBetween`).
- `Sidebar.tsx` (`adminItems`) é onde entra o item novo "Leads", ao lado de "Faturamento" e
  "Afiliados".

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-163](../tasks/TASK-163.md) | Backend: `LandingLead.status` de `String` livre pra enum `LeadStatus` | BACKEND | 🟠 Alto |
| [TASK-164](../tasks/TASK-164.md) | Backend: endpoint agregado `GET /admin/leads/summary` (mensal por status + top fontes/referrers) | BACKEND | 🟠 Alto |
| [TASK-165](../tasks/TASK-165.md) | Backend: `GET /admin/leads` (lista paginada/filtrável) + `PATCH /admin/leads/{id}/status` | BACKEND | 🟠 Alto |
| [TASK-166](../tasks/TASK-166.md) | Frontend: item "Leads" no menu + visão agregada (gráfico + top fontes/referrers) | FRONTEND | 🟠 Alto |
| [TASK-167](../tasks/TASK-167.md) | Frontend: lista individual de leads — filtros + troca de status inline | FRONTEND | 🟠 Alto |

Ordem: TASK-163 primeiro (TASK-164 e TASK-165 dependem do enum existir) → TASK-164 e TASK-165 podem
andar em paralelo (endpoints independentes) → TASK-166 (depende do endpoint agregado da TASK-164)
→ TASK-167 (depende do endpoint de lista da TASK-165 e da página já existir, TASK-166).

---

## Critério de Conclusão do Épico

- [x] `/private/admin/leads` acessível só pelo admin, item novo no menu
- [x] Gráfico mostra os últimos 12 meses de leads, empilhado por status
- [x] Tabelas de top fontes e top referrers mostram contagem correta do período
- [x] Lista individual filtra por status/fonte/campanha (igualdade exata) e período
- [x] Troca de status por linha salva de verdade (persiste; reflexo na visão agregada depende de
      recarregar a página — os dois blocos buscam dados independentemente, não há refresh cruzado
      automático, comportamento aceito pois não foi um critério explícito de nenhuma task)
- [x] `npm run build` (frontend) e suíte de testes (backend) sem regressão

Falta apenas: QA manual com dado real (Douglas) e abertura dos PRs `feature/EPIC-021-leads-dashboard` → `staging` em ambos os repos.

---

## Fora de Escopo

- Filtro/breakdown por `medium`.
- Qualquer automação disparada por mudança de status (e-mail, notificação).
- Edição de outros campos do lead além do status.
- Exportação (CSV) da lista.

## Riscos
Baixo — extensão aditiva, não altera nenhum fluxo de captura de lead já existente (EPIC-018). Único
ponto de atenção: a migração do campo `status` de `String` pra enum precisa confirmar que não há
nenhum valor fora do enum já gravado em produção antes de aplicar (mitigação: todo lead até hoje é
criado com `"NEW"` fixo no `LeadService`, não há caminho pra outro valor existir).
