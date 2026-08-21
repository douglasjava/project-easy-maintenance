# TASK-185 — Frontend: `/ai-onboarding` — filtro instantâneo de catálogo + IA como complemento progressivo

## Tipo
FRONTEND

## Categoria
Onboarding por IA / UX

## Prioridade
🟠 Alto

## Épico
[EPIC-025](../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas

## QA obrigatório
Sim — QA manual dos 3 cenários: (1) sem descrição — tabela abre na hora só com catálogo; (2) com
descrição — tabela abre com catálogo na hora, itens de IA chegam depois sem perder seleção; (3) IA
falha (simular erro) — tela não bloqueia, catálogo continua disponível com aviso não-bloqueante.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-20-onboarding-catalog-filter-design.md`.

Depende de TASK-182 (`catalog-preview`) e TASK-184 (`alreadyCoveredItemTypes` + `normId` em
`apply()`). Reescreve o fluxo de `easy-maintenance-web/src/app/ai-onboarding/page.tsx` pra usar o
filtro determinístico como caminho principal (instantâneo, sem custo de IA) e a IA como complemento
opcional só quando há descrição livre.

## Objetivo

Etapa 1 (formulário) sem mudança de campos. `handleGenerate()` e a Etapa 2 (tabela) mudam pra
refletir a nova arquitetura de duas camadas.

## Escopo

### 1. Tipos (`src/types/ai-onboarding.ts`)

```ts
export interface AiItemPreview {
    itemType: string;
    category: string;
    criticality: string;
    maintenance: AiMaintenancePreview;
    source: "CATALOG" | "AI";   // novo
    normId?: number;             // novo
}
```

### 2. `handleGenerate()` reescrito

```ts
async function handleGenerate() {
    setLoading(true);
    try {
        const payload = { companyType, description };

        // 1. Catálogo — síncrono, sempre
        const { data: catalogData } = await api.post<AiBootstrapPreviewResponse>(
            "/ai/bootstrap/catalog-preview", payload
        );
        const catalogItems = catalogData.items.map((it, idx) => ({
            ...it, selected: true, localId: `catalog-${idx}`
        }));
        setItems(catalogItems);
        setStep(2);
        setLoading(false);

        // 2. IA — só se houver descrição
        if (description.trim()) {
            setAiLoading(true); // novo estado — indicador discreto na tabela
            try {
                const alreadyCoveredItemTypes = catalogItems.map(it => it.itemType);
                const { data: accepted } = await api.post<{ jobId: string }>(
                    "/ai/bootstrap/preview", { ...payload, alreadyCoveredItemTypes }
                );
                const aiData = await pollAiJob<AiBootstrapPreviewResponse>(accepted.jobId, 45, 2000);
                if (aiData.usedAi && aiData.items.length > 0) {
                    const aiItems = aiData.items.map((it, idx) => ({
                        ...it, selected: true, localId: `ai-${idx}`
                    }));
                    setItems(prev => [...prev, ...aiItems]); // anexa, não substitui
                }
            } catch {
                toast("A IA não conseguiu complementar as sugestões, mas os itens do catálogo continuam disponíveis.", { icon: "⚠️" });
            } finally {
                setAiLoading(false);
            }
        }
    } catch (err: unknown) {
        const mapped = mapError(err);
        toast.error(mapped.global ?? "Falha ao gerar pré-cadastros. Tente novamente.");
        setLoading(false);
    }
}
```

Ponto-chave: o catálogo nunca é bloqueado ou descartado por falha da IA — só o complemento é
opcional. Falha da IA vira aviso não-bloqueante (`toast` informativo, não `toast.error` bloqueante).

### 3. Indicador de carregamento da IA (Etapa 2)

Quando `aiLoading === true`, mostrar uma linha/banner discreto no topo da tabela: "🔄 Buscando
sugestões adicionais com IA...". Desaparece quando `aiLoading` volta a `false` (sucesso ou erro).

### 4. Coluna/badge "Origem" na tabela

Nova coluna antes ou depois de "Item": badge "✅ Catálogo" (verde) quando `source === "CATALOG"`,
"✨ IA" (mesmo estilo do badge que já existe hoje no cabeçalho da Etapa 2) quando `source === "AI"`.

### 5. `handleApply()` — payload inclui `normId`/`source`

```ts
const payload = {
    items: selectedItems.map(({ selected, localId, ...rest }) => rest)
    // rest já inclui source e normId, que agora fazem parte de AiItemPreview
};
```

## Critérios de Aceite

- [ ] Sem descrição preenchida: Etapa 2 abre com os itens do catálogo, sem nenhum job/polling
      disparado
- [ ] Com descrição preenchida: Etapa 2 abre com catálogo na hora; itens de IA são anexados depois,
      sem resetar seleção/edição já feita pelo usuário nas linhas do catálogo
- [ ] Falha do job de IA não bloqueia a tela — catálogo continua utilizável, aviso não-bloqueante
      aparece
- [ ] Tabela mostra origem (Catálogo/IA) por linha
- [ ] `handleApply()` envia `normId` e `source` de cada item selecionado
- [ ] `npm run build` limpo

## Dependências
TASK-182 (endpoint `/catalog-preview`), TASK-184 (`alreadyCoveredItemTypes` + `normId` em
`apply()`). TASK-183 (bugfix) não é dependência direta do frontend, mas idealmente já mergeada
antes (corrige o dado por trás do que esta tela cria).

## Riscos
Médio — reescreve a lógica central da tela de onboarding por IA (`handleGenerate`), incluindo
estado assíncrono parcial (catálogo já renderizado recebendo itens de IA depois). Mitigado por
manter a estrutura de estado (`items[]`, `selected`, `localId`) igual à atual — só a origem dos
dados e o timing de chegada mudam.

## Esforço
Médio

## Status
✅ Implementada e commitada (20/08/2026) na branch `feature/ai-onboarding-catalog-filter`
(`easy-maintenance-web`). `npm run build` limpo. PR
[#46](https://github.com/douglasjava/easy-maintenance-web/pull/46) aberta em 21/08/2026 (mesma
branch reúne toda a Fase 2 do frontend, incluindo TASK-186).
