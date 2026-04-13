# EPIC-002 — Confiabilidade Operacional

## Status
Parcial — 3/4 tasks entregues (TASK-025 — fila/retry e-mails — pendente)

## Objetivo
Garantir que o sistema opere de forma estável e previsível em produção, sem falhas em cascata, jobs duplicados ou e-mails perdidos.

## Descrição
O sistema possui 5 jobs críticos agendados (billing, trial, cancelamento, notificação) que rodam sem proteção contra execução simultânea. Além disso, integrações externas (Asaas, OpenAI, S3, MailerSend) não têm circuit breaker ou retry — uma falha em qualquer delas pode travar a aplicação inteira. O envio de e-mails críticos também não tem mecanismo de reenvio em caso de falha.

## Impacto no Produto
- **Sem este épico:** Um deploy com 2 instâncias gera cobranças duplicadas. O Asaas fora do ar trava o onboarding de novos clientes. Um e-mail de pagamento falha silenciosamente.
- **Com este épico:** Sistema resiliente a falhas de dependências externas, sem risco de operações duplicadas.

## Tasks Relacionadas

| ID | Título | Prioridade | Fase |
|----|--------|-----------|------|
| TASK-003 | Implementar ShedLock nos jobs agendados | 🔴 Crítico | 1 |
| TASK-008 | Circuit breaker para serviços externos | 🟠 Alto | 1 |
| TASK-012 | Verificar e corrigir profile de e-mail em produção | 🟠 Alto | 1 |
| TASK-025 | Fila/retry para envio de e-mails | 🟡 Médio | 2 |

## Critério de Conclusão do Épico
- [ ] Jobs não executam simultaneamente em múltiplas instâncias
- [ ] Falha no Asaas não propaga erro para requests de usuário não relacionados
- [ ] E-mails críticos têm retry automático em caso de falha
- [ ] Profile de e-mail correto está ativo em produção
- [ ] Logs de jobs incluem: registros processados, falhas e tempo de execução
