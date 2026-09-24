# TASK-285 — Frontend: página pública `/para-fornecedores` (divulgação + políticas)

## Tipo
FRONTEND

## Categoria
Marketing / Marketplace de Fornecedores

## Prioridade
🟠 Alto — aquisição de fornecedores pagantes

## Épico
[EPIC-028](../epics/EPIC-028.md) — Marketplace de Fornecedores

## QA obrigatório
Sim — QA manual no browser (acesso deslogado, responsividade, CTAs, eventos de tracking, regressão
do cadastro/pagamento de fornecedor).

---

## Contexto

O marketplace de fornecedores está pronto de ponta a ponta (cadastro, Pix Automático R$ 15,99/mês,
autogestão via link mágico, pedido de orçamento no WhatsApp), mas não existe página para divulgar
ao fornecedor por que participar, quanto custa e quais são as regras. Detalhe completo em
`docs/superpowers/specs/2026-09-24-pagina-para-fornecedores-design.md`.

## Escopo

- Nova rota pública `/para-fornecedores`: hero com foto, por que participar, como funciona (mockups
  do card no marketplace e da mensagem no WhatsApp), preço, políticas (`#politicas`), FAQ, CTA final.
- `Shell.tsx` (allowlist pública), `sitemap.ts`, `metadata` + Open Graph.
- Link "Para fornecedores" no footer da `/landing`; link "Como funciona e políticas" em
  `/fornecedores/cadastro`.
- `lib/tracking.ts`: evento de clique no CTA + `CompleteRegistration` no cadastro concluído.

## Critérios de Aceite

- [ ] `/para-fornecedores` acessível deslogado (sem redirect pro `/login`) e logado
- [ ] Responsiva em 390/1024/1366/1920px, sem scroll horizontal
- [ ] Todos os CTAs levam a `/fornecedores/cadastro`; `#politicas` funciona; links do footer da
      `/landing` e de `/fornecedores/cadastro` funcionam
- [ ] Texto de políticas bate com a tabela "Políticas → comportamento verificado" do spec
- [ ] Nenhuma prova social numérica na página
- [ ] Eventos Pixel/GA disparam no clique do CTA e no cadastro concluído (testes em `tracking.test.ts`)
- [ ] Fluxo de cadastro/pagamento de fornecedor inalterado
- [ ] `tsc`/`lint`/`build` limpos, `npm test` sem regressão nova

## Dependências
Nenhuma.

## Riscos
Baixo — página nova, aditiva, sem backend. Atenção à allowlist do `Shell.tsx` (bug recorrente).

## Esforço
Médio

## Status
Backlog — spec aprovado, aguardando plano de implementação
