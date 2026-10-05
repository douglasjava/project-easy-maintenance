# EPIC-032 — Controle Financeiro Simples por Organização

## Status
Implementado (05/10/2026) — 8 tasks, seguindo o plano em
`docs/superpowers/plans/2026-10-04-financial-entries-plan.md`. Backend numa branch dedicada
(`feature/EPIC-032-financial-entries`, repos api/web): 20/20 testes passando
(`FinancialEntryPersistenceTest` + `FinancialEntryServiceTest`), suíte completa da API sem
regressão (1425/1425). Frontend: `tsc`/`eslint` limpos. E2E (teste de UI real,
`tests/frontend/finance-entries.spec.ts`) direto no `main` do repositório raiz — esse repo não usa
branch de feature/PR, commits de roadmap e e2e vão direto pra `main` (confirmado: nenhum PR nunca
foi aberto nele). Escrito e reconhecido pelo Playwright, mas **não executado contra API/banco
reais** nesta sessão — sem API/frontend local de pé (mesma limitação já documentada em outros specs
deste repositório). Rodar `npm run setup:db` + subir a API e o frontend antes de considerar
validado de verdade.

## Objetivo
Dar ao síndico um lugar pra lançar receitas e despesas da edificação que **não** são de
manutenção (ex.: taxa condominial recebida, salário de funcionário, conta de luz da área comum) —
hoje o produto só modela custo de manutenção (`Maintenance.costCents`, já automático), sem nenhum
registro de receita nem de despesa avulsa.

## Descrição

Módulo novo `finance`, isolado (`domain`/`application`/`infrastructure`, mesmo padrão de
`billing`/`assets`/`supplier`). Entidade única `FinancialEntry`: tipo (`REVENUE`/`EXPENSE`),
categoria fixa definida pelo backend (4 por tipo), valor, descrição opcional, data. Nunca editado
depois de criado — só cancelado com motivo obrigatório (soft-delete auditável, mesmo padrão de
`Maintenance.cancel`/TASK-137).

Tela nova `/financeiro` pra lançar/listar/cancelar. A Prestação de Contas (`/reports`, aba
"Prestação de Contas", já existente desde EPIC-017) passa a mostrar Receitas, Despesas Manuais e
Saldo do período, ao lado do Custo de Manutenção que já era automático — sem duplicar nada, o
endpoint de resumo (`GET /finance/summary`) soma os lançamentos manuais e reaproveita a query de
custo de manutenção que já existia (`MaintenanceRepository.sumCostCentsByOrgsInAndPerformedBetween`).

**Decisão importante**: v1 é um livro-caixa simples — sem conciliação bancária, sem contas a pagar
com vencimento/parcelamento, sem integração bancária. Liberado pra todas as organizações, sem gate
de plano de billing.

---

## Contexto Técnico

- Custo de manutenção já é automático (`Maintenance.costCents`) — nunca lançado manualmente neste
  módulo, evita contagem dupla.
- Permissão de criar/cancelar: `Role.ADMIN`/`Role.SYNDIC`, mesmo padrão de
  `MaintenanceService.requireCancelPermission`. Leitura liberada pra qualquer papel autenticado da
  organização.
- Tenant scoping explícito (`organizationCode` passado em toda query/método), não automático —
  o `TenantFilterAspect` de Hibernate é restrito só a `MaintenanceItemRepository`; este módulo
  segue o mesmo padrão explícito que `MaintenanceRepository` já usa.
- Precedente de módulo isolado por domínio é o padrão do projeto.

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-322](../tasks/TASK-322.md) | Backend: FinancialEntry — domain, migration V122, repository | BACKEND | 🟠 Alto |
| [TASK-323](../tasks/TASK-323.md) | Backend: FinancialEntryService (criar/cancelar/listar/resumir) | BACKEND | 🟠 Alto |
| [TASK-324](../tasks/TASK-324.md) | Backend: endpoints REST /finance | BACKEND | 🟠 Alto |
| [TASK-325](../tasks/TASK-325.md) | Frontend: tela /financeiro | FRONTEND | 🟠 Alto |
| [TASK-326](../tasks/TASK-326.md) | Frontend: integração com Prestação de Contas | FRONTEND | 🟠 Alto |
| [TASK-327](../tasks/TASK-327.md) | Frontend: item "Financeiro" no menu | FRONTEND | 🟡 Médio |
| [TASK-328](../tasks/TASK-328.md) | QA: E2E fluxo completo do módulo financeiro | QA | 🟠 Alto |
| [TASK-329](../tasks/TASK-329.md) | Roadmap: documentação do épico | INFRA / CONFIG | 🔵 Baixo |

Ordem: TASK-322 → 323 → 324 (backend, sequencial — cada um consome o anterior). TASK-325 depende
de TASK-324 (endpoints prontos). TASK-326/327 podem andar em paralelo com TASK-325. TASK-328
depende de tudo anterior (exercita o fluxo ponta a ponta). TASK-329 é a própria documentação.

---

## Critério de Conclusão do Épico

- [x] Síndico lança receita/despesa manual via `/financeiro`, com categoria validada contra o tipo
- [x] Lançamento nunca editado — só cancelado com motivo obrigatório, auditável
- [x] Permissão `ADMIN`/`SYNDIC` pra criar/cancelar; leitura liberada pra qualquer papel
- [x] Prestação de Contas mostra Receitas/Despesas Manuais/Saldo, sem duplicar custo de manutenção
- [x] `mvn test` sem regressão (1425/1425); `tsc`/`eslint` do frontend limpos
- [ ] E2E validado contra API/banco reais (escrito e reconhecido pelo Playwright; execução real
      pendente — precisa de `npm run setup:db` + API local de pé)

---

## Fora de Escopo

- Conciliação bancária, contas a pagar com vencimento/parcelamento, integração bancária/open finance.
- Edição de lançamento existente (só cancelamento + novo lançamento).
- Gate por plano de billing.
- Categorias customizáveis pelo usuário.
- Anexo de comprovante no lançamento.

## Riscos
Baixo pro restante do sistema — módulo novo, isolado, sem alterar entidade/fluxo existente além da
leitura adicional (aditiva) em `PrestacaoContasSection`/PDF. Risco próprio do épico: dado financeiro
sensível sem edição — mitigado pela decisão de nunca editar, só cancelar com motivo.
