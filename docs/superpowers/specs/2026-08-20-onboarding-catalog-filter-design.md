# Filtro Determinístico de Catálogo no Onboarding por IA — Design

**Data**: 20/08/2026
**Status**: Aprovado por Douglas, pronto para plano de implementação.

## Motivação

Aproveitando o levantamento de normas do EPIC-025 (`docs/produto/levantamento-normas-abnt.md`),
avaliamos o fluxo de onboarding assistido por IA (`/ai-onboarding`, `AiBootstrapService`) — a tela
onde o usuário escolhe o tipo de empresa e opcionalmente descreve a estrutura, e a IA sugere itens
de manutenção pra cadastro em lote. Três problemas foram identificados:

1. **Custo evitável**: a IA gera *todo* item do zero (tipo, norma, periodicidade, criticidade) sem
   saber quais normas já existem curadas no catálogo (`norms` table) — mesmo quando o resultado
   final é descartado porque bate com uma norma já cadastrada.
2. **Cobertura perdida por match frágil**: `apply()` casa o `itemType` que a IA escreveu contra
   `norms.item_type` por **igualdade exata de string**. Divergência de nome (espaço vs. underscore,
   sinônimo) faz o item cair como `OPERATIONAL` sem norma, mesmo quando uma norma curada aplicável
   existe.
3. **Bug de dado**: quando o match acontece e o item vira `REGULATORY`, o `nextDueAt` gravado é
   calculado a partir do período que **a IA inventou no JSON**, não do período real da norma curada
   vinculada (`IAiBootstrapMapper.calculateNextDueAt()`). Diverge do fluxo manual de criação de
   item, que sempre usa `ServiceBase.resolvePeriod()` — busca o período real da `Norm` vinculada
   quando `itemCategory == REGULATORY`. Um item pode nascer citando "ABNT NBR 5419" corretamente mas
   com data de vencimento errada, até a primeira manutenção ser registrada (que recalcula certo).

## Objetivo

Fazer o catálogo de normas já curado (`norms`) responder sozinho, sem IA, pela maior parte do
checklist esperado por segmento de empresa — reduzindo custo de IA e eliminando o bug — e manter a
IA só como complemento opcional para o que o texto livre do usuário descreve além do catálogo.

## Fora de escopo

- Qualquer mudança na tela obrigatória de cadastro `/onboarding` (2 passos, cobrança + organização)
  — ela não chama IA hoje e continua não chamando.
- Mudança na lógica de créditos de IA (`AiCreditService`) — o efeito desejado (menos chamadas de IA
  quando não há descrição) já reduz consumo por consequência do desenho, sem precisar mexer na
  regra de dedução em si.
