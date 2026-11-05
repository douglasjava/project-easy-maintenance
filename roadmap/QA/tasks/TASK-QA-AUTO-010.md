# TASK-QA-AUTO-010 — Teste de integração: `verifyTwoFactor()` nega login com `AccessMode.NO_ACCESS`

## Tipo
QA Automatizada — Unitário/Integração (`easy-maintenance-api`, Mockito/`@SpringBootTest`, mesmo
padrão de `UsersServiceLoginAccessTest`)

## Categoria
Backend / Segurança (login, 2FA)

## Prioridade
🟡 Médio — gap identificado na implementação do EPIC-041: o caminho de `authenticate()` tem
cobertura parametrizada completa por `SubscriptionStatus`/`AccessMode`
(`UsersServiceLoginAccessTest`), mas `verifyTwoFactor()` reaproveita a mesma checagem
(`resolveLoginAccessMode`) sem um teste dedicado isolando esse caminho.

## Épico
EPIC-041 (origem: TASK-397)

## Descrição
1. Teste parametrizado análogo ao de `authenticate()`: para cada valor de `AccessMode` exceto
   `NO_ACCESS`, `verifyTwoFactor()` com código correto deve suceder normalmente.
2. Caso dedicado: `AccessMode.NO_ACCESS` com código 2FA **correto** deve rejeitar com a mesma
   exceção/mensagem usada em `authenticate()` (distinta de código 2FA inválido).
3. Caso de regressão: código 2FA **incorreto** nunca deve chegar a avaliar `AccessMode` — mantém a
   mensagem genérica de código inválido, mesmo que o usuário esteja bloqueado (mesmo padrão já
   confirmado para senha incorreta em `authenticate()`).

## Justificativa para Automatização
- `verifyTwoFactor()` é um segundo ponto de entrada de login, com a mesma superfície de risco que
  motivou o teste parametrizado completo em `authenticate()` (ver FLOW-013, Riscos) — sem teste
  dedicado, uma refatoração futura do 2FA pode remover a checagem silenciosamente sem quebrar
  nenhum teste existente.
- Validado manualmente no MTD-010 (Cenário 8), mas QA manual não roda em CI — não protege contra
  regressão automática.

## Cobertura Esperada
- ~10 valores de `AccessMode`/`SubscriptionStatus` via `@EnumSource` (exceto `NO_ACCESS`) → sucesso.
- 1 cenário dedicado `NO_ACCESS` + código correto → rejeitado.
- 1 cenário de regressão: código incorreto + `NO_ACCESS` → mensagem de código inválido, não de
  acesso suspenso (prova que a ordem de checagem não mudou).

## Status
🟢 Implementado (04/11/2026) — branch `feature/EPIC-041-admin-access-control`
(`easy-maintenance-api`, commit `68b7678`). `UsersServiceTwoFactorAccessTest` novo, cobrindo:
- todo `AccessMode` exceto `NO_ACCESS` completa o 2FA normalmente (`@ParameterizedTest`/`@EnumSource`)
- `NO_ACCESS` rejeita mesmo com código 2FA correto (`ForbiddenException`, mensagem distinta)
- código 2FA incorreto nunca avalia `AccessMode` (mantém `ErrorResponseException` genérico)

Suíte completa: 1697 testes (1693 + 4 novos), 0 falhas. Branch ainda não mergeada em `staging`.
