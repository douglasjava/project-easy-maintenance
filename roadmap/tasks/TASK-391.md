# TASK-391 — FRONTEND: aba "Pendentes" em `/pessoas`

## Tipo
FRONTEND

## Categoria
Esteira de Identidade do Morador

## Prioridade
🟠 Alto

## Épico
[EPIC-040](../epics/EPIC-040.md) — Esteira de Aprovação de Identidade do Morador

## QA obrigatório
Sim — aprovar vinculando unidade existente, aprovar criando unidade nova, reprovar, confirmar que
o item sai da lista depois de processado.

---

## Contexto
Canal de aprovação sempre disponível, independente de WhatsApp — cobre toda organização cujo
síndico ainda não está linkado ao assistente (maioria, até a Onda 2 do EPIC-031). Detalhe completo
na spec da esteira, seção "Decisões" (opção A — reaproveitar a tela de Pessoas).

## Escopo
- Aba nova "Pendentes" em `/pessoas` (TASK-384), listando `GET
  /organizations/resident-identity-pendings?status=PENDENTE` (endpoint novo de leitura — decisão de
  implementação: pode reaproveitar o service da TASK-390 ou expor via `ResidentIdentityPending`
  diretamente).
- Cada item mostra nome, telefone, apto/bloco informado na intake, resumo da solicitação.
- Botão **Aprovar**: abre seleção de unidade (combo com as `Unit` existentes da organização + opção
  "criar nova unidade" com campos número/andar/tipo) — chama `POST
  /organizations/resident-identity-pendings/{id}/approve` (TASK-390).
- Botão **Reprovar**: chama `POST /organizations/resident-identity-pendings/{id}/reject`
  (TASK-390), sem campo adicional.
- Item some da lista depois de aprovado/reprovado (sem precisar de reload manual).

## Critérios de Aceite
- [x] Lista mostra só pendências com status `PENDENTE` da organização autenticada
- [x] Aprovar com unidade existente funciona e remove o item da lista
- [x] Aprovar criando unidade nova funciona e remove o item da lista
- [x] Reprovar funciona e remove o item da lista
- [x] Estados de loading/erro consistentes com o resto do app
- [x] `npm run build`/`tsc --noEmit` sem regressão

## Dependências
TASK-390 (endpoints de aprovação/reprovação) e TASK-384 (página/abas já criadas).

## Riscos
Baixo — CRUD de leitura + duas ações, sem lógica de negócio nova no frontend (tudo decidido no
backend).

## Esforço
Médio

## Status
🟢 Implementado (02/11/2026) — branch `feature/EPIC-040-resident-identity-approval`
(`easy-maintenance-web`), commit `cb95ef3`. Nova aba "Pendentes" em `/pessoas`, com badge de
contagem; `ApprovePendingModal` alterna entre unidade existente (combo) e nova (número/andar/tipo).
Lista recarrega via `fetchAll()` depois de aprovar/reprovar, mesmo padrão das outras abas. `tsc`/
`build` limpos. QA manual (ao vivo contra API/web local) ainda pendente — servidor local não estava
rodando nesta sessão.
