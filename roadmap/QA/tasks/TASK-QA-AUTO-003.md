# TASK-QA-AUTO-003 — Testes de Integração: Rate Limiting nos Endpoints de Autenticação

## Tipo
QA Automatizada — Integração (API)

## Categoria
Segurança / Autenticação / Backend

## Prioridade
🟠 Alto

## Épico
EPIC-001 — Segurança Crítica

## Flow relacionado
[FLOW-001](../Flow/FLOW-001.md) | [FLOW-007](../Flow/FLOW-007.md)

## Descrição
Criar testes de integração que validam o comportamento do rate limiting configurado na TASK-006 para os endpoints de autenticação e reset de senha. Garantir que os limites configurados em `application.properties` estão sendo respeitados e que a resposta 429 está no formato correto.

## Justificativa para Automatização
- Rate limiting é configurável via properties — mudanças acidentais de configuração podem desabilitar a proteção
- Testes manuais de rate limiting são trabalhosos e raramente executados em cada deploy
- Regressão de rate limiting é invisível até um incidente de segurança

## Tecnologias
- JUnit 5
- MockMvc ou `WebTestClient` (Spring Boot Test)
- TestContainers (MySQL, se necessário para contexto completo)
- `@SpringBootTest(webEnvironment = RANDOM_PORT)`

## Cobertura Esperada

### Endpoint /auth/login (por IP)
- [ ] 10 requests de login com senha errada → 401 em todos
- [ ] 11ª request do mesmo IP → HTTP 429
- [ ] Resposta 429 contém header `Retry-After` com valor > 0
- [ ] Resposta 429 tem `Content-Type: application/problem+json`
- [ ] Request do mesmo IP após o período de `Retry-After` → volta a funcionar (401 novamente)
- [ ] Request de IP diferente após o bloqueio → não bloqueado (isolamento por IP)

### Endpoint /auth/password-reset/request (por e-mail)
- [ ] 3 requests para o mesmo e-mail → 200/204 em todos
- [ ] 4ª request para o mesmo e-mail em < 15 min → HTTP 429
- [ ] Resposta 429 contém `Retry-After`
- [ ] Request com e-mail diferente → não bloqueado

### Formato de resposta
- [ ] Body do 429 é `ProblemDetail` com `status: 429` e `detail` explicativo

## Subtasks
- [ ] Criar classe `RateLimitingIT`
- [ ] Configurar helper para simular múltiplos requests com mesmo IP (usar MockMvc request builder com header X-Forwarded-For)
- [ ] Garantir que os limites de teste não conflitam com os limites de produção (usar perfil de teste com limites menores ou reset entre testes)
- [ ] Integrar na suite de CI

## Esforço Estimado
Médio (5-8h)

## Observação Técnica
O rate limiter provavelmente usa Caffeine como backend (descrito na TASK-006). Em testes, verificar se há mecanismo para resetar o bucket entre testes (`@BeforeEach` ou perfil de teste com limites menores, ex: max 3 tentativas em vez de 10).

## Status
Pendente — implementar durante SPRINT-03 ou SPRINT-04
