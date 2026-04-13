# Runbooks — Easy Maintenance

Procedimentos operacionais para resposta a incidentes em produção.

**Objetivo:** qualquer membro da equipe deve conseguir diagnosticar e resolver os incidentes listados seguindo estes runbooks, independentemente de quem criou o sistema.

---

## Índice

| Runbook | Cenário | Severidade |
|---------|---------|-----------|
| [RB-001](RB-001-job-billing-falhou.md) | Job de billing falhou (BillingCycleJob, SubscriptionBlockingJob, etc.) | Alta |
| [RB-002](RB-002-asaas-fora-do-ar.md) | Asaas fora do ar / circuit breaker aberto | Alta |
| [RB-003](RB-003-banco-de-dados-lento.md) | Banco de dados lento / pool esgotado / lock preso | Alta |
| [RB-004](RB-004-openai-quota-esgotada.md) | OpenAI / DeepSeek quota esgotada ou indisponível | Média |
| [RB-005](RB-005-railway-restart-loop.md) | Railway em restart loop (app indisponível) | Crítica |
| [RB-006](RB-006-cobranca-duplicada.md) | Cobrança duplicada — identificação e estorno | Alta |

---

## Links de Referência Rápida

| Recurso | URL |
|---------|-----|
| Status Asaas | https://status.asaas.com |
| Status Railway | https://status.railway.app |
| Status OpenAI | https://status.openai.com |
| Actuator Health (prod) | `https://api.easy-maintenance.com/actuator/health` |
| Painel Sentry | Configurado via `SENTRY_DSN_BACKEND` |

---

## Estrutura de Cada Runbook

Cada runbook segue o formato:
1. **Sintomas** — como detectar o incidente
2. **Causa provável** — as causas mais comuns em ordem de frequência
3. **Passos de diagnóstico** — comandos e queries para confirmar a causa
4. **Passos de resolução** — por caso, com comandos exatos
5. **Como comunicar o cliente** — templates prontos para usar

---

## Atualizações

Atualizar este runbook quando:
- Uma nova causa de incidente for descoberta em produção
- Um procedimento mudar (ex: novo endpoint, nova variável de ambiente)
- Um incidente ocorrer e a resolução for diferente do documentado

Cada runbook deve refletir o estado atual do sistema.
