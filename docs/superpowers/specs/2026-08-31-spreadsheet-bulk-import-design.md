# Importação de itens + histórico de manutenção via planilha (.xlsx)

**Data:** 31/08/2026
**Status:** Aprovado por Douglas (brainstorm conduzido nesta data)

## Motivação

Clientes que já controlam manutenção predial numa planilha (Excel) hoje só têm dois caminhos pra
migrar pro Easy Maintenance: cadastrar item a item na tela manual, ou passar pelo onboarding por IA
(chat). Nenhum dos dois aproveita o fato de que o dado já existe, estruturado, na planilha do
cliente. Uma importação em massa reduz o atrito de adoção pra exatamente o perfil de cliente que o
produto mais precisa converter agora (zero clientes pagantes, ver
[[project_zero_customers_landing_copy]]).

## Contexto (levantado antes do desenho)

- `poi-ooxml` (Apache POI) já é dependência do projeto (TASK-147/EPIC-017, exportação do Relatório
  Analítico em `.xlsx`) — a leitura de planilha no backend não precisa de biblioteca nova.
- `AiBootstrapService` já resolve "aplicar em lote com resultado parcial" (criados/falhos/pulados)
  pro onboarding por IA — decidido em conversa **não** reaproveitar esse pipeline aqui (fluxo de UX
  bem diferente: planilha é upload + grade de revisão, não chat). A importação usa seu próprio
  serviço, mas por baixo chama exatamente os mesmos métodos que o cadastro manual já usa
  (`MaintenanceItemService.create()`, `MaintenanceService.register()`) — nenhuma regra de negócio é
  duplicada.
- Classificação de item (Regulatório × Operacional) precisa seguir exatamente o mecanismo da
  TASK-212 (`item_types.norm_id`) — texto livre da planilha nunca decide a categoria sozinho, mesmo
  princípio já estabelecido: input livre não pode furar uma garantia central do produto.
- `MaintenanceItem` já suporta múltiplas instâncias do mesmo tipo via `location.complement`
  (ex.: "Extintor — Térreo" vs. "Extintor — 1º andar"), reaproveitado como campo de desambiguação na
  planilha.

## Decisões de escopo (brainstorm, 31/08/2026)

1. **Escopo do dado: itens + histórico completo de manutenções**, não só a lista de itens. Decisão
   explícita de Douglas — mais valioso, aceitando a complexidade adicional de validar N linhas de
   histórico por item.
2. **Fluxo separado do onboarding por IA** — não reaproveita `AiBootstrapService`/
   `AiBootstrapApplyRequest`. Reaproveita as regras de negócio (via os mesmos services), não o
   pipeline de aplicação em si.
3. **Classificação por casamento com `item_types`/normas curadas** — mesmo mecanismo da TASK-212.
   Tipo que bate com uma norma vira Regulatório automático; que não bate vira Operacional (e cria um
   `item_types` novo, mesmo comportamento de hoje ao digitar um tipo inédito no cadastro manual).
4. **Modelo fixo pra download** (não upload livre + mapeamento de coluna). Mais simples de validar;
   mapeamento de coluna livre fica como evolução futura (v2), não este desenho.
5. **Self-service** — o próprio cliente faz, sem ajuda do time. Implica UX com prévia revisável
   antes de confirmar, mensagens de erro claras por linha (não só um log técnico).
6. **Duas etapas, síncrono, parsing no backend** (Abordagem A, ver conversa) — preview sem persistir
   nada, depois confirmação explícita. Processamento assíncrono (fila/job) descartado pra v1 — carga
   esperada (dezenas a poucas centenas de itens por cliente) não justifica a complexidade.

## Modelo da planilha

Duas abas, ligadas por um ID sequencial simples (evita ambiguidade de nome duplicado, ex. dois
itens "Extintor — Térreo"):

**Aba "Itens"**

