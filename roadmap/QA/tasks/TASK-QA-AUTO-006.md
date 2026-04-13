# TASK-QA-AUTO-006 — Testes E2E: Performance React Query sem Requisições Redundantes

## Tipo
QA Automatizada — E2E (End-to-End)

## Categoria
Performance / Frontend / React Query

## Prioridade
🟡 Médio

## Épico
EPIC-009 — Performance Frontend

## Flow relacionado
[FLOW-010](../Flow/FLOW-010.md)

## Descrição
Criar testes E2E instrumentados com interceptor de network para validar que as otimizações de cache do React Query (TASK-041) estão funcionando corretamente: segunda visita a uma rota dentro do `staleTime` não dispara re-fetch, troca de aba não causa re-fetch, e a listagem de itens executa no máximo 2 requisições na carga inicial.

## Justificativa para Automatização
- Sem teste automatizado, regressões de performance de cache são invisíveis até usuários reclamarem de lentidão
- Uma alteração no `QueryClient` (ex: remover `staleTime`) elimina todo o benefício de performance silenciosamente
- Alto impacto de UX com baixo custo de manutenção do teste — uma vez estável, raramente falha

## Tecnologias
- Playwright (recomendado) ou Cypress
- Network interceptors para contar requests
- `page.on('request', ...)` ou `cy.intercept(...)` para monitorar chamadas à API

## Cobertura Esperada

### Cache hit — sem re-fetch na segunda visita
- [ ] Navegar para /items → aguardar carregamento → navegar para /maintenances → voltar para /items
- [ ] Verificar que ZERO novas requests para o endpoint de listagem de itens foram feitas na segunda visita
- [ ] Mesmo teste para /maintenances como rota de volta

### Sem re-fetch em window focus
- [ ] Abrir /items → focar outra aba → voltar para a aba da aplicação
- [ ] Verificar que ZERO novas requests foram disparadas ao retornar o foco

### Expiração correta do cache (staleTime = 2 min)
- [ ] Navegar para /items → aguardar 2+ minutos (mock de tempo com `page.clock.setSystemTime` no Playwright)
- [ ] Navegar para /maintenances e voltar para /items
- [ ] Verificar que NOVA request é feita (staleTime expirado — comportamento correto)

### Skeleton de loading (primeira visita sem cache)
- [ ] Limpar cookies e storage → acessar /items com rede lenta (throttle)
- [ ] Verificar que skeleton é exibido antes dos dados carregarem
- [ ] Verificar que NENHUMA tela branca ocorre durante o carregamento

### Máximo 2 requests em /items (sem N+1)
- [ ] Acessar /items pela primeira vez
- [ ] Contar requests de dados (excluindo estáticos: CSS, fonts, images)
- [ ] Verificar que no máximo 2 requests de dados foram feitas

### Middleware de auth sem flash de tela (TASK-045)
- [ ] Sem autenticação, navegar para /items diretamente
- [ ] Verificar que NÃO há flash da tela de /items antes do redirect para /login

## Subtasks
- [ ] Configurar Playwright ou Cypress no repositório frontend (se não existir)
- [ ] Criar helper para limpar cache React Query entre testes (`localStorage.clear()` + cookie reset)
- [ ] Criar helper para mock de tempo com `page.clock` (Playwright) para testar expiração
- [ ] Implementar interceptor de contagem de requests por endpoint
- [ ] Criar classe `ReactQueryCacheE2E` ou `performance.spec.ts` com os cenários listados
- [ ] Integrar no CI (pode ser suite separada — mais lenta que unitários)

## Esforço Estimado
Grande (10-15h) — incluindo setup inicial de E2E framework se não existir

## Dependências
- Framework E2E configurado no repositório frontend
- Ambiente de staging disponível para execução

## Observação
Esta task é de menor urgência do que as de segurança. Recomendar para SPRINT-04 ou sprint dedicada a qualidade.

## Status
Pendente — implementar durante SPRINT-04 ou Sprint de Qualidade
