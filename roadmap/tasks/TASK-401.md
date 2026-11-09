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

## Causa (verificada no código; o falso positivo exato a confirmar no teste de regressão)
1. `ItemMatcher.match` só casa por **substring exata** do nome normalizado (`label.contains(query)`
   ou `query.contains(tipo)`); um erro de digitação ("gorduro") zera os candidatos.
2. Sem candidato, `start` vai direto ao catálogo. `CatalogMatcher.regulatory` aceita casar pelos
   tokens **do nome da norma** (`all(entry.normTokens(), said)`), e `CatalogTokens.same` aceita
   prefixo a partir de 6 letras — "emergencial" casa com "emergência". Uma norma cujo nome só tenha
   esse token relevante seleciona um item regulatório sem o usuário ter citado o objeto.
3. O cartão mostra "🆕 Item novo: Gerador" e o usuário confirma às cegas (sem "é algum destes?").

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
- [ ] "manutenção da caixa de gorduro ontem, R$ 300, emergencial" com item "Limpeza caixa de gordura" cadastrado → sugere esse item; **não** cria Gerador
- [ ] Teste de regressão com o texto exato do teste 1 do Tiago
- [ ] Teste unitário do `CatalogMatcher`: "emergencial" sozinho não seleciona nenhum tipo regulatório
- [ ] Casos já cobertos continuam passando ("caixa d'água do bloco B", "extintores", TASK-314/315)
- [ ] Histórico: "última manutenção da caixa de gorduro" acha o item
- [ ] `mvn test` sem regressão

## Dependências
Mesma branch da [TASK-400](TASK-400.md) (a troca de item usa este matcher).

## Riscos
Busca mais tolerante pode gerar mais "É algum deles?" — preferível a gravar no item errado. Calibrar
com os itens reais do Edifício Veneza.
