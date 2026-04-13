# TASK-031 — Notificações in-app (lista no header)

## Tipo
Produto / UX

## Categoria
Frontend / Backend / Produto

## Prioridade
🔵 Baixo

## Fase
2 — Pós-lançamento

## Épico
EPIC-006 — Produto SaaS

## Descrição
Push notifications via Firebase já estão implementadas, mas não há um centro de notificações in-app (lista de notificações no header com contador de não lidas). Usuários que não habilitaram push ou que estão no desktop web não recebem alertas de manutenções vencendo.

## Critérios de Aceite
- [x] Ícone de sino no header com contador de notificações não lidas
- [x] Dropdown com lista das últimas 20 notificações
- [x] Notificações incluem: item em vencimento, manutenção em vencimento, assinatura bloqueada
- [x] Notificação pode ser marcada como lida ao clicar (individual + marcar todas)
- [x] Link de "ver todas" para tela completa de notificações (`/notifications`)

## Esforço
Médio (1-2 dias)

## Status
Concluído
