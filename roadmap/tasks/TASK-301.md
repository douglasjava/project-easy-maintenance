# TASK-301 — Vínculo do número + consentimento + Perfil

## Tipo
FULL_STACK

## Prioridade
🟠 Alto

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 1**

## Depende de
TASK-299, TASK-300

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-301-<descricao-curta>`.

**Escopo**
- Migrations `assistant_links` e `assistant_consents`; termo versionado (texto em PT-BR).
- API: iniciar ativação (gera código de 6 dígitos, 15 min, uso único), status e desativar.
- Worker: mensagem "ATIVAR <código>" vincula o `wa_id` remetente; "PARAR" revoga.
- Perfil (web): card "Assistente no WhatsApp" com aceite do termo, código + botão `wa.me` com
  texto pronto, status (ativo/inativo) e desativar. Estados de carregando, erro e vazio; mobile.

**Critérios de aceite**
- [ ] O número vinculado é o que **enviou** o código, não o digitado no Perfil.
- [ ] Código expirado ou reutilizado é recusado com mensagem clara.
- [ ] `wa_id` já vinculado a outro usuário é recusado.
- [ ] "PARAR" e desativar no Perfil cortam o acesso na mensagem seguinte.
- [ ] Opt-in de alertas (TASK-122) continua independente.

**Prompt**: `execute a TASK-301 (EPIC-031): vínculo do WhatsApp por código ATIVAR e consentimento
versionado, com card no Perfil.`

## Execução (27/09/2026)
API na branch da fundação (V119, código ATIVAR por prova de posse, consentimento versionado `2026-09-v1`, PARAR, `GET/POST/DELETE /me/whatsapp-assistant`) + web em `feature/TASK-301-assistente-perfil` (card no Perfil com termo, código, link `wa.me`, contagem, checagem a cada 5 s e desativação com confirmação).
Plano: `docs/superpowers/plans/2026-09-26-epic-031-onda-1-assistente-whatsapp.md` · testes: API 1.209 verdes; web 214 verdes (3 falhas pré-existentes em `middleware.test.ts`) · validação local ponta a ponta com a conta demo. Revisão final independente feita (6 pontos importantes corrigidos com teste). PR para `staging`: [api#123](https://github.com/douglasjava/easy-maintenance-api/pull/123) + [web#104](https://github.com/douglasjava/easy-maintenance-web/pull/104).

## Status
✅ Concluída — em produção desde 27/09/2026 (api#124 / web#105); validada no piloto com o número do Douglas.
