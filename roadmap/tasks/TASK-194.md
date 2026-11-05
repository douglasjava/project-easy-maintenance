# TASK-194 — Frontend: seções de cadastro de despesas e regras de comissão manual

## Tipo
FRONTEND

## Categoria
Admin / Financeiro

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Fase 2

## QA obrigatório
Sim — QA manual: cadastrar despesa em cada categoria, remover, cadastrar regra de comissão manual,
encerrar uma regra ativa, conferir que os cards/gráfico da TASK-193 refletem os lançamentos novos
depois de salvar.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-23-financial-module-design.md`.

Depende da TASK-191 (endpoints de despesa/regra de comissão) e da TASK-193 (a página precisa
existir). Fecha o pedido de Douglas de ter "um lugar de fazer o cadastro das despesas" e de
"exibir comissões manuais" — sem esta task, os endpoints da TASK-191 não têm UI nenhuma.

## Objetivo

Duas seções novas na página `/private/admin/financials`: "Despesas" (tabela + filtro + cadastro) e
"Comissões manuais" (tabela + cadastro + encerrar).

## Escopo

### 1. `labels.ts` — label map novo

```typescript
export const expenseCategoryLabelMap: Record<string, string> = {
    FORNECEDOR: "Fornecedor",
    INFRA: "Infraestrutura",
    MARKETING: "Marketing",
    IMPOSTOS_TAXAS: "Impostos/Taxas",
    FOLHA_PROLABORE: "Folha/Pró-labore",
    JURIDICO_CONTABIL: "Jurídico/Contábil",
    FERRAMENTAS_SAAS: "Ferramentas/SaaS",
    OUTROS: "Outros"
};
```

Substitui o `expenseCategoryLabelMap` atual (categorias antigas `RAILWAY/OPENAI/S3/ASAAS_FEES`) —
mesmo nome de export, conteúdo novo.

### 2. `ExpenseFormModal.tsx` (novo, `src/app/private/admin/financials/`)

Modal Bootstrap (mesmo padrão de `LeadFormModal.tsx`/`CancelMaintenanceModal.tsx`), só criação (sem
edição, decisão da spec): categoria (`<select>` com `expenseCategoryLabelMap`), descrição (texto),
valor (input formatado em R$, mesmo padrão de máscara monetária já usado em outros formulários
admin), data (input date, default hoje).

### 3. `ExpensesSection.tsx` (novo)

Tabela com filtro por categoria + período (mesmo padrão de filtro de `LeadListSection.tsx`): colunas
Categoria, Descrição, Valor, Data, Ações (Remover). Botão "+ Nova despesa" abre `ExpenseFormModal`.
`onSaved`/`onRemoved` disparam refetch da lista e notificam a página pai (via prop `onChanged`) pra
recarregar os cards/gráfico da TASK-193, mesmo padrão de callback já usado em `ExpenseRatesSection`
atual.

### 4. `CommissionRuleFormModal.tsx` (novo)

Modal só de criação: nome de quem recebe (texto), percentual (input numérico 0-100, convertido pra
fração 0-1 no payload), data de início (default hoje).

### 5. `ManualCommissionRulesSection.tsx` (novo)

Tabela: Nome, Percentual, Vigência (de/até, "—" se ainda ativa), Status (badge Ativa/Encerrada,
mesmo `StatusBadge` já usado em outras telas admin), Ações (Encerrar, só visível se ativa). Botão
"+ Nova regra" abre `CommissionRuleFormModal`.

### 6. `financials/page.tsx` (TASK-193) — adiciona as duas seções

```tsx
<ExpensesSection onChanged={fetchFinancials} />
<ManualCommissionRulesSection onChanged={fetchFinancials} />
```

### 7. Testes / verificação
- `npm run build` limpo.
- QA manual (ver "QA obrigatório").

## Critérios de Aceite

- [ ] "+ Nova despesa" cria lançamento nas 8 categorias, aparece na tabela, remove funciona
- [ ] Filtro de despesas por categoria e período funciona
- [ ] "+ Nova regra" cria regra de comissão manual, aparece na tabela como "Ativa"
- [ ] "Encerrar" muda o status pra "Encerrada" sem remover a linha da tabela
- [ ] Cadastrar despesa ou regra e voltar pra tela reflete nos cards/gráfico (TASK-193) depois de
      recarregar
- [x] `npm run build` limpo

**Nota**: os 5 itens acima (exceto build) dependem de clicar de verdade na tela — não pude validar
visualmente, mesma limitação já registrada em tasks anteriores (tela exige login, sem credenciais
de teste). Implementação segue a spec e consome os endpoints da TASK-191, já com teste automatizado
cobrindo o contrato. Aguardando Douglas testar em navegador real — isso fecha a QA de toda a
Fase 2 (TASK-190 a TASK-194) numa passada só, já que tudo está na mesma branch.

## Dependências
**TASK-191** (endpoints) e **TASK-193** (página onde as seções entram).

## Riscos
Baixo — extensão aditiva da página já criada na TASK-193, mesmo padrão de modal/tabela já usado em
Leads (EPIC-021 Fase 2) e Afiliados.

## Esforço
Médio

## Status
✅ Implementada e commitada (23/08/2026) na branch `feature/financial-module-v2`
(`easy-maintenance-web`, commit `6d0c54a`). `npm run build` limpo. **Não validada visualmente por
mim** — mesma limitação já registrada em tasks anteriores (tela exige login, sem credenciais de
teste). Última das 5 tasks da Fase 2 — backend e frontend 100% prontos, aguardando Douglas testar
local e em staging antes de abrir PR.
