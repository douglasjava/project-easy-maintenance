# TASK-302 — Contexto "em nome do usuário" + porta de domínio + escolha de organização

## Tipo
BACKEND

## Prioridade
🔴 Crítico (segurança)

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 1**

## Depende de
TASK-301

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-302-<descricao-curta>`.

**Escopo**
- Executor que monta `SecurityContext` + `TenantContext` do usuário por mensagem e limpa em
  `finally`.
- Porta de domínio (`AssistantDomainGateway`) com as travas: vínculo com a organização,
  `FULL_ACCESS` para gravar, papel (`READER` só leitura), revalidação de usuário, consentimento e
  vínculo.
- Teste de arquitetura: todo handler que grava passa pela trava.
- Escolha de organização: uma → automática; várias → lista; "trocar condomínio" a qualquer momento.

**Critérios de aceite**
- [ ] Usuário não consegue ler nem gravar em organização a que não pertence (teste).
- [ ] Conta em somente leitura: consultas funcionam e gravação é recusada com mensagem clara.
- [ ] `READER` recebe recusa ao tentar registrar.
- [ ] Contexto nunca vaza entre mensagens (teste com duas mensagens de usuários diferentes na
  mesma thread).

**Prompt**: `execute a TASK-302 (EPIC-031): contexto de execução em nome do usuário e porta de
domínio com as mesmas travas do web (tenant, FULL_ACCESS, papel). Trate como revisão de segurança.`

## Execução (27/09/2026)
Mesma branch da fundação — V120 (`assistant_conversations`), `AssistantUserContext.runAs` (limpa contexto em finally), `AssistantAccessGuard` (vínculo, FULL_ACCESS para gravar, READER só lê, assinatura ausente = sem acesso), escolha de organização por lista ou nome digitado (id forjado ignorado) e teste de fronteira do módulo. O teste 'todo handler que grava passa pelo guard' entra com o primeiro handler de gravação (TASK-306).
Plano: `docs/superpowers/plans/2026-09-26-epic-031-onda-1-assistente-whatsapp.md` · testes: API 1.209 verdes; web 214 verdes (3 falhas pré-existentes em `middleware.test.ts`) · validação local ponta a ponta com a conta demo. Revisão final independente feita (6 pontos importantes corrigidos com teste). PR para `staging`: [api#123](https://github.com/douglasjava/easy-maintenance-api/pull/123).

## Status
✅ Concluída — em produção desde 27/09/2026 (api#124 / web#105); validada no piloto com o número do Douglas.
