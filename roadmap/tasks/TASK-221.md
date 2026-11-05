# TASK-221 — FRONTEND: Fecha o ciclo item → manutenção nas telas de criação

## Tipo
FRONTEND

## Categoria
Frontend / Itens + Manutenções (UX pós-criação)

## Prioridade
🟢 Baixo-Médio — item #8 da demo com o cliente Rogerio Dantas (31/08/2026, ver `TASK-218.md`)

## QA obrigatório
Sim — QA manual: criar um item novo e testar os 3 caminhos do painel de sucesso ("Registrar
manutenção agora", "Ver lista de itens", "Cadastrar outro item"); registrar uma manutenção e
confirmar o redirecionamento certo em cada `origin` (direto, vindo do item, vindo do dashboard).

---

## Contexto

Hoje as duas telas de criação (`/items/new` e `/maintenances/new`) fazem a mesma coisa depois de
salvar: mostram um toast e resetam o formulário, sem navegar pra lugar nenhum. Isso favorece cadastro
rápido em sequência, mas não fecha o ciclo "criei o item → devo registrar a manutenção dele". Achado
levantado por Douglas ao ver o Rogerio, na demo, criar um item e emendar registrando a manutenção na
sequência.

## Decisão de design (discutida com Douglas — análise de UX antes de criar a task)

**Manutenção (`/maintenances/new`)**: ao finalizar o registro, navega pra listagem de manutenções —
mas reaproveitando o `backHref` que a tela já calcula a partir do `origin` (usado hoje só pro link
"← Voltar"): se veio do detalhe de um item (`origin=item-detail`), volta pro detalhe daquele item
(onde a manutenção recém-criada já aparece no histórico); se veio do dashboard, volta pro dashboard;
senão, vai pra listagem geral. Mais inteligente que só mandar sempre pra listagem, sem custo extra —
o cálculo já existe.

**Item (`/items/new`)**: rejeitada a ideia inicial de um modal 50/50 ("listagem OU manutenção") — mata
o fluxo de cadastro em lote (alguém criando vários itens seguidos). Em vez disso, um painel de
confirmação (mesmo padrão visual do passo 2 da tela de manutenção, que já é um mini-wizard) com 3
ações, não 2:
- **"Registrar manutenção agora →"** — botão primário, reforça o ciclo que o Douglas quer.
- **"Ver lista de itens"** — botão secundário.
- **"Cadastrar outro item"** — link discreto, preserva o fluxo rápido de cadastro em lote sem ele
  precisar ser a única opção visível.

## Escopo

### `easy-maintenance-web/src/app/items/new/page.tsx`
- Novo estado `createdItem: { id, itemType } | null`, setado com a resposta da API no `POST /items`
  (hoje a resposta nem é capturada) no lugar de `setFormData(EMPTY_FORM)`.
- Card do formulário só renderiza quando `!createdItem`; quando `createdItem` existe, renderiza o
  painel de sucesso com os 3 caminhos acima.
- "Registrar manutenção agora" navega pra `/maintenances/new?itemId={id}&origin=item-detail` —
  reaproveita o mesmo `origin` que a tela de manutenção já entende (mesmo destino de retorno do botão
  que já existe no detalhe do item).
- "Ver lista de itens" navega pro `backHref` que a tela já calcula (`/items` ou `/` se
  `origin=dashboard`).
- "Cadastrar outro item" limpa `createdItem` e reseta o formulário (comportamento de hoje).
- Sem mudança no fluxo de **edição** de item (`editId` presente) — esse já navega direto (`router.push(backHref)`
  após atualizar), não é afetado.

### `easy-maintenance-web/src/app/maintenances/new/page.tsx`
- Importa `useRouter`, adiciona `const router = useRouter()`.
- Botão "Finalizar registro" (passo 2, anexos): troca `onClick={() => resetForm()}` por navegação pro
  `backHref` já calculado (reaproveita a mesma variável usada no link "← Voltar").

## Critérios de Aceite

- [ ] Criar item mostra painel de sucesso com os 3 caminhos, sem quebrar o formulário
- [ ] "Registrar manutenção agora" leva pro registro de manutenção já com o item selecionado
- [ ] "Ver lista de itens" leva pra `/items` (ou `/` se veio do dashboard)
- [ ] "Cadastrar outro item" volta pro formulário limpo, sem sair da página
- [ ] Finalizar registro de manutenção navega — pro detalhe do item (se veio de lá), pro dashboard (se
      veio de lá), ou pra listagem de manutenções (padrão)
- [ ] Edição de item continua com o comportamento de hoje, sem regressão
- [ ] `tsc --noEmit` e `eslint` sem regressão nos arquivos alterados

## Fora de escopo
- Qualquer mudança na tela de listagem de itens ou manutenções em si.
- O fluxo de importação por planilha (spec já escrita à parte) — cadastro em lote de verdade migra
  pra lá, não é resolvido nesta task.

## Dependências
Nenhuma.

## Riscos
Baixo — mudança de navegação pós-sucesso em 2 telas, sem tocar em regra de negócio nem contrato de
API.

## Esforço
Baixo

## Status
✅ Implementada, PR aberta contra `staging`:
[web#66](https://github.com/douglasjava/easy-maintenance-web/pull/66). Branch
`feature/TASK-221-post-create-navigation`. `tsc`/`eslint` sem regressão (confirmado via stash).
Falta QA manual: os 3 caminhos do painel de item, os 3 `origin` de finalização de manutenção,
regressão na edição de item.

**01/09/2026 — mergeada em `staging`, PR `staging→main` aberta**:
[web#69](https://github.com/douglasjava/easy-maintenance-web/pull/69) (promove TASK-219 a TASK-223
juntas).
