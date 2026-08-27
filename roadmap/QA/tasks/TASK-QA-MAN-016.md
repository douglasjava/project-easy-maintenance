# TASK-QA-MAN-016 — QA Manual: Split de comissão entre beneficiários (caso Grupo Silva)

## Tipo
QA Manual

## Categoria
Backend + Frontend / Admin, Financeiro, Afiliados

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Revisão da Fase 2 — split de comissão

## Tasks cobertas
[TASK-207](../../tasks/TASK-207.md) — Backend: `affiliate_commission_splits` + endpoints + beneficiários no breakdown
[TASK-208](../../tasks/TASK-208.md) — Frontend: ação "Dividir comissão" + sub-linhas no financeiro

---

## Descrição

Valida a divisão de comissão de um afiliado entre N beneficiários (ex.: "Grupo Silva" + vendedora que
fechou a venda), sem alterar a regra de "1 comissionado ativo por cliente" nem o schema de
`ReferralCommission`/`CommissionService` — o split é só uma visão de rateio consultada no breakdown
mensal do financeiro.

**Como o percentual do split se relaciona com `commissionRate` do afiliado (ponto que gerou dúvida
real com Douglas, 27/08/2026):** o split **não** substitui `commissionRate` — ele reparte o total já
configurado no afiliado. Exemplo real usado nesta QA: vendedora 35% + Grupo Silva 10% (ambos sobre a
venda, mesma recorrência) → `Affiliate.commissionRate` do "Grupo Silva" precisa ser **45%** (35+10);
dentro do split, os percentuais digitados são a *proporção de cada um dentro desses 45%*, não o
percentual da venda direto:
- Vendedora: 35 ÷ 45 = **77,78%**
- Grupo Silva: 10 ÷ 45 = **22,22%**

(77,78 + 22,22 = 100% — é isso que a tela valida como "soma tem que fechar em 100%".) Confirmado com
Douglas: recorrência é igual para os dois beneficiários neste caso — o split atual não suporta
recorrência diferente por beneficiário (é propriedade do afiliado inteiro, `Affiliate.recurrenceType`);
se algum caso futuro precisar disso, é uma task nova, fora do escopo de TASK-207/208.

Toda a implementação está em branches próprias, sem PR aberta ainda:
- `feature/TASK-207-commission-split` (`easy-maintenance-api`, commit `fcadbbb`)
- `feature/TASK-208-commission-split-ui` (`easy-maintenance-web`, commit `1c628e5`)

---

## Pré-condições

- Checkout das duas branches acima, rodando local (api + web apontando um pro outro).
- Acesso admin (`/private/admin/affiliates` e `/private/admin/financials`).
- **Sem clientes pagantes reais ainda** — pra ter comissão de teste no mês atual, usar o simulador de
  QA (perfil `local`/`dev`/`staging`/`debug` apenas):
  ```
  POST /easy-maintenance/api/v1/dev/simulate/affiliate-flow
  { "affiliateCode": "<código de um afiliado existente>", "planCode": "<código de plano válido>", "amountCents": 15000 }
  ```
  Gera um usuário sintético + pagamento + comissão real (`ReferralCommission`) pro afiliado
  informado, no mês corrente — suficiente pra aparecer no breakdown do financeiro sem precisar de
  Asaas real. Repetir com `existingUserId` se quiser gerar uma segunda comissão de teste sem duplicar
  o usuário.
- Pelo menos 2 afiliados cadastrados em `/private/admin/affiliates`: um que vai ganhar split (ex.:
  "Grupo Silva") e um que fica sem split (pra validar que nada muda pra quem não usa o recurso).

---

## Cenários de Teste

### C1 — Suíte automatizada, sem regressão

| Passo | Ação                                                              | Resultado esperado                                                                                                                        |
|-------|-------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | `mvn test` na api (branch `feature/TASK-207-commission-split`)    | 843/843 testes passando, incluindo os novos casos de `AffiliateServiceTest`/`AffiliateRepositoryTest`/`FinancialsServiceTest` sobre split |
| 2     | `npm test` no web (branch `feature/TASK-208-commission-split-ui`) | 105/108 passando — as 3 falhas são em `middleware.test.ts`, pré-existentes, sem relação                                                   |
| 3     | `npm run build` no web                                            | Build limpo, 54 rotas, sem erro de TypeScript                                                                                             |

---

### C2 — Gerar comissão de teste pro afiliado que vai ganhar split

| Passo | Ação                                                                                         | Resultado esperado                                                                         |
|-------|----------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|
| 1     | Cadastrar (ou reaproveitar) um afiliado chamado "Grupo Silva" em `/private/admin/affiliates` | Afiliado criado com `commissionRate` e `recurrenceType` próprios                           |
| 2     | Chamar `POST /dev/simulate/affiliate-flow` com o `affiliateCode` do Grupo Silva              | `SimulationResult` retorna `commissionId`/`commissionAmount` preenchidos, sem `error`      |
| 3     | Abrir `/private/admin/financials` no mês corrente                                            | Seção "Comissões por pessoa" mostra a linha "Grupo Silva" com o valor da comissão simulada |

---

### C3 — Afiliado sem split configurado: comportamento idêntico ao atual (regressão)

| Passo | Ação                                                                                                  | Resultado esperado                                                                 |
|-------|-------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| 1     | Gerar uma comissão de teste (C2) pra um segundo afiliado, sem configurar split nele                   | Aparece no breakdown normalmente, como antes desta feature                         |
| 2     | Conferir a linha desse afiliado no financeiro                                                         | Nenhuma sub-linha extra aparece — visual idêntico ao que já existia antes do split |
| 3     | Na tela de afiliados, abrir "Dividir comissão" nesse afiliado sem configurar nada e fechar (Cancelar) | Nada é persistido, afiliado continua sem split                                     |

