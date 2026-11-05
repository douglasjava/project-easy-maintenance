# TASK-272 — BUGFIX: Páginas públicas de fornecedor redirecionavam pro login

## Tipo
BUGFIX

## Categoria
Fornecedores / Marketplace / Frontend

## Prioridade
🔴 Alto — bloqueava por completo o fluxo público de auto-cadastro (C4 do QA)

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — Douglas re-testa C4/C6 de [TASK-QA-MAN-022](../QA/tasks/TASK-QA-MAN-022.md) a partir desta
correção.

---

## Contexto

Achado de QA do Douglas (13/09/2026, cenário C4): `/fornecedores/cadastro` estava sendo
redirecionada pro `/login` em vez de renderizar como página pública.

### Causa raiz

`middleware.ts` não faz nenhuma proteção de rota — é só passthrough (`NextResponse.next()`), com
um comentário explícito no próprio arquivo explicando por quê: o cookie `accessToken` é HttpOnly no
domínio da API (Railway), nunca chega no servidor Next.js num domínio diferente
(easymaintenance.com.br). Toda a proteção de rota é feita client-side, em `Shell.tsx`: uma
allowlist (`isAuth`) decide quais paths renderizam full-screen, sem sidebar e sem exigir login; tudo
que **não** está nessa lista cai no guard padrão (`if (!token) window.location.replace("/login")`).

As páginas novas `/fornecedores/cadastro` (TASK-270) e `/fornecedores/gerenciar/[token]`
(TASK-271) foram implementadas seguindo o plano à risca (formulário público, cliente de API
isolado sem `X-Org-Id`/cookie), mas **nenhuma das duas foi adicionada à allowlist do `Shell.tsx`**
— gap real da implementação: o plano documentou o isolamento do cliente HTTP, mas não verificou o
guard de rota client-side que envolve todo o app, que é um mecanismo cross-cutting fora do escopo
direto das duas tasks.

### Comparação com o padrão correto (já existente)

`/chamados/[orgCode]` (fluxo público de chamados de morador, EPIC-027) já resolve exatamente esse
problema com `pathname?.startsWith("/chamados/")` na mesma allowlist.

## Escopo

Adicionar as duas rotas novas na allowlist `isAuth` de `Shell.tsx`:
```tsx
pathname?.startsWith("/fornecedores/cadastro") ||
pathname?.startsWith("/fornecedores/gerenciar/") ||
```
(`/fornecedores` em si, a listagem autenticada do síndico, continua **fora** da allowlist —
propositalmente, ela exige login.)

## Critérios de Aceite

- [x] `/fornecedores/cadastro` renderiza sem exigir login
- [x] `/fornecedores/gerenciar/<token>` renderiza sem exigir login
- [x] `/fornecedores` (listagem do síndico) continua exigindo login normalmente
- [x] `npm run build` limpo

## Dependências
TASK-270, TASK-271.

## Riscos
Baixo — mudança de 2 linhas, escopo restrito à condição booleana já existente.

## Esforço
Trivial

## Implementação

### Arquivos modificados
`src/components/Shell.tsx` — 2 linhas adicionadas na condição `isAuth`.

### Decisões tomadas durante a implementação
- Confirmado via `git diff staging -- src/components/Shell.tsx` que a mudança é isolada (só as 2
  linhas novas).
- `npx eslint src/components/Shell.tsx` acusa 1 erro (`react-hooks/set-state-in-effect`, linha do
  `setCanRenderPrivate(false)` dentro de um `useEffect`) — confirmado **pré-existente** rodando o
  eslint contra a versão do arquivo em `staging` (mesmo erro, mesma linha). Não introduzido por
  esta correção, fora de escopo consertar aqui.

### Verificação
`npm run build` → limpo, rotas `/fornecedores/cadastro` e `/fornecedores/gerenciar/[token]`
continuam geradas normalmente.

## Status
🟢 Corrigido. Aguardando Douglas repetir C4/C6 do QA manual pra confirmar.
