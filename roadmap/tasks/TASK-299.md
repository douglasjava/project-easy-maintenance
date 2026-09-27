# TASK-299 — Módulo `assistant`: fila, worker, controle de fluxo, liga/desliga e piloto

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 1**

## Depende de
—

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-299-<descricao-curta>`.

**Escopo**
- Migration `assistant_inbound_messages` (wamid único) e `assistant_conversations`.
- `WhatsAppWebhookService.processChange`: com o assistente ligado, cada mensagem de entrada vai
  para a fila (hoje só loga). Statuses continuam como estão.
- Worker com `ThreadPoolTaskExecutor` dedicado e limitado; consumo via `SELECT … FOR UPDATE SKIP
  LOCKED`; processamento em ordem por usuário; retomada após reinício.
- Controle de fluxo: agrupamento de rajadas, um pedido por vez, limites (Bucket4j), limites de
  conteúdo, ignorar grupos, ecos e tipos não suportados, e instrução para desconhecido 1 vez/dia.
- `assistant.enabled` (padrão falso) + lista de liberação por usuário e organização.
- Endpoint de simulação em `dev/` (perfis local/staging) que injeta payloads da Meta.
- Handler provisório de eco ("recebido") só para o piloto validar o encanamento.

**Critérios de aceite**
- [ ] Mesma mensagem reenviada pela Meta é processada uma única vez.
- [ ] Três mensagens em 2 s do mesmo usuário viram um único processamento.
- [ ] Estouro de limite: uma resposta de aviso e as demais ignoradas.
- [ ] Assistente desligado: comportamento idêntico ao atual (só log).
- [ ] Usuário fora da lista de piloto: ignorado.
- [ ] Reinício da API no meio do processamento não perde a mensagem.

**Prompt para o Claude Code**: `execute a TASK-299 (EPIC-031): módulo assistant com fila em
tabela, worker dedicado, controle de fluxo e liga/desliga por usuário. Leia o EPIC-031 §Arquitetura
e §Controle de fluxo antes de começar.`

## Execução (27/09/2026)
Branch `feature/TASK-299-assistente-fundacao` (api) — fila `assistant_inbound_messages` (V118), ingestor com proteção contra reentrega, poller com ShedLock + agrupamento de 3 s + um pedido por vez por remetente, limite por remetente (Bucket4j), pipeline de etapas (`AssistantStep`), porta de resposta com modo dry-run, endpoint de simulação (`POST /dev/simulate/whatsapp-inbound`, exige login). Eco provisório substituído pela própria ativação como primeiro teste em produção.
Plano: `docs/superpowers/plans/2026-09-26-epic-031-onda-1-assistente-whatsapp.md` · testes: API 1.209 verdes; web 214 verdes (3 falhas pré-existentes em `middleware.test.ts`) · validação local ponta a ponta com a conta demo. Revisão final independente feita (6 pontos importantes corrigidos com teste). PR para `staging`: [api#123](https://github.com/douglasjava/easy-maintenance-api/pull/123).

## Status
🟡 Em validação — PR aberta
