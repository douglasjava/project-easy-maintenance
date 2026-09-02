# TASK-228 — BACKEND: Norma para pontos de ancoragem / linha de vida

## Tipo
BACKEND

## Categoria
Conteúdo Regulatório / Compliance

## Prioridade
🟡 Médio

## Épico
[EPIC-025](../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas

## QA obrigatório
Sim — teste manual: cadastrar um item com o tipo "PONTOS DE ANCORAGEM" (ou similar), selecionar a
norma no dropdown e confirmar que `nextDueAt` calcula 12 meses a partir da última execução.

---

## Contexto

Item #5a do feedback de demo real do cliente Rogerio Dantas ([TASK-218](TASK-218.md)): ele
cadastrou um item como "INSTALAÇÃO DE PONTOS DE ANCORAGEM" durante o cadastro ao vivo e não havia
nenhuma norma correspondente no catálogo — nem em `item_types`, nem em `norms`. Sistema de proteção
contra queda (ponto de ancoragem fixo/linha de vida) é comum em condomínios e indústrias com acesso
a fachada/cobertura pra manutenção (limpeza de fachada, poda, manutenção de telhado/SPDA) — exatamente
o tipo de cliente que o produto mira.

Mesmo padrão da TASK-178 (instalação de gás): `item_types` é só um catálogo de autocomplete de
texto livre, sem relação direta com a chave usada pelas normas — o dropdown "Norma" do formulário de
item busca `GET /norms` dinamicamente. Não seria o caso de adicionar um `item_type` fixo, só uma
linha nova em `norms`.

## Pesquisa de periodicidade (verificada antes de implementar, mesmo padrão de rigor da TASK-178)

- **NR-35 (MTE), item 35.6.6.3**: inspeção periódica do sistema de ancoragem com periodicidade **não
  superior a 12 meses**, por profissional qualificado, além de inspeção inicial obrigatória após
  instalação, alteração ou mudança de local.
- **ABNT NBR 16325** — Partes 1 e 2 (2024): requisitos de projeto, fabricação e desempenho dos
  dispositivos de ancoragem (resistência mínima de 15 kN sem deformação permanente). Parte 3: regime
  de inspeção e ensaio de arrancamento em campo dos pontos já instalados.

Fontes: [gov.br — NR-35](https://www.gov.br/trabalho-e-emprego/pt-br/acesso-a-informacao/participacao-social/conselhos-e-orgaos-colegiados/comissao-tripartite-partitaria-permanente/normas-regulamentadora/normas-regulamentadoras-vigentes/norma-regulamentadora-no-35-nr-35),
Atlas Safe, Hook Engenharia, Dois Dez (checklists/guias técnicos que citam o texto da NR-35 e da
NBR 16325 sobre periodicidade e resistência).

## Escopo

- Nova migration `V106__seed_pontos_ancoragem_norm.sql`: `INSERT INTO norms` com `item_type =
  'PONTOS_ANCORAGEM'`, `period_unit = 'MESES'`, `period_qty = 12`, `tolerance_days = 30` (mesmo
  padrão da V90/TASK-178), idempotente (`WHERE NOT EXISTS`).
- Sem mudança de frontend — dropdown de normas já é dinâmico (confirmado na TASK-178).

## Critérios de Aceite

- [x] Nova norma `PONTOS_ANCORAGEM` existe e aparece no dropdown de normas ao cadastrar item
      REGULATORY (dropdown já é dinâmico, `GET /norms`)
- [x] Norma cadastrada com `period_qty=12`/`period_unit=MESES` — `nextDueAt` calcula pelo mecanismo
      genérico já existente
- [x] `authority`/`notes` citam NR-35 (periodicidade) e ABNT NBR 16325 (requisitos técnicos +
      regime de inspeção), com a fonte/item exato da NR-35 (35.6.6.3)
- [x] `mvn test` sem regressão (878 testes, 0 falhas)
- [ ] QA manual — cadastrar item de verdade com esse tipo, confirmar dropdown e `nextDueAt`
      (pendente, sem acesso ao ambiente logado)

## Dependências
Nenhuma técnica. Nomenclatura do `item_type` (`PONTOS_ANCORAGEM`) é nova (não precisa bater com o
texto livre que o cliente digitou) — mesma lógica confirmada na TASK-178.

## Riscos
Baixo — item novo, aditivo, não toca em nenhum item/norma existente. Único ponto de atenção: este
repo não tem teste automatizado que valide a sintaxe SQL da migration contra MySQL real (Flyway só
roda de fato no boot da aplicação — `spring.flyway.enabled=false` no profile de teste padrão, e não
há teste com Testcontainers ativo hoje apesar da dependência estar no `pom.xml`). Migration escrita
espelhando exatamente a estrutura da V90 (já validada em produção), mas vale conferir no primeiro
deploy.

## Esforço
Baixo

## Status
✅ Implementada, PR aberta contra `staging`. Branch `feature/TASK-228-pontos-ancoragem-norm`.
`mvn test` limpo (878 testes, 0 regressão — suite roda em H2, não valida a migration contra MySQL
real, ver Riscos). Falta QA manual (cadastro de item real) e confirmação do Douglas sobre a
nomenclatura do `item_type` antes do primeiro deploy em produção.
