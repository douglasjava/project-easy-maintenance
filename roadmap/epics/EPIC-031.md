# EPIC-031 — Assistente no WhatsApp (canal de entrada como segunda interface)

## Status
✅ Onda 1 em produção (27/09/2026) e validada no piloto (ativação, menu, texto livre, áudio, PARAR). Ajustes do piloto na TASK-313. Ondas 2 e 3 no Backlog — próxima: TASK-305 (consultas) e TASK-306 (registro).
pré-brainstorm no Cowork, desenho refinado nesta sessão com leitura do código.

## Objetivo
Permitir que usuários **já cadastrados** usem o WhatsApp como uma **segunda interface** do produto,
por texto ou áudio, para:
1. **consultar** rapidamente (o que vence, o que está vencido, histórico de um item, índice de
   conformidade);
2. **registrar manutenção** em campo, com foto e **confirmação explícita** antes de gravar;
3. **adicionar um condomínio novo** a uma conta existente, por perguntas guiadas;
4. **receber relatórios**: documento fechado como arquivo e análise exploratória como link.

O WhatsApp não substitui o web. Ele atende quem está em campo (síndico, zelador, técnico com
conta) e consultas rápidas do gestor. Análise de carteira e configuração inicial em massa
continuam no web.

## Fora do escopo (explícito)
- Cadastro em massa de itens pelo WhatsApp (continua no web).
- Criar **conta nova** pelo WhatsApp: aceite de termos e cadastro de faturamento ficam no web.
- Editar, cancelar ou excluir registros pelo WhatsApp (cancelamento com motivo continua no web).
- Chamados de moradores pelo WhatsApp (o fluxo por QR code do EPIC-027 continua).
- Mensagens proativas fora da janela de 24h na v1 (são pagas e exigem template).
- Chat livre com IA: o assistente **não** responde perguntas fora do domínio (ver §Guarda-corpos).
- Outros canais (Telegram, Instagram) e microserviço separado. Módulo interno agora; reavaliar se
  o assistente evoluir para um hub multicanal ou ganhar volume e equipe próprios.

---

## ⚠️ Achados do código (o pré-brainstorm não tinha acesso ao repositório)

Correções de referência do prompt original: EPIC-012 é **Afiliados** (o modelo de épico usado
aqui é o EPIC-030); o catálogo de itens por tipo de estabelecimento é a **TASK-181/182**, não a
TASK-137 (que trata do cancelamento de manutenção); a TASK-122 é o telefone e o opt-in de alertas.

### O que já existe e reduz esforço
- **Webhook de entrada pronto** (TASK-128): `POST /public/webhooks/whatsapp` com validação de
  assinatura da Meta (`WhatsAppSignatureValidator`), resposta 200 imediata e processamento
  `@Async`. Mensagens recebidas hoje **só vão para o log** (`WhatsAppWebhookService.processChange`).
  Os eventos de status já chegam em produção, então o caminho Meta → Cloudflare → API funciona.
- **Fonte única de itens por tipo de estabelecimento**: `AiBootstrapService.previewFromCatalog`
  (catálogo curado, sem IA, TASK-182) + `apply`. O onboarding conversacional usa **a mesma** fonte
  do web.
- **Anexos com S3 + auditoria**: `MaintenanceAttachmentService` já grava em `audit_logs`.
- **Estrutura de IA** (Spring AI, `gpt-4o-mini` + fallback DeepSeek, `AiProvider`), controle de
  crédito por plano (`AiCreditService`, `aiMonthlyCredits`) e Resilience4j (circuit breaker `ai`).
- **Controle de envio e cota** (`BusinessWhatsAppNotificationService`/`QuotaService`) e o padrão
  de simulação de webhooks em `dev/SimulationController`.

### O que falta ou precisa de cuidado
1. **`WhatsAppClient` só envia template.** Texto livre, botões, listas, documento, "lida/digitando"
   e download de mídia são novos.
