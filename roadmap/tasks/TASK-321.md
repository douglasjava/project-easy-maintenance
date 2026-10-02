# TASK-321 — BUGFIX: assinatura CARD encerrava sozinha na Asaas sem aviso

## Tipo
BUGFIX / FULL_STACK (Backend crítico + Frontend de autoatendimento)

## Prioridade
🔴 Crítico — corta recorrência de cobrança sem aviso pro cliente nem pro time.

## QA obrigatório
Sim — mexe no fluxo de criação/transição de assinatura de pagamento.

## Contexto
Investigado em 02/10/2026 a partir de um caso real em PRD. Os detalhes técnicos (causa raiz, payload exato, conta
afetada) ficam na issue privada [api#145](https://github.com/douglasjava/easy-maintenance-api/issues/145) e na PR da
correção — não reproduzidos aqui por serem específicos de implementação/dados de conta real.

Resumo público: um bug no payload enviado à Asaas na criação/atualização de assinaturas recorrentes por cartão fazia a
assinatura se encerrar sozinha logo após cobrar o primeiro ciclo, sem gerar nenhum erro, webhook ou alerta — o cliente
simplesmente parava de ser cobrado nos meses seguintes.

## Escopo (aprovado por Douglas em 02/10/2026)
1. Corrigir o payload de criação de assinatura recorrente CARD (3 pontos de código com o mesmo bug).
2. Rede de segurança na reconciliação automática, para detectar esse estado mesmo que aconteça de novo por outro motivo.
3. Botão de autoatendimento no painel de billing para o cliente reabrir o checkout quando a cobrança parar de ser gerada.

## Fora de escopo (nesta task)
- Remediar a assinatura específica já afetada em PRD — feita manualmente depois do deploy, via o próprio botão novo.
- Qualquer mudança no fluxo PIX — não é afetado por esse bug.

## Critérios de aceite
- [x] Payload de criação de assinatura recorrente corrigido, com teste de regressão cobrindo isso nos 3 pontos afetados.
- [x] Reconciliação automática passa a sinalizar/corrigir esse estado de divergência, com teste cobrindo o cenário.
- [x] Autoatendimento (reabrir checkout) funciona para uma assinatura em estado "quebrado".
- [x] Botão no painel de billing (frontend) com estados de loading/erro/sucesso.
- [ ] Regressivo E2E de billing sem regressão (não executado nesta rodada).

## Execução (02/10/2026)
PR [api#146](https://github.com/douglasjava/easy-maintenance-api/pull/146) e [web#110](https://github.com/douglasjava/easy-maintenance-web/pull/110)
mergeadas em `staging` e promovidas pra `main` ([api#147](https://github.com/douglasjava/easy-maintenance-api/pull/147),
[web#111](https://github.com/douglasjava/easy-maintenance-web/pull/111)) — detalhes técnicos completos na issue privada.

**Follow-up (mesmo dia):** ao tentar remediar a assinatura afetada em PRD via o botão novo, o endpoint
`update-card` devolveu 502 — causa: `initiateCardUpdate` usava `next_due_date` desatualizado (congelado desde a
ativação) sem checar se já tinha passado, e a Asaas rejeita checkout com vencimento no passado. Corrigido em
[api#148](https://github.com/douglasjava/easy-maintenance-api/pull/148) (mergeada em staging), com o mesmo "clamp pra
hoje" que `CardTransitionService`/`PixRenewalService` já usavam. Promoção pra main aberta:
[api#149](https://github.com/douglasjava/easy-maintenance-api/pull/149).

`mvn test` 72/72 nos serviços afetados.

**Follow-up 2 (mesmo dia):** card update pago e confirmado na Asaas, mas o painel continuou mostrando "Pagamento
pendente" — `PAYMENT_CONFIRMED` (evento de confirmação de cobrança CARD, equivalente ao `PAYMENT_RECEIVED` de
PIX/boleto) nunca teve handler registrado. Corrigido em [api#150](https://github.com/douglasjava/easy-maintenance-api/pull/150)
(novo handler + fix na reconciliação noturna, que corrigia o `Payment` mas não a `Invoice`). `mvn test` 96/96.

**Follow-up 3 (mesmo dia):** investigando o pagamento preso, o payment em si já estava `PAID` (o `PAYMENT_CREATED`
chegou com status já confirmado) — quem ficou presa foi só a invoice, porque esse handler nunca sincronizava a
invoice nesse caminho (diferente de outros handlers que já faziam isso). Esse caso não é coberto pela reconciliação
(só olha payments `PENDING`). Corrigido em [api#152](https://github.com/douglasjava/easy-maintenance-api/pull/152)
(mergeada em staging, promoção pra main aberta: [api#153](https://github.com/douglasjava/easy-maintenance-api/pull/153)).
A invoice específica já afetada precisou de correção manual pontual, já que o evento só chega uma vez e não há
mecanismo automático pra esse estado.

## Status
api#150/151 mergeadas e promovidas. api#152 mergeada em staging; promoção pra main aberta (api#153).
