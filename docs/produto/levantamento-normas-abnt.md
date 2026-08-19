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

---

### NBR 14037 — Diretrizes para Elaboração de Manuais de Uso, Operação e Manutenção das Edificações

**Status**: ✅ Analisada (19/08/2026). É a norma pra qual a NBR 5674 remete toda periodicidade
específica — as duas formam o par central do discurso do produto, mas **a 14037 não tem entrada
nem na página estática `/norms` nem no catálogo funcional**, apesar de ser citada o tempo todo
(inclusive no nosso blog).

**Status oficial confirmado direto num catálogo de normas** (não fonte secundária tipo blog): **vigente**,
edição revisada em **janeiro/2024**. Buscas genéricas retornavam "cancelada em janeiro de 2024" —
era ruído: a edição *anterior* (2011/2014) foi substituída pela edição 2024 da mesma norma, o que
buscadores/blogs às vezes relatam de forma confusa como "cancelada". **Mesmo padrão de ambiguidade
que já tinha marcado pra NBR 16083 e NBR 17240** — daqui pra frente, verificar status direto num
catálogo de normas dedicado, não em busca genérica.

**O que a norma exige:**

1. Define o **conteúdo obrigatório** do Manual de Uso, Operação e Manutenção: características
   construtivas de unidades e áreas comuns, descrição de instalações, modelos de programa de
   manutenção e listas de verificação, planos de manutenção e controle pra conservação adequada
   dos sistemas construtivos.
2. **Obrigação é da construtora/incorporadora** — é ela quem precisa elaborar e entregar o manual
   ao representante legal do empreendimento (síndico), não do gestor de manutenção depois.
   Elaborado especificamente pra cada empreendimento (não é um modelo genérico).
3. Função: funciona como guia de instrução do condomínio — uso correto, conservação, manutenção
   preventiva e operação dos sistemas construtivos, aumentando a vida útil do prédio.
4. Não achei, nas fontes consultadas, prazo legal explícito de quando a construtora deve entregar
   o manual (marcado como pendência de verificação, não como "a norma não define" — pode estar no
   texto oficial e não ter aparecido nos resumos).

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | Não se aplica — mesma razão da 5674: é norma de "o que o manual deve conter", não item com periodicidade própria | Nenhuma |
| `/norms` (página estática) | **Ausente** — a norma mais citada no nosso discurso ("o manual da NBR 14037 diz...") não tem entrada própria pro usuário final entender o que ela é | Adicionar entrada (mesmo formato das outras 13) |
| Blog (`nbr-5674-responsabilidade-sindico`) | Cita a 14037 corretamente como "norma complementar", mas não explica o que ela exige nem menciona que é obrigação da construtora entregar | Poderia ganhar 1-2 frases explicando melhor, não é erro, é oportunidade |
| Produto (funcionalidade) | Não existe hoje nenhum conceito de "esse cliente tem o Manual NBR 14037 do prédio dele arquivado/em dia" — é um documento que a NBR 5674 pressupõe existir, mas o produto não rastreia sua existência/conteúdo | Observação, não recomendação de feature agora |

**Pendência**: prazo de entrega do manual pela construtora — verificar na próxima passada com fonte
melhor (ou texto oficial, se conseguir acesso).

---

### NBR 16280 — Reforma em Edificações — Sistema de Gestão de Reformas — Requisitos

**Status**: ✅ Analisada (19/08/2026). Status oficial confirmado direto num catálogo de normas
(buscanormas.com.br): **vigente**, edição atual **2020, versão corrigida 2022** (original 2014).
Sem a confusão de "cancelada" que apareceu nas outras 3 normas — aqui a busca genérica já veio
mais limpa, mas confirmei do mesmo jeito por disciplina.

**Achado conceitual importante**: a própria norma **define reforma como o que NÃO é manutenção** —
"reforma é qualquer alteração nas condições da edificação com o objetivo de recuperar, melhorar ou
ampliar suas condições de habitabilidade, uso ou segurança, **e que não é manutenção**". Isso
importa pro produto: a NBR 16280 é **adjacente**, não **central**, ao que o Easy Maintenance faz —
diferente da 5674/14037, que são o núcleo do produto, a 16280 trata de uma categoria de atividade
que a própria norma separa de "manutenção". Não é um gap a corrigir, é uma fronteira de escopo a
ter clareza.

**O que a norma exige:**

1. Sistema de gestão de reformas: comunicação formal ao síndico **antes do início** de qualquer
   intervenção construtiva/reforma na unidade, independente do porte, em linguagem simples e
   objetiva.
2. **ART/RRT obrigatória** quando a intervenção afeta estrutura, elétrica, hidráulica, gás ou
   segurança do prédio (demolição interna, abertura de vão em parede, furo em laje, alteração de
   instalação hidráulica/elétrica/gás, quebra de piso, etc.) — sem ART/RRT, a obra não pode
   começar.
3. **Responsabilidades do síndico**: aprovar ou reprovar a documentação apresentada, fiscalizar a
   obra durante toda a execução, garantir conformidade com o projeto, comunicar os demais
   moradores (datas/horários permitidos), monitorar cumprimento do plano.
4. Documentação técnica: laudo técnico assinado por engenheiro ou arquiteto pra obras de reforma
   dentro ou fora das unidades.
5. Depois de autorizada pelo síndico, o morador também precisa comunicar os vizinhos.

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | Não se aplica — mesma razão da 5674/14037: norma de sistema de gestão, não item periódico | Nenhuma |
| `/norms` (página estática) | **Já existe e está correta** — menciona ART/RRT e o objetivo de não comprometer a estrutura. Nenhum erro encontrado | Nenhuma correção necessária |
| Produto (funcionalidade) | O produto não tem (e provavelmente não deveria ter, dado o escopo) nenhum fluxo de "reforma" — é manutenção preventiva/corretiva de sistemas existentes, categoria diferente por definição da própria norma | Nenhuma — é clareza de fronteira de escopo, não um gap |

