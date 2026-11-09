# TASK-401 — BUGFIX: registro pelo WhatsApp cria item errado (Gerador) em vez de achar o item existente (EPIC-031)

## Tipo
BUGFIX — BACKEND

## Categoria
Assistente WhatsApp (Samu) / Registro de manutenção

## Prioridade
🔴 Crítico — cria item duplicado/errado e grava manutenção nele.

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · Onda 1 da triagem de usabilidade
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), itens **WA-02** e parte do **WA-22**)

## QA obrigatório
Sim — coberto pelo [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md).

---

## Contexto
"caixa de gorduro" (erro de digitação) + "emergencial" virou item novo **Gerador** (Regulatório,
periodicidade pela norma), embora já existisse "Limpeza caixa de gordura · Garragem subsolo".

## Causa (verificada no código em 09/11/2026 — hipótese inicial corrigida)
1. `ItemMatcher.match` só casava por **trecho exato** do nome normalizado; um erro de digitação
   ("gorduro") zerava os candidatos e o fluxo ia **direto ao catálogo**, que pode propor item novo.
2. **Causa confirmada em produção (09/11/2026):** o texto recebido (manutenção 19) **não contém
   "gerador"** — "manutenção da caixa de gorduro do predio, nao me lembro de ter cadastrado o item ainda…
   feita de forma emergencial". O item criado (140) é `GERADOR`, ligado à norma `GERADOR` (só a palavra
   "gerador"). Logo, o "gerador" veio do **campo `item` extraído pela IA** (alucinação — o mesmo
   classificador devolveu `responsavel = "emergencial"`). A hipótese "emergencial → emergência" e a da
   mensagem juntada no lote foram descartadas.
3. A correção abaixo resolve o caso **qualquer que tenha sido a origem do "gerador"**: itens parecidos que
   já existem passam a ser oferecidos **antes** de o catálogo propor item novo.

## Escopo da correção
- **Busca aproximada nos itens da organização** antes do catálogo: tolerância a erro de digitação
  (ex.: distância de edição por token, ≥ 5 letras) e casamento por tokens (não só substring),
  ignorando palavras fracas (`CatalogTokens.WEAK`) e de tipo de manutenção (preventiva/corretiva/
  emergencial). 1 candidato forte → segue; parecidos → "Achei estes. É algum deles?" com
  "Outro item"/"Criar item novo".
- **Catálogo regulatório não casa só por palavra de tipo de manutenção**: excluir
  emergencial/emergência/corretiva/preventiva dos tokens comparados, e exigir ao menos um token
  "forte" do próprio tipo (objeto) quando o casamento é pelo nome da norma.
- **Item novo nunca em silêncio:** antes de cair em item novo, se houver itens existentes com
  similaridade parcial, oferecê-los primeiro.
- Reaproveitar o mesmo matcher na consulta de histórico (`AssistantQueryService.match`) — mesmo
  problema de typo.

## Fora de escopo
- Mini-cadastro completo de item novo pelo chat (tipo, local, categoria — WA-22 completo): Parte B.
- Cadastro de Locais (IT-01).

## Critérios de Aceite
- [x] "manutenção da caixa de gorduro ontem, R$ 300, emergencial" com item "Limpeza caixa de gordura" cadastrado → sugere esse item; **não** cria Gerador
- [x] Teste de regressão com o texto exato do teste 1 do Tiago
- [x] Teste unitário do `CatalogMatcher`: "emergencial" sozinho não seleciona nenhum tipo regulatório (defensivo: "emergencial"/"urgente" viraram palavras ignoradas)
- [x] Casos já cobertos continuam passando ("caixa d'água do bloco B", "extintores", TASK-314/315)
- [x] Histórico: "última manutenção da caixa de gorduro" acha o item
- [x] `mvn test` sem regressão — 1741/1741 (14 testes novos: `ItemMatcherTest` 8, registro 4, catálogo 1, histórico 1)

## Dependências
Mesma branch da [TASK-400](TASK-400.md) (a troca de item usa este matcher).

## Riscos
Busca mais tolerante pode gerar mais "É algum deles?" — preferível a gravar no item errado. Calibrar
com os itens reais do Edifício Veneza.

## Implementação (09/11/2026)
- `ItemMatcher.find` → `Match(candidates, exact)`. Sem casamento exato, compara por palavras
  (`CatalogTokens`), tolerando **um** erro de digitação em palavras com 6+ letras ("porta" × "portão" não
  casa). Ficam só os empatados no topo. É **sugestão** (`exact=false`), exceto quando um único item tem o
  tipo dito por inteiro e sem erro ("limpeza **da** caixa de gordura" → direto).
- Registro: sugestão → "Achei estes itens parecidos em *X*. É algum deles?" + **Nenhum destes**; só o
  "Nenhum destes" leva ao catálogo curado (item novo). Item novo nunca é proposto se há parecido.
- Campo `item` da IA sem resultado → tenta o texto inteiro antes do catálogo.
- **Campo `item` da IA só vale se aparecer no texto** (`groundedInText`: ao menos uma palavra forte do
  campo presente na mensagem, tolerando erro de digitação). Sem isso, como o Gerador (140) agora existe
  no Veneza, o casamento exato iria direto para ele na próxima alucinação. Commit `9f3cea4`.
- Regressão com o **texto exato** da manutenção 19 (`PROD_TEXT_19`).
- Histórico e troca de item da TASK-400 usam a mesma busca.
- Fora desta task: o mini-cadastro completo de item novo pelo chat (WA-22) segue na Parte B.

## Branch
`bugfix/onda1-usabilidade-samu` (`easy-maintenance-api`), commits `ce34b40`, `30bdd87` e `9f3cea4`.

## Status
🟡 Em Validação — implementado e testado (1744/1744); causa confirmada em produção; falta QA manual
[TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md) (C1).
