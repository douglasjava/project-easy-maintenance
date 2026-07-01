# TASK-105 — Frontend: botão "Limpar" sempre visível em /items (paridade com /maintenances)

## Tipo
FRONTEND

## Categoria
UX / Consistência de Interface

## Prioridade
🔵 Baixo

## Fase
3 — Produto

## Épico
EPIC-006 — Frontend UX

---

## Contexto

Em `/items`, o botão "Limpar filtros" existe no código mas está envolto em `{hasActiveFilters && (...)}` — ou seja, desaparece quando nenhum filtro está ativo. Em `/maintenances`, o botão é **sempre visível**, mudando apenas de estilo: cinza/normal quando sem filtros ativos, vermelho/negrito quando há filtros aplicados.

O usuário esperaria o mesmo comportamento em ambas as telas.

### Comportamento atual — `/items`

```tsx
{hasActiveFilters && (
  <div className="col-12 col-md-auto">
    <button
      className="btn btn-outline-secondary btn-sm"
      type="button"
      onClick={clearFilters}
      title="Limpar filtros"
    >
      ✕ Limpar
    </button>
  </div>
)}
```

### Comportamento esperado — igual a `/maintenances`

```tsx
<div className="col-12 col-md-2">
  <button
    className="btn btn-sm w-100"
    style={{
      border: "1px solid #e5e7eb",
      borderRadius: 8,
      color: hasActiveFilters ? "#dc2626" : "#6b7280",
      fontWeight: hasActiveFilters ? 600 : 400,
    }}
    onClick={clearFilters}
  >
    {hasActiveFilters ? "✕ Limpar" : "Limpar"}
  </button>
</div>
```

---

## O que fazer

Em `src/app/items/page.tsx`, localizar o bloco condicional do botão Limpar e substituir por renderização incondicional com estilo dinâmico:

- Remover o `{hasActiveFilters && (...)}` que envolve o botão
- Aplicar `col-12 col-md-2` + `w-100` (largura total no mobile, igual à /maintenances)
- Estilo inline: `color` e `fontWeight` condicionais baseados em `hasActiveFilters`
- Label: `"✕ Limpar"` quando ativo, `"Limpar"` quando inativo

Nenhuma outra mudança necessária — `clearFilters()` e `hasActiveFilters` já existem e funcionam corretamente.

---

## Critérios de Aceite

- [ ] Botão "Limpar" sempre visível na área de filtros de `/items`
- [ ] Estilo cinza + texto "Limpar" quando nenhum filtro ativo
- [ ] Estilo vermelho + texto "✕ Limpar" quando há filtro(s) ativo(s)
- [ ] Largura total no mobile (`w-100`), coluna `col-md-2` no desktop
- [ ] Clicar limpa todos os filtros e reseta o cursor de paginação (comportamento já existente)
- [ ] Sem regressão nos filtros de status, categoria e tipo de item

## Esforço Estimado
Muito baixo — alteração cirúrgica de ~10 linhas em um único arquivo

## Dependências
Nenhuma

## Risco
Baixo — mudança puramente visual; lógica de `clearFilters()` não é tocada
