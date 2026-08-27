# TASK-208 — Frontend: configurar divisão de comissão + exibir beneficiários no financeiro

## Tipo
FRONTEND

## Categoria
Admin / Financeiro / Afiliados

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Revisão da Fase 2 — split de comissão

## QA obrigatório
Sim — QA manual: configurar split de 2 beneficiários somando 100% e confirmar persistência; tentar
salvar com soma diferente de 100% e confirmar bloqueio com mensagem clara; remover o split (lista
vazia) e confirmar que volta a mostrar só o afiliado; conferir que a tela de financeiro mostra as
sub-linhas de beneficiário só pra afiliado com split configurado, sem afetar quem não tem.

---

## Contexto

Depende da TASK-207 (endpoints `GET`/`PUT /private/admin/affiliates-commissions/{id}/splits` e campo
`beneficiaries` no breakdown mensal). Caso real: "Grupo Silva" precisa dividir a comissão de um
cliente entre o grupo e o vendedor que fechou a venda — hoje `/private/admin/affiliates` (seção
"Comissionados", criada na TASK-198) só edita `commissionRate`/`recurrenceType` do afiliado como um
todo, sem noção de divisão interna.

## Objetivo

Tela de afiliados ganha ação "Dividir comissão" por linha; tela de financeiro mostra o valor do mês
já dividido por beneficiário, quando configurado.

## Escopo

### 1. `easy-maintenance-web/src/app/private/admin/affiliates/page.tsx` — ação nova

- Ação "Dividir comissão" por linha na seção "Comissionados" (ao lado de "Editar" e "Atribuir
  cliente", já existentes desde a TASK-198) → abre `CommissionSplitModal.tsx` (novo).
- `CommissionSplitModal.tsx`: carrega splits atuais (`GET .../{id}/splits`); lista editável de
  linhas nome + percentual (input 0-100, convertido pra fração no payload, mesmo padrão de
  `AffiliateEditModal`); botões "Adicionar beneficiário"/remover linha; validação client-side — soma
  precisa fechar em 100% antes de habilitar "Salvar" (mensagem de erro inline se não bater, mesmo
  padrão de validação já usado em outros formulários admin); "Salvar" chama
  `PUT .../{id}/splits` com a lista (lista vazia = ação "Remover divisão", volta o afiliado a 100%
  pra ele mesmo).

### 2. `easy-maintenance-web/src/app/private/admin/financials/page.tsx` — sub-linhas de beneficiário

- `CommissionsBreakdownSection` (já existe, TASK-198): quando a linha do afiliado tiver
  `beneficiaries` não vazio na resposta, renderizar sub-linhas indentadas abaixo da linha principal
  (nome do beneficiário + valor do mês já calculado pelo backend). Sem split configurado
  (`beneficiaries` vazio), comportamento idêntico ao atual — sem mudança visual.

### 3. Testes / verificação
- `npm run build` limpo.
- QA manual (ver "QA obrigatório").

## Critérios de Aceite

- [ ] "Dividir comissão" abre modal com beneficiários atuais (vazio se nenhum configurado)
- [ ] Salvar com soma != 100% é bloqueado no cliente, com mensagem clara, sem chamar a API
- [ ] Salvar com soma == 100% persiste e reflete na tabela/breakdown
- [ ] Salvar lista vazia remove o split (afiliado volta a aparecer sozinho no breakdown)
- [ ] Breakdown do financeiro mostra sub-linhas de beneficiário só pra afiliado com split
      configurado, sem alterar a exibição de quem não tem
- [ ] `npm run build` limpo

## Dependências
**TASK-207** (endpoints de split e campo `beneficiaries` no breakdown).

## Riscos
Baixo — extensão da tela de afiliados e financeiro já existentes, mesmo padrão de modal já usado em
`AffiliateEditModal`/`AssignCommissionedModal`, sem tocar em fluxo de cliente final.

## Esforço
Médio

## Status
📋 Criada (27/08/2026) — ainda não implementada.
