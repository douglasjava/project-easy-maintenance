# TASK-017 — Enforcement automático de tenant no repository

## Tipo
Segurança / Arquitetura

## Categoria
Backend / Multi-tenancy / Segurança

## Prioridade
🟡 Médio

## Fase
1 — Antes do lançamento

## Épico
EPIC-003 — Multi-tenancy e Autorização

## Descrição
O isolamento multi-tenant atual depende de annotations manuais (`@TenantRequired`) nos serviços. Isso funciona para os endpoints já implementados, mas é frágil: qualquer desenvolvedor que crie um novo endpoint sem a annotation correta cria uma brecha de segurança sem aviso.

A solução ideal é que o próprio framework aplique o filtro de tenant automaticamente em todas as queries de entidades com tenant, usando Hibernate Filters ou Row-Level Security.

## Problema
Modelo atual: desenvolvedor responsável por adicionar o filtro de tenant em cada query. Um `findById()` chamado diretamente em um repositório sem filtro pode retornar um registro de outro tenant.

## Impacto
Crescimento do codebase aumenta a probabilidade de criar acidentalmente um endpoint sem filtro de tenant.

## Dependências
- TASK-009 deve estar concluída (validação de X-Org-Id)

## Critérios de Aceite
- [ ] Entidades com tenant (`MaintenanceItem`, `Maintenance`, `User`, `Organization`, etc.) possuem `@Filter` do Hibernate configurado para `org_code`
- [ ] Filter é habilitado automaticamente via Spring AOP/Interceptor quando `TenantContext` está populado
- [ ] Chamada ao repositório sem TenantContext configurado gera exceção imediata (fail-fast)
- [ ] Teste: query em `MaintenanceItemRepository.findById()` sem contexto de tenant retorna erro
- [ ] Teste: query retorna apenas registros do tenant ativo

## Subtasks
- [ ] Definir estratégia: Hibernate `@FilterDef` + `@Filter` vs Spring Data `@Query` customizado em base repository
- [ ] Implementar `@FilterDef` nas entidades com tenant
- [ ] Implementar `TenantFilterInterceptor` que ativa o filtro após autenticação
- [ ] Criar `BaseRepository` que aplica filtro automaticamente
- [ ] Escrever testes de isolamento

## Esforço
Médio (1-2 dias)

## Risco de não fazer
Com crescimento do time e do codebase, a probabilidade de criar um endpoint sem filtro de tenant aumenta. É uma bomba relógio.

## Status
Concluído