---

### C4 — Configurar split de 2 beneficiários somando 100% (caso real: vendedora 35% + Grupo Silva 10%)

| Passo | Ação                                                                                                        | Resultado esperado                                                               |
|-------|--------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| 1     | Cadastrar/editar o afiliado "Grupo Silva" com `commissionRate` = **45%** (35 da vendedora + 10 do grupo)    | Afiliado salvo com 45%                                                            |
| 2     | Em `/private/admin/affiliates`, clicar "Dividir comissão" na linha do Grupo Silva                          | Modal abre, vazio (2 linhas em branco, nenhum split configurado ainda)           |
| 3     | Preencher linha 1: "Vendedora" / **77,78%** — linha 2: "Grupo Silva" / **22,22%** (proporção de 35 e 10 dentro dos 45% totais) | Texto "Soma atual: 100%" aparece em cinza (não vermelho)          |
| 4     | Clicar "Salvar"                                                                                              | Toast de sucesso ("Divisão de comissão salva"), modal fecha                      |
| 5     | Reabrir "Dividir comissão" no mesmo afiliado                                                                 | Modal carrega as 2 linhas já preenchidas com os valores salvos (77,78% e 22,22%) |

---

### C5 — Validação client-side bloqueia soma diferente de 100%

| Passo | Ação                                                                                           | Resultado esperado                                                                                              |
|-------|------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| 1     | Abrir "Dividir comissão" em qualquer afiliado, preencher 2 linhas somando 90% (ex.: 60% + 30%) | Texto "Soma atual: 90%" aparece em **vermelho**, negrito                                                        |
| 2     | Clicar "Salvar"                                                                                | Nada é enviado à API (conferir aba Network — nenhuma chamada `PUT .../splits`); mensagens de validação aparecem |
| 3     | Corrigir pra somar 100% (ex.: 70% + 30%) e salvar novamente                                    | Salva normalmente                                                                                               |

---

### C6 — Financeiro mostra sub-linhas de beneficiário com valores corretos

| Passo | Ação                                                                                                              | Resultado esperado                                                                                                                                                    |
|-------|-------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Com o split de C4 configurado (Vendedora 77,78% / Grupo Silva 22,22%) e uma comissão gerada (C2)                  | —                                                                                                                                                                    |
| 2     | Abrir `/private/admin/financials`, mês corrente, anotar o valor total da linha "Grupo Silva" (ex.: R$X)          | Logo abaixo da linha principal, 2 sub-linhas indentadas aparecem: "↳ Vendedora" e "↳ Grupo Silva"                                                                   |
| 3     | Calcular manualmente 77,78% e 22,22% de R$X e comparar com os valores das sub-linhas                              | Sub-linha "Vendedora" ≈ 77,78% de R$X; sub-linha "Grupo Silva" ≈ 22,22% de R$X — a soma das duas pode ficar 1 centavo abaixo de R$X por truncamento (documentado na TASK-207, não é bug) |

---

### C7 — Remover divisão

| Passo | Ação                                                                   | Resultado esperado                                                                                   |
|-------|------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| 1     | Com o split de C4 configurado, abrir "Dividir comissão" no Grupo Silva | Botão "Remover divisão" aparece no rodapé (só aparece quando já existe split)                        |
| 2     | Clicar "Remover divisão"                                               | Abre `ConfirmModal` perguntando confirmação — nenhum `confirm()` nativo do navegador                 |
| 3     | Confirmar                                                              | Toast de sucesso, modal fecha                                                                        |
| 4     | Abrir `/private/admin/financials` novamente                            | Linha "Grupo Silva" volta a aparecer sozinha, sem sub-linhas — 100% pra ele mesmo, igual antes de C4 |
| 5     | Reabrir "Dividir comissão" no Grupo Silva                              | Modal abre vazio (2 linhas em branco) — botão "Remover divisão" não aparece mais                     |

---

### C8 — Backend direto: contratos de erro (opcional, via curl/Postman)

| Passo | Ação                                                                                                                                                              | Resultado esperado                                        |
|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------|
| 1     | `GET /private/admin/affiliates-commissions/999999/splits` (id inexistente)                                                                                        | 404                                                       |
| 2     | `PUT /private/admin/affiliates-commissions/{id real}/splits` com `[{"beneficiaryName":"A","percentage":0.5},{"beneficiaryName":"B","percentage":0.3}]` (soma 80%) | 400, `ProblemDetail` com mensagem citando a soma recebida |
| 3     | `PUT` no mesmo endpoint com lista vazia `[]`                                                                                                                      | 200, lista vazia retornada, split removido                |

---

## Critérios de Aceite da Suíte

- [X] C1: suíte automatizada (backend + frontend) sem regressão
- [X] C2: comissão de teste gerada via simulador, aparece no breakdown
- [X] C3: afiliado sem split — nenhuma mudança visual ou de comportamento
- [ ] C4: configurar split de 2 beneficiários somando 100% persiste e recarrega corretamente
- [ ] C5: soma diferente de 100% bloqueia o salvamento no cliente, sem chamar a API
- [ ] C6: sub-linhas no financeiro mostram valores proporcionais corretos
- [ ] C7: remover divisão (com confirmação) volta o afiliado a 100% pra ele mesmo
- [ ] C8 (opcional): contratos de erro do backend (404/400) corretos

---

## Status
📋 Criada (27/08/2026) — aguardando execução por Douglas. Sem PR aberta ainda em nenhum dos dois
repos; abrir só depois desta QA passar.
