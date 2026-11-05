# TASK-181 — Backend: tabela `norm_segments` + filtro por segmento no `NormRepository`

## Tipo
BACKEND

## Categoria
Onboarding por IA / Catálogo de Normas

## Prioridade
🟠 Alto

## Épico
[EPIC-025](../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas

## QA obrigatório
Não precisa QA manual — é camada de dado + query, coberta por teste automatizado. Validar com
query direta no banco pós-migration que a contagem de linhas por segmento bate com a classificação
esperada.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-20-onboarding-catalog-filter-design.md`.

O fluxo de onboarding assistido por IA (`/ai-onboarding`) hoje gera todo item do zero via IA, sem
saber quais normas já existem curadas no catálogo (`norms`), e sem saber a que segmento de empresa
cada norma se aplica — a tabela `norms` não tem nenhuma coluna/relação de segmento hoje. Esta task
cria essa peça de dado que faltava, base para o filtro determinístico da TASK-182.

**Achado importante da fase de brainstorm**: extintor (e outras normas) não são exclusivas de um
segmento — precisa ser relação N-pra-N, não uma coluna simples 1-pra-1 na tabela `norms`.

## Objetivo

Criar `norm_segments` (junção N-pra-N entre `norms` e segmento de empresa) e popular todas as ~30
normas já catalogadas, a partir da classificação já feita em
`docs/produto/levantamento-normas-abnt.md` (EPIC-025) — é transcrição de trabalho já pronto, não
pesquisa nova.

## Escopo

### 1. Migration (próximo número livre em `db/migration/`)

```sql
CREATE TABLE norm_segments (
    id           BIGINT PRIMARY KEY AUTO_INCREMENT,
    norm_id      BIGINT NOT NULL,
    company_type VARCHAR(20) NOT NULL,
    CONSTRAINT fk_norm_segments_norm FOREIGN KEY (norm_id) REFERENCES norms(id),
    UNIQUE KEY ux_norm_segments (norm_id, company_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

`company_type` usa exatamente os mesmos valores de `organizations.company_type` (os `dbValue` do
enum `CompanyType`: `CONDOMINIO`, `HOSPITAL`, `ESCOLA`, `INDUSTRIA`, `ESCRITORIO`, `OUTROS`) — não
criar um vocabulário novo.

Popular via `INSERT ... SELECT id, '<segmento>' FROM norms WHERE item_type = '<item_type>'` (uma
linha por combinação norma×segmento), cobrindo os padrões já documentados na spec:
- Universais (todos os 6 segmentos): EXTINTOR, SPDA (`SPDA_INSPECAO_VISUAL`/`SPDA_INSPECAO_COMPLETA`/
  `ATERRAMENTO_MEDICAO_RESISTENCIA`/`EQUIPOTENCIALIZACAO_VERIFICACAO`), ILUMINACAO_EMERGENCIA,
  hidrantes/mangueiras/mangotinhos, NBR 9077 (se já estiver como item de catálogo — confirmar contra
  o estado real do banco antes de escrever o INSERT, mesmo cuidado já registrado na TASK-177).
- Só HOSPITAL: itens relacionados a RDC 50/RDC 15 se existirem como item de catálogo (confirmar
  estado real — pelo levantamento, hospital não tem item funcional hoje; se não houver linha em
  `norms` pra isso, não há o que popular em `norm_segments` — não inventar linha nova aqui, essa
  task é só relacionar o que já existe).
- Só INDUSTRIA: NR-12 (se item de catálogo existir), NR-13/23/35 (confirmar se algum já existe como
  universal vs. específico — NR-23 por exemplo é "proteção contra incêndio trabalhista", pode ser
  universal a ambientes de trabalho, não só indústria — decidir com base no que a norma realmente
  cobre, documentado na análise de cada NR em `levantamento-normas-abnt.md`).
- Presente em vários, não todos: `INSTALACAO_GAS` (TASK-178, CONDOMINIO + ESCRITORIO, não INDUSTRIA
  pesada nem HOSPITAL), `CAIXA_DAGUA` (CONDOMINIO + ESCOLA + ESCRITORIO — vigilância sanitária,
  universal-ish mas não HOSPITAL/INDUSTRIA por não ser o padrão de uso ali).

**Antes de escrever os `INSERT`s definitivos**: rodar um select no `item_type` real de todas as
linhas de `norms` em produção (mesmo cuidado da TASK-177/178 — não confiar de memória no que o
levantamento documentou, conferir contra o banco real) e classificar cada uma.

### 2. Entidade `NormSegment` (nova, plana)

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
Sem relacionamento JPA com `Norm` (mantém `Norm` plana, sem lazy-loading) — mesmo estilo
minimalista já usado no módulo `catalog_norms`.

### 3. `NormRepository` — novo método

```java
@Query("SELECT n FROM Norm n JOIN NormSegment ns ON ns.normId = n.id WHERE ns.companyType = :companyType")
List<Norm> findBySegment(@Param("companyType") String companyType);
```
Uma query só (JOIN), sem N+1 — mesma análise de performance já validada na fase de brainstorm desta
task (tabela pequena, ~30-90 linhas totais).

## Critérios de Aceite

- [ ] `norm_segments` criada, populada, sem duplicata (`UNIQUE KEY` garante isso)
- [ ] `NormSegment` entity mapeada corretamente
- [ ] `NormRepository.findBySegment("CONDOMINIO")` retorna as normas certas (teste automatizado
      cobrindo pelo menos 1 segmento universal + 1 específico)
- [ ] Nenhuma norma universal ficou de fora de nenhum dos 6 segmentos
- [ ] `mvn test` sem regressão

## Dependências
Nenhuma técnica. Precede TASK-182 (usa `findBySegment`).

## Riscos
Baixo — tabela nova, aditiva, não altera `norms` nem `maintenance_items`.

## Esforço
Baixo-Médio (o trabalho real é classificar cada norma, não a estrutura em si)

## Status
✅ Implementada e commitada (20/08/2026) na branch `feature/ai-onboarding-catalog-filter`
(`easy-maintenance-api`). PR [#40](https://github.com/douglasjava/easy-maintenance-api/pull/40)
aberta em 21/08/2026 (mesma branch reúne toda a Fase 2 do backend).
