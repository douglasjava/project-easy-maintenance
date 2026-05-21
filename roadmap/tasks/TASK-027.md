# TASK-027 — Pre-signed URLs S3 para uploads diretos

## Tipo
Performance / Arquitetura

## Categoria
Backend / Frontend / Performance

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-007 — Performance e Escalabilidade

## Descrição
O upload de attachments de manutenção (`MaintenanceAttachmentService`) recebia o arquivo no backend e o 
repassava para o S3. Isso fazia o arquivo binário passar pelo servidor Java, consumindo memória, threads e largura de banda desnecessariamente.

Com pre-signed URLs, o frontend obtém uma URL temporária assinada do S3 e faz o upload diretamente do browser para o S3, sem passar pelo backend.

## Critérios de Aceite
- [x] Endpoint `POST /{maintenanceId}/attachments/upload-url` retorna uma pre-signed URL do S3 (válida por 15 minutos)
- [x] Frontend usa a pre-signed URL para upload direto ao S3 via `PUT`
- [x] Após upload, frontend confirma ao backend que o upload foi concluído (`POST /{maintenanceId}/attachments/confirm`)
- [x] Nenhum arquivo binário passa pelo backend Java
- [x] Tamanho máximo de arquivo configurável via propriedade (`aws.s3.upload.max-file-size-mb`, default 10 MB)

## Esforço
Médio (1 dia)

## Implementação

### Fluxo
1. Browser → `POST /maintenances/{id}/attachments/upload-url` (com fileName, contentType, attachmentType, sizeBytes)
2. Backend gera S3 key (`maintenances/{id}/{uuid}/{safeFileName}`), valida tamanho, chama `S3Presigner` → devolve `{ uploadUrl, s3Key, expiresAt }`
3. Browser → `PUT {uploadUrl}` diretamente ao S3 com `Content-Type` correto e body binário
4. Browser → `POST /maintenances/{id}/attachments/confirm` com `{ s3Key, fileName, contentType, sizeBytes, attachmentType }`
5. Backend valida que `s3Key` pertence à manutenção correta, persiste `MaintenanceAttachment` e retorna resposta

### Segurança
- `s3Key` validado no confirm: deve iniciar com `maintenances/{maintenanceId}/` — evita que um cliente registre anexos de outra manutenção
- Tamanho validado em ambos os endpoints (geração e confirmação)
- Endpoint existente de upload multipart mantido para compatibilidade

### Arquivos criados / modificados

| Arquivo | Operação |
|---------|----------|
| `infrastructure/storage/S3Config.java` | Adicionado bean `S3Presigner` |
| `infrastructure/storage/S3FileStorageService.java` | Adicionados `generatePresignedPutUrl()` e `buildFileUrl()` |
| `assets/application/dto/PresignedUploadUrlRequest.java` | **Criado** — fileName, contentType, attachmentType, sizeBytes |
| `assets/application/dto/PresignedUploadUrlResponse.java` | **Criado** — uploadUrl, s3Key, expiresAt |
| `assets/application/dto/ConfirmUploadRequest.java` | **Criado** — s3Key, fileName, contentType, sizeBytes, attachmentType |
| `assets/application/service/MaintenanceAttachmentService.java` | Adicionados `generatePresignedUploadUrl()` e `confirmUpload()` |
| `assets/infrastructure/web/MaintenanceAttachmentsController.java` | 2 novos endpoints: `upload-url` e `confirm` |
| `src/main/resources/application.properties` | Adicionado `aws.s3.upload.max-file-size-mb=10` |
| `easy-maintenance-web/.../maintenances/new/page.tsx` | `handleUploadAttachments()` migrado para fluxo de 3 etapas |
| `test/.../MaintenanceAttachmentServiceTest.java` | **Criado** — 6 testes unitários, todos passando |

### Testes
- `shouldGeneratePresignedUploadUrl_whenFileSizeIsWithinLimit` ✅
- `shouldSanitizeFileNameInS3Key` ✅
- `shouldThrowRuleException_whenFileSizeExceedsLimit` ✅
- `shouldConfirmUpload_andPersistAttachment` ✅
- `shouldThrowRuleException_whenS3KeyBelongsToDifferentMaintenance` ✅
- `shouldThrowRuleException_onConfirm_whenFileSizeExceedsLimit` ✅

**Resultado: 6/6 passando — BUILD SUCCESS**

## Risco de não fazer
Uploads de arquivos grandes consumiam memória do servidor e poderiam causar timeout. Com muitos usuários fazendo upload simultaneamente, o servidor poderia ficar sem memória.

## Status
Done
