# Triagem: registro de usabilidade do Tiago (testes de 08/11/2026)

**Data:** 09/11/2026 · **Fonte:** [registro-usabilidade-producao.md](registro-usabilidade-producao.md)
**Objetivo deste documento:** guardar a análise feita com o Douglas para **não repetir a conversa**.
A Onda 1 virou tasks. O restante (Parte B do Tiago, Locais, Financeiro e integração) está registrado
aqui, com causas, sobreposições e conflitos, para retomar quando a Onda 1 terminar.

---

## 1. Diagnóstico geral

Os 35 itens se agrupam em três problemas:

1. **O Samu grava dado errado**: correção sem troca de item, item errado, data presumida. É a prioridade,
   porque suja a base que sustenta a "prova de manutenção" (EPIC-033).
2. **O Samu funciona como um menu fechado**: poucas intenções, sem contexto, resposta genérica quando
   não entende.
3. **O financeiro está isolado**: sem edição, categorias pobres, custo da manutenção não vira despesa.

## 2. Onda 1: virou tasks (09/11/2026)

| Task | Itens do Tiago | Causa encontrada no código |
|---|---|---|
| [TASK-400](../tasks/TASK-400.md) 🔴 | WA-01 | `continuePending` não tem caminho para trocar o item → ciclo `REGISTER_CONFIRM_FIRST` |
| [TASK-401](../tasks/TASK-401.md) 🔴 | WA-02, parte do WA-22 | `ItemMatcher` só por substring exata → foi direto ao catálogo. + **IA inventou `item="gerador"`** (confirmado em produção: o texto da manutenção 19 não tem "gerador") |
| [TASK-402](../tasks/TASK-402.md) 🟠 | WA-13, WA-07 | Data ausente vira hoje (`performedAtAssumed`); `parseDate` não entende "hj" |
| [TASK-403](../tasks/TASK-403.md) 🟠 | WA-06, WA-23 | Próxima data só aparece depois do `commit` |
| [TASK-404](../tasks/TASK-404.md) 🟠 | WA-19, WA-15 | `upcoming` ignora vencidos; formato `dd/MM` sem ano |
| [TASK-405](../tasks/TASK-405.md) 🟡 | WA-03, WA-14 | Descrição = texto cru; campo `responsavel` da IA sem validação |
| [TASK-406](../tasks/TASK-406.md) 🟡 | WA-09 | Histórico ignora `lastPerformedAt` do item |
| [TASK-407](../tasks/TASK-407.md) 🟠 | WA-08 | **Não é corrida:** o botão "Registrar" não grava estado de espera; a mensagem seguinte vai ao classificador sem contexto |
| [TASK-408](../tasks/TASK-408.md) 🔵/🟡 | WA-12, WA-17, WA-18 | Nome da organização com espaço no final; Gerador criado por engano; WA-17 a verificar |
| [TASK-409](../tasks/TASK-409.md) 🔵 | FI-04 | Formulário dentro do `ConfirmModal` destrutivo (vermelho fixo no código) |
| [TASK-QA-MAN-030](tasks/TASK-QA-MAN-030.md) | — | QA manual com os textos reais dos testes |

**Decisão tomada na Onda 1:** a hora da execução (WA-03, "09:00 ignorado") fica fora. `performedAt` é
`LocalDate` em todo o domínio; a hora fica na descrição.

### Revisão antes do merge (09/11/2026)
- Regra única para os campos que a IA extrai (`AiIntentClassifier`, `gpt-4o-mini`): **o texto vence, e o campo da
  IA só vale com pista no texto** — item e responsável (`groundedInText`), data (`mentionsWhen`), valor
  (`mentionsMoney`), tipo de manutenção (`mentionsKind`). Vale no registro e no lançamento financeiro (api `d80be6b`).
- Lançamento financeiro: a data padrão continua **hoje** (aparece no cartão) e receita/despesa aceita a inferência
  da IA ("conta de luz" → despesa). Revisitar se o Tiago apontar erro.
