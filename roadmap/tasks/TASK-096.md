# TASK-096 — Frontend: Painel admin de comissões de afiliados

## Tipo
FRONTEND

## Épico
EPIC-012 — Sistema de Indicação

## Prioridade
🟠 Alto

## Fase
3 — Divulgação / Pós-Lançamento

## Descrição
Criar a página `/private/admin/affiliates` com a tabela de comissões geradas. O admin vê quem deve receber, o valor, o plano, e pode marcar como pago após realizar o PIX manualmente.

**Funcionalidades:**
- Tabela com: nome/e-mail do afiliado, WhatsApp (link para WhatsApp Web), org ID, plano, valor do plano, comissão em R$, status (badge), data
- Filtro rápido: Todas / Pendentes / Pagas
- Cabeçalho com total a pagar (R$) em destaque
- Botão "Marcar pago" nas linhas com status PENDING — com confirmação

## Critérios de Aceite
- [ ] `GET /api/v1/admin/affiliates-commissions/commissions` popula a tabela
- [ ] Filtro por status funciona no frontend (sem nova request)
- [ ] Total a pagar calculado somente sobre PENDING
- [ ] "Marcar pago" exibe `confirm()` antes de chamar `PATCH .../pay`
- [ ] Após marcar pago, tabela é recarregada
- [ ] WhatsApp do afiliado é clicável (`https://wa.me/55{numero}`)
- [ ] Página responsiva

## Esforço
Médio (3-4h)

## Status
Em Validação

## Dependências
TASK-091 (endpoints admin de comissões)