**Pendência**: não achei prazo numérico específico (em dias) pra comunicação prévia ao síndico nas
fontes consultadas — só "antes do início da obra", sem prazo fixo. Marcado como pendência, não
como "a norma não define um prazo" (pode estar no texto oficial sem ter aparecido nos resumos).

---

### NBR 16747 — Inspeção Predial — Diretrizes, Conceitos, Terminologia e Procedimento

**Status**: ✅ Analisada (19/08/2026). **Vigente**, edição **2020** (primeira edição, 21/05/2020).
Sem ambiguidade de cancelamento nas fontes consultadas — status limpo, mas mesmo assim não achei
um catálogo dedicado (tipo buscanormas.com.br) que listasse essa norma especificamente pra bater
com a técnica das anteriores; o "vigente" aqui vem de múltiplas fontes secundárias convergentes
(blogs de engenharia, IBAPE), não de um catálogo formal. Vale reforçar essa checagem se a norma for
usada pra alguma alegação forte.

**O que a norma exige:**

1. Define inspeção predial como avaliação sistêmica e predominantemente **sensorial** (visual,
   sem ensaios/sondagens) das condições de uso, operação, manutenção e funcionalidade do edifício
   e seus sistemas.
2. Estabelece metodologia padronizada: levantamento e análise de dados/documentos como etapa
   mínima, classificação de anomalias em 3 graus de risco — **Crítico** (risco iminente,
   ação imediata), **Médio** (ação programada a curto prazo), **Mínimo** (não compromete
   segurança, ação a médio/longo prazo).
3. Define conteúdo mínimo do laudo, que organiza recomendações por prioridade (1/2/3) e pode
   indicar a necessidade de inspeções especializadas complementares.
4. **Fora do escopo da norma**: análises estruturais profundas que exigem sondagem/ensaios, laudo
   de vistoria pra seguro, AVCB, certificado de elevadores — a inspeção predial não substitui esses
   documentos, é complementar.
5. **Não define periodicidade fixa** — fica a critério do inspetor, dependendo de exposição ao
   meio e qualidade da gestão de manutenção já implantada. Ordem de grandeza encontrada nas fontes:
   5-10 anos pra edificações novas, 1-5 anos pra edificações antigas (não é valor normativo, é
   prática de mercado reportada).
6. Laudo deve ter ART/RRT do profissional responsável — mesma exigência de responsabilidade
   técnica já vista na 16280.

**Achado — mesmo padrão de regionalização já flagado nos achados #2/#3**: não existe lei federal
que torne a inspeção predial obrigatória. A obrigatoriedade é **municipal**, variando por cidade —
ex.: São Paulo (capital) tem **Lei 13.558/2003** + **Decreto 58.633/2019** + **Lei 16.642/2017**,
exigindo inspeção periódica pra prédios com mais de 5 anos. Não encontrei confirmação equivalente
pra outras cidades relevantes ao produto (Belo Horizonte, Rio de Janeiro) nas fontes consultadas —
marcado como pendência de verificação, não como "não existe". Reforça que qualquer comunicação
sobre "obrigatoriedade" da NBR 16747 no produto precisa ser condicionada ao município, igual já
vale pros achados #2/#3 (Corpo de Bombeiros e vigilância sanitária).

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | Ausente — mas essa é diferente das anteriores: **poderia** ter representação no schema atual, já que na prática o mercado usa periodicidade de referência (1-5 ou 5-10 anos), mesmo não sendo normativa | Avaliar como item de catálogo, com ressalva clara de que o prazo é "de mercado", não normativo |
| `/norms` (página estática) | Ausente — norma relevante e de alto valor de marketing (liga direto com responsabilidade do síndico/Código Civil art. 1.348), recomendo adicionar | Adicionar entrada |
| Produto (funcionalidade) | Não existe hoje nenhum conceito de "inspeção predial" como atividade distinta de manutenção de item — é uma avaliação sistêmica pontual, não um item recorrente como os que o catálogo modela | Observação, não recomendação de feature agora |

**Pendência**: confirmar status "vigente" num catálogo formal de normas (não só fontes
secundárias); confirmar quais outros municípios relevantes ao produto (BH, RJ) têm lei própria de
obrigatoriedade, além de São Paulo.

---

### NBR 5626 — Sistemas Prediais de Água Fria e Água Quente — Projeto, Execução, Operação e Manutenção

**Status**: ⚠️ **Ambíguo — não resolvido nesta rodada**. Edição atual é **2020** (substituiu a
antiga NBR 5626:1998 + NBR 7198:1993, que tratava separadamente água quente). Ao consultar
diretamente o catálogo dedicado normas.com.br (técnica já validada nas normas anteriores), a página
mostra "Vigente" no campo de status, mas também exibe um aviso textual contraditório: **"A norma
NBR5626 em 06/2020 foi cancelada e seu uso pode trazer riscos"**. Busquei uma edição mais nova
(2023/2024) que explicasse esse aviso e não encontrei nenhuma nas fontes disponíveis. Não vou
tratar isso como "norma morta" nem como "norma 100% vigente" — fica como pendência explícita de
verificação direta na fonte oficial ABNT antes de qualquer uso em alegação de produto.

**O que a norma exige (independente da pendência de status acima, o conteúdo é consistente entre
todas as fontes):**

1. Escopo: projeto, execução, especificação de materiais, **inspeção e manutenção preventiva** de
   sistemas prediais de água fria e água quente potável — residencial, comercial, industrial, misto.
2. **Fora do escopo**: água não potável, água de processo industrial, sistemas intrínsecos a
   equipamentos específicos, combate a incêndio, e o sistema de abastecimento público em si (a
   norma trata do sistema predial, não da rede externa).
3. Objetivos centrais: preservar a potabilidade da água ao longo do sistema predial, garantir bom
   desempenho hidráulico, uso racional de água e energia.
