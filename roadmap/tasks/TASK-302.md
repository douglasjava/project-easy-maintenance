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

## Status
Backlog
