# TASK-371 — FULL_STACK: Opt-in de WhatsApp do morador com confirmação por código

## Tipo
FULL_STACK

## Categoria
Chamados de Moradores

## Prioridade
🟠 Alto

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — marcar opt-in, confirmar recebimento do código real por WhatsApp, confirmar código válido
ativa o opt-in, confirmar código expirado/errado é rejeitado, confirmar chamado abre normalmente
mesmo sem confirmar o opt-in.

---

## Contexto

Decisão de Douglas (28/10/2026, segunda rodada do brainstorm): o telefone informado na abertura do
chamado não é verificado hoje — qualquer um poderia marcar o opt-in com o telefone de terceiros.
Por isso o opt-in não fica ativo só por marcar o checkbox: exige confirmação por código enviado via
WhatsApp ao telefone informado. Detalhe completo em
`docs/superpowers/specs/2026-10-28-resident-tickets-category-protocol-notification-design.md`.

## Escopo

**Backend:**
- Substituir o campo `whatsapp_opt_in` (boolean) originalmente planejado por:
  - `whatsapp_opt_in_status`: enum `NAO_SOLICITADO` (default) / `PENDENTE_CONFIRMACAO` /
    `CONFIRMADO`.
  - `whatsapp_confirmation_code`: código numérico curto (ex. 6 dígitos).
  - `whatsapp_confirmation_expires_at`: expiração curta (ex. 10 min — ajustar na implementação).
- Ao marcar o checkbox na abertura (ou depois, via ação própria): gera código, salva com expiração,
  envia via WhatsApp (`WhatsAppNotificationProvider`) usando o template de confirmação de código
  submetido/aprovado em **TASK-372**.
- `POST /public/resident-tickets/{id}/whatsapp-opt-in/confirm` — valida código + expiração, marca
  `CONFIRMADO`. Código errado ou expirado retorna erro claro (não genérico).
- Endpoint de reenvio de código (gera novo código, invalida o anterior), com rate limit próprio
  (`RateLimiterService`) — evita abuso de envio.
- Chamado abre e funciona normalmente mesmo sem confirmar o opt-in — confirmação nunca bloqueia a
  abertura do chamado.

**Frontend:**
- Checkbox no formulário público de abertura ("Quero receber atualizações deste chamado pelo
  WhatsApp").
- Se marcado: novo passo/tela pedindo o código recebido, com opção de reenviar.
- Feedback claro de código inválido/expirado, sem travar o fluxo principal (morador pode pular a
  confirmação e seguir vendo o chamado já aberto).

## Critérios de Aceite

- [ ] Marcar o checkbox dispara envio de código real via WhatsApp ao telefone informado
- [ ] Código correto dentro da validade confirma o opt-in (`CONFIRMADO`)
- [ ] Código errado é rejeitado com mensagem clara
- [ ] Código expirado é rejeitado e oferece reenvio
- [ ] Reenvio de código é limitado por rate limit (não permite spam de códigos)
- [ ] Chamado é criado e fica acessível mesmo que o morador nunca confirme o código
- [ ] `mvn test`/`npm run build` sem regressão

## Dependências
TASK-367 (precisa do contrato de API já com categoria/protocolo). TASK-372 (template de confirmação
de código aprovado pela Meta) bloqueia o envio real em produção, mas não bloqueia escrever/testar o
código contra mock. Desbloqueia TASK-368 (notificação só é enviada pra opt-in `CONFIRMADO`).

## Riscos
Envio real do código depende do template da TASK-372 estar aprovado pela Meta — sem isso, só
funciona em mock/sandbox até a aprovação sair.

## Esforço
Médio

## Status
📋 Backlog
