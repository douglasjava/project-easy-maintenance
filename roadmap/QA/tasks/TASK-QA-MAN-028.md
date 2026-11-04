# TASK-QA-MAN-028 — QA Manual: Controle Administrativo de Acesso + Gate de Plano Ativo (EPIC-041, local/staging)

## Tipo
QA Manual — **execução manual** pelo Douglas, contra ambiente local (branches
`feature/EPIC-041-admin-access-control`, api PR #178 e web PR #127 ainda não mergeadas) ou
`staging` depois do merge

## Categoria
Backend + Frontend / Billing / Segurança (login)

## Prioridade
🔴 Crítico — toca `UsersService.authenticate()`, usado por todo login do sistema. Precisa ser
homologado antes de promover as branches para `staging`/`main`.

## Tasks cobertas

| Task | O que entrega | Status |
|---|---|---|
| [TASK-396](../../tasks/TASK-396.md) | Endpoint admin de prorrogar/cortar acesso + rota consertada, com auditoria | Implementado |
| [TASK-397](../../tasks/TASK-397.md) | Bloqueio de login por `AccessMode` — dono e "filhos" | Implementado |
| [TASK-398](../../tasks/TASK-398.md) | Botões "Prorrogar trial"/"Cortar acesso" na UI | Implementado |
| [TASK-399](../../tasks/TASK-399.md) | Gate de plano ativo no assistente de IA e 5 notificações | Implementado |

Roteiro completo de cenários: [MTD-010](../MTD/MTD-010.md), fluxo [FLOW-013](../Flow/FLOW-013.md).

---

## Descrição
Executar o roteiro do MTD-010 contra o ambiente local (ou `staging`, se já mergeado) e registrar o
resultado de cada cenário. Este é o QA manual exigido pelo critério de conclusão do EPIC-041 antes
de mergear as branches `feature/EPIC-041-admin-access-control` (api/web) em `staging`.

## Passos
Seguir [MTD-010](../MTD/MTD-010.md) na ordem: Cenário 1 (prorrogar trial) → 2 (cortar leitura) → 3
(cortar bloqueio total) → 4 (motivo obrigatório) → 5 (404 sem assinatura) → 6 (cascata dono/
organização/"filhos") → 7 (organização saudável, sem regressão) → 8 (2FA bloqueado).

## Resultado Esperado
Todos os cenários do MTD-010 aprovados, com evidência (prints/queries) anexada em
`roadmap/QA/MTD/evidencias/MTD-010/`. Nenhuma regressão de login para usuários/organizações fora do
escopo deste teste.

## Critérios de Aceite
- [ ] Cenário 1 — prorrogar trial reflete em `/me/access-context` imediatamente
- [ ] Cenário 2 — cortar "somente leitura": login ok, escrita bloqueada
- [ ] Cenário 3 — cortar "bloqueio total": login negado na próxima tentativa, mensagem distinta de
      senha incorreta
- [ ] Cenário 4 — motivo vazio bloqueado no front e rejeitado no back
- [ ] Cenário 5 — endpoints admin em usuário sem assinatura retornam 404
- [ ] Cenário 6 — cascata dono→organização confirmada; "filho" sem outra organização não loga;
      "filho" com organização saudável continua logando; assistente nega conversa; 5 notificações
      não disparam
- [ ] Cenário 7 — organização saudável sem nenhuma regressão de login/assistente/notificação
      operacional; notificação de billing continua incondicional
- [ ] Cenário 8 — 2FA nega login mesmo com código correto, quando acesso está bloqueado

## Status
Backlog — aguardando execução antes do merge de staging
