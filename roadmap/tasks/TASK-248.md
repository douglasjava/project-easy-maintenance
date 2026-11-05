# TASK-248 — BACKEND: Fila de ações + ações inline (adiar)

## Tipo
BACKEND

## Categoria
Dashboard / Compliance

## Prioridade
🟠 Alto

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Sim — confirmar ordenação exata da fila, que adiar sem motivo é rejeitado, e que o registro de
auditoria grava usuário/data/data-antiga/data-nova/motivo corretamente.

---

## Contexto

Renumerada de TASK-132 do documento original. Fila de trabalho priorizada — cada item carrega a
norma que exige aquele item (é a "história de conformidade" na tela).

## Escopo

- `GET /easy-maintenance/api/v1/dashboard/actions?limit=8` — fila priorizada.
- Cada entrada: `severity`, `reason` (`OVERDUE`/`DUE_SOON`/`MISSING_EVIDENCE`/`EXPIRED_DOCUMENT`),
  `norm`, `allowedActions`.
- Ordenação: `OVERDUE` desc por `daysOverdue` → `DUE_SOON` asc por `dueDate` →
  `MISSING_EVIDENCE` → `EXPIRED_DOCUMENT`.
- Reaproveitar endpoints existentes de completar manutenção/upload de evidência pras ações inline.
  Só falta `POST /dashboard/actions/{id}/postpone` (motivo obrigatório, grava auditoria).

## Critérios de Aceite

- [x] `norm` vem do registro de norma vinculado ao item; nunca hardcoded no serviço
- [x] Adiar grava entrada de auditoria (quem, quando, data antiga, data nova, motivo)
- [x] Entradas `MISSING_EVIDENCE` expõem só `ATTACH_EVIDENCE` em `allowedActions`

## Viabilidade Técnica

**Reaproveitável direto:**
- `AuditLog`/`AuditService`/`AuditAction` (`infrastructure/audit/`) já existem — o requisito
  "adiar grava auditoria" não precisa de infraestrutura nova, só um novo `AuditAction` (ex.
  `MAINTENANCE_ITEM_POSTPONED`) e a chamada no serviço.
- `norm` por item: `MaintenanceItem.normId` → `catalog_norms.domain.Norm` já é o caminho direto —
  não precisa hardcoded, o dado já está modelado exatamente como o critério de aceite pede.
- Endpoints de completar manutenção e upload de evidência (`MaintenanceAttachmentsController`)
  já existem — reaproveitar é literal, não estimativa.

**Não existe e depende de outra task:**
- `EXPIRED_DOCUMENT` como motivo de fila depende da entidade de documento que **não existe ainda**
  (mesmo achado da TASK-246). Sem ela, essa razão específica não tem query possível — a fila fica
  só com `OVERDUE`/`DUE_SOON`/`MISSING_EVIDENCE` até a entidade de documento existir.

**Requer cuidado extra:**
- `POSTPONE` muda `MaintenanceItem.nextDueAt` — precisa reusar a mesma lógica de recálculo de
  status já existente (`StatusCalculator`, usado em `DashboardService`) pra não deixar o item com
  `status` desatualizado até o próximo recálculo em lote.

## Dependências
Nenhuma bloqueante — a entidade `ItemDocument` já existia desde a TASK-246, então `EXPIRED_DOCUMENT`
pôde ser implementado nesta task também (o achado original de que dependia de outra task ficou
resolvido de graça).

## Riscos
Baixo — a maior parte reaproveita infraestrutura existente (auditoria, norma, evidência).

## Esforço
Pequeno-médio.

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `dashboard/infrastructure/persistence/DashboardActionsRepository.java` + `ActionQueueRow.java` | query nativa única com `UNION ALL` dos 4 motivos (`OVERDUE`/`DUE_SOON`/`MISSING_EVIDENCE`/`EXPIRED_DOCUMENT`), já com `JOIN` pra `norms`/`organizations` embutido — nenhum N+1 no Java. Ordenação via `reasonPriority`/`sortKey` calculados na própria query |
| `dashboard/application/DashboardActionsService.java` | `getActions` (mapeia severidade/`allowedActions` por motivo) + `postpone` (autoriza por item, não por escopo — item pertence a alguma organização que o usuário acessa) |
| `dashboard/application/dto/PostponeActionRequest.java` | `newDueDate` (`@FutureOrPresent`) + `reason` (`@NotBlank`) |
| `dashboard/infrastructure/web/dto/DashboardActionResponse.java` | DTO da resposta |
| `test/.../DashboardActionsServiceTest.java` | 8 testes: escopo vazio, `OVERDUE` sempre `CRITICAL`, `DUE_SOON` `CRITICAL` só dentro de 3 dias, `MISSING_EVIDENCE` só expõe `ATTACH_EVIDENCE`, adiar com motivo em branco rejeitado, item inexistente, item de organização que o usuário não acessa (mesma mensagem — não revela existência), adiamento válido atualiza o item e grava auditoria com data antiga/nova/motivo |

### Arquivos modificados
`dashboard/infrastructure/web/DashboardController.java` — novos `GET /dashboard/actions` e
`POST /dashboard/actions/{id}/postpone`.

### Decisões tomadas durante a implementação
- **`EXPIRED_DOCUMENT` implementado de verdade** — a entidade `ItemDocument` da TASK-246 já cobre
  isso; o achado original ("depende de entidade que não existe") ficou obsoleto assim que a
  TASK-246 foi feita antes desta. Só falta o endpoint de renovação/upload de documento pra essa
  razão ter uma ação de verdade em `allowedActions` — fica vazio (`[]`) até essa UI existir
  (fora do escopo desta task e do EPIC-030 como um todo, nenhuma das 9 tasks originais previa CRUD
  de documento).
- **Auditoria usa `AuditAction.UPDATE`, não uma ação nova** — o enum `AuditAction` existente
  (`CREATE`/`UPDATE`/`DELETE`/`LINK`/`UNLINK`/`LOGIN`/`LOGOUT`/`OTHER`) é genérico por design; o
  contexto específico ("foi um adiamento") vai no `diff` JSON (`action: "POSTPONE"`, `oldDueDate`,
  `newDueDate`, `reason`), não no nome da ação em si. Proposta original da task (criar
  `MAINTENANCE_ITEM_POSTPONED`) não seguia o padrão já estabelecido no resto do código.
- **Autorização do `postpone` é por item, não por escopo** — diferente de `/summary`/`/series`
  (que recebem `companyCode` e resolvem escopo antes de qualquer query), `postpone` recebe só o
  `id` do item; a organização dele só é conhecida depois de carregá-lo. Autorização acontece
  carregando o item via `TenantContext.runCrossOrg` e então checando se a organização dele está
  entre as que o usuário autenticado acessa — mesma mensagem genérica de "não encontrado" nos dois
  casos (item não existe / item existe mas é de outra organização), pelo mesmo motivo de nunca
  revelar existência cross-tenant já usado em `DashboardScopeResolver`.

### Verificação
- `mvn clean test` → **984/984, 0 falhas** (976 da TASK-247 + 8 testes novos desta task).
- Query nativa da fila de ações validada diretamente contra o MySQL real do docker local — os 4
  motivos, `JOIN`s com `norms`/`organizations`, e a ordenação (`OVERDUE` desc por `daysOverdue`)
  confirmados com dado real (6 itens `OVERDUE` retornados na ordem certa: 52, 27, 27, 27, 27, 14
  dias de atraso).

Branch `feature/EPIC-030-compliance-dashboard` (mesma do épico).

## Status
🟢 Implementado e testado (`mvn test` 984/984). Onda 1 (backend: TASK-246/247/248) completa.
