# TASK-141 — Frontend: Exibir manutenções canceladas na tela do item

## Tipo
FRONTEND

## Categoria
Manutenções / Compliance e Auditoria

## Prioridade
🟡 Médio

## Épico
[EPIC-016](../epics/EPIC-016.md) — Cancelamento de Manutenções com Motivo

## QA obrigatório
Sim — validar visualmente que canceladas não se misturam com válidas de forma confusa.

---

## Contexto

Complementa a TASK-140: sem essa visualização, o benefício de "não perder o histórico" existe só no
banco, ninguém no time consegue de fato auditar depois. Depende do endpoint/parâmetro da **TASK-139**
(`includeCancelled`).

---

## Objetivo

Deixar visível, na tela de manutenções do item, quais foram canceladas — sem confundir com o
histórico de manutenções válidas.

---

## Escopo

### 1. Toggle "Mostrar canceladas"

- Na tela de manutenções do item, adicionar toggle/checkbox "Mostrar canceladas" — desligado por
  padrão (a visão principal continua só com o que foi feito de verdade, sem poluir com
  cancelamentos).
- Ligado: busca com `includeCancelled=true` (TASK-139) e exibe as canceladas junto, mas **sempre**
  com badge visual claro ("Cancelada") — nunca misturadas sem diferenciação.

### 2. Detalhe da manutenção cancelada

- Ao expandir/abrir uma manutenção cancelada, mostrar: motivo do cancelamento, quem cancelou e
  quando (mesmo padrão de resolução de nome de usuário já usado pra "Registrado por", TASK-104).
- Não mostrar a ação de "Cancelar" (TASK-140) nem de adicionar anexo em manutenções já canceladas.

### 3. Testes

- Toggle desligado → comportamento idêntico ao atual (nenhuma cancelada aparece).
- Toggle ligado → canceladas aparecem com badge e motivo/autor/data visíveis.

---

## Arquivos impactados (estimativa)

### Frontend
- `src/app/maintenances/page.tsx` — toggle, badge visual, exibição de motivo/autor/data nas
  canceladas

---

## Critérios de Aceite

- [ ] Toggle "Mostrar canceladas" desligado por padrão, sem alterar a experiência atual
- [ ] Canceladas, quando exibidas, têm badge visual claro e nunca se misturam com válidas sem
      diferenciação
- [ ] Motivo, autor e data do cancelamento visíveis no detalhe de uma manutenção cancelada
- [ ] Ações de cancelar/anexar não aparecem em manutenções já canceladas

## Dependências
- **TASK-139** — endpoint/parâmetro de canceladas precisa existir.
- **TASK-140** — natural fazer em conjunto (mesma tela, mesmo contexto de trabalho).

## Riscos
Nenhum risco técnico relevante além dos já cobertos na TASK-139 (a parte de backend é que carrega o
risco real desta funcionalidade).

## Esforço
Baixo (toggle + badge visual — sem lógica nova além do que a TASK-139 já expõe)

## Status
**Concluída (superada pela TASK-144)** — o card/toggle "Manutenções canceladas deste item" implementado aqui foi
**removido** de `/maintenances` em 27/07/2026, a pedido de Douglas, depois que a TASK-144 passou a
oferecer a mesma visualização (mais um histórico de ativas) na página de detalhe do item, sem a
sensação de bagunça visual apontada no QA manual (TASK-QA-MAN-011 C1/C2). O trabalho de backend que
esta task consumia (TASK-139) continua válido e em uso — só a superfície de UI aqui mudou de lugar.
Detalhes da remoção documentados na TASK-144. Commitado, com PR aberto para `staging`.

## Implementação

- **Gap encontrado antes de implementar**: o card já assumia "quem cancelou" como nome resolvido
  ("mesmo padrão... TASK-104"), mas a TASK-139 só tinha exposto o ID cru (`cancelledBy: Long`) —
  resolvido retroativamente na própria TASK-139 (ver addendum lá), adicionando
  `cancelledByName` com resolução em lote via `UserRepository`, antes de implementar este frontend.
- Toggle "Mostrar canceladas" só aparece com um item selecionado (`selectedItemId`) — a consulta é
  sempre por item (`GET /items/maintenances/cancelled?itemId=X`), não faz sentido sem esse filtro.
  Desligado por padrão.
- **Sem modal de detalhe reaproveitado**: o modal de detalhe existente (`viewingMaintId`/`maintDetail`)
  busca por `GET /items/maintenances/{id}`, que nunca encontra uma cancelada (`@SQLRestriction`
  filtra automaticamente — daria 404). Como o endpoint de canceladas (TASK-139) já retorna os dados
  completos (incluindo anexos) numa lista só, implementei um card expansível inline
  (`CancelledMaintenanceRow`) em vez de tentar reabrir o modal padrão — mais simples e evita esse
  problema de raiz.
- Badge "Cancelada" (vermelho) sempre visível no card fechado — nunca precisa expandir pra saber que
  é cancelada, só pra ver motivo/autor/data.
- Novo `formatDateTime` — `cancelledAt` é `Instant` (data+hora), diferente de `performedAt` (só
  data); o `formatDate` existente quebraria concatenando `"T00:00:00"` numa string ISO que já tem
  hora.
- Invalidação de `["maintenances-cancelled"]` adicionada ao `handleMaintenanceCancelled` (TASK-140)
  — cancelar uma manutenção agora atualiza também esta lista, se estiver aberta.
- **Mesma limitação de teste da TASK-140**: sem infraestrutura de teste de componente React neste
  projeto — validado via build/lint/revisão manual, sem clique-a-clique real (mesmo motivo: API
  local bloqueada pelo `bootstrap.admin.token`). Fica para o cenário C7/C8 da TASK-QA-MAN-011.
