# TASK-385 — FRONTEND: aba Unidades (listar, criar, editar)

## Tipo
FRONTEND

## Categoria
Pessoas e Papéis

## Prioridade
🟠 Alto

## Épico
[EPIC-039](../epics/EPIC-039.md) — Pessoas e Papéis

## QA obrigatório
Sim — criar unidade, editar, confirmar que pessoa vinculada aparece na listagem.

---

## Contexto
Frontend do CRUD de `Unit` (TASK-382), aba dentro da mesma tela `/pessoas` (TASK-384). Detalhe
completo na spec de Pessoas e Papéis, seção "Frontend (rascunho)".

## Escopo
- Aba nova "Unidades" em `/pessoas` (TASK-384), grade por andar: número, tipo, status (ocupada/
  vaga — derivado de ter ou não `CondoPerson` vinculado, não campo próprio), nome+papel da pessoa
  vinculada quando houver.
- Criar/editar unidade (número, andar, tipo) via `POST`/`PUT /organizations/units`.
- Sem geração em lote ("Gerar unidades" do protótipo) — fora de escopo desta v1 (decisão 6 da
  spec).

## Critérios de Aceite
- [ ] Criar unidade nova aparece na grade imediatamente
- [ ] Editar unidade existente persiste e reflete na grade
- [ ] Unidade com `CondoPerson` vinculado mostra nome+papel da pessoa; sem vínculo mostra "vaga"
- [ ] Número duplicado na mesma organização mostra erro legível (reflete o `400` da TASK-382)
- [ ] `npm run build`/`tsc --noEmit` sem regressão

## Dependências
TASK-382 (contrato de API) e TASK-384 (página/abas já criadas).

## Riscos
Baixo.

## Esforço
Pequeno

## Status
Em Validação — implementado em `feature/EPIC-039-pessoas-papeis` (web), `tsc`/`build` limpos, aguardando push/PR e QA manual.
