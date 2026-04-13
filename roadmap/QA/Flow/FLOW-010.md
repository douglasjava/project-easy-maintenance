# FLOW-010 — Performance Frontend e Cache React Query

## Criticidade
🟡 MEDIUM

## Launch Relevance
UX direta — navegação lenta gera abandono em early adopters e impacta NPS dos primeiros usuários.

## Tasks Relacionadas
- TASK-041 — Configurar defaults globais do React Query
- TASK-042 — Adicionar loading.tsx nas rotas principais
- TASK-043 — Migrar useDashboardData para useQuery
- TASK-044 — Eliminar N+1 de permissões na página de itens
- TASK-045 — Criar middleware.ts para guards de autenticação

## Descrição do Fluxo

O `QueryClient` tem `staleTime: 2min` e `refetchOnWindowFocus: false` globais. Dados recentes permanecem em cache ao navegar entre páginas. Skeletons de loading aparecem durante carregamento inicial em todas as rotas principais. A listagem de itens executa no máximo 2 requisições na carga inicial (lista + permissões em bulk, não N+1). O middleware de edge valida autenticação sem flash de tela branca.

## Comportamentos Esperados

| Comportamento | Baseline (antes) | Esperado (depois) |
|--------------|-----------------|------------------|
| Segunda visita a `/items` < 2min | Nova requisição disparada | Zero novas requisições |
| Troca de aba e retorno | Re-fetch de todos os dados | Sem re-fetch |
| Carregamento inicial de `/items` | Tela em branco | Skeleton visível |
| Listagem de itens: requisições na carga | N+1 (N permissões) | Máximo 2 |
| Rota protegida sem auth | Flash de tela branca + redirect | Redirect imediato via middleware |

## Cenários Críticos

| Cenário | Tipo | Cobertura Atual |
|---------|------|----------------|
| Cache hit na segunda visita (< staleTime) | Performance | Manual |
| Skeleton em loading inicial | UX | Manual |
| Sem re-fetch em `window focus` | Performance | Manual |
| Máximo 2 requests em carga de `/items` | Performance | Manual |
| Redirect sem flash de tela | UX | Manual (TASK-045) |

## Validação Recomendada
- **Manual:** [MTD-008](../MTD/MTD-008.md) — com DevTools Network aberto
- **Automatizada:** [TASK-QA-AUTO-006](../tasks/TASK-QA-AUTO-006.md) — E2E com Playwright

## Gaps
- Sem teste automatizado de performance de cache — regressões invisíveis
- Número exato de requests em `/items` não monitorado automaticamente

## Status de Validação
- [ ] Cache hit em segunda visita validado via DevTools
- [ ] Skeleton visível em todas as rotas principais (/, /items, /maintenances, /organizations)
- [ ] N+1 eliminado na listagem de itens
- [ ] Middleware de auth sem flash de tela
