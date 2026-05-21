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
- JUnit 5 + MockMvc
- `@WebMvcTest(AuthController.class)` — sem Docker, sem DB
- `@Import` para beans de rate limiting (AOP, Caffeine)
- `@MockitoBean` para serviços de auth

## Cobertura Esperada

### Endpoint /auth/login (por IP)
- [x] 2 requests de login com senha errada → não 429 (401 por credencial inválida)
- [x] 3ª request do mesmo IP → HTTP 429 *(capacidade reduzida para 2 no perfil de teste)*
- [x] Resposta 429 contém header `Retry-After` com valor numérico > 0
- [x] Resposta 429 tem `Content-Type: application/problem+json` com `status: 429`
- [ ] Request do mesmo IP após o período de `Retry-After` → volta a funcionar *(não testado — refill period = 1h no perfil de teste)*
- [x] Request de IP diferente após o bloqueio → não bloqueado (isolamento por IP)

### Endpoint /auth/forgot-password (por IP)
- [x] 2 requests para qualquer e-mail → 200 em todos
- [x] 3ª request do mesmo IP → HTTP 429
- [x] Resposta 429 contém `Retry-After`
- [x] Resposta 429 tem `Content-Type: application/problem+json` com `status: 429`
- [x] Request de IP diferente → não bloqueado

> **Nota**: O limite real é por IP, não por e-mail. A task originalmente descrevia isolamento por e-mail, mas a implementação (`@RateLimit key=IP`) usa IP.

### Formato de resposta
- [x] Body do 429 é `ProblemDetail` com `status: 429`

## Subtasks
- [x] Criar classe `RateLimitingIT`
- [x] Configurar helper para simular múltiplos requests com mesmo IP (header `X-Forwarded-For`)
- [x] Garantir que os limites de teste não conflitam com os limites de produção (`application-integration-test.properties` com `capacity=2`)
- [ ] Integrar na suite de CI

## Arquivos Criados / Modificados

| Arquivo                                                      | Operação                                                                                           |
|--------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| `src/test/resources/application-integration-test.properties` | Adicionadas overrides: `capacity=2`, `refill-period-seconds=3600` para `login` e `forgot-password` |
| `src/test/java/.../security/RateLimitingIT.java`             | Refatorado para `@WebMvcTest` — sem TestContainers/Docker; asserções explícitas (401/200/429)      |

## Esforço Estimado
Médio (5-8h)

## Observação Técnica
O rate limiter usa Caffeine como backend (TASK-006). Buckets são isolados por IP (`key=IP`). Cada test method usa um IP único (`X-Forwarded-For`) para evitar contaminação cruzada.

**Arquitetura do teste**:
- `@WebMvcTest(AuthController.class)` carrega só a camada web (sem JPA, sem Flyway, sem Docker)
- `@Import({JwtService, RateLimitAspect, RateLimiterService})` disponibiliza o AOP de rate limiting
- `@EnableConfigurationProperties(RateLimitProperties.class)` vincula as properties do perfil de teste
- `@MockitoBean UsersService + PasswordResetService` elimina dependências de banco
- Auth endpoints são públicos na `SecurityConfig` e ignorados pelo `TenantFilter` (bypass por prefixo)
- Execução estimada: ~2s vs ~30s com TestContainers

## Status
Concluida — refatoração completa; sem Docker; asserções explícitas