4. Trata de reservatórios (caixa d'água): tubulação de limpeza, extravasão (ladrão) e aviso — proíbe
   ligação direta dessas linhas com rede de esgoto ou pluvial; exige que o reservatório seja
   projetado para permitir verificação e manutenção de forma simples e econômica.
5. Regra de transição: a versão 2020 não se aplica a projetos protocolados antes da publicação nem
   dentro dos 180 dias seguintes (26/12/2020 é a data efetiva de aplicação obrigatória) — projetos
   anteriores a essa janela seguem a norma antiga. Relevante só para novas edificações, não para o
   produto (que lida com edificações já existentes/operando).

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | Ausente — mas a caixa d'água/reservatório **já é um item do catálogo hoje**, citado como "CAIXA_DAGUA / Vigilância Sanitária" (ver `Status do catálogo hoje`) | Avaliar se a NBR 5626 deveria ser citada como base técnica complementar à vigilância sanitária no item já existente, não como item novo |
| `/norms` (página estática) | Ausente | Adicionar só depois de resolver a pendência de status — não faz sentido publicar uma norma pro público com status ambíguo |
| Produto (funcionalidade) | O item CAIXA_DAGUA já existe e é funcional — essa norma reforça a base técnica dele, não expõe gap novo de funcionalidade | Nenhuma ação de produto |

**Pendência**: resolver a contradição "vigente" vs. aviso de "cancelada em 06/2020" direto com
texto oficial ABNT ou uma segunda fonte de catálogo, antes de usar essa norma em qualquer alegação
pública do produto.

---

### NBR 17240 — Sistemas de Detecção e Alarme de Incêndio — Projeto, Instalação, Comissionamento e Manutenção — Requisitos

**Status**: ✅ **Resolvida** (era 🔍 no levantamento inicial). **Vigente**, edição **2010**,
confirmada periodicamente pela ABNT (últimas confirmações registradas: 2014, 2020, 02/2025) — não
existe edição nova publicada apesar de já haver um projeto de revisão em andamento na CB-24 (PN
17240), sem data prevista. O aviso de "cancelada" que aparece nas buscas genéricas é sobre a norma
**anterior, NBR 9441:1998**, que a 17240:2010 cancelou e substituiu — exatamente o mesmo padrão de
ruído já identificado na NBR 14037 (edição velha superada por revisão da mesma norma ≠ norma
morta). Confirmado direto no catálogo normas.com.br, técnica já validada nas rodadas anteriores.

**O que a norma exige:**

1. Escopo: projeto, instalação, comissionamento e manutenção de sistemas **manuais e automáticos**
   de detecção e alarme de incêndio.
2. Especifica componentes do sistema: centrais de alarme, detectores (fumaça, calor, chama),
   acionadores manuais, e como eles se interconectam.
3. Exige **fontes de alimentação redundantes** — o sistema precisa continuar funcionando mesmo em
   caso de falha da energia principal (bateria/fonte auxiliar).
4. Cobre todo o ciclo: planejamento, instalação, comissionamento (testes de aceitação antes de
   entrar em operação), treinamento dos usuários, e manutenção/inspeção periódica do sistema já
   instalado.

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | O item `ALARME` já existe no catálogo hoje, mas citando **CBMMG IT-16** (Corpo de Bombeiros de MG) como base — já flagado no Achado #2 (regionalização) | A NBR 17240 é a base técnica **nacional** que os ITs estaduais complementam — recomendo citar a NBR 17240 como base primária no item `ALARME`, com o IT estadual como complemento regional, não o contrário como está hoje |
| `/norms` (página estática) | Ausente | Adicionar, já que reforça exatamente o item ALARME que o produto já cobre funcionalmente |
| Produto (funcionalidade) | Item já existe e funciona — essa norma só corrige/reforça a base de citação, não expõe gap de funcionalidade | Nenhuma ação de produto, só de conteúdo/citação |

**Pendência**: nenhuma nova — essa norma resolveu de forma limpa. Vale reaproveitar a mesma técnica
pra NBR 12693 (ainda 🔍 no levantamento inicial) na próxima rodada.

---

### NBR 16083 — Manutenção de Elevadores, Escadas Rolantes e Esteiras Rolantes — Requisitos para Instruções de Manutenção

**Status**: ✅ **Resolvida** (era 🔍 no levantamento inicial, com uma fonte secundária fraca
afirmando "cancelada em julho de 2012"). Consultei o normas.com.br diretamente — a página mostra o
mesmo padrão de aviso "foi cancelada" ligado à data da **primeira edição** (07/2012), mas lista
confirmações da ABNT em 10/2016, 07/2020 e **01/2025**. Uma norma recebendo confirmação da ABNT em
janeiro de 2025 não é uma norma cancelada — é o mesmo padrão de ruído já visto e resolvido nas NBR
14037 e NBR 17240 (o aviso do site parece ser um texto padrão ligado à edição original, não um
status real). Reforcei isso cruzando com uma segunda linha de evidência independente: pesquisei se
alguma norma nova substituiu a 16083 nesse escopo específico (instruções de manutenção) e não achei
nenhuma — o que existe é a **NBR 16858** (2020, vigência adiada pra 04/2024), mas essa trata de
**instalações novas** de elevadores (substituindo NM207/NM267/NBR 16042), um escopo diferente do da
16083 (manutenção de elevadores já instalados). Concluo com confiança razoável: **NBR 16083:2012
está vigente**, confirmada pela última vez em 01/2025.

**O que a norma exige:**

1. Especifica os elementos necessários pra elaboração das **instruções de manutenção** de
   elevadores, escadas rolantes e esteiras rolantes — o que deve e o que não deve estar incluído no
   escopo de manutenção contratado.
2. Define obrigações tanto do **condomínio** quanto da **empresa de manutenção** — dupla
   responsabilidade, não só do prestador de serviço.
3. Manutenção preventiva mensal por profissional habilitado é citada como prática associada
   (algumas fontes secundárias tratam isso como exigência da norma; não confirmei se o texto oficial
   define "mensal" como valor normativo ou se é praxe de mercado — mesma cautela já aplicada à
   NBR 16747).
4. Itens tipicamente cobertos pela instrução de manutenção: componentes de segurança, freios,
   cabos, sensores, portas automáticas, lubrificação, comandos eletrônicos.

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | Não há item de elevador no catálogo hoje (confirmar contra a lista completa de `itemType`) | Avaliar se elevador deveria virar item novo — é comum em condomínios verticais, o segmento principal do produto |
| `/norms` (página estática) | Já presente (📄, conforme levantamento inicial) — mas com uma ressalva já flagada: uma fonte secundária alegava cancelamento. Com a resolução desta rodada, **a entrada pode continuar publicada com confiança** | Nenhuma correção de status necessária; revisar só o texto descritivo se citar periodicidade "mensal" como normativa sem ressalva |
| Produto (funcionalidade) | Se elevador não é item do catálogo, é um gap de funcionalidade real pra condomínios verticais — mas isso é uma decisão de produto, não uma correção de conteúdo | Observação para Douglas, não ação automática |

**Pendência**: confirmar se "mensal" é valor normativo da NBR 16083 ou prática de mercado citada
por terceiros (mesma cautela da 16747); confirmar se elevador já existe como possível `itemType` no
catálogo antes de sugerir adição.

---

### NBR 12693 — Sistemas de Proteção por Extintores de Incêndio

**Pendência de identidade resolvida**: ✅ **NBR 12693 é uma norma distinta da NBR 12962**, não uma
duplicata. A 12693 trata de **projeto, seleção e instalação** de sistemas de extintores
(dimensionamento, capacidade extintora, distância máxima a percorrer por classe de risco). A NBR
12962 (já citada como base do item `EXTINTOR` no catálogo) trata de **inspeção, manutenção e
recarga** de extintores já instalados. São complementares, no mesmo padrão já visto em outras
duplas normativas (ex.: NBR 5626 cobre projeto+manutenção junto, mas aqui o extintor tem a
separação em duas normas). Como o produto rastreia manutenção recorrente de itens já instalados, a
citação correta pro `EXTINTOR` continua sendo a NBR 12962 — a 12693 seria relevante só se o produto
algum dia cobrisse dimensionamento/projeto de novos sistemas, o que está fora do escopo atual.

**Status**: ⚠️ **Ambíguo — não resolvido nesta rodada**, diferente das últimas duas normas. O
normas.com.br mostra a edição 01/2021 com o mesmo aviso "foi cancelada e seu uso pode trazer
riscos" já visto nas outras consultas — mas, diferente da 17240 e da 16083 (que tinham
confirmações registradas até 2025), não encontrei nenhuma confirmação posterior a 2021 pra essa
norma especificamente, em nenhuma fonte consultada. Isso quebra o padrão que vinha permitindo
resolver a ambiguidade com confiança — aqui a ausência de confirmação recente é um sinal
genuinamente diferente, não apenas ruído do aviso padrão do site. Fica como pendência real de
verificação direta com a ABNT.

