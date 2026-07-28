# EPIC-017 — Relatórios: Prestação de Contas (PDF) e Analítico (Excel)

## Status
**Concluído — 28/07/2026.** Todas as 6 tasks técnicas (TASK-145 a 150) implementadas e validadas;
QA manual (TASK-QA-MAN-012) executado e aprovado por Douglas — incluindo 2 achados incorporados
durante o próprio QA (TASK-149: seletor de organização inline na Prestação de Contas; TASK-150:
ocultar o menu "Relatórios" por completo quando o plano não inclui a funcionalidade, em vez de só
bloquear o botão). Suíte backend: 719/719 verde. Commitado e com PR aberto para `staging` em ambos
os repos (`easy-maintenance-api`, `easy-maintenance-web`).

## Objetivo
Evoluir a área de relatórios do "básico" que existe hoje (`/me/reports`: KPIs cross-org + tabela +
CSV) para dois relatórios com propósitos claramente diferentes:

1. **Relatório de Prestação de Contas** (novo) — PDF de uma organização por vez, pensado pra ser
   apresentado a terceiros (assembleia de condomínio, cliente, auditor/seguradora) como prova do que
   foi feito no período.
2. **Relatório Analítico** (evolução do existente) — Excel de verdade (não CSV), cross-org, dado cru
   pra quem quer analisar/calcular por conta própria (tabela dinâmica, etc.).

---

## Descrição

O relatório atual (`/me/reports`) resolve bem o caso "eu, dono de várias empresas, quero ver os
números consolidados", mas não resolve "eu preciso mostrar pra alguém de fora o que foi feito nesta
empresa". São necessidades diferentes o suficiente pra justificar dois produtos, não um relatório
único tentando servir aos dois.

**Decisão de escopo (Douglas, 27/07/2026):** evitar de propósito a ideia inicial de "níveis de
relatório" (auditor / controle interno / etc.) — começar com **um relatório de prestação de contas
configurável por filtros**, não vários templates fixos. Se no futuro um recorte específico for
necessário, vira um toggle de seções dentro do mesmo relatório, não um relatório novo.

**Decisão de escopo (Douglas, 27/07/2026):** o Excel analítico entrega **dado cru, uma linha por
manutenção** — sem abas de totais agregados nem fórmulas prontas. Tabela dinâmica é trabalho do
usuário no Excel dele, não responsabilidade do sistema.

---

## Regras de Negócio

- **RN-017-01:** o Relatório de Prestação de Contas é sempre de **uma organização por vez** — nunca
  cross-org (diferente do Analítico, que continua cross-org).
- **RN-017-02:** manutenções canceladas aparecem no Relatório de Prestação de Contas numa seção
  própria e explícita ("auditoria"), nunca misturadas com as realizadas — mesma filosofia de
  RN-016-05.
- **RN-017-03:** o Relatório Analítico nunca inclui manutenções canceladas (mesma regra já aplicada
  ao export CSV atual, TASK-139).
- **RN-017-04:** ambos os relatórios ficam atrás do plan feature `reportsEnabled` — mesmo gate já
  usado no export CSV hoje (`BillingPlanFeatures.reportsEnabled`, cujo comentário já previa
  "PDF/Excel report export available").
- **RN-017-05:** a geração do PDF é **client-side** (sem endpoint dedicado de "gerar PDF" no
  backend) — decisão de arquitetura para a v1; se um dia for necessário automatizar (relatório
  agendado, envio por e-mail), a geração migra pro backend nessa ocasião, não antes.

---

## Contexto Técnico

- `ReportsController` (`easy-maintenance-api/reports/infrastructure/web`) já expõe `/me/reports`
  cross-org: `GET /overview` (KPIs), `GET /maintenances` (listagem paginada), `GET
  /maintenances/export` (CSV, delega pra `MaintenanceExportService.exportCsvCrossOrg`). O Relatório
  Analítico desta task **evolui** `exportCsvCrossOrg`, não cria um endpoint novo.
- Colunas atuais do CSV: `ID, Empresa, Item, Data da Manutenção, Tipo, Responsável, Custo (R$),
  Próxima Data, Norma Aplicável, Categoria, Registrado por`. Novas colunas propostas: **Status do
  item** (reaproveita `StatusCalculator`, já usado em `MaintenanceService`) e **Qtd. de evidências
  anexadas** (reaproveita `MaintenanceAttachmentRepository.findByMaintenanceIdIn`, batch já
  construído na TASK-142 — não reintroduzir N+1 aqui).
- **Gap real identificado**: `GET /items/maintenances/cancelled` (TASK-139) só aceita `itemId`
  (uma manutenção cancelada de um item por vez) — não existe hoje uma forma de listar canceladas de
  **uma organização inteira num período**, que é o que a seção de auditoria do Relatório de
  Prestação de Contas precisa. Requer método novo em `MaintenanceRepository` (nativo, igual ao
  padrão de `findCancelledByItemId`, mas fazendo join com `maintenance_items` pra filtrar por
  `organization_code` + intervalo de `performed_at`) e endpoint novo/estendido.
