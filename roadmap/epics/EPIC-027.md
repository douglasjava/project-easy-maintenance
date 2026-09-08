# EPIC-027 — Chamados de Moradores

## Status
Desenhado via brainstorm com Douglas (08/09/2026), pronto para implementar. Spec em
`docs/superpowers/specs/2026-09-08-resident-tickets-design.md`. Ideia original registrada em
07/09/2026 (macro, sem desenho).

## Objetivo
Dar aos moradores das edificações atendidas uma forma de abrir e acompanhar chamados/solicitações
— hoje o produto só modela quem administra a manutenção (ADMIN/MEMBER de uma `Organization`), sem
canal estruturado pro morador reportar um problema.

## Descrição

Morador acessa via QR code físico fixado na edificação (encoda o `Organization.code` já existente
— sem criar conceito novo de "unidade"). Fluxo público em 2 telas (`/c/{orgCode}`): tela 1 só pede
CPF ("Entrar"); tela 2 lista "Meus chamados" daquele CPF + botão pra abrir um novo (nome, telefone,
descrição livre, foto opcional). Telefone e CPF são obrigatórios na abertura (mínimo de
seriedade/anti-spam); CPF sozinho é a chave de consulta depois — sem senha, sem conta completa.

Chamado é sempre relato livre, sem vínculo com o catálogo de itens existente. Ao abrir, dispara
e-mail pros ADMINs da organização (WhatsApp fica com flag pronta, desligada por padrão — mesmo
padrão do EPIC-023). Painel interno (autenticado, `X-Org-Id`) ganha um kanban de 3 colunas
(`SOLICITADO`/`EM_ANDAMENTO`/`CONCLUIDO`) com arrastar-e-soltar de verdade (biblioteca `dnd-kit`,
nenhuma existe hoje no projeto). QR code em si é gerado client-side (sem endpoint novo), exibido
numa seção nova em Configurações/Perfil da organização, com botão de baixar/imprimir.

**Decisão importante**: v1 entrega só isso — sem notificação proativa de volta pro morador (só
telefone/CPF capturados, sem e-mail), sem vínculo com o catálogo de itens, sem conceito de
"unidade"/apartamento (fica no nível da organização inteira).

---

## Contexto Técnico

- `Organization.code` já existe e é único — reaproveitado como identificador do QR code, sem
  entidade nova.
- `RateLimiterService` (já usado em auth/reset/IA) protege os endpoints públicos (sem autenticação,
  mais expostos a abuso — enumeração de CPF, abuso de upload).
- `S3FileStorageService` (genérico, usado por baixo do fluxo de anexos de manutenção) é reutilizado
  pro upload da foto — **não** reaproveita `MaintenanceAttachmentService` diretamente (acoplado ao
  fluxo autenticado + billing plan, não se aplica aqui).
- Módulo backend isolado (`resident_tickets`, nome exato a definir), espelhando a estrutura já
  usada por `assets`/`billing`/`catalog_norms` (`domain`/`application`/`infrastructure` próprios).
  Dois controllers separados (público sem `@PreAuthorize`, autenticado) — separação física reduz
  risco de vazar autenticação por engano.
- Frontend: rota isolada `src/app/c/[orgCode]/`, fora do layout autenticado normal (sem
  sidebar/navbar interna).

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-237](../tasks/TASK-237.md) | Backend: módulo público de chamados (abrir, consultar por CPF, upload de foto) | BACKEND | 🟠 Alto |
| [TASK-238](../tasks/TASK-238.md) | Backend: endpoints autenticados (listar/mudar status) + notificação por e-mail + flag WhatsApp | BACKEND | 🟠 Alto |
| [TASK-239](../tasks/TASK-239.md) | Frontend: fluxo público em 2 telas (`/c/[orgCode]`) | FRONTEND | 🟠 Alto |
| [TASK-240](../tasks/TASK-240.md) | Frontend: kanban interno (drag-and-drop) + QR code em Configurações/Perfil | FRONTEND | 🟠 Alto |

Ordem: TASK-237 e TASK-238 são independentes entre si no backend (podem andar em paralelo).
TASK-239 depende de TASK-237 (precisa dos endpoints públicos prontos). TASK-240 depende de
TASK-238 (precisa dos endpoints autenticados) — a parte de QR code dentro dela não tem dependência
técnica (é puramente client-side), mas fica junto por viver na mesma tela/módulo de frontend.

---

## Critério de Conclusão do Épico

- [ ] Morador abre um chamado via `/c/{orgCode}` (nome, telefone, CPF, descrição, foto opcional)
      sem precisar de login/conta
- [ ] Morador consulta seus chamados de volta usando só o CPF
- [ ] ADMINs da organização recebem e-mail quando um chamado é aberto
- [ ] Painel interno mostra o kanban de 3 colunas com drag-and-drop funcional, restrito a
      ADMIN/MEMBER da própria organização (`X-Org-Id`)
- [ ] QR code da organização disponível em Configurações/Perfil, com botão de baixar/imprimir
- [ ] Endpoints públicos protegidos por rate limit (abertura, consulta por CPF, upload de foto)
- [ ] `mvn test`/`npm run build` sem regressão

---

## Fora de Escopo

- Notificação proativa de volta pro morador (WhatsApp com flag pronta, desligada; sem e-mail do
  morador nesta v1).
- Vínculo do chamado com o catálogo de itens (`MaintenanceItem`) existente.
- Conceito de "unidade"/apartamento — vínculo fica só no nível da organização inteira.
- Múltiplas fotos por chamado (só 1).
- Edição/cancelamento do chamado pelo próprio morador depois de aberto.

## Riscos
Baixo pro restante do sistema — módulo novo, isolado, sem alterar fluxo/entidade existente. Riscos
próprios do épico: enumeração de CPF no endpoint público de consulta (mitigado por rate limit,
risco aceito conscientemente por Douglas em troca de simplicidade de acesso); abuso do upload
público de foto (mitigado por rate limit + restrição de tipo/tamanho); esforço extra de trazer uma
biblioteca de drag-and-drop nova ao frontend (decisão explícita de Douglas, não um dropdown mais
simples).