**O que a norma exige (independente da pendência de status):**

1. Requisitos de projeto, seleção e instalação de extintores portáteis e sobre rodas, em
   edificações e áreas de risco, pra combate a princípio de incêndio.
2. Capacidade extintora, distância máxima a percorrer, considerando classe de risco da área
   protegida e natureza do fogo.
3. Extintores são exigidos como primeira linha de resposta **mesmo quando** o local já tem
   chuveiros automáticos (sprinklers), hidrantes/mangueiras ou outro sistema fixo — não substitui,
   complementa.

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | Item `EXTINTOR` já cita NBR 12962 corretamente (norma de manutenção, não a de projeto) | Nenhuma correção — a citação atual já está certa, a 12693 não precisa ser adicionada |
| `/norms` (página estática) | N/A — mesma lógica do banco | Nenhuma ação |
| Produto (funcionalidade) | Nenhum gap — produto não cobre dimensionamento/projeto de sistemas novos, então a 12693 é fora de escopo por natureza | Nenhuma ação |

**Pendência**: confirmar status real da NBR 12693:2021 direto com a ABNT antes de citá-la em
qualquer contexto (mesmo que hoje ela não seja usada em nenhuma alegação do produto).

---

### NBR 9050 — Acessibilidade a Edificações, Mobiliário, Espaços e Equipamentos Urbanos

**Status**: ✅ Analisada (19/08/2026). **Vigente**, confirmado direto no buscanormas.com.br
("NBR 9050 (Vigente)"). Edição atual **2020, Versão Corrigida 2021** (Errata 1, 25/01/2021) —
equivale à consolidação da NBR 9050:2015 + Emenda 1 (03/08/2020). Status limpo, sem ambiguidade
nas fontes consultadas.

**O que a norma exige:**

1. Critérios e parâmetros técnicos pra projeto, construção, instalação e **adaptação** de
   edificações e espaços urbanos às condições de acessibilidade — rampas, elevadores acessíveis,
   banheiros/cozinhas dimensionados pra cadeirantes, rotas acessíveis desde o estacionamento até a
   entrada principal, sinalização visual e tátil, vagas de estacionamento exclusivas.
2. Em condomínios residenciais multifamiliares: **áreas de uso comum** precisam ser acessíveis
   (entradas, funções principais das áreas comuns). Áreas técnicas de acesso restrito (casa de
   máquinas, barrilete, passagem técnica e afins) **não** precisam ser acessíveis.
3. Diferente de quase toda outra norma revisada até agora, a NBR 9050 tem **força legal direta**,
   não apenas referência técnica: **Decreto Federal 5.296/2004** e a **Lei Brasileira de Inclusão
   (Lei 13.146/2015)** determinam que espaços de uso coletivo sigam a norma, tornando-a referência
   obrigatória — não apenas recomendada — para síndicos e gestores. Confirma e reforça o achado já
   registrado no levantamento inicial (seção E).
