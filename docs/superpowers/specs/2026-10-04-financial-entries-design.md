# EPIC-032 — Controle Financeiro Simples por Organização (Lançamentos de Receita/Despesa)

**Data:** 04/10/2026
**Status:** Aprovado por Douglas (brainstorm conduzido nesta data)

## Motivação

Feedback de clientes reais em conversas recentes: falta um lugar pra registrar receitas (ex.: taxa
condominial recebida) e despesas que não são de manutenção (ex.: salário de funcionário, conta de
luz da área comum). O custo de manutenção em si **já é automático** (`Maintenance.costCents`,
preenchido no registro de cada manutenção e somado hoje em `PrestacaoContasSection.tsx` e no KPI do
dashboard via `MaintenanceRepository`) — o que falta é só o resto do fluxo de caixa da edificação.

Avaliado antes de desenhar (ver conversa de 02-04/10/2026, TASK-321 e investigação de produto
subsequente): a entidade `Expense` que já existe (`billing/domain/financials/Expense.java`) é o
financeiro **interno do próprio SaaS** (receita de assinatura menos custo operacional), exposta só
em `/private/admin/financials` — não serve pra isso, é outro domínio. Confirmado por grep que não
existe nenhuma entidade de "lançamento financeiro por organização" no sistema hoje.

**Fora de escopo deliberado:** isso não é um sistema de contabilidade — sem conciliação bancária,
sem contas a pagar com vencimento/parcelamento, sem integração com banco. É um livro-caixa simples:
lançar receita/despesa, ver o saldo do período, pronto.

## Contexto (levantado antes do desenho)

- `MaintenanceItem`/demais entidades de `assets` usam `@Filter(name = "tenantFilter", condition =
  "organization_code = :org_code")` com coluna `organization_code` — mecanismo de tenant scoping
  automático já estabelecido, reaproveitado aqui sem mudança.
- `MaintenanceService.cancel` estabelece o padrão de "nunca editar um registro sensível, só cancelar
  com motivo (soft-delete auditável) e lançar de novo" — mesmo padrão adotado aqui pra lançamentos
  financeiros, por serem dado sensível.
- `MaintenanceRepository.sumCostCentsByOrgsInAndPerformedBetween` já soma `costCents` por
  organização(ões) e período (usada hoje pelo KPI `monthlyCost` do dashboard, EPIC-030/TASK-246) —
  o endpoint de resumo financeiro **reaproveita essa query existente**, não duplica a lógica.
- Precedente de módulo isolado por domínio é o padrão do projeto (`billing`, `assets`, `supplier`,
  `resident_tickets`, `catalog_norms`, `assistant` — cada um com `domain`/`application`/
  `infrastructure` próprios). Módulo novo aqui: `finance`.
- `PrestacaoContasSection.tsx`/`PrestacaoContasPdfDocument.tsx` (EPIC-017, aba "Prestação de Contas"
  em `/reports`) já existem e hoje calculam `totalCostCents` só a partir das manutenções do período
  — ponto de integração final deste épico, não ponto de partida (não se reescreve do zero).

## Decisões de escopo (brainstorm, 04/10/2026)

1. **Permissão: `ADMIN`/`SYNDIC` da organização só para criar e cancelar**, mesma regra já usada em
   `MaintenanceService.requireCancelPermission` pra outras ações sensíveis. **Leitura (listagem e
   resumo) liberada pra qualquer membro autenticado da organização** — consistente com o resto de
   `/reports` hoje, que não tem gate de papel no controller, só o filtro de tenant (`X-Org-Id`)
   padrão.

2. **Categoria fixa simples** (enum), diferente por tipo:
   - Receita: `TAXA_CONDOMINIAL`, `MULTA`, `ALUGUEL_ESPACO`, `OUTRAS_RECEITAS`.
   - Despesa: `FOLHA_PAGAMENTO`, `CONTA_CONSUMO`, `SERVICO_TERCEIRO`, `OUTRAS_DESPESAS`.
   - Manutenção **não** é categoria aqui — continua exclusivamente automática via `Maintenance.
     costCents`, nunca lançada manualmente neste módulo (evita contagem dupla).

3. **Sem edição — só cancelamento com motivo.** Lançamento criado é imutável; para corrigir, cancela
   (motivo obrigatório, soft-delete auditável — `canceledAt`/`canceledBy`/`cancelReason`) e cria um
   novo. Mesmo padrão de `Maintenance.cancel`. Não pode cancelar duas vezes (409).

4. **Sem gate de plano.** Liberado pra todas as organizações, independente do plano de billing —
   decisão explícita de não usar `BillingPlanFeatures` aqui por ora.

5. **Validações de negócio:**
   - Valor deve ser positivo (`amountCents > 0`).
   - Data do lançamento não pode ser futura (mesmo princípio de `Maintenance.performedAt`).
   - Categoria deve pertencer ao tipo escolhido (`REVENUE` só aceita categorias de receita, e
     vice-versa) — 422 se não bater.

---

## Arquitetura

Módulo novo `finance`, seguindo a estrutura `domain`/`application`/`infrastructure` já padrão no
projeto. Não reaproveita nem estende `Maintenance`/`assets` (domínio diferente — risco de acoplar
lançamento financeiro livre a uma entidade fortemente ligada a normas/conformidade) nem o módulo
`billing` (que é sobre a assinatura do SaaS, não sobre a vida financeira do condomínio).