2. **Não existe transcrição de áudio** em lugar nenhum (a SAMU só faz chat).
3. **Os serviços dependem do usuário da requisição web**: `MaintenanceService.register()` usa
   `authenticationService.getCurrentUser()` (`SecurityContextHolder`) e a organização vem do
   `TenantContext`. O assistente roda fora de requisição autenticada → precisa de um contexto de
   execução "em nome do usuário" (TASK-302). **Ponto mais sensível de segurança do épico.**
4. **As travas de acesso estão nos controllers**: `@RequiresFullAccess` (conta em somente leitura)
   é aplicado nos controllers, e o assistente não passa por eles. As travas precisam ser repetidas
   explicitamente na porta de domínio do assistente.
5. **Telefone do usuário não é verificado nem único**: `users.phone_number` é texto livre, sem
   índice. Confiar nele permitiria que o usuário A cadastrasse o número de B e B agisse como A. Por
   isso o vínculo exige prova de posse (código ATIVAR, TASK-301).
6. **Item não tem nome nem local**, só `itemType`. Dois itens `CAIXA_DAGUA` na mesma organização
   são indistinguíveis → campo opcional "Identificação/local" (TASK-304).
7. **PDF da prestação de contas é gerado no navegador** (react-pdf em
   `PrestacaoContasPdfDocument.tsx`). O backend só gera CSV/Excel (`MaintenanceExportService`).
   Enviar o PDF pelo WhatsApp exige geração no servidor (TASK-310).
8. **`audit_logs` é pouco usada** (só anexos e itens). A origem "WhatsApp" precisa de coluna
   `source` em item e manutenção, além do registro em `audit_logs`.
9. **Papéis são globais do usuário** (`Role`: `ADMIN`, `SYNDIC`, `TECH`, `READER`), não por
   organização.

---

## Arquitetura

Módulo novo **`assistant`** dentro da `easy-maintenance-api`. Ele conversa com os outros módulos
**só por interfaces** (porta de domínio), nunca pelos repositórios deles, para poder ser extraído
depois sem reescrita.

```
Meta ──► WhatsAppWebhookController (existente) ── valida assinatura, 200 imediato
            ▼
 [1] Recepção ── grava em assistant_inbound_messages (wamid único = sem repetição)
            ▼
 [2] Controle de fluxo ── agrupa rajadas (~3 s), um pedido por vez por usuário,
            │               limites por usuário, ignora grupos/ecos/números desconhecidos
            ▼
 [3] Worker (pool próprio, fila por SELECT … FOR UPDATE SKIP LOCKED) ── "lida" + "digitando…"
            ▼
 [4] Identidade ── wa_id verificado → usuário com consentimento → organizações
            ▼
 [5] Mídia ── áudio: baixa → transcreve → descarta | foto/PDF: guarda temporário
            ▼
 [6] Classificador ── botão/menu/"sim": sem IA | texto: IA → JSON {intenção, campos}
            ▼
 [7] Handlers ── Consultas | Registro | Onboarding | Relatórios
            │     (contexto "em nome do usuário" + travas explícitas na porta de domínio)
            ▼
 [8] Montador de resposta (textos fixos PT-BR) ──► [9] Envio (WhatsAppClient ampliado)
```

**Tabelas novas**
- `assistant_inbound_messages`: wamid (único), wa_id, tipo, texto/transcrição, status
  (`RECEIVED`/`PROCESSING`/`DONE`/`IGNORED`/`FAILED`), motivo, timestamps. É fila, proteção contra
  repetição e trilha de depuração.
- `assistant_conversations`: uma por usuário. Organização ativa, ação pendente (JSON), expiração
  da ação, última mensagem do usuário (janela de 24h).
- `assistant_consents`: usuário, versão do termo, aceite, revogação, IP.
- `assistant_links`: usuário ↔ `wa_id` verificado (índice único em `wa_id`) + código de ativação
  pendente com expiração.

