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

### 3. O padrão do achado #2 se repete: normas de escola também são regionalizadas

Não é só incêndio. Vigilância sanitária de creches/escolas e limpeza de reservatório de água
também são regidas por **comunicados estaduais/municipais** (ex.: CVS 006/2011 e CVS 31/2012 são
específicos de São Paulo), não por uma norma ABNT federal única. Isso reforça que "citar uma
autoridade normativa fixa e nacional" não é suficiente pra pelo menos 2 dos 3 domínios mais
sensíveis (incêndio e vigilância sanitária) — o produto precisa de um jeito de lidar com
variação estadual/municipal de autoridade, não só um catálogo fixo nacional.

### 4. Não existe épico dono do catálogo de normas como conteúdo

O único trabalho já feito (TASK-088) está arquivado dentro do EPIC-004 ("Banco de Dados e
Persistência"), que é sobre integridade técnica de dados, não sobre correção/abrangência do
conteúdo regulatório em si. Se esse levantamento virar trabalho de verdade, provavelmente merece
um épico próprio.

---

## Status do catálogo hoje (`norms` table, ~26 registros após dedupe da V78)

| item_type (banco)                | Autoridade citada                   | Observação                                                                                                                                                                                                                                                                                                                            |
|----------------------------------|-------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| EXTINTOR                         | ABNT NBR 12962                      | Federal, ok                                                                                                                                                                                                                                                                                                                           |
| SPDA (vários sub-itens)          | ABNT NBR 5419                       | Federal, ok — mas período já teve 2 bugs corrigidos (V71, V78)                                                                                                                                                                                                                                                                        |
| CAIXA_DAGUA                      | Vigilância Sanitária / ANVISA RE 09 | —                                                                                                                                                                                                                                                                                                                                     |
| ILUMINACAO_EMERGENCIA            | ABNT NBR 10898                      | Federal, ok                                                                                                                                                                                                                                                                                                                           |
| HIDRANTE / MANGUEIRA_DE_INCENDIO | ABNT NBR 13714                      | Federal, ok                                                                                                                                                                                                                                                                                                                           |
| AR_CONDICIONADO                  | ABNT NBR 11742 (?)                  | **Verificar** — Lei 13.589/2018 (PMOC) não aparece citada, é a base legal mais direta hoje em dia                                                                                                                                                                                                                                     |
| ALARME_DE_INCENDIO               | CBMMG IT (MG-específico)            | **Achado #2**                                                                                                                                                                                                                                                                                                                         |
| BOTOEIRA_DE_INCENDIO             | CBMMG IT (MG-específico)            | **Achado #2**                                                                                                                                                                                                                                                                                                                         |
| PORTA_CORTA_FOGO                 | CBMMG IT (MG-específico)            | **Achado #2**                                                                                                                                                                                                                                                                                                                         |
| AUTOMACAO_BOMBEIRO               | CBMMG IT (MG-específico)            | **Achado #2**                                                                                                                                                                                                                                                                                                                         |
| GERADOR                          | —                                   | **Não existe uma NBR única e dedicada à periodicidade de manutenção de gerador** (pesquisado) — o mercado usa `NBR ISO 8528` (classificação/especificação, não manutenção), `NBR 10898` (laudo do sistema de emergência) e boas práticas do fabricante. Precisa de decisão de produto: qual citar, ou tratar como item sem norma fixa |
| NR-10 (treinamento)              | NR-10 (MTE)                         | Federal, ok                                                                                                                                                                                                                                                                                                                           |
| NR-13 (caldeiras)                | NR-13 (MTE)                         | Federal, ok — período já corrigido (V71)                                                                                                                                                                                                                                                                                              |
| NR-23                            | NR-23 (MTE)                         | Federal, ok                                                                                                                                                                                                                                                                                                                           |
| NR-35                            | NR-35 (MTE)                         | Federal, ok                                                                                                                                                                                                                                                                                                                           |

*(lista reconstruída a partir da pesquisa de código — vale conferir linha a linha direto no banco
antes de qualquer mudança real)*

---

## Levantamento — normas candidatas por domínio (a verificar uma a uma)

Convenção de status: **✅ no catálogo** (banco) · **📄 só na página estática** · **❌ ausente dos dois** · **🔍 a verificar**

### A. Gestão de manutenção predial (base — aplica a todos os segmentos)

| Norma         | O que cobre                                                                                                                                                                                                                        | Status hoje                                                                                                               |
|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| **NBR 5674**  | Requisitos do sistema de gestão de manutenção de edificações — é a norma "guarda-chuva" que todo o discurso comercial do produto usa                                                                                               | 📄 só na página estática, **ausente do catálogo funcional**                                                               |
| **NBR 14037** | Conteúdo do Manual de Uso, Operação e Manutenção (a construtora deveria entregar)                                                                                                                                                  | ❌ ausente dos dois                                                                                                        |
| **NBR 16280** | Reforma em edificações — gestão de reformas, ART, responsabilidade técnica                                                                                                                                                         | 📄 só na página estática                                                                                                  |
| **NBR 16747** | Inspeção predial — diretrizes, terminologia, procedimentos (norma mais recente, 2020)                                                                                                                                              | ❌ ausente dos dois — vale avaliar se entra                                                                                |
| **NBR 5626**  | Instalações prediais de água fria                                                                                                                                                                                                  | ❌ ausente — relevante pra caixa d'água/rede hidráulica                                                                    |
| **NBR 15575** | Norma de Desempenho — define "vida útil de projeto" e exige que o Manual de Uso/Operação/Manutenção (NBR 14037) especifique as intervenções preventivas necessárias pra manter esse desempenho. Complementa a 14037, não substitui | 📄 **correção**: já está na página estática (`norms/page.tsx`) — eu tinha marcado errado como ausente na primeira rodada. Segue ausente do catálogo funcional |

### B. Segurança contra incêndio (todos os segmentos, mas estadualizada — ver achado #2)

| Norma                                                  | O que cobre                                                                  | Status hoje                                                                                                                                                                                                   |
|--------------------------------------------------------|------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| NBR 12962                                              | Extintores — inspeção, manutenção, recarga                                   | ✅ no catálogo                                                                                                                                                                                                 |
| NBR 13714                                              | Hidrantes e mangotinhos                                                      | ✅ no catálogo                                                                                                                                                                                                 |
| NBR 10898                                              | Iluminação de emergência                                                     | ✅ no catálogo                                                                                                                                                                                                 |
| NBR 17240                                              | Sistema de detecção e alarme de incêndio (substituiu a antiga NBR 9441/1998) | 🔍 citado na seed original, confirmar se sobreviveu ao dedupe da V78. **Fontes secundárias divergem sobre se a própria 17240 também já foi cancelada/revisada** — não confiar nisso sem checar direto na ABNT |
| NBR 16785                                              | Detecção de incêndio (aparece em fontes mais recentes)                       | ❌ ausente — pode ser sucessora/complementar da 17240, precisa verificar                                                                                                                                       |
| NBR 12693                                              | Sistemas de proteção por extintores / sprinklers                             | 🔍 confirmar se é a mesma citada como base do EXTINTOR ou é norma separada de sprinkler                                                                                                                       |
| NBR 9077                                               | Saídas de emergência                                                         | ❌ ausente                                                                                                                                                                                                     |
| **Instruções Técnicas do Corpo de Bombeiros estadual** | AVCB — varia por estado, hoje só MG está representado                        | ⚠️ ver achado #2                                                                                                                                                                                              |

### C. Elétrica / SPDA / climatização

| Norma                                             | O que cobre                                                                                                                    | Status hoje                                                                                                                                                |
|---------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| NBR 5410                                          | Instalações elétricas de baixa tensão                                                                                          | 📄 só na página estática                                                                                                                                   |
| NBR 5419                                          | SPDA (para-raios)                                                                                                              | ✅ no catálogo                                                                                                                                              |
| NR-10                                             | Segurança em instalações e serviços em eletricidade                                                                            | ✅ no catálogo                                                                                                                                              |
| **Lei 13.589/2018 + Portaria 3523/ANVISA (PMOC)** | Plano de Manutenção, Operação e Controle de ar-condicionado — obrigatório pra sistemas ≥60.000 BTU/5TR em uso público/coletivo | 🔍 catálogo cita "NBR 11742" pro AR_CONDICIONADO — **essa não é a base legal mais direta**; vale reavaliar se a citação certa não deveria ser a Lei 13.589 |

### C-bis. Instalações de gás combustível (transversal — comum em condomínio, hospital e indústria)

| Norma     | O que cobre                                                                                                             | Status hoje        |
|-----------|-------------------------------------------------------------------------------------------------------------------------|--------------------|
| NBR 13103 | Instalação de aparelhos a gás — foco residencial, manutenção preventiva anual (ou conforme fabricante, o que for menor) | ❌ ausente dos dois |
| NBR 15526 | Redes de distribuição interna de gás combustível — projeto e execução                                                   | ❌ ausente dos dois |
| NBR 15923 | Inspeção de redes de distribuição interna de gás                                                                        | ❌ ausente dos dois |

Gap real — nenhum item de gás está no catálogo hoje, apesar de ser um sistema predial comum com
obrigação de manutenção anual clara.

### D. Elevadores

| Norma     | O que cobre                                        | Status hoje                                                                                                                                                                                                                                                                                                                              |
|-----------|----------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| NBR 16083 | Manutenção de elevadores/escadas/esteiras rolantes | 📄 só na página estática. **⚠️ Um resultado de busca indicou que essa norma teria sido "cancelada em julho de 2012"** — informação de fonte secundária, não confiável por si só, **precisa verificação direta na ABNT antes de qualquer alteração no produto** (pode ser confusão com uma norma anterior substituída pela própria 16083) |

### E. Acessibilidade (transversal, exigida por lei federal)

| Norma    | O que cobre                                                                                                         | Status hoje                                                                     |
|----------|---------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| NBR 9050 | Acessibilidade a edificações/espaços — exigida por lei (Lei 13.146/2015, Decreto 5.296/2004), não é "opcional ABNT" | ❌ ausente dos dois — é diferente das outras por ter força de lei federal direta |

### F. Específicas de hospitais/saúde (ANVISA)

| Norma        | O que cobre                                                                                                      | Status hoje                                                                    |
|--------------|------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------|
| RDC 50/2002  | Projeto físico de estabelecimentos de saúde (inclui diretrizes de manutenção predial hospitalar)                 | 📄 só na página estática                                                       |
| RDC 63/2011  | Boas práticas de funcionamento de serviços de saúde — manutenção preventiva/corretiva de instalações             | 📄 só na página estática                                                       |
| RDC 15/2012  | Processamento de produtos pra saúde (esterilização/CME) — manutenção preventiva de equipamentos de esterilização | ❌ ausente dos dois                                                             |
| RDC 222/2018 | Gerenciamento de resíduos de serviços de saúde                                                                   | ❌ ausente — fora do escopo de "manutenção" mas pode ser relevante pro segmento |

**Nenhuma norma hospitalar-específica está no catálogo funcional** — confirma o gap do achado #1.

### G. Específicas de escolas

| Norma                                                                   | O que cobre                                                                                          | Status hoje |
|-------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|-------------|
| NBR 9050                                                                | Acessibilidade (mesma da seção E, com exigência específica de Corpo de Bombeiros pra alvará escolar) | ❌ ausente   |
| Instrução Técnica de Corpo de Bombeiros (saídas de emergência, lotação) | Varia por estado                                                                                     | ❌ ausente   |

**Confirmado**: escola não tem um corpo normativo ABNT/federal próprio equivalente ao da saúde
(ANVISA). O que existe é **vigilância sanitária estadual/municipal pra creches/escolas** (ex.: em
SP, Comunicado CVS 006/2011 pra limpeza de reservatório de água até 2.000L, Comunicado CVS 31/2012
pra caixas de areia recreativas) — mesmo padrão de regionalização do achado #2/#3, agora também
pra escola. Escola herda as normas gerais de edificação + acessibilidade + incêndio (estas
também regionalizadas), mais essa camada extra de vigilância sanitária local específica de
educação infantil.

### H. Específicas de indústrias

| Norma                 | O que cobre                                                                                                          | Status hoje                                                |
|-----------------------|----------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------|
| NR-13                 | Caldeiras, vasos de pressão, tubulação                                                                               | ✅ no catálogo                                              |
| NR-12                 | Segurança em máquinas e equipamentos                                                                                 | ❌ ausente                                                  |
| NR-23                 | Proteção contra incêndio (é a "incêndio" trabalhista, diferente das NBR de incêndio predial)                         | ✅ no catálogo                                              |
| NR-35                 | Trabalho em altura                                                                                                   | ✅ no catálogo                                              |
| NR-33                 | Espaços confinados                                                                                                   | ❌ ausente — confirmar se é relevante pro escopo do produto |
| NBR 12177 / NBR 12228 | Complementam NR-13 — inspeção de segurança de caldeiras aquotubulares/flamotubulares e tanques de gases refrigerados | ❌ ausente                                                  |

**"Indústria" é o segmento mais heterogêneo** — o corpo normativo real varia MUITO por tipo de
indústria (química, alimentícia, metalúrgica, etc.), licenciamento ambiental estadual entra em
jogo, e não dá pra cobrir com uma lista fixa pequena do jeito que dá pra fazer com condomínio.
Vale uma conversa à parte sobre até onde o produto se compromete a cobrir esse segmento.

---

## A lista já está completa? (resposta à pergunta do Douglas)

**Pra começar o trabalho norma-a-norma, sim — essa base já é sólida o suficiente.** Ela cobre os
domínios que seguram 90% do que os 4 segmentos realmente precisam: gestão predial geral, incêndio,
elétrica/SPDA/climatização, gás, elevadores, acessibilidade, hospitalar (ANVISA) e as NRs
industriais mais comuns.

**Mas "completa" no sentido absoluto não é uma linha de chegada fixa** — pesquisa regulatória
sempre tem cauda longa (normas estaduais específicas, normas de nicho por tipo de indústria,
atualizações futuras). Ficar expandindo a lista antes de começar o trabalho norma-a-norma vira
procrastinação disfarçada de rigor. Recomendo: começar já pelas normas da seção A/B (base +
incêndio, que são o núcleo do que o catálogo hoje tenta cobrir e onde os achados #1/#2 doem mais),
e deixar a lista crescer organicamente conforme formos encontrando lacunas durante esse trabalho —
não como pré-requisito bloqueante.

Pontos que ainda merecem uma palavra final antes de tratar a lista como fechada:
- Indústria (seção H) — decisão de produto sobre até onde cobrir, não é só pesquisa
- 3 itens marcados 🔍 (NBR 17240, NBR 12693, GERADOR) — precisam verificação direta na fonte, não
  de mais busca genérica

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

---

## Trabalho norma-a-norma

### NBR 5674 — Manutenção de Edificações — Requisitos para o Sistema de Gestão de Manutenção

**Status**: ✅ Analisada (19/08/2026). Fontes: tentativa de PDF oficial (pmb.eb.mil.br — 404; cópia
alternativa não estava em texto extraível) + triangulação de 3 fontes secundárias especializadas
(sienge.com.br, blog.engeman.com.br, checklistfacil.com — a terceira não retornou conteúdo). Duas
fontes independentes convergiram no conteúdo abaixo, tratando como confiável; nenhuma frase única
de fonte não-oficial é citada literalmente.

**O que a norma realmente exige** (não é uma norma de periodicidade fixa — é uma norma de
**sistema de gestão**):

1. **Programa de manutenção documentado**: atividades programadas, com periodicidade, responsáveis
   e recursos definidos — não um documento genérico, precisa ser específico da edificação.
2. **Três tipos de manutenção reconhecidos pela norma**: preventiva (agendada por periodicidade),
   corretiva (reativa a falha) e **preditiva** (baseada em dado real de condição — termografia,
   análise de vibração, sensores). *Achado: nosso próprio post do blog e a página estática `/norms`
   só mencionam preventiva/corretiva, omitindo a preditiva.*
3. **Inspeções prediais formalizadas, com relatório** — não é "olhar e anotar", é inspeção com
   documento de saída.
4. **Planejamento orçamentário anual, com reserva para emergências**. *Achado: isso é uma exigência
   explícita da norma que o produto não endereça hoje — não temos nenhuma feature de orçamento/fundo
   de reserva pro prédio do cliente (o painel financeiro do EPIC-020 é do nosso próprio negócio, não
   do condomínio do cliente). Não é uma recomendação de feature agora, só um gap real que vale saber
   que existe.*
5. **Registros legíveis e arquivados**, sob responsabilidade formal do proprietário/síndico.
6. **Não define periodicidade fixa universal** — remete ao Manual de Uso, Operação e Manutenção de
   cada edificação (NBR 14037), que por sua vez deve conter: diretrizes de uso por sistema,
   cronograma de manutenção preventiva, materiais usados e vida útil esperada dos componentes,
   contatos de fornecedores, diagramas técnicos.
7. **Não classifica edificações por categoria/porte** — a norma é genérica pra qualquer edificação,
   a especificidade vem do manual de cada uma.

**Base legal de responsabilidade** (achado novo, não estava no nosso conteúdo até agora):
- **Código Civil, Art. 937**: o proprietário responde por danos causados pela ruína do prédio,
  resultante de falta de manutenção ou de defeito de construção.
- **Código Civil, Art. 938**: o morador/ocupante responde por dano causado por coisa que caia de
  sua unidade.
- Exposição criminal possível em caso de morte por negligência comprovada.
- Documentação de diligência (seguir a norma, contratar profissional qualificado) funciona como
  proteção jurídica — é exatamente o argumento comercial que já usamos, mas agora com base legal
  citável, não só "a norma vira régua em perícia".

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | Não se aplica — NBR 5674 é norma de sistema de gestão, não item periódico com `period_qty`. Não faz sentido virar uma linha no catálogo do jeito que ele existe hoje | Nenhuma — o gap real não é "falta uma linha", é que o catálogo hoje só modela normas de item, não normas de processo/gestão |
| `/norms` (página estática) | Descrição atual diz "plano de manutenção preventiva e corretiva" — **falta menção à manutenção preditiva** | Pequeno ajuste de texto |
| Blog (`nbr-5674-responsabilidade-sindico`) | Bem alinhado no geral (plano, inspeção, registro, responsabilidade civil/criminal) — mas **não cita os artigos do Código Civil** (poderia, dá mais credibilidade) e **não menciona a reserva orçamentária anual nem a manutenção preditiva** | Vale uma atualização pontual do post, não uma reescrita |

**Pendência não resolvida**: não consegui ler o texto oficial completo da norma (PDF direto falhou/
não decodificou) — o que está acima é triangulado de fontes especializadas confiáveis, mas não é
"li o texto da ABNT com meus próprios olhos". Se algum ponto for usado pra afirmação jurídica forte
(não só conteúdo de blog), vale confirmar contra a cópia oficial paga da ABNT antes.
