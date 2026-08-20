# TASK-182 — Backend: endpoint síncrono `POST /ai/bootstrap/catalog-preview` (filtro determinístico, sem IA)

## Tipo
BACKEND

## Categoria
Onboarding por IA / Redução de custo

## Prioridade
🟠 Alto

## Épico
[EPIC-025](../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas

## QA obrigatório
Sim — QA manual: chamar o endpoint pra cada `company_type`, conferir que os itens retornados batem
com o catálogo esperado, com `normId` preenchido e período correto (não inventado).

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-20-onboarding-catalog-filter-design.md`.

Depende da TASK-181 (`norm_segments` + `NormRepository.findBySegment()`). Esta task expõe esse
filtro como o novo caminho **rápido e gratuito** (sem custo de IA) do onboarding: dado o tipo de
empresa, devolve na hora os itens de manutenção já cobertos pelo catálogo curado.

## Objetivo

Novo método de serviço + endpoint que devolve, sem chamar IA, a lista de itens sugeridos pro
segmento — no mesmo formato já usado pela resposta de preview, mas com origem e dados 100% reais
(sem invenção de norma/período).

## Escopo

### 1. `AiBootstrapService.previewFromCatalog(AiBootstrapPreviewRequest request)`

```java
public AiBootstrapPreviewResponse previewFromCatalog(AiBootstrapPreviewRequest request) {
    List<Norm> norms = normRepository.findBySegment(request.getCompanyType().getDbValue());
    List<AiBootstrapPreviewResponse.BootstrapItem> items = norms.stream()
        .map(this::toCatalogItem)
        .toList();
    return AiBootstrapPreviewResponse.builder()
        .usedAi(false)
        .companyType(request.getCompanyType().getDbValue())
        .items(items)
        .build();
}

private AiBootstrapPreviewResponse.BootstrapItem toCatalogItem(Norm norm) {
    return AiBootstrapPreviewResponse.BootstrapItem.builder()
        .itemType(norm.getItemType())
        .category("REGULATORIO")
        .criticality("MEDIA")
        .source("CATALOG")           // novo campo — ver passo 2
        .normId(norm.getId())        // novo campo — ver passo 2
        .maintenance(AiBootstrapPreviewResponse.MaintenancePreview.builder()
            .norm(norm.getAuthority())
            .periodUnit(norm.getPeriodUnit().name())
            .periodQty(norm.getPeriodQty())
            .toleranceDays(norm.getToleranceDays())
            .notes(norm.getNotes())
            .build())
        .build();
}
```

`category`/`criticality` são defaults simples, editáveis pelo usuário na tela antes de aplicar —
não existe fonte determinística pra esses dois campos hoje, não vale inventar heurística.

### 2. DTOs — novos campos

- `AiBootstrapPreviewResponse.BootstrapItem`: adicionar `source` (`String`, "CATALOG" ou "AI") e
  `normId` (`Long`, nullable — só preenchido pra itens de catálogo nesta task; a TASK-184 usa o
  mesmo campo pros itens de IA quando fizer match).
- Sem mudança em `AiBootstrapPreviewRequest` nesta task (isso é da TASK-184).

### 3. Controller — novo endpoint

```java
@PostMapping("/catalog-preview")
@RequireTenant
@Operation(summary = "Retorna itens do catálogo curado aplicáveis ao segmento, sem IA")
public ResponseEntity<AiBootstrapPreviewResponse> catalogPreview(@Validated @RequestBody AiBootstrapPreviewRequest request) {
    return ResponseEntity.ok(bootstrapService.previewFromCatalog(request));
}
```
Síncrono — responde 200 direto, sem `jobId`/polling (diferente de `/preview`, que continua
assíncrono). Mesmo `@RequireTenant` do endpoint existente.

## Critérios de Aceite

- [ ] `POST /ai/bootstrap/catalog-preview` responde na hora (sem job), com itens do segmento
      corretos
- [ ] Cada item tem `normId` preenchido e período vindo direto da `Norm` real (não inventado)
- [ ] `source = "CATALOG"` em todos os itens desta resposta
- [ ] Nenhuma chamada ao `AiProvider` acontece neste caminho (confirmar via teste/mock —
      zero custo de IA)
- [ ] Teste cobrindo os 6 segmentos (`CompanyType`)
- [ ] `mvn test` sem regressão

## Dependências
TASK-181 (precisa de `NormRepository.findBySegment()`).

## Riscos
Baixo — endpoint novo, aditivo, não altera o fluxo de IA existente.

## Esforço
Baixo-Médio

## Status
✅ Implementada e commitada (20/08/2026) na branch `feature/ai-onboarding-catalog-filter`
(`easy-maintenance-api`). 772 testes, 0 falhas. Ainda sem PR — mesma branch reúne toda a Fase 2.
