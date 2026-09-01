# TASK-223 — FRONTEND: Refinamento visual da sidebar (ícones, hover, estado ativo)

## Tipo
FRONTEND

## Categoria
Frontend / UX (design visual)

## Prioridade
🟢 Baixo — refinamento visual sobre a TASK-222 (sidebar fixa em desktop), a pedido do Douglas via
skill `frontend-design` depois de ver o resultado da TASK-222 em produção.

## QA obrigatório
Sim — QA manual: conferir os 3 estados de cada item (normal, hover, ativo) em desktop; conferir que
o comportamento de drawer em mobile continua sem regressão (só o conteúdo visual dos itens muda,
não a mecânica de abrir/fechar); conferir a área `/private` (admin) também.

---

## Contexto

TASK-222 tornou a sidebar fixa em desktop. Ao ver o resultado, Douglas achou que ainda dava pra
melhorar o menu, mas sem certeza do quê — pediu avaliação via skill `frontend-design`. Achados
concretos (não just "parece que falta algo"):

1. **Zero ícone** — lista de texto puro, apesar do dashboard já ter um vocabulário de ícone
   estabelecido (`QuickActions.tsx`: 📦 Itens, 🔧 Manutenções, 🤖 IA Onboarding) que a sidebar não
   reaproveita.
2. **Sem hover** — nenhum feedback visual antes do clique em nenhum item.
3. **Estado ativo fraco** — só borda esquerda de 3px + um ponto de 8px. Fácil de não notar em qual
   página se está.
4. **Seção "Ações" indiferenciada** — visualmente idêntica a "Principal"/"Recursos", apesar de conter
   as duas ações mais importantes do produto (criar item, registrar manutenção).

## Decisão de design (mockup validado com Douglas antes de implementar)

Construído e testado num browser real (não só descrito) um comparativo antes/depois. Reaproveita o
que já existe no app — mesma paleta (`#0B5ED7` primary, `#F59E0B` accent, `#F3F4F6` bg), mesmo stack
de fonte do sistema (sem fonte nova), mesmo vocabulário de ícone em emoji já usado no
`QuickActions.tsx` do dashboard (extensão, não sistema novo). Sem novas dependências.

- Ícone emoji antes de cada label (reaproveita 📦🔧🤖 do dashboard; novos: 🏠 Dashboard, ➕ Novo Item,
  ⚖️ Normas, 📊 Relatórios, ❓ Ajuda, mais os itens de admin).
- Hover: fundo neutro sutil (`rgba(15,23,42,.045)`) em todo item não-ativo.
- Ativo: fundo azul claro arredondado + texto em negrito + cor primária + barra lateral — troca o
  "pontinho" por um sinal mais forte.
- Divisores finos entre seções em vez de só espaço em branco.

## Escopo

### `Sidebar.tsx`
- Adiciona um mapa `icon` por `NavItem` (emoji).
- `NavLink`: renderiza ícone antes do label; troca o indicador de "ponto" pelo novo estado ativo
  (fundo + peso de fonte + barra lateral); adiciona hover.
- Divisores finos (`<hr>` ou borda sutil) entre as seções, no lugar dos `<div className="mt-2"/>`
  atuais.
- Sem mudança de estrutura de navegação, permissões, ou mecânica de abrir/fechar — só o visual dos
  itens.

## Critérios de Aceite

- [ ] Todos os itens da sidebar (usuário e admin) têm ícone
- [ ] Hover visível em item não-ativo
- [ ] Estado ativo claramente perceptível (fundo + peso + barra lateral)
- [ ] Seções separadas por divisor fino
- [ ] Sem regressão no comportamento de drawer em mobile (só o conteúdo visual dos itens muda)
- [ ] `tsc --noEmit` e `eslint` sem regressão

## Fora de escopo
- Qualquer mudança de estrutura/permissão de navegação — só o visual.
- Sidebar retrátil/colapsável (já descartada na TASK-222).

## Dependências
TASK-222 (sidebar fixa em desktop), já mergeada em `staging`.

## Riscos
Baixo — mudança puramente visual dentro de um componente já isolado, sem tocar em lógica de
permissão/navegação.

## Esforço
Baixo

## Status
✅ Implementada, PR aberta contra `staging`:
[web#68](https://github.com/douglasjava/easy-maintenance-web/pull/68). Branch
`feature/TASK-223-sidebar-visual-refinement`. `tsc`/`eslint` sem regressão — na verdade melhora: de
6 pra 2 erros pré-existentes no arquivo (aproveitado pra mover `SectionTitle`/`NavLink`/
`SectionDivider` pra fora do render, corrigindo violação de `react-hooks/static-components` já
flagada antes desta task). Design validado num mockup isolado em browser real antes de implementar.
Não foi possível testar o componente de produção num browser real (exige login) — QA manual
recomendado.
