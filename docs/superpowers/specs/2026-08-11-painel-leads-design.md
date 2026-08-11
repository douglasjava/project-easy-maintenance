# Painel de Leads — Design

**Data**: 2026-08-11
**Status**: Aprovado por Douglas (via diálogo de brainstorm)

## Contexto

O EPIC-018 já captura leads da landing (`landing_leads`: email, name, source, medium, campaign,
referrer, affiliateCode, landingPath, utmJson, ip, userAgent, status, consentAcceptedAt,
createdAt), mas não existe nenhuma tela de admin pra visualizar isso — só a captura funciona. O
campo `status` existe no schema mas é uma `String` livre sem nenhum workflow: todo lead nasce e
fica "NEW" pra sempre, porque nenhum código muda esse valor.

Este épico entrega a primeira visão administrativa de leads: quantos chegam, de onde vêm, e um
fluxo mínimo de status pra acompanhar o funil manualmente (Douglas marcando à mão quem já foi
contatado, quem converteu, quem não vingou).

## Decisões de escopo (confirmadas com Douglas)

1. **Não é só visualização — inclui trocar status**: além dos números agregados, uma lista
   individual de leads com ação de mudar status por linha (vira um mini-CRM básico, não só
   dashboard).
2. **Status do funil**: `NEW → CONTACTED → CONVERTED / LOST`. Converte o campo `status` (hoje
   `String` livre) pra um enum de verdade — migração segura porque todo dado existente já é
   `"NEW"`, um valor válido do enum.
3. **Quebra por mês**: a contagem por status é vista mês a mês (últimos 12 meses), não só o total
   atual — mesmo padrão do EPIC-020 (Financeiro), pra enxergar tendência.
4. **Fonte e referrer**: tabela (não gráfico) com top N por contagem no período — `referrer`
   pode ter muitos valores distintos, um gráfico com muitas séries fica ilegível; tabela ordenada
   é mais prática.
5. **Filtros da lista individual**: status, fonte (`source`), campanha (`campaign`) — todos por
   **igualdade exata**, sem busca parcial (`LIKE`) — e período.
6. **Localização**: novo item de topo "Leads" no menu admin, mesmo nível de Faturamento/Afiliados
   (`/private/admin/leads`), não é sub-aba de nenhuma seção existente.
7. **Fora de escopo**: `medium` como filtro isolado (só `source`/`campaign` foram pedidos);
   qualquer automação disparada por mudança de status (e-mail, notificação); campanha/medium na
   visão agregada mensal (só status entra no gráfico mensal).

## Modelo de dados

### `LandingLead.status`: de `String` livre pra enum

Nova classe `LeadStatus` (`NEW`, `CONTACTED`, `CONVERTED`, `LOST`). Migração:
```sql
-- Coluna já é VARCHAR compatível com os nomes do enum; só documenta a mudança de significado,
-- sem transformação de dado necessária (todo valor existente já é "NEW").
```
Entidade: `@Enumerated(EnumType.STRING) private LeadStatus status;` com `@Builder.Default status =
LeadStatus.NEW`.

## Backend

### `GET /admin/leads/summary?months=12`
- Busca todos os leads com `createdAt` dentro da janela de N meses (uma query, sem `GROUP BY`
  mês em SQL — mesmo raciocínio do EPIC-020: volume baixo, agregação em Java é suficiente e mais
  simples).
- Resposta: contagem mensal por status (pra alimentar o gráfico empilhado) + top fontes e top
  referrers do período inteiro (não por mês).

### `GET /admin/leads`
- Lista paginada (`PageResponse`, mesmo padrão do resto do admin).
- Filtros opcionais combináveis via `Specification<LandingLead>` (mesmo padrão de
  `PaymentRepository`): `hasStatus`, `hasSource`, `hasCampaign` (igualdade exata), `createdBetween`.

### `PATCH /admin/leads/{id}/status`
- Corpo: `{ status: LeadStatus }`. Atualiza e retorna o lead. Valida que o valor é um `LeadStatus`
  válido (enum já garante isso na deserialização — valor inválido já falha antes de chegar no
  service, com 400 padrão do Spring).

## Frontend

Nova rota `/private/admin/leads`, novo item "Leads" em `Sidebar.tsx` (`adminItems`).

1. **Visão agregada** (topo da página): gráfico Recharts empilhado, 12 meses, séries = os 4
   status. Abaixo, duas tabelas lado a lado: "Top fontes" e "Top referrers" (contagem, período
   selecionável).
2. **Lista individual** (abaixo): tabela paginada — nome, e-mail, fonte, referrer, status, data.
   Filtros no topo: status (select), fonte (texto, igualdade exata), campanha (texto, igualdade
   exata), período (date range). Seletor de status inline por linha, salva via `PATCH` ao trocar.

## Fora de Escopo (não construir agora)

- Filtro/breakdown por `medium`.
- Qualquer automação disparada por mudança de status.
- Edição de outros campos do lead além do status.
- Exportação (CSV) da lista — pode vir depois se fizer falta.
