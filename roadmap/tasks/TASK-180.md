# TASK-180 — Conteúdo: revisar post do blog sobre NBR 5674

## Tipo
FRONTEND (conteúdo)

## Categoria
Conteúdo Regulatório / Compliance

## Prioridade
🔵 Baixo

## Épico
[EPIC-025](../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas

## QA obrigatório
Não — é edição de conteúdo de post MDX já publicado, sem lógica nova. Revisão de leitura antes de
publicar (ler o post inteiro depois da edição pra garantir que o texto flui).

---

## Contexto

`easy-maintenance-web/src/app/blog/nbr-5674-responsabilidade-sindico/page.mdx` é o primeiro post do
blog, já publicado. O levantamento norma-a-norma (`docs/produto/levantamento-normas-abnt.md`,
análise da NBR 5674) encontrou 3 pontos pontuais de melhoria — nenhum é erro grave, são
complementos que aumentam a precisão e a credibilidade jurídica do texto.

## Objetivo

Aplicar 3 pequenos ajustes de conteúdo ao post, sem reescrever a estrutura.

## Escopo

1. **Mencionar manutenção preditiva**: o post hoje só fala de preventiva/corretiva. A NBR 5674
   reconhece um terceiro tipo — preditiva (baseada em dado real de condição: termografia, análise
   de vibração, sensores). Adicionar 1 frase nesse sentido, no trecho que já fala dos tipos de
   manutenção.
2. **Citar os artigos do Código Civil**: o post já fala de responsabilidade civil/criminal do
   síndico, mas sem citar a base legal específica. Adicionar referência ao **Art. 937** (proprietário
   responde por dano de ruína por falta de manutenção) e **Art. 938** (ocupante responde por dano de
   coisa que cai da unidade) do Código Civil — dá mais peso e credibilidade ao argumento já feito.
3. **Mencionar a reserva orçamentária anual**: a norma exige planejamento orçamentário anual com
   reserva para emergências, algo que o post não menciona hoje. Adicionar 1-2 frases — é um ponto
   prático que reforça a mensagem de "gestão séria de manutenção", alinhado ao posicionamento do
   produto.

## Critérios de Aceite

- [ ] Post menciona manutenção preditiva como terceiro tipo reconhecido pela norma
- [ ] Post cita Código Civil Art. 937 e Art. 938
- [ ] Post menciona a exigência de planejamento orçamentário anual com reserva de emergência
- [ ] Texto revisado flui naturalmente — não parece uma lista de tópicos colados no meio do post
- [ ] `npm run build` limpo

## Dependências
Nenhuma.

## Riscos
Baixo — é edição pontual de conteúdo já publicado, sem mudança estrutural.

## Esforço
Baixo

## Status
✅ Concluída — PR [#45](https://github.com/douglasjava/easy-maintenance-web/pull/45) mergeada em
`staging` em 19/08/2026. `npm run build` limpo. Ajuste da NBR 5674 na página `/norms` (menção à
preditiva) já tinha sido feito na TASK-179; aqui só o post do blog.
