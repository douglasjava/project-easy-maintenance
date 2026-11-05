# EPIC-016 — Cancelamento de Manutenções com Motivo (correção sem perda de histórico)

## Status
**Concluído — 27/07/2026.** Todas as 9 tasks técnicas (TASK-137 a 144) implementadas e validadas;
QA manual (TASK-QA-MAN-011) executado e aprovado por Douglas, incluindo 3 bugs reais achados e
corrigidos durante o próprio QA (ver TASK-137 — persistência dos campos de cancelamento, constraint
UNIQUE que bloqueava reaproveitar o dia após cancelar, checagem de duplicidade do `register()`
usando a data errada) e 1 correção de UX (TASK-144, histórico de manutenções movido pra página do
item). Suíte backend: 713/713 verde. Commitado e com PR aberto para `staging` em ambos os repos
(`easy-maintenance-api`, `easy-maintenance-web`).

## Objetivo
Dar ao usuário uma forma de corrigir um cadastro de manutenção incorreto (item errado, data errada,
tipo errado) **sem editar ou apagar o registro original** — a correção acontece via cancelamento com
motivo obrigatório, preservando o histórico completo para fins de compliance/auditoria, seguido do
recadastro da manutenção correta.

---

## Descrição

Hoje `MaintenancesController` só tem `POST` (registrar) e `GET` (ler/listar/exportar) — **não existe
nenhuma forma de corrigir um erro de cadastro de manutenção**. Isso foi descoberto testando em
produção: ao tentar corrigir um registro para anexar documentação, não havia nem edição nem
cancelamento disponível.

O problema é mais sério do que parece à primeira vista: `MaintenanceService.register()` recalcula
**imediatamente** `nextDueAt`, `lastPerformedAt` e `status` do item a partir da manutenção
registrada. Ou seja, um cadastro errado já contamina o cronograma de compliance do item na hora, sem
nenhum caminho de volta hoje.

A entidade `Maintenance` já tem soft-delete pronto (`@SQLDelete` + `@SQLRestriction("deleted_at IS
NULL")`) e colunas de auditoria (`createdBy`/`updatedBy`), mas nenhum endpoint aciona isso.

**Decisão de produto (validada com Douglas, 25/07/2026):** a correção é por **cancelamento com
motivo**, nunca por edição direta dos campos da manutenção. Um auditor deve sempre conseguir ver que
existiu um erro, quando foi corrigido, por quem e por quê — em vez de um histórico reescrito
silenciosamente. Isso é consistente com a trava que já existe para o item (`RN-001`: item com
manutenção não pode ser editado).

---

## Regras de Negócio

- **RN-016-01:** Cancelar uma manutenção exige motivo obrigatório (texto livre).
- **RN-016-02:** Cancelamento é sempre soft-delete — o registro nunca é apagado fisicamente.
- **RN-016-03:** Após cancelar, o item recalcula `nextDueAt`/`lastPerformedAt`/`status` a partir da
  manutenção válida (não cancelada) **mais recente por `performedAt`** — não necessariamente a
  próxima que for cadastrada depois, para cobrir corretamente o caso de já existir uma manutenção
  válida posterior à que está sendo cancelada.
- **RN-016-04:** Se não sobrar nenhuma manutenção válida após o cancelamento, o item volta ao estado
  "sem manutenção registrada" (mesmo estado anterior à primeira manutenção já cadastrada).
- **RN-016-05:** Manutenções canceladas continuam consultáveis na tela do item, mas sempre separadas
  /marcadas — nunca misturadas silenciosamente com as válidas.
- **RN-016-06:** Não é possível cancelar uma manutenção que já está cancelada (idempotência).
- **RN-016-07:** Apenas papéis com permissão de gestão (ADMIN/SYNDIC) podem cancelar — TECH não deve
  ter esse poder (a confirmar o mecanismo exato de enforcement durante a TASK-137).

---

## Contexto Técnico

- `assets/domain/Maintenance.java` — já tem `@SQLDelete(sql = "UPDATE maintenances SET deleted_at =
  now() WHERE id = ?")` + `@SQLRestriction("deleted_at IS NULL")`. Isso significa que **toda query
  JPA padrão já filtra canceladas automaticamente** — a view de "mostrar canceladas" (TASK-139)
  precisa contornar essa restrição de forma explícita (Hibernate `@Filter` toggle, query nativa, ou
  método de repositório dedicado), com cuidado para não vazar canceladas em outras queries que não
  deveriam mostrá-las (export CSV, KPIs do dashboard, listagem padrão).
- `assets/application/service/MaintenanceService.java#register()` (linhas ~55-85) é o método que
  recalcula `nextDueAt`/`lastPerformedAt`/`status` do item — a lógica de recálculo do cancelamento
  (TASK-138) deve reaproveitar as mesmas peças (`serviceBase.resolvePeriod(item)`,
  `StatusCalculator.calculate(...)`), só aplicadas sobre a manutenção válida mais recente em vez da
  recém-registrada.
- `Maintenance` não tem hoje nenhuma coluna pra guardar o motivo do cancelamento —
  `deleted_at`/`updated_by` existem mas não guardam "por quê". Precisa de migration nova (próxima
  disponível: **V84**, a mais recente hoje é V83).
