# EPIC-009 — Performance Frontend

## Status
Concluído ✅ — 5/5 tasks entregues (SPRINT-06 era autônoma, tarefas 041–045 entregues em sprint anterior)

## Objetivo
Eliminar os principais gargalos de performance de navegação no frontend, tornando a experiência do usuário fluida e responsiva entre páginas, sem regressões de funcionalidade.

## Descrição
O diagnóstico de performance frontend identificou múltiplos problemas compounding que causam navegação lenta: React Query sem configuração global (staleTime: 0 para todos os dados), padrão N+1 de requisições na página de itens, ausência de qualquer loading.tsx nas rotas principais, validação de autenticação feita no cliente após hidratação, e dashboard sem cache. A combinação desses fatores faz com que cada navegação seja tratada como um cold start completo.

## Impacto no Produto
- **Sem este épico:** Cada troca de página dispara múltiplas requisições desnecessárias, o usuário vê telas em branco durante a navegação, e o dashboard sempre carrega do zero mesmo com dados recentes disponíveis.
- **Com este épico:** Navegação instantânea para dados já carregados, feedback visual imediato durante carregamentos, redução de até 90% nas requisições redundantes e eliminação do padrão N+1 na listagem de itens.

## Tasks Relacionadas

| ID | Título | Prioridade | Fase |
|----|--------|-----------|------|
| TASK-041 | Configurar defaults globais do React Query | 🟠 Alto | 2 |
| TASK-042 | Adicionar loading.tsx nas rotas principais | 🟠 Alto | 2 |
| TASK-043 | Migrar useDashboardData para useQuery | 🟡 Médio | 2 |
| TASK-044 | Eliminar N+1 de permissões na página de itens | 🟡 Médio | 2 |
| TASK-045 | Criar middleware.ts para guards de autenticação | 🟡 Médio | 2 |

## Critério de Conclusão do Épico
- [ ] QueryClient configurado com `staleTime` global e `refetchOnWindowFocus: false`
- [ ] Skeletons de carregamento visíveis nas rotas `/`, `/items`, `/maintenances`, `/organizations`
- [ ] Dashboard reutiliza cache do React Query ao navegar de volta
- [ ] Página de itens executa no máximo 2 requisições na carga inicial (lista + permissões em bulk)
- [ ] Redirecionamentos de autenticação ocorrem via middleware (edge), sem flash de tela
