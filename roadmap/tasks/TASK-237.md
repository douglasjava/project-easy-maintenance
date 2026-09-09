# TASK-237 — BACKEND: Módulo público de chamados (abrir, consultar por CPF, upload de foto)

## Tipo
BACKEND

## Categoria
Chamados de Moradores

## Prioridade
🟠 Alto

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — abrir um chamado real (com e sem foto) contra um org code válido, confirmar rejeição de org
code inválido, confirmar rate limit disparando após N tentativas.

---

## Contexto

Primeira metade do backend do épico: a superfície **pública** (sem autenticação) que o morador usa
pra abrir um chamado e consultar os próprios depois. Detalhe completo do desenho em
`docs/superpowers/specs/2026-09-08-resident-tickets-design.md`.

## Escopo

- Novo módulo `resident_tickets` (nome exato a definir): `domain/` (entidade `ResidentTicket` +
  enum de status `SOLICITADO`/`EM_ANDAMENTO`/`CONCLUIDO`), `application/`, `infrastructure/`.
- Nova migration: tabela do chamado — `organization_id` (FK), `resident_name`, `resident_phone`,
  `resident_cpf`, `description`, `photo_url` (nullable), `status`, `created_at`/`updated_at`.
- `POST /public/resident-tickets` — recebe `organizationCode` (resolve pra `organization_id` via
  `OrganizationRepository`, 404 se não existir), `residentName`, `residentPhone` (obrigatório),
  `residentCpf` (obrigatório), `description`, `photoUrl` (opcional). Cria em `SOLICITADO`.
- `GET /public/resident-tickets?organizationCode=X&cpf=Y` — lista chamados daquele CPF, naquela
  organização.
- `POST /public/resident-tickets/upload-url` (ou nome equivalente) — gera presigned URL via
  `S3FileStorageService` (não via `MaintenanceAttachmentService`, que é acoplado ao fluxo
  autenticado/billing), restrito a imagem, tamanho conservador (menor que o teto de anexo de
  manutenção — é foto de celular, não PDF; valor exato a definir na implementação).
- Todos os 3 endpoints protegidos por `RateLimiterService` (mesmo serviço já usado em auth/reset/IA).
- Controller separado (`ResidentTicketsPublicController`), sem `@PreAuthorize`, fisicamente isolado
  do controller autenticado (TASK-238) — reduz risco de vazar autenticação por engano.

## Critérios de Aceite

- [x] Abrir chamado com `organizationCode` válido cria o registro em `SOLICITADO`
- [x] Abrir chamado com `organizationCode` inexistente retorna erro claro (não 500) — `NotFoundException`/404
- [x] `residentPhone`/`residentCpf` ausentes são rejeitados (validação de DTO, `@NotBlank`/`@CPF`)
- [x] Consulta por CPF retorna só os chamados daquele CPF, naquela organização (nunca de outra)
- [x] Upload de foto: presigned URL gerada, restrita a imagem, tamanho limitado (5MB, configurável)
- [x] Rate limit ativo nos 3 endpoints via `@RateLimit` (mesmo padrão de auth/reset/IA) — configuração
      em `application.properties`, não testado disparando de verdade (mecanismo já coberto por
      testes próprios do `RateLimiterService`/`RateLimitAspect`, reaproveitado sem alteração)
- [x] Testes cobrindo happy path + validação + isolamento entre organizações (10 testes novos)
- [x] `mvn test` sem regressão (928/928)

## Dependências
Nenhuma técnica. Independente da TASK-238 (podem andar em paralelo). TASK-239 (frontend público)
depende desta task pronta.

## Riscos
Enumeração de CPF (mitigado por rate limit, risco aceito conscientemente — ver EPIC-027). Abuso do
upload público (mitigado por rate limit + restrição de tipo/tamanho de arquivo).

## Esforço
Médio

## Status
✅ Implementada na branch `feature/EPIC-027-resident-tickets` (`easy-maintenance-api`). Migration
V108 validada contra MySQL 8 real em modo estrito (container Docker efêmero, mesmo cuidado da
TASK-230). `mvn test` → 935/935, 0 regressão. QA manual completo e aprovado por Douglas
([TASK-QA-MAN-018](../QA/tasks/TASK-QA-MAN-018.md)). PR contra `staging` aberta:
[api#85](https://github.com/douglasjava/easy-maintenance-api/pull/85).
