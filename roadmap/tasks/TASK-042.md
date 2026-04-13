# TASK-042 — Adicionar loading.tsx nas rotas principais

## Tipo
FRONTEND

## Categoria
Performance / UX / Next.js

## Prioridade
🟠 Alto

## Fase
2 — Estabilização Pós-Lançamento

## Épico
EPIC-009 — Performance Frontend

## Descrição
Nenhum arquivo `loading.tsx` existe na estrutura `src/app/`. O Next.js App Router usa esses arquivos para exibir uma UI de carregamento instantânea enquanto o conteúdo da página é preparado — sem eles, o usuário vê a página anterior congelada ou uma tela em branco durante a navegação, o que cria uma percepção de lentidão mesmo quando o carregamento real é rápido.

**Rotas prioritárias para criação de loading.tsx:**
- `src/app/loading.tsx` — Dashboard (página inicial)
- `src/app/items/loading.tsx` — Listagem de itens
- `src/app/maintenances/loading.tsx` — Listagem de manutenções
- `src/app/organizations/loading.tsx` — Listagem de organizações

**Padrão de implementação:** Skeleton loaders usando as classes Bootstrap já presentes no projeto (`.placeholder`, `.placeholder-glow`), replicando a estrutura visual de cada página.

**Exemplo para `src/app/items/loading.tsx`:**
```tsx
export default function ItemsLoading() {
  return (
    <div className="container-fluid py-4">
      <div className="placeholder-glow mb-4">
        <span className="placeholder col-3 rounded" style={{ height: 28 }} />
      </div>
      {[...Array(5)].map((_, i) => (
        <div key={i} className="placeholder-glow mb-3 p-3 border rounded">
          <span className="placeholder col-4" />
          <span className="placeholder col-2 ms-3" />
        </div>
      ))}
    </div>
  );
}
```

## Critérios de Aceite
- [ ] `loading.tsx` criado nas 4 rotas prioritárias: `/`, `/items`, `/maintenances`, `/organizations`
- [ ] Cada skeleton reflete a estrutura visual da página correspondente (header + lista)
- [ ] Nenhum `"use client"` nos arquivos loading.tsx (devem ser Server Components)
- [ ] Skeletons visíveis durante navegação entre páginas
- [ ] Não interfere com o comportamento existente das páginas

## Esforço
Pequeno (2–3 horas)

## Status
Concluído

## Impacto Esperado
Alto — melhoria imediata na performance percebida pelo usuário sem alterar nenhuma lógica de negócio.