| Coluna | Obrigatório | Regra |
|---|---|---|
| `ID` | sim | sequencial (1, 2, 3...), só pra referência da aba Histórico |
| `Tipo do item` | sim | texto livre — casa contra `item_types`/norma curada (TASK-212) |
| `Local/Complemento` | não | desambigua itens do mesmo tipo |
| `Periodicidade (meses)` | condicional | obrigatório se o tipo não bater com norma nenhuma (fica Operacional) |

**Aba "Histórico"**

| Coluna | Obrigatório | Regra |
|---|---|---|
| `ID do item` | sim | precisa existir na aba Itens |
| `Data da manutenção` | sim | não pode ser futura; não pode repetir pro mesmo item |
| `Tipo` | sim | Preventiva / Corretiva / Inspeção / Teste / Emergencial |
| `Responsável` | não | — |
| `Custo (R$)` | não | — |
| `Descrição` | não | — |

Sem coluna de "próxima manutenção" manual no histórico — sempre calculada automaticamente (mesma
decisão da TASK-216). Só a manutenção mais recente de cada item importa pro `nextDueAt` final; as
outras linhas de histórico do mesmo item só alimentam o histórico, não o cálculo.

## API

Dois endpoints, nada persistido na primeira chamada:

```
POST /easy-maintenance/api/v1/items/import/preview
  multipart file (.xlsx) → ImportPreviewResponse
  - items: [{ rowId, itemType, location, category (derivada), normMatched: bool,
              status: OK|WARNING|ERROR, messages: string[] }]
  - history: [{ itemRowId, performedAt, type, status, messages: string[] }]
  - summary: { itemsOk, itemsWithWarning, itemsWithError,
               historyOk, historyWithError,
               planLimitExceeded: bool, maxItems, currentItems, validItemsCount }

POST /easy-maintenance/api/v1/items/import/confirm
  body: { items: PreviewItemRow[], history: PreviewHistoryRow[] }
  → ImportResultResponse { itemsCreated: number, historyCreated: number,
                            skipped: [{ rowId, reason }] }
```

`confirm` recebe os dados já estruturados da prévia (não o arquivo de novo) — permite o usuário
corrigir um erro pequeno na grade (ex.: data errada) sem gerar uma planilha nova. O backend
**revalida tudo do zero em `confirm`**, nunca confia no que a prévia calculou (backend autoritativo,
mesmo princípio da TASK-212) — o estado pode ter mudado entre as duas chamadas (ex.: limite de plano
mudou, outro item foi criado nesse meio-tempo).

Por baixo, `confirm` processa item por item chamando `MaintenanceItemService.create()` e, pra cada
linha de histórico válida do item, `MaintenanceService.register()` — herda de graça toda proteção já
existente (classificação TASK-212, recálculo de `nextDueAt` TASK-213/216, limite de plano,
idempotência de data duplicada) sem duplicar nenhuma regra.

**Guarda-corpo:** limite de 500 linhas por importação (arquivo ou combinação itens+histórico) — evita
abuso e mantém o processamento síncrono rápido. Acima disso, o arquivo é rejeitado antes de
processar, com mensagem clara. Se no futuro esse limite for baixo demais na prática, é o gatilho pra
reconsiderar processamento assíncrono (Abordagem C, descartada agora).

Autenticação/multi-tenant: mesmos `@RequireTenant`/`@RequiresFullAccess` (`canCreateItem`) já usados
em `POST /items` — nada novo aqui.

## Fluxo de tela

Nova página `/items/import`, acessível por um botão "Importar planilha" ao lado de "+ Novo Item" em
`/items`.

