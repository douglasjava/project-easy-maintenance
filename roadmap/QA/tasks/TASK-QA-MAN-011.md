# TASK-QA-MAN-011 — QA Manual: E2E cancelamento de manutenção + recálculo de compliance (EPIC-016)

## Tipo
QA Manual

## Categoria
Backend + Frontend / Manutenções / Compliance

## Prioridade
🟠 Alto

## Épico
[EPIC-016](../../epics/EPIC-016.md) — Cancelamento de Manutenções com Motivo

## Tasks cobertas
[TASK-137](../../tasks/TASK-137.md) (endpoint de cancelamento)
· [TASK-138](../../tasks/TASK-138.md) (recálculo do item)
· [TASK-139](../../tasks/TASK-139.md) (exposição de canceladas)
· [TASK-140](../../tasks/TASK-140.md) (ação de cancelar no frontend)
· [TASK-141](../../tasks/TASK-141.md) (exibição de canceladas no frontend)
· [TASK-142](../../tasks/TASK-142.md) (autor do anexo)
· [TASK-143](../../tasks/TASK-143.md) (anexar evidência depois, no frontend)

---

## Descrição

Validação end-to-end do fluxo de cancelamento de manutenção com motivo — o ponto crítico não é só
"o cancelamento funciona", é **"o item fica com o cronograma de compliance certo depois"**. A maior
parte dos cenários aqui existe pra provar isso em ordens diferentes de cadastro/cancelamento, não só
o caminho feliz simples.

---

## Pré-condições

- Ambiente: staging (`{BASE_URL}`)
- Um item de manutenção de teste (`{ITEM_ID}`) sem nenhuma manutenção registrada ainda
- Um usuário ADMIN/SYNDIC (`{JWT_ADMIN}`) e, se possível, um usuário TECH (`{JWT_TECH}`) da mesma
  organização, pra validar a restrição de papel

---

## Cenários de Teste

### C1 — Cancelar a única manutenção do item: volta ao estado "sem manutenção"

Setup: registrar uma manutenção para `{ITEM_ID}` (`POST /items/{ITEM_ID}/maintenances`).

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Conferir `nextDueAt`/`status` do item após o registro | Atualizados conforme a manutenção registrada |
| 2 | Cancelar a manutenção sem informar motivo | `400` — motivo obrigatório |
| 3 | Cancelar a manutenção informando motivo | `200`/`204`, `cancelReason`/`cancelledAt`/`cancelledBy` preenchidos |
| 4 | Conferir o item novamente | `nextDueAt`/`lastPerformedAt` voltam ao estado anterior à primeira manutenção (mesmo valor de antes do passo 1) |

---

### C2 — Cancelar a manutenção mais recente, havendo uma anterior válida

Setup: registrar M1 (`performedAt` mais antigo) e M2 (`performedAt` mais recente) para o mesmo item.

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Cancelar M2 (a mais recente) | Sucesso |
| 2 | Conferir o item | `nextDueAt`/`lastPerformedAt` recalculados a partir de M1, não do estado "sem manutenção" |

---

### C3 — Cancelar uma manutenção do meio, havendo uma válida mais recente depois dela (ordem fora de sequência)

Setup: registrar M1 (jan), M2 (fev), M3 (mar), nessa ordem, todas para o mesmo item.

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Cancelar M2 | Sucesso |
| 2 | Conferir o item | `nextDueAt`/`lastPerformedAt` recalculados a partir de **M3** (a mais recente válida por data), não de M1 |

Este é o cenário que mais provavelmente pega um bug de "recalcula a partir da anterior" em vez de
"recalcula a partir da mais recente válida" — não pular este cenário.

---

### C4 — Idempotência: cancelar uma manutenção já cancelada

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Cancelar uma manutenção já cancelada (reaproveitar a M2 do C3) | `409 Conflict`, sem alterar `cancelledAt`/`cancelReason` já gravados |

---

### C5 — Canceladas não aparecem por padrão, nem em export/KPIs

**Correção (Douglas, 27/07/2026)**: os passos 1-2 abaixo descreviam o design original da TASK-139
(parâmetro `includeCancelled` na listagem padrão), que **não foi o que foi implementado**. A
decisão real (documentada em `TASK-139.md`) foi um **endpoint dedicado**, pra não tocar na
paginação por cursor da listagem padrão — `includeCancelled` nunca existiu de fato. Roteiro
corrigido para refletir a implementação real.

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | `GET /items/maintenances?itemId={ITEM_ID}` | Cancelada (M2) não aparece |
| 2 | `GET /items/maintenances/cancelled?itemId={ITEM_ID}` | Cancelada aparece, com `cancelReason`/`cancelledAt`/`cancelledBy`/`cancelledByName` |
| 3 | `GET /items/maintenances/export` (CSV) | Cancelada não aparece no CSV |
| 4 | Conferir dashboard/KPIs que dependam de manutenções do item (se aplicável) | Sem influência da manutenção cancelada |

---

