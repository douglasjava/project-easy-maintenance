# TASK-258 — BUGFIX: FirebaseMessaging impedia o boot local sem credencial real

## Tipo
BUGFIX

## Categoria
Backend / Infraestrutura

## Prioridade
🔴 Crítico — bloqueou validação HTTP real de EPIC-028, EPIC-030 e quase o EPIC-029, todos na mesma
sessão

## Épico
Nenhum — achado durante o EPIC-029 (precisava da API rodando de verdade pra rodar o k6), mas o
impacto é do projeto inteiro: qualquer sessão/ambiente local sem `FIREBASE_SERVICE_ACCOUNT_JSON`
real não conseguia subir a aplicação, ponto final.

## QA obrigatório
Sim — confirmar que a API sobe local sem a variável configurada (comportamento novo) e que push
notification continua funcionando normalmente com credencial real configurada (comportamento
preservado).

---

## Contexto
Ao longo desta sessão, três épicos diferentes precisaram (e não conseguiram) validar mudanças
contra a API rodando de verdade localmente — sempre documentado como "bloqueio de Firebase,
mesmo problema de sempre". Ao investigar de verdade pra poder rodar o k6 do EPIC-029, a causa raiz
foi isolada com precisão.

## Causa raiz
`FirebaseConfig.firebaseMessaging()` (`@Bean`) retorna `null` quando
`FIREBASE_SERVICE_ACCOUNT_JSON` está vazia — comportamento intencional, com um `log.warn` explícito.
O problema é o consumidor: `PushNotificationProvider` injetava `FirebaseMessaging` direto (tipo
não-opcional) via construtor gerado pelo Lombok `@RequiredArgsConstructor`. O Spring recusa injetar
um bean que resolveu pra `null` num parâmetro de construtor obrigatório —
`UnsatisfiedDependencyException`, aplicação inteira falha ao subir, mesmo a classe já tendo uma
checagem `if (firebaseMessaging == null)` logo na primeira linha do método `send()` que nunca
chegava a ser executada.

## Escopo
- [x] `PushNotificationProvider.firebaseMessaging` vira `Optional<FirebaseMessaging>` — o padrão
      que o próprio Spring documenta pra injeção opcional-aware de um `@Bean` que pode resolver
      pra `null`.
- [x] `send()` ajustado pra `firebaseMessaging.isEmpty()` / `firebaseMessaging.get().send(...)`.
- [x] Testes novos cobrindo os dois caminhos (ausente/presente).

## Viabilidade Técnica
Trivial — troca de tipo + dois pontos de uso, zero mudança de comportamento com Firebase
configurado de verdade (dev com credencial real, staging, produção).

## Dependências
Nenhuma.

## Riscos
Baixo. Comportamento com Firebase configurado é idêntico (mesmo `if` que já existia, só que agora
o Spring de fato consegue chegar até ele).

## Esforço
Pequeno.

## Implementação

### Arquivos modificados
- `PushNotificationProvider.java` — `Optional<FirebaseMessaging>`.
- `PushNotificationProviderTest.java` (novo) — 2 testes: ausente (não toca repositórios) e
  presente (envia pros tokens ativos do usuário).

### Verificação
`mvn test` 989/989 (na hora desta task) → 990/990 depois da TASK-234 corrigida na mesma sessão.
**Validado de ponta a ponta**: aplicação subiu local com sucesso pela primeira vez nesta sessão
inteira — `actuator/health` UP, `POST /auth/login` respondendo de verdade, usado em seguida pra
rodar o k6 do EPIC-029/TASK-235 contra a API real.

Branch `bugfix/TASK-258-firebase-messaging-optional-bean` (a partir de `staging`), mergeada em
`feature/EPIC-029-load-testing` pra poder rodar o k6.

## Status
🟢 Corrigido e validado com a aplicação rodando de verdade. Aguardando abrir PR própria pra
`staging` (fora do fluxo do EPIC-029 — é um fix independente, mesmo padrão da TASK-255/256).
