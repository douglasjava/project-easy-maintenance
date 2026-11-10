# TASK-435 — Samu e web: "Foi feita ou quer remarcar?" + alterar vencimento com motivo

## Tipo
FULL_STACK

## Categoria
Manutenção / Vencimento

## Prioridade
🟠 Alto — WA-05 e fluxo D do Tiago.

## Épico
[EPIC-043](../epics/EPIC-043.md) — Samu conversacional (Parte B)

## QA obrigatório
Sim.

---

## Contexto
Decisão de 10/11/2026 ([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), seção 7): "atualizar manutenção" pergunta [Foi feita] [Remarcar data].
Alterar vencimento é função nova só de ADMIN/SYNDIC (D16).

## Escopo
- Samu: "quero atualizar a manutenção do X" → [Foi feita] (registro) ou [Remarcar data].
- Alterar vencimento: item → nova data ([+7 dias] [+30 dias] [Outra data]) → motivo ([Fornecedor remarcou]
  [Validade do laudo] [Erro no cadastro]) → confirmação mostrando a data antiga e a nova.
- Web: mesma ação no detalhe do item; a mudança fica no histórico do item com motivo e autor.

## Critérios de Aceite
- [x] "quero atualizar a manutenção do alarme" → pergunta, sem presumir data
- [x] Remarcar grava data nova, motivo e autor no histórico
- [x] READER e personas sem a capacidade não conseguem remarcar

## Dependências
[TASK-414](TASK-414.md).

## Riscos
Remarcar não pode registrar manutenção nem mexer na última execução.

## Implementação (10/11/2026)
[api#211](https://github.com/douglasjava/easy-maintenance-api/pull/211) e [web#148](https://github.com/douglasjava/easy-maintenance-web/pull/148), mergeadas em `staging`.
- `ItemDueDateService` (V148 `item_due_date_changes`): só ADMIN/SYNDIC, motivo obrigatório e data futura. Não registra manutenção nem mexe na última execução. O histórico guarda a data antiga e a nova, o motivo, o autor e o canal.
- Bot: "atualizar…" responde [Foi feita] [Remarcar data] sem presumir data; remarcar segue item → +7, +30 ou outra data → motivo → confirmação de/para.
- Web: "Alterar vencimento" no detalhe do item, com a lista de remarcações.
- `mvn test` 1993, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — aguarda a validação de Douglas.
