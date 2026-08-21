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
[TASK-185](../../tasks/TASK-185.md) (frontend `/ai-onboarding` em duas camadas)

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

| Passo | Ação                                                                          | Resultado esperado                                                                                                                                                                         |
|-------|--------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Forçar a falha por uma das duas opções acima, antes de gerar com descrição preenchida | O catálogo (Etapa 2) continua exibido e utilizável normalmente                                                                                                                             |
| 2     | Aguardar o timeout/erro do job de IA                                           | Aparece um toast de aviso não-bloqueante ("A IA não conseguiu complementar as sugestões, mas os itens do catálogo continuam disponíveis") — a tela **não** trava nem exibe erro bloqueante |
| 3     | Aplicar os itens do catálogo normalmente                                                                                                                        | Aplicação funciona mesmo com a IA tendo falhado                                                                                                                                            |

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

| Passo | Ação                                                                                                                                 | Resultado esperado                                                                                                |
|-------|--------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| 1     | Gerar preview com descrição (mistura catálogo + IA), editar a periodicidade de um item de catálogo antes de aplicar (botão "Editar") | Edição salva localmente, refletida na linha                                                                       |
| 2     | Desmarcar 2-3 itens (um de cada origem)                                                                                              | Itens desmarcados não vão pro payload de aplicação                                                                |
| 3     | Aplicar                                                                                                                              | Só os itens marcados são criados; o item editado manualmente reflete a edição, não o valor original               |
| 4     | Conferir em `/items` os itens de origem IA que não bateram com nenhuma norma curada                                                  | Categoria `OPERATIONAL`, sem norma vinculada — comportamento correto pra item sem cobertura regulatória conhecida |

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
- [ ] C3: segmento OUTROS não quebra — vazio sem descrição, só IA com descrição
- [X] C4: IA complementa corretamente, sem substituir os itens de catálogo já exibidos
- [X] C5: IA não duplica item já coberto pelo catálogo, mesmo quando a descrição o menciona
- [ ] C6: falha da IA não bloqueia a aplicação dos itens de catálogo
- [ ] C7: `nextDueAt` do item aplicado bate com o período real da norma, não com valor divergente
- [ ] C8: aplicação mista + edição manual funcionam corretamente, item sem norma vira OPERATIONAL
- [ ] C9: amostragem de outros segmentos bate com a classificação esperada

---

## Status
Pendente de validação por Douglas — local primeiro, depois em staging. Sem PR aberta até a
aprovação.
