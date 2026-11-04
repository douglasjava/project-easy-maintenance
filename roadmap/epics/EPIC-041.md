# EPIC-041 — Controle Administrativo de Acesso do Usuário (Prorrogar/Cortar) + Gate de Notificações por Plano

## Status
🟡 QA manual executado, 1 bug encontrado e corrigido, aguardando homologação final e merge
(04/11/2026) — spec em `docs/superpowers/specs/2026-11-03-admin-access-control-design.md`.
API PR [#178](https://github.com/douglasjava/easy-maintenance-api/pull/178) (commit `68b7678`),
Web PR [#127](https://github.com/douglasjava/easy-maintenance-web/pull/127) (commit `c99d18e`),
ambas em `feature/EPIC-041-admin-access-control`. `mvn test`: 1697 testes sem regressão (1693 +
4 do TASK-QA-AUTO-010, 2FA); `tsc --noEmit`/`npm run build` do web limpos.

QA manual (TASK-QA-MAN-028/MTD-010) executado 04/11/2026 contra ambiente local real (API+web+MySQL
rodando, usuários sintéticos isolados, nenhum usuário real tocado): 7 dos 8 cenários confirmados ao
vivo via API/banco/UI (login, cascata dono→filhos, órfão corrigido, motivo obrigatório, 404 sem
assinatura, regressão em conta saudável). Cenário de 2FA coberto só pelo automatizado. Encontrado e
corrigido um bug real: botões "Prorrogar trial"/"Cortar acesso" só apareciam com status `ACTIVE`,
escondendo os casos principais (`TRIAL`/cortado) — ver detalhe em [TASK-398](../tasks/TASK-398.md).
Achado secundário não-bloqueante: tabela de assinaturas não atualiza visualmente após filtro/ação
(dado real sempre correto no banco) — pré-existente à entrega, avaliar task própria.

## Objetivo
Dar ao Douglas, como admin do SaaS (não ao `ADMIN` de uma organização cliente), o poder de agir
pontualmente sobre um usuário do piloto em validação: prorrogar o trial dele, ou cortar o acesso
antes do fim — sem mudar a regra geral de 15 dias de trial pra todo mundo. Em paralelo, fechar um
gap real: hoje nada no sistema impede login por status de assinatura, e notificações/assistente de
IA não checam se o plano está realmente ativo antes de interagir — incluindo com usuários "filhos"
(membros de equipe e moradores vinculados à organização de quem paga), que não têm billing próprio
e ficariam órfãos se só o dono fosse cortado.

## Descrição

Hoje a aba "Billing" da tela `/private/users/[id]` tem campos de status/período, mas o PUT que ela
chama foi removido do backend no TASK-206 e nunca foi atualizado no front — salva e falha
silenciosamente. E mesmo que funcionasse, nada usaria esse status pra realmente impedir login: o
único enforcement real hoje é o `SubscriptionAccessAspect`, que bloqueia só escrita.

Esta entrega: (1) conserta esse endpoint e adiciona dois atalhos de admin — "Prorrogar trial" e
"Cortar acesso" (dois níveis: somente leitura ou bloqueio total de login) — reaproveitando
`SubscriptionStatus` como já existe, sem campo novo; (2) fecha o gap do login, incluindo o caso dos
"filhos" sem billing próprio (membros de equipe), que precisam ser cortados quando a organização do
dono é bloqueada, mesmo não tendo item de assinatura individual; (3) endurece o chat do assistente
de IA pra também negar quando o modo não for `FULL_ACCESS` (hoje só nega em `NO_ACCESS`); (4) adiciona
a mesma checagem a 5 serviços de notificação proativa que hoje disparam sem checar nada — exceto os
e-mails do próprio billing (fatura, aviso de bloqueio), que continuam incondicionais de propósito.

**Decisões confirmadas por Douglas (03/11/2026, ver spec para detalhe completo):**
- Só o Douglas opera isso, via `/private/admin` — não é feature de cliente.
- Sem campo/enum novo — reaproveita `SubscriptionStatus`/`AccessMode` existentes, aceitando o risco
  de um webhook/job automático sobrescrever um status manual (ele confere e refaz se acontecer).
- Escopo cobre só dono de conta diretamente (membro de equipe não tem billing próprio pra editar),
  mas cortar o dono cascateia pra organização inteira (mesma `BillingSubscription`) — comportamento
  intencional, não efeito colateral.
- Bloqueio de login vale a partir do próximo login — sem invalidar token/sessão já emitida.
- "Filhos" (membros de equipe sem billing próprio) só perdem o login se **todas** as organizações
  deles estiverem em `NO_ACCESS` — login é por conta, não por organização isolada.
- Notificações de billing (cobrança, aviso de bloqueio) ficam fora do gate — são o canal que avisa
  disso mesmo.

---

## Contexto Técnico

- `SubscriptionStatus`/`AccessMode`/`SubscriptionAccessService.mapToAccessMode()` já existem —
  `ACTIVE`/`TRIAL`/`MEMBER` → `FULL_ACCESS`; `BLOCKED` → `NO_ACCESS`; o resto → `READ_ONLY`.
- `BillingSubscriptionItem` (tipo `USER` ou `ORGANIZATION`) só existe pra dono de conta
  (`OnboardingService.createUser`) — membro de equipe nunca tem item `USER` próprio, cai hoje em
  `READ_ONLY` fixo por `resolveUserAccessMode` (função não diferencia "sem item" de "org saudável
  mas eu não pago").
- `resolveEffectiveStatus()` já deriva `TRIAL_EXPIRED` **na leitura**, não persistido — prorrogar o
  trial é só empurrar `currentPeriodEnd` pra frente, sem precisar tocar em mais nada.
- `AssistantAccessGuard.checkRead` já nega leitura do assistente em `NO_ACCESS`; falta negar também
  em não-`FULL_ACCESS`.
- Rota morta a corrigir: front chama `PUT /private/admin/billing/user/{id}/subscription` (singular),
  backend não tem essa rota desde o TASK-206 (removida, nunca substituída).

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-396](../tasks/TASK-396.md) | Backend: conserta rota de edição de assinatura do usuário + endpoint admin de prorrogar/cortar acesso, com auditoria | BACKEND | 🟠 Alto |
| [TASK-397](../tasks/TASK-397.md) | Backend: bloqueio de login por `AccessMode` — dono e "filhos" sem billing próprio | BACKEND | 🔴 Crítico |
| [TASK-398](../tasks/TASK-398.md) | Frontend: botões "Prorrogar trial" / "Cortar acesso" no admin de billing | FRONTEND | 🟠 Alto |
| [TASK-399](../tasks/TASK-399.md) | Backend: gate de plano ativo no assistente de IA e nas notificações operacionais (exceto billing) | BACKEND | 🟠 Alto |

Ordem: TASK-396 não depende de nada (conserta o que já devia existir). TASK-397 é independente de
código novo do TASK-396 (toca login, não o endpoint admin), mas faz mais sentido testar os dois
juntos já que ambos tocam o mesmo conceito de `AccessMode` por usuário. TASK-398 depende do
TASK-396 (usa o endpoint consertado). TASK-399 é independente das outras três — só precisa do
`SubscriptionAccessService` que já existe — mas deve ser testado em conjunto por tocar organizações
reais usadas pelas outras tasks.

---

## Critério de Conclusão do Épico

- [ ] Douglas consegue, pela UI de admin, prorrogar o trial de um usuário (nova data de
      `currentPeriodEnd`) e ver o efeito refletido imediatamente em `/me/access-context`
- [ ] Douglas consegue cortar o acesso de um usuário em dois níveis (somente leitura / bloqueio
      total de login), com motivo registrado em auditoria
- [ ] Usuário com acesso cortado como "bloqueio total" não consegue logar a partir da próxima
      tentativa (sem precisar invalidar sessão já ativa)
- [ ] Membro de equipe vinculado à organização de um dono bloqueado também não consegue logar,
      exceto se pertencer a outra organização saudável
- [ ] Assistente de IA nega conversa (leitura, não só escrita) para organização que não está em
      `FULL_ACCESS`, cobrindo moradores (`CondoPerson`) automaticamente
- [ ] As 5 notificações operacionais identificadas (identidade, chamado de morador x2, boas-vindas,
      lembrete de vencimento) não disparam para organização/usuário fora de `FULL_ACCESS`
- [ ] Notificações de billing (fatura, bloqueio) continuam disparando incondicionalmente —
      confirmado por teste de regressão explícito
- [ ] `mvn test`/`npm run build`/`tsc --noEmit` sem regressão, com teste de login cobrindo todos os
      valores de `SubscriptionStatus`

## Fora de Escopo
- Mudar a regra geral de 15 dias de trial.
- Dar esse poder a `ADMIN` de organização cliente.
- Qualquer campo/enum novo — tudo reaproveita `SubscriptionStatus`/`AccessMode`.
- Invalidação ativa de token/sessão já emitida.
- Auto-provisionar assinatura pra usuário que ainda não tem nenhuma (endpoint admin faz 404 nesse
  caso, não cria do zero).

## Riscos
Tocar `UsersService.authenticate()` afeta o login de **todo** usuário do sistema, não só os do
piloto — mitigado com teste de regressão por status antes de qualquer merge (ver spec,
`2026-11-03-admin-access-control-design.md`, seção "Riscos"). Endurecer o assistente pra tratar
`READ_ONLY` como bloqueio pode cortar organizações que hoje "funcionam por sorte" nesse estado —
aceitável dado que, nesta fase, só o usuário do próprio Douglas está realmente ativo em produção.
