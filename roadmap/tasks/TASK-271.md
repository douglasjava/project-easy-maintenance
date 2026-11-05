# TASK-271 — FRONTEND: Página pública de gestão via link mágico

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

Última task do plano. Página pública (`/fornecedores/gerenciar/[token]`), sem login, onde o
fornecedor consulta seu status de assinatura e atualiza telefone/categoria usando o link mágico
recebido por e-mail na ativação (TASK-265).

## Escopo

- Adiciona `getManagedSupplier`/`updateManagedSupplier` ao `publicSupplierApi.ts` (TASK-270).
- `page.tsx`: carrega o perfil pelo token, mostra badge de visibilidade + status da assinatura,
  formulário de telefone/categoria.

## Critérios de Aceite

- [x] Token válido mostra perfil + status corretos
- [x] Token inválido mostra mensagem de erro amigável
- [x] Atualização salva e reflete na tela
- [x] `npm run build` limpo, `eslint` sem erro novo

## Dependências
TASK-266 (endpoints `GET`/`PUT /public/suppliers/manage/{token}`), TASK-270 (`publicSupplierApi.ts`).

## Riscos
Baixo — página nova e isolada.

## Esforço
Pequeno

## Implementação

### Arquivos criados
`fornecedores/gerenciar/[token]/page.tsx`.

### Arquivos modificados
`fornecedores/cadastro/_lib/publicSupplierApi.ts` — `SupplierManageResponse`,
`getManagedSupplier`, `updateManagedSupplier`.

### Decisões tomadas durante a implementação
- O rascunho do plano usava `use(params: Promise<{token}>)` (padrão de Server Component
  assíncrono). Trocado por `useParams<{ token: string }>()` — o repo já usa esse padrão em outra
  rota dinâmica de cliente (`chamados/[orgCode]/page.tsx`), então segui o padrão real existente em
  vez do rascunho do plano.

### Verificação
`npm run build` → limpo (rota `/fornecedores/gerenciar/[token]` gerada, dinâmica). `npx eslint
src/app/fornecedores/gerenciar/` → sem erros. `npm test` → 107/110 (as mesmas 3 falhas
pré-existentes em `middleware.test.ts`, não relacionadas a esta task).

Com esta task, as 12 tasks do plano
(`docs/superpowers/plans/2026-09-11-supplier-marketplace-monetization.md`) estão concluídas.

## Status
🟢 Implementado e testado (build/eslint). Validação end-to-end fica pra a rodada de QA manual do
Douglas no final do épico — ver plano de teste consolidado em `QA/tasks/` (a criar).
