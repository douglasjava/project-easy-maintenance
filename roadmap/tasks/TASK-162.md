# TASK-162 — Frontend: cadastro/edição de custo de infraestrutura

## Tipo
FRONTEND

## Categoria
Admin / Financeiro

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo)

## QA obrigatório
Sim — validar que lançar um novo valor não apaga o anterior e que o gráfico da TASK-161 reflete a
mudança no mês certo (não retroativamente).

---

## Contexto

Como não existe integração automática com as faturas de Railway/OpenAI/S3/Asaas, o custo de
infraestrutura é lançado manualmente. Esta task adiciona a interface pra isso na mesma página
criada na TASK-161 — consome os endpoints de custo criados na TASK-159.

---

## Objetivo

Seção na página `/financeiro` mostrando os valores vigentes atuais por categoria + formulário pra
lançar um novo valor.

---

## Escopo

### 1. Seção na página `financeiro/page.tsx` (ou componente separado importado nela)
- Tabela com os valores vigentes atuais: categoria, valor, vigente desde — busca
  `GET /admin/billing/expense-rates`.
- Formulário: categoria (select fixo com as 5 categorias), valor (R$), data de vigência (default
  hoje) → `POST /admin/billing/expense-rates`.
- Após salvar, atualiza a tabela e re-busca o gráfico/grid da TASK-161 (o novo custo pode afetar o
  mês atual exibido).
- Mensagem clara se a API rejeitar (ex.: vigência anterior à última já cadastrada — ver validação
  da TASK-159).

### 2. Testes
- Validar manualmente: lançar um valor novo pra uma categoria existente mantém o valor antigo
  associado aos meses anteriores no gráfico (não reescreve o passado).

---

## Critérios de Aceite

- [ ] Tabela mostra o valor vigente atual de cada categoria
- [ ] Formulário lança novo valor com sucesso e atualiza a tela sem reload manual
- [ ] Erro de validação da API (vigência inválida) aparece de forma clara pro usuário
- [ ] `npm run build` limpo

## Dependências
- **TASK-159** — endpoints de custo precisam existir.
- **TASK-161** — a página precisa existir antes de adicionar essa seção nela.

## Riscos
Baixo — CRUD simples sobre endpoint já pronto.

## Esforço
Baixo

## Status
Pronto para Implementar