4. Vale mesmo pra edificações **já existentes**: o Decreto 5.296/2004 exige adaptação progressiva
   pra garantir acessibilidade, não só em obras novas — reforma/ampliação de edificação existente
   também precisa seguir a norma.
5. Responsabilidade recai sobre o síndico — descumprimento pode gerar multas, ações civis e, em
   casos extremos, interdição da edificação.

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | ❌ Ausente — mas essa norma **não é periódica por natureza** (é critério de projeto/adaptação, não item de manutenção recorrente), então tem o mesmo problema estrutural já visto em 5674/14037/16280: não cabe no schema atual | Não força adição ao banco — observação estrutural, não gap de conteúdo |
| `/norms` (página estática) | ❌ Ausente | Recomendo fortemente adicionar — é a norma com **força legal mais direta** de todo o levantamento até agora, e reforça a mensagem de responsabilidade legal do síndico que já é usada em outras partes do produto (ex.: blog NBR 5674) |
| Produto (funcionalidade) | Não existe hoje nenhuma trilha de "conformidade de acessibilidade" no produto — mas, assim como a 16747, isso é uma verificação pontual/qualitativa, não um item recorrente de manutenção. Observação, não recomendação de feature agora | Nenhuma ação imediata |

**Pendência**: nenhuma relevante — essa norma resolveu de forma limpa e sem contradição entre
fontes.

---

### NBR 13103 — Instalação de Aparelhos a Gás — Requisitos

**Status**: ✅ Analisada (19/08/2026). **Vigente**, edição atual **6ª edição, 03/2024** — a
ABNT NBR 13103:2024 cancela e substitui explicitamente a NBR 13103:2020 (que por sua vez tinha
substituído a versão 2011+emenda 2013). Uma busca genérica trouxe de novo o mesmo padrão de ruído
já visto várias vezes ("norma cancelada em 03/2024") — mas aqui a própria fonte deixa claro que
03/2024 é a data de publicação da **edição nova que substituiu a anterior**, não um cancelamento
sem sucessora. Resolvido com confiança alta.

**O que a norma exige:**

1. Requisitos mínimos pra **projeto, execução, vistoria, manutenção, operação e abandono** de
   instalações internas de gás combustível em edificações residenciais.
2. Escopo específico: aparelhos a gás com pressão nominal até 2,0 kPa (gás natural) ou 2,8 kPa
   (GLP) — cobre a instalação interna da unidade/edificação, não a rede de distribuição externa.
3. A edição 2024 ampliou o escopo em relação à 2020: passou a cobrir **toda a instalação** (antes
   era focada só em requisitos de ambiente), com mais detalhamento por tipo de aparelho.
4. **Achado de cruzamento entre normas**: a própria NBR 13103 remete à **NBR 15923** pra definir
   periodicidade e procedimento das inspeções periódicas — ou seja, 13103 é a norma de
   requisitos/instalação, e 15923 é quem define o "de quanto em quanto tempo inspecionar". Isso já
   antecipa que a análise da NBR 15923 (próxima da seção C-bis) vai ser a peça que efetivamente
   define a periodicidade usável no catálogo do produto, não a 13103 isoladamente.

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | ❌ Ausente — confirma o gap já flagado no levantamento inicial (Achado C-bis: nada relacionado a gás no catálogo, apesar de ser item comum e claramente periódico) | Gap real — mas a periodicidade certa pra usar no `periodQty`/`periodUnit` vem da NBR 15923, não da 13103; aguardar a análise dela antes de propor o item completo |
| `/norms` (página estática) | ❌ Ausente | Mesma lógica — melhor adicionar as duas (13103 + 15923) juntas, como par requisito+periodicidade, do que a 13103 isolada |
| Produto (funcionalidade) | Gap de funcionalidade real: instalação de gás é item comum em condomínios e não tem nenhuma representação hoje | Observação para Douglas — decisão de produto, não ação automática |

**Pendência**: nenhuma sobre a 13103 em si — mas o item fica "incompleto" até a NBR 15923 ser
analisada (é ela que define a periodicidade concreta que o catálogo precisaria).

---

### NBR 15923 — Inspeção de Rede de Distribuição Interna de Gases Combustíveis em Instalações Residenciais e Instalação de Aparelhos a Gás para Uso Residencial — Procedimento

**Status**: ✅ **Resolvida com confiança alta**. O normas.com.br mostra o mesmo aviso padrão de
"cancelada em 02/2011" já visto em outras 4 normas deste levantamento (5626, 17240, 16083, 12693) —
mas aqui a evidência de que é ruído de boilerplate, não status real, é a mais forte até agora:
confirmações registradas em **12/2015, 12/2019 e 07/2024** (a mais recente é de só um mês antes da
5ª edição da NBR 13103, coincidência que reforça a leitura). Além disso, a **própria NBR 13103:2024
— norma nova, publicada há poucos meses — continua remetendo à NBR 15923** como procedimento de
inspeção periódica vigente. A ABNT não referenciaria uma norma morta numa revisão recém-publicada.
Concluo com confiança: **NBR 15923:2011 está vigente**, confirmada pela última vez em 07/2024.

**O que a norma exige:**

1. Requisitos mínimos pra **inspeção** de rede de distribuição interna de gases combustíveis em
   instalações residenciais (partes comuns e individuais) e instalação de aparelhos a gás
   residenciais — inclui adequação dos ambientes que os contêm e exaustão dos produtos de
   combustão.
2. Situações em que a inspeção se aplica: inspeção periódica de redes já em uso; troca de tipo ou
   fornecedor de gás; reforma ou ampliação; substituição ou instalação de novo aparelho; liberação
   de rede nova para comissionamento.
