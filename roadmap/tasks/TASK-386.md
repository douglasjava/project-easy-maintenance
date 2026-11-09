# TASK-386 — FRONTEND: entrada "Pessoas e Papéis" no menu do usuário

## Tipo
FRONTEND

## Categoria
Pessoas e Papéis

## Prioridade
🟡 Médio

## Épico
[EPIC-039](../epics/EPIC-039.md) — Pessoas e Papéis

## QA obrigatório
Não — item de menu simples, sem lógica de negócio.

---

## Contexto
Torna `/pessoas` (TASK-384) alcançável pela navegação normal, mesmo padrão da entrada
"Configurações" adicionada no EPIC-038 (TASK-379).

## Escopo
- Item novo no menu do usuário apontando para `/pessoas`, visível para `ADMIN`/`SYNDIC` (oculto
  para `TECH`/`READER`, mesmo critério de acesso da tela).

## Critérios de Aceite
- [ ] Item aparece no menu para `ADMIN`/`SYNDIC` e leva a `/pessoas`
- [ ] Item não aparece para `TECH`/`READER`
- [ ] `tsc --noEmit` sem regressão

## Dependências
TASK-384 (página precisa existir antes do link).

## Riscos
Nenhum.

## Esforço
Pequeno

## Status
Em Validação — implementado em `feature/EPIC-039-pessoas-papeis` (web), `tsc` limpo, item visível para ADMIN/SYNDIC via mesmo critério de `/configuracoes`.
