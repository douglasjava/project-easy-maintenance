# Levantamento de Normas — Auditoria de Compliance (ABNT/NR/RDC)

**Início**: 19/08/2026
**Objetivo**: análise fria de NBR 5674 e todas as normas relevantes pro domínio do produto (condomínios,
hospitais, escolas, indústrias), cruzando com o que o sistema realmente tem hoje. Trabalho em
andamento — este documento é atualizado a cada rodada, norma por norma.

---

## Achados críticos (antes de qualquer norma específica)

### 1. O catálogo funcional (banco de dados) e a página `/norms` são dois sistemas desconectados

- **Catálogo real** (`norms` table, ~26 registros, alimentado só por migration SQL — sem UI de
  admin pra adicionar/editar): cobre **só** incêndio/elétrico/prédio genérico + NR-10/13/23/35.
  **Não tem NBR 5674**, nem nada específico de hospital, escola ou indústria.
- **Página `/norms`** (`easy-maintenance-web/src/app/norms/page.tsx`): conteúdo estático,
  hardcoded, 13 normas incluindo NBR 5674, NBR 16280, RDC 50, RDC 63 — mas **não consulta o
  banco**. É uma página educativa/institucional, não reflete o que realmente é usado quando um
  item de manutenção é cadastrado.
- **Consequência prática**: se um usuário cadastra um item "Regulatório" pra um equipamento
  hospitalar ou industrial hoje, não existe norma curada pra vincular — o item cai como
  `OPERATIONAL` (sem base normativa), mesmo que a página `/norms` "prometa" cobertura de RDC
  50/63.

### 2. Autoridade de incêndio citada no banco é de um estado só (Minas Gerais)

Os registros de incêndio no catálogo citam `CBMMG IT-12/13/16/17` (Instruções Técnicas do Corpo de
Bombeiros de **Minas Gerais**). Segurança contra incêndio é regulada por Corpo de Bombeiros
**estadual** — cada estado tem sua própria numeração de Instrução Técnica. Um cliente fora de MG
hoje recebe uma citação de autoridade que não é a dele. Isso precisa de decisão de produto: citar
só a norma ABNT federal (mais genérico, sempre válido) e deixar a IT estadual como informação à
parte / configurável por organização, em vez de hardcoded pra um estado só.

### 3. Não existe épico dono do catálogo de normas como conteúdo

