# TASK-088 — Compliance e Governança do Catálogo de Normas (norms)

## Tipo
FULL_STACK — Backend (migration + service) + Frontend (sinalização visual)

## Épico
EPIC-004 — Integridade de Dados

## Prioridade
🟠 Alto — risco de compliance antes do lançamento

## Contexto e Problema

A tabela `norms` é central para o produto: define periodicidades de manutenção vinculadas a normas ABNT, NR e CBMMG. Qualquer dado incorreto nela afeta diretamente os alertas de vencimento e a credibilidade de compliance do cliente.

Durante análise pré-lançamento foram identificados três problemas independentes:

---

### Problema 1 — V9 seed com `period_qty = 0` (15+ registros)

A migration `V9__seed_norms.sql` inseriu norms como "referências de requisito de projeto" sem periodicidade definida:

```sql
('NR10_TREINAMENTO',               'ANUAL', 0, 0, 'NR-10 (MTE)', ...)
('HIDRANTES_MANGOTINHOS_SISTEMA',  'ANUAL', 0, 0, 'CBMMG IT 17', ...)
('SPRINKLERS_SISTEMA',             'ANUAL', 0, 0, 'CBMMG IT',    ...)
-- + 12 outros com period_qty = 0
```

**Impacto**: `IAiBootstrapMapper.calculateNextDueAt()` faz `now.plusYears(0)` → `nextDueAt = hoje`. Todo item vinculado a essas norms nasce imediatamente como OVERDUE, gerando alertas incorretos e falsos positivos de compliance.

**Causa raiz**: Falta de distinção no schema entre "norm periódica" e "referência de projeto sem período fixo". O campo `period_qty = 0` não tem semântica clara.

---

### Problema 2 — `resolveNorm()` nunca usa o catálogo curado

Em `AiBootstrapService.resolveNorm()` (linha 163):

```java
// Filtra APENAS norms com authority = 'AI_BOOTSTRAP'
.filter(n -> n.getAuthority().equals("AI_BOOTSTRAP"))
```

**Impacto**: Quando a IA gera um item do tipo `EXTINTOR`, ela cria uma norm `AI_BOOTSTRAP` paralela — mesmo já existindo a norm curada ABNT NBR 12962 (V2). Resultado: duplicidade silenciosa; a norm que governa o item é a AI_BOOTSTRAP, não a curada.

---

### Problema 3 — Norms geradas por IA entram no banco sem validação

O fluxo atual:

```
IA gera norm (periodicity + referência normativa) → salva direto no banco → authority = 'AI_BOOTSTRAP' → sem doc_url → sem revisão
```

Exemplo real detectado em beta:
```
CENTRAL_OXIGENIO | MESES | 1 | AI_BOOTSTRAP | "Referências: NBR 12188"
```
NBR 12188 é sobre cilindros transportáveis de gás industrial — não sobre central de oxigênio hospitalar. A IA escolheu a norma mais próxima que conhecia, foi plausível mas tecnicamente incorreta, e foi salva como verdade de compliance.

**Não existe nenhuma barreira entre a sugestão da IA e o dado persitido.**

---

## Solução — Três Passos

### Passo A — Curated-first no `resolveNorm()` (backend, sem migration)

Alterar `AiBootstrapService.resolveNorm()` para buscar primeiro por `itemType` **sem filtrar por authority**. Se existe norm curada → reutiliza. Só cria `AI_BOOTSTRAP` se não houver nenhuma norm curada para aquele tipo.

```java
// Antes: só busca AI_BOOTSTRAP
.filter(n -> n.getAuthority().equals("AI_BOOTSTRAP"))

// Depois: tenta curada primeiro
Optional<Norm> curated = existingNorms.stream()
    .filter(n -> !n.getAuthority().equals("AI_BOOTSTRAP"))
    .findFirst();
if (curated.isPresent()) return curated.get().getId();

// Só então: verifica ou cria AI_BOOTSTRAP
```

### Passo B — Campo `source` + `pendingReview` na entidade Norm (migration + frontend)

Adicionar via migration:
```sql
ALTER TABLE norms ADD COLUMN source VARCHAR(30) NOT NULL DEFAULT 'CURATED';
ALTER TABLE norms ADD COLUMN pending_review BOOLEAN NOT NULL DEFAULT FALSE;

-- Marcar as existentes AI_BOOTSTRAP como pendentes
UPDATE norms SET source = 'AI_GENERATED', pending_review = TRUE
WHERE authority = 'AI_BOOTSTRAP';
```