- Regionalização de normas (achados #2/#3 do EPIC-025, Corpo de Bombeiros por estado) — o filtro por
  segmento não resolve isso, fica como já registrado no EPIC-025.

---

## Modelo de dados

Nova tabela `norm_segments`, relação N-pra-N entre `norms` e o segmento de empresa (`company_type`):

```sql
CREATE TABLE norm_segments (
    id           BIGINT PRIMARY KEY AUTO_INCREMENT,
    norm_id      BIGINT NOT NULL,
    company_type VARCHAR(20) NOT NULL,
    CONSTRAINT fk_norm_segments_norm FOREIGN KEY (norm_id) REFERENCES norms(id),
    UNIQUE KEY ux_norm_segments (norm_id, company_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

`company_type` reaproveita exatamente os valores já usados em `organizations.company_type` (os
`dbValue` do enum `CompanyType`: `CONDOMINIO`, `HOSPITAL`, `ESCOLA`, `INDUSTRIA`, `ESCRITORIO`,
`OUTROS`) — mesmo vocabulário, sem risco de divergência entre as duas tabelas.

Uma norma pode ter de 1 a N linhas (uma por segmento aplicável). Classificação a transcrever do
`docs/produto/levantamento-normas-abnt.md` (trabalho já feito no EPIC-025, não pesquisa nova):

| Padrão | Exemplos | Segmentos |
|---|---|---|
| Universal | EXTINTOR, SPDA, ILUMINACAO_EMERGENCIA, hidrantes, NBR 9077 | Todos (5 linhas cada) |
| Específico de 1 segmento | gases medicinais/vácuo/vapor (RDC 50), autoclave (RDC 15) | Só HOSPITAL |
| Específico de 1 segmento | NR-12 (máquinas industriais) | Só INDUSTRIA |
| Presente em vários, não todos | gás combustível (NBR 13103/15923) | CONDOMINIO, ESCRITORIO — não INDUSTRIA pesada |
| Presente em vários, não todos | NR-33 (espaço confinado) | CONDOMINIO (caixa d'água), INDUSTRIA — não ESCOLA |

Migration única (`V91__create_norm_segments.sql`), popula as ~30 normas de uma vez.

---

## Backend

### 1. Filtro determinístico (novo, síncrono, sem IA)

**Entidade** `NormSegment` (nova, plana — mesmo estilo minimalista de `Norm`, sem relacionamento
JPA em `Norm` pra não introduzir lazy-loading):

```java
@Entity
@Table(name = "norm_segments")
public class NormSegment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "norm_id") private Long normId;
    @Column(name = "company_type") private String companyType;
}
```

**`NormRepository`** ganha:
```java
@Query("SELECT n FROM Norm n JOIN NormSegment ns ON ns.normId = n.id WHERE ns.companyType = :companyType")
List<Norm> findBySegment(@Param("companyType") String companyType);
```
Uma query só — sem N+1 (mesma análise já feita e validada com Douglas: N+1 só ocorreria com loop de
queries por registro, não com JOIN).

**`AiBootstrapService.previewFromCatalog(AiBootstrapPreviewRequest request)`** (novo método):
busca `normService.findBySegment(companyType)` e monta a resposta no mesmo formato de
`AiBootstrapPreviewResponse`, mas:
- `source = "CATALOG"` em cada item.
- `normId` já resolvido diretamente da norma (não precisa de match por string depois).
- `maintenance.periodQty/periodUnit/toleranceDays/notes/norm` vêm direto da `Norm` real — nunca
  inventados.
- Defaults simples e editáveis pelo usuário na tela: `category = "REGULATORIO"`,
  `criticality = "MEDIA"`.
- **Sem chamada de IA, sem job, sem dedução de crédito.**

**Novo endpoint** `POST /ai/bootstrap/catalog-preview` — síncrono, responde 200 na hora com a lista
(sem `jobId`, sem polling). Mesmo `@RequireTenant` do endpoint de preview atual.

### 2. IA (mantém assíncrona, muda quando é chamada e o que recebe)

- Frontend só aciona `POST /ai/bootstrap/preview` (job assíncrono, como hoje) quando há descrição
  livre preenchida — ver seção de frontend.
- `AiBootstrapPreviewRequest` ganha campo opcional `alreadyCoveredItemTypes: List<String>` — a lista
  de `itemType` que o filtro do catálogo já trouxe.
- A instrução "não repita estes itens: {lista}" é anexada em código (mesmo padrão já usado por
  `appendOutputContract()` em `AiBootstrapService`), não editada nos templates salvos no banco —
  funciona pra qualquer `company_type` sem precisar de migration nova por template.
- Itens gerados pela IA ganham `source = "AI"` na resposta.
- **Rede de segurança determinística**: a instrução no prompt não é garantia — LLM pode ignorá-la.
  Antes de devolver a resposta do job pro frontend, `preview()` filtra fora qualquer item cujo
  `itemType` (normalizado, mesma função `NormalizerUtil.normalize()` já usada em
  `AiBootstrapService.ensureItemType()`) já esteja em `alreadyCoveredItemTypes` — dedupe feito em
  código, não confiado só à obediência do modelo.

### 3. `apply()` — corrige o bug e fica mais robusto

- `AiBootstrapApplyRequest.BootstrapApplyItem` ganha campo opcional `normId`. Itens do catálogo
  devolvem esse campo preenchido (echo do que receberam no preview) — `processItem()` usa direto,
  sem re-match por string, zero risco de divergência de nome. Itens da IA (sem `normId` no payload)
  continuam pelo match curated-first por string já existente, como fallback — agora bem mais raro de
  disparar, já que o catálogo cobre o determinístico e a IA foi instruída a não repetir.
- **Fix do bug**: em `processItem()`, quando `itemCategory == REGULATORY` (por qualquer um dos dois
  caminhos), `nextDueAt` deixa de ser calculado a partir do período que veio no JSON — passa a usar
  `serviceBase.resolvePeriod(maintenanceItem)` (mesmo helper do fluxo manual de criação de item),
  com `LocalDate.now()` como base (item ainda não executado, mesma convenção de
  `MaintenanceItemService.create()`).
- `customPeriodUnit`/`customPeriodQty` passam a ser gravados como `null` quando `itemCategory ==
  REGULATORY` — replicando exatamente o que `IMaintenanceItemMapper` já faz no fluxo manual
  (`request.itemCategory().isOperational() ? request.customPeriodUnit() : null`), eliminando o dado
  morto/enganoso que ficava salvo hoje.

---

## Frontend (`easy-maintenance-web/src/app/ai-onboarding/page.tsx`)

**Etapa 1**: sem mudança nos campos (tipo de empresa + descrição opcional).

**`handleGenerate()` reescrito:**

1. Chama `POST /ai/bootstrap/catalog-preview` (síncrono). Itens voltam com `source: "CATALOG"` e
   `normId` resolvido.
2. Renderiza a Etapa 2 imediatamente com esses itens.
3. **Se a descrição estiver preenchida**: dispara em paralelo o job assíncrono de sempre
   (`POST /ai/bootstrap/preview` + polling via `pollAiJob`), passando `alreadyCoveredItemTypes` =
   os `itemType` do catálogo. Indicador discreto no topo da tabela ("🔄 Buscando sugestões
   adicionais com IA..."). Quando o polling termina, os itens retornados (`source: "AI"`) são
   **anexados** à tabela já renderizada — sem resetar seleções/edições que o usuário já tenha feito
   nas linhas do catálogo.
4. **Se a descrição estiver vazia**: pula o job inteiro — Etapa 2 abre só com o catálogo, sem
   espera perceptível.

**Tratamento de erro revisado**: falha do job de IA vira aviso não-bloqueante (toast leve — "A IA
não conseguiu complementar as sugestões, mas os itens do catálogo continuam disponíveis"), em vez
de bloquear a tela inteira como hoje (`if (!data.usedAi) toast.error(...)` presumia que todo
resultado dependia da IA).

**Tabela (Etapa 2)**: nova coluna/badge "Origem" por linha — "✅ Catálogo" vs "✨ IA" (mesmo estilo
visual do badge que já existe hoje no cabeçalho da etapa). Edição, remoção, seleção e modal de
edição continuam funcionando exatamente como hoje, linha a linha, independente da origem.

**`handleApply()`**: o payload de cada item passa a incluir `normId` (quando presente) e `source`.

**Tipos** (`src/types/ai-onboarding.ts`): `AiItemPreview` ganha `source: "CATALOG" | "AI"` e
`normId?: number`.

---

## Testes

- Backend: `AiBootstrapService.previewFromCatalog()` retorna itens corretos por segmento (incluindo
  caso de norma universal aparecendo em múltiplos segmentos); `apply()` com `normId` explícito não
  faz match por string; `apply()` sem `normId` mantém o fallback curated-first; fix do bug —
  `nextDueAt` de item REGULATORY bate com `serviceBase.resolvePeriod()`, não com o período do JSON
  recebido; `customPeriodQty/Unit` nulos para REGULATORY; dedupe determinístico remove item da IA
  cujo `itemType` normalizado já estava em `alreadyCoveredItemTypes`, mesmo que o prompt tenha sido
  ignorado.
- Frontend: fluxo sem descrição não dispara polling; fluxo com descrição mescla itens da IA sem
  perder seleção prévia; erro de IA não bloqueia a tela quando há itens de catálogo.

## Riscos

Baixo-Médio. Maior superfície de mudança está em `AiBootstrapService`/`apply()` (código que já
existe e é sensível — mexe em criação de item de cliente novo). Mitigado por: fix do bug converge
pro mesmo caminho já testado do fluxo manual (`ServiceBase.resolvePeriod()`), não introduz lógica
nova de cálculo. Tabela `norm_segments` é aditiva, sem risco de regressão em dado existente.