1. **Passo 1**: instrução curta + botão "Baixar modelo" (.xlsx) + input de upload.
2. **Passo 2** (após `preview`): grade com abas Itens/Histórico, status colorido por linha
   (✅ pronto / ⚠️ aviso com motivo / ❌ erro com motivo), banner resumo ("42 itens prontos, 3 com
   aviso, 1 com erro"). Botão "Confirmar importação" desabilitado se houver erro bloqueante de
   arquivo (ex.: limite de plano estourado).
3. **Passo 3** (após `confirm`): resumo final (X criados, Y pulados com motivo) — mesmo padrão
   visual já usado no toast de resultado da remoção em massa (TASK-214).

## Tratamento de erro

**Erros de arquivo (bloqueiam a importação inteira, antes de processar linha por linha):**
- Arquivo não segue o modelo (aba/coluna faltando ou renomeada)
- Planilha vazia (zero linhas válidas)
- Mais de 500 linhas (itens + histórico combinados)
- Limite de plano estourado (itens válidos > vagas restantes na conta)

**Erros de linha — aba Itens (linha não entra):**
- `Tipo do item` vazio
- `ID` duplicado ou vazio
- Ficou Operacional (tipo não bate com norma) sem `Periodicidade (meses)` preenchida, ou valor
  inválido (não numérico, ≤ 0)

**Avisos de linha — aba Itens (entra, mas fica sinalizado):**
- Já existe item com o mesmo Tipo+Local na organização (possível duplicata — reimportação por
  engano, por exemplo)
- Tipo do item nunca visto antes — vai criar `item_types` novo, sem norma vinculada (Operacional)

**Erros de linha — aba Histórico (linha não entra):**
- `ID do item` não existe na aba Itens, **ou** aponta pra uma linha de Itens que teve erro (herda o
  erro do item pai — "item pai inválido", não é revalidado como se fosse independente)
- `Data da manutenção` vazia, futura, ou duplicada pro mesmo item
- `Tipo` fora dos valores permitidos

## Testes

- **Parser**: planilha fixture válida + variantes quebradas (aba errada, coluna faltando, arquivo
  vazio, mais de 500 linhas).
- **Validação**: um teste por regra (tipo vazio, operacional sem periodicidade, data duplicada, ID
  órfão, item pai com erro, limite de plano).
- **Classificação**: mesmo padrão de `MaintenanceItemClassificationTest` (TASK-212) — tipo que bate
  com norma vira Regulatório; que não bate vira Operacional + `item_types` novo.
- **Fluxo completo**: `preview` → `confirm` no caminho feliz cria tudo certo; caminho com erro
  parcial só pula as linhas ruins, resto entra.
- **Frontend**: sem teste automatizado novo (mesmo padrão desta sessão — typecheck/lint são o gate
  automatizado; validação visual fica com Douglas, mesmo aviso já dado nas tasks anteriores sobre
  não conseguir rodar a app localmente neste ambiente).

## Riscos e fora de escopo

- **Sem dedup automático entre importações** — reimportar o mesmo arquivo cria itens novos, não
  atualiza os existentes. O aviso de "item parecido já existe" (acima) é a única rede de segurança
  de v1; dedup de verdade (fuzzy match, merge) fica pra depois se aparecer como problema real de
  uso.
- **Mapeamento de coluna livre (upload da planilha como o cliente já tem, sem modelo fixo)** — v2,
  não este desenho. V1 exige que o cliente reorganize os dados no modelo baixado.
- **Processamento assíncrono** — não necessário na carga esperada; gatilho de reconsideração é o
  limite de 500 linhas se aparecer se mostrar insuficiente na prática.
- **Esforço**: é uma feature grande — parser + validação em duas camadas (linha e arquivo) + tela de
  revisão com grade + dois endpoints novos. Maior que qualquer task fechada nesta sessão até agora;
  vale considerar dividir a implementação em sub-tasks (ex.: backend preview, backend confirm,
  frontend) na hora de virar plano, mesmo sendo uma spec só.

## Próximos passos

Revisão desta spec por Douglas → plano de implementação (via `writing-plans`, provavelmente dividido
em sub-tasks pelo tamanho) → `execute-task` por sub-task.
