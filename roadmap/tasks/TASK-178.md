# TASK-178 — Backend: novo item de catálogo para instalação de gás combustível

## Tipo
BACKEND

## Categoria
Conteúdo Regulatório / Compliance

## Prioridade
🟡 Médio

## Épico
[EPIC-025](../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas

## QA obrigatório
Sim — teste manual: cadastrar um item de manutenção do novo `itemType`, confirmar que
`nextDueAt` calcula certo (12 meses a partir da última execução) e que a norma vinculada aparece
correta no detalhe do item.

---

## Contexto

O levantamento norma-a-norma (`docs/produto/levantamento-normas-abnt.md`, seção C-bis) encontrou um
gap real e totalmente especificado: instalação de gás combustível é um sistema predial comum em
condomínios (e também hospitais/indústrias) e **não existe nenhum item relacionado no catálogo
hoje** — nem em `item_types`, nem em `norms`. Diferente de outros gaps encontrados (NBR 5674,
NBR 14037, NBR 9050), esse tem periodicidade concreta e verificada, então dá pra virar item
completo, não só observação.

Base normativa (3 normas, papéis complementares):
- **NBR 13103** (2024) — requisitos do aparelho a gás, define a periodicidade: manutenção
  preventiva a cada **12 meses**, ou conforme fabricante (o que for mais curto).
- **NBR 15923** (2011, vigente) — procedimento de como inspecionar a rede/aparelho.
- **NBR 15526** (2026) — projeto e execução da rede/tubulação (referência complementar, não define
  a periodicidade do aparelho).

## Objetivo

Criar um novo `item_type` pra instalação/aparelho de gás combustível, com norma vinculada de
periodicidade 12 meses, seguindo o mesmo padrão dos itens já existentes (`AR_CONDICIONADO`,
`CAIXA_DAGUA`, etc.).

## Escopo

### 1. Novo `item_types` (migration)
Inserir novo tipo. Nome sugerido: `INSTALACAO_GAS` (a confirmar com Douglas antes de aplicar — é
decisão de nomenclatura, não técnica).

### 2. Novo `norms` (mesma migration)
```sql
INSERT INTO norms (item_type, period_unit, period_qty, tolerance_days, authority, doc_url, notes)
VALUES (
  'INSTALACAO_GAS', 'MESES', 12, 30,
  'ABNT NBR 13103 + ABNT NBR 15923 (procedimento) + ABNT NBR 15526 (rede, complementar)',
  'https://biblioteca.abnt.org.br/norma/abnt-nbr-13103-2024',
  'Manutenção preventiva do aparelho a gás a cada 12 meses, ou conforme fabricante (o que for mais
  curto). Verificar: limpeza do aparelho, estanqueidade da conexão com a rede, conexões de água/
  elétrica, sistema de exaustão, filtro, ventilação permanente, sistema de combustão.'
);
```
Nome de migration: próximo número livre em sequência com a TASK-177 (conferir qual delas roda
primeiro e ajustar numeração pra não colidir).

### 3. Frontend (se necessário)
Conferir se o formulário de cadastro de item consulta `item_types` dinamicamente (via
`ItemTypesController`) — se sim, o novo tipo aparece automaticamente, sem mudança de código
frontend. Confirmar isso antes de assumir que não precisa de trabalho de frontend.

## Critérios de Aceite

- [ ] Novo `item_type` de gás combustível existe e aparece na lista de tipos disponíveis pro
      usuário ao cadastrar item
- [ ] Norma vinculada calcula `nextDueAt` corretamente (12 meses)
- [ ] `authority`/`notes` citam as 3 normas com os papéis corretos (13103 = requisito/periodicidade,
      15923 = procedimento, 15526 = rede/complementar)
- [ ] Teste cobrindo criação de item do novo tipo e cálculo de `nextDueAt`
- [ ] `mvn test` sem regressão

## Dependências
Nenhuma técnica. Nomenclatura do `item_type` (`INSTALACAO_GAS` vs. outro nome) precisa de
confirmação rápida com Douglas antes de aplicar a migration (é o tipo de decisão que fica fixada
depois, difícil de renomear com dados em produção).

## Riscos
Baixo — item novo, aditivo, não toca em nenhum item existente.

## Esforço
Baixo-Médio

## Status
Pronto para implementar — nomenclatura do `item_type` a confirmar antes da migration.
