# TASK-284 — Mais vida e dinamismo na landing (benchmark easyalert.com.br)

## Tipo
FRONTEND

## Categoria
Frontend (landing pública — layout/interação, sem mudança de backend)

## Prioridade
🟡 Médio — não é bug, é melhoria de percepção/conversão. Pedido direto de Douglas em 23/09/2026
depois de revisar `easyalert.com.br` (concorrente direto, mesmo nicho) e achar a nossa landing
"parada" em comparação.

## Épico
Sem épico — pedido pontual, sequência natural da TASK-283 (mesma seção de conteúdo).

## QA obrigatório
Sim (visual) — checar desktop, mobile (carrossel) e performance de scroll antes de publicar.

---

## Contexto

Benchmark em `easyalert.com.br` (23/09/2026, ver conversa) — concorrente direto que usa 5 técnicas
pra parecer mais "vivo" que a nossa landing hoje:

1. Mockups de produto (mini-widgets ilustrativos: gráfico de barras, gauge circular, lista com
   badge de status) no lugar de emoji + texto nos cards de recurso.
2. Contraste visual "antes/depois" na seção de problema (bagunça vs. painel limpo).
3. Bento grid assimétrico na seção de recursos, não grid uniforme.
4. Fade-in no scroll (texto/seções aparecem com transição conforme o usuário rola).
5. Scrollytelling na seção "Como funciona": passos numerados com painel fixo ao lado que
   acompanha o scroll.

Checado: os "mockups" deles nos cards de recurso **não são screenshots reais** do produto — são
widgets ilustrativos simples (divs com CSS: barras coloridas, círculo de progresso, lista com
badge). Isso é viável de replicar sem precisar de captura de tela nova. Já existe 1 screenshot real
do produto em `public/dashboard_preview.webp` (usado no hero); não há screenshot de chamados de
moradores nem do índice de conformidade em `public/` hoje — se Douglas preferir usar prints reais
em vez de widgets ilustrativos em algum ponto do plano, precisa fornecer/eu capturar novos assets
(decisão em aberto por item, ver abaixo).

Nota de cautela (mantida da TASK-283): nenhuma prova social numérica/depoimento — mantido fora de
escopo aqui também.

## Escopo — 4 frentes, em ordem de execução

### Frente 1 — Fade-in no scroll (infraestrutura reutilizável)
Hook `useScrollReveal` (ou equivalente) baseado em `IntersectionObserver`, aplicado como classe
utilitária (`className="reveal-on-scroll"` + CSS transition de opacity/translateY) nas seções
principais da landing (`RiskBlock`, "Para quem é", "Problema", "Solução", "Diferenciais",
`PartnerBlock`, CTA final). Sem lib nova — só CSS + hook próprio, ~30-40 linhas. Base pra tudo que
vem depois, por isso vai primeiro.

**Critério de aceite**: seções aparecem com fade-in suave ao rolar (uma vez só, não repete ao rolar
pra cima e descer de novo); sem flash de conteúdo invisível se JS demorar pra carregar (fallback:
visível por padrão, reveal é progressive enhancement); sem impacto perceptível de performance
(Lighthouse não pode cair).

---

### Frente 2 — Seção "Solução": bento grid + mini-mockups (mesma passada, mesmo arquivo)
Fundir bento grid e mockups num único passo porque mexem na mesma seção — fazer em 2 passadas
duplicaria trabalho de layout.

- Reestruturar `SOLUTION_ITEMS`/`SolutionCard` de grid uniforme (`row g-5` + `col-md-4`) pra bento
  grid assimétrico via CSS Grid (`grid-template-columns`/`grid-template-areas`, alguns itens
  ocupando 2 colunas ou 2 linhas).
  - Requer decisão simples: 8 itens (após TASK-283) numa composição assimétrica agradável — proposta
    concreta a validar visualmente no `/execute-task`: "Índice de conformidade" e "Chamados de
    moradores" (os 2 mais novos/fortes) ganham cards maiores (2 colunas), os outros 6 mantêm
    tamanho padrão.
- Cada `SolutionCard` ganha um mini-widget ilustrativo simples em vez do emoji atual:
  - Central de ativos → lista de 2-3 linhas com ícone de check
  - Agenda de vencimentos → mini calendário/barra de progresso com marcador
  - Índice de conformidade → gauge circular (SVG simples, `stroke-dasharray`) com um número (ex.:
    "87%"), mesmo padrão do gauge do concorrente
  - Chamados de moradores → mini kanban de 3 colunas (bolinhas coloridas)
  - Gestão de fornecedores → lista com badge de pontuação (★ 4.8)
  - Repositório de laudos / Trilha de auditoria / Evidências fotográficas → variações de lista com
    ícone, sem inventar dado real
  - **Sem número/dado fictício que pareça real** (ex.: não usar "87%" como se fosse métrica real de
    cliente — só como elemento decorativo do widget, deixar claro visualmente que é ilustrativo, não
    "prova").
- Manter o `CardCarousel` mobile funcionando (mobile provavelmente cai pra layout mais simples,
  sem bento — o bento é essencialmente um recurso desktop; mobile já usa carrossel de 1 card por
  vez, onde bento não faz sentido).