- KPIs de item (em dia/vencido/próximo do vencimento) e a lista de itens pendentes já existem via
  `GET /items?status=X` (`ItemsController`) — sem necessidade de endpoint novo pra essa seção.
- Manutenções realizadas no período de uma org já existem via `GET /items/maintenances` com
  `performedAtFrom`/`performedAtTo` (`MaintenancesController`, escopado por `X-Org-Id`) — sem
  necessidade de endpoint novo pra essa seção também.
- Frontend: `easy-maintenance-web/src/app/reports/page.tsx` (734 linhas) é a tela atual — abriga o
  Relatório Analítico evoluído. O Relatório de Prestação de Contas é fluxo novo (nova rota ou nova
  aba dentro de `/reports`, a definir na task de frontend).
- Biblioteca de geração de PDF client-side (`@react-pdf/renderer` ou equivalente) ainda não existe
  no projeto — nova dependência do frontend.
- Biblioteca de geração de Excel real no backend (Apache POI ou equivalente) ainda não existe no
  projeto — nova dependência do backend.

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-145](../tasks/TASK-145.md) | Backend: listar manutenções canceladas de uma organização num período (auditoria) | BACKEND | 🟠 Alto |
| [TASK-146](../tasks/TASK-146.md) | Frontend: Relatório de Prestação de Contas — PDF de uma organização, 4 seções | FRONTEND | 🟠 Alto |
| [TASK-147](../tasks/TASK-147.md) | Backend: evoluir export cross-org de CSV para Excel (.xlsx) real, com novas colunas | BACKEND | 🟡 Médio |
| [TASK-148](../tasks/TASK-148.md) | Frontend: ajustar tela de Relatório Analítico para refletir export em Excel | FRONTEND | 🔵 Baixo |
| [TASK-149](../tasks/TASK-149.md) | Frontend: seletor de organização na aba Prestação de Contas (achado pós-TASK-146) | FRONTEND | 🟡 Médio |
| [TASK-150](../tasks/TASK-150.md) | Frontend: ocultar menu "Relatórios" quando o plano não inclui relatórios (achado no QA manual, C3) | FRONTEND | 🟡 Médio |
| [TASK-QA-MAN-012](../QA/tasks/TASK-QA-MAN-012.md) | QA Manual: E2E dos dois relatórios (Prestação de Contas em PDF + Analítico em Excel) | QA | 🟠 Alto |

Ordem sugerida: TASK-145 (endpoint de auditoria, pré-requisito) → TASK-146 (frontend do PDF, depende
do 145 e dos endpoints já existentes) → TASK-147/148 (Excel analítico, trilha independente, pode
andar em paralelo com 145/146) → TASK-149 (achado de UX depois de validar a TASK-146: seletor de
organização inline) → TASK-150 (achado do próprio QA manual, C3) → TASK-QA-MAN-012 (por último,
valida os dois relatórios ponta a ponta).

---

## Critério de Conclusão do Épico

- [x] Usuário consegue gerar um PDF de prestação de contas de uma organização específica, num
      período escolhido, com as 4 seções (resumo, realizadas, canceladas/auditoria, pendentes)
- [x] Usuário consegue exportar o Relatório Analítico em Excel (.xlsx) real, cross-org, com as
      colunas novas (status do item, qtd. de evidências)
- [x] Nenhum dos dois relatórios vaza manutenções canceladas fora da seção de auditoria dedicada
      (PDF) ou nunca as inclui (Excel)
- [x] Ambos os relatórios respeitam o gate `reportsEnabled` do plano — reforçado com TASK-150
      (menu oculto por completo, não só o botão bloqueado)
- [x] QA manual (TASK-QA-MAN-012) executada e aprovada

---

## Riscos

- Volume de dados: um PDF client-side com muitas manutenções/itens pode ficar pesado ou lento pra
  gerar no navegador — se isso aparecer no QA manual, considerar paginação/limite de período antes
  de escalar pra geração server-side (RN-017-05 já prevê essa porta de saída).
- A nova coluna "Qtd. de evidências anexadas" no Excel precisa reaproveitar o batch de
  `findByMaintenanceIdIn` (TASK-142) com cuidado — reintroduzir N+1 aqui numa exportação de até 5000
  linhas seria um problema de performance real, não teórico.
- Escopo do gap de auditoria (TASK-145) pode crescer se a query nativa de canceladas-por-org-e-
  período precisar dos mesmos cuidados multi-tenant já resolvidos na TASK-137/139 (org embutida na
  query, não checagem posterior).
