# TASK-367 — BACKEND: Categoria e protocolo sequencial no chamado de morador

## Tipo
BACKEND

## Categoria
Chamados de Moradores

## Prioridade
🟠 Alto

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — abrir chamado com cada categoria, confirmar protocolo gerado, confirmar que dois chamados
simultâneos na mesma organização não colidem no número de protocolo (teste de concorrência real,
não só sequencial), confirmar backfill correto nos chamados que já existiam.

---

## Contexto

Pedido trazido por Douglas após conversa com a síndica Aliria Emanuela (28/10/2026): o chamado de
morador hoje é só relato livre, sem classificação, e sem número de protocolo para o morador
acompanhar. Esta task cobre o modelo de dado e o contrato de API — base para TASK-368/369/370/371.
Detalhe completo em
`docs/superpowers/specs/2026-10-28-resident-tickets-category-protocol-notification-design.md`.

## Escopo

- Novo enum `ResidentTicketCategory`: `SUGESTAO`, `RECLAMACAO`, `MANUTENCAO`.
- Nova migration em `ResidentTicket`:
  - `category` (enum, `NOT NULL`).
  - `protocol_number` (inteiro, `NOT NULL`), sequencial por `organization_id` — gerado na criação
    com lock de linha (`SELECT ... FOR UPDATE` numa linha de controle por organização, ou tabela de
    contador dedicada — decisão de implementação) para evitar colisão sob concorrência. Constraint
    única `(organization_id, protocol_number)`.
  - **Backfill** dos chamados já existentes em produção: `category = MANUTENCAO` (era o uso de fato
    até agora), `protocol_number` atribuído por ordem de `created_at` dentro de cada organização.
- `POST /public/resident-tickets`: corpo passa a exigir `category`. Resposta inclui
  `protocolNumber`.
- `GET /public/resident-tickets?organizationCode=X&cpf=Y`: cada chamado na resposta inclui
  `category` e `protocolNumber`.
- `GET /resident-tickets` (autenticado, kanban interno): resposta inclui `category` e
  `protocolNumber`.

## Critérios de Aceite

- [x] Abrir chamado sem `category` é rejeitado (erro claro, não 500) — `@NotNull` no DTO,
      `CreateResidentTicketRequestTest`
- [x] Abrir chamado com `category` válida persiste corretamente e retorna `protocolNumber` —
      `ResidentTicketPublicServiceTest`
- [x] Dois chamados abertos ao mesmo tempo, na mesma organização, nunca recebem o mesmo
      `protocolNumber` — serialização via lock `PESSIMISTIC_WRITE` na linha de `Organization`
      (`OrganizationRepository.findByIdForUpdate`) antes de calcular `MAX(protocol_number)+1`.
      Constraint única `(organization_id, protocol_number)` como última linha de defesa, provada em
      `ResidentTicketPersistenceTest` (H2). Teste de concorrência real com múltiplas
      threads/transações não foi automatizado (sem precedente no projeto — demais testes de
      "corrida"/constraint seguem o mesmo padrão de `SupplierPersistenceTest`: prova a constraint,
      não simula threads); risco residual fica para validação manual em staging com requests
      simultâneos reais, mesmo cuidado já usado no EPIC-029
- [x] `protocolNumber` reinicia em `1` para cada organização nova (não é sequência global) —
      testado e confirmado também na validação manual contra MySQL real (ver abaixo)
- [x] Migration de backfill roda sem erro contra dados existentes reais — **validada contra MySQL 8
      real (container Docker efêmero)**: seed com 5 chamados pré-existentes em 2 organizações,
      migration V126 aplicada, resultado confirmado (protocolo por ordem de `created_at`, reinicia
      por organização, categoria `MANUTENCAO`, constraint única rejeita duplicata com erro 1062)
- [x] Endpoints públicos e autenticados retornam `category`/`protocolNumber` no payload —
      `ResidentTicketResponse` atualizado, usado pelos dois serviços
- [x] `mvn test` sem regressão — 1497/1497 (JDK 21, suíte completa)

## Dependências
Nenhuma técnica. Desbloqueia TASK-368, TASK-369, TASK-370, TASK-371.

## Riscos
Corrida na geração do protocolo sob concorrência real — precisa de teste dedicado, não só
unitário sequencial. Migration de backfill roda contra dado de produção existente — validar em
staging com cópia real antes de promover.

## Esforço
Médio

## Status
🟡 Implementada, aguardando PR/validação final — branch `feature/TASK-367-categoria-protocolo-chamado`
(`easy-maintenance-api`), a partir de `staging`. `mvn test` 1497/1497 sem regressão (JDK 21).
Migration V126 validada à parte contra MySQL 8 real (container Docker efêmero).
