# EPIC-038 — Módulo de Configurações da Organização (SLA de Chamados + Áreas Comuns)

## Status
📝 Backlog — spec e plano aprovados por Douglas (brainstorm 29/10/2026). Criado em 29/10/2026.

Spec: `docs/superpowers/specs/2026-10-29-organization-settings-module-design.md`.
Plano: `docs/superpowers/plans/2026-10-29-organization-settings-module.md`.

## Objetivo
Dar ao síndico/admin um lugar central para configurar parâmetros da própria organização —
começando por SLA de chamados (`ResidentTicket`, EPIC-027) e cadastro de áreas comuns com regras
de reserva — num mecanismo genérico que permita novas configurações entrarem depois sem migration
nova.

## Escopo
- Armazenar/validar/editar parâmetros de SLA de chamados (uma configuração por organização).
- Cadastrar/editar/desativar áreas comuns, cada uma com suas regras de reserva e taxa informativa.
- Tela nova `/configuracoes`, uma aba por bloco de configuração.
- Permissão `ADMIN` ou `SYNDIC` (nunca `ADMIN` sozinho).

## Fora de Escopo
- Nenhuma automação consome essas configurações ainda: `ResidentTicket` não ganha prazo/prioridade,
  não existe fluxo de reserva de área comum (pedido, aprovação, bloqueio de agenda).
- Taxa de área comum é só informativa — sem lançamento financeiro automático, sem cobrança Asaas.
- Sem controle de versão/concorrência nas configurações (descartado explicitamente por Douglas).

## Arquitetura (resumo)
Duas entidades novas em um módulo backend `settings` (mesma estrutura de `resident_tickets`):
- `organization_settings` — uma linha por categoria (`organization_id`, `category`, `config` JSON),
  pensada para novas categorias entrarem só com um valor de enum + DTO novo, sem migration. Só
  `TICKETS_SLA` nesta entrega.
- `common_area` — lista de áreas por organização, com `fee_cents` como coluna própria (padrão de
  dinheiro em centavos já usado no projeto) e `rules` em JSON.

Frontend: página única `/configuracoes` com abas por state local (sem sub-rota por aba), uma aba
por bloco de configuração, cada aba independente para facilitar adicionar novas no futuro.

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-373](../tasks/TASK-373.md) | Backend: `OrganizationSetting` — entidade, migration V128 e repositório | BACKEND | 🟠 Alto |
| [TASK-374](../tasks/TASK-374.md) | Backend: `CommonArea` — entidade, migration V129 e repositório | BACKEND | 🟠 Alto |
| [TASK-375](../tasks/TASK-375.md) | Backend: configuração de SLA de chamados — DTOs, serviço e API | BACKEND | 🟠 Alto |
| [TASK-376](../tasks/TASK-376.md) | Backend: áreas comuns — DTOs, serviço CRUD e API | BACKEND | 🟠 Alto |
| [TASK-377](../tasks/TASK-377.md) | Frontend: página `/configuracoes` + aba de SLA de Chamados | FRONTEND | 🟠 Alto |
| [TASK-378](../tasks/TASK-378.md) | Frontend: aba de Áreas Comuns (listar, criar, editar) | FRONTEND | 🟠 Alto |
| [TASK-379](../tasks/TASK-379.md) | Frontend: entrada "Configurações" no menu do usuário | FRONTEND | 🟡 Médio |

Ordem: TASK-373 e TASK-374 em paralelo (independentes) → TASK-375 (depende da 373) e TASK-376
(depende da 374), também em paralelo entre si → TASK-377 (depende da 375) → TASK-378 (depende da
376 e da 377, que cria a página) → TASK-379 (depende da 377 existir).

## Critério de Conclusão do Épico
- [ ] `organization_settings`/`common_area` persistem e isolam por `organization_id` corretamente
      (testes de persistência + unitários)
- [ ] `ADMIN`/`SYNDIC` conseguem editar; `TECH`/`READER` recebem `403`
- [ ] `GET` de configuração sem linha salva retorna defaults com `200`, nunca `404`
- [ ] `mvn test` e `npm run build`/`tsc --noEmit` sem regressão
- [ ] QA manual: editar SLA e cadastrar/editar área comum (incluindo desativar) na tela
      `/configuracoes`, validado contra ambiente local real

## Fora de Escopo
- Consumo das configurações por `ResidentTicket` (prazo/prioridade) ou por um fluxo de reserva de
  área comum — ambos ficam para quando esses módulos existirem.
- Cobrança real da taxa de área comum.

## Riscos
- Nenhuma dependência externa bloqueante — módulo autocontido, sem integração de terceiros.
