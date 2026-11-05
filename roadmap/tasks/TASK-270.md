# TASK-270 — FRONTEND: Página pública de auto-cadastro de fornecedor

## Tipo
FRONTEND

## Categoria
Fornecedores / Marketplace

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — validar em ambiente com credenciais Asaas reais (sandbox) o fluxo completo cadastro →
cobrança PIX → link de pagamento.

---

## Contexto

Página pública (`/fornecedores/cadastro`), sem login, onde o próprio fornecedor se cadastra e paga
R$15,99/mês pra ficar visível no marketplace. Consome o endpoint público da TASK-264.

## Escopo

- `_lib/publicSupplierApi.ts`: cliente axios isolado (sem `X-Org-Id`, sem cookie, sem redirect em
  401/403), mesmo espírito do `publicApi.ts` do fluxo de chamados de moradores (EPIC-027).
- `page.tsx`: formulário (documento, nome, e-mail, telefone, categoria) → submete → mostra tela de
  "Quase lá!" com o link de pagamento PIX.

## Critérios de Aceite

- [x] Formulário valida CPF/CNPJ, campos obrigatórios
- [x] Submissão bem-sucedida mostra o link de pagamento PIX
- [x] `npm run build` limpo, `eslint` sem erro novo

## Dependências
TASK-264 (endpoint `POST /public/suppliers/register`).

## Riscos
Baixo — página nova e isolada, não interfere com nenhum fluxo autenticado existente.

## Esforço
Pequeno

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `fornecedores/cadastro/_lib/publicSupplierApi.ts` | cliente axios público + `registerSupplier()` |
| `fornecedores/cadastro/page.tsx` | formulário de auto-cadastro + tela de "Quase lá!" (link PIX) |

### Verificação
`npm run build` → limpo (rota `/fornecedores/cadastro` gerada). `npx eslint
src/app/fornecedores/cadastro/` → sem erros.

## Status
🟢 Implementado e testado (build/eslint). Validação end-to-end contra o Asaas sandbox fica pra a
rodada de QA manual do Douglas.
