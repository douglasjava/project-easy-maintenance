# TASK-142 — Backend: Resolver autor de cada anexo de manutenção (rastreabilidade de evidência)

## Tipo
BACKEND

## Categoria
Manutenções / Compliance e Auditoria

## Prioridade
🟡 Médio

## Épico
[EPIC-016](../epics/EPIC-016.md) — Cancelamento de Manutenções com Motivo

## QA obrigatório
Sim — é a peça que sustenta a decisão de produto de "pode anexar evidência depois, desde que fique
claro quando e por quem".

---

## Contexto

Durante o desenho do EPIC-016 (conversa com Douglas, 25/07/2026), surgiu a pergunta: anexar uma
evidência (comprovante/certificado) dias depois da manutenção fere compliance? A resposta é **não**,
desde que fique visível *quando* e *por quem* foi anexado — diferente de editar a manutenção em si
(que muda um fato), anexar depois só completa a documentação, e o sistema já registra isso de forma
rastreável.

`MaintenanceAttachment` já tem `uploadedAt` (`Instant`) e `uploadedByUserId` (`Long`) persistidos.
O gap não é de dado, é de exposição:
- `MaintenanceAttachmentResponse` (retornado por `GET
  /{maintenanceId}/attachments`) **já** expõe os dois campos, mas `uploadedByUserId` é só um ID cru,
  sem nome resolvido.
- `MaintenanceAttachmentSimpleResponse` (o que vem embutido dentro de `MaintenanceResponse.attachments`,
  usado na tela de detalhe da manutenção) **não** expõe nenhum dos dois campos — só `id`, `fileName`,
  `attachmentType`.

---

## Objetivo

Dar ao frontend um jeito de exibir "anexado por {nome} em {data}" pra cada comprovante, sem exigir
uma chamada extra por anexo.

---

## Escopo

### 1. Resolver nome do autor em lote

- Seguir o mesmo padrão já usado na TASK-104 ("Registrado por" nos CSVs de manutenções — resolução
  batch via `UserRepository`, sem N+1): resolver `uploadedByUserId` → nome do usuário numa única
  query por lista de anexos, não uma query por anexo.

### 2. Expor os campos onde o frontend precisa

- Decidir durante a implementação a forma mais simples: ou (a) enriquecer
  `MaintenanceAttachmentSimpleResponse` com `uploadedByName`/`uploadedAt`, ou (b) o frontend passa a
  consumir `GET /{maintenanceId}/attachments` (que já tem os dados brutos) em vez do array embutido,
  e essa task só resolve o nome nesse endpoint já existente. Preferência inicial pela opção (a) —
  evita uma chamada de rede extra por manutenção aberta na tela.

### 3. Testes

- Resolução de nome em lote sem N+1 (mesmo tipo de verificação já feito na TASK-104).
- Anexo sem `uploadedByUserId` (dado legado, se existir) não quebra a resolução — cai num fallback
  razoável (ex.: "Usuário removido" ou omite o campo).

---

## Arquivos impactados (estimativa)

### Backend
- `assets/application/dto/MaintenanceAttachmentSimpleResponse.java` (ou
  `MaintenanceAttachmentResponse.java`, conforme decisão do item 2) — novos campos
  `uploadedByName`/`uploadedAt`
- `assets/application/service/MaintenanceService.java` ou `MaintenanceAttachmentService` — resolução
  batch do nome, reaproveitando o padrão da TASK-104

---

## Critérios de Aceite

- [ ] Nome do autor de cada anexo disponível na resposta usada pelo frontend, sem N+1
- [ ] Data/hora do upload disponível na mesma resposta
- [ ] Anexo com autor não resolvível não quebra a listagem (fallback definido)
- [ ] Testes cobrindo a resolução em lote

## Dependências
Nenhuma — pode começar imediatamente, independente das outras tasks do épico.

## Riscos
Nenhum risco relevante — é uma extensão pequena de um padrão já validado (TASK-104).

## Esforço
Baixo (reaproveita padrão já existente, só aplicado a uma entidade diferente)

## Status
**Concluída** — implementado na branch `feature/EPIC-016-cancel-maintenance-reason`, 707/707 testes
backend green à época (713/713 na suíte final do épico). QA manual aprovado. Commitado, com PR
aberto para `staging`.

## Implementação

- Opção (a) do card: `MaintenanceAttachmentSimpleResponse` ganhou `uploadedByUserId`/`uploadedAt`/
  `uploadedByName` — sem chamada de rede extra pro frontend.
- `withAttachmentAuthorNames` (dois overloads: um resolve sozinho a partir da lista, outro recebe um
  mapa já pronto) reaproveita `resolveUserNames`/`resolvedName`, os mesmos helpers já criados na
  TASK-141 pra `cancelledByName` — nenhuma duplicação de lógica de resolução de nome.
- **Sem N+1 garantido em dois níveis**: `findById` (uma manutenção) resolve os autores dos seus
  anexos numa query; `findCancelledByItem` (N manutenções) foi refeito pra buscar **todos** os
  anexos de **todas** as manutenções canceladas do item numa única query
  (`findByMaintenanceIdIn`, novo método no repositório) e resolver todos os nomes de upload numa
  única query também — não uma por manutenção. Coberto explicitamente por
  `findCancelledByItem_resolvesAttachmentAuthors_acrossMultipleMaintenances_withoutNPlusOne`, que
  verifica via Mockito que `findByMaintenanceIdIn` é chamado exatamente 1 vez e `findByMaintenanceId`
  nunca é chamado nesse fluxo.
- Fallback `"—"` quando o autor do upload não é resolvível, mesmo padrão de `cancelledByName`.
- 4 testes novos em `MaintenanceAttachmentAuthorTest.java` (novo arquivo).
