# TASK-021 — Alertas no Prometheus/Grafana

## Tipo
Operação / Observabilidade

## Categoria
Infra / Observabilidade

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-005 — Observabilidade e Operação

## Descrição
O sistema coleta métricas via Prometheus mas não tem alertas configurados. Ter métricas sem alertas é equivalente a ter câmeras de segurança sem ninguém assistindo — problemas em produção são descobertos pelos clientes, não pela equipe.

## Alertas Prioritários a Configurar

| Alerta | Condição | Severidade |
|--------|----------|-----------|
| High Error Rate | Taxa de erro HTTP 5xx > 1% por 5 min | CRÍTICO |
| High Latency | P95 de latência > 2s por 5 min | ALTO |
| Job Failure | Job agendado sem execução bem-sucedida nas últimas 26h | CRÍTICO |
| AI Quota Warning | Créditos de IA consumidos > 80% do limite mensal | ALTO |
| DB Connections High | Pool de conexões MySQL > 80% de utilização | ALTO |
| Memory High | JVM heap > 85% por 10 min | MÉDIO |
| Email Delivery Failure | Taxa de entrega de e-mail < 95% | MÉDIO |

## Dependências
- Prometheus já configurado e coletando métricas
- Grafana disponível (ou configurar)
- Canal de notificação definido (Slack, PagerDuty, e-mail)

## Critérios de Aceite
- [ ] Pelo menos 5 alertas críticos configurados e testados
- [ ] Canal de notificação definido e testado (ex: Slack + e-mail)
- [ ] Dashboard Grafana com as principais métricas visível
- [ ] Runbook de resposta para cada alerta crítico
- [ ] Teste de alerta: disparar condição manualmente e confirmar notificação

## Subtasks
- [ ] Configurar Grafana (cloud ou self-hosted)
- [ ] Importar ou criar dashboard para métricas de negócio e infra
- [ ] Criar regras de alerta no Prometheus (`alerts.yml`)
- [ ] Configurar AlertManager com canal de notificação
- [ ] Documentar runbook para cada alerta

## Esforço
Médio (1-2 dias)

## Risco de não fazer
Problemas em produção são descobertos pelos clientes. Incidentes de billing (job falhando) podem durar dias sem detecção.

## Status
Backlog
