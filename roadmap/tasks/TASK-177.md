# TASK-177 — Backend: corrigir/completar citações de normas no catálogo (`norms`)

## Tipo
BACKEND

## Categoria
Conteúdo Regulatório / Compliance

## Prioridade
🟠 Alto

## Épico
[EPIC-025](../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas

## QA obrigatório
Não precisa QA manual de fluxo — é migration de dados. Validar com query direta no banco pós-
migration + revisão do texto das `notes`/`authority` por alguém (Douglas) antes de aplicar em
produção, já que é conteúdo com implicação de compliance.

---

## Contexto

Levantamento norma-a-norma (`docs/produto/levantamento-normas-abnt.md`, root repo) encontrou
citações incompletas em linhas específicas do catálogo `norms`. **Importante**: antes de escrever
esta task, o estado real das migrations (`V2__seed_norms.sql`, `V9__seed_norms.sql`,
`V78__fix_spda_period_and_dedupe_norms.sql`) foi conferido diretamente — duas suposições do
levantamento inicial estavam erradas e **não** viram correção aqui:
- `ALARME_DE_INCENDIO` já cita `ABNT NBR 17240` corretamente (V2), sobrevivente do dedupe da V78.
  `BOTOEIRA_DE_INCENDIO` também já cita `ABNT NBR 17240`. Nenhuma ação necessária nesses dois.
- `AR_CONDICIONADO` nunca citou "NBR 11742" — isso era do item `PORTA_CORTA_FOGO` (citação correta,
  fora do escopo desta task). `AR_CONDICIONADO` cita hoje `ANVISA RE 09 / Qualidade do Ar Interno`
  — correto mas **incompleto**, é o que esta task corrige.

## Objetivo

Atualizar `authority`/`doc_url`/`notes` das linhas abaixo em `norms`, via migration nova
(`V79__fix_norm_citations.sql` ou próximo número livre — conferir o mais recente antes de nomear).

## Escopo — linhas a corrigir

### 1. `AR_CONDICIONADO`
Hoje: `authority = 'ANVISA RE 09 / Qualidade do Ar Interno'`.
Corrigir para citar a base legal completa confirmada em
`docs/produto/levantamento-normas-abnt.md` (seção "Lei 13.589/2018 + Portaria GM/MS 3.523/1998 +
ANVISA RE 9/2003"):
```
authority = 'Lei 13.589/2018 + Portaria GM/MS 3.523/1998 + ANVISA RE 9/2003'
notes = 'PMOC obrigatório para sistemas ≥60.000 BTU/h em áreas de uso público/coletivo (ex.: áreas
comuns do condomínio — portaria, salão de festas). Não se aplica a ar-condicionado individual de
unidade privativa. Periodicidade de limpeza de filtros definida pelo responsável técnico/
fabricante, sem prazo fixo universal na lei.'
```

### 2. `CAIXA_DAGUA`
Hoje: `authority = 'Vigilância Sanitária'`, sem menção a segurança do trabalho.
Adicionar referência complementar à NR-33 (achado do levantamento: a limpeza do reservatório vazio
é, ela mesma, trabalho em espaço confinado):
```
notes = notes atual + ' Atenção: a limpeza do reservatório vazio caracteriza espaço confinado
(NR-33) — exigir capacitação do prestador de serviço conforme a norma.'
```
Não alterar `authority` (continua Vigilância Sanitária, que é a base do item em si) — só enriquecer
`notes`.

### 3. `SAIDAS_EMERGENCIA_ROTAS` e `SINALIZACAO_EMERGENCIA`
Hoje: ambos citam só `'CBMMG IT'` (regional, MG-específico — Achado #2 do levantamento).
Adicionar a base nacional como primária, mantendo o IT estadual como complemento:
```
authority = 'ABNT NBR 9077 + CBMMG IT (complemento regional)'
```
**Coordenar com TASK-088** antes de aplicar: essas duas linhas também estão no escopo da correção
de `period_qty = 0` da TASK-088 (mesma migration ou migrations sequenciais, não conflitantes — não
sobrescrever o trabalho um do outro). Se a TASK-088 já tiver rodado quando esta for implementada,
aplicar só o `UPDATE` de `authority`, preservando o `period_qty` já corrigido.

### 4. `HIDRANTES_MANGOTINHOS_SISTEMA` e `BOMBAS_INCENDIO_SISTEMA`
Mesmo padrão do item 3 — hoje citam só `'CBMMG IT 17'`. A base nacional é `ABNT NBR 13714`
(hidrantes/mangotinhos, já citada corretamente no item `HIDRANTE` do V2):
```
authority = 'ABNT NBR 13714 + CBMMG IT 17 (complemento regional)'
```
Mesma coordenação com TASK-088 que o item 3.

## Critérios de Aceite

- [ ] `AR_CONDICIONADO.authority` reflete a base legal completa (Lei 13.589 + Portaria GM/MS 3.523 +
      ANVISA RE 9/2003)
- [ ] `CAIXA_DAGUA.notes` menciona NR-33 pra atividade de limpeza do reservatório vazio
- [ ] `SAIDAS_EMERGENCIA_ROTAS` e `SINALIZACAO_EMERGENCIA` citam NBR 9077 como base nacional
- [ ] `HIDRANTES_MANGOTINHOS_SISTEMA` e `BOMBAS_INCENDIO_SISTEMA` citam NBR 13714 como base nacional
- [ ] Nenhuma linha teve `period_qty`/`period_unit`/`tolerance_days` alterado por esta migration —
      escopo é só citação/texto
- [ ] `ALARME_DE_INCENDIO`, `BOTOEIRA_DE_INCENDIO` e `PORTA_CORTA_FOGO` **não tocados** (já corretos)
- [ ] Migration idempotente (roda seguro mesmo se já aplicada — usar `WHERE authority = '<valor
      antigo>'` como guarda, mesmo padrão da V78)
- [ ] `mvn test` sem regressão

## Dependências
Coordenar com `TASK-088` (EPIC-004) nas linhas `SAIDAS_EMERGENCIA_ROTAS`, `SINALIZACAO_EMERGENCIA`,
`HIDRANTES_MANGOTINHOS_SISTEMA`, `BOMBAS_INCENDIO_SISTEMA` — mesmas linhas, migrations diferentes,
sequenciar pra não colidir.

## Riscos
Baixo — é migration de conteúdo textual, não altera `period_qty`/cálculo de `nextDueAt`. Risco real
é só de coordenação de migration com a TASK-088 nas 4 linhas compartilhadas.

## Esforço
Baixo

## Status
Pronto para implementar.
