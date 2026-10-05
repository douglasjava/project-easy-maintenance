# TASK-QA-MAN-025 — QA Manual: controle financeiro simples (EPIC-032, staging → main)

## Tipo
QA Manual — **execução manual** em homologação (`staging`), antes de promover pra `main`

## Categoria
Full-Stack / Financeiro / Relatórios

## Prioridade
🔴 Alto — dado financeiro sem edição (só cancelamento), isolamento multi-tenant, e um dos achados
corrigidos na revisão era vazamento de existência cross-organização.

## Tasks cobertas (o que está em `staging` e ainda não está em `main`)

| Task | O que entrega | PRs |
|---|---|---|
| [TASK-322](../../tasks/TASK-322.md) | `FinancialEntry`, migration V122, repository | api#154 |
| [TASK-323](../../tasks/TASK-323.md) | `FinancialEntryService` — criar/cancelar/listar/resumir | api#154 |
| [TASK-324](../../tasks/TASK-324.md) | Endpoints REST `/finance/entries`, `/finance/summary` | api#154 |
| [TASK-325](../../tasks/TASK-325.md) | Tela `/financeiro` (lançar/listar/cancelar/filtrar) | web#112 |
| [TASK-326](../../tasks/TASK-326.md) | Prestação de Contas exibe Receitas/Despesas Manuais/Saldo | web#112 |
| [TASK-327](../../tasks/TASK-327.md) | Item "Financeiro" no menu do usuário | web#112 |

O e2e automatizado (TASK-328, `tests/frontend/finance-entries.spec.ts`) foi escrito mas **nunca
executado contra um ambiente real** — este QA manual é o que de fato valida a feature antes da
promoção.

---

## Pré-condições

- Deploy de `staging` com api#154 e web#112.
- Migration `V122` aplicada no boot — conferir no log da API:
  `Successfully applied … now at version v122`.
- Dois usuários de teste na mesma organização: um com papel **ADMIN** ou **SYNDIC**, outro com
  **TECH** ou **READER** (pra validar a trava de permissão).
- Uma segunda organização (qualquer conta existente de outro tenant em staging) só pra pegar o
  `orgCode` dela no Bloco C7 — não precisa logar nela.
- Pelo menos uma manutenção **com custo registrado** (`costCents`) na organização de teste, no
  período que for usar nos testes — pra conferir que o custo de manutenção aparece certo ao lado
  dos lançamentos manuais.
- Nomes/descrições de teste prefixados com `QA-025-` pra facilitar limpeza.

**Ordem sugerida:** Bloco A (rápido) → B → C → D → E.

---

## Bloco A — Lançar e listar (happy path) 🔴 CRÍTICO

