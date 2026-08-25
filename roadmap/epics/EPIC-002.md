# EPIC-002 — Confiabilidade Operacional

## Status
Parcial — 3/4 tasks da Fase 1/2 entregues (TASK-025 — fila/retry e-mails — pendente); Fase 3
implementada em 25/08/2026 (5/5 tasks, `feature/EPIC-002-fase3-asaas-sync` nos dois repos, PR ainda
não aberta — achadas ao investigar falha silenciosa de criação de cliente Asaas no onboarding, caso
real do primeiro cliente pagante)

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
| [TASK-201](../tasks/TASK-201.md) | Ressincronização manual de cliente Asaas por usuário | 🟠 Alto | 3 |
| [TASK-202](../tasks/TASK-202.md) | Frontend: validação de dígito verificador de CPF/CNPJ no onboarding | 🟠 Alto | 3 |
| [TASK-203](../tasks/TASK-203.md) | Backend: validação de dígito verificador de CPF/CNPJ (defesa em profundidade) | 🟡 Médio | 3 |
| [TASK-204](../tasks/TASK-204.md) | Alerta (Sentry) quando falha a criação do cliente Asaas | 🟠 Alto | 3 |
| [TASK-205](../tasks/TASK-205.md) | Indicador visual de sincronização pendente com Asaas | 🟡 Médio | 3 |

## Critério de Conclusão do Épico
- [ ] Jobs não executam simultaneamente em múltiplas instâncias
- [ ] Falha no Asaas não propaga erro para requests de usuário não relacionados
- [ ] E-mails críticos têm retry automático em caso de falha
- [ ] Profile de e-mail correto está ativo em produção
- [ ] Logs de jobs incluem: registros processados, falhas e tempo de execução

### Fase 3 — Falha silenciosa de criação de cliente Asaas (25/08/2026)
Achado real: CPF com dígito verificador inválido no onboarding do primeiro cliente pagante foi
rejeitado pela Asaas e engolido silenciosamente, deixando a conta sem `externalCustomerId` — sem
alerta, sem correção automática eficaz (job diário reenvia o mesmo CPF errado) e sem ferramenta de
correção rápida no admin. Ver `docs/superpowers/` (conversa de 25/08/2026) para a investigação
completa.
- [ ] Admin consegue corrigir CPF/CNPJ e ressincronizar com a Asaas sem esperar o job noturno (TASK-201)
- [ ] CPF/CNPJ com dígito verificador inválido é bloqueado no onboarding, front e back (TASK-202, TASK-203)
- [ ] Falha de criação de cliente Asaas é capturada no Sentry, em tempo real e no job diário (TASK-204)
- [ ] Admin identifica contas com sincronização pendente sem precisar consultar log/banco (TASK-205)
