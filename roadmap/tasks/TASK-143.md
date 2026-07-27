# TASK-143 — Frontend: Permitir anexar evidência a manutenções existentes, exibindo autor e data

## Tipo
FRONTEND

## Categoria
Manutenções / Compliance e Auditoria

## Prioridade
🟡 Médio

## Épico
[EPIC-016](../epics/EPIC-016.md) — Cancelamento de Manutenções com Motivo

## QA obrigatório
Sim — validar visualmente que fica claro "quando" e "quem" anexou, não só o link do arquivo.

---

## Contexto

Foi o gap que motivou toda a investigação deste épico: o backend já suporta anexar um comprovante a
uma manutenção **já existente** (`POST /{maintenanceId}/attachments`), mas o upload hoje só está
cabeado em `maintenances/new/page.tsx` (tela de criação) — não existe nenhum botão de "adicionar
anexo" numa manutenção já registrada. `maintenances/page.tsx` (listagem/detalhe) só tem download.

Decisão de produto (Douglas, 25/07/2026): permitir anexar depois é aceitável e não fere compliance,
**desde que fique visível quem e quando anexou** — depende da TASK-142 (nome resolvido + data
disponíveis na resposta).

---

## Objetivo

Deixar o usuário completar a documentação de uma manutenção já registrada, com rastreabilidade clara
de quando e por quem cada anexo foi de fato adicionado.

---

## Escopo

### 1. Ação de adicionar anexo em manutenção existente

- No detalhe da manutenção (`maintDetail`, em `maintenances/page.tsx`), adicionar a mesma UI de
  upload já usada em `maintenances/new/page.tsx` (tipo de anexo + seleção de arquivo), reaproveitando
  o componente se possível em vez de duplicar.
- Disponível em manutenções válidas (não em canceladas — ver TASK-141).

### 2. Exibir autor e data de cada anexo

- Cada anexo listado passa a mostrar "Anexado por {nome} em {data/hora}" (dado vindo da TASK-142),
  não só o nome do arquivo e o link de download.
- Quando o anexo foi adicionado no mesmo dia da manutenção, pode exibir de forma mais discreta;
  quando foi adicionado depois, o formato deve deixar isso claro sem soar como um alerta de erro —
  é um comportamento esperado, não uma exceção.

### 3. Testes

- Upload de anexo numa manutenção existente atualiza a lista sem precisar recarregar a página.
- Autor e data aparecem corretamente pra anexos adicionados em momentos diferentes.

---

## Arquivos impactados (estimativa)

### Frontend
- `src/app/maintenances/page.tsx` — ação de upload no detalhe, exibição de autor/data por anexo
- Componente de upload reaproveitado de `maintenances/new/page.tsx`, se viável

---

## Critérios de Aceite

- [ ] É possível anexar um novo comprovante a uma manutenção já registrada, sem precisar editar
      nada mais
- [ ] Cada anexo mostra claramente quem e quando foi adicionado
- [ ] Ação de anexar não aparece em manutenções canceladas
- [ ] Upload atualiza a lista de anexos na tela sem reload

## Dependências
- **TASK-142** — nome do autor e data precisam estar disponíveis na resposta usada pelo frontend.

## Riscos
Nenhum risco técnico relevante — reaproveita upload já existente na tela de criação.

## Esforço
Baixo/Médio (reaproveitamento de componente de upload já existente + exibição de metadados novos)

## Status
**Concluída** — implementado na branch `feature/EPIC-016-cancel-maintenance-reason`
(`easy-maintenance-web`). `npm run build` limpo, `npm test` 86/89 (3 falhas pré-existentes, não
relacionadas). QA manual aprovado (C8). Commitado, com PR aberto para `staging`.

## Implementação

- Reaproveitou o **mesmo fluxo de upload** de `maintenances/new/page.tsx` (presigned URL: `POST
  .../attachments/upload-url` → `PUT` direto pro S3 → `POST .../attachments/confirm`), não o
  endpoint multipart direto — mantém consistência com o único caminho de upload já testado em
  produção, em vez de introduzir um segundo mecanismo.
- **Permissão diferente da TASK-140 de propósito**: o backend não restringe upload de anexo a
  ADMIN/SYNDIC (só `@RequireTenant`) — mesmo nível de `permissions.canRegisterMaintenance`, já usado
  nesta página pro botão "Registrar manutenção". Diferente do cancelamento (TASK-140), que usa o
  `userRole` bruto porque ali o backend É restrito por papel.
- Botão "+ Adicionar anexo" oculto em manutenções canceladas (`!maintDetail.cancelled`).
- Cada anexo agora mostra "Anexado por {nome} em {data/hora}" (dados da TASK-142), com
  `formatDateTime` (já criado na TASK-141) — texto neutro, não um alerta, mesmo quando a data de
  upload é bem posterior à da manutenção (comportamento esperado, não erro).
- `useEffect` reseta o formulário de anexo (arquivo/tipo/aberto) ao trocar de manutenção ou fechar o
  modal — evita carregar estado de upload de uma manutenção anterior.
- Pós-upload: invalida só `["maintenance-detail", viewingMaintId]` — os outros campos
  (itemType/performedAt/etc.) não mudam, não precisa invalidar a lista principal nem o item.
- **Mesma limitação de teste das TASK-140/141**: sem infraestrutura de teste de componente React
  neste projeto — validado via build/lint/revisão manual. Fica pro cenário C8 da TASK-QA-MAN-011.
