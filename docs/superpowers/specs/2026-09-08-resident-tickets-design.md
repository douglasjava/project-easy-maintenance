# EPIC-027 — Chamados de Moradores

**Data:** 08/09/2026
**Status:** Aprovado por Douglas (brainstorm conduzido nesta data)

## Motivação

Ideia registrada em 07/09/2026 (macro, sem desenho): dar aos moradores das edificações atendidas
uma forma de abrir e acompanhar chamados/solicitações. Hoje o produto não modela "morador" como
tipo de usuário/acesso — todo o sistema é construído em torno de quem administra a manutenção
(ADMIN/MEMBER de uma `Organization`), sem canal estruturado pro morador reportar um problema.

## Contexto (levantado antes do desenho)

- `Organization` representa a edificação/condomínio inteiro como uma unidade só (um endereço) —
  **não existe** conceito de "unidade"/apartamento no schema hoje. `Organization.code` já é único
  e serve como identificador natural pra vincular o QR code físico à organização certa, sem
  precisar criar uma entidade nova só pra isso.
- `RateLimiterService` (`shared.ratelimit`) já existe e é usado em auth/reset/IA — reutilizável
  pros endpoints públicos deste épico (sem autenticação, logo mais expostos a abuso).
- `S3FileStorageService` (`infrastructure.storage`) é o serviço genérico de armazenamento já usado
  por baixo do fluxo de anexos de manutenção — reutilizável pra foto do chamado. **Não** reaproveita
  `MaintenanceAttachmentService` (módulo `assets`) diretamente — esse serviço é acoplado ao fluxo
  autenticado de manutenção e a checagem de limite por plano de billing, que não se aplica a um
  endpoint público de morador.
- Provedor de e-mail (Resend) e integração WhatsApp (Meta Cloud API) já existem e são reutilizáveis
  como canal de notificação — mesmo princípio do EPIC-023 (flag desligada por padrão, pronta pra
  ligar depois).
- Precedente de módulo isolado por domínio já é o padrão do projeto (`assets`, `billing`,
  `catalog_norms`, `org_users` — cada um com `domain`/`application`/`infrastructure` próprios).

## Decisões de escopo (brainstorm, 08/09/2026)

1. **Identidade do morador: sem conta completa.** QR code físico fixado na edificação carrega o
   `Organization.code` já existente. Pra abrir um chamado, morador informa nome, telefone e CPF
   (ambos telefone e CPF **obrigatórios**, intencionalmente, pra dar um mínimo de seriedade/reduzir
   spam). Pra acompanhar depois, usa **só o CPF** como chave de consulta ("login" informal, sem
   senha).
2. **Chamado é sempre relato livre** — sem vínculo com o catálogo de itens (`MaintenanceItem`)
   existente. Cobre qualquer tipo de problema (barulho, vazamento, item quebrado ou nem cadastrado),
   sem exigir que o morador entenda a estrutura interna de itens da organização.
3. **Foto opcional na abertura** — 1 arquivo por chamado (não lista), reaproveitando
   `S3FileStorageService` via presigned URL (mesmo mecanismo já usado nos anexos de manutenção,
   TASK-027). Por ser endpoint público sem autenticação, o limite fica mais conservador que o dos
   anexos internos (a definir na implementação, referência: teto atual de anexo de manutenção é
   20MB — aqui deve ficar bem menor, é uma foto de celular, não um PDF).
4. **Fluxo público em 2 telas**, não um formulário único:
   - Tela 1 (`/c/{orgCode}`): só campo de CPF, botão "Entrar". URL curta e memorável — o público
     final é limitado tecnicamente e a maior parte do acesso vem do QR code (não digitação manual),
     mas quando precisar ser falado/digitado, quanto mais curto melhor.
   - Tela 2: lista "Meus chamados" (status de cada um por essa organização+CPF) + botão "Abrir novo
     chamado", que abre o formulário (nome, telefone, descrição, foto opcional). CPF já vindo da
     tela 1, não precisa repetir.
