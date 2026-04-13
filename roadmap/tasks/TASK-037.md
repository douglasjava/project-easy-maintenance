# TASK-037 — Jobs de billing assíncronos com fila

## Tipo
Performance / Escalabilidade / Confiabilidade

## Categoria
Backend / Infra / Billing

## Prioridade
🔵 Baixo

## Fase
3 — Escala

## Épico
EPIC-007 — Performance e Escalabilidade

## Descrição
Os jobs de billing processam todas as assinaturas em loop síncrono. Com 1.000+ clientes, o `DailyTrialJob` pode demorar horas percorrendo todos os trials, fazendo chamadas ao Asaas para cada um. Isso cria um gargalo e pode causar sobrecarga do banco e do Asaas.

Solução: publicar eventos de billing em uma fila (AWS SQS, RabbitMQ ou Redis Streams) e processar com workers paralelos e concorrência controlada.

## Critérios de Aceite
- [ ] Jobs publicam eventos em fila em vez de processar diretamente
- [ ] Workers consomem a fila com concorrência configurável (ex: 5 workers paralelos)
- [ ] Processamento idempotente (reprocessar o mesmo evento não tem efeito colateral)
- [ ] Dead letter queue para eventos que falham repetidamente
- [ ] Dashboard de fila mostrando tamanho, taxa de processamento e DLQ

## Esforço
Grande (1 semana)

## Status
Backlog
