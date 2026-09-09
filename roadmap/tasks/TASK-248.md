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

- [ ] `norm` vem do registro de norma vinculado ao item; nunca hardcoded no serviço
- [ ] Adiar grava entrada de auditoria (quem, quando, data antiga, data nova, motivo)
- [ ] Entradas `MISSING_EVIDENCE` expõem só `ATTACH_EVIDENCE` em `allowedActions`

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
`EXPIRED_DOCUMENT` depende da entidade de documento (mesma pendência da TASK-246). O resto é
independente e pode começar em paralelo com TASK-246/247.

## Riscos
Baixo — a maior parte reaproveita infraestrutura existente (auditoria, norma, evidência). Único
risco real é escopo incompleto de `EXPIRED_DOCUMENT` até a entidade de documento existir.

## Esforço
Pequeno-médio.

## Status
🔴 Não iniciada.
