# TASK-025 — Fila/retry para envio de e-mails

## Tipo
Confiabilidade / Produto

## Categoria
Backend / E-mail / Infra

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-002 — Confiabilidade Operacional

## Descrição
O envio de e-mails via MailerSend acontece de forma síncrona (ou assíncrona simples com `@Async`). Se o MailerSend falhar, o e-mail é perdido silenciosamente. E-mails críticos como aviso de trial expirando, confirmação de pagamento e reset de senha precisam de garantia de entrega.

## Problema
- MailerSend fora do ar por 5 minutos durante o `DailyTrialJob` → todos os e-mails de aviso perdidos
- Falha no envio de reset de senha → usuário não consegue recuperar acesso
- Sem retry, a única solução é reprocessar manualmente

## Impacto
Clientes não recebem comunicações críticas. Suporte aumenta. Conversão de trial cai.

## Dependências
- TASK-012 (profile de e-mail) deve estar concluída
- TASK-008 (circuit breaker) cobre a parte de proteção; esta task cobre o retry

## Critérios de Aceite
- [ ] E-mails críticos têm pelo menos 3 tentativas com backoff exponencial
- [ ] Falha definitiva (após todas as tentativas) é logada com contexto suficiente para reprocessamento manual
- [ ] Tabela `email_send_queue` (ou `business_email_dispatches` existente) rastreia status de envio
- [ ] Dashboard admin mostra e-mails com falha (fase 3 — opcional)

## Subtasks
- [ ] Avaliar estratégia: Spring Retry (`@Retryable`) vs tabela de fila no banco
- [ ] Implementar `@Retryable` no `MailerSendServiceImpl` com backoff exponencial (3 tentativas, 1s/2s/4s)
- [ ] Verificar se `business_email_dispatches` já rastreia status — se sim, atualizar para incluir falhas
- [ ] Adicionar log estruturado de falha de e-mail com contexto (tipo, destinatário, tentativa)
- [ ] Testar: simular falha do MailerSend e verificar retry e log

## Esforço
Médio (4-8h)

## Risco de não fazer
E-mails críticos perdidos silenciosamente durante instabilidades do MailerSend.

## Status
Backlog
