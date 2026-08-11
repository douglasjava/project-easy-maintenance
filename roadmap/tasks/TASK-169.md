# TASK-169 — BUGFIX: custos "Outros" com labels diferentes conflitavam entre si

## Tipo
BUGFIX

## Categoria
Admin / Financeiro (EPIC-020)

## Prioridade
🔴 Crítico

## Épico
—

## QA obrigatório
Sim — cadastrar dois "Outros" com labels diferentes e confirmar que os dois aparecem na lista e
somam no total financeiro do mês.

---

## Contexto

Achado por Douglas em uso real: ao tentar cadastrar um segundo custo "Outros" (GoDaddy) além de um
já existente (Vercel), a API respondeu `400 rules-invalid`: "A data de vigência deve ser posterior
à vigência mais recente já cadastrada para esta categoria".

Investigação encontrou a causa raiz — mais grave que a mensagem de erro em si: `OperatingExpenseRateService`
tratava a categoria `OUTROS` inteira como uma única linha de vigência, ignorando o `label` (campo
adicionado na TASK-162/V88 justamente pra permitir múltiplos itens dentro de "Outros"). Duas
consequências:

1. **Validação bloqueava indevidamente** um segundo item de "Outros" com vigência na mesma data (ou
   depois) de um item *diferente* já cadastrado — o bug relatado.
2. **`resolveAmountCents` (usado no total financeiro) também só considerava um item por categoria**
   — ou seja, mesmo que o cadastro tivesse funcionado por acaso (datas crescentes), o total do
   dashboard financeiro somaria só o "Outros" mais recente, **ignorando silenciosamente os demais**.
   O total financeiro já estava incorreto antes desta correção, não é uma regressão nova.

Confirmado com Douglas: a intenção é multi-item — cada label de "Outros" é seu próprio custo
independente, todos somados no total financeiro do mês.

## Objetivo

Cada `(categoria, label)` vira sua própria linha de vigência independente. RAILWAY/OPENAI/S3/ASAAS_FEES
continuam com um único item (label sempre nulo, comportamento inalterado). OUTROS pode ter vários
itens simultâneos, todos somados no total financeiro.

## Escopo

- `OperatingExpenseRateRepository`: os dois finders por `category` (`findFirstByCategoryOrderByEffectiveFromDesc`,
  `findFirstByCategoryAndEffectiveFromLessThanEqualOrderByEffectiveFromDesc`) trocados por um único
  `findByCategory(ExpenseCategory)` — agrupamento e resolução por `label` ficam no service (mesmo
  motivo de outras decisões de "sem GROUP BY em SQL" já usadas neste épico).
- `OperatingExpenseRateService`:
  - `create()`: valida vigência por `(category, label)`, não só `category`. Validação nova: `label`
    só é aceito quando `category = OUTROS` (protege o invariante de identidade).
  - `listCurrentRates()`: retorna uma linha por `(category, label)` com pelo menos uma vigência,
    não uma por categoria.
  - `resolveAmountCents(category, data)`: agora **soma** o valor vigente de todos os itens da
    categoria na data (antes retornava só um). Item sem nenhuma vigência iniciada até a data é
    ignorado na soma (não entra como 0 nem quebra os demais).
- Frontend: nenhuma mudança necessária — `ExpenseRatesSection.tsx` já renderiza a lista de forma
  genérica (`rates.map(...)`), então múltiplas linhas de "Outros" já aparecem corretamente.

## Critérios de Aceite

- [x] Cadastrar um segundo "Outros" com label diferente não é bloqueado pela vigência de outro item
- [x] Os dois itens aparecem em `GET /expense-rates`
- [x] O total financeiro do mês soma os dois valores (não só o mais recente)
- [x] RAILWAY/OPENAI/S3/ASAAS_FEES continuam com comportamento de item único, inalterado
- [x] Cadastrar o mesmo label duas vezes com vigência não-crescente continua bloqueado
- [x] Categoria diferente de OUTROS com label preenchido é rejeitada (defensivo)
- [x] Suíte completa sem regressão

## Dependências
Nenhuma (correção sobre o que já existe desde TASK-159/162, EPIC-020).

## Riscos
Baixo — mudança isolada num serviço já coberto por testes; sem migração de schema (dado existente
já tem `label` correto, só a lógica de leitura/validação mudou).

## Esforço
Pequeno

## Status
Em Validação — branch `bugfix/TASK-169-outros-multiplos-itens`, commit `71ae5ec`
(easy-maintenance-api). QA manual pendente (cadastrar GoDaddy de verdade e conferir o total).