O único trabalho já feito (TASK-088) está arquivado dentro do EPIC-004 ("Banco de Dados e
Persistência"), que é sobre integridade técnica de dados, não sobre correção/abrangência do
conteúdo regulatório em si. Se esse levantamento virar trabalho de verdade, provavelmente merece
um épico próprio.

---

## Status do catálogo hoje (`norms` table, ~26 registros após dedupe da V78)

| item_type (banco) | Autoridade citada | Observação |
|---|---|---|
| EXTINTOR | ABNT NBR 12962 | Federal, ok |
| SPDA (vários sub-itens) | ABNT NBR 5419 | Federal, ok — mas período já teve 2 bugs corrigidos (V71, V78) |
| CAIXA_DAGUA | Vigilância Sanitária / ANVISA RE 09 | — |
| ILUMINACAO_EMERGENCIA | ABNT NBR 10898 | Federal, ok |
| HIDRANTE / MANGUEIRA_DE_INCENDIO | ABNT NBR 13714 | Federal, ok |
| AR_CONDICIONADO | ABNT NBR 11742 (?) | **Verificar** — Lei 13.589/2018 (PMOC) não aparece citada, é a base legal mais direta hoje em dia |
| ALARME_DE_INCENDIO | CBMMG IT (MG-específico) | **Achado #2** |
| BOTOEIRA_DE_INCENDIO | CBMMG IT (MG-específico) | **Achado #2** |
| PORTA_CORTA_FOGO | CBMMG IT (MG-específico) | **Achado #2** |
| AUTOMACAO_BOMBEIRO | CBMMG IT (MG-específico) | **Achado #2** |
| GERADOR | — | **Verificar norma de referência** |
| NR-10 (treinamento) | NR-10 (MTE) | Federal, ok |
| NR-13 (caldeiras) | NR-13 (MTE) | Federal, ok — período já corrigido (V71) |
| NR-23 | NR-23 (MTE) | Federal, ok |
| NR-35 | NR-35 (MTE) | Federal, ok |

*(lista reconstruída a partir da pesquisa de código — vale conferir linha a linha direto no banco
antes de qualquer mudança real)*

---

## Levantamento — normas candidatas por domínio (a verificar uma a uma)

Convenção de status: **✅ no catálogo** (banco) · **📄 só na página estática** · **❌ ausente dos dois** · **🔍 a verificar**

### A. Gestão de manutenção predial (base — aplica a todos os segmentos)

| Norma | O que cobre | Status hoje |
|---|---|---|
| **NBR 5674** | Requisitos do sistema de gestão de manutenção de edificações — é a norma "guarda-chuva" que todo o discurso comercial do produto usa | 📄 só na página estática, **ausente do catálogo funcional** |
| **NBR 14037** | Conteúdo do Manual de Uso, Operação e Manutenção (a construtora deveria entregar) | ❌ ausente dos dois |
| **NBR 16280** | Reforma em edificações — gestão de reformas, ART, responsabilidade técnica | 📄 só na página estática |
| **NBR 16747** | Inspeção predial — diretrizes, terminologia, procedimentos (norma mais recente, 2020) | ❌ ausente dos dois — vale avaliar se entra |
| **NBR 5626** | Instalações prediais de água fria | ❌ ausente — relevante pra caixa d'água/rede hidráulica |

### B. Segurança contra incêndio (todos os segmentos, mas estadualizada — ver achado #2)

| Norma | O que cobre | Status hoje |
|---|---|---|
| NBR 12962 | Extintores — inspeção, manutenção, recarga | ✅ no catálogo |
| NBR 13714 | Hidrantes e mangotinhos | ✅ no catálogo |
| NBR 10898 | Iluminação de emergência | ✅ no catálogo |
| NBR 17240 | Sistema de detecção e alarme de incêndio | 🔍 citado na seed original, confirmar se sobreviveu ao dedupe da V78 |
| NBR 16785 | Detecção de incêndio (aparece em fontes mais recentes) | ❌ ausente — pode ser sucessora/complementar da 17240, precisa verificar |
| NBR 12693 | Sistemas de proteção por extintores / sprinklers | 🔍 confirmar se é a mesma citada como base do EXTINTOR ou é norma separada de sprinkler |
| NBR 9077 | Saídas de emergência | ❌ ausente |
| **Instruções Técnicas do Corpo de Bombeiros estadual** | AVCB — varia por estado, hoje só MG está representado | ⚠️ ver achado #2 |

### C. Elétrica / SPDA / climatização

| Norma | O que cobre | Status hoje |
|---|---|---|
| NBR 5410 | Instalações elétricas de baixa tensão | 📄 só na página estática |
| NBR 5419 | SPDA (para-raios) | ✅ no catálogo |
| NR-10 | Segurança em instalações e serviços em eletricidade | ✅ no catálogo |
| **Lei 13.589/2018 + Portaria 3523/ANVISA (PMOC)** | Plano de Manutenção, Operação e Controle de ar-condicionado — obrigatório pra sistemas ≥60.000 BTU/5TR em uso público/coletivo | 🔍 catálogo cita "NBR 11742" pro AR_CONDICIONADO — **essa não é a base legal mais direta**; vale reavaliar se a citação certa não deveria ser a Lei 13.589 |

### D. Elevadores

| Norma | O que cobre | Status hoje |
|---|---|---|
| NBR 16083 | Manutenção de elevadores/escadas/esteiras rolantes | 📄 só na página estática. **⚠️ Um resultado de busca indicou que essa norma teria sido "cancelada em julho de 2012"** — informação de fonte secundária, não confiável por si só, **precisa verificação direta na ABNT antes de qualquer alteração no produto** (pode ser confusão com uma norma anterior substituída pela própria 16083) |

### E. Acessibilidade (transversal, exigida por lei federal)

| Norma | O que cobre | Status hoje |
|---|---|---|
| NBR 9050 | Acessibilidade a edificações/espaços — exigida por lei (Lei 13.146/2015, Decreto 5.296/2004), não é "opcional ABNT" | ❌ ausente dos dois — é diferente das outras por ter força de lei federal direta |

### F. Específicas de hospitais/saúde (ANVISA)

| Norma | O que cobre | Status hoje |
|---|---|---|
| RDC 50/2002 | Projeto físico de estabelecimentos de saúde (inclui diretrizes de manutenção predial hospitalar) | 📄 só na página estática |
| RDC 63/2011 | Boas práticas de funcionamento de serviços de saúde — manutenção preventiva/corretiva de instalações | 📄 só na página estática |
| RDC 15/2012 | Processamento de produtos pra saúde (esterilização/CME) — manutenção preventiva de equipamentos de esterilização | ❌ ausente dos dois |
| RDC 222/2018 | Gerenciamento de resíduos de serviços de saúde | ❌ ausente — fora do escopo de "manutenção" mas pode ser relevante pro segmento |

**Nenhuma norma hospitalar-específica está no catálogo funcional** — confirma o gap do achado #1.

### G. Específicas de escolas

| Norma | O que cobre | Status hoje |
|---|---|---|
| NBR 9050 | Acessibilidade (mesma da seção E, com exigência específica de Corpo de Bombeiros pra alvará escolar) | ❌ ausente |
| Instrução Técnica de Corpo de Bombeiros (saídas de emergência, lotação) | Varia por estado | ❌ ausente |

**Não achei uma norma ABNT "exclusiva" de escola além das já cobertas em incêndio/acessibilidade/
estrutural** — escola parece herdar as normas gerais de edificação + acessibilidade + incêndio,
sem um corpo normativo próprio equivalente ao da saúde (ANVISA). **Precisa confirmar isso com mais
pesquisa antes de dar como fechado** — pode haver norma estadual/municipal de vigilância sanitária
escolar não coberta ainda.

### H. Específicas de indústrias

| Norma | O que cobre | Status hoje |
|---|---|---|
| NR-13 | Caldeiras, vasos de pressão, tubulação | ✅ no catálogo |
| NR-12 | Segurança em máquinas e equipamentos | ❌ ausente |
| NR-23 | Proteção contra incêndio (é a "incêndio" trabalhista, diferente das NBR de incêndio predial) | ✅ no catálogo |
| NR-35 | Trabalho em altura | ✅ no catálogo |
| NR-33 | Espaços confinados | ❌ ausente — confirmar se é relevante pro escopo do produto |
| NBR 12177 / NBR 12228 | Complementam NR-13 — inspeção de segurança de caldeiras aquotubulares/flamotubulares e tanques de gases refrigerados | ❌ ausente |

**"Indústria" é o segmento mais heterogêneo** — o corpo normativo real varia MUITO por tipo de
indústria (química, alimentícia, metalúrgica, etc.), licenciamento ambiental estadual entra em
jogo, e não dá pra cobrir com uma lista fixa pequena do jeito que dá pra fazer com condomínio.
Vale uma conversa à parte sobre até onde o produto se compromete a cobrir esse segmento.

---

## Próximos passos (a decidir com Douglas)

1. Confirmar prioridade: seguir o levantamento (mais domínios/normas a checar) ou já começar o
   trabalho norma-a-norma nas que já estão listadas aqui?
2. Decidir o que fazer com o achado #2 (autoridade de incêndio MG-específica) — provavelmente
   merece task própria, independente do resto.
3. Decidir se cria um épico específico pra "catálogo de normas" em vez de deixar dentro do
   EPIC-004.
4. Verificar diretamente na fonte (ABNT/normas.com.br oficial) o status real da NBR 16083 antes de
   qualquer normativa nova ser adicionada citando ela.