- Registradas para depois da Onda 1: [TASK-410](../tasks/TASK-410.md) (endurecer o prompt) e
  [TASK-411](../tasks/TASK-411.md) (conjunto de avaliação do classificador — pré-requisito da 410).

## 3. Itens corrigidos ou reclassificados na triagem

- **WA-11** ("falta lançar receita/despesa pelo WhatsApp"): a funcionalidade **existe** (TASK-330, por texto
  livre). O problema é que ninguém a encontra: não está no menu nem na mensagem `OUT_OF_SCOPE`. Resolve-se
  com o menu por papel (spec da matriz, item 1).
- **WA-04 / WA-20** ("é preciso digitar menu"): "oi" e "menu" já abrem o menu (`DeterministicIntentMatcher`).
  O que falha é texto livre classificado como `FORA_DO_ESCOPO`, que responde "digite menu" em vez de
  mostrar o painel ou os botões.
- **WA-16** (ações por item na lista de vencidos): é a [TASK-340](../tasks/TASK-340.md) (EPIC-033).
- **WA-05** (anexo depois do registro): encosta na [TASK-339](../tasks/TASK-339.md) (EPIC-033).
- **WA-10** (alterar vencimento): feature, fluxo D da Parte B.

## 4. Pendente: Parte B do Tiago (reestruturação do Samu) × spec da matriz de papéis

Spec: [`2026-11-06-assistant-role-matrix-design.md`](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md)
(fechada em 06/11, D1 a D13, ainda sem EPIC).

