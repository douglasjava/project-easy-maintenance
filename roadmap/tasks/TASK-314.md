# TASK-314 — Assistente: áudio > 2 min barrado sem IA e item novo pelo nome da norma

## Tipo
BUGFIX (backend)

## Prioridade
🟠 Alto

## Épico
[EPIC-031](../epics/EPIC-031.md) — ajuste do piloto da Onda 2 (TASK-306)

## QA obrigatório
Sim

## Contexto
Piloto do dia 28/09/2026, numa organização nova (Casa Marques, sem itens):
- *"Troquei o filtro da caixa d'água no dia 20/08/2026 Custo 350 Reais o responsável foi a empresa Caixas Luiza"*
  → "Não encontrei esse item… Escolha um item da lista", mas a lista estava vazia.
- Um áudio com mais de 2 min foi transcrito e classificado (300 + 572 créditos) e terminou em "fora do escopo".

## Causa raiz
- O catálogo regulatório era comparado só com o nome do **tipo**. A norma CAIXA_DAGUA está ligada ao tipo
  "LIMPEZA CAIXA DAGUA" (V101), então "caixa d'água" nunca casava.
- O limite de áudio era só de 1 MB, o que numa nota de voz Opus passa de 8 minutos. A Cloud API não manda a duração.

## Correção
- O tipo regulatório casa pelo nome dele ou pelo nome da norma. Se a norma tiver vários tipos, fica o que foi
  citado no texto; se nenhum foi citado, o mais antigo.
- Nova mensagem `REGISTER_NO_ITEMS` para organização sem itens.
- `OggOpusDuration` lê a duração do arquivo, sem IA. Acima de `max-audio-seconds` (120) o áudio é recusado antes
  do Whisper e não gasta crédito.
- O parser também lê "o responsável foi a empresa X".

**Critérios de aceite**
- [x] "caixa d'água" em organização vazia propõe item novo (teste que reproduz a mensagem do piloto).
- [x] Organização sem itens não recebe mais "escolha da lista" vazia.
- [x] Áudio > 2 min recusado sem transcrição e sem crédito.
- [x] Confirmar no piloto com uma nota de voz real (o teste usa um Ogg sintético).

## Notas de execução (28/09/2026)
- Branch `bugfix/TASK-314-assistente-audio-longo-item-catalogo` · PR [api#132](https://github.com/douglasjava/easy-maintenance-api/pull/132) → staging.
- Suíte: 1287/1287.

## Status
Done — validada no piloto em produção em 28/09/2026 (item novo pelo catálogo + foto anexada, áudio > 2 min recusado sem crédito).
