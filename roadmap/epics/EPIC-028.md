# EPIC-028 — Cadastro de Fornecedores pelos Usuários + Inteligência de Pontuação

## Status
💡 Ideia registrada (07/09/2026), **não desenhada, não priorizada**. Aguardando sessão de
brainstorm calma com Douglas antes de qualquer detalhamento técnico ou task.

## Objetivo (macro)
Permitir que os usuários finais (organizações clientes) cadastrem fornecedores por conta própria —
hoje o [EPIC-023](EPIC-023.md) só sugere fornecedores buscados via Google Places (dado externo, sem
histórico real de uso). Com fornecedores cadastrados pelos próprios clientes, dá pra construir uma
"inteligência de pontuação" que os recomenda para outras edificações próximas geograficamente.

## Descrição (nível macro, como Douglas trouxe)

> "Para os usuários finais eles poderem cadastrarem os fornecedores e a gente ter uma inteligência
> de pontuação para poder indica-los se estiverem próximo a outras edificações."

## ⚠️ Ponto estratégico explícito do Douglas
Esse épico **não abre mão do case futuro de capitalizar por essa porta** — ou seja, a intenção
declarada é que essa rede de fornecedores cadastrados/pontuados vire, no futuro, uma fonte de
monetização própria (ex.: fornecedor pago pra aparecer melhor ranqueado, cobrança por lead
gerado ao fornecedor, etc. — nada disso decidido ainda, só a intenção de **não desenhar o modelo de
dados de um jeito que feche essa porta**). Isso é um requisito não-funcional a levar em conta desde
o primeiro desenho técnico do épico, não um detalhe de monetização a adicionar depois.

## Sem escopo técnico definido ainda
- Modelo de dados do "fornecedor cadastrado pelo cliente" (é um dado por organização, ou um dado
  compartilhado entre organizações desde já?).
- Como a "pontuação"/ranking funciona (nº de vezes indicado? avaliação de outros clientes? não
  definido).
- Como "próximo a outras edificações" é calculado (mesma cidade, como hoje no
  [EPIC-023](EPIC-023.md)? raio geográfico real via lat/long?).
- Relação com o `SupplierLookupService`/`SupplierSearchService` já existentes (TASK-172) — esse
  novo fluxo substitui, complementa ou roda em paralelo com a busca via Google Places?

## Fora de escopo (por ora)
Qualquer detalhamento de arquitetura, modelo de dados, telas ou modelo de monetização —
propositalmente, a pedido do Douglas ("deixar anotado... pra analisar mais friamente" depois).

## Riscos conhecidos (nível macro)
- Dado compartilhado entre organizações (um fornecedor visível pra outra edificação) quebra a
  premissa de isolamento multi-tenant estrito usada no resto do produto hoje — precisa decisão de
  produto explícita sobre o que é dado privado da organização vs. dado que intencionalmente cruza
  tenants.
- Qualidade do dado (fornecedor cadastrado manualmente por um cliente pode estar errado/desatualizado)
  — sem esse cuidado, a "pontuação" perde confiança rápido.
