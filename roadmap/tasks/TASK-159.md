# TASK-159 — Backend: modelo de dados + CRUD de custo de infraestrutura

## Tipo
BACKEND

## Categoria
Admin / Financeiro

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo)

## QA obrigatório
Sim — validar que atualizar um custo não apaga o histórico, e que o cálculo de "valor vigente em
um mês" resolve corretamente quando há múltiplas vigências.

---

## Contexto

Não existe hoje nenhum conceito de custo/despesa do próprio negócio no sistema. O custo de
infraestrutura (Railway, OpenAI, S3, taxas Asaas) precisa ser lançado manualmente, já que não há
integração automática com essas faturas. Ver decisão de escopo no EPIC-020: valor fixo mensal por
categoria, e atualizar cria uma nova vigência em vez de sobrescrever — isso preserva a exatidão do
gráfico de meses passados quando uma fatura mudar de valor.

---

## Objetivo

Criar a tabela `operating_expense_rates`, o domínio, e os endpoints de listagem/criação de
vigência de custo por categoria.

---

## Escopo

### 1. Migração
- `V<próxima>__create_operating_expense_rates.sql`:
  ```sql
  CREATE TABLE operating_expense_rates (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(30) NOT NULL,
    amount_cents INT NOT NULL,
    effective_from DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  );
  CREATE INDEX idx_expense_rates_category_effective ON operating_expense_rates (category, effective_from);
  ```

### 2. Domínio
- `OperatingExpenseRate` (entity): `id`, `category` (enum `ExpenseCategory`: `RAILWAY`, `OPENAI`,
  `S3`, `ASAAS_FEES`, `OUTROS`), `amountCents`, `effectiveFrom` (`LocalDate`), `createdAt`.

### 3. Repositório
- `findAllByOrderByCategoryAscEffectiveFromDesc()` — pra listar os valores vigentes atuais (pega o
  primeiro de cada categoria no resultado).
- `findByCategoryAndEffectiveFromLessThanEqualOrderByEffectiveFromDesc(category, date, Pageable)`
  ou equivalente — pra resolver o valor vigente de uma categoria numa data específica (usado pela
  TASK-160).

### 4. Serviço + Controller
- `GET /easy-maintenance/api/v1/admin/billing/expense-rates` — retorna o valor vigente atual de
  cada categoria (uma linha por categoria, a mais recente).
- `POST /easy-maintenance/api/v1/admin/billing/expense-rates` — cria uma nova vigência
  (`category`, `amountCents`, `effectiveFrom`). Não permite `effectiveFrom` no passado anterior à
  vigência mais recente já cadastrada da mesma categoria (evita inconsistência de ordem).
- Mesmo padrão de autenticação/autorização do resto de `/admin/*`.

### 5. Testes
- Criar vigência nova não apaga a anterior (ambas continuam no banco).
- Resolver valor vigente numa data anterior a todas as vigências cadastradas retorna vazio/zero
  (categoria ainda não tinha custo lançado naquele período).
- Resolver valor vigente numa data entre duas vigências retorna a mais antiga das duas.
- `POST` com `effectiveFrom` anterior à vigência mais recente já cadastrada é rejeitado (400).

---

## Critérios de Aceite

- [x] Migração aplicada, tabela `operating_expense_rates` existe (`V87`)
- [x] `POST /admin/billing/expense-rates` cria nova vigência sem apagar a anterior
- [x] `GET /admin/billing/expense-rates` retorna o valor vigente atual de cada categoria
- [x] Suíte de testes backend passa, incluindo os casos de resolução de vigência por data (7 testes
      novos, incluindo o caso de troca de vigência no meio de uma janela de meses)
- [x] Suíte completa do backend sem regressão

## Dependências
Nenhuma.

## Riscos
Baixo — tabela nova, aditiva, sem tocar em nada existente.

## Esforço
Baixo

## Status
Concluído — QA manual aprovado por Douglas (11/08/2026). Falta só mergear
[easy-maintenance-api#31](https://github.com/douglasjava/easy-maintenance-api/pull/31) para `staging`.
