# TASK-QA-AUTO-007 — Testes E2E: rotas públicas abrem deslogado e privadas redirecionam

## Tipo
QA Automatizada — E2E (Playwright, repo `easy-maintenance-e2e`)

## Categoria
Frontend / Roteamento / Autenticação

## Prioridade
🟠 Alto — **Agora**

## Épico
EPIC-028 (origem: refactor `isPublicPath` da TASK-285)

## Descrição
Smoke E2E que abre, **sem sessão**, todas as rotas públicas (`/landing`, `/agendar`, `/blog`, um post
do blog, `/termos`, `/privacidade`, `/fornecedores/cadastro`, `/fornecedores/gerenciar/<token>`,
`/para-fornecedores`, `/indicador/novo`, `/obrigado`) e confirma que não houve redirect pro `/login`;
e abre rotas privadas (`/items`, `/fornecedores`, `/users`, `/private/admin/leads`) confirmando o
redirect.

## Justificativa para Automatização
- O guard de rotas públicas quebrou **4 vezes** (TASK-272/273/274 e `/agendar`) — toda página pública
  nova corre o mesmo risco, e a falha só aparece com o usuário deslogado (quem desenvolve está logado).
- `src/lib/publicPaths.test.ts` cobre a função, mas não a integração com `Shell.tsx`/`AuthContext`.
- Teste barato, estável e rápido — ideal pro `smoke.spec.ts` existente.

## Cobertura Esperada
- 1 caso por rota pública (sem redirect, sem sidebar) e 1 por rota privada (redirect pro login).
- Rodar no pipeline de `staging` antes de cada promoção pra `main`.

## Status
Backlog