### Entidade: `FinancialEntry`

| Campo | Tipo | Observação |
|---|---|---|
| `id` | Long | PK |
| `organizationCode` | String | Tenant scoping, `@Filter` igual `MaintenanceItem` |
| `type` | enum `FinancialEntryType` | `REVENUE` / `EXPENSE` |
| `category` | enum `FinancialEntryCategory` | Validada contra `type` no service |
| `amountCents` | Integer | > 0 |
| `description` | String | Livre, opcional |
| `entryDate` | LocalDate | Não pode ser futura |
| `createdBy` | Long (userId) | |
| `createdAt` | Instant | `@CreationTimestamp` |
| `canceledAt` | Instant | Nulo = ativo |
| `canceledBy` | Long (userId) | Nulo = ativo |
| `cancelReason` | String | Obrigatório só no cancelamento |

### Componentes

- `FinancialEntryRepository` — CRUD + query de soma por tipo/período/org (para o resumo).
- `FinancialEntryService` — `create`, `cancel`, `listByPeriod`, `summarize`. Permissão e validações
  de negócio centralizadas aqui (mesmo padrão de `MaintenanceService`).
- `FinancialEntryController` — `/easy-maintenance/api/v1/finance`:
  - `POST /finance/entries` — criar.
  - `GET /finance/entries?start=&end=&type=` — listar, paginado.
  - `POST /finance/entries/{id}/cancel` — cancelar (body: `{ reason }`).
  - `GET /finance/summary?start=&end=` — `{ totalRevenueCents, totalManualExpenseCents,
    totalMaintenanceExpenseCents, balanceCents }` — combina soma de `FinancialEntry` (ativo, por
    tipo) com a soma já existente de `Maintenance.costCents` via `MaintenanceRepository`.

### Frontend

- Tela nova `/financeiro` — lista de lançamentos (filtro por período/tipo), botão "Novo lançamento"
  (modal: tipo → categoria filtrada pelo tipo → valor → descrição → data), ação "Cancelar" por linha
  (reaproveita o padrão visual de `ConfirmModal` já usado em billing/manutenções).
- `PrestacaoContasSection.tsx` passa a chamar `GET /finance/summary` além do que já busca hoje, e
  exibe/soma: Receitas, Despesas de Manutenção (automático, inalterado), Despesas Manuais, Saldo.
- `PrestacaoContasPdfDocument.tsx` ganha essas linhas novas no PDF exportado.

---

## Fluxo de dados

1. `ADMIN`/`SYNDIC` acessa `/financeiro`, escolhe tipo → categoria filtra pelo tipo → preenche
   valor/descrição/data → `POST /finance/entries`.
2. `FinancialEntryService.create` valida permissão, compatibilidade categoria×tipo, valor positivo,
   data não futura → persiste.
3. `GET /finance/summary` soma `FinancialEntry` ativo (não cancelado) por tipo no período + reutiliza
   a query existente de `MaintenanceRepository` para despesa de manutenção → compõe o DTO de saldo.
4. Cancelamento: `POST /finance/entries/{id}/cancel` com motivo obrigatório; 409 se já cancelado.

## Erros

| Código | Caso |
|---|---|
| 403 | Usuário sem papel `ADMIN`/`SYNDIC` tentando criar/cancelar |
| 422 | Categoria incompatível com o tipo, valor ≤ 0, data futura |
| 409 | Cancelar lançamento já cancelado |
| 404 | Lançamento não encontrado (inclui de outra organização — coberto pelo filtro de tenant) |

## Testes

- `FinancialEntryServiceTest` — criação feliz (receita e despesa), categoria incompatível, permissão
  negada, cancelamento, cancelamento duplicado, data futura, valor zero/negativo.
- Teste de `summarize` — soma correta combinando `FinancialEntry` + `Maintenance.costCents`,
  confirmando que lançamento cancelado **não** entra na soma.
- Frontend: fluxo de criar/listar/cancelar em `/financeiro`; `PrestacaoContasSection` exibindo os
  totais novos.
- Regressivo: organizações sem nenhum `FinancialEntry` continuam mostrando a prestação de contas
  igual a hoje (saldo = só despesa de manutenção, receita e despesa manual = zero).

---

## Fora de Escopo

- Conciliação bancária, contas a pagar com vencimento/parcelamento, integração com banco/open
  finance.
- Edição de lançamento existente (só cancelamento + novo lançamento).
- Gate por plano de billing (liberado pra todas as organizações nesta v1).
- Categorias customizáveis pelo usuário (lista fixa, backend-defined).
- Anexo de comprovante no lançamento (ex.: nota fiscal da conta de luz) — não pedido nesta rodada;
  se vier a ser necessário, reaproveitaria o mesmo padrão de `MaintenanceAttachment`/S3 já existente.

## Riscos

Baixo pro restante do sistema — módulo novo, isolado, sem alterar entidade/fluxo existente além da
leitura adicional em `PrestacaoContasSection`/PDF (aditiva, não quebra organizações sem lançamentos).
Risco próprio do épico: é dado financeiro sensível sem auditoria de edição (mitigado pela decisão de
nunca editar, só cancelar com motivo).
