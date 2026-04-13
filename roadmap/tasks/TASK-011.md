# TASK-011 — Restringir endpoints do Actuator em produção

## Tipo
Segurança / Configuração

## Categoria
Backend / Segurança / Infra

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-001 — Segurança Crítica

## Descrição
O Spring Boot Actuator está configurado com `management.endpoint.health.show-details=always` e expondo endpoints como `/actuator/prometheus`, `/actuator/health`, `/actuator/metrics`. Se esses endpoints estiverem acessíveis publicamente sem autenticação, expõem informações sobre o estado interno da aplicação, conexões de banco, versão, configurações e mais.

## Problema
Endpoints do Actuator expostos publicamente revelam:
- Informações de saúde da aplicação (pools de conexão, status de dependências)
- Métricas detalhadas (pode revelar padrões de uso)
- Em configurações mais abertas, beans, env, mappings

## Impacto
- Informações de diagnóstico úteis para um atacante
- Exposição de detalhes de infraestrutura

## Dependências
- Nenhuma

## Critérios de Aceite
- [ ] `/actuator/health` acessível publicamente mas com `show-details=never` (apenas UP/DOWN)
- [ ] `/actuator/prometheus` acessível apenas por IP interno ou via autenticação (para Prometheus scraper)
- [ ] Demais endpoints do Actuator desabilitados ou restritos por role em produção
- [ ] `management.endpoints.web.exposure.include` configurado explicitamente (não `*`)

## Subtasks
- [ ] Atualizar `application-prod.properties`:
  ```properties
  management.endpoint.health.show-details=never
  management.endpoints.web.exposure.include=health,prometheus
  ```
- [ ] Configurar Spring Security para restringir `/actuator/prometheus` a role ACTUATOR ou IP interno
- [ ] Verificar que Prometheus scraper ainda consegue acessar `/actuator/prometheus`

## Esforço
Pequeno (1-2h)

## Risco de não fazer
Informações internas da aplicação expostas publicamente.

## Status
Concluído
