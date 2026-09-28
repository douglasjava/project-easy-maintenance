# TASK-315 — Assistente: item operacional novo pelo catálogo padronizado + periodicidade por botão

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 2** (extensão da TASK-306)

## Depende de
TASK-306, TASK-314

## QA obrigatório
Sim.

## Contexto
No piloto de 28/09/2026, "Limpeza de piscina no dia 10/08/2026, executado pelo Augusto da empresa Piscinas Azuis"
caiu em "não encontrei esse item". Pela regra da TASK-306, o bot só cria item **regulatório**, porque a periodicidade vem
da norma. Item operacional precisa de periodicidade, e o bot não pode inventá-la.

Douglas quer que o bot também cadastre o item operacional, com **um padrão mínimo de nome**: nada de itens como
"bananinha" criados pelo WhatsApp.

## Decisão de desenho
- **O nome vem só do catálogo `item_types`** (cerca de 180 tipos operacionais padronizados da V7/V8, ex.: MANUTENCAO DE PISCINA,
  LIMPEZA FILTRO PISCINA, TRATAMENTO QUIMICO PISCINA). O texto do usuário nunca vira nome de item.
  - Sem correspondência no catálogo → mantém a resposta atual (lista de itens + link `/items/new`). "Bananinha" nunca é criado.
- **Correspondência determinística primeiro:** pontuação por palavras do texto contra o nome legível do tipo
  (`ItemTypeLabels`), ignorando palavras vazias ("de", "da", "o"…). Se houver 1 candidato forte, ele é usado; se houver
  2 ou mais, o bot mostra os 3 melhores numa lista mais a opção "Nenhum desses".
- **IA só como alternativa e só escolhendo:** se a correspondência determinística não achar nada, o classificador pode devolver
  um `item_type_id` de uma **lista fechada** de ids do catálogo (mesma regra do EPIC-031: a IA classifica, não escreve).
  Id fora da lista → é ignorado. É opcional nesta task e só entra se o custo de tokens for aceitável.
- **Periodicidade por botão (lista):** 1 mês · 3 meses · 6 meses · 1 ano · Cancelar. Não gasta IA.
- **Resumo** com "🆕 Item novo: Manutenção de piscina (Operacional — a cada 3 meses)" e os botões Confirmar/Corrigir/Cancelar
  de sempre. "Corrigir" permite trocar a periodicidade ("a cada 6 meses").
- Gravação: `MaintenanceItemService.create` com `customPeriodUnit`/`customPeriodQty` + manutenção, na mesma transação
  da TASK-306 (`source = WHATSAPP`, auditoria com o wamid). O limite de itens do plano continua valendo.

## Critérios de aceite
- [ ] "limpeza de piscina…" propõe um tipo do catálogo (ou pede escolha entre até 3) e depois pergunta a periodicidade.
- [ ] Texto sem correspondência no catálogo ("bananinha") nunca cria item: a resposta continua sendo o link de cadastro.
- [ ] O item criado usa o `normalized_name` do catálogo, categoria OPERATIONAL e a periodicidade escolhida.
- [ ] Item regulatório continua com prioridade (se casar com norma, segue o fluxo da TASK-314).
- [ ] Limite de itens do plano, perfil só leitura e somente leitura da assinatura continuam barrando.
- [ ] Escolha de tipo e de periodicidade não consome crédito de IA.

**Prompt**: `execute a TASK-315 (EPIC-031): item operacional novo pelo WhatsApp só com nome do catálogo item_types e
periodicidade escolhida por botão.`

## Status
Backlog
