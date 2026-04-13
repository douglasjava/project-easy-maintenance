# EPIC-005 — Observabilidade e Operação

## Status
Parcial — 2/4 tasks entregues (TASK-021 — alertas Grafana e TASK-033 — status page — pendentes)

## Objetivo
Ter visibilidade completa do sistema em produção — saber quando algo está errado antes do cliente reclamar, diagnosticar problemas rapidamente e ter playbooks para resposta a incidentes.

## Descrição
O sistema tem uma base boa de observabilidade (Prometheus, Micrometer, MDC nos logs), mas falta o nível seguinte: alertas configurados para condições críticas, rastreamento de erros não tratados (Sentry), status page para transparência com clientes, e runbooks para a equipe operar o sistema em produção.

## Impacto no Produto
- **Sem este épico:** Problemas em produção são descobertos pelos clientes. Diagnóstico de incidentes leva horas. Equipe não sabe o que fazer quando um job falha ou o Asaas fica fora.
- **Com este épico:** Equipe é notificada antes dos clientes. Diagnóstico em minutos. Respostas a incidentes são procedurais.

## Tasks Relacionadas

| ID | Título | Prioridade | Fase |
|----|--------|-----------|------|
| TASK-021 | Alertas no Prometheus/Grafana | 🟡 Médio | 2 |
| TASK-022 | Sentry em backend e frontend | 🟡 Médio | 2 |
| TASK-029 | Runbook de incidentes e operação | 🟡 Médio | 2 |
| TASK-033 | Status page básica | 🔵 Baixo | 2 |

## Critério de Conclusão do Épico
- [ ] Alertas configurados para: job com falha, taxa de erro > 1%, tempo de resposta P95 > 2s, quota de IA próxima do limite
- [ ] Sentry capturando exceções não tratadas no backend
- [ ] Sentry capturando erros JavaScript no frontend
- [ ] Status page pública mostrando disponibilidade dos serviços
- [ ] Runbook documentado para: falha do Asaas, falha de job de billing, incidente de segurança
