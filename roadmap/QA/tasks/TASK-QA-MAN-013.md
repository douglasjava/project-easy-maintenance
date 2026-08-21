# TASK-QA-MAN-013 — QA Manual: filtro determinístico de catálogo no onboarding por IA (EPIC-025 Fase 2)

## Tipo
QA Manual

## Categoria
Backend + Frontend / Onboarding por IA

## Prioridade
🔴 Crítico

## Épico
[EPIC-025](../../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas (Fase 2)

## Tasks cobertas
[TASK-181](../../tasks/TASK-181.md) (tabela `norm_segments`) ·
[TASK-182](../../tasks/TASK-182.md) (`POST /ai/bootstrap/catalog-preview`) ·
[TASK-183](../../tasks/TASK-183.md) (bugfix `nextDueAt`/`customPeriod*`) ·
[TASK-184](../../tasks/TASK-184.md) (IA complemento — dedupe + `normId` explícito) ·
[TASK-185](../../tasks/TASK-185.md) (frontend `/ai-onboarding` em duas camadas) ·
[TASK-186](../../tasks/TASK-186.md) (experiência mobile — cards no lugar da tabela)

Spec completa: `docs/superpowers/specs/2026-08-20-onboarding-catalog-filter-design.md`.

---

## Descrição

Valida o redesenho do onboarding assistido por IA: filtro determinístico do catálogo (instantâneo,
sem custo de IA) como caminho principal, IA só como complemento opcional pro que o texto livre
descreve além do catálogo. Os dois pontos mais críticos: (1) o bug de `nextDueAt` — item REGULATORY
tem que nascer com a data de vencimento certa, calculada pela norma real, não por um número
inventado; (2) a IA não pode duplicar o que o catálogo já trouxe.

Toda a Fase 2 está numa branch só nos dois repos: `feature/ai-onboarding-catalog-filter`
(`easy-maintenance-api` e `easy-maintenance-web`). Ainda sem PR — testar local primeiro, depois em
staging.

---

## Pré-condições

- Checkout da branch `feature/ai-onboarding-catalog-filter` nos dois repos, rodando local (api +
  web apontando um pro outro).
- Migration `V91__create_norm_segments.sql` aplicada (roda automático ao subir a API — Flyway).
- Usuário/organização de teste com plano que tenha créditos de IA disponíveis (`aiMonthlyCredits >
  0` e ainda não esgotados no mês) — necessário só pros cenários que envolvem IA (C4, C5, C6).
- Acesso ao DevTools (aba Network) do navegador, pra confirmar quais chamadas disparam em cada
  cenário.
- Se possível, acesso a um client SQL no banco local, pra rodar as queries de verificação do C1.

---

## Cenários de Teste

### C1 — `norm_segments` populada corretamente

| Passo | Ação                                                                                                         | Resultado esperado                                                                            |
|-------|--------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| 1     | Rodar `SELECT company_type, COUNT(*) FROM norm_segments GROUP BY company_type;`                              | CONDOMINIO=26, HOSPITAL=25, ESCOLA=25, INDUSTRIA=26, ESCRITORIO=26 (nenhuma linha pra OUTROS) |
| 2     | Rodar `SELECT n.item_type FROM norms n LEFT JOIN norm_segments ns ON ns.norm_id = n.id WHERE ns.id IS NULL;` | Vazio — todo `item_type` de `norms` tem pelo menos 1 segmento                                 |

---

### C2 — Filtro instantâneo, sem descrição (CONDOMINIO)

| Passo | Ação                                                                                                                | Resultado esperado                                                                                                     |
|-------|---------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| 1     | Abrir `/ai-onboarding`, escolher "Condomínio", deixar a descrição em branco, clicar em "Gerar pré-cadastros com IA" | Etapa 2 abre quase instantaneamente (sem spinner longo)                                                                |
| 2     | Conferir a aba Network                                                                                              | Só houve chamada a `POST /ai/bootstrap/catalog-preview` — nenhuma chamada a `/ai/bootstrap/preview` nem a `/ai/jobs/*` |
| 3     | Conferir a tabela                                                                                                   | Todas as linhas têm o badge "✅ Catálogo"; nenhum indicador "Buscando sugestões adicionais com IA..." aparece           |
| 4     | Conferir a quantidade de itens                                                                                      | Bate com a contagem de CONDOMINIO do C1 (26, salvo item já removido/desmarcado manualmente antes)                      |

---

### C3 — Segmento "Outro" retorna catálogo vazio (comportamento esperado, não bug)

| Passo | Ação                                                                                                        | Resultado esperado                                                                                                                                        |
|-------|-------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Escolher "Outro", sem descrição, gerar                                                                      | Etapa 2 abre com a tabela vazia — nenhum item, nenhum erro                                                                                                |
| 2     | Escolher "Outro", com uma descrição livre (ex.: "prédio comercial com estacionamento e restaurante"), gerar | Etapa 2 abre vazia primeiro, depois os itens sugeridos pela IA aparecem (badge "✨ IA") — só a IA cobre esse segmento, por não ter perfil predial definido |

---

### C4 — IA como complemento (com descrição)

| Passo | Ação                                                                                      | Resultado esperado                                                                                                                                                |
|-------|-------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Escolher "Condomínio", descrição "tenho piscina e sistema de câmeras de segurança", gerar | Etapa 2 abre na hora com os itens do catálogo (badge "✅ Catálogo")                                                                                                |
| 2     | Observar o topo da tabela logo em seguida                                                 | Indicador "🔄 Buscando sugestões adicionais com IA..." aparece                                                                                                    |
| 3     | Aguardar o job terminar (alguns segundos, até 90s)                                        | Itens novos relacionados a piscina/câmeras são anexados à tabela, com badge "✨ IA" — os itens do catálogo já exibidos continuam lá, sem sumir ou resetar          |
| 4     | Conferir a aba Network                                                                    | Duas chamadas: `POST /ai/bootstrap/catalog-preview` (imediata) e `POST /ai/bootstrap/preview` + polling em `/ai/jobs/{jobId}` (só essa segunda usa crédito de IA) |

---

### C5 — Dedupe determinístico: IA não repete item do catálogo

| Passo | Ação                                                                                                            | Resultado esperado                                                                                                                                                                                               |
|-------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Escolher "Condomínio", descrição "tenho extintores, hidrantes e piscina" (extintor/hidrante já vêm do catálogo) | Etapa 2 abre com o catálogo primeiro                                                                                                                                                                             |
| 2     | Aguardar a IA complementar                                                                                      | Só aparece 1 linha de EXTINTOR e 1 de HIDRANTE (as do catálogo) — a IA não duplica, mesmo a descrição mencionando esses itens explicitamente. Só itens genuinamente novos (ex.: piscina) chegam com badge "✨ IA" |

---

### C6 — Falha/lentidão da IA não bloqueia o catálogo

**Como forçar a falha (2 opções):**

- **Cota esgotada** — tabela `ai_usage_monthly` (1 crédito = 1 job de IA completado, por
  usuário/mês):
  ```sql
  SELECT id FROM users WHERE email = 'seu-email-de-teste@...'; -- pega o user_id

  INSERT INTO ai_usage_monthly (user_id, usage_month, credits_used)
  VALUES (SEU_USER_ID, '2026-08', 999)
  ON DUPLICATE KEY UPDATE credits_used = 999;
  ```
  Reverter depois: `DELETE FROM ai_usage_monthly WHERE user_id = SEU_USER_ID AND usage_month = '2026-08';`
- **IA lenta/indisponível (sem mexer no banco)** — DevTools → aba Network → clique direito na
  requisição `POST /ai/bootstrap/preview` (ou nas de `GET /ai/jobs/*`) → **Block request URL**.

| Passo | Ação                                                                                  | Resultado esperado                                                                                                                                                                         |
|-------|---------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Forçar a falha por uma das duas opções acima, antes de gerar com descrição preenchida | O catálogo (Etapa 2) continua exibido e utilizável normalmente                                                                                                                             |
| 2     | Aguardar o timeout/erro do job de IA                                                  | Aparece um toast de aviso não-bloqueante ("A IA não conseguiu complementar as sugestões, mas os itens do catálogo continuam disponíveis") — a tela **não** trava nem exibe erro bloqueante |
| 3     | Aplicar os itens do catálogo normalmente                                              | Aplicação funciona mesmo com a IA tendo falhado                                                                                                                                            |

---

### C7 — `nextDueAt` correto após aplicar (bugfix TASK-183 — o mais crítico)

| Passo | Ação                                                                                                     | Resultado esperado                                                                        |
|-------|----------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| 1     | Gerar preview pra "Condomínio", localizar o item EXTINTOR (deve vir do catálogo, `periodQty=12`/`MESES`) | Item exibido com periodicidade 12 meses                                                   |
| 2     | Aplicar (marcar e clicar em "Aplicar")                                                                   | Redireciona pra `/items`                                                                  |
| 3     | Abrir o item EXTINTOR recém-criado                                                                       | `nextDueAt` = data de hoje + 12 meses — **não** um valor diferente                        |
| 4     | Conferir a norma vinculada no detalhe do item                                                            | Mesma norma (`ABNT / Corpo de Bombeiros`, 12 meses) mostrada no preview — bate exatamente |

---

### C8 — Aplicação mista (catálogo + IA) com edição manual

**Achado (Douglas, 21/08/2026)**: o modal deixava editar periodicidade/norma de itens vindos do
catálogo (`source="CATALOG"`), mas o backend sempre usa o período real da norma pra esses itens
(regra da TASK-183) — a edição era salva na tela mas descartada silenciosamente no `apply()`.
**Corrigido**: modal agora trava esses campos quando o item é de catálogo, com nota explicando o
motivo. Cenário reescrito pra refletir o comportamento correto.

| Passo | Ação                                                                                                | Resultado esperado                                                                                                        |
|-------|-----------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| 1     | Gerar preview com descrição (mistura catálogo + IA), abrir "Editar" num item de origem "✅ Catálogo" | Campos Norma/Qtd. Período/Unidade/Tolerância aparecem desabilitados, com nota explicando que a periodicidade vem da norma |
| 2     | Abrir "Editar" num item de origem "✨ IA"                                                            | Campos continuam editáveis normalmente (item sem norma curada vinculada)                                                  |
| 3     | Desmarcar 2-3 itens (um de cada origem)                                                             | Itens desmarcados não vão pro payload de aplicação                                                                        |
| 4     | Aplicar                                                                                             | Só os itens marcados são criados                                                                                          |
| 5     | Conferir em `/items` os itens de origem IA que não bateram com nenhuma norma curada                 | Categoria `OPERATIONAL`, sem norma vinculada — comportamento correto pra item sem cobertura regulatória conhecida         |

---

### C10 — Idempotência: rodar preview + apply duas vezes não duplica

**Achado (Douglas, 21/08/2026)**: gerar preview e aplicar duas vezes seguidas duplicava todos os
itens (EXTINTOR e os demais apareciam repetidos em `/items`). Como o catálogo agora é instantâneo e
barato de re-rodar, repetir o fluxo por engano ficou bem mais fácil do que era antes (quando cada
rodada custava uma chamada de IA). **Corrigido**: `apply()` agora verifica, por item, se já existe
um item ativo do mesmo `itemType` na organização antes de criar.

| Passo | Ação                                                                                                                                                              | Resultado esperado                                                                             |
|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| 1     | Gerar preview pra "Condomínio" (sem descrição) e aplicar todos os itens                                                                                           | Itens criados normalmente em `/items`                                                          |
| 2     | Gerar preview pra "Condomínio" de novo (mesma organização) e aplicar de novo                                                                                      | Nenhum item duplicado em `/items` — a contagem continua igual à do passo 1                     |
| 3     | Conferir o toast/resposta da segunda aplicação                                                                                                                    | Mensagem informando que os itens já existiam e não foram duplicados (não é um erro bloqueante) |
| 4     | Rodar `SELECT item_type, COUNT(*) FROM maintenance_items WHERE organization_code = 'SEU_ORG_CODE' AND deleted_at IS NULL GROUP BY item_type HAVING COUNT(*) > 1;` | Vazio — nenhum `item_type` duplicado pra essa organização                                      |

---

### C9 — Outros segmentos (checagem rápida de amostragem)

| Passo | Ação                                        | Resultado esperado                                                                   |
|-------|---------------------------------------------|--------------------------------------------------------------------------------------|
| 1     | Repetir o C2 (sem descrição) pra "Hospital" | 25 itens, todos universais — nenhum item específico de condomínio (ex.: gás) aparece |
| 2     | Repetir pra "Indústria"                     | 26 itens — os 25 universais + NR-13 (caldeiras)                                      |
| 3     | Repetir pra "Escritório"                    | 26 itens — os 25 universais + instalação de gás                                      |

---

## Critérios de Aceite da Suite

- [X] C1: `norm_segments` com contagem correta por segmento, nenhum item de `norms` órfão
- [X] C2: catálogo abre instantâneo, sem chamada de IA, badges corretos
- [X] C3: segmento OUTROS não quebra — vazio sem descrição, só IA com descrição
- [X] C4: IA complementa corretamente, sem substituir os itens de catálogo já exibidos
- [X] C5: IA não duplica item já coberto pelo catálogo, mesmo quando a descrição o menciona
- [X] C6: falha da IA não bloqueia a aplicação dos itens de catálogo
- [X] C7: `nextDueAt` do item aplicado bate com o período real da norma, não com valor divergente
- [X] C8: campos de período travados pra itens de catálogo no modal de edição, item sem norma vira OPERATIONAL — **corrigido, aguardando revalidação**
- [X] C9: amostragem de outros segmentos bate com a classificação esperada
- [X] C10: `apply()` idempotente — rodar preview+apply duas vezes não duplica itens — **corrigido, aguardando revalidação**

---

### C11 — Tipo de empresa pré-preenchido a partir da organização

**Achado (Douglas, 21/08/2026)**: a organização já declara o tipo dela no cadastro
(`Organization.companyType`) — não fazia sentido pedir pro usuário escolher de novo na Etapa 1.
**Corrigido**: o campo agora vem preenchido e desabilitado automaticamente, lendo
`organization.companyType` do contexto de acesso já carregado (`useCurrentOrganizationAccess`,
mesmo hook usado em outras telas) — sem chamada de rede nova.

| Passo | Ação                                                                                    | Resultado esperado                                                                                          |
|-------|--------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| 1     | Logar numa organização com `companyType` já cadastrado, abrir `/ai-onboarding`             | Campo "Tipo de Empresa" já vem preenchido com o tipo certo da organização, e desabilitado (não clicável)     |
| 2     | Conferir o texto de apoio abaixo do campo                                                  | "Definido pelo cadastro da sua organização." aparece                                                        |
| 3     | Gerar preview                                                                               | Usa o tipo pré-preenchido — bate com o catálogo esperado pra esse segmento (comparar com C2/C9)              |
| 4     | (Se possível) testar com uma organização antiga sem `companyType` salvo                    | Campo continua editável normalmente, sem nota — comportamento de hoje preservado pra esse caso               |

---

### C12 — Rolagem interna da tabela (Etapa 2)

**Achado (Douglas, 21/08/2026)**: com muitos itens, a página inteira rolava verticalmente,
escondendo o título "Passo 2" e os botões Voltar/Aplicar. **Corrigido**: a tabela agora tem altura
máxima com rolagem própria (55% da altura da tela) e cabeçalho de colunas fixo (sticky) — título e
botões ficam sempre visíveis.

| Passo | Ação                                                                          | Resultado esperado                                                                                  |
|-------|------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| 1     | Gerar preview com um segmento que traga bastante itens (ex.: "Condomínio", 26 itens) | A tabela tem barra de rolagem vertical própria; o card inteiro não ultrapassa a tela                   |
| 2     | Rolar a tabela pra baixo                                                     | Título "Passo 2: Preview dos itens" e os botões "Voltar"/"Aplicar" continuam visíveis, fora da rolagem  |
| 3     | Rolar a tabela pra baixo                                                     | O cabeçalho das colunas (Origem, Item, Categoria...) permanece fixo no topo da área da tabela           |

---

### C13 — Experiência mobile (TASK-186): cards no lugar da tabela

**Achado (Douglas, 21/08/2026)**: a tabela de 8 colunas é inviável no mobile, mesmo com rolagem
horizontal contida (C12). **Implementado**: abaixo do breakpoint `md` do Bootstrap (768px), a
tabela dá lugar a uma lista de cards compactos — mesmo estado/handlers, só a apresentação muda. Não
pude validar visualmente (tela exige login, sem credenciais de teste disponíveis) — só build e
revisão de código até aqui.

| Passo | Ação                                                                                   | Resultado esperado                                                                                  |
|-------|-----------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| 1     | Abrir `/ai-onboarding` em viewport < 768px (DevTools device toolbar ou celular real)    | Lista de cards aparece, tabela não aparece                                                             |
| 2     | Abrir em viewport ≥ 768px                                                                | Tabela aparece normalmente (sem regressão), cards não aparecem                                         |
| 3     | No modo card: marcar/desmarcar um item individual                                       | Funciona igual ao modo tabela                                                                          |
| 4     | No modo card: usar o checkbox "Selecionar todos" acima da lista                         | Marca/desmarca todos os cards                                                                          |
| 5     | No modo card: tocar em "Editar" num item                                                | Abre o mesmo modal de edição já usado no desktop, com a mesma regra de campos travados pra "✅ Catálogo" |
| 6     | No modo card: tocar em "Remover"                                                        | Remove o item do preview, igual ao modo tabela                                                         |
| 7     | Redimensionar a janela passando por 768px (ou girar o celular)                          | Troca entre tabela/cards acontece sem quebrar o estado (seleções continuam corretas)                   |
| 8     | Abrir o modal de edição num celular estreito (< 400px de largura)                       | Campos "Qtd. Período" e "Unidade" não ficam espremidos lado a lado — empilham verticalmente             |

---

## Critérios de Aceite da Suite (C11/C12/C13)

- [ ] C11: tipo de empresa pré-preenchido e travado quando a organização já tem `companyType`
- [ ] C12: tabela com rolagem vertical interna, cabeçalho fixo, título/botões sempre visíveis
- [ ] C13: lista de cards no mobile, tabela no desktop, mesmo comportamento nos dois modos

---

## Achados de layout (Douglas, 21/08/2026) — corrigidos

- Checkbox "marcar/desmarcar tudo" no cabeçalho da tabela → adicionado.
- Container da Etapa 2 estreito, causava rolagem horizontal → alargado (900px → 1200px só na
  Etapa 2).
- Rolagem da tabela empurrava título/botões pra fora da tela → rolagem interna com cabeçalho fixo
  (ver C12).
- Tipo de empresa pedido de novo, apesar de já cadastrado na organização → pré-preenchido e travado
  (ver C11).
- Tabela de 8 colunas inviável no mobile → lista de cards abaixo de 768px (ver C13, TASK-186).

---

## Status
C1-C10 validados por Douglas (21/08/2026), incluindo os fixes de edição de período (C8) e
idempotência do `apply()` (C10). C11 (tipo de empresa pré-preenchido), C12 (rolagem interna) e C13
(experiência mobile, TASK-186) são achados/tasks do mesmo dia, já implementados e commitados na
mesma branch `feature/ai-onboarding-catalog-filter` (backend: 779 testes, 0 falhas; frontend: build
limpo), mas **ainda não revalidados por Douglas** — C13 em especial não pôde ser conferido
visualmente por mim (tela exige login). Fase 2 do EPIC-025 fica pronta pra PR assim que C11/C12/C13
forem confirmados.