**Onde se encontram:** o menu (WA-11, WA-21, 5.3 do Tiago) é o **item 1 da quebra da spec** (política única
de permissões + menu por papel em lista de 10 linhas). O menu do Tiago precisa ser **gerado a partir da
política**, não desenhado à parte. A spec já tinha diagnosticado o problema (problema 3: "funções sem atalho
no menu").

**Conflitos a resolver antes de criar o EPIC da Parte B (de preferência com o Tiago, que escreveu a Parte B
sem conhecer a matriz):**

1. **Abrir chamado:** na matriz, só o Morador abre; síndico e zelador "atendem". O Tiago (fluxo F) quer que
   síndico e zelador também abram pelo WhatsApp.
2. **Fornecedor do item × D8:** o Tiago (fluxo G, IN-01) fala em "fornecedor habitual do item", "vínculo a
   itens" e "Acionar fornecedor usa o fornecedor do item". A **D8** põe o fornecedor responsável **na
   manutenção**. A [TASK-346](../tasks/TASK-346.md) (EPIC-034) também fala em "vínculo item ↔ fornecedor".
   Caminho possível: fornecedor *habitual* no item, como sugestão, e fornecedor *responsável* na manutenção,
   como registro do que aconteceu. A decisão é do Douglas.
3. **Funções fora da matriz:** alterar vencimento, cadastrar fornecedor pelo bot, cadastrar item ou local pelo
   bot. Viram linhas novas na matriz, com o papel de cada uma.
4. **"Nova empresa":** na matriz é ✅ ADMIN no menu; o Tiago quer movê-la para dentro de "Trocar condomínio".
   Muda só onde aparece, não quem pode usar.
5. **Contexto curto (30 min) e entrada sem menu obrigatório:** a spec (item 3) troca a chave da conversa de
   `userId` para persona. **A identidade por persona tem que vir antes do contexto curto**, senão ele é refeito.
6. **Texto livre em primeiro lugar × D11 (limite de IA):** sem problema para papéis de login; para personas
   por telefone, a matriz restringe a IA ("só abrir chamado"/"só registrar execução").
7. **Painel de entrada** ("N vencidos · N chamados · fora do SLA"): o conteúdo precisa variar por papel,
   conforme a matriz (o zelador, por exemplo, não vê custo).

**Sobreposição com o que já existe no roadmap:**
- Fluxo C (vencidos com ações) → TASK-340 · Fluxo A passo 5 (anexo) → TASK-339
- Fluxo G (fornecedor) → TASK-346 · Fluxo I (anexo sem contexto, leitura de documento) → TASK-345/347
- Fluxo E (item novo pelo chat com foto da etiqueta) → TASK-347/349
- 5.7 (métricas) → TASK-311 e TASK-343

**Ordem combinada:** (1) Onda 1 → (2) EPIC da matriz de papéis, itens 1 e 2 (política + menu por papel +
remoção do TECH; absorve WA-11 e WA-21) → (3) EPIC "Samu conversacional" (Parte B), depois de resolver os
7 conflitos e depois do item 3 da spec (identidade por persona).

**Itens do Tiago que vão para esse EPIC:** WA-04, WA-05 (parte), WA-10, WA-16 (via TASK-340), WA-20,
WA-21, WA-22 (mini-cadastro completo), fluxos A a J e as métricas 5.7.

## 5. Pendente: Locais (backoffice)

IT-01 (áreas comuns como cadastro; hoje o local é `location_label` em texto livre, até 80 caracteres),
IT-02 (Novo Item pede o tipo antes do local), IT-03 (unidades fora de uma estrutura torre/andar).
- O "item de backlog Cadastro de Locais redigido em 04/11" citado pelo Tiago **não está no repositório**:
  pedir o documento a ele.
- Relação: EPIC-038 (áreas comuns em Configurações), EPIC-039 (unidades), chamado de morador sem local
  (EPIC-027). O fluxo E da Parte B depende disso.
- Proposta: EPIC próprio "Locais e estrutura do condomínio".

## 6. Pendente: Financeiro v2 e integração com manutenção

Verificado no código: `FinancialEntry` tem só tipo, categoria, valor, descrição, data e cancelamento. A API
só tem criar, listar, cancelar e resumir. `FinancialEntryCategory` tem **4 categorias de despesa**
(FOLHA_PAGAMENTO, CONTA_CONSUMO, SERVICO_TERCEIRO, OUTRAS_DESPESAS), nenhuma de manutenção, o que explica o
FI-03.

| Item | Tipo | Nota |
|---|---|---|
| FI-01 editar e clonar | Melhoria (full-stack) | Editar exige auditoria; clonar é barato |
| FI-02 visão mensal e acumulado | Melhoria (full-stack) | `/summary` já existe; falta agrupar por mês |
| FI-03 categorias | Melhoria + decisão | Enum fixo × configurável por condomínio |
| FI-05 competência, fundo, fornecedor, documento, anexo, recorrência/parcelas | Feature | Grande; quebrar |
| FI-06 lançar e continuar | Melhoria (frontend) | Pequena |
| FI-07 filtro por categoria e busca | Melhoria (full-stack) | Pequena |
| IN-01 manutenção com custo → despesa | Feature (full-stack) | `maintenance_id` no lançamento, vínculo nos dois sentidos, evitar duplicidade, parcelas; depende de FI-03 e da D8 (fornecedor) |

Proposta: EPIC "Financeiro v2 + integração com manutenção".

## 7. Decisões de produto em aberto (do Douglas)

1. Manutenção corretiva ou emergencial reinicia o ciclo preventivo? (Tiago: por padrão não; perguntar.)
2. "Atualizar manutenção" → desambiguação "foi feita ou quer remarcar?" (Tiago propõe; entra no fluxo D.)
3. Custo da manutenção = valor pago (vira despesa) ou só referência (contrato ou garantia)?
4. Categorias financeiras: enum fixo ou configuráveis por condomínio?
5. Os 7 conflitos da seção 4.
6. Registrar manutenção com data **anterior** à última do item recalcula o vencimento a partir dela (puxa para
   trás) — manter ou só recalcular quando for a mais recente? (achado na TASK-403, 09/11)
