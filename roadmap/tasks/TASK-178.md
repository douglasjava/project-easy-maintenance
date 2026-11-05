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

**Correção de entendimento (19/08/2026, antes de implementar)**: `item_types` **não** é a tabela
certa aqui — é um catálogo de autocomplete de texto livre (nomes com espaço, ex.: "INSTALACAO DE AR
CONDICIONADO"), cresce organicamente via `POST /item-types` quando o usuário digita um tipo novo no
formulário, e não tem relação direta com a chave usada pelas normas. O dropdown "Norma" do
formulário de item (`items/new/page.tsx`) busca `GET /norms` **dinamicamente** e renderiza
`n.itemType` como label — basta a linha existir em `norms` pra aparecer no dropdown, sem qualquer
mudança de frontend ou de `item_types`. Nome confirmado com Douglas: `INSTALACAO_GAS`.

### 1. Novo `norms` (migration)
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
### 2. Frontend
Nenhuma mudança necessária — confirmado que o dropdown já é dinâmico (`GET /norms`).

## Critérios de Aceite

- [x] Nova norma `INSTALACAO_GAS` existe e aparece no dropdown de normas ao cadastrar item
      REGULATORY (dropdown já é dinâmico, `GET /norms`)
- [x] Norma cadastrada com `period_qty=12`/`period_unit=MESES` — `nextDueAt` calcula pelo mecanismo
      genérico já existente, mesmo usado por todas as outras normas do catálogo
- [x] `authority`/`notes` citam as normas com os papéis corretos (13103+15923 = base/periodicidade,
      15526 = rede/complementar, em notes)
- [x] `mvn test` sem regressão (763 testes, 0 falhas)

## Dependências
Nenhuma técnica. Nomenclatura do `item_type` (`INSTALACAO_GAS` vs. outro nome) precisa de
confirmação rápida com Douglas antes de aplicar a migration (é o tipo de decisão que fica fixada
depois, difícil de renomear com dados em produção).

## Riscos
Baixo — item novo, aditivo, não toca em nenhum item existente.

## Esforço
Baixo-Médio

## Status
✅ Concluída — PR [#39](https://github.com/douglasjava/easy-maintenance-api/pull/39) mergeada em
`staging` em 19/08/2026. `V90__seed_gas_installation_norm.sql`, idempotente (`WHERE NOT EXISTS`), 763 testes
existentes passando (0 regressão). Nenhum teste novo dedicado — segue o mesmo padrão das demais
linhas de seed do catálogo (V2/V9), cobertas pelos testes genéricos de resolução de norma já
existentes, não por um teste por item_type. `authority` cita 13103+15923 (os dois com papel direto
na periodicidade); 15526 fica só em `notes` como referência complementar de rede — mais preciso do
que citar as 3 igualmente na `authority`.