5. **Notificação pro lado da administradora: e-mail agora, WhatsApp preparado pra depois.** Ao abrir
   um chamado, e-mail (Resend) pros usuários ADMIN da organização. Envio por WhatsApp fica atrás de
   uma flag desligada por padrão (`notification.whatsapp.resident-ticket-enabled=false`), mesmo
   padrão já usado no EPIC-023 — pronta pra ligar quando decidido. **Sem notificação de volta pro
   morador** nesta v1 (só telefone/CPF são capturados, sem e-mail; morador confere status voltando
   no link/CPF).
6. **Kanban no painel interno com 3 colunas** (`SOLICITADO` → `EM_ANDAMENTO` → `CONCLUIDO`) e
   **arrastar-e-soltar de verdade** (não só dropdown de status) — decisão explícita de Douglas,
   aceitando o esforço extra de trazer uma biblioteca de drag-and-drop nova ao projeto (nenhuma
   existe hoje). Só usuários já autenticados (ADMIN/MEMBER) da organização veem/movem os chamados
   da própria org — mesma regra de acesso multi-tenant (`X-Org-Id`) do resto do sistema.
7. **Código organizado em módulo isolado**, backend e frontend — decisão explícita de Douglas pra
   manter fácil de implementar e visualizar, sem espalhar em módulos existentes.

---

## Arquitetura

### Modelo de dado

Nova entidade `ResidentTicket` (nome de tabela/classe exato a definir na implementação — módulo
próprio, ex. `resident_tickets`):

| Campo | Tipo | Observação |
|---|---|---|
| `id` | Long | PK |
| `organizationId` | Long (FK) | Vínculo via `Organization.code` recebido na abertura |
| `residentName` | String | — |
| `residentPhone` | String | Obrigatório |
| `residentCpf` | String | Obrigatório — chave de consulta na tela 2 |
| `description` | String (texto livre) | — |
| `photoUrl` | String, nullable | Preenchido só se o morador anexar foto |
| `status` | Enum: `SOLICITADO`/`EM_ANDAMENTO`/`CONCLUIDO` | Default `SOLICITADO` na criação |
| `createdAt`/`updatedAt` | Instant | Padrão já usado em todo o schema |

Sem soft delete específico decidido ainda — segue o padrão já usado no restante do schema
(`@SQLDelete`/`deleted_at`) se fizer sentido na implementação.

### Endpoints

**Públicos (sem JWT, protegidos por `RateLimiterService`):**
- `POST /public/resident-tickets` — corpo: `organizationCode`, `residentName`, `residentPhone`,
  `residentCpf`, `description`, `photoUrl` (opcional, já resultante do upload presigned). Cria em
  `SOLICITADO`, dispara e-mail pros ADMINs da org (best-effort, não bloqueia a criação se falhar).
- `GET /public/resident-tickets?organizationCode=X&cpf=Y` — lista chamados daquele CPF, naquela
  organização. Rate-limited (mesma preocupação de enumeração de CPF já levantada e aceita com esse
  controle).
- `POST /public/resident-tickets/upload-url` (ou nome equivalente) — gera presigned URL pro upload
  da foto, via `S3FileStorageService`, com limite de tamanho conservador e tipo de arquivo
  restrito a imagem. Rate-limited.

**Autenticados (JWT + `X-Org-Id`, mesmo padrão do resto do sistema):**
- `GET /resident-tickets` — lista os chamados da organização corrente, pro kanban.
- `PATCH /resident-tickets/{id}/status` — muda status (disparado pelo drag-and-drop).

### Backend — módulo isolado

Novo pacote de domínio (nome exato a definir, ex. `resident_tickets`), espelhando a estrutura já
usada por `assets`/`billing`/`catalog_norms`:
- `domain/` — entidade `ResidentTicket`, enum de status.
- `application/service/` — serviço de criação (valida CPF/telefone, dispara e-mail best-effort),
  serviço de consulta pública, serviço de listagem/mudança de status autenticado.