3. **Periodicidade concreta encontrada** (atribuída à NBR 13103, que é quem efetivamente define o
   prazo pro aparelho, com a 15923 fornecendo o procedimento de como inspecionar): manutenção
   preventiva do aparelho a gás a cada **12 meses**, ou conforme instrução do fabricante — vale o
   prazo mais curto entre os dois. Itens verificados: limpeza do aparelho, conexão com a rede
   interna (estanqueidade, vazamentos, validade), conexões de água quente/fria, conexões elétricas,
   sistema de exaustão (oxidação, amassados, furos), limpeza de filtro, área de ventilação
   permanente, sistema de combustão.
4. Descumprimento da manutenção preventiva pode gerar **perda de garantia** do aparelho —
   argumento de valor prático pra síndico/gestor, além da segurança.

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | ❌ Ausente — agora com periodicidade concreta e verificada: **12 meses**, item claramente compatível com o schema atual (`periodQty=12`, `periodUnit=MESES` ou equivalente) | **Gap real e acionável** — diferente da 5674/14037/16280 (que não cabiam no schema), esse item pode ser adicionado como está, citando NBR 13103 (requisito) + NBR 15923 (procedimento de inspeção) juntas |
| `/norms` (página estática) | ❌ Ausente | Adicionar — par 13103+15923, com a periodicidade de 12 meses como diferencial concreto |
| Produto (funcionalidade) | Gap de funcionalidade real, e agora com dado suficiente pra ser implementado como item de catálogo completo (diferente do gap "estrutural" das normas de gestão) | Observação pra Douglas: esse é o item de gás mais pronto pra virar `itemType` novo no catálogo, dos 3 pesquisados na seção C-bis |

**Pendência**: nenhuma relevante — essa é a norma do levantamento até agora com o achado mais
diretamente acionável (periodicidade concreta e verificada). Falta só a NBR 15526 pra fechar a
seção C-bis (gás) por completo.

---

### NBR 15526 — Redes de Distribuição Interna para Gases Combustíveis em Instalações Residenciais e Comerciais — Projeto e Execução

**Status**: ✅ **Resolvida com confiança alta**. Mesmo aviso padrão de "cancelada em 12/2012" —
mas o histórico de edições encontrado direto no catálogo é o mais completo e conclusivo de todo o
levantamento até agora: **2007 → 2009 → 2012 → 2016 → confirmação 2022 → nova edição em 02/2026**.
Uma norma recebendo uma edição nova publicada em fevereiro deste ano é, por definição, uma norma
viva e ativamente mantida pela ABNT — o oposto de cancelada. O aviso "cancelada em 12/2012" é o
mesmo padrão de boilerplate (ligado à edição específica daquela data, superada por revisões
seguintes da mesma norma) já visto em 5 outras normas neste levantamento. **NBR 15526 está
vigente, edição atual 2026** (substituindo a 2016).

**O que a norma exige:**

1. Requisitos mínimos pra **projeto e execução** de redes de distribuição interna de gases
   combustíveis em instalações residenciais e comerciais, com pressão de operação até 150 kPa —
   gás natural (GN) e GLP (propano/butano) em fase vapor, e mistura ar-GLP.
2. Define materiais permitidos, critérios de seleção de tubulação e componentes, proteção contra
   corrosão e danos mecânicos.
3. Tubulação enterrada ou em áreas molhadas da edificação precisa de revestimento adequado
   (asfáltico, plástico, pintura epóxi) ou proteção catódica.
4. É a norma "irmã" da NBR 13103: a 15526 trata da **rede/tubulação** (projeto e execução física),
   enquanto a 13103 trata dos **aparelhos e sua instalação/manutenção**, e a 15923 do
   **procedimento de inspeção**. As três juntas cobrem o ciclo completo de gás combustível predial.

**Cruzamento com o que temos hoje — fecha a seção C-bis (gás):**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | ❌ Ausente — mas essa é mais uma norma de **projeto/execução** (como a 12693 de extintores), não de manutenção recorrente. A periodicidade acionável pro catálogo já veio da NBR 15923 (12 meses), não da 15526 | Não é ela quem define o item de catálogo — a 15526 seria citada como referência técnica complementar de instalação, não como base do item periódico |
| `/norms` (página estática) | ❌ Ausente | Se um item de gás for adicionado à página (par 13103+15923, já recomendado), a 15526 pode entrar como terceira referência técnica complementar, não como entrada própria |
| Produto (funcionalidade) | Nenhum gap novo além do já identificado na 15923 | Nenhuma ação adicional |

**Resumo da seção C-bis (gás combustível) agora completa**: 3 normas pesquisadas, todas vigentes
(com o mesmo padrão de aviso "cancelada" resolvido como ruído em todas), formando um conjunto
coerente — NBR 13103 (aparelhos, com periodicidade de 12 meses), NBR 15923 (procedimento de
inspeção), NBR 15526 (rede/tubulação, projeto e execução). Confirma o Achado C-bis original: gás é
um gap real e agora **totalmente especificado** — item de catálogo pronto pra ser proposto, citando
as 3 normas juntas.

**Pendência**: nenhuma.

---

### RDC 15/2012 (ANVISA) — Requisitos de Boas Práticas para o Processamento de Produtos para Saúde

**Status**: ✅ Analisada (19/08/2026). **Vigente**, sem indicação de revogação nas fontes
consultadas (diferente das normas ABNT, resoluções ANVISA não seguem o mesmo padrão de
"confirmação periódica" — aqui a ausência de revogação publicada é o sinal relevante, não um
selo de "vigente" explícito). Publicada em 15/03/2012, motivou a revisão/uniformização de
resoluções anteriores (RDC 156/2006, RE 2605/2006, RE 2606/2006).

