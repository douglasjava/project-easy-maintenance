# TASK-202 — Frontend: validação de dígito verificador de CPF/CNPJ no onboarding

## Tipo
FRONTEND

## Categoria
Billing / Onboarding — Confiabilidade

## Prioridade
🟠 Alto

## Épico
[EPIC-002](../epics/EPIC-002.md) — Confiabilidade Operacional

## QA obrigatório
Sim — QA manual: tentar submeter o passo 1 do onboarding com um CPF/CNPJ com dígito verificador
errado (ex.: `266.848.958-03`, usado no caso real do Ricardo Cerqueira) e confirmar que o formulário
bloqueia antes de chamar a API, com mensagem clara; testar também com CPF/CNPJ válidos reais pra
garantir que não há falso positivo.

---

## Contexto

Achado ao investigar o caso do Ricardo Cerqueira (25/08/2026): ele digitou um CPF com formato correto
(11 dígitos) mas dígito verificador inválido (`266.848.958-03` — o 1º dígito verificador bate, o 2º
não). O onboarding aceitou, e só a Asaas rejeitou (`invalid_object`), silenciosamente, no meio do
fluxo de criação de conta — ver TASK-201 pra correção reativa desse caso específico.

Hoje `src/app/onboarding/page.tsx` só tem `maskCPF`/`maskCNPJ`/`maskCPFCNPJ` (formatação visual),
sem nenhuma validação de dígito verificador. Qualquer sequência de 11 (CPF) ou 14 (CNPJ) dígitos
passa pro backend.

## Objetivo

Bloquear no frontend, antes de submeter, CPF/CNPJ com dígito verificador inválido — tanto no campo
"CPF" do passo 1 (`billingData.doc`, pessoa física, obrigatório) quanto no campo "CNPJ/CPF" do passo
2 (`orgData.orgDoc`, opcional).

## Escopo

`src/app/onboarding/page.tsx`:

- Duas funções novas de validação (algoritmo padrão de dígito verificador, mod 11):
  `isValidCPF(digits: string): boolean` e `isValidCNPJ(digits: string): boolean`. Incluir também a
  checagem de sequências repetidas (`00000000000`, `11111111111`, etc.) — matematicamente "válidas"
  pelo dígito verificador mas nunca são CPFs reais.
- `handleStep1`: antes do `api.post`, validar `onlyNumbers(billingData.doc)` com `isValidCPF`. Se
  inválido, `setFieldErrors({ doc: "CPF inválido — confira os dígitos" })` e não submeter (mesmo
  padrão de erro já usado pros outros campos, `fieldErrors.doc` já é lido pelo JSX existente).
- `handleStep2`: mesma validação em `orgData.orgDoc` quando preenchido (campo é opcional — só valida
  se não estiver vazio), usando `isValidCPF` ou `isValidCNPJ` conforme o tamanho (11 ou 14 dígitos,
  mesmo critério que `maskCPFCNPJ` já usa pra decidir a máscara).

## Critérios de Aceite

- [ ] CPF com dígito verificador inválido bloqueia o submit do passo 1, com mensagem em `fieldErrors.doc`
- [ ] CNPJ/CPF com dígito verificador inválido bloqueia o submit do passo 2 (quando preenchido)
- [ ] Sequências repetidas (`11111111111` etc.) são tratadas como inválidas
- [ ] CPF/CNPJ reais e válidos continuam passando sem falso positivo
- [ ] `npm run build` sem regressão

## Fora de Escopo

- Validação equivalente no backend — coberta separadamente em TASK-203 (defesa em profundidade,
  já que a API pode ser chamada fora do formulário).
- Validação de CPF/CNPJ em outras telas do sistema (edição de fornecedor, cadastro de item etc.) —
  fora do escopo, focar no onboarding que foi onde o problema real aconteceu.

## Dependências
Nenhuma.

## Riscos
Baixo — validação client-side aditiva, não muda contrato com o backend.

## Esforço
Baixo

## Status
🟡 Em validação — testada localmente pelo Douglas (`TASK-QA-MAN-014`), PR web#53 aberta contra
`staging`. `isValidCPF`/`isValidCNPJ` (mod 11 + rejeição de sequências repetidas) bloqueando
`handleStep1` (CPF obrigatório) e `handleStep2` (CNPJ/CPF opcional). `npm run build` limpo.
