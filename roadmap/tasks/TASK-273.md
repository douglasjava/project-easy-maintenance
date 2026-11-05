# TASK-273 — BUGFIX: Endpoints públicos de fornecedor retornavam 403

## Tipo
BUGFIX

## Categoria
Fornecedores / Marketplace / Segurança

## Prioridade
🔴 Alto — bloqueava por completo o fluxo público de auto-cadastro (mesmo cenário do TASK-272,
segunda camada do mesmo bug de ponta a ponta)

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — Douglas re-testa C4/C6 de [TASK-QA-MAN-022](../QA/tasks/TASK-QA-MAN-022.md) a partir desta
correção (TASK-272 destravou o frontend, esta destrava o backend).

---

## Contexto

Depois da correção do [TASK-272](TASK-272.md) (frontend redirecionava pro login), Douglas
conseguiu chegar na chamada real e encontrou o próximo bloqueio: `POST
/easy-maintenance/api/v1/public/suppliers/register` retornava `403 Forbidden`, mesmo sendo um
endpoint público por design (`SupplierPublicController`, sem anotação de auth, `@RateLimit` em vez
de autenticação).

### Causa raiz

`SecurityConfig.java` define explicitamente cada prefixo de rota pública via
`.requestMatchers(...).permitAll()` — não existe um wildcard genérico pra `/public/**`. Os
endpoints já existentes (`/public/resident-tickets/**`, `/public/webhooks/asaas`,
`/public/webhooks/whatsapp`) estão cada um na lista. Os endpoints novos de fornecedor
(`/public/suppliers/register`, `/public/suppliers/manage/{token}`) **nunca foram adicionados** —
caem no `.anyRequest().authenticated()` no fim da cadeia e retornam 403 pra qualquer requisição
sem JWT válido, que é exatamente o caso de um visitante anônimo.

Gap real do plano (`docs/superpowers/plans/2026-09-11-supplier-marketplace-monetization.md`): as
Tasks 5 e 7 (auto-cadastro público e gestão via link mágico) implementaram os controllers e
`@RateLimit`, mas nenhum passo do plano tocou em `SecurityConfig.java` — o padrão de
"endpoint público = sem `@PreAuthorize`" está correto pro código do controller em si, mas o
projeto exige também a liberação explícita em `SecurityConfig`, que ficou de fora da pesquisa do
plano.

Confirmado que `JwtAuthenticationFilter` não é a causa (ele nunca bloqueia sozinho — só popula o
`SecurityContext` quando há token, e deixa passar sem token; quem decide 401/403 é
`authorizeHttpRequests`).

## Escopo

```java
.requestMatchers("/easy-maintenance/api/v1/public/suppliers/**").permitAll()
```
Adicionado logo após a linha de `/public/resident-tickets/**`.

## Critérios de Aceite

- [x] `POST /public/suppliers/register` sem token retorna 201 (ou erro de validação/rate-limit),
      nunca mais 403 de autenticação
- [x] `GET`/`PUT /public/suppliers/manage/{token}` sem token idem
- [x] Nenhum outro endpoint (`/suppliers` autenticado, `/private/admin/suppliers/**`) teve seu
      comportamento de auth alterado
- [x] `mvn test` sem regressão

## Dependências
TASK-264 (registra o endpoint), TASK-266 (gestão via link), TASK-272 (destrava o frontend — sem
essa correção o bug do backend nem seria alcançado pela UI).

## Riscos
Baixo, mas atenção: é uma mudança em `SecurityConfig`, arquivo compartilhado por todo o app. O
padrão `/public/suppliers/**` é específico o bastante pra não vazar nenhuma rota autenticada
(`/suppliers` sem o segmento `public/` continua exigindo login).

## Esforço
Trivial

## Implementação

### Arquivos modificados
`src/main/java/com/brainbyte/easy_maintenance/shared/web/SecurityConfig.java` — 1 linha.

### Verificação
`mvn test` (suíte completa) → PASS, sem regressão.

## Status
🟢 Corrigido. Aguardando Douglas repetir C4/C6 do QA manual pra confirmar.
