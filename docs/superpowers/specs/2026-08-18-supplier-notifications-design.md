# Fornecedores nas Notificações de Vencimento — Design

**Data**: 2026-08-18
**Status**: Aprovado por Douglas (via diálogo de brainstorm)

## Contexto

As notificações de vencimento de manutenção (e-mail e WhatsApp, EPIC-015) hoje avisam que um item
está vencendo ou vencido, mas não ajudam o síndico/gestor a agir — ele ainda precisa abrir o
sistema, ir no fluxo de "registrar manutenção" e buscar um fornecedor manualmente (busca ao vivo
via Google Places, já existente, `SupplierSearchService`). Ideia do Douglas: trazer 2-3
fornecedores próximos direto na mensagem, fechando o ciclo "avisei que venceu" → "aqui está quem
pode resolver" numa etapa só.

**Achado importante da pesquisa que embasou o design**: a busca de fornecedores existente é
100% interativa — depende de `navigator.geolocation` do navegador, chamado no clique do usuário
dentro de `maintenances/new/page.tsx`. Não existe tabela de fornecedores, nem coordenada
(latitude/longitude) salva em lugar nenhum do backend. O job de notificação (`NotificationEventDetectionJob`)
roda à noite, sem navegador, sem geolocalização — a infraestrutura pra alimentar fornecedor nesse
contexto simplesmente não existia antes desta task.

## Decisões de escopo (confirmadas com Douglas)

