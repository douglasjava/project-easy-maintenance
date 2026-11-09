# TASK-400 — BUGFIX: "Corrigir" do registro pelo WhatsApp não troca o item e prende o usuário no "confirme antes" (EPIC-031)

## Tipo
BUGFIX — BACKEND

## Categoria
Assistente WhatsApp (Samu) / Registro de manutenção

## Prioridade
🔴 Crítico — a única saída do ciclo é confirmar um registro errado (grava manutenção no item errado).

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · Onda 1 da triagem de usabilidade
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), item **WA-01**)

## QA obrigatório
Sim — fluxo crítico (grava dado de manutenção). Coberto pelo [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md).

---

## Contexto
Teste do Tiago em produção (08/11/2026): "o item é caixa de gordura, não é gerador" foi ignorado duas
vezes; o bot repetiu "Antes, confirme (ou corrija/cancele) o registro acima 👆" e o registro acabou
gravado como Gerador (maintenanceId=19). A correção de data e custo em texto livre funcionou no teste 2.

## Causa (verificada no código)
`AssistantRegistrationService.continuePending` (estágio `CONFIRM`) só lê das correções: data, tipo,
custo, responsável, periodicidade e anexo (`RegistrationParser`). **Não existe caminho para trocar o
item.** Quando nada disso é reconhecido, cai em `REGISTER_CONFIRM_FIRST` — repetido indefinidamente.
O botão "Corrigir" só reenvia `REGISTER_FIX_PROMPT` (exemplos sem item), sem mudar de estágio.

## Escopo da correção
- Reconhecer troca de item no estágio `CONFIRM`, em texto livre ("o item é X", "é a caixa de gordura",
  "não é gerador, é X") e quando o texto não casa com nenhum campo mas casa com item(ns) da organização.
  Reaproveitar a busca de item da [TASK-401](TASK-401.md) (mesmo matcher; 1 candidato → troca e
  reapresenta o cartão; vários → lista `CHOOSE_ITEM`; nenhum → lista de itens + opção "cancelar").
- Ao trocar item, um item novo do catálogo que estava no rascunho (`newItemType`) é descartado.
- "Corrigir" passa a oferecer a escolha do campo (lista: Item, Data, Tipo, Valor, Quem fez) além do
  texto livre. Escolher "Item" leva à lista de itens.
- **Nunca** existir estado em que a única saída seja confirmar: texto não reconhecido no `CONFIRM`
  responde com o que dá para corrigir + botões Confirmar/Corrigir/Cancelar (já existe) **e** a dica
  de troca de item. "cancelar" continua funcionando em qualquer estágio.
- Atualizar `REGISTER_FIX_PROMPT` incluindo o exemplo de troca de item.

## Fora de escopo
- Correção de "próxima data" (depende da [TASK-403](TASK-403.md)) e de despesa (EPIC futuro de financeiro).
- Menu/fluxos novos do Samu (Parte B — ver triagem).

## Critérios de Aceite
- [x] Rascunho em `CONFIRM` + "o item é caixa de gordura" → item trocado para "Limpeza caixa de gordura · …" e cartão reapresentado
- [x] Rascunho com item novo do catálogo + troca para item existente → cartão sem "🆕 Item novo"; confirmar não cria item
- [x] Texto que casa com vários itens → lista para escolher; escolha volta ao cartão com os demais campos preservados (data, custo, anexos)
- [x] Botão "Corrigir" → lista de campos; "Item" → lista de itens
- [x] Correção de data/custo em texto livre continua funcionando (regressão do teste 2)
- [x] Teste de regressão reproduzindo a transcrição do teste 1 (gerador → caixa de gordura)
- [x] Item de outra organização nunca aparece/é aceito — a busca usa só `allItems(orgCode)` da conversa e a escolha passa por `continueChoosingItem` (id fora da lista ignorado; teste existente `choosingItemFromList_onlyAcceptsListedCandidates`)
- [x] `mvn test` sem regressão — 1727/1727 (13 testes novos em `AssistantRegistrationServiceTest`, 40/40)

## Dependências
Compartilha o matcher com a [TASK-401](TASK-401.md) — fazer as duas na mesma branch.

## Riscos
Texto livre ambíguo ("mudar") hoje é palavra de correção; garantir que a troca de item não roube
correções legítimas de data/custo (ordem: campos conhecidos primeiro, item depois).

## Implementação (09/11/2026)
- `AssistantRegistrationService.continuePending` (estágio `CONFIRM`): lê frases de troca de item
  ("o item é X", "não é Y, é X", "troca o item para X", "é a X") e nome de item solto; 1 candidato →
  troca e reapresenta o cartão; vários → `CHOOSE_ITEM`; nenhum (frase explícita) → lista de itens.
  Correções de data/tipo/valor/responsável na mesma mensagem continuam sendo aplicadas.
- "não é X" sem dizer o certo → lista de itens (nunca escolhe o negado). "não é preventiva, é
  corretiva" segue como correção de **tipo** (achado na revisão, coberto por teste).
- Botão "Corrigir" → lista de campos (Item, Data, Tipo, Valor, Quem fez); "Item" → lista de itens.
- `REGISTER_CONFIRM_FIRST` reescrita: explica as saídas (Corrigir / só o que mudou / Cancelar).
- Limitações conhecidas (escopo da TASK-401): a busca de item ainda é por trecho exato (typo não acha);
  a lista de itens mostra no máximo 10. A descrição do cartão ainda é o texto original (TASK-405).

## Branch
`bugfix/onda1-usabilidade-samu` (`easy-maintenance-api`, a partir de `staging`) — branch única da
Onda 1, por decisão do Douglas. Commit `c3dec3e`.

## Status
✅ Concluído — validado em `staging` no QA manual [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md) pelo Douglas e promovida para `main` em 09/11/2026 — api [#184](https://github.com/douglasjava/easy-maintenance-api/pull/184)→[#185](https://github.com/douglasjava/easy-maintenance-api/pull/185), web [#136](https://github.com/douglasjava/easy-maintenance-web/pull/136)→[#137](https://github.com/douglasjava/easy-maintenance-web/pull/137).
