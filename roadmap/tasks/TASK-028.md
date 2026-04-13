# TASK-028 — Processamento assíncrono de chamadas IA

## Tipo
Performance / UX / Arquitetura

## Categoria
Backend / Frontend / IA / Performance

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-007 — Performance e Escalabilidade

## Descrição
Chamadas para OpenAI e DeepSeek acontecem de forma síncrona dentro de endpoints HTTP. O modelo GPT-4o-mini pode demorar 5-30 segundos dependendo do tamanho do prompt e carga do serviço. Isso bloqueia threads do servidor e pode causar timeout no browser.

Solução: retornar imediatamente com um job ID, processar em background e disponibilizar resultado via polling ou WebSocket.

## Critérios de Aceite
- [ ] Endpoints de IA retornam 202 Accepted com `jobId` imediatamente
- [ ] Job é processado em thread pool separado (`@Async`)
- [ ] Frontend faz polling em `GET /ai/jobs/{jobId}` para verificar status (PENDING, PROCESSING, DONE, FAILED)
- [ ] Resultado disponível por 24h após conclusão
- [ ] Timeout de processamento configurável (padrão: 60s)

## Esforço
Grande (2-3 dias)

## Risco de não fazer
Timeout em chamadas de IA com prompts grandes. Threads do servidor bloqueadas durante pico de uso simultâneo.

## Status
Backlog
