# TASK-033 — Status page básica

## Tipo
Operação / Produto

## Categoria
Infra / Produto

## Prioridade
🔵 Baixo

## Fase
2 — Pós-lançamento

## Épico
EPIC-005 — Observabilidade e Operação

## Descrição
Clientes pagantes esperam transparência sobre o estado operacional do sistema. Uma status page básica mostra histórico de incidentes e disponibilidade atual, aumentando a confiança e reduzindo tickets de suporte durante instabilidades.

## Critérios de Aceite
- [ ] Status page pública acessível em `status.easymaintenance.com.br` ou similar
- [ ] Mostra estado atual de: API, banco de dados, e-mails, pagamentos
- [ ] Histórico de incidentes dos últimos 90 dias
- [ ] Usuários podem se inscrever para notificações de incidentes

## Solução Sugerida
- Statuspage.io (free tier) ou Instatus (mais barato para BR)
- Integração com Prometheus para atualização automática de status

## Esforço
Pequeno (2-4h de configuração)

## Status
Backlog
