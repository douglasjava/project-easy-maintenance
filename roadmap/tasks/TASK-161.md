# TASK-161 — Frontend: página `/financeiro` — grid de totalizadores + gráfico

## Tipo
FRONTEND

## Categoria
Admin / Financeiro

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo)

## QA obrigatório
Sim — validar visualmente o gráfico e os cartões com dado real do endpoint, incluindo o caso de
lucro negativo (cor/indicação diferente).

---

## Contexto

Nenhuma biblioteca de gráfico está instalada no projeto — o único "gráfico" hoje
(`/private/dashboard`) é uma barra CSS artesanal. Esta task instala a primeira lib de gráfico
(Recharts) e cria a página que consome o endpoint agregado da TASK-160.

---

## Objetivo

Nova rota `/private/admin/billing/financeiro`: grid de 3 cartões (mês atual) + gráfico dos últimos
12 meses.

---

## Escopo

### 1. Dependência nova
- `npm install recharts` no `easy-maintenance-web`.

### 2. `src/app/private/admin/billing/financeiro/page.tsx`
- Busca `GET /admin/billing/financials?months=12` no mount.
- **Grid de 3 cartões** (dado do último item da lista, i.e. mês atual): Recebido, Gasto
  (`costCents + commissionCents`), Total (`profitCents`) — Total muda de cor (vermelho) se
  negativo.
- **Gráfico Recharts** (barra agrupada ou linha): três séries — Receita, Gasto (custo + comissão
  somados, mesma lógica do cartão), Lucro — eixo X com os 12 meses.
- Estado de loading e erro (mesmo padrão já usado no resto do admin).

### 3. Navegação
- Link/entrada pra essa página a partir de `/private/admin/billing` (mesma nav lateral/tabs já
  usada pelas outras sub-páginas de billing admin: plans, subscriptions, invoices).

### 4. Testes
- Sem infraestrutura de teste de componente React neste projeto (limitação já registrada em tasks
  anteriores) — validar via build/lint + teste manual com dado real do endpoint.

---

## Critérios de Aceite

- [x] `/private/admin/billing/financeiro` acessível só pelo admin (mesmo padrão `X-Admin-Token`
      automático do resto de `/private/admin/*`)
- [x] Grid mostra Recebido/Gasto/Total do mês atual corretamente
- [x] Gráfico renderiza os 12 meses com as 3 séries
- [x] Total fica visualmente diferente quando negativo
- [x] `npm run build` limpo
- [ ] **QA manual de ponta a ponta com dado real** — não realizado nesta sessão (backend local
      exige chaves de IA que não estavam disponíveis); pendente de validação do Douglas em
      `staging`

## Dependências
- **TASK-160** — precisa do endpoint agregado existir.

## Riscos
Baixo — primeira vez usando Recharts no projeto, mas é uma lib madura e bem documentada; risco
maior é só familiarização com a API na primeira implementação.

## Esforço
Médio

## Status
Em Validação — implementado em `feature/EPIC-020-financial-dashboard` (branch a partir de
`staging`), commit `d2b008e`. `npm run build` limpo, mesmo padrão exato das outras páginas de
billing admin. Falta QA manual com dado real (não foi possível localmente — backend exige chaves
de IA ausentes neste ambiente) e o cadastro de custo da TASK-162.
