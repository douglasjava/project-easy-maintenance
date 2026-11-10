# TASK-432 — Samu: contexto curto de 30 min + comandos voltar/cancelar/menu/trocar

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Conversa

## Prioridade
🟠 Alto — "e para caixa de gordura?" (WA-10).

## Épico
[EPIC-043](../epics/EPIC-043.md) — Samu conversacional (Parte B)

## QA obrigatório
Sim.

---

## Contexto
Princípio 7 e fluxo J da [Parte B](../QA/registro-usabilidade-producao.md). D18: o contexto curto vem **depois** da identidade por persona.

## Escopo
- O bot lembra por 30 min o último item, condomínio e fluxo da persona.
- Pergunta de continuação usa esse contexto ("e para caixa de gordura?" depois de um histórico).
- Comandos em qualquer ponto: `voltar`, `cancelar`, `menu`, `trocar condomínio`.

## Critérios de Aceite
- [x] "e para caixa de gordura?" depois de consultar histórico → histórico da caixa de gordura
- [x] Depois de 30 min o contexto expira
- [x] Comandos funcionam no meio de qualquer fluxo

## Dependências
[TASK-417](TASK-417.md). Entra junto com a [TASK-410](TASK-410.md) (prompt), que precisa saber do contexto.

## Riscos
Contexto errado aplicado a outra pergunta: só usar quando a mensagem não traz item próprio.

## Implementação (10/11/2026)
[api#208](https://github.com/douglasjava/easy-maintenance-api/pull/208), mergeada em `staging`.
- Contexto curto (V146) por persona, por 30 minutos: depois de um histórico, "e para caixa de godura?" responde o histórico sem IA (caso `his-02` da TASK-411).
- Comandos: `voltar` abre o painel; `cancelar` sem nada em andamento responde que não há nada; `menu` e `trocar condomínio` já existiam.
- `voltar` não volta etapa por etapa dentro de um rascunho: encerra a etapa e abre o painel.
- `mvn test` 1977, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — aguarda a validação de Douglas.
