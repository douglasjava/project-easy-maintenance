# TASK-220 — FRONTEND: Anexos de manutenção viram lista com limite de 6

## Tipo
FRONTEND

## Categoria
Frontend / Manutenções (anexos)

## Prioridade
🟡 Médio — item #3 da demo com o cliente Rogerio Dantas (31/08/2026, ver `TASK-218.md`)

## QA obrigatório
Sim — QA manual: registrar uma manutenção nova subindo 3 anexos um a um (confirmar que cada um sobe
na hora); numa manutenção existente, subir anexos até bater 6 e confirmar que o botão de adicionar
some/desabilita com a mensagem correta; confirmar responsividade mobile da lista.

---

## Contexto

Cliente reclamou que a tela de registro de manutenção só permite 2 anexos (grade fixa "Documento 1 /
Documento 2" em `maintenances/new/page.tsx`, passo 2). Não existe limite de quantidade no backend —
é puramente uma limitação da UI. Douglas decidiu, junto com a análise: replicar o padrão que a tela
de edição de manutenção (`maintenances/page.tsx`) já usa (lista que cresce, upload imediato por
arquivo) nas duas telas, com um teto de 6 anexos aplicado só no front, e uma mensagem amigável
sugerindo zipar os arquivos se precisar de mais.

## Decisão de design (confirmada com Douglas antes de criar a task)

- **Upload imediato por arquivo** (não em lote no "Finalizar registro") — mesmo comportamento e
  mesma sequência de chamadas (`upload-url` → PUT no S3 → `confirm`) que `maintenances/page.tsx` já
  usa em `handleUploadAttachmentToExisting`. Menos código novo, reaproveita a lógica existente,
  feedback de erro por arquivo individual (já melhorado na TASK-219) em vez de um erro genérico só
  no final.
- **Lógica compartilhada**: como as duas telas vão ter exatamente o mesmo comportamento (adicionar →
  form pequeno → upload imediato → aparece na lista; teto de 6; mensagem de zip), extrair um hook
  `useMaintenanceAttachments(maintenanceId, initialAttachments)` que encapsula upload, lista local e
  checagem do limite — evita duplicar a regra do limite em dois arquivos (risco real: mudar o limite
  num lugar e esquecer o outro).
- **Sem botão de remover** — mantém paridade com o que a edição já faz hoje (só "Download", nenhuma
  forma de remover um anexo já enviado pela UI atual). Fora de escopo desta task mudar isso.

## Escopo

### Novo: hook compartilhado
`useMaintenanceAttachments(maintenanceId: number, initialAttachments: Attachment[])`
- Estado: lista de anexos (inicializada com `initialAttachments`, cresce a cada upload confirmado).
- `uploadAttachment(file, type)`: mesma sequência de 3 chamadas já usada hoje (upload-url → PUT S3 →
  confirm), com o tratamento de erro da TASK-219 (`err?.response?.data?.detail`).
- `canAddMore`: `attachments.length < 6`.
- Constante do limite (`MAX_ATTACHMENTS_PER_MAINTENANCE = 6`) exportada, não hardcoded em 2 lugares.

### `maintenances/new/page.tsx` (passo 2 — registro)
- Remove a grade fixa `[0, 1].map(...)` e o upload em lote (`handleUploadAttachments`,
  `attachments` state, `filesToUpload`).
- Usa o hook novo: botão "+ Adicionar documento" → form (input file + select de tipo) → "Enviar" →
  upload imediato → item confirmado aparece na lista abaixo.
- Ao atingir 6: botão some/desabilita, mostra mensagem "Você atingiu o limite de 6 anexos por
  manutenção. Para enviar mais arquivos, agrupe-os em um único .zip."
- "Finalizar registro" deixa de precisar fazer upload — só navega/reseta (os anexos já foram todos
  enviados no momento em que cada um foi adicionado).

### `maintenances/page.tsx` (edição/detalhe)
- Usa o mesmo hook novo no lugar da lógica de upload que já existe ali (`newAttachmentFile`,
  `handleUploadAttachmentToExisting`), inicializado com `maintDetail.attachments`.
- Mesma checagem de limite/mensagem de zip aplicada ao botão "+ Adicionar anexo".

## Critérios de Aceite

- [ ] Registro de manutenção permite subir mais de 2 anexos, um a um, com upload imediato
- [ ] Ambas as telas bloqueiam a partir do 6º anexo, com a mesma mensagem amigável sugerindo zipar
- [ ] Ambas as telas usam a mesma lógica (hook compartilhado) — limite definido em um único lugar
- [ ] Mensagem de erro por arquivo (TASK-219) continua funcionando no novo fluxo de registro
- [ ] Sem regressão no fluxo de edição (download de anexo já existente continua funcionando)
- [ ] `tsc --noEmit` e `eslint` sem regressão nos arquivos alterados

## Fora de escopo (decisão consciente)
- Botão de remover anexo já enviado — não existe hoje em nenhuma das telas, não é desta task.
- Limite no backend — só front, por decisão do Douglas.
- Zipar automaticamente pro cliente — só a mensagem sugerindo, sem automação.

## Dependências
Nenhuma nova migration/endpoint. Reaproveita os 3 endpoints de anexo que já existem
(`upload-url`, `confirm`, `download`).

## Riscos
Baixo-Médio — maior mudança é estrutural (extrair hook, remover fluxo em lote da tela de registro),
mas sem tocar em contrato de API nem em regra de negócio do backend.

## Esforço
Médio

## Status
🟡 Em andamento.
