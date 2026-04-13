# TASK-041 — Configurar defaults globais do React Query

## Tipo
FRONTEND

## Categoria
Performance / React Query

## Prioridade
🟠 Alto

## Fase
2 — Estabilização Pós-Lançamento

## Épico
EPIC-009 — Performance Frontend

## Descrição
O `QueryClient` em `src/components/Providers.tsx` é instanciado com `new QueryClient()` sem nenhuma configuração. Isso resulta em `staleTime: 0` e `refetchOnWindowFocus: true` para todas as queries da aplicação — ou seja, toda navegação entre páginas e toda troca de aba/janela dispara re-fetches de todos os dados ativos, mesmo quando foram carregados há poucos segundos.

**Arquivo afetado:** `src/components/Providers.tsx:6`

**Configuração atual:**
```ts
const [queryClient] = useState(() => new QueryClient());
```

**Configuração proposta:**
```ts
const [queryClient] = useState(
  () =>
    new QueryClient({
      defaultOptions: {
        queries: {
          staleTime: 1000 * 60 * 2,       // 2 minutos
          refetchOnWindowFocus: false,
          retry: 1,
        },
      },
    })
);
```

Queries que precisam de dados sempre frescos (ex: notificações, dados de billing em tempo real) devem sobrescrever `staleTime: 0` localmente.

## Critérios de Aceite
- [ ] `QueryClient` instanciado com `defaultOptions` configurados
- [ ] `staleTime` global de 2 minutos aplicado
- [ ] `refetchOnWindowFocus: false` globalmente
- [ ] `retry: 1` globalmente (evita 3 tentativas padrão em erros de rede)
- [ ] AccessContextProvider mantém seu próprio `staleTime: 5min` (sem regressão)
- [ ] Navegando entre `/items` → `/maintenances` → `/items`, a segunda visita a `/items` não dispara nova requisição se os dados têm menos de 2 minutos
- [ ] Trocar de aba e voltar não dispara requisições desnecessárias

## Esforço
Pequeno (< 1 hora)

## Status
Concluído

## Impacto Esperado
Alto — elimina a principal causa de requisições redundantes em toda a aplicação com uma mudança de 10 linhas.
