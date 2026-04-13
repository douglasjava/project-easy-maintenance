# TASK-043 — Migrar useDashboardData para useQuery

## Tipo
FRONTEND

## Categoria
Performance / React Query / Refactor

## Prioridade
🟡 Médio

## Fase
2 — Estabilização Pós-Lançamento

## Épico
EPIC-009 — Performance Frontend

## Descrição
O hook `src/hooks/useDashboardData.ts` implementa data fetching manualmente com `useState` + `useEffect`. Isso significa que não há cache: toda vez que o usuário navega para o dashboard (página `/`), as requisições são disparadas do zero, mesmo que o usuário tenha acabado de sair da página há 5 segundos.

**Problema específico:**
- Sem cache → dashboard sempre mostra loading na volta
- Sem deduplicação → múltiplas instâncias do hook disparam chamadas redundantes
- Sem React Query devtools integration → difícil debugar

**Migração proposta:**

```ts
// Antes — useState/useEffect manual
const [data, setData] = useState(null);
const [isLoading, setIsLoading] = useState(false);

useEffect(() => {
  if (!canFetch) return;
  setIsLoading(true);
  fetchDashboard(params).then(setData).finally(() => setIsLoading(false));
}, [params, canFetch]);

// Depois — useQuery
const { data, isLoading, error, refetch } = useQuery({
  queryKey: ["dashboard", params],
  queryFn: () => fetchDashboard(params),
  enabled: canFetch,
  staleTime: 1000 * 60 * 2,
});
```

A interface pública do hook (`data`, `isLoading`, `error`, `refresh`, `hasNoOrganization`, `isAccessDenied`) deve ser preservada para não exigir mudanças nos consumidores.

## Critérios de Aceite
- [ ] Hook migrado para `useQuery` com queryKey `["dashboard", params]`
- [ ] `enabled` controlado pelas mesmas condições da implementação atual (token, auth loaded, access loaded, org code, permissão)
- [ ] `staleTime` de 2 minutos aplicado
- [ ] Interface pública do hook preservada: `data`, `isLoading`, `error`, `refresh()`, `hasNoOrganization`, `isAccessDenied`
- [ ] Navegar para outra página e voltar ao dashboard em menos de 2 minutos não dispara nova requisição
- [ ] `refresh()` continua funcionando (deve chamar `refetch()` internamente)
- [ ] Estados `hasNoOrganization` e `isAccessDenied` derivados corretamente do resultado da query

## Esforço
Pequeno (2–4 horas)

## Status
Concluído

## Impacto Esperado
Alto — o dashboard é a página mais acessada da aplicação. Cache elimina o loading redundante na maioria das visitas.
