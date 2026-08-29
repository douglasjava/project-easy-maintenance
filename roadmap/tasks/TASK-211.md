# TASK-211 — BUGFIX Backend: coluna `landing_leads.fbc` curta demais derruba o cadastro do lead

## Tipo
BUGFIX

## Categoria
Backend / Leads (Meta Conversions API, TASK-157)

## Prioridade
🔴 Crítico

## Épico
Sem épico — achado por Douglas em log de produção, 29/08/2026.

## QA obrigatório
Sim — QA manual: confirmar em produção (após deploy) que um cadastro de lead vindo de um clique de
anúncio Meta (cookie `_fbc` presente) não gera mais `Data truncation` no log e o lead é persistido.

---

## Contexto

Douglas encontrou no log de produção (29/08, 00:10) duas tentativas seguidas de cadastro do mesmo
lead (`sindifacil@gmail.com`) falhando com o mesmo erro:

```
SQL Error: 1406, SQLState: 22001
Data truncation: Data too long for column 'fbc' at row 1
insert into landing_leads (..., fbc, ...) values (...)
```

`sindifacil` é exatamente o público-alvo do produto (síndico/administradora) — **as duas tentativas
falharam e o lead foi perdido por completo**, não só a atribuição de anúncio. Dado que o produto tem
0 clientes pagantes ([[project_zero_customers_landing_copy]]), qualquer lead perdido por bug de
backend é grave.

## Causa raiz

A V97 (TASK-157, Meta CAPI) criou `landing_leads.fbc` como `VARCHAR(64)`. O cookie `_fbc` real que o
Meta Pixel seta no navegador tem o formato `fb.<subdomain_index>.<creation_time>.<fbclid>`, e o
`fbclid` sozinho já passa de 64 caracteres em cliques recentes de anúncio — o valor nunca coube na
coluna.

A entidade `LandingLead.fbc` não declarava `@Column(length=...)`, então o Hibernate assumia o
default implícito de 255 — divergente dos 64 reais da coluna migrada. Esse descompasso não é
pego pelo `ddl-auto=validate` no boot (validação de schema não é estrita o bastante pra comprimento
de VARCHAR nessa versão/dialect), só se manifesta em runtime quando um valor realmente longo é
inserido. `LeadService.createLead` monta o `LandingLead` inteiro (email, nome, UTMs, etc.) num único
`.save()` dentro de uma transação — sem tratamento por campo, então a falha em `fbc` derruba o
INSERT inteiro, e com ele o lead inteiro (mesmo tendo e-mail/nome válidos).

`GlobalExceptionHandler.handleDataIntegrityViolationException` devolve HTTP 409 com mensagem
genérica ("conflito com os dados existentes") — nem indica ao usuário que é um problema do backend,
não dele.

## Objetivo

Coluna `fbc` comporta um `_fbc` real sem truncar, e a entidade JPA declara o mesmo tamanho
explicitamente (evita esse tipo de mismatch silencioso se repetir).

## Escopo

### Migration `V99__widen_landing_leads_fbc_column.sql`
```sql
ALTER TABLE landing_leads MODIFY COLUMN fbc VARCHAR(255) NULL;
```

### `LandingLead.fbc` — declarar o tamanho explicitamente
```java
@Column(length = 255)
private String fbc;
```

**Fora de escopo (registrado, não corrigido agora):** tornar a criação do lead resiliente a falha
num campo opcional (ex.: capturar `DataIntegrityViolationException` e tentar salvar de novo sem
`fbc`/`fbp`/`eventId`) — o fix direto (coluna do tamanho certo) já resolve o caso relatado sem
precisar dessa camada extra de defesa. Vale reconsiderar se aparecer outro campo opcional com o
mesmo padrão de risco.

## Critérios de Aceite

- [x] Migration `V99` amplia `fbc` para `VARCHAR(255)`
- [x] `LandingLead.fbc` declara `@Column(length = 255)`, alinhado com a coluna real
- [x] Teste de migration (`LandingLeadFbcColumnMigrationTest`, H2 modo MySQL, DDL puro) comprova a
      regressão: falha com o `VARCHAR(64)` antigo, passa com o `VARCHAR(255)` novo
- [x] `mvn test` sem regressão
- [ ] QA manual: lead com `_fbc` real (cookie de clique de anúncio Meta) persiste sem erro em
      produção — pendente de deploy

## Dependências
Nenhuma (TASK-157 introduziu o campo; independente da TASK-209/210).

## Riscos
Baixo — amplia uma coluna VARCHAR existente (`MODIFY COLUMN`, sem perda de dado, sem mudança de
contrato). Mesmo padrão de teste de migration já usado em
`MaintenanceUniqueConstraintMigrationTest`.

## Esforço
Baixo

## Status
✅ Implementado e PR aberta contra `staging`: [api#58](https://github.com/douglasjava/easy-maintenance-api/pull/58).
Branch `bugfix/TASK-211-landing-lead-fbc-column-too-short`, commit `b5982cb` (a partir de `staging`,
já com a TASK-210 mergeada). Suíte completa: 854/854 testes, 0 falhas. QA final (lead com `_fbc` real
persistindo em produção) pendente do merge e deploy.
