# TASK-006 — Rate limiting em auth, reset e IA

## Tipo
Segurança / Performance

## Categoria
Backend / Segurança

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-001 — Segurança Crítica

## Descrição
Os endpoints de autenticação, reset de senha e IA não possuem rate limiting. Isso os deixa vulneráveis a ataques de força bruta, abuso de custo (IA) e sobrecarga.

Endpoints críticos sem proteção:
- `POST /auth/login` — brute force de senhas
- `POST /auth/password-reset/request` — abuso de envio de e-mail (spam)
- `POST /ai/*` — cada chamada custa créditos OpenAI — abuso pode gerar custo elevado
- `POST /webhooks/asaas` — flood de eventos

## Problema
- Brute force em `/auth/login` pode comprometer contas com senhas fracas
- Abuso de reset de senha pode gerar custo e marcar domínio como spam
- Um usuário malicioso pode esgotar toda a cota de IA do plano ou da conta da empresa

## Impacto
- Segurança de contas comprometida
- Custos inesperados de OpenAI
- DoS de aplicação via flood em endpoints custosos

## Dependências
- Nenhuma infraestrutura adicional requerida (usar Caffeine já configurado como backend do rate limiter)

## Critérios de Aceite
- [ ] `POST /auth/login` limitado a 10 tentativas por IP por minuto (retorna 429)
- [ ] `POST /auth/password-reset/request` limitado a 3 tentativas por e-mail por 15 minutos
- [ ] `POST /ai/*` limitado por usuário (ex: 30 requests/hora no plano FREE, 100/hora no STARTER+)
- [ ] Resposta 429 inclui header `Retry-After` com tempo de espera
- [ ] Limites configuráveis via `application.properties` (não hardcoded)

## Subtasks
- [ ] Adicionar dependência `bucket4j-spring-boot-starter` ao `pom.xml`
- [ ] Configurar `BucketConfiguration` para endpoint de login (por IP)
- [ ] Configurar `BucketConfiguration` para endpoint de reset (por e-mail)
- [ ] Configurar `BucketConfiguration` para endpoints de IA (por userId + plano)
- [ ] Adicionar handler para `RateLimitExceededException` no `@ControllerAdvice`
- [ ] Testar: 11 tentativas de login em sequência deve bloquear na 11ª

## Esforço
Médio (4-8h)

## Risco de não fazer
Brute force de senhas sem obstáculos. Custo de OpenAI pode explodir por abuso de um único usuário.

## Status
Concluído
