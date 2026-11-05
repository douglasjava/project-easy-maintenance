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
- [x] Fila de ações: faixa de severidade, nome do item, pill de severidade, chip da norma,
      categoria, linha de contexto, ações inline conforme `allowedActions`.
- [x] Adiar abre diálogo exigindo motivo.
- [ ] Painel "Laudos e documentos" — **não implementado**, ver Viabilidade Técnica.
- [~] Estado vazio real — implementado sem o "próxima manutenção em X dias" específico (essa data
      não vem em nenhum response quando a fila está vazia; adicionar exigiria um campo novo no
      backend só pra esse texto). Mensagem genérica porém honesta: "Nenhuma pendência agora".

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

## Implementação
`src/components/dashboard/compliance/ActionQueue.tsx` — fila real + diálogo de adiamento
(`newDueDate` + `reason` obrigatório, chama `POST /dashboard/actions/{id}/postpone` da TASK-248,
invalida `dashboard-actions`/`dashboard-summary`/`dashboard-series` depois de confirmar). `COMPLETE`
linka pra `/maintenances/new?itemId=X`, `ATTACH_EVIDENCE` linka pro detalhe do item (`/items/{id}`)
— não existe uma tela dedicada de "anexar evidência numa manutenção já concluída" em lugar nenhum
do app hoje, esse é o destino real mais próximo.

**Painel "Laudos e documentos" não implementado** — confirmado o achado da Viabilidade Técnica:
`ItemDocument` (TASK-246) só tem a entidade + `findByItemIdOrderByValidUntilAsc`, sem endpoint de
leitura exposto no controller. Construir esse painel exigiria primeiro um `GET` novo no backend
(fora do escopo original das 9 tasks do épico) — registrado aqui como pendência real, não
escondido.

`npm run build`/`eslint` limpos, sem regressão em `npm test`.

## Status
🟡 Fila de ações implementada e testada; painel de documentos pendente de um endpoint de backend
que não existe (fora do escopo das 9 tasks originais do épico).