1. **Geolocalização**: busca textual do Google Places (`textsearch/json`, ex.: "eletricista em
   Belo Horizonte, MG") usando cidade/estado do endereço já cadastrado na `Organization` — **sem**
   geocodificação nem coordenadas novas armazenadas. Menos preciso que uma busca por raio real,
   mas sem infraestrutura nova de geo.
2. **WhatsApp**: novo template HSM (`vencimento_manutencao_v3` — o `v2` atual já está aprovado e em
   uso, não dá pra editar um template aprovado, precisa ser um novo) com **2 fornecedores fixos,
   nome + telefone cada** (4 variáveis novas), somadas às 5 já existentes. Dependência externa
   real: o template novo precisa passar pela aprovação da Meta antes de ir pro ar — mesmo processo
   (e risco de demora) que já atrasou o `v2` antes dele ser aprovado.
3. **E-mail**: sem essa restrição — lista de fornecedores (0 a N encontrados) vira um bloco HTML
   novo no template já existente (`EmailTemplateHelper.generateNotificationEventHtml`), só aparece
   se a lista não estiver vazia.
4. **Quais eventos buscam fornecedor**: só os que já disparam WhatsApp ou E-mail hoje (WhatsApp:
   `NEAR_DUE` com `daysOffset==1` ou `OVERDUE`; E-mail: só `OVERDUE`). `PUSH` (que dispara em todo
   `NEAR_DUE`) **não** busca fornecedor — é notificação in-app, sem o mesmo peso de mensagem
   externa, e buscar pra todo `NEAR_DUE` multiplicaria as chamadas ao Google Places à toa.
5. **Cache**: 7 dias por `(organizationCode, categoryKeyword)` — fornecedor próximo raramente muda
   de uma semana pra outra; evita bater no Google Places todo dia pro mesmo caso.
6. **Comportamento do WhatsApp com menos de 2 fornecedores encontrados**: o template HSM exige as
   2 vagas preenchidas (Meta não aceita variável de corpo vazia). Se a busca achar 0 ou 1
   fornecedor pra aquela categoria/região, **o envio por WhatsApp desse evento específico é pulado**
   — mesmo comportamento de fallback que já existe hoje quando o WhatsApp falha por qualquer outro
   motivo (cai pra e-mail se o evento também dispara e-mail; se o evento só dispararia WhatsApp
   — caso `NEAR_DUE` dia 1 — o usuário fica só com a notificação in-app já seria enviada de
   qualquer forma).
7. **Arquitetura**: busca de fornecedor acontece **dentro de cada serviço de canal**
   (`BusinessWhatsAppNotificationService`, `BusinessEmailNotificationService`), não no
   `NotificationEvent`/orquestrador — `NotificationEvent` não ganha campo novo, nenhum cálculo
   desperdiçado pra eventos que não chegam nesses dois canais. Alternativa descartada: pré-computar
   fornecedores pra todas as organizações antes do job rodar — mais complexidade (cache extra,
   invalidação) sem ganho real no volume atual do produto.

---

## Componentes técnicos

### `SupplierLookupService` (novo, backend)

- Método principal: `findNearbyByCityState(String city, String state, String categoryKeyword)`.
- Reaproveita o cliente HTTP do Google Places já usado por `SupplierSearchService`
  (`supplier/application/service/SupplierSearchService.java`), mas chama o endpoint **Text Search**
  (`textsearch/json`) em vez de **Nearby Search** (`nearbysearch/json`), já que não há
  latitude/longitude disponível nesse contexto.
- Reaproveita (extrai pra local compartilhado, não duplica) o mapeamento `itemType → keyword` que
  já existe em `SupplierSearchService.mapServiceKeyToKeyword` (whitelist pequeno: `EXTINTOR`,
  `SPDA`, `CAIXA_DAGUA`, `ILUMINACAO_EMERGENCIA`, `HIDRANTE`, `AR_COND` + fallback genérico
  `"manutenção " + itemType`). Sem expansão desse whitelist nesta task — mesma cobertura de hoje.
- Cache Caffeine próprio (`suppliersNotification`), TTL 7 dias, chave `(organizationCode,
  categoryKeyword)` — **não** reaproveita o cache de curto prazo (`suppliersNearby`) do fluxo
  interativo, contextos diferentes (7 dias vs. sessão de clique único).
- Retorna lista vazia (nunca lança exceção pro chamador) em qualquer falha: API fora do ar, quota
  estourada, categoria sem resultado na região.

### `BusinessWhatsAppNotificationService`

- `buildPayload()` passa de 5 para 9 variáveis de corpo: `recipientName, itemName, companyName,
  dueDate` + `supplier1Name, supplier1Phone, supplier2Name, supplier2Phone` (ordem exata a definir
  na implementação, alinhada com o texto do template submetido à Meta).
- Antes de montar o payload, chama `SupplierLookupService.findNearbyByCityState(...)` usando
  cidade/estado da `Organization` do evento e a categoria do item referenciado. Se retornar menos
  de 2 fornecedores, **não envia** — mesmo caminho de fallback já existente pra outras falhas de
  envio do WhatsApp.
- Nome do template migra de `vencimento_manutencao_v2` pra `vencimento_manutencao_v3` via a config
  já existente (`whatsapp.default-template-name`) — só depois do `v3` estar aprovado pela Meta.
  Até lá, o código do `v3` pode estar pronto e testado, mas a config continua apontando pro `v2`
  (sem fornecedor) em produção — dependência externa, não bloqueia o resto da implementação.

### `BusinessEmailNotificationService` / `EmailTemplateHelper`

- `buildPayload()` chama o mesmo `SupplierLookupService`, sem limite de quantidade (usa quantos a
  busca retornar, tipicamente 2-3 dado o `limit` já praticado no fluxo interativo).
- `EmailTemplateHelper.generateNotificationEventHtml` ganha um parâmetro novo (lista de
  fornecedores: nome, telefone, endereço/link do Maps) e um bloco HTML condicional — só renderiza
  a seção se a lista não estiver vazia. Sem aprovação externa nenhuma (diferente do WhatsApp), pode
  ir pro ar assim que implementado.

### Frontend

Nenhuma mudança — e-mail e WhatsApp são gerados inteiramente no backend, sem UI nova envolvida.

---

## Fluxo de dados

1. `NotificationEventDetectionJob` (cron diário, já existe) detecta evento de vencimento/atraso.
2. `NotificationOrchestratorService` (já existe) despacha por canal.
3. **[Novo]** Dentro do canal WhatsApp (só `NEAR_DUE` dia 1 ou `OVERDUE`) ou canal E-mail (só
   `OVERDUE`): resolve `Organization` do evento → cidade/estado → categoria do item/manutenção
   referenciado → `SupplierLookupService.findNearbyByCityState(...)` (cache 7 dias) → monta payload
   com (ou sem, se a busca vier vazia) fornecedores.
4. Envia normalmente pelo provedor já existente (Graph API do WhatsApp / Resend).

## Tratamento de erro

- Falha na API do Google Places (timeout, quota, chave inválida): loga, retorna lista vazia,
  notificação segue sem a seção de fornecedores — nunca bloqueia o envio principal.
- Categoria sem fornecedor encontrado na região: mesmo comportamento — lista vazia.
- WhatsApp com menos de 2 fornecedores encontrados: envio pulado pra esse evento específico (ver
  decisão de escopo #6).
- Template `v3` ainda não aprovado pela Meta: sistema continua operando com `v2` (sem fornecedor)
  até a aprovação acontecer — dependência externa documentada, não é bug nem bloqueio de
  implementação.

## Testes

- `SupplierLookupServiceTest`: mock do cliente HTTP do Google Places — casos de sucesso (2+
  resultados), 1 resultado, 0 resultados, erro de API (timeout/4xx/5xx) — todos devem retornar
  lista vazia ou a lista real, nunca propagar exceção.
- `BusinessWhatsAppNotificationServiceTest`: payload com 2 fornecedores encontrados (envia
  normalmente) e com <2 encontrados (não envia, cai no fallback já testado hoje).
- `BusinessEmailNotificationServiceTest`/`EmailTemplateHelperTest`: HTML gerado com 0, 1 e 3
  fornecedores — bloco aparece só quando a lista não está vazia.
- `npm run build` (frontend) não se aplica — sem mudança de frontend nesta feature.

---

## Fora de Escopo (decidir depois se/quando virar necessidade)

- Geocodificação de endereço da organização (lat/lng reais, busca por raio) — só busca textual por
  cidade/estado por enquanto.
- Expansão do whitelist `itemType → keyword` — mesma cobertura de categorias que já existe hoje.
- Fornecedor em notificações `PUSH` (in-app).
- Qualquer persistência de fornecedor (tabela, histórico de fornecedores contatados, avaliação) —
  segue sendo busca ao vivo, sem banco de dados, igual ao fluxo interativo existente.
- Tratamento alternativo pro caso de menos de 2 fornecedores no WhatsApp (ex.: enviar com 1 vaga
  vazia, ou template alternativo pra 1 fornecedor) — decisão explícita foi pular o envio nesse caso.

## Riscos

- **Aprovação da Meta do template `v3`** é uma dependência externa fora do controle da
  implementação — mesmo risco que já atrasou o `v2` antes. O código pode ficar pronto e testado
  sem que o canal WhatsApp com fornecedor esteja de fato ativo em produção até a aprovação sair.
- **Custo/rate-limit do Google Places**: mitigado pelo cache de 7 dias e pelo escopo restrito
  (só eventos que já disparam WhatsApp/E-mail), mas ainda é uma chamada de API paga por
  organização/categoria nova a cada 7 dias — vale observar o volume real depois do rollout.
- Busca textual por cidade/estado é menos precisa que busca por raio real — um fornecedor "próximo"
  pode não ser tão próximo assim numa cidade grande. Aceito como trade-off pra evitar
  geocodificação nesta primeira leva.