**Critério de aceite**: seção "Solução" com grid assimétrico no desktop, mockups ilustrativos em
cada card, carrossel mobile continua 1-card-por-vez sem quebrar; nenhum dado inventado apresentado
como real.

---

### Frente 3 — Seção "Problema": contraste "Hoje" vs. "Com Easy Maintenance"
- Redesenhar a seção `id="problema"` pra um layout de 2 colunas lado a lado (ou empilhado no
  mobile): coluna "Hoje" (visual de bagunça — recriação estilizada de post-it + trecho de
  WhatsApp, sem usar nome/foto real de ninguém) vs. coluna "Com Easy Maintenance" (print real
  recortado do produto, se disponível, ou recriação estilizada da tela de chamados/índice de
  conformidade).
- **Decisão em aberto**: usar screenshot real (mais autêntico, mas exige capturar tela nova — app
  local não sobe sem credencial real nesta sessão, mesmo bloqueio já documentado em outras tasks) ou
  recriação ilustrativa em CSS (mais rápido, sem dependência externa, consistente com os widgets da
  Frente 2). Recomendação: ilustrativo primeiro (mesmo padrão da Frente 2), trocar por print real
  depois se Douglas quiser/puder fornecer.
- Mantém os 4 `PROBLEM_ITEMS` atuais como apoio textual abaixo ou ao lado do contraste visual — não
  descartar o conteúdo existente, só dar um elemento visual mais forte por cima.

**Critério de aceite**: seção "Problema" tem um elemento visual de contraste "antes/depois",
sem nome/foto real de terceiros, legível em mobile (empilhado) e desktop (lado a lado).

---

### Frente 4 — "Como funciona" (seção nova, scrollytelling)
Maior escopo das 4 frentes — só entra depois das outras 3 estarem prontas e aprovadas.

- Nova seção entre "Problema" e "Solução" (ou entre "Solução" e "Diferenciais" — a decidir com
  Douglas): 3-4 passos numerados (ex.: "Cadastre seus ativos" → "Receba alertas automáticos" →
  "Registre a manutenção com foto" → "Gere o relatório de conformidade"), cada um com um mini-mockup
  ilustrativo ao lado (reaproveita os widgets da Frente 2 onde fizer sentido).
- Comportamento scroll-linked: passo ativo em destaque (opacidade/negrito) conforme a seção
  correspondente entra no viewport, via `IntersectionObserver` (reaproveita o hook da Frente 1).
  Painel lateral com `position: sticky` acompanhando o scroll dos passos (CSS puro, sem lib de
  scroll nova).
- Mobile: provavelmente vira uma lista vertical simples (passo + mockup empilhados), sem sticky —
  sticky scroll não funciona bem em telas pequenas.

**Critério de aceite**: nova seção com passos numerados, painel sticky acompanha o scroll no
desktop, passo ativo destacado; mobile empilhado e legível; não quebra a navegação por âncora do
menu (`#problema`, `#solucao` etc.) se a nova seção ganhar um ID próprio.

---

## Decisões em aberto (produto/design) — a confirmar antes/durante o `/execute-task`
1. Frente 2: aprovar a composição assimétrica proposta (quais 2 cards ficam maiores) antes de
   codar, ou deixar a critério de quem implementar e ajustar depois visualmente?
2. Frente 3: screenshot real vs. recriação ilustrativa (recomendo ilustrativa primeiro).
3. Frente 4: posição da nova seção no fluxo da página, e o texto exato dos 3-4 passos (a matéria-
   prima do fluxo real do produto existe — onboarding, alertas, evidência fotográfica, relatório —
   só falta redigir os títulos curtos no tom da marca).

## Critérios de Aceite (gerais)
- [ ] As 4 frentes implementadas e revisadas visualmente (desktop + mobile) por Douglas
- [ ] Nenhuma prova social numérica/depoimento novo
- [ ] Nenhum dado ilustrativo (gauge, badge, número) apresentado de forma que pareça uma métrica
      real de cliente
- [ ] `npx tsc --noEmit` e `npm run build` sem regressão
- [ ] Performance de scroll/animação sem degradação perceptível (checar visualmente, sem jank)

## Dependências
Sequencial: Frente 1 (infra de scroll) antes das Frentes 2-4, que reaproveitam o mesmo hook.
Frente 4 depende das Frentes 2-3 estarem prontas (reaproveita os widgets ilustrativos).

## Riscos
- Baixo-médio: mudança de layout em seção de alta visibilidade (primeira impressão da landing) —
  QA visual cuidadoso antes de publicar, sem mudança de contrato de API (puramente frontend).
- Risco de escopo: Frente 4 (scrollytelling) é a mais aberta em termos de design — pode exigir mais
  de uma rodada de ajuste visual com Douglas antes de aprovar.

## Esforço
- Frente 1: pequeno (~1-2h)
- Frente 2: médio (~3-4h)
- Frente 3: pequeno-médio (~2-3h)
- Frente 4: médio-grande (~4-6h)
- Total estimado: ~10-15h, recomendo dividir em commits/checkpoints por frente (não uma PR gigante
  de uma vez) pra facilitar revisão visual incremental do Douglas.

## Status
🔵 Pronto para implementar — plano definido em 23/09/2026, aguardando decisão do Douglas sobre os
3 pontos em aberto (ou sinal verde pra eu decidir e ajustar depois) antes de abrir a branch.
