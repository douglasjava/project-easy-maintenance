# TASK-269 — FRONTEND: `/fornecedores` — CPF/CNPJ + botão "Solicitar Orçamento"

## Tipo
FRONTEND

## Categoria
Fornecedores / Marketplace

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — coberto pela rodada de QA manual única no final do épico.

---

## Contexto

Primeira task de frontend da Fase 2. Alinha a tela existente com o backend generalizado
(TASK-260, `cnpj`→`document`) e adiciona a UX de "Solicitar Orçamento" (decisão de escopo #4 do
spec): botão no grid abre um modal, registra a solicitação no backend e já abre o WhatsApp do
fornecedor com a mensagem pronta.

## Escopo

- `src/app/fornecedores/page.tsx`: campo `cnpj` → `document` em tipo/formulário/payload;
  `maskCNPJ`/`isValidCNPJ` → `maskCPFCNPJ`/`isValidCPFCNPJ` (já existentes em `@/lib/docMask`).
- Coluna "Ações" na tabela desktop + botão no card mobile — abre modal de "Solicitar Orçamento".
- Modal: campo de texto livre (resumo da necessidade), submete `POST
  /suppliers/{id}/budget-request` e abre `wa.me/55<telefone>?text=<mensagem>` numa nova aba.

## Critérios de Aceite

- [x] Formulário de cadastro aceita CPF ou CNPJ, mesma máscara/validação
- [x] Grid (desktop e mobile) exibe o documento mascarado corretamente
- [x] Botão "Solicitar Orçamento" abre modal, registra a solicitação e abre o WhatsApp
- [x] `npm run build` limpo, `eslint` sem erro novo

## Dependências
TASK-260 (`document` no backend), TASK-263 (endpoint `budget-request`).

## Riscos
Baixo — mudança isolada numa única página, sem alterar contrato consumido por outras telas.

## Esforço
Pequeno

## Implementação

### Arquivos modificados
`src/app/fornecedores/page.tsx` — rename `cnpj`→`document` em todo o arquivo (tipo, form, payload,
exibição), novo estado/handler do modal de orçamento, coluna/botão de ação no grid, modal no fim
da página.

### Verificação
`npm run build` → limpo (rota `/fornecedores` gerada). `npx eslint src/app/fornecedores/page.tsx`
→ sem erros.

Branch `feature/EPIC-028-fase2-marketplace` no repo `easy-maintenance-web` (criada a partir de
`staging`, mesmo padrão do repo `api`).

## Status
🟢 Implementado e testado (build/eslint). Validação end-to-end contra a API real fica pra a rodada
de QA manual do Douglas no final do épico.
