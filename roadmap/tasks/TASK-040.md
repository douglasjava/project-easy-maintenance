# TASK-040 — Acessibilidade básica (WCAG AA)

## Tipo
UX / Produto / Qualidade

## Categoria
Frontend / UX

## Prioridade
🔵 Baixo

## Fase
3 — Escala

## Épico
EPIC-006 — Produto SaaS

## Descrição
A aplicação usa Bootstrap 5 que fornece uma base razoável de acessibilidade, mas componentes customizados (modais, dropdowns, formulários, tabelas) podem não ter os atributos ARIA corretos. Para um produto que atende segmentos como hospitais e organizações governamentais, acessibilidade pode ser requisito legal.

## Critérios de Aceite
- [ ] Auditoria de acessibilidade com axe-core ou Lighthouse (meta: zero erros críticos)
- [ ] Formulários com `aria-label` ou `aria-describedby` em todos os campos
- [ ] Navegação por teclado funcional nas rotas principais
- [ ] Contraste de cores em conformidade com WCAG AA (4.5:1 para texto normal)
- [ ] Modais com focus trap e `aria-modal`
- [ ] Imagens e ícones funcionais com `alt` ou `aria-label`

## Esforço
Grande (1 semana de auditoria + correções)

## Status
Backlog
