# FLOW-007 — Segurança HTTP e Headers

## Criticidade
🟠 HIGH

## Launch Relevance
Auditoria de segurança básica antes de qualquer marketing público. Falhas aqui são visíveis para qualquer scanner de segurança.

## Tasks Relacionadas
- TASK-005 — Desabilitar Swagger/OpenAPI em produção
- TASK-010 — Auditar e rotacionar secrets no repositório
- TASK-011 — Restringir endpoints do Actuator em produção
- TASK-013 — Adicionar security headers HTTP
- TASK-014 — Restrição CORS para domínio de produção

## Descrição do Fluxo

Toda resposta HTTP da API deve incluir os headers de segurança configurados. Endpoints de desenvolvimento (Swagger, Actuator detalhado) devem estar bloqueados em produção. CORS deve rejeitar origens não autorizadas. Secrets não devem estar expostos no repositório.

## Camadas Impactadas
- **Backend:** Spring Security config, `application-prod.properties`, CORS config
- **Frontend:** `next.config.ts` (headers de segurança)
- **Infra:** Variáveis de ambiente Railway, `.gitignore`

## Checklist de Validação

| Item | Esperado | Ferramenta |
|------|----------|-----------|
| `X-Frame-Options: DENY` | Presente | DevTools / curl |
| `X-Content-Type-Options: nosniff` | Presente | DevTools |
| `Strict-Transport-Security` | Presente | DevTools |
| `Content-Security-Policy` | Presente | DevTools |
| `/swagger-ui.html` em produção | 404 | Browser |
| `/v3/api-docs` em produção | 404 | Browser |
| `/actuator/env` em produção | 403/404 | Browser |
| `/actuator/prometheus` | Acessível internamente | Prometheus |
| CORS — origem não autorizada | Sem `Access-Control-Allow-Origin` | curl |
| CORS — origem autorizada | Com `Access-Control-Allow-Origin` correto | curl |
| Rate limiting `/auth/login` (11ª tentativa) | 429 com `Retry-After` | curl / script |
| Rate limiting reset de senha (4ª em 15min) | 429 | curl / script |
| Nota em securityheaders.com | Mínimo B | securityheaders.com |

## Validação Recomendada
- **Manual:** [MTD-006](../MTD/MTD-006.md) — pré-launch obrigatório
- **Automatizada:** [TASK-QA-AUTO-003](../tasks/TASK-QA-AUTO-003.md) — rate limiting em integração

## Gaps
- Sem teste automatizado de presença de headers de segurança
- CORS sem teste automatizado de origem bloqueada

## Status de Validação
- [ ] Security headers validados via securityheaders.com
- [ ] Swagger inacessível em produção
- [ ] Actuator bloqueado em produção
- [ ] Rate limiting validado em staging
- [ ] CORS testado com origem não autorizada