- `application/dto/` — requests/responses dos 4 endpoints acima.
- `infrastructure/web/` — dois controllers separados (`ResidentTicketsPublicController` sem
  `@PreAuthorize`, `ResidentTicketsController` autenticado) — separação física reforça que um é
  público e o outro não, reduz risco de vazar autenticação por engano.
- `infrastructure/persistence/` — repository JPA.

Dependências externas do módulo: `S3FileStorageService` (upload), `RateLimiterService` (throttle),
provedor de e-mail existente (notificação), `OrganizationRepository` (resolver `organizationCode`).
Nenhuma dependência no sentido contrário — módulos existentes não precisam saber que
`resident_tickets` existe.

### Frontend — rota isolada

Nova rota `src/app/c/[orgCode]/` (fora do layout autenticado normal — sem sidebar/navbar interna,
tela pública própria):
- `page.tsx` — tela 1 (campo de CPF).
- `chamados/page.tsx` (ou equivalente) — tela 2 (lista + botão abrir novo).
- Componentes próprios da feature num subdiretório local (`_components/` ou `components/`), sem
  reaproveitar componentes das telas internas de manutenção — telas visualmente/funcionalmente
  diferentes (público vs. autenticado).

Painel interno (autenticado): nova página/seção com o kanban de 3 colunas, biblioteca
**dnd-kit** (recomendada — leve, mantida ativamente, acessível; alternativa descartada:
`@hello-pangea/dnd`, fork mais antigo do react-beautiful-dnd, comunidade menor).

### QR code (achado depois do desenho inicial — geração/exibição pro ADMIN)

O QR code físico fixado na edificação precisa ser gerado e disponibilizado em algum lugar das
rotas privadas — não estava coberto na primeira versão do desenho. Como o QR só encoda a URL
pública (`/c/{orgCode}`, a partir do `Organization.code` que a tela autenticada já tem
disponível), **não precisa de endpoint novo no backend** — geração 100% client-side via biblioteca
leve (ex. `qrcode`).

Decisão (08/09/2026): fica em **Configurações/Perfil da organização** (não junto do kanban) — tratado
como algo que se configura uma vez, não uma tela de uso diário. Nova seção nessa página existente
mostrando o QR code + botão de baixar/imprimir.

---

## Fora de Escopo (v1)

- Notificação proativa de volta pro morador (WhatsApp fica com a flag pronta, desligada; e-mail não
  se aplica — não capturamos e-mail do morador nesta v1).
- Vínculo do chamado com o catálogo de itens existente.
- Conceito de "unidade"/apartamento — o vínculo fica só no nível da organização inteira.
- Múltiplas fotos por chamado (só 1).
- Edição/cancelamento do chamado pelo próprio morador depois de aberto.

## Riscos

- **Enumeração de CPF**: o endpoint público de consulta (`GET /public/resident-tickets`) permite,
  em tese, tentar CPFs até achar um válido pra aquela organização. Mitigado por rate limit
  (`RateLimiterService`), mas é um risco aceito conscientemente — decisão de produto de Douglas de
  priorizar simplicidade de acesso sobre uma barreira mais forte. Não expõe dado sensível além do
  status/descrição dos próprios chamados daquele CPF.
- **Abuso do upload público de foto**: endpoint de presigned URL é público — precisa de rate limit
  + restrição de tipo/tamanho de arquivo bem definida na implementação, pra não virar vetor de
  custo de armazenamento ou abuso de conteúdo.
- **Esforço de drag-and-drop**: biblioteca nova no frontend (nenhuma hoje) — mais superfície de
  teste/manutenção que um dropdown simples, aceito conscientemente pela decisão de UX.
- Baixo risco pro restante do sistema — módulo novo, isolado, sem alterar nenhum fluxo/entidade
  existente.
