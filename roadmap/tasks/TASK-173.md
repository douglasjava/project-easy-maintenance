# TASK-173 — Backend: fornecedores no e-mail de notificação (30 dias antes de vencer)

## Tipo
BACKEND

## Categoria
Notificações / Fornecedores

## Prioridade
🟠 Alto

## Épico
[EPIC-023](../epics/EPIC-023.md) — Fornecedores nas Notificações de Vencimento

## QA obrigatório
Sim — QA manual com dado real (mesma classe de bloqueio de secrets locais já registrada em tasks
anteriores do projeto, se aplicável) + testes automatizados do HTML gerado e do roteamento de
canal.

---

## Contexto

Primeira versão (PR [api#79](https://github.com/douglasjava/easy-maintenance-api/pull/79), ainda
não mergeada) colocou o bloco de fornecedores no e-mail de item/manutenção **vencida**
(`OVERDUE`). Revisão de produto em 03/09/2026 (Douglas): fornecedor faz muito mais sentido **antes**
de vencer — dá tempo de contratar. Depois de vencido, sugerir fornecedor não agrega (o problema já
é urgente/em atraso); nesse caso o e-mail já leva pro item/manutenção via CTA, onde a busca
interativa de fornecedor já existe.

Mesmo raciocínio já aplicado na TASK-226 (WhatsApp em todos os checkpoints de `NEAR_DUE`, não só
no mais urgente) — o cliente real (Rogerio Dantas) pediu explicitamente 1 mês de antecedência pra
buscar fornecedor.

**Detalhe importante**: hoje o e-mail só dispara no evento `OVERDUE` — `NotificationChannelResolver`
nunca inclui `EMAIL` para `NEAR_DUE` (só `PUSH` + `WHATSAPP`, ver TASK-226). Então essa mudança não é
só mover a busca de fornecedor de lugar — é fazer o e-mail passar a existir num momento em que ele
hoje nunca dispara. Mexe no `NotificationChannelResolver` de novo.

Design geral em `docs/superpowers/specs/2026-08-18-supplier-notifications-design.md` (documento
original ainda cita `OVERDUE` para e-mail — esta task diverge dele nesse ponto específico, por
decisão de produto de 03/09/2026).

## Decisão (Douglas, 03/09/2026)

- Novo disparo de e-mail **só no checkpoint de 30 dias antes** (`NEAR_DUE`, `daysOffset==30`) —
  não nos 4 checkpoints (30/15/7/1). Motivo: repetir a sugestão de fornecedor a cada checkpoint
  vira ruído pra quem já resolveu, e cada e-mail extra consome a cota mensal por organização
  (`BusinessEmailQuotaService`).
- Bloco de fornecedores **sai do e-mail de `OVERDUE`** — reverte a parte de
  `resolveNearbySuppliers` guardada por `ITEM_OVERDUE`/`MAINTENANCE_OVERDUE` do PR #79. O e-mail de
  vencido continua existindo (mesmo conteúdo de sempre), só sem a seção de fornecedores.
- WhatsApp (TASK-174) já dispara nos 4 checkpoints de `NEAR_DUE` desde a TASK-226, incluindo o de
  30 dias — quando o template novo for aprovado pela Meta, complementa o e-mail sem trabalho extra
  de design aqui.
- Reaproveita a mesma branch/PR #79 (ainda não mergeada) em vez de abrir uma nova.

## Escopo

1. **`NotificationChannelResolver`**: reintroduz um branch dedicado pro caso `NEAR_DUE` —
   `PUSH` + `WHATSAPP` sempre, `EMAIL` só quando `daysOffset == 30`. Ajustar
   `NotificationChannelResolverTest` (novo caso: `NEAR_DUE` com `daysOffset=30` inclui `EMAIL`;
   `daysOffset` 15/7/1 não inclui).
2. **`BusinessEmailNotificationService`**: `resolveNearbySuppliers()` muda a guarda de
   `ITEM_OVERDUE`/`MAINTENANCE_OVERDUE` pra `ITEM_NEAR_DUE`/`MAINTENANCE_NEAR_DUE` com
   `event.getDaysOffset() == 30`. Resto da resolução (organização → cidade/estado, referenceId →
   item_type, `SupplierCategoryKeywords`, `SupplierLookupService`) não muda.
3. **`EmailTemplateHelperTest`**: sem mudança de escopo — o overload com lista de fornecedores já é
   genérico (não sabe se é `OVERDUE` ou `NEAR_DUE`), continua válido como está.
4. Ajustar/remover os testes de `BusinessEmailNotificationServiceTest` que hoje cobrem o cenário
   `OVERDUE` com fornecedor, substituindo por cenários `NEAR_DUE daysOffset=30`.

## Critérios de Aceite

- [ ] `NotificationChannelResolver`: `NEAR_DUE` com `daysOffset=30` inclui `EMAIL` (além de
      `PUSH`+`WHATSAPP`); `daysOffset` 15/7/1 não inclui `EMAIL`
- [ ] E-mail de `NEAR_DUE daysOffset=30` inclui bloco de fornecedores quando `SupplierLookupService`
      retorna 1+ resultados
- [ ] E-mail de `OVERDUE` **não** busca fornecedor (nem chama `SupplierLookupService`)
- [ ] E-mail sem fornecedor encontrado renderiza normalmente, sem a seção
- [ ] Testes cobrindo o roteamento de canal (`NotificationChannelResolverTest`) e o HTML gerado
      (`EmailTemplateHelperTest`, já existente) e a nova guarda de evento
      (`BusinessEmailNotificationServiceTest`)
- [ ] `mvn test` sem regressão

## Dependências
TASK-172 (`SupplierLookupService`), já implementada.

## Riscos
Baixo-Médio — mexe no `NotificationChannelResolver` pela 3ª vez na sessão (TASK-226 já alterou o
mesmo arquivo); risco principal é reintroduzir alguma regressão no roteamento de canal já coberto
por `NotificationChannelResolverTest`. Volume de e-mail aumenta (novo disparo que não existia),
mas escopado a 1x por item/manutenção no ciclo (só o checkpoint de 30 dias), não 4x.

## Esforço
Baixo-Médio

## Status
🔵 Card ajustado em 03/09/2026 após conversa com Douglas — implementação da v1 (PR
[api#79](https://github.com/douglasjava/easy-maintenance-api/pull/79)) ainda não mergeada, será
retrabalhada nesta mesma branch pra refletir o novo desenho (fornecedor no `NEAR_DUE` de 30 dias,
não no `OVERDUE`). Aguardando confirmação pra implementar.
