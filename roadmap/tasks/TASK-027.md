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
O upload de attachments de manutenção (`MaintenanceAttachmentService`) provavelmente recebe o arquivo no backend e o repassa para o S3. Isso significa que o arquivo binário passa pelo servidor Java, consumindo memória, threads e largura de banda desnecessariamente.

Com pre-signed URLs, o frontend obtém uma URL temporária assinada do S3 e faz o upload diretamente do browser para o S3, sem passar pelo backend.

## Critérios de Aceite
- [ ] Endpoint `POST /attachments/upload-url` retorna uma pre-signed URL do S3 (válida por 15 minutos)
- [ ] Frontend usa a pre-signed URL para upload direto ao S3 via `PUT`
- [ ] Após upload, frontend confirma ao backend que o upload foi concluído
- [ ] Nenhum arquivo binário passa pelo backend Java
- [ ] Tamanho máximo de arquivo configurável via propriedade

## Esforço
Médio (1 dia)

## Risco de não fazer
Uploads de arquivos grandes consumem memória do servidor e podem causar timeout. Com muitos usuários fazendo upload simultaneamente, o servidor pode ficar sem memória.

## Status
Backlog
