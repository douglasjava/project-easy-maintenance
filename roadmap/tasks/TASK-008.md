# TASK-008 — Circuit breaker para serviços externos

## Tipo
Confiabilidade / Infra

## Categoria
Backend / Integração / Resiliência

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-002 — Confiabilidade Operacional

## Descrição
As integrações externas (Asaas, OpenAI/DeepSeek, AWS S3, MailerSend, Firebase) são chamadas de forma síncrona sem proteção contra falhas em cascata. Se qualquer um desses serviços ficar lento ou fora do ar, as threads do servidor ficam bloqueadas esperando timeout, o que pode derrubar toda a aplicação.

## Problema
- Asaas com latência alta durante pico → onboarding de novos clientes trava
- OpenAI com timeout → requests de IA ficam pendurados bloqueando threads
- S3 indisponível → upload de anexo retorna 500 sem mensagem útil
- MailerSend falhando → job de e-mail fica em loop ou falha silenciosamente

## Impacto
- Uma falha em serviço externo pode derrubar a aplicação inteira (thread pool esgotado)
- Usuários recebem erros 500 sem mensagem útil
- Jobs ficam presos esperando timeout de serviços externos

## Dependências
- Nenhuma infraestrutura adicional — Resilience4j é biblioteca Java pura

## Critérios de Aceite
- [ ] `resilience4j` adicionado ao `pom.xml`
- [ ] `AsaasClient` protegido com `@CircuitBreaker` e `@TimeLimiter` (timeout: 10s)
- [ ] Clientes de IA (OpenAI, DeepSeek) protegidos com `@CircuitBreaker` e `@TimeLimiter` (timeout: 30s)
- [ ] `MailerSendServiceImpl` protegido com `@Retry` (3 tentativas com backoff exponencial)
- [ ] Circuit breaker de Asaas em estado OPEN retorna erro claro (não 500 genérico)
- [ ] Métricas de circuit breaker visíveis no `/actuator/metrics`

## Subtasks
- [ ] Adicionar `resilience4j-spring-boot3` ao `pom.xml`
- [ ] Configurar `application.properties` com thresholds de circuit breaker por serviço
- [ ] Proteger `AsaasClient` com `@CircuitBreaker(name = "asaas", fallbackMethod = "...")`
- [ ] Proteger `OpenAiAiProvider` e `DeepSeekAiProvider` com `@TimeLimiter`
- [ ] Proteger `MailerSendServiceImpl` com `@Retry`
- [ ] Implementar fallback methods com mensagens de erro adequadas
- [ ] Testar simulando timeout do Asaas (ex: apontando para endpoint lento)

## Esforço
Médio (1 dia)

## Risco de não fazer
Falha de qualquer serviço externo pode derrubar toda a aplicação. Isso acontecerá com o Asaas (serviço brasileiro com instabilidades conhecidas).

## Status
Concluído
