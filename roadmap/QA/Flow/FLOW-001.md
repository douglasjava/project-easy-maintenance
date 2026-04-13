# FLOW-001 — Autenticação e Sessão

## Criticidade
🔴 CRITICAL

## Launch Relevance
Bloqueador absoluto — qualquer falha aqui impede o uso do produto por todos os usuários.

## Tasks Relacionadas
- TASK-001 — Persistir chaves RSA JWT
- TASK-002 — Migrar JWT de localStorage para cookie HttpOnly
- TASK-006 — Rate limiting em auth, reset e IA

## Descrição do Fluxo

O usuário acessa a tela de login, insere credenciais válidas e recebe um cookie `HttpOnly` com o token JWT. O token é assinado com chave RSA persistida no ambiente (não gerada em memória). A sessão sobrevive a restarts do servidor. O logout remove o cookie. Tentativas excessivas de login são bloqueadas por rate limiting.

## Camadas Impactadas
- **Backend:** `AuthorizationServerConfig`, `AuthController`, `RsaKeyGenerator`
- **Frontend:** `AuthContext.tsx`, `apiClient.ts`, middleware de autenticação
- **Infra:** Railway env vars (`JWT_RSA_PRIVATE_KEY`, `JWT_RSA_PUBLIC_KEY`)

## Cenários Críticos

| Cenário | Tipo | Cobertura Atual |
|---------|------|----------------|
| Login com credenciais válidas | Happy path | Manual (TASK-002) |
| Token no cookie HttpOnly, não no localStorage | Segurança | Manual |
| Sessão sobrevive ao restart do servidor | Confiabilidade | Manual (TASK-001) |
| Logout remove cookie | Happy path | Manual |
| 11ª tentativa de login → 429 | Rate limiting | Manual (TASK-006) |
| Reset de senha (4ª tentativa no mesmo e-mail) → 429 | Rate limiting | Manual |
| Rota protegida sem autenticação → redirect para login | Auth guard | E2E (TASK-045) |
| Flash de tela branca no redirect | UX | E2E (TASK-045) |

## Validação Recomendada
- **Manual:** [MTD-001](../MTD/MTD-001.md) — executar antes do launch
- **Automatizada:** [TASK-QA-AUTO-003](../tasks/TASK-QA-AUTO-003.md) — rate limiting em integração

## Gaps
- Teste automatizado de persistência de sessão após restart (apenas manual descrito em TASK-001)
- Cobertura de renovação automática de token (se refresh token implementado)

## Status de Validação
- [ ] Happy path validado manualmente
- [ ] Cookie HttpOnly confirmado via DevTools
- [ ] Sessão pós-restart testada
- [ ] Rate limiting testado em staging
- [ ] Middleware de auth sem flash de tela (TASK-045 concluída — verificar E2E)
