# TASK-222 — FRONTEND: Sidebar fixa em desktop + campo de descrição maior

## Tipo
FRONTEND

## Categoria
Frontend / UX (navegação + formulário de manutenção)

## Prioridade
🟢 Baixo — itens #10 e #12 da demo com o cliente Rogerio Dantas (31/08/2026, ver `TASK-218.md`).
Agrupados numa task só a pedido do Douglas (os dois são ajustes de UX, sem dependência entre si).

## QA obrigatório
Sim — QA manual: navegar em desktop (≥ breakpoint `lg`) confirmando que a sidebar fica sempre
visível e o conteúdo não fica coberto; confirmar que em mobile/tablet o comportamento de drawer
(abre com o hambúrguer, fecha ao navegar) continua idêntico; conferir a tela `/private` (admin)
também; conferir o campo de descrição da manutenção com mais linhas visíveis.

---

## Contexto

**#10 — menu lateral**: `Sidebar.tsx` é hoje um Bootstrap `offcanvas` — um drawer escondido por
padrão, que só abre com clique no botão hambúrguer (`TopBarBrand.tsx`), **em qualquer tamanho de
tela, inclusive desktop**. `Shell.tsx` monta `<main className="container">` sem reservar espaço pra
sidebar; ela vive por cima do conteúdo, sempre fechada. Análise de UX discutida com Douglas antes de
implementar: em desktop, isso obriga um clique extra pra cada navegação — o padrão do setor pra
painel administrativo é ter o menu sempre visível numa coluna fixa à esquerda em telas grandes, só
virando drawer em mobile.

**#12 — campo de descrição da manutenção**: `maintenances/new/page.tsx:585` tem
`<textarea rows={3} maxLength={1000}>` — o limite de caracteres já é generoso, só a altura visível é
pequena. Sem segredo, só aumentar.

## Decisão de design (#10, confirmada com Douglas antes de implementar)

Sidebar fixa em desktop (`≥ lg`), drawer continua em mobile — usando o suporte nativo do Bootstrap
5.3 pra offcanvas responsivo (`offcanvas-lg`), sem reescrever a lógica de itens/seções/permissões que
já existe. Alternativas consideradas e descartadas por ora: sidebar retrátil tipo Notion/Linear
(exige conjunto de ícones que não existe hoje, esforço bem maior) e só polir visual do drawer atual
sem torná-lo fixo (não resolve o clique extra, que é o problema principal).

## Escopo

### `Sidebar.tsx`
- Classe do container: `offcanvas offcanvas-start` → `offcanvas offcanvas-lg offcanvas-start`.
  Abaixo de `lg`: comportamento de drawer idêntico ao de hoje. A partir de `lg`: passa a ficar
  sempre visível, sem overlay, ocupando espaço próprio no layout (comportamento nativo do Bootstrap
  pra offcanvas responsivo).

### `Shell.tsx`
- Envolve `<Sidebar />` e `<main>` num container flex, pra ficarem lado a lado em desktop sem exigir
  nenhuma mudança na estrutura de navegação em si.

### `TopBarBrand.tsx`
- Botão hambúrguer ganha `d-lg-none` — deixa de aparecer a partir de `lg`, já que a sidebar fica
  sempre visível e não precisa mais de toggle ali.

### `maintenances/new/page.tsx`
- `rows={3}` → valor maior (a definir durante a implementação, algo como `rows={5}` ou `6`).

## Critérios de Aceite

- [ ] Desktop (`≥ lg`): sidebar sempre visível, conteúdo não fica coberto por ela
- [ ] Mobile/tablet (`< lg`): comportamento de drawer idêntico ao de hoje (abre/fecha via hambúrguer)
- [ ] Área `/private` (admin) com o mesmo comportamento responsivo
- [ ] Campo de descrição da manutenção com mais linhas visíveis
- [ ] Verificado visualmente num browser real (dev server + Chrome), não só typecheck/lint — mudança
      de layout tem risco real de quebra visual que os dois não capturam

## Fora de escopo
- Redesenho visual do conteúdo da sidebar (ícones, agrupamento, cores) — só o comportamento
  fixo/drawer muda nesta task.
- Sidebar retrátil/colapsável — considerada, não é desta rodada.

## Dependências
Nenhuma.

## Riscos
Médio (pro item #10) — mudança de layout que afeta todas as telas autenticadas; testado em
`offcanvas-lg` nativo do Bootstrap (baixo risco de bug de lógica), mas precisa validação visual real
em vários breakpoints antes de considerar pronto. Baixo pro item #12 (mudança isolada).

## Esforço
Baixo-Médio

## Status
✅ Implementada, PR aberta contra `staging`:
[web#67](https://github.com/douglasjava/easy-maintenance-web/pull/67). Branch
`feature/TASK-222-sidebar-desktop-and-description-field`.

**Nota técnica**: a tentativa inicial de usar `offcanvas-lg` nativo do Bootstrap 5.3 não funcionou —
verificado num teste isolado num browser real (Bootstrap CSS de verdade via CDN, não suposição) que
esse mecanismo assume a sidebar dentro de `.navbar.navbar-expand-lg` (nav horizontal → hambúrguer),
não uma sidebar vertical persistente. Fix real: regra própria em `globals.css`
(`@media (min-width: 992px)`) forçando `#appSidebar` a `position:static`/visível, dentro de um
container flex no `Shell.tsx`. Validado visualmente em desktop no teste isolado antes de aplicar no
código real. `tsc`/`eslint` sem regressão.

**Limitação conhecida**: não foi possível validar visualmente em viewport mobile real neste
ambiente — a ferramenta de resize de janela não afetou o viewport do browser remoto usado nesta
sessão. A garantia de que o mobile fica inalterado é lógica (a regra nova só existe dentro da media
query maior, sem tocar em nada usado abaixo do breakpoint), não visual. **QA manual em mobile real
recomendado antes do merge.**

**01/09/2026 — mergeada em `staging`, PR `staging→main` aberta**:
[web#69](https://github.com/douglasjava/easy-maintenance-web/pull/69) (promove TASK-219 a TASK-223
juntas).
