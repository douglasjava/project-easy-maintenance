# TASK-238 — BACKEND: Endpoints autenticados de chamados + notificação por e-mail + flag WhatsApp

## Tipo
BACKEND

## Categoria
Chamados de Moradores

## Prioridade
🟠 Alto

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — confirmar que só usuários autenticados da organização correta veem/movem os chamados
(isolamento multi-tenant), e que o e-mail chega pros ADMINs ao abrir um chamado.

---

## Contexto

Segunda metade do backend do épico: a superfície **autenticada** (`X-Org-Id`) que o painel interno
usa pro kanban, mais a notificação disparada quando um morador abre um chamado (TASK-237). Detalhe
completo em `docs/superpowers/specs/2026-09-08-resident-tickets-design.md`.

## Escopo

- `GET /resident-tickets` (JWT + `X-Org-Id`) — lista os chamados da organização corrente, pro
  kanban. Mesma regra de isolamento multi-tenant do resto do sistema.
- `PATCH /resident-tickets/{id}/status` (JWT + `X-Org-Id`) — muda status
  (`SOLICITADO`/`EM_ANDAMENTO`/`CONCLUIDO`), disparado pelo drag-and-drop do frontend (TASK-240).
  Rejeita se o chamado não pertencer à organização do token.
- Notificação por e-mail: ao criar um chamado (`POST /public/resident-tickets`, TASK-237), dispara
  e-mail pros usuários ADMIN da organização, reaproveitando o provedor já usado (Resend).
  Best-effort — falha no envio não impede a criação do chamado.
- Flag nova `notification.whatsapp.resident-ticket-enabled` (default `false`) — só a flag e o ponto
  de extensão preparado, sem implementar o envio de fato (mesmo padrão do EPIC-023: pronta pra
  ligar depois).
- Controller separado (`ResidentTicketsController`, autenticado) do controller público da TASK-237.

## Critérios de Aceite

- [x] `GET /resident-tickets` só retorna chamados da organização do token (`X-Org-Id`)
- [x] `PATCH /resident-tickets/{id}/status` rejeita chamado de outra organização (404)
- [x] E-mail disparado pros ADMINs da organização ao criar um chamado (best-effort, não bloqueia
      criação se falhar — try/catch isolado, testado forçando falha do `MailService`)
- [x] Flag `notification.whatsapp.resident-ticket-enabled=false` existe e não dispara nada por
      padrão
- [x] Testes cobrindo isolamento multi-tenant + fluxo de notificação (mock do provedor de e-mail)
- [x] `mvn test` sem regressão (935/935)

## Dependências
Precisa da entidade/módulo criado na TASK-237 (mesma tabela, mesmo módulo). Independente da
TASK-237 no sentido de implementação (podem andar em paralelo se a entidade já estiver definida
cedo). TASK-240 (frontend kanban) depende desta task pronta.

## Riscos
Baixo — endpoints seguem o mesmo padrão de autenticação/isolamento já usado em todo o resto do
sistema, nada novo em termos de risco de segurança.

## Esforço
Médio

## Status
✅ Implementada na branch `feature/EPIC-027-resident-tickets` (`easy-maintenance-api`), mesma branch
da TASK-237. `mvn test` → 935/935, 0 regressão. QA manual completo e aprovado por Douglas
([TASK-QA-MAN-018](../QA/tasks/TASK-QA-MAN-018.md)). PR contra `staging` aberta:
[api#85](https://github.com/douglasjava/easy-maintenance-api/pull/85).
