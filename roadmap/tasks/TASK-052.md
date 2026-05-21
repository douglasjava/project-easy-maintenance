# TASK-052 — BUG: E-mail de convite de admin não entra na fila de retry

## Tipo

BUGFIX — Backend

## Categoria

Notificações / E-mail / Confiabilidade

## Prioridade

🟠 Alto

## Épico

EPIC-002 — Confiabilidade Operacional

## Severidade

ALTA — E-mail de acesso inicial do usuário é perdido silenciosamente em caso de falha transiente

---

## Descrição

O método `AdminService.initializeUserAccess` envia o e-mail de convite com credenciais de primeiro acesso ao usuário recém-criado chamando `mailService.sendEmail()` diretamente, envolto em um try-catch que apenas loga o erro.

Como resultado, qualquer falha no envio (limite de destinatários do plano trial, timeout de rede, quota da API MailerSend) é descartada silenciosamente — nenhum registro persiste na tabela `business_email_dispatches` e o `EmailRetryJob` nunca consegue reprocessar o envio.

## Log de evidência

```
2026-05-06 11:16:17.423 ERROR requestId=dd793b33 orgId=N/A
c.b.e.a.a.service.AdminService - Erro ao enviar e-mail de convite para
deborahlrm92@gmail.com: E-mail não pôde ser entregue após todas as
tentativas: MailerSend email send failed: HTTP 422 UNPROCESSABLE_ENTITY -
error {"message":"You have reached trial account unique recipients limit.
#MS42225","errors":{"to":["You have reached trial account unique
recipients limit. #MS42225"]}}
```

## Fluxos impactados

| Fluxo | Método | Status antes | Status depois |
|-------|--------|-------------|--------------|
| Admin cria usuário | `AdminService.createUser` | ❌ Falha silenciosa | ✅ Persistido + retry |
| Admin cria usuário com org | `AdminService.createUserWithOrganization` | ❌ Falha silenciosa | ✅ Persistido + retry |

## Causa raiz

`initializeUserAccess` usa `mailService.sendEmail()` diretamente sem passar pelo `CriticalEmailDispatchService`. A infraestrutura de retry (`EmailRetryJob`) só reprocessa registros da tabela `business_email_dispatches` — que nunca foi alimentada por este fluxo.

## Solução implementada

1. **`NotificationEventType`** — adicionado enum `ADMIN_INVITATION`
2. **`AdminService`**:
   - Removida injeção de `MailService`
   - Injetado `CriticalEmailDispatchService`
   - `initializeUserAccess` agora aceita `orgCode` como parâmetro para enriquecer o registro de dispatch
   - Chamada substituída por `criticalEmailDispatchService.send(..., ADMIN_INVITATION, ..., retryable=true)`
   - O HTML pré-renderizado é armazenado em `business_email_dispatches.html_content` — permite reenvio exato pelo job

## Impacto do retry job

- O `EmailRetryJob` já processa registros com `htmlContent` não nulo re-enviando o HTML armazenado
- `resolveRecipientName` já lida com `organizationCode == null` (retorna o `recipientEmail` como fallback) — sem necessidade de alteração
- Janela de retry: 24 h, até 2 tentativas, intervalo mínimo de 15 min

## Arquivos alterados

- `infrastructure/notification/enums/NotificationEventType.java` — novo valor `ADMIN_INVITATION`
- `admin/application/service/AdminService.java` — refatoração do fluxo de e-mail

## Critérios de Aceite

- [x] Falha no envio do e-mail de convite NÃO é descartada silenciosamente
- [x] Um registro `BusinessEmailDispatch` com `status=FAILED` e `retryable=true` é criado quando o envio falha
- [x] O `EmailRetryJob` reprocessa o registro dentro da janela de 24 h
- [x] O HTML pré-renderizado (com credenciais) é armazenado para reenvio exato
- [x] Fluxo de sucesso: status persiste como `SENT` com `sent_at` preenchido
- [x] Nenhuma exception é propagada ao criador do usuário — fluxo de cadastro não é interrompido por falha no e-mail

## Status

✅ Implementado — 06/05/2026