**Liga/desliga e piloto**: `assistant.enabled` (padrão **desligado**) + lista de liberação por
**usuário** e por organização. O teste será **em produção com um usuário controlado** do Douglas
(decisão #13). Com o assistente desligado ou o usuário fora da lista, o comportamento é o de hoje
(só log).

**Falhas**: IA fora do ar → circuit breaker, resposta "use o menu" (o menu funciona sem IA);
transcrição falhou → "pode escrever?"; erro inesperado → `FAILED` com motivo + resposta genérica.
Nunca silêncio.

## Guarda-corpos contra "chat de IA livre"
- A IA **só classifica**: devolve um JSON validado contra uma **lista fechada** de intenções
  (`CONSULTAR_VENCIMENTOS`, `CONSULTAR_VENCIDOS`, `HISTORICO_ITEM`, `INDICE_CONFORMIDADE`,
  `REGISTRAR_MANUTENCAO`, `NOVO_CONDOMINIO`, `RELATORIO`, `TROCAR_ORGANIZACAO`, `AJUDA`,
  `FORA_DO_ESCOPO`).
- **Nenhum texto gerado pela IA vai para o usuário.** Respostas são montadas pelo nosso código a
  partir de textos fixos e dados do banco. Tentativa de manipular a IA com instruções escondidas
  no máximo leva a uma intenção errada, e toda gravação passa por confirmação.
- `FORA_DO_ESCOPO` → resposta fixa com o menu ("Por aqui eu te ajudo com a manutenção do seu
  condomínio…").
- Atalhos determinísticos (menu, botões, "sim"/"corrigir"/"cancelar") não chamam a IA.

## Segurança e identidade
- **Vínculo por prova de posse**: no Perfil, "Ativar assistente" → aceite do termo → a tela mostra
  "Envie **ATIVAR 482913** para (31) 9xxxx-xxxx" (link `wa.me` com texto pronto). O `wa_id` que
  enviar o código (garantido pela Meta) é vinculado. O código vale 15 minutos e é de uso único. Um
  `wa_id` pertence a um único usuário.
- **Consentimento próprio**, separado do opt-in de alertas (TASK-122). O termo informa o
  processamento por IA de terceiros (OpenAI), a retenção e como desativar. "PARAR" no WhatsApp ou o
  Perfil revogam na hora.
- **Contexto "em nome do usuário"**: para cada mensagem, o worker monta o `SecurityContext` e o
  `TenantContext` equivalentes a uma requisição web do usuário, e limpa **sempre** em `finally`.
- **Travas explícitas antes de qualquer ação** (porta de domínio): vínculo com a organização,
  `FULL_ACCESS` para gravar (senão só consulta), papel (`READER` só consulta; `ADMIN`/`SYNDIC`/
  `TECH` registram) e revalidação a cada mensagem (usuário ativo, consentimento válido, número
  vinculado). Um teste de arquitetura garante que todo handler que grava passa pela trava.
- **Privacidade**: áudio nunca é guardado (só a transcrição); foto temporária só vai para o S3 após
  confirmação e é apagada se a ação expirar; mensagens ficam 90 dias e depois o texto é apagado,
  mantendo só os metadados; telefone mascarado em log; mensagens de grupo ignoradas.
- **Origem**: coluna `source` (`WEB`/`WHATSAPP`) em item e manutenção + `audit_logs` com
  `user_agent = "whatsapp-assistant"` e `request_id = wamid`.

## Controle de fluxo (anti-rajada)
- Agrupar mensagens seguidas do mesmo usuário (~3 s de silêncio) numa só.
- Um pedido por vez por usuário. Com confirmação pendente, só "sim"/"corrigir"/"cancelar"/botões.
- Limite por usuário (Bucket4j): 20 mensagens / 10 min e 100 / dia. Ao estourar, responde **uma
  vez** e ignora em silêncio até liberar; reincidência gera suspensão temporária, e há uma flag de
  bloqueio manual no admin.
- Número desconhecido ou sem consentimento: instrução no máximo 1 vez por dia por número.
- Texto até 1.000 caracteres e áudio até 2 min.
- Mensagens do próprio número (ecos) nunca são processadas.
- Todos os limites ficam em configuração (sem deploy para ajustar).

## Custos
- **Meta**: mensagem recebida, resposta dentro da janela de 24h (texto, botões, documento) e
  download de mídia são **grátis**. Só mensagem iniciada por nós fora da janela é paga (template),
  e isso está fora da v1. **Respostas grátis não contam na cota mensal de WhatsApp do plano.**
- **IA**: classificação com `gpt-4o-mini` ≈ US$ 0,0003/mensagem; transcrição ≈ US$ 0,003–0,006/min.
  O consumo é descontado do crédito de IA do plano. Valores são ordem de grandeza (conferir no
  momento da implementação).
- **Latência esperada**: botão/menu ~1 s; texto com IA ~2–4 s; áudio de 30 s ~4–8 s; relatório com
  aviso "gerando…" antes.

---

## Tasks

| ID | Título | Camada | Onda | Depende de |
|---|---|---|---|---|
| [TASK-299](../tasks/TASK-299.md) | Módulo `assistant`: fila de mensagens, worker, controle de fluxo, liga/desliga e piloto | Backend | 1 | — |
| [TASK-300](../tasks/TASK-300.md) | `WhatsAppClient` ampliado (texto, botões, lista, documento, lida/digitando, mídia) + cota | Backend | 1 | — |
| [TASK-301](../tasks/TASK-301.md) | Vínculo do número (código ATIVAR) + consentimento + Perfil | Full-stack | 1 | TASK-299, TASK-300 |
| [TASK-302](../tasks/TASK-302.md) | Contexto "em nome do usuário" + porta de domínio com travas + escolha de organização | Backend | 1 | TASK-301 |
| [TASK-303](../tasks/TASK-303.md) | Classificador de intenção (lista fechada) + transcrição de áudio + crédito de IA | Backend | 1 | TASK-299 |
| [TASK-304](../tasks/TASK-304.md) | Campo "Identificação/local" no item + coluna `source` em item e manutenção | Full-stack | 1 | — |
| [TASK-305](../tasks/TASK-305.md) | Consultas só leitura | Backend | 2 | TASK-302, TASK-303 |
| [TASK-306](../tasks/TASK-306.md) | Registro rápido de manutenção com confirmação, foto e item novo | Full-stack | 2 | TASK-302, TASK-303, TASK-304 |
| [TASK-307](../tasks/TASK-307.md) | Links diretos: organização e filtros pela URL nas telas do web | Frontend | 2 | — |
| [TASK-308](../tasks/TASK-308.md) | Onboarding conversacional (novo condomínio para conta existente) | Backend | 3 | TASK-302 |
| [TASK-309](../tasks/TASK-309.md) | Relatórios fase 1: Excel como documento + prestação de contas por link | Backend | 3 | TASK-305, TASK-307 |
| [TASK-310](../tasks/TASK-310.md) | PDF da prestação de contas gerado no servidor (Next.js) + envio | Full-stack | 3 | TASK-309 |
| [TASK-311](../tasks/TASK-311.md) | Retenção (90 dias) + métricas do assistente | Backend | 3 | TASK-299 |
| [TASK-312](../tasks/TASK-312.md) | QA manual + automação (fluxos e segurança) | QA | 3 | TASK-305, TASK-306 |

Base de todas as branches: `staging`. Nome: `feature/TASK-XXX-descricao-curta`.

---

### TASK-299 — Módulo `assistant`: fila, worker, controle de fluxo, liga/desliga e piloto
**Escopo**
- Migration `assistant_inbound_messages` (wamid único) e `assistant_conversations`.
- `WhatsAppWebhookService.processChange`: com o assistente ligado, cada mensagem de entrada vai
  para a fila (hoje só loga). Statuses continuam como estão.
- Worker com `ThreadPoolTaskExecutor` dedicado e limitado; consumo via `SELECT … FOR UPDATE SKIP
  LOCKED`; processamento em ordem por usuário; retomada após reinício.
- Controle de fluxo: agrupamento de rajadas, um pedido por vez, limites (Bucket4j), limites de
  conteúdo, ignorar grupos, ecos e tipos não suportados, e instrução para desconhecido 1 vez/dia.
- `assistant.enabled` (padrão falso) + lista de liberação por usuário e organização.
- Endpoint de simulação em `dev/` (perfis local/staging) que injeta payloads da Meta.
- Handler provisório de eco ("recebido") só para o piloto validar o encanamento.

**Critérios de aceite**
- [ ] Mesma mensagem reenviada pela Meta é processada uma única vez.
- [ ] Três mensagens em 2 s do mesmo usuário viram um único processamento.
- [ ] Estouro de limite: uma resposta de aviso e as demais ignoradas.
- [ ] Assistente desligado: comportamento idêntico ao atual (só log).
- [ ] Usuário fora da lista de piloto: ignorado.
- [ ] Reinício da API no meio do processamento não perde a mensagem.

**Prompt para o Claude Code**: `execute a TASK-299 (EPIC-031): módulo assistant com fila em
tabela, worker dedicado, controle de fluxo e liga/desliga por usuário. Leia o EPIC-031 §Arquitetura
e §Controle de fluxo antes de começar.`

### TASK-300 — `WhatsAppClient` ampliado + cota
**Escopo**
- Envio de texto livre, botões de resposta (até 3), lista (até 10 opções), documento (PDF/XLSX),
  marcar como lida com indicador de digitação e download de mídia (`GET /{media-id}` → URL →
  bytes).
- Respeito à janela de 24h: fora da janela, recusa o envio livre (erro claro).
- Mensagens de resposta dentro da janela **não** consomem a cota mensal de WhatsApp do plano.

**Critérios de aceite**
- [ ] Cada tipo de envio coberto por teste com o `WebClient` mockado (payload conforme a Graph API).
- [ ] Download de mídia com limite de tamanho e timeout.
- [ ] Cota do plano inalterada ao responder dentro da janela.

**Prompt**: `execute a TASK-300 (EPIC-031): ampliar WhatsAppClient para texto, botões, lista,
documento, lida/digitando e download de mídia, sem consumir cota dentro da janela de 24h.`

### TASK-301 — Vínculo do número + consentimento + Perfil
**Escopo**
- Migrations `assistant_links` e `assistant_consents`; termo versionado (texto em PT-BR).
- API: iniciar ativação (gera código de 6 dígitos, 15 min, uso único), status e desativar.
- Worker: mensagem "ATIVAR <código>" vincula o `wa_id` remetente; "PARAR" revoga.
- Perfil (web): card "Assistente no WhatsApp" com aceite do termo, código + botão `wa.me` com
  texto pronto, status (ativo/inativo) e desativar. Estados de carregando, erro e vazio; mobile.

**Critérios de aceite**
- [ ] O número vinculado é o que **enviou** o código, não o digitado no Perfil.
- [ ] Código expirado ou reutilizado é recusado com mensagem clara.
- [ ] `wa_id` já vinculado a outro usuário é recusado.
- [ ] "PARAR" e desativar no Perfil cortam o acesso na mensagem seguinte.
- [ ] Opt-in de alertas (TASK-122) continua independente.

**Prompt**: `execute a TASK-301 (EPIC-031): vínculo do WhatsApp por código ATIVAR e consentimento
versionado, com card no Perfil.`

### TASK-302 — Contexto "em nome do usuário" + porta de domínio + escolha de organização
**Escopo**
- Executor que monta `SecurityContext` + `TenantContext` do usuário por mensagem e limpa em
  `finally`.
- Porta de domínio (`AssistantDomainGateway`) com as travas: vínculo com a organização,
  `FULL_ACCESS` para gravar, papel (`READER` só leitura), revalidação de usuário, consentimento e
  vínculo.
- Teste de arquitetura: todo handler que grava passa pela trava.
- Escolha de organização: uma → automática; várias → lista; "trocar condomínio" a qualquer momento.

**Critérios de aceite**
- [ ] Usuário não consegue ler nem gravar em organização a que não pertence (teste).
- [ ] Conta em somente leitura: consultas funcionam e gravação é recusada com mensagem clara.
- [ ] `READER` recebe recusa ao tentar registrar.
- [ ] Contexto nunca vaza entre mensagens (teste com duas mensagens de usuários diferentes na
  mesma thread).

**Prompt**: `execute a TASK-302 (EPIC-031): contexto de execução em nome do usuário e porta de
domínio com as mesmas travas do web (tenant, FULL_ACCESS, papel). Trate como revisão de segurança.`

### TASK-303 — Classificador + transcrição + crédito de IA
**Escopo**
- Atalhos determinísticos (menu numerado, botões, sim/corrigir/cancelar, ATIVAR, PARAR).
- IA com saída estruturada (JSON schema) na lista fechada de intenções + extração de campos
  (item, data, custo, tipo, responsável, período). Saída inválida → `FORA_DO_ESCOPO`.
- Transcrição de áudio via Spring AI (OpenAI), com limite de 2 min; o arquivo é descartado depois.
- Desconto no crédito de IA do plano; sem crédito → só menu/botões.

**Critérios de aceite**
- [ ] "Como faço isso em Python?" → `FORA_DO_ESCOPO` com resposta fixa.
- [ ] Nenhum texto da IA chega ao usuário (teste de contrato do montador de resposta).
- [ ] IA fora do ar → menu funciona.
- [ ] Áudio acima do limite é recusado sem transcrever.

**Prompt**: `execute a TASK-303 (EPIC-031): classificador de intenção com lista fechada e saída
estruturada, atalhos sem IA e transcrição de áudio.`

### TASK-304 — "Identificação/local" no item + `source`
**Escopo**
- Coluna opcional `location_label` (ex.: "Bloco B") em `maintenance_items`: API (criar/editar/
  listar) e web (formulário, lista, detalhe, exibição junto ao tipo).
- Coluna `source` (`WEB` padrão, `WHATSAPP`) em `maintenance_items` e `maintenances`.
- Detalhe da manutenção mostra "Registrado via WhatsApp" quando for o caso.

**Critérios de aceite**
- [ ] Itens existentes continuam funcionando sem o campo.
- [ ] Dois itens do mesmo tipo aparecem distinguíveis na lista.
- [ ] Contrato da API compatível (campos novos opcionais).

**Prompt**: `execute a TASK-304 (EPIC-031): campo opcional de identificação/local no item e coluna
source em item e manutenção.`

### TASK-305 — Consultas só leitura
**Escopo**: vencimentos (semana/30 dias), vencidos, histórico de um item (últimas 5), índice de
conformidade; até 10 linhas por resposta + link "ver todos"; nomes legíveis (portar
`formatItemType` para o backend); comparação entre condomínios → link para Relatórios.

**Critérios de aceite**
- [ ] Respostas batem com o que o dashboard e as listas mostram para a mesma organização.
- [ ] Organização sem itens: resposta útil (como começar), não lista vazia.
- [ ] Nenhuma consulta atravessa organizações.

**Prompt**: `execute a TASK-305 (EPIC-031): consultas só leitura pelo assistente, reaproveitando
os serviços de dashboard, itens e manutenções.`

### TASK-306 — Registro rápido com confirmação
**Escopo**
- Identificar o item pelo tipo (+ identificação/local); vários candidatos → lista; nenhum →
  proposta de item novo pelo catálogo curado (sem inventar norma, regra da TASK-212).
- Campos assumidos (data = hoje, tipo = Preventiva) aparecem no resumo.
- Ação pendente em `assistant_conversations` com expiração de 30 min; botões Confirmar/Corrigir/
  Cancelar; "corrigir" reinterpreta só os campos citados.
- Fotos/PDF recebidos durante a ação pendente → anexo (foto/laudo) via `MaintenanceAttachmentService`
  **após** confirmar (método novo que aceita bytes, sem `MultipartFile`).
- Gravação via `MaintenanceService.register` (regras existentes valem) com `source = WHATSAPP` +
  `audit_logs`.

**Critérios de aceite**
- [ ] Nada é gravado sem Confirmar.
- [ ] Expiração apaga a foto temporária.
- [ ] Data duplicada, somente leitura e papel sem permissão retornam as mensagens do próprio serviço.
- [ ] Item novo e manutenção são criados juntos e de forma atômica.
- [ ] Detalhe da manutenção no web mostra a origem e a foto.

**Prompt**: `execute a TASK-306 (EPIC-031): registro de manutenção pelo WhatsApp com resumo,
confirmação por botões, anexos após confirmar e origem auditada.`

### TASK-307 — Links diretos no web
**Escopo**: itens, manutenções, dashboard e relatórios aceitam organização e filtros pela URL
(ex.: `?org=…&status=OVERDUE`), trocando a organização ativa se o usuário tiver acesso. Sem login
automático: link sem sessão leva ao login e volta para o destino.

**Critérios de aceite**
- [ ] Link para organização sem acesso → mensagem clara, sem vazar dado.
- [ ] Após o login, o usuário cai na tela filtrada.

**Prompt**: `execute a TASK-307 (EPIC-031): links diretos com organização e filtros pela URL nas
telas de itens, manutenções, dashboard e relatórios.`

### TASK-308 — Onboarding conversacional
**Escopo**: só para conta existente, dentro de `maxOrganizations`. Perguntas: nome, tipo de empresa
(lista), CEP, e perguntas de sim/não geradas do catálogo do tipo (elevador, gerador, piscina, gás…).
Resumo "Vou cadastrar N itens" → Confirmar → `previewFromCatalog` + `apply` (sem IA).

**Critérios de aceite**
- [ ] Os itens criados são os mesmos que o onboarding web criaria para as mesmas respostas.
- [ ] Limite de organizações respeitado com mensagem clara.
- [ ] Abandono no meio não cria nada.

**Prompt**: `execute a TASK-308 (EPIC-031): novo condomínio pelo WhatsApp reaproveitando
catalog-preview e apply do onboarding web.`

### TASK-309 — Relatórios fase 1
**Escopo**
- **Regra documento × link**:
  - **documento fechado** (uma organização, período definido, para imprimir/enviar) → arquivo;
  - **exploratório** (filtros, vários condomínios, comparação de períodos, dashboard) → link.
- Excel de manutenções (export existente) enviado como documento.
- Prestação de contas: link da tela com o período preenchido.

**Caso ambíguo**: "relatório de conformidade" → documento só se o usuário disser PDF/assembleia/
prestação; senão, link do dashboard. Calendário `.ics` (export existente): opcional.

**Critérios de aceite**
- [ ] Excel recebido no WhatsApp igual ao baixado no web para o mesmo filtro.
- [ ] Pedido exploratório sempre responde com link.

**Prompt**: `execute a TASK-309 (EPIC-031): relatórios pelo WhatsApp: Excel como documento e
prestação de contas por link.`

### TASK-310 — PDF da prestação de contas no servidor
**Escopo**: rota no Next.js que renderiza o **mesmo** `PrestacaoContasPdfDocument` no servidor
(autenticada serviço a serviço, com escopo de organização e período); o assistente pede o PDF e
envia como documento. A tela continua gerando no navegador (ou passa a usar a rota).

**Critérios de aceite**
- [ ] PDF do WhatsApp idêntico ao baixado na tela.
- [ ] Rota inacessível sem a credencial de serviço; nunca devolve outra organização.

**Prompt**: `execute a TASK-310 (EPIC-031): gerar o PDF da prestação de contas no servidor
reaproveitando o componente react-pdf e enviar pelo assistente.`

### TASK-311 — Retenção + métricas
**Escopo**: job (ShedLock) que apaga o texto das mensagens com mais de 90 dias mantendo os
metadados; métricas: volume, intenções, `FORA_DO_ESCOPO`, tempo de resposta (p50/p95), falhas e
custo de IA estimado.

**Critérios de aceite**
- [ ] Após o job, nenhuma mensagem com mais de 90 dias tem conteúdo.
- [ ] Métricas visíveis no monitoramento existente.

**Prompt**: `execute a TASK-311 (EPIC-031): retenção de 90 dias e métricas do assistente.`

### TASK-312 — QA manual + automação do assistente (fluxos e segurança)
**Escopo**: plano de QA manual (em produção, com o usuário controlado do piloto) + testes
automatizados.
- Fluxos: ativação, consultas, registro com foto, correção, expiração, onboarding, relatórios.
- Segurança: número não verificado, organização alheia, conta em somente leitura, `READER`,
  tentativa de manipular a IA, rajada de mensagens e revogação com "PARAR".

**Critérios de aceite**
- [ ] Todos os cenários de segurança com evidência.
- [ ] Automação dos cenários de segurança na suíte do backend.

**Prompt**: `execute a TASK-312 (EPIC-031): plano de QA manual e testes automatizados de
segurança do assistente.`

---

## Decisões — respondidas em 26/09/2026

| # | Decisão | Resposta |
|---|---|---|
| 1 | Formato da confirmação | Botões Confirmar / Corrigir / Cancelar, aceitando também "sim" escrito |
| 2 | Validade da ação pendente | 30 minutos |
| 3 | Transcrição | OpenAI direto via Spring AI (a SAMU não tem transcrição) |
| 4 | Lembretes proativos fora da janela (pagos) | Não na v1 |
| 5 | Número compartilhado (ex.: portaria) | Um usuário por número na v1 |
| 6 | `TECH` registra manutenção? | Sim. `READER` só consulta |
| 7 | Planos | Todos, descontando do crédito de IA. Sem crédito: só menu e botões |
| 8 | Retenção | Mensagens por 90 dias. Áudio nunca guardado |
| 9 | Limites | Agrupar em 3 s · 20 msgs/10 min · 100/dia · texto 1.000 caracteres · áudio 2 min (configuráveis) |
| 10 | Campo "Identificação/local" no item | Sim, na Onda 1 (TASK-304) |
| 11 | PDF da prestação de contas | Link na v1 (TASK-309), geração no servidor depois (TASK-310) |
| 12 | Piloto | Conta demo + 1 ou 2 clientes depois do teste interno |
| 13 | Ambiente de teste | **Produção, com usuário controlado do Douglas**, via lista de liberação por usuário (assistente desligado por padrão). Local/staging usam o endpoint de simulação |
| 14 | Cloudflare/WAF | Status da Meta já chegam hoje → não deve precisar de regra nova. **Verificar** nos logs de produção se as mensagens recebidas aparecem (`Mensagem inbound recebida`) antes da TASK-299 |
| 15 | Microserviço separado | Não agora. Módulo interno com fronteira por interfaces; reavaliar se virar hub multicanal |

## Sequenciamento

```
Onda 1 — Fundação (piloto interno com eco ao final)
  TASK-299 ─┬─► TASK-301 ─► TASK-302
  TASK-300 ─┘
  TASK-299 ─► TASK-303
  TASK-304 (independente)

Onda 2 — Conversas (piloto real ao final: consultas + registro)
  TASK-305 ─► TASK-306        TASK-307 (independente, em paralelo)

Onda 3 — Onboarding, relatórios e qualidade
  TASK-308 · TASK-309 ─► TASK-310 · TASK-311 · TASK-312
```

## Riscos
- **Agir em nome do usuário (TASK-302)** é o maior risco. Um erro aqui vira acesso entre
  organizações. Exige revisão de segurança dedicada e o teste de arquitetura.
- **Teste em produção**: o código chega a produção antes do piloto. Mitigação: desligado por
  padrão, lista de liberação por usuário e chave para desligar sem deploy.
- **Qualidade da interpretação** (nomes de item, datas, valores em áudio): mitigada pelo resumo
  obrigatório com confirmação e pela correção por campo.
- **Mudanças de preço/política da Meta e da OpenAI**: custos revisados antes de abrir o piloto
  para clientes.
- **LGPD**: dados de condomínio passam pela OpenAI. Termo próprio, retenção curta e áudio
  descartado. Revisar a política de privacidade do site antes do piloto com clientes.
