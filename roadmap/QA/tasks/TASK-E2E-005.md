# TASK-E2E-005 — Testes E2E: Performance React Query sem Requisições Redundantes

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

## Migração
Migração de **TASK-QA-AUTO-006** para o projeto `easy-maintenance-e2e`.

## Descrição
Criar testes E2E com Playwright instrumentados com interceptor de network para validar que as otimizações de cache do React Query (TASK-041) estão funcionando corretamente: segunda visita a uma rota dentro do `staleTime` não dispara re-fetch, troca de aba não causa re-fetch, e a listagem de itens executa no máximo 2 requisições na carga inicial.

## Justificativa
- Sem teste automatizado, regressões de performance de cache são invisíveis até usuários reclamarem
- Uma alteração em `QueryClient` (ex: remover `staleTime`) elimina todo benefício de performance silenciosamente
- Alto impacto de UX com baixo custo de manutenção — uma vez estável, raramente falha

## Tecnologias
- Playwright (TypeScript) — com browser (projeto `ui`)
- `page.on('request', ...)` para interceptar e contar chamadas à API
- `page.clock.setSystemTime()` para simular expiração de `staleTime`
- Docker Compose E2E + Next.js frontend

## Cobertura Esperada

### Cache hit — sem re-fetch na segunda visita
- [ ] Navegar para `/items` → aguardar carregamento → navegar para `/maintenances` → voltar para `/items`
- [ ] Verificar que ZERO novas requests para o endpoint de listagem de itens foram feitas na segunda visita
- [ ] Mesmo teste para `/maintenances` como rota de retorno

### Sem re-fetch em window focus
- [ ] Abrir `/items` → focar outra aba (via `page.evaluate`) → retornar foco para a aba da aplicação
- [ ] Verificar que ZERO novas requests foram disparadas ao retornar o foco

### Expiração correta do cache (staleTime = 2 min)
- [ ] Navegar para `/items` → usar `page.clock.setSystemTime` para avançar 3 minutos
- [ ] Navegar para `/maintenances` e voltar para `/items`
- [ ] Verificar que NOVA request é feita (staleTime expirado — comportamento correto)

### Skeleton de loading (primeira visita sem cache)
- [ ] Limpar cookies e localStorage → acessar `/items` com rede throttled
- [ ] Verificar que skeleton é exibido antes dos dados carregarem
- [ ] Verificar que NENHUMA tela branca ocorre durante o carregamento

### Máximo 2 requests em /items (sem N+1)
- [ ] Acessar `/items` pela primeira vez (cache limpo)
- [ ] Contar requests de dados (excluindo estáticos: CSS, fonts, imagens)
- [ ] Verificar que no máximo 2 requests de dados foram feitas

### Middleware de auth sem flash de tela (TASK-045)
- [ ] Sem autenticação, navegar para `/items` diretamente
- [ ] Verificar que NÃO há flash da tela de `/items` antes do redirect para `/login`

## Subtasks
- [ ] Adicionar projeto `ui` no `playwright.config.ts` com Chromium configurado
- [ ] Criar helper `countApiRequests(page, urlPattern)` usando `page.on('request', ...)`
- [ ] Criar helper `clearReactQueryCache(page)` via `localStorage.clear()` + reload
- [ ] Implementar `tests/frontend/react-query-cache.spec.ts`
- [ ] Adicionar Next.js frontend ao `docker-compose.e2e.yml`
- [ ] Integrar na suite CI como job separado (mais lento — rodar em PRs que tocam frontend)

## Esforço Estimado
Grande (10-15h) — inclui configuração do browser project no Playwright e integração do frontend no Docker Compose

## Dependências
- TASK-E2E-001 (setup Playwright) concluída
- Frontend Next.js rodando via Docker Compose

## Observação
Esta task é de menor urgência do que as de segurança (TASK-E2E-002) e billing (TASK-E2E-003). Recomendar para Sprint de Qualidade após o setup do projeto E2E estar estável.

## Status
Pendente