### C6 — Restrição de papel

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Tentar cancelar com usuário TECH (`{JWT_TECH}`), se a restrição tiver sido implementada na TASK-137 | `403 Forbidden` |
| 2 | Cancelar com usuário ADMIN/SYNDIC | Sucesso |

Se a TASK-137 tiver documentado uma decisão de **adiar** essa restrição (ver seção de Implementação
da task), marcar este cenário como **N/A** e registrar o motivo aqui.

---

### C7 — Frontend: fluxo completo pela UI

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Abrir o detalhe de uma manutenção válida na tela de manutenções | Botão "Cancelar manutenção" visível (papel autorizado) |
| 2 | Tentar confirmar o modal sem preencher motivo | Bloqueado, validação inline |
| 3 | Cancelar informando motivo | Toast de sucesso, manutenção some da lista de válidas, status/próximo vencimento do item atualizado na tela sem reload |
| 4 | Ligar o toggle "Mostrar canceladas" | Manutenção cancelada aparece com badge, motivo/autor/data visíveis |
| 5 | Abrir a manutenção cancelada | Sem ação de "Cancelar" nem "Adicionar anexo" disponível |

---

### C8 — Anexar evidência depois, com autor e data visíveis

Setup: manutenção válida registrada há alguns dias, sem nenhum anexo ainda.

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Abrir o detalhe de uma manutenção válida já registrada | Ação "Adicionar anexo" disponível, mesmo sem ter sido anexado nada na criação |
| 2 | Anexar um comprovante | Sucesso, anexo aparece na lista imediatamente, sem reload |
| 3 | Conferir os metadados do anexo na tela | Mostra claramente quem anexou e quando (data/hora do upload), diferente da data da manutenção |
| 4 | Repetir o passo 1-3 numa manutenção **cancelada** | Ação "Adicionar anexo" não disponível |

---

## Critérios de Aceite da Suite

- [x] C1: cancelar a única manutenção reverte o item ao estado "sem manutenção"
- [x] C2: cancelar a mais recente recalcula a partir da anterior válida
- [x] C3: cancelar uma do meio recalcula a partir da mais recente válida (não da anterior)
- [x] C4: cancelar uma já cancelada retorna 409, idempotente
- [x] C5: canceladas não vazam em listagem padrão, export CSV nem KPIs
- [x] C6: restrição de papel aplicada (ou decisão de adiamento documentada e validada)
- [x] C7: fluxo completo funciona pela UI, incluindo o toggle de exibição
- [x] C8: anexo adicionado depois mostra autor e data corretamente, e não é permitido em manutenção cancelada

---

## Status
**Aprovado — 27/07/2026.** Todos os 8 cenários (C1-C8) validados por Douglas na branch
`feature/EPIC-016-cancel-maintenance-reason`. Fecha o EPIC-016.

- **C1 — dois bugs achados e corrigidos**:
  1. Passo 3 falhava — `cancelReason`/`cancelledAt`/`cancelledBy` ficavam null no banco (só
     `deleted_at` era gravado). Causa: `save()` + `delete()` na mesma transação faz o Hibernate
     descartar o UPDATE de dirty-checking. Corrigido com `saveAndFlush()` antes do `delete()`.
  2. Depois de corrigir o #1, registrar uma nova manutenção pro mesmo item no mesmo dia (após
     cancelar a anterior) passou a falhar com `409 Duplicate entry`. Causa: constraint UNIQUE do
     banco (`uq_maint_item_date`, V24) não considera `deleted_at` — a linha cancelada continuava
     "ocupando" o dia. Corrigido com nova migration (V85) + coluna `active_dedup_key`.
  Detalhes, evidência (testes de persistência real com H2 e validação contra MySQL real) e decisões
  descartadas documentados em `TASK-137.md`. Suíte backend revalidada: 711/711 verde.
  **Requer reiniciar o backend local (aplica a migration V85) antes de re-executar C1 do zero.**

- **Achado de UX (C1/C2)**: card "Manutenções canceladas deste item" (TASK-141) ficava mal
  posicionado em `/maintenances` — não fazia sentido dentro do modal "Ver detalhes" (escopado a uma
  manutenção só) nem solto na listagem geral (escopada a vários itens). Resolvido com **TASK-144**:
  seção "Histórico de manutenções" (abas Ativas/Canceladas) na página de detalhe do item
  (`/items/[id]`), mantendo `/maintenances` como segunda forma de acesso.

- **C2 — bug achado e corrigido**: registrar uma manutenção com `performedAt` no passado falhava
  com `409 Duplicate` mesmo sem nenhuma manutenção na data informada, bastando existir qualquer
  outra manutenção do item com `performed_at` = hoje. Causa: `register()` conferia
  `existsByItemIdAndPerformedAt(itemId, LocalDate.now())` (data de hoje) em vez de
  `req.performedAt()` (a data sendo registrada) — bug pré-existente, exposto porque C2 foi o
  primeiro cenário a registrar com `performedAt` diferente de hoje. Corrigido; 2 testes novos em
  `MaintenanceRegisterCalculationTest`. Detalhes em `TASK-137.md`. Suíte backend revalidada:
  713/713 verde. **Requer reiniciar o backend local antes de re-executar C2.**
