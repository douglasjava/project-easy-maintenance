# TASK-002 — Migrar JWT de localStorage para cookie HttpOnly

## Tipo
Segurança

## Categoria
Backend / Frontend / Segurança

## Prioridade
🔴 Crítico

## Fase
1 — Antes do lançamento

## Épico
EPIC-001 — Segurança Crítica

## Descrição
O `AuthContext.tsx` armazena o access token JWT em `localStorage` (ou `sessionStorage` no modo sem "remember me"). `localStorage` é acessível por qualquer JavaScript executado na página, incluindo scripts de terceiros, extensões de browser e qualquer XSS.

A mitigação correta é usar um cookie `HttpOnly; Secure; SameSite=Strict`, que o browser envia automaticamente mas que JavaScript não consegue ler.

## Problema
Um ataque XSS (através de dependência npm comprometida, CDN de terceiro ou script injetado) consegue executar `document.cookie` para exfiltrar o token, impersonate qualquer usuário e manter acesso indefinido.

## Impacto
- Roubo de sessão via XSS em qualquer ponto da aplicação
- Comprometimento de múltiplos usuários simultaneamente em caso de XSS persistente
- Tokens roubados podem ser usados enquanto válidos, sem mecanismo de revogação

## Dependências
- TASK-001 deve estar concluída (RSA keys persistidas)
- Requer mudança coordenada em backend (Set-Cookie no login) e frontend (remover localStorage)

## Critérios de Aceite
- [ ] Endpoint `/auth/login` retorna `Set-Cookie: accessToken=...; HttpOnly; Secure; SameSite=Strict`
- [ ] Frontend NÃO armazena token em `localStorage` ou `sessionStorage`
- [ ] `apiClient.ts` NÃO injeta `Authorization: Bearer ...` manualmente (cookie é enviado automaticamente)
- [ ] Logout limpa o cookie via `Set-Cookie` com `Max-Age=0`
- [ ] Token não é legível via `document.cookie` no browser
- [ ] Autenticação funciona corretamente após migração

## Subtasks
- [ ] Backend: modificar `AuthController` para retornar `Set-Cookie` em vez de body com token
- [ ] Backend: configurar `SameSite=Strict`, `Secure`, `HttpOnly` no cookie
- [ ] Backend: configurar `withCredentials: true` no CORS para aceitar cookies
- [ ] Frontend: remover todo uso de `localStorage.setItem/getItem` para tokens
- [ ] Frontend: configurar `axios` com `withCredentials: true`
- [ ] Frontend: remover injeção manual do header `Authorization`
- [ ] Testar fluxo completo de login, navegação e logout
- [ ] Testar que token não é visível no DevTools > Application > Local Storage

## Esforço
Médio (1-2 dias)

## Risco de não fazer
Qualquer XSS na aplicação resulta em roubo em massa de sessões. Com volume de usuários crescendo, o risco aumenta proporcionalmente.

## Status
Concluído