### A1 — Lançar receita
1. Logado como **ADMIN**/**SYNDIC**, abrir `/financeiro` (menu do usuário → "Financeiro").
2. "Nova receita" → categoria "Taxa condominial" → valor `1500,00` → descrição `QA-025 taxa` →
   data de hoje → "Lançar".

**Esperado:** toast de sucesso; valor digitado como "1500,00" aparece na lista como **R$ 1.500,00**
(não R$ 1,50 — esse foi um bug real corrigido na revisão, vale conferir esse valor específico com
atenção).

### A2 — Lançar despesa
"Nova despesa" → categoria "Conta de consumo" → valor `80,00` → "Lançar".

**Esperado:** aparece na lista como despesa, R$ 80,00.

### A3 — Filtro por período e tipo
1. Trocar o filtro "Tipo" pra "Receitas".

**Esperado:** só a receita do A1 aparece.

2. Trocar pra "Despesas".

**Esperado:** só a despesa do A2 aparece.

3. Voltar pra "Todos" e mudar o período pra não incluir hoje.

**Esperado:** lista vazia ("Nenhum lançamento neste período").

**Evidência:** prints da lista depois de A1, A2 e do filtro por tipo.

---

## Bloco B — Validações de negócio 🟠 ALTO

### B1 — Permissão: TECH/READER não lança nem cancela
Logado como **TECH** ou **READER**, abrir `/financeiro`.

**Esperado:** botões "Nova receita"/"Nova despesa" e "Cancelar" **não aparecem**. A lista em si
(leitura) continua visível.

### B2 — Categoria incompatível com o tipo (via API direta, já que a UI não deixa escolher errado)
```bash
curl -i -X POST -H "Content-Type: application/json" -H "Authorization: Bearer <TOKEN>" \
  -H "X-Org-Id: <ORG_CODE>" \
  -d '{"type":"EXPENSE","category":"TAXA_CONDOMINIAL","amountCents":1000,"entryDate":"<HOJE>"}' \
  https://api-staging.easymaintenance.com.br/easy-maintenance/api/v1/finance/entries
```

**Esperado:** `400`, mensagem citando que a categoria não é compatível com o tipo.

### B3 — Valor zero ou negativo
Repetir o B2 com `"amountCents": 0` e depois `"amountCents": -500` (categoria compatível).

**Esperado:** `400` nos dois, "o valor deve ser maior que zero".

### B4 — Data futura
Repetir o B2 com `"entryDate"` um dia no futuro.

**Esperado:** `400`, "a data não pode ser futura".

**Evidência:** saída dos 3 `curl`.

---

## Bloco C — Cancelamento 🔴 CRÍTICO

### C1 — Cancelar exige motivo
1. Na lista, clicar "Cancelar" num lançamento de teste.
2. Tentar confirmar com o motivo vazio, depois com menos de 5 caracteres.

**Esperado:** não deixa confirmar / mostra erro até digitar pelo menos 5 caracteres.

### C2 — Cancelamento remove da lista
Completar o cancelamento com um motivo válido.

**Esperado:** toast de sucesso; o lançamento some da lista; some também do "Resumo do período" na
Prestação de Contas (Bloco D).

### C3 — Cancelar duas vezes
Tentar cancelar o **mesmo** lançamento de novo (via API, usando o mesmo id):
```bash
curl -i -X POST -H "Content-Type: application/json" -H "Authorization: Bearer <TOKEN>" \
  -H "X-Org-Id: <ORG_CODE>" -d '{"reason":"segunda tentativa"}' \
  https://api-staging.easymaintenance.com.br/easy-maintenance/api/v1/finance/entries/<ID>/cancel
```

**Esperado:** `409` (já cancelado), não `200`/`204` nem `500`.

### C4 — Segurança: lançamento de outra organização não pode ser cancelado 🔴
Com o token do usuário de teste (organização A) e o `id` de um lançamento **real de outra
organização** (se não tiver um à mão, usar qualquer id pequeno improvável de existir na própria
org, ex. `1`):
```bash
curl -i -X POST -H "Content-Type: application/json" -H "Authorization: Bearer <TOKEN_ORG_A>" \
  -H "X-Org-Id: <ORG_CODE_A>" -d '{"reason":"teste cross-org"}' \
  https://api-staging.easymaintenance.com.br/easy-maintenance/api/v1/finance/entries/<ID_DE_OUTRA_ORG>/cancel
```

**Esperado:** `404` — **nunca** `403`. Esse é justamente o achado da revisão (vazamento de
existência cross-tenant): antes do fix, um lançamento ativo de outra organização dava 403
("não pertence a essa organização"), o que já revela que o id existe e está ativo em outro tenant.
Agora precisa dar 404 igual a um id que nunca existiu — sem diferença observável entre os dois
casos.

**Evidência:** saída dos 2 `curl` (C3 e C4) com o código de status bem visível.

---

## Bloco D — Prestação de Contas (`/reports`) 🟠 ALTO

### D1 — Receita/despesa manual aparece ao lado do custo de manutenção
1. Lançar uma receita e uma despesa manual (se já não tiver do Bloco A) no mesmo período de uma
   manutenção com custo registrado.
2. Ir em `/reports?tab=prestacao`, ajustar o período pra cobrir os dois, "Visualizar relatório".

**Esperado:** "Resumo do período" mostra **Receitas**, **Despesas manuais** e **Saldo do período**,
além de "Custo total" (das manutenções, como já era antes). O saldo bate com:
`Receitas − Despesas manuais − Custo de manutenção`.

### D2 — Baixar PDF reflete os mesmos números
"Baixar PDF" e abrir o arquivo.

**Esperado:** as mesmas linhas (Receitas/Despesas manuais/Saldo) aparecem no PDF, com os mesmos
valores da tela.

### D3 — Organização sem nenhum lançamento financeiro não quebra
Trocar pra um período em que a organização não tem nenhum `FinancialEntry` (ex.: mês passado, se
só lançou hoje).

**Esperado:** Receitas e Despesas manuais aparecem como **R$ 0,00** (não "—", não `NaN`, não
`undefined`); Saldo = só o negativo do custo de manutenção daquele período (ou R$ 0,00 se também
não teve manutenção). O relatório continua funcionando normalmente.

**Evidência:** print da tela + o PDF baixado do D2.

---

## Bloco E — Regressão dos achados da revisão 🟡 MÉDIO

### E1 — Valor com separador de milhar (o bug original)
No formulário de lançamento, digitar exatamente `1500` (sem pontuação) e depois, em outro
lançamento, `1.500,00` (com a pontuação já formatada).

**Esperado:** os dois resultam no mesmo valor exibido, **R$ 1.500,00** — nunca R$ 1,50 nem R$ 15,00.

### E2 — Mobile (390px, ou celular de verdade)
Abrir `/financeiro` e o modal de "Nova receita"/"Nova despesa".

**Esperado:** sem scroll horizontal; os campos (categoria, valor, data, descrição) ficam legíveis e
usáveis no modal.

---

## Limpeza
- Lançamentos de teste: cancelar pela própria UI (`DELETE` não existe — é sempre cancelamento com
  motivo, então "limpar" aqui é cancelar os de teste que ainda estiverem ativos e não forem mais
  necessários pra inspeção).
- Se quiser remover de vez pro banco não acumular dado de teste:
  `UPDATE financial_entries SET deleted_at = NOW(), cancelled_at = NOW(), cancelled_by = <seu_user_id>, cancel_reason = 'Limpeza QA-025' WHERE description LIKE 'QA-025%' AND deleted_at IS NULL;`

## Critério de aprovação pra promover `staging` → `main`
Blocos **A**, **C3**, **C4** e **D1, D3** são obrigatórios. B2–B4 (validação via `curl`) podem ser
aprovados com uma passada rápida, já que são cobertos por teste automatizado
(`FinancialEntryServiceTest`) — o objetivo aqui é confirmar que o comportamento documentado
realmente aparece via API real, não reproduzir toda a suíte manualmente. E1/E2 são regressão dos
achados da revisão de código, não têm teste automatizado de UI ainda (TASK-328 não foi executado
contra ambiente real) — por isso entram aqui.

## Riscos conhecidos
- TASK-328 (e2e automatizado) nunca rodou contra um ambiente real — este QA manual é, por ora, a
  única validação de ponta a ponta da feature. Depois que `npm run setup:db` + API/frontend
  estiverem de pé num ambiente controlado, vale rodar `tests/frontend/finance-entries.spec.ts` e
  anexar o resultado aqui.
- Lançamento financeiro nunca é editado, só cancelado — um erro de digitação some da visão normal
  (soft-delete), mas o registro em si continua no banco (auditoria). Isso é intencional (ver spec),
  não é bug.
- Cancelamentos concorrentes (duas abas cancelando o mesmo lançamento ao mesmo tempo) não têm
  lock otimista — o mesmo comportamento já existente em `Maintenance.cancel`. Risco aceito,
  registrado no ledger da implementação, não bloqueia esta promoção.

## Status
Backlog — aguardando execução manual pelo Douglas em staging
