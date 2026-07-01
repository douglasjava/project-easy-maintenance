# TASK-104 — Backend/Frontend: exibir criador e último modificador nos relatórios de exportação

## Tipo
FULL_STACK

## Categoria
Rastreabilidade / Relatórios

## Prioridade
🟡 Médio

## Fase
3 — Produto

## Épico
EPIC-013 — Gestão de Equipe por Conta (Team Members)

---

## Contexto

Os campos `createdBy` e `updatedBy` (IDs de usuário) foram adicionados às tabelas `maintenance_items` e `maintenances` pela TASK-103. Exibir esses campos nos grids/telas de listagem sobrecarregaria a UI com informação de contexto que não é relevante no fluxo operacional do dia a dia.

A rastreabilidade de criação/modificação faz mais sentido em **relatórios**, onde o usuário tem a intenção explícita de auditar o histórico de operações.

---

## O que fazer

### Backend

#### 1. Resolver nome do usuário para exportação

Os campos `createdBy` e `updatedBy` são `Long` (IDs sem FK). Para exibir o **nome** no relatório, fazer lookup via `UserRepository.findById()` ou `AuthenticationService` no momento da geração do relatório.

Estratégia: ao gerar o relatório, coletar todos os IDs únicos de `createdBy`/`updatedBy` dos registros e fazer **uma única query** para resolver os nomes:

```java
// Coletar IDs únicos
Set<Long> userIds = items.stream()
    .flatMap(i -> Stream.of(i.getCreatedBy(), i.getUpdatedBy()))
    .filter(Objects::nonNull)
    .collect(Collectors.toSet());

// Resolver nomes em batch
Map<Long, String> nameById = userRepository.findAllById(userIds).stream()
    .collect(Collectors.toMap(User::getId, User::getName));

// Usar na projeção
String createdByName = nameById.getOrDefault(item.getCreatedBy(), "—");
```

#### 2. Exportação de itens (`MaintenanceExportService` ou equivalente)

Adicionar colunas ao relatório de itens:
- **Criado por** — nome do usuário que criou o item (`createdBy`)
- **Última alteração por** — nome do usuário da última modificação (`updatedBy`)

Registros históricos anteriores à TASK-103 terão `null` → exibir `"—"` na coluna.

#### 3. Exportação de manutenções

Mesma abordagem para o relatório de manutenções registradas:
- **Registrado por** — nome do usuário que registrou a manutenção (`createdBy`)

---

### Frontend

Nenhuma mudança de UI necessária — os campos de auditoria aparecem apenas no arquivo de exportação (CSV/Excel) gerado pelo backend.

---

## Critérios de Aceite

- [ ] Relatório de itens inclui colunas "Criado por" e "Última alteração por" com nome do usuário (não ID)
- [ ] Relatório de manutenções inclui coluna "Registrado por" com nome do usuário
- [ ] Registros históricos (anteriores à TASK-103) exibem "—" nas colunas de auditoria
- [ ] Resolução de nomes feita em batch (sem N+1) no momento da geração do relatório
- [ ] Nenhuma mudança nos grids/telas de listagem da UI

## Esforço Estimado
Médio — ajuste no serviço de exportação + resolução de nomes em batch

## Dependências
- **TASK-103** (concluída): campos `createdBy`/`updatedBy` disponíveis nas entidades e DTOs

## Risco
- Usuários removidos da equipe: IDs sem correspondência no `UserRepository` → exibir "—" via `getOrDefault`
- Performance: resolver nomes em batch (não por registro) — sem N+1
