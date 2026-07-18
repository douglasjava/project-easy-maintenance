# TASK-123 — Full-Stack: Exportar lembrete de item para o calendário (.ics)

## Tipo
FULL_STACK

## Categoria
Produto / Lembretes / Item

## Prioridade
🟡 Médio

## Épico
EPIC-006 — Produto / Experiência do Usuário

## Fase
2 — Pós-lançamento

## QA obrigatório
Sim — validar o arquivo `.ics` gerado abrindo de verdade no Google Calendar (e idealmente também
Outlook/Apple Calendar), e validar isolamento por organização no endpoint.

---

## Contexto e motivação

Discutido com Douglas antes de virar card (ver histórico de brainstorming da sessão — design aprovado
em 14/07/2026). Ideia: dar ao usuário uma forma de levar o vencimento de um item de manutenção para o
calendário pessoal dele. Reforça o posicionamento do produto ("sai das planilhas e do WhatsApp para um
sistema centralizado") oferecendo mais um lugar onde o síndico/gestor já vive no dia a dia — o
calendário — sem duplicar o app de notificações in-app/push/e-mail já existente (nem o WhatsApp da
TASK-122): é um lembrete complementar, não um canal de notificação novo no `NotificationOrchestratorService`.

### Decisão de escopo (v1, deliberada)

Duas abordagens foram avaliadas:

1. **Sync automático via Google Calendar API (OAuth2)** — o sistema cria/atualiza o evento sozinho
   sempre que `nextDueAt` muda, sem ação manual do usuário. Descartada para a v1: exige tela de
   consentimento OAuth, armazenamento/renovação de refresh token por usuário, e — como o app é
   multi-tenant em produção — passar pela verificação de app sensível do Google para o escopo de
   Calendar (processo longo, pode exigir CASA assessment). Não existe hoje nenhuma integração OAuth com
   Google no backend (o único uso de Google é `GooglePlacesConfig`/`GooglePlacesProperties`, autenticação
   por API key para autocomplete de endereço — modelo bem diferente).
2. **Exportação manual de arquivo `.ics`** *(escolhida para v1)* — usuário clica um botão, baixa/abre um
   arquivo `.ics` com o evento do item, e importa no calendário que usar (Google, Outlook, Apple). Sem
   OAuth, sem token armazenado, sem revisão de app pelo Google, implementável em poucos dias.

Também foi avaliado (e descartado para v1) o link direto de "Adicionar ao Google Calendar" (`calendar.google.com/calendar/render`) — mais simples que `.ics` (abre em 1 clique, sem download), mas só
funciona com Google Calendar e **não permite embutir lembrete customizado** (`VALARM`), ficando
dependente do lembrete padrão que o usuário já tem configurado. O `.ics` foi preferido por funcionar em
qualquer app de calendário e permitir controlar o lembrete.

### Limitação conhecida e aceita para v1

O `.ics` é uma "foto" do momento do clique. Se o usuário concluir a manutenção antes do prazo, adiar, ou
o item mudar de data por qualquer motivo depois da exportação, **o evento no calendário do usuário não
se atualiza sozinho** (sem OAuth não há como o backend alcançar o calendário do usuário depois do
download). Mitigação decidida: incluir na descrição do evento um aviso + link de volta para o item no
app, orientando o usuário a conferir o status atualizado. Sem mecanismo ativo de resync — aceito
conscientemente para não aumentar o escopo da v1.

---

## Escopo

### Backend

- Novo endpoint `GET /me/items/{id}/calendar.ics` (módulo `assets`), autenticado e escopado por
  organização como qualquer outro recurso de `MaintenanceItem` — usuário de outra org não pode baixar o
  `.ics` de um item que não é seu.
- Gerado sob demanda a partir do `MaintenanceItem.nextDueAt` atual — **sem persistência nova, sem
  tabela de auditoria de exportação** (é serialização pura, não haverá tracking de "quando foi
  exportado").
- Resposta `Content-Type: text/calendar` com um único `VEVENT`:
  - Evento de dia inteiro: `DTSTART;VALUE=DATE` = `nextDueAt` (não há horário associado ao vencimento).
  - Dois `VALARM`: `-P7D` (7 dias antes) e `-P1D` (1 dia antes).
  - `SUMMARY`: `Manutenção: {itemType}` (mesmo nome/label já exibido em `/items`).
  - `DESCRIPTION`: categoria (`itemCategory`), criticidade (`criticality`), aviso de que o status pode
    ter mudado desde a exportação, com link para `https://www.easymaintenance.com.br/items/{id}`.
- Sem custo de terceiros, sem quota, sem segredo/credencial novo — ao contrário da TASK-122 (WhatsApp),
  não há necessidade de rate limiting ou controle de custo por mensagem.

### Frontend

- Botão "Adicionar ao calendário" (ícone de calendário) na tela de detalhe do item, ao lado das ações
  já existentes.
- Clique dispara download do `.ics` gerado pelo endpoint; comportamento de abrir direto no app de
  calendário ou salvar o arquivo fica a critério do navegador/SO (sem lógica extra no frontend).
- Tratamento de erro: toast padrão já usado nas outras telas em caso de falha de rede/permissão.

### Fora de escopo da v1 (registrado para não virar ambiguidade depois)

- Sync automático via OAuth2.
- Exportação em lote (`.ics` com todos os itens pendentes de uma vez).
- Botão na listagem `/items` ou no card "Atenção Agora" do dashboard — só no detalhe do item por ora.
- Qualquer mecanismo de resync/atualização do evento já exportado.

---

## Arquivos impactados (estimativa)

### Backend
- Novo controller/endpoint em `assets/infrastructure/web/` (ou onde já vive o controller de item) —
  `GET /me/items/{id}/calendar.ics`
- Novo service/builder de `.ics` (ex.: `assets/application/service/ItemCalendarExportService.java`)

### Frontend
- Tela de detalhe do item — botão "Adicionar ao calendário"

---

## Critérios de Aceite

- [x] `GET /easy-maintenance/api/v1/items/{id}/calendar.ics` retorna um `.ics` válido
      (`VCALENDAR`/`VEVENT` bem formado) — testado em `ItemCalendarExportServiceTest`
- [x] Evento tem `DTSTART` = `nextDueAt` do item, como evento de dia inteiro (`DTSTART;VALUE=DATE`)
- [x] Evento tem 2 `VALARM` (7 dias antes e 1 dia antes) — `TRIGGER:-P7D` e `TRIGGER:-P1D`
- [x] Descrição do evento inclui categoria, criticidade e link de volta para o item no app
- [x] Usuário de uma organização não consegue baixar o `.ics` de item de outra organização — reaproveita
      `MaintenanceItemService.validateTenant` (mesmo padrão do `findById`), propaga `TenantException`
      (403), testado
- [x] Botão "Adicionar ao calendário" visível na tela de detalhe do item, dispara o download
- [x] Teste manual: arquivo importado de verdade no Google Calendar exibe título, data e os 2 lembretes
      corretamente — **confirmado por Douglas**, testou e importou certinho nos calendários

## Implementação

### Backend
- `assets/application/service/MaintenanceItemService.java` — novo método público
  `findEntityForOrg(orgId, itemId)`, reaproveita a validação de tenant já existente (`validateTenant`)
  para devolver a entidade completa (necessário para `criticality`, que não está no `ItemResponse`).
- `assets/application/service/ItemCalendarExportService.java` — **novo**, gera o `.ics` (VEVENT de dia
  inteiro + 2 VALARM), com escaping e line folding conforme RFC 5545 §3.1 (limite de 75 caracteres por
  linha de conteúdo). Lança `RuleException` (400 `rules-invalid`) se o item não tiver `nextDueAt`.
- `assets/infrastructure/web/ItemsController.java` — novo endpoint
  `GET /{id}/calendar.ics`, mesmo padrão de download já usado em
  `MaintenancesController.exportCsv` (`Content-Disposition: attachment`, `ResponseEntity<byte[]>`).
- `assets/application/service/ItemCalendarExportServiceTest.java` — **novo**, 4 testes: VEVENT/VALARM
  válidos, erro sem `nextDueAt`, propagação de `TenantException` em org errada, folding de linhas longas.

### Frontend
- `app/items/[id]/page.tsx` — botão movido do cabeçalho (ficou apertado ao lado de Editar/Remover/
  Registrar Manutenção — feedback do Douglas após teste) para um link contextual "+ calendário" ao lado
  do valor de "Próximo vencimento", condicionado a `data.nextDueAt` existir. Mesmo padrão de download
  blob já usado em `app/maintenances/page.tsx` (`handleExportCsv`).
- `app/items/page.tsx` (listagem) — botão "Calendário" adicionado antes do "Abrir" em cada linha, tanto
  na tabela desktop quanto no card mobile (nesse último, sem `flex-fill` para não apertar os outros 3
  botões — mesmo problema de UX identificado no detalhe, evitado preventivamente aqui).

### Resultados
- 565/565 testes backend green (4 novos).
- `tsc --noEmit` e `eslint` limpos nos 3 arquivos alterados (avisos/erro pré-existentes confirmados via
  `git stash` — mesma linha antes da minha mudança, fora do escopo desta task).
- Branches criadas a partir de `staging`: `feat/task-123-item-calendar-ics` (API e Web).
- **Validado por Douglas**: testou de verdade e o `.ics` importou corretamente nos calendários.

## Dependências
Nenhuma — feature isolada, não depende de outras tasks em aberto.

## Riscos
- Baixo. Pior caso é o usuário confiar num lembrete desatualizado (mitigado pelo aviso na descrição do
  evento) — não há risco de custo, segurança ou bloqueio de conta como no canal WhatsApp (TASK-122).

## Esforço
Pequeno (endpoint + geração de `.ics` + botão no frontend — sem integração externa, sem migration)

## Status
Done — implementação, testes automatizados e validação manual (Douglas) completos. Ajuste de UX
aplicado após feedback: botões do detalhe do item estavam apertados; calendário virou link contextual
junto ao "Próximo vencimento", e a listagem `/items` ganhou o mesmo botão em cada linha.
