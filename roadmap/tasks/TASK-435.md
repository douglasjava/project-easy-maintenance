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
- [ ] "quero atualizar a manutenção do alarme" → pergunta, sem presumir data
- [ ] Remarcar grava data nova, motivo e autor no histórico
- [ ] READER e personas sem a capacidade não conseguem remarcar

## Dependências
[TASK-414](TASK-414.md).

## Riscos
Remarcar não pode registrar manutenção nem mexer na última execução.

## Status
⬜ Backlog