No `IAiBootstrapMapper.toNorm()`: setar `source = AI_GENERATED`, `pendingReview = true`.

No frontend (detalhe do item e tela de normas): exibir badge "⚠️ Norma gerada por IA — não validada" quando `pendingReview = true`.

### Passo C — Corrigir V9 norms com `period_qty = 0` (migration)

Migration `V12__fix_norms_period_qty.sql` com os valores corretos baseados nas normas reais:

| item_type | Correção |
|---|---|
| NR10_TREINAMENTO | 2 anos (NR-10 item 10.8) |
| NR13_CALDEIRAS_INSPECAO | 1 ano (NR-13, dependente do PIS/PIE) |
| NR35_TREINAMENTO | 2 anos (NR-35 item 35.4) |
| NR23_PROTECAO_INCENDIO | 1 ano (inspeção anual padrão) |
| SPRINKLERS_SISTEMA | 1 ano (CBMMG IT) |
| ALARME_INCENDIO_SISTEMA | 1 ano (CBMMG IT) |
| HIDRANTES_MANGOTINHOS_SISTEMA | 1 ano (CBMMG IT 17) |
| HIDRANTES_MANGUEIRAS_INSPECAO | 1 ano (CBMMG IT 17) |
| BOMBAS_INCENDIO_SISTEMA | 1 ano (CBMMG IT 17) |
| EXTINTORES_SISTEMA_PROTECAO | 1 ano (CBMMG IT 16) |
| SAIDAS_EMERGENCIA_ROTAS | 1 ano |
| SINALIZACAO_EMERGENCIA | 1 ano |
| PORTAS_CORTA_FOGO | 1 ano |
| ILUMINACAO_EMERGENCIA_SISTEMA | 1 ano (fabricante / CBMMG IT 13) |
| ILUMINACAO_EMERGENCIA_BATERIAS | 1 ano (fabricante) |

Itens que genuinamente não têm periodicidade definida em norma: `period_qty = NULL` (tratar no scheduler como "não agendar automaticamente") ao invés de `0`.

---

## Limpeza de dados AI_BOOTSTRAP existentes (beta)

Como ainda estamos em beta, incluir na migration uma limpeza cirúrgica das norms `AI_BOOTSTRAP` cujos `itemType` já têm curadoria no catálogo (V2/V9). Itens afetados serão reassociados à norm curada correspondente.

---

## Arquivos Impactados

**Backend:**
- `AiBootstrapService.java` — método `resolveNorm()`
- `IAiBootstrapMapper.java` — método `toNorm()` (adicionar source + pendingReview)
- `Norm.java` — novos campos `source`, `pendingReview`
- `NormDTO.java` — expor `source`, `pendingReview` na API
- `V12__fix_norms_period_qty.sql` — migration de correção
- `V13__norm_source_pending_review.sql` — migration de schema

**Frontend:**
- Detalhe do item regulatório — badge de aviso quando `pendingReview = true`
- Tela de listagem de normas (se existir) — coluna de status

---

## Critérios de Aceite

- [ ] `resolveNorm()` reutiliza norm curada quando existe, nunca cria duplicata AI_BOOTSTRAP para tipos já catalogados
- [ ] Novas norms AI_BOOTSTRAP nascem com `source = AI_GENERATED` e `pendingReview = true`
- [ ] Nenhuma norm V9 com `period_qty = 0` — todas com valor correto ou `NULL` semântico
- [ ] Frontend sinaliza visualmente normas pendentes de revisão
- [ ] Norms curadas V2 permanecem intactas e sem alteração
- [ ] Testes: `resolveNorm()` com itemType curado → retorna norm curada; com itemType novo → cria AI_BOOTSTRAP

## Riscos

- **Migration V12**: atualizar `period_qty` em norms já vinculadas a items recalcula `nextDueAt` nos items afetados — validar impacto antes de rodar em produção
- **Limpeza beta**: reassociar items de norms AI_BOOTSTRAP para curadas deve ser feito com `UPDATE maintenance_items SET norm_id = ? WHERE norm_id = ?` — jamais delete sem reassociar primeiro
