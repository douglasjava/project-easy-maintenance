# TASK-184 — Backend: IA como complemento — evita repetir itens do catálogo e aceita `normId` explícito em `apply()`

## Tipo
BACKEND

## Categoria
Onboarding por IA / Redução de custo

## Prioridade
🟡 Médio

## Épico
[EPIC-025](../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas

## QA obrigatório
Sim — QA manual: gerar preview com descrição livre contendo um item já coberto pelo catálogo (ex.:
"tenho extintores e piscina" quando extintor já veio do filtro) e confirmar que a IA não o repete.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-20-onboarding-catalog-filter-design.md`.

Depende da TASK-182 (conceito de itens já cobertos pelo catálogo só existe depois de
`catalog-preview` retornar algo). Com o filtro determinístico cobrindo o catálogo curado
(TASK-182), a chamada de IA (`POST /ai/bootstrap/preview`, mantida assíncrona) passa a ser só
complemento pro que o texto livre do usuário descreve além do catálogo — e não deveria gastar
tokens gerando norma/período pra item que já vai ser descartado por duplicidade.

## Objetivo

Fazer a IA saber o que já foi coberto (evitando repetição/gasto à toa) e tornar `apply()` robusto
o suficiente pra aceitar `normId` já resolvido, sem depender só do match por string.

## Escopo

### 1. `AiBootstrapPreviewRequest` — novo campo

```java
private List<String> alreadyCoveredItemTypes; // opcional
```

### 2. Prompt — instrução anexada em código

Em `AiBootstrapService.preview()`, antes de montar o `userPrompt` final (mesmo padrão de
`appendOutputContract()`, que já anexa instrução dinamicamente em vez de editar o template salvo no
banco):

```java
if (request.getAlreadyCoveredItemTypes() != null && !request.getAlreadyCoveredItemTypes().isEmpty()) {
    userPrompt += "\n\nNão sugira novamente os seguintes itens, já cobertos: "
        + String.join(", ", request.getAlreadyCoveredItemTypes()) + ".";
}
```
Funciona pra qualquer `company_type` sem precisar de migration nova por template.

### 3. Rede de segurança determinística (não confiar só na instrução do prompt)

LLM pode ignorar a instrução. Depois de receber a resposta da IA em `preview()`, antes de devolver
pro caller, filtrar fora qualquer item cujo `itemType` normalizado (mesma função
`NormalizerUtil.normalize()` já usada em `ensureItemType()`) já esteja em
`alreadyCoveredItemTypes` (também normalizado pra comparação justa):

```java
if (request.getAlreadyCoveredItemTypes() != null) {
    Set<String> covered = request.getAlreadyCoveredItemTypes().stream()
        .map(NormalizerUtil::normalize)
        .collect(Collectors.toSet());
    response.setItems(response.getItems().stream()
        .filter(it -> !covered.contains(NormalizerUtil.normalize(it.getItemType())))
        .toList());
}
```

### 4. `source = "AI"` na resposta

Itens gerados por este caminho (preview assíncrono) recebem `source = "AI"` no `BootstrapItem`
(campo já adicionado na TASK-182).

### 5. `apply()` — aceitar `normId` explícito

`AiBootstrapApplyRequest.BootstrapApplyItem` ganha campo opcional `normId`. Em
`AiBootstrapService.processItem()`:

```java
Long normId;
ItemCategory itemCategory;

if (item.getNormId() != null) {
    // Item veio do catálogo (TASK-182) — normId já resolvido, sem match por string
    normId = item.getNormId();
    itemCategory = ItemCategory.REGULATORY;
} else {
    // Fallback existente — match curated-first por itemType (itens vindos só da IA)
    Optional<Norm> curatedNorm = normRepository.findByItemType(item.getItemType()).stream()
        .filter(n -> !"AI_BOOTSTRAP".equals(n.getAuthority()))
        .findFirst();
    normId = curatedNorm.map(Norm::getId).orElse(null);
    itemCategory = curatedNorm.isPresent() ? ItemCategory.REGULATORY : ItemCategory.OPERATIONAL;
}
```
O fallback por string continua existindo (itens só de IA ainda passam por ele), mas fica mais raro
de disparar — o catálogo já cobriu o determinístico e a IA foi instruída (+ filtrada) a não repetir.

## Critérios de Aceite

- [ ] Prompt da IA inclui a lista de itens já cobertos quando fornecida
- [ ] Item da IA cujo `itemType` bate (normalizado) com algo em `alreadyCoveredItemTypes` é
      removido da resposta antes de chegar ao frontend, mesmo que a IA tenha ignorado a instrução
- [ ] Itens do caminho `/preview` (IA) têm `source = "AI"`
- [ ] `apply()` com `normId` explícito no payload usa ele direto, sem chamar
      `normRepository.findByItemType()`
- [ ] `apply()` sem `normId` mantém o comportamento atual (match por string, fallback)
- [ ] Teste cobrindo: IA sugere item duplicado do catálogo apesar da instrução → item é removido no
      backend antes da resposta
- [ ] `mvn test` sem regressão

## Dependências
TASK-182 (conceitualmente — o campo `alreadyCoveredItemTypes` só é útil depois que o frontend tem o
que passar nele, mas o código desta task pode ser implementado e testado de forma independente).

## Riscos
Baixo-Médio — toca `processItem()`, caminho já sensível (criação de item de cliente novo). Mitigado
por manter o fallback existente intacto pra itens sem `normId`.

## Esforço
Médio

## Status
✅ Implementada e commitada (20/08/2026) na branch `feature/ai-onboarding-catalog-filter`
(`easy-maintenance-api`). 775 testes, 0 falhas. PR
[#40](https://github.com/douglasjava/easy-maintenance-api/pull/40) aberta em 21/08/2026 (mesma
branch reúne toda a Fase 2).
