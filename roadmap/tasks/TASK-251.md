# TASK-251 — FRONTEND: Fila de ações + painel de documentos

## Tipo
FRONTEND

## Categoria
Dashboard / Compliance

## Prioridade
🟠 Alto

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Sim — testar as 3 ações inline num navegador real (completar, adiar com motivo, anexar evidência),
e o estado vazio real (fila vazia mas conta tem histórico).

---

## Contexto
Renumerada de TASK-135 do documento original. Substitui o card "Atenção agora" vazio pela fila de
ações real, mais o painel "Laudos e documentos".

## Escopo
- Fila de ações: faixa de severidade, nome do item, pill de severidade, chip da norma, categoria,
  linha de contexto, ações inline conforme `allowedActions`.
- Adiar abre diálogo exigindo motivo.
- Painel "Laudos e documentos" — documentos vinculados por validade.
- Estado vazio real: fila vazia + conta com histórico → "Nenhuma pendência — próxima manutenção em
  X dias" (não um check genérico).

## Viabilidade Técnica

**Reaproveitável:** `AttentionCard.tsx` (134 linhas) já é a versão atual do card que este task
substitui — mesmo componente-base, reescrito com os campos novos (`norm`, `allowedActions`,
`context`) que vêm da TASK-248.

**Bloqueado por entidade que não existe:**
- **O painel "Laudos e documentos" inteiro depende da entidade de documento que não existe no
  backend** (achado central do épico, ver TASK-246). Não há endpoint, não há dado — este task não
  pode implementar essa metade do escopo até essa sub-feature existir. Proposta: implementar
  primeiro a fila de ações (dado real disponível via TASK-248) e tratar o painel de documentos como
  entregável separado, condicionado à entidade existir.

**Sem achado técnico contrário** no resto (fila de ações, diálogo de motivo, estado vazio — tudo
implementável com o que a TASK-248 já entrega).

## Dependências
TASK-248 (fila de ações), TASK-249 (shell). Painel de documentos depende da entidade de documento
(mesma pendência da TASK-246).

## Riscos
Médio — risco de a task "parecer" completa sem o painel de documentos, que é metade do valor de
produto descrito no protótipo original ("um laudo vencido derruba o índice igual uma manutenção
atrasada").

## Esforço
Médio (fila de ações) + indeterminado (painel de documentos, depende de escopo ainda não fechado).

## Status
🔴 Não iniciada — bloqueada por TASK-248/249.
