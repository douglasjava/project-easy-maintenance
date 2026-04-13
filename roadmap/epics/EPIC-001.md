# EPIC-001 — Segurança Crítica

## Status
Quase concluído — 8/9 tasks entregues (TASK-039 — 2FA — pendente, Fase 3)

## Objetivo
Eliminar todas as vulnerabilidades de segurança que comprometem a integridade da autenticação, proteção de tokens, exposição de API e controle de acesso a nível de infraestrutura.

## Descrição
O sistema possui uma base de segurança razoável (BCrypt, JWT com RSA, RBAC), mas existem falhas estruturais que precisam ser corrigidas antes de qualquer lançamento público. As mais críticas envolvem a forma como tokens JWT são gerados (chaves efêmeras) e armazenados (localStorage), além de ausência de proteção básica em endpoints públicos.

## Impacto no Produto
- **Sem este épico:** Um deploy de produção desloga todos os usuários. Um XSS rouba tokens de todos os usuários ativos. Qualquer técnico pode mapear toda a API via Swagger. Brute force é trivial no login.
- **Com este épico:** O sistema é confiável para operar em produção com clientes reais pagantes.

## Tasks Relacionadas

| ID | Título | Prioridade | Fase |
|----|--------|-----------|------|
| TASK-001 | Persistir chaves RSA JWT | 🔴 Crítico | 1 |
| TASK-002 | Migrar JWT de localStorage para cookie HttpOnly | 🔴 Crítico | 1 |
| TASK-005 | Desabilitar Swagger/OpenAPI em produção | 🟠 Alto | 1 |
| TASK-006 | Rate limiting em auth, reset e IA | 🟠 Alto | 1 |
| TASK-007 | Validação robusta de webhook Asaas | 🟠 Alto | 1 |
| TASK-010 | Auditar e rotacionar secrets no repositório | 🟠 Alto | 1 |
| TASK-011 | Restringir endpoints do Actuator em produção | 🟠 Alto | 1 |
| TASK-013 | Adicionar security headers HTTP | 🟠 Alto | 1 |
| TASK-039 | Autenticação 2FA | 🔵 Baixo | 3 |

## Critério de Conclusão do Épico
- [ ] Nenhum token JWT é invalidado por restart da aplicação
- [ ] Tokens não são acessíveis via JavaScript (HttpOnly cookies)
- [ ] Swagger inacessível em ambiente de produção
- [ ] Login com rate limit ativo (máx. 10 tentativas/minuto por IP)
- [ ] Webhook Asaas rejeitando eventos sem token válido
- [ ] Nenhuma chave de API no git history (ou rotacionadas)
- [ ] Actuator acessível apenas por IP interno ou role admin
- [ ] Headers de segurança presentes em todas as respostas HTTP
