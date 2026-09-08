# TASK-243 — FRONTEND: Tela dedicada de fornecedores (lista + filtro + cadastro)

## Tipo
FRONTEND

## Categoria
Fornecedores / Cadastro

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Cadastro de Fornecedores pelos Usuários + Pontuação

## QA obrigatório
Sim — cadastrar um fornecedor de verdade, confirmar que aparece na lista com a pontuação certa, e
testar o filtro por categoria num navegador real.

---

## Contexto

Tela nova dedicada (não integrada à busca interativa já existente na criação de manutenção —
decisão explícita, ver EPIC-028) onde a organização cadastra e navega fornecedores da região.
Detalhe completo em `docs/superpowers/specs/2026-09-08-supplier-registry-design.md`.

## Escopo

- Nova rota dentro do layout autenticado normal (`/fornecedores` ou `/suppliers`, nome exato a
  definir na implementação).
- Lista de fornecedores da região (`city`/`state` da organização logada), com pontuação visível
  (`registrationCount`) e filtro por categoria.
- Formulário de cadastro: CNPJ, nome, telefone, categoria — cidade/estado herdados da organização
  logada (não repete o que o usuário já cadastrou na org).
- Estados de UI: loading, erro (ex.: CNPJ inválido), vazio (nenhum fornecedor na região ainda).
- Item novo no menu lateral, seguindo o padrão visual já estabelecido (TASK-222/223).

## Critérios de Aceite

- [ ] Lista mostra fornecedores da região, com pontuação
- [ ] Filtro por categoria funciona
- [ ] Cadastro de fornecedor novo funciona e reflete na lista
- [ ] Cadastro de fornecedor com CNPJ já existente (de outra organização) funciona sem erro
      confuso — mensagem clara de que já foi vinculado
- [ ] Estados de loading/erro/vazio tratados
- [ ] Responsivo (mobile e desktop, mesmo padrão do resto do sistema)
- [ ] `npm run build` sem erro
- [ ] Validado num navegador real

## Dependências
TASK-242 (endpoints) precisa estar pronta.

## Riscos
Baixo — tela nova, isolada, não altera nenhuma tela existente.

## Esforço
Médio

## Status
🔴 Não iniciada
