# TASK-384 — FRONTEND: tela `/pessoas` — abas e formulário "Adicionar pessoa"

## Tipo
FRONTEND

## Categoria
Pessoas e Papéis

## Prioridade
🟠 Alto

## Épico
[EPIC-039](../epics/EPIC-039.md) — Pessoas e Papéis

## QA obrigatório
Sim — cadastrar pessoa em cada uma das 5 abas, confirmar campo Detalhe mudando conforme o Papel
selecionado, responsividade mobile.

---

## Contexto
Frontend do CRUD de `CondoPerson` (TASK-383), espelhando o protótipo do Tiago. Detalhe completo na
spec de Pessoas e Papéis, seção "Frontend (rascunho)".

## Escopo
- Rota nova `/pessoas`, abas Gestão/Conselho/Moradores/Fornecedores (aba Unidades fica na
  TASK-385) como state local, mesmo padrão já adotado em `/configuracoes` (EPIC-038) — sem
  sub-rota por aba.
- Cada aba lista as pessoas filtradas por papel (`GET /organizations/condo-people?role=`).
- Formulário único "Adicionar pessoa": Documento, Nome, Tipo PF/PJ, E-mail, Telefone/WhatsApp (com
  toggle de opt-in), Papel, Detalhe (select condicional ao Papel escolhido — reflete o mapa de
  `role_detail` válido da TASK-383), Unidade (select, vazio para papéis sem unidade), Fornecedor
  (segundo combo, só aparece quando Papel = Fornecedor, linkando ao cadastro existente), Início/fim
  de mandato, Remunerado, Aprova orçamentos.
- Estados de loading/erro/vazio consistentes com o resto do app.

## Critérios de Aceite
- [ ] As 4 abas (Gestão/Conselho/Moradores/Fornecedores) listam só pessoas do papel correspondente
- [ ] Campo Detalhe muda as opções disponíveis conforme o Papel selecionado, e fica ausente/
      desabilitado para papéis sem detalhe (Subsíndico/Zelador/Administradora/Construtora)
- [ ] Papel Fornecedor exibe o combo de vínculo ao `Supplier` existente e oculta campos de
      documento/nome manual (vêm do fornecedor selecionado)
- [ ] Erro de validação do backend (ex. combinação `role`/`role_detail` inválida) aparece como
      mensagem legível, não crash/tela branca
- [ ] Funciona em viewport mobile
- [ ] `npm run build`/`tsc --noEmit` sem regressão

## Dependências
TASK-383 (contrato de API). Desbloqueia TASK-385 (aba Unidades vive na mesma página) e TASK-386.

## Riscos
Baixo — extensão de padrão de tela já existente (`/configuracoes`), sem mudança estrutural de
rota/layout.

## Esforço
Médio

## Status
Em Validação — implementado em `feature/EPIC-039-pessoas-papeis` (web), `tsc`/`build` limpos, aguardando push/PR e QA manual (cadastrar pessoa em cada aba, campo Detalhe condicional, mobile).
