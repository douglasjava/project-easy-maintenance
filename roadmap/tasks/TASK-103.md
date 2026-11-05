# TASK-103 — Backend: auditoria de criação e modificação em maintenance_items e maintenances

## Tipo
BACKEND

## Categoria
Auditoria / Rastreabilidade

## Prioridade
🟠 Alto

## Fase
3 — Produto

## Épico
EPIC-013 — Gestão de Equipe por Conta (Team Members)

---

## Contexto

Com a introdução de membros de equipe (EPIC-013), múltiplos usuários agora podem operar sobre as mesmas organizações. Torna-se necessário registrar **quem criou** e **quem modificou por último** cada item de manutenção e cada manutenção registrada.

### Decisão técnica — `Long` simples, sem `@ManyToOne`

Os campos devem ser armazenados como `Long` direto na coluna, **sem** anotação de relacionamento JPA (`@ManyToOne` / `@JoinColumn`). Motivo:

- Evita SELECT adicional escondido (N+1) ao carregar listas de itens/manutenções
- O nome do usuário é exibido apenas em contextos específicos (detalhe do item, histórico); nesse caso o frontend faz uma chamada direcionada ou o service faz lookup pontual pelo ID
- Mantém queries de listagem eficientes sem JOIN desnecessário
- Alinhado com o padrão já adotado para `organizationCode` (String simples, sem entidade)

---

## O que fazer

### 1. Migration — `maintenance_items`

```sql
ALTER TABLE maintenance_items
    ADD COLUMN created_by  BIGINT NULL,
    ADD COLUMN updated_by  BIGINT NULL;
```

### 2. Migration — `maintenances`

```sql
ALTER TABLE maintenances
    ADD COLUMN created_by  BIGINT NULL,
    ADD COLUMN updated_by  BIGINT NULL;
```

> Ambas as colunas são `NULL` para não quebrar registros históricos existentes.

### 3. Entidades

Adicionar em `MaintenanceItem.java` e `Maintenance.java`:

```java
@Column(name = "created_by")
private Long createdBy;

@Column(name = "updated_by")
private Long updatedBy;
```

Sem `@ManyToOne`. Sem `@JoinColumn`. Sem `FetchType`.

### 4. Preenchimento automático

Em cada service que cria/atualiza os registros (`MaintenanceItemService`, `MaintenanceService`):

- `createdBy`: preenchido no momento da criação com o ID do usuário autenticado (via `AuthenticationService.getCurrentUser().getId()`)
- `updatedBy`: atualizado em cada modificação com o ID do usuário autenticado
- `createdBy` nunca é sobrescrito após a criação

### 5. Exposição na API (mínima)

Incluir `createdBy` e `updatedBy` nos DTOs de resposta existentes onde fizer sentido exibir (ex.: detalhe do item, resposta de criação). Campos opcionais (`null` para registros históricos).

---

## Critérios de Aceite

- [ ] Colunas `created_by` e `updated_by` adicionadas via migration em `maintenance_items`
- [ ] Colunas `created_by` e `updated_by` adicionadas via migration em `maintenances`
- [ ] Campos declarados como `Long` simples nas entidades (sem anotação de relacionamento)
- [ ] `createdBy` preenchido automaticamente na criação; nunca sobrescrito
- [ ] `updatedBy` atualizado automaticamente em cada modificação
- [ ] Campos incluídos nos DTOs de resposta relevantes
- [ ] Registros históricos (anteriores à migration) permanecem com `NULL` sem quebrar leitura
- [ ] Testes unitários cobrindo o preenchimento correto dos campos nos services

## Esforço Estimado
Médio — migration + ajuste de entidades + services + DTOs + testes

## Dependências
- EPIC-013 (TASK-098): endpoint `/me/team/users` — cria o contexto que motiva este rastreamento
- `AuthenticationService.getCurrentUser()` já disponível

## Risco
- Registros existentes terão `NULL` nos novos campos — tratar como "desconhecido" na UI
- Garantir que o preenchimento ocorra no nível do service, não do controller, para consistência em todos os pontos de entrada
