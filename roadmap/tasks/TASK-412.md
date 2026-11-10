# TASK-412 — BUG: Samu descarta o valor do lançamento financeiro quando vem sem "R$"/"reais" (EPIC-031)

## Tipo
BUGFIX — BACKEND

## Categoria
Assistente WhatsApp (Samu) / Financeiro

## Prioridade
🟠 Alto — fluxo principal do lançamento pelo WhatsApp: o usuário diz o valor e o Samu pergunta de novo.

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · achado na linha de base da [TASK-411](TASK-411.md)

## QA obrigatório
Sim — regra de leitura de valor do lançamento financeiro.

---

## Contexto
Linha de base da TASK-411 (09/11/2026), casos `fin-05` e `fin-07`, 3 de 3 rodadas:

| Mensagem | A IA devolve | O Samu faz |
|---|---|---|
| "aluguel do salão de festas, recebi 300" | `custo=300` ✅ | descarta e pergunta o valor (`FIN_HOW`) |
| "lançar despesa de salário do porteiro 2.100" | `custo=2100` ✅ | descarta e pergunta o valor (`FIN_HOW`) |

`AssistantFinancialEntryService.start` lê o valor do texto primeiro (`RegistrationParser.parseCostCents`) e só usa o
da IA se `mentionsMoney(text)` for verdadeiro (regra da Onda 1: a IA não pode inventar o valor).

- `parseCostCents` só acha número com "R$", "reais"/"conto", um verbo de pagamento colado ("paguei 300") ou a mensagem
  inteira sendo o número.
- `MONEY_HINT` não tem as palavras do financeiro: "recebi", "receita", "despesa", "entrou", "entrada".
- Já funciona: "multa do morador do 101 de 150 reais" (sufixo "reais") e "paguei a administradora, 1.287,85" ("paguei"
  é pista de dinheiro, então o valor da IA vale).

## Escopo
- No **lançamento financeiro**, aceitar o `custo` da IA quando o **número aparece no texto** (mesmo valor em centavos de
  algum número da mensagem: "2.100" → 210000, "300" → 30000). Isso prova que a IA não inventou o valor.
- ~~Pistas de dinheiro do financeiro: "recebi", "receita", "despesa", "entrou", "entrada".~~ **Descartado na
  execução.** Com essas palavras como pista, "lançar despesa de luz" aceitaria um valor que a IA inventou. A regra do
  número no texto já cobre os dois casos e é mais segura.
- Continua valendo: o número do texto vence o da IA, e um valor que não aparece no texto é descartado.

## Fora de escopo
- Valor por extenso ("trezentos reais") — já cai na pergunta `FIN_HOW`; tratar à parte, se aparecer em teste.
- Mudar o prompt do classificador ([TASK-410](TASK-410.md)).

## Critérios de Aceite
- [x] "aluguel do salão de festas, recebi 300" → cartão com R$ 300,00, sem perguntar o valor
- [x] "lançar despesa de salário do porteiro 2.100" → R$ 2.100,00
- [x] Valor da IA que **não** está no texto continua descartado (ex.: texto "conta de luz", IA `custo=200` → pergunta o valor)
- [x] Número que não é valor não vira valor por engano (ex.: "multa do apto 302", **mesmo com** a IA devolvendo `302` → pergunta)
- [x] Registro de manutenção sem mudança de comportamento (testes da Onda 1 verdes)
- [x] Casos `fin-05` e `fin-07` da avaliação: o runner da TASK-411 deixa de marcar `custo` como inventado — PR
  [api#188](https://github.com/douglasjava/easy-maintenance-api/pull/188) (`grounded` usa `amountInText` no financeiro)
- [x] `mvn test` sem regressão — 1813/1813

## Dependências
Nenhuma. Pode ir antes da [TASK-410](TASK-410.md).

## Riscos
Número de unidade/apartamento confundido com valor ("apto 302"). Por isso a regra exige que a **IA** tenha devolvido
o valor e que ele bata com um número do texto: não basta haver um número na mensagem.

## Implementação (10/11/2026)
Branch `bugfix/TASK-412-financial-amount-grounding` (a partir de `staging`) · PR
[api#187](https://github.com/douglasjava/easy-maintenance-api/pull/187).
- `AssistantFinancialEntryParser.amountInText(cents, text)` — o valor da IA é um número solto da mensagem (300, 2.100,
  1.287,85). Não contam número de unidade (logo após apto, bloco, sala, casa, torre, nº…), data (03/11) nem hora (10:30).
- `AssistantFinancialEntryService.start` — o texto vence; o valor da IA vale se o texto fala de dinheiro **ou** se
  `amountInText` confirma. Registro de manutenção inalterado.
- Testes: +2 no parser e +4 no serviço.
- Risco que sobra: "a taxa do 101", sem palavra de unidade, com a IA devolvendo `101`. O cartão mostra o valor para confirmar.

## Status
✅ Concluída — em produção (`main`) em 10/11/2026: api [#187](https://github.com/douglasjava/easy-maintenance-api/pull/187)
+ [#188](https://github.com/douglasjava/easy-maintenance-api/pull/188) → promoção
[#189](https://github.com/douglasjava/easy-maintenance-api/pull/189). `mvn test` na `staging`: 1822, 0 falhas.
