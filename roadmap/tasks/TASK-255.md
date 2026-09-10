# TASK-255 — BUGFIX: cache "norms" ausente nos profiles local/e2e/prod

## Tipo
BUGFIX

## Categoria
Backend / Configuração

## Prioridade
🔴 Crítico — quebra qualquer chamada de `NormService.findById`, incluindo o fluxo de apply da IA
(`AiBootstrapService`)

## Épico
Nenhum — achado avulso reportado pelo usuário ao testar a IA de onboarding, não relacionado ao
EPIC-030.

## QA obrigatório
Sim — confirmar que `NormService.findById` funciona com o profile `local` ativo (era exatamente o
que estava quebrado).

---

## Contexto
Usuário rodou o fluxo de IA (sugestão de itens/normas, "Gerar plano automático") e o apply falhou
com `Cannot find cache named 'norms'` pra todos os itens sugeridos (`NormService.findById`,
anotado `@Cacheable("norms")`).

## Causa raiz
`TASK-224` (EPIC-025, commit `7c7c9ed6`, 01/09/2026) adicionou `norms` à lista de caches em
`application.properties` (base): `spring.cache.cache-names=suppliersNearby,norms`. Só que
`application-local.properties`, `application-e2e.properties` e `application-prod.properties` cada
um já redeclarava essa mesma propriedade com `spring.cache.cache-names=suppliersNearby` (sem
`norms`) desde antes da TASK-224 — e propriedade de profile **substitui** a da base inteira, não
mescla. Resultado: com qualquer um desses 3 profiles ativos (ou seja, em qualquer boot real da
aplicação), o cache `norms` nunca existia, e o `@Cacheable("norms")` falhava.
`application-hml.properties` (staging) e os profiles de teste não redeclaram
`spring.cache.cache-names`, então herdavam a base corretamente — só local/e2e/prod estavam
quebrados. Não relacionado a nenhum trabalho desta sessão (EPIC-030) — confirmado via `git blame`.

## Escopo
- [x] Adicionar `norms` à lista de `spring.cache.cache-names` em `application-local.properties`,
      `application-e2e.properties` e `application-prod.properties`, espelhando a base.
- [x] Comentário explicando a armadilha (profile substitui, não mescla) pra evitar repetição
      futura se um novo cache for adicionado só na base de novo.

## Viabilidade Técnica
Trivial — mudança de configuração, sem código. Risco de regressão é essencialmente zero (só
adiciona um nome de cache à lista permitida).

## Dependências
Nenhuma.

## Riscos
Baixo. Verificado que `application-hml.properties` (staging) e os profiles de teste não têm essa
armadilha (não redeclaram a propriedade).

## Esforço
Trivial.

## Implementação

### Arquivos modificados
- `src/main/resources/application-local.properties`
- `src/main/resources/application-e2e.properties`
- `src/main/resources/application-prod.properties`

Todos os três: `spring.cache.cache-names=suppliersNearby` → `spring.cache.cache-names=suppliersNearby,norms`,
com comentário explicando por que profile properties sobrescrevem a base inteira em vez de mesclar.

### Verificação
`mvn test` completo — sem regressão (mesma suíte que passava antes, mudança é só de properties).
Não deu pra validar em boot real (mesmo bloqueio de Firebase local desta sessão), mas a causa raiz
é uma leitura direta de `git blame` + comparação textual das 4 arquivos, não uma hipótese — a
correção é objetivamente completa (as 3 properties que faltavam `norms` agora têm).

Branch `bugfix/TASK-255-norms-cache-missing-in-profiles`, criada a partir de `staging`.

## Status
🟢 Corrigido, aguardando você confirmar rodando localmente (é exatamente o cenário que você acabou
de reproduzir) antes de abrir a PR pra staging.