**Achado de escopo importante, antes do conteúdo**: essa RDC trata principalmente do
**processamento clínico** de produtos para saúde (limpeza, desinfecção, esterilização de
instrumentos cirúrgicos) — é majoritariamente uma norma de **prática assistencial/operacional**,
não de manutenção predial. A interseção real com o escopo do produto (manutenção de edificações e
seus sistemas) é mais estreita do que as normas ABNT já revisadas: só a parte de **manutenção e
calibração dos equipamentos** do CME (Central de Material e Esterilização) é diretamente
relevante — o resto (protocolos de limpeza, classificação de risco de instrumentos, etc.) é fora do
domínio de "manutenção" que o produto cobre.

**O que a norma exige (focado na parte relevante ao produto):**

1. Aplica-se a Centrais de Material e Esterilização (CME) de serviços de saúde públicos e privados,
   civis e militares, e empresas processadoras — exclui consultórios odontológicos individuais não
   vinculados a serviço de saúde, unidades de endoscópios, terapia renal substitutiva, e serviços
   veterinários.
2. **Plano de manutenção preventiva** obrigatório pra autoclaves e equipamentos de esterilização,
   seguindo recomendação do fabricante + a própria RDC.
3. **Qualificação térmica e calibração** dos instrumentos de controle/medição (manômetro,
   pressostato, sensor de temperatura, válvula de segurança) de equipamentos de esterilização a
   vapor/termodesinfecção — periodicidade **mínima anual**, executada por laboratório qualificado.
4. Registro obrigatório das intervenções técnicas por equipamento, com prazo de arquivamento
   contado a partir da desativação ou transferência definitiva do equipamento do serviço.