- `MaintenanceResponse` (DTO de retorno) e os endpoints `GET /maintenances/{id}` e `GET
  /maintenances` não expõem hoje nenhum indicativo de cancelamento — precisa de campo novo
  (`cancelled`/`cancelReason`/`cancelledAt`/`cancelledBy`).
- Frontend: tela em `easy-maintenance-web/src/app/maintenances/page.tsx` é onde hoje se vê o detalhe
  de uma manutenção (`maintDetail`) e os anexos — é o lugar natural pra adicionar a ação de cancelar
  e a exibição de canceladas.

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-137](../tasks/TASK-137.md) | Backend: endpoint de cancelamento de manutenção com motivo obrigatório | BACKEND | 🟠 Alto |
| [TASK-138](../tasks/TASK-138.md) | Backend: recálculo de nextDueAt/lastPerformedAt/status do item após cancelamento | BACKEND | 🟠 Alto |
| [TASK-139](../tasks/TASK-139.md) | Backend: expor manutenções canceladas na consulta/detalhe do item | BACKEND | 🟡 Médio |
| [TASK-140](../tasks/TASK-140.md) | Frontend: ação "Cancelar manutenção" com modal de motivo obrigatório | FRONTEND | 🟠 Alto |
| [TASK-141](../tasks/TASK-141.md) | Frontend: exibir manutenções canceladas na tela do item | FRONTEND | 🟡 Médio |
| [TASK-142](../tasks/TASK-142.md) | Backend: resolver autor de cada anexo de manutenção (rastreabilidade de evidência) | BACKEND | 🟡 Médio |
| [TASK-143](../tasks/TASK-143.md) | Frontend: permitir anexar evidência a manutenções existentes, exibindo autor e data | FRONTEND | 🟡 Médio |
| [TASK-144](../tasks/TASK-144.md) | Frontend: histórico de manutenções (ativas e canceladas) na página de detalhe do item | FRONTEND | 🟡 Médio |
| [TASK-QA-MAN-011](../QA/tasks/TASK-QA-MAN-011.md) | QA Manual: E2E cancelamento de manutenção + recálculo de compliance | QA | 🟠 Alto |

Ordem sugerida: TASK-137 (endpoint + migration) → TASK-138 (recálculo, depende do 137 existir) →
TASK-139 (exposição de canceladas, pode andar em paralelo com o 138) → TASK-140/141 (frontend,
dependem dos endpoints do 137/139) → TASK-142/143 (anexo tardio, independente do resto — pode andar
em paralelo desde o início) → TASK-144 (achado de UX durante o QA manual, C1/C2) → TASK-QA-MAN-011
(por último, valida tudo ponta a ponta).

**Decisão de produto adicional (Douglas, 25/07/2026):** anexar evidência a uma manutenção depois de
registrada **não** fere compliance, diferente de editar a manutenção em si — nenhum fato muda, só a
documentação de apoio é completada, desde que fique visível *quando* e *por quem* foi anexado
(`MaintenanceAttachment.uploadedAt`/`uploadedByUserId` já existem no banco, só não são expostos ao
usuário hoje — TASK-142/143 resolvem isso). Ficou como **decisão em aberto, fora do escopo deste
épico**: se vale travar o quanto `performedAt` pode ser retroativo em relação ao momento real do
registro (`createdAt`), para dificultar o cenário de alguém registrar a manutenção tardiamente mas
alegando ter sido feita na data de vencimento original — precisa de definição de produto sobre qual
janela seria razoável antes de virar task.

---

## Critério de Conclusão do Épico

- [x] Usuário consegue cancelar uma manutenção informando motivo obrigatório
- [x] Manutenção cancelada nunca é apagada fisicamente (soft-delete)
- [x] Após cancelar, `nextDueAt`/`lastPerformedAt`/`status` do item são recalculados a partir da
      manutenção válida mais recente
- [x] Sem manutenção válida remanescente, item volta ao estado "sem manutenção registrada"
- [x] Manutenções canceladas ficam visíveis (separadas, com motivo/autor/data) — na página de
      detalhe do item (TASK-144, home definitivo) e em `/maintenances` (TASK-139/141)
- [x] Apenas papéis autorizados (ADMIN/SYNDIC) podem cancelar
- [x] Não é possível cancelar uma manutenção já cancelada
- [x] Testes automatizados cobrindo happy path + edge cases (sem remanescente, múltiplas
      manutenções fora de ordem, permissão negada) — 713/713 backend green
- [x] Usuário consegue anexar evidência a uma manutenção já registrada, com autor e data visíveis
- [x] QA manual (TASK-QA-MAN-011) executada e aprovada

---

## Riscos (do épico como um todo)

- Contornar `@SQLRestriction("deleted_at IS NULL")` pra exibir canceladas é o ponto tecnicamente mais
  delicado — se malfeito, risco de vazar manutenções canceladas em queries que não deveriam
  considerá-las (export CSV, KPIs do dashboard, cálculo de status de outros itens).
- Recalcular `nextDueAt` errado no cancelamento volta a corromper o compliance do item exatamente no
  cenário que este épico existe pra resolver — cobertura de teste do recálculo é crítica, não
  opcional.
- Mecanismo exato de restrição por papel (ADMIN/SYNDIC) ainda não confirmado no código — não há
  `@PreAuthorize` em uso hoje nos controllers de assets; validar o padrão de enforcement correto
  durante a TASK-137 antes de assumir uma implementação.
