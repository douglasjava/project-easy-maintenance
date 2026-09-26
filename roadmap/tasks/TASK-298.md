# TASK-298 — IA de onboarding lê o manual do síndico (PDF) e monta itens + cronograma

## Tipo
FULL_STACK (IA + upload + onboarding)

## Prioridade
🟡 Médio — gancho de implantação usado por concorrente; não bloqueia venda

## Contexto
Comparação com o Manu Help (25/09/2026): "Envie o manual do síndico e nossa IA monta o cronograma"
é o argumento de implantação deles ("começa a operar em dias, não em meses").

Hoje a nossa IA de onboarding (`AiBootstrapService`, `AiBootstrapPreviewRequest`) recebe só
`companyType` + `description` (texto livre) e gera sugestões de itens a partir do catálogo. Ela não
lê documentos.

O "Manual de Uso, Operação e Manutenção" (NBR 14037) que a construtora entrega traz os sistemas do
prédio e as periodicidades de manutenção. É a fonte mais completa para montar o plano de manutenção
(NBR 5674) sem digitação.

## Proposta (a detalhar em brainstorming)
- Upload de PDF (e talvez foto de páginas) no IA Onboarding.
- Extração de texto (PDF com texto; OCR fica fora do MVP) → IA mapeia sistemas/equipamentos para os
  `item_type` do catálogo + periodicidade + norma, com a mesma revisão e aprovação do fluxo atual
  (preview → aplicar).
- Itens que não existem no catálogo viram sugestão operacional, sem inventar norma (regra da TASK-212).

## Riscos / pontos de atenção
- Custo de tokens (manuais têm 50–200 páginas): limite de páginas, resumo por seção, créditos de IA
  do plano (`aiMonthlyCredits`).
- Plano: IA só no Business/Enterprise. Decidir se o upload do manual entra no trial.
- Arquivo vai para o S3 (mesma infraestrutura de anexos). Tratar LGPD e tamanho máximo do plano.
- Qualidade: manuais variam muito. Nenhum item é criado sem a revisão do usuário.

## Critérios de Aceite
- [ ] Usuário sobe o manual em PDF e recebe o preview de itens com periodicidade
- [ ] Nada é criado sem aprovação no preview
- [ ] Item regulatório só com `item_type` curado (sem norma inventada)
- [ ] Consumo de créditos de IA controlado e visível
- [ ] Erro claro para PDF sem texto / grande demais

## Status
Backlog — precisa de brainstorming/spec antes