5. Exige sistema de informação (manual ou automatizado) com registro de monitoramento das etapas de
   processamento **e** da manutenção/monitoramento dos equipamentos.

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | ❌ Ausente — mas, assim como a NBR 15923 (gás), essa tem periodicidade concreta e verificada (**mínima anual**), compatível com o schema atual | Item de catálogo específico pra hospitais: "Autoclave/Equipamento de Esterilização" com base na RDC 15/2012, periodicidade mínima 12 meses |
| `/norms` (página estática) | ❌ Ausente (confirma o Achado #1 original: nenhuma norma hospitalar está no catálogo funcional) | Adicionar — mas com o cuidado de descrever especificamente a parte de manutenção de equipamento, não o processamento clínico completo (que foge do que o produto faz) |
| Produto (funcionalidade) | Gap real e agora acionável — mas junto com uma decisão de escopo maior: o segmento "hospitais" do produto hoje não tem NENHUM item de catálogo específico (nem esse, nem os das RDCs já mapeadas 50/63) | Reforça a necessidade de uma conversa de escopo sobre o segmento hospitalar como um todo, não só essa norma isoladamente |

**Pendência**: nenhuma sobre o conteúdo em si — mas fica reforçada a necessidade de decidir, com
Douglas, até onde o produto vai no segmento hospitalar (só equipamentos prediais genéricos
adaptados, ou também equipamentos clínicos como autoclave) antes de propor esse item específico.

---

### RDC 222/2018 (ANVISA) — Regulamenta as Boas Práticas de Gerenciamento dos Resíduos de Serviços de Saúde (PGRSS)

**Status**: ✅ **Vigente**, confirmado por múltiplas fontes convergentes. Publicada 28/03/2018,
entrou em vigor 25/09/2018 (180 dias após publicação), **revogou expressamente a RDC 306/2004**
(que era a norma anterior sobre o mesmo tema) — diferente do padrão "confirmação periódica" das
normas ABNT, aqui a substituição é explícita e documentada, sem ambiguidade.

**Achado de escopo — mais distante do domínio do produto do que a RDC 15/2012**: essa RDC é quase
inteiramente sobre **gestão de resíduos** (Plano de Gerenciamento de Resíduos de Serviços de Saúde
— PGRSS): geração, identificação, segregação, acondicionamento, coleta, armazenamento, transporte,
destinação final. É uma norma de **processo operacional/ambiental**, não de manutenção de
equipamento ou sistema predial. A única interseção real com "manutenção predial" é um requisito
**construtivo pontual** (não recorrente) sobre a infraestrutura física do abrigo de resíduos.

**O que a norma exige (focado na parte com alguma relevância ao produto):**

1. Aplica-se a qualquer gerador de resíduos de serviço de saúde — hospitais, clínicas, mas também
   serviços de estética, piercing, e qualquer atividade que gere resíduo similar, público ou
   privado.
2. Exige documento formal (PGRSS) cobrindo todo o ciclo do resíduo, com foco em segurança de
   trabalhadores, saúde pública e meio ambiente.
3. **Requisito construtivo do abrigo temporário de resíduos** (o único ponto com alguma
   proximidade de "infraestrutura predial"): piso e paredes revestidos de material resistente,
   lavável e impermeável; ponto de iluminação artificial e de água; tomada elétrica alta; ralo
   sifonado com tampa; identificação obrigatória "ABRIGO TEMPORÁRIO DE RESÍDUOS".
4. Esse requisito é de **adequação construtiva** (fazer certo uma vez), não de manutenção
   periódica recorrente — não tem um "a cada X meses" associado, diferente de quase toda norma já
   revisada até agora.

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | Não se aplica — não há item periódico real pra extrair dessa norma, ao contrário da RDC 15/2012 | Nenhuma ação |
| `/norms` (página estática) | Ausente | **Não recomendo adicionar** — é uma norma de gestão de resíduos, fora do domínio "manutenção" que dá sentido ao produto anunciar; incluir arriscaria diluir a mensagem do produto com algo que ele não endereça |
| Produto (funcionalidade) | Nenhum gap de manutenção — a única peça (infraestrutura do abrigo) é adequação construtiva pontual, não um item de manutenção recorrente | Nenhuma ação |

**Conclusão da seção F (hospitais/ANVISA) até agora**: das 4 RDCs mapeadas no levantamento inicial
(50/2002, 63/2011, 15/2012, 222/2018), a 15/2012 foi a única com um item de manutenção periódica
real e acionável (calibração de autoclave, anual). A 222/2018 confirma que **nem toda norma
relevante ao segmento hospitalar cabe no domínio do produto** — reforça a necessidade da conversa
de escopo com Douglas antes de qualquer ajuste na tabela de normas pro segmento hospital.

**Pendência**: nenhuma sobre o conteúdo — a decisão de escopo pro segmento hospitalar (já
sinalizada na análise da RDC 15/2012) continua em aberto.

---

### NBR 16785 — Correção de premissa do levantamento inicial (não é norma de incêndio)

**Achado principal desta rodada**: a hipótese registrada no levantamento inicial — "possível
sucessora/complemento da NBR 17240" (detecção/alarme de incêndio) — **estava errada**. NBR 16785 é
**Proteção contra Descargas Atmosféricas — Sistemas de Alerta de Tempestades Elétricas**: uma norma
sobre sistemas de **alerta de raios/tempestades** (dados em tempo real sobre descargas atmosféricas
ou eletrificação de nuvens, pra programar medidas preventivas), sem nenhuma relação com detecção de
incêndio. É prima da NBR 5419 (SPDA) por estar no mesmo domínio de proteção contra descargas
atmosféricas, não da 17240.

**Status**: ✅ Vigente. Edição única 09/2019, com confirmação registrada em 03/2024 — mesmo padrão
de aviso "cancelada" já resolvido como boilerplate em 6 outras normas deste levantamento.

**O que a norma exige**: características de sistemas de alerta que captam dados em tempo real
sobre atividade elétrica atmosférica e tratam essa informação pra permitir ações preventivas
(evacuação de áreas abertas, suspensão de atividades ao ar livre) antes da queda de raios.

**Cruzamento com o que temos hoje e relevância ao produto**: **fora do escopo do produto**. É uma
norma voltada a **áreas abertas** (estádios, eventos, áreas externas expostas) — não é um sistema
predial interno, não tem periodicidade de manutenção recorrente no sentido que o catálogo modela, e
não se aplica ao universo de condomínio/hospital/escola/indústria da forma como o produto opera
hoje (foco em sistemas e itens dentro da edificação). Não recomendo adicionar ao banco nem à página
estática.

**Ação de correção**: a entrada da NBR 16785 na seção B do levantamento inicial (`❌, possível
sucessor/complemento a 17240`) deve ser lida como corrigida por esta análise — não é sucessora nem
complemento da 17240, é norma de domínio diferente (descargas atmosféricas/alerta de tempestade),
sem relevância prática ao produto.

**Pendência**: nenhuma — item encerrado, sem necessidade de retomar.

---

### NBR 9077 — Saídas de Emergência em Edifícios (Projeto de Saídas de Emergência)

**Status**: ✅ Analisada (19/08/2026). **Vigente**, confirmado direto no buscanormas.com.br
("NBR 9077 (Vigente)"). Edição **2025** (publicada 16/07/2025), cancela e substitui a edição
2001 — atualização recente e significativa: o dimensionamento deixou de ser baseado só no tipo de
ocupação e passou a considerar características dos ocupantes (mobilidade, estado de vigília,
familiaridade com o edifício). Status limpo, sem ambiguidade.

**O que a norma exige:**

1. Procedimentos pra **projeto** dos meios de circulação que garantem abandono seguro dos
   ocupantes em caso de incêndio — acessos, corredores, escadas, rampas, antecâmaras, desde o
   ponto mais remoto de qualquer pavimento até a via pública/área externa segura.
2. Aplica-se a **qualquer tipo de edificação**, independente de ocupação, altura ou área
   construída — residencial, comercial, industrial, hospitalar, escolar, uso misto. É a norma mais
   transversal aos 4 segmentos do produto encontrada até agora.
3. Critérios de dimensionamento de rota de fuga, distância máxima a percorrer, iluminação de
   emergência (conecta diretamente com o item `ILUMINACAO_EMERGENCIA` já existente no catálogo,
   hoje citando NBR 10898) e sinalização obrigatória.
4. **Manutenção/inspeção**: fontes secundárias convergem que a gestão das rotas de fuga deve ser
   contínua — desobstrução permanente, inspeções periódicas pra identificar e corrigir obstrução ou
   dano, regulagem/substituição de elementos fora de condições de funcionamento. **Não encontrei um
   valor numérico de periodicidade definido no próprio texto da norma** nas fontes consultadas —
   mesma cautela já aplicada à NBR 16747 (norma define o dever, não um prazo fixo universal).
5. Responsabilidade recai sobre síndico/administrador — omissão/negligência comprovada pode gerar
   responsabilização civil e criminal, mesmo padrão de gravidade já visto na 5674/16747.

**Cruzamento com o que temos hoje:**

| Onde | Situação | Ação sugerida |
|---|---|---|
| `norms` table (banco) | ❌ Ausente como norma própria — mas o item `ILUMINACAO_EMERGENCIA` já existe e é adjacente (a 9077 é quem define os critérios de rota que a iluminação de emergência precisa atender) | Citar a NBR 9077 como referência complementar no item `ILUMINACAO_EMERGENCIA`, não como item novo — sem periodicidade própria, não caberia como item isolado |
| `/norms` (página estática) | ❌ Ausente | Recomendo adicionar — é a norma mais transversal aos 4 segmentos encontrada até agora, e reforça a narrativa de responsabilidade legal do síndico já usada em outros conteúdos |
| Produto (funcionalidade) | Nenhum gap de manutenção recorrente novo — desobstrução de rota de fuga é mais checklist qualitativo (ex.: vistoria) do que item com `periodQty` fixo | Observação, não recomendação de feature agora |

**Pendência**: confirmar se a norma define algum prazo numérico de inspeção periódica no texto
oficial (não encontrado nas fontes secundárias consultadas) antes de qualquer alegação de
periodicidade específica.
