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
— detalhes técnicos completos na issue/PR privadas. `mvn test` 71/71 nos serviços afetados; typecheck/lint do
frontend OK. Pendente: remediação manual da assinatura já afetada em PRD, depois do deploy.

## Status
Em validação — PRs abertas para `staging`, aguardando review/merge.
