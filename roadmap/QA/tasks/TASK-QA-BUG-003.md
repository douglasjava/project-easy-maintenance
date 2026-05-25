# TASK-QA-BUG-003 — Bug: Criação de organização via admin falha com 422 — campo companyType nulo

## Tipo
BUG

## Categoria
Full-Stack / Admin / Organizations

## Prioridade
🟠 Alto — Bloqueia criação de organizações pela área privada do SaaS

## Épico
EPIC-006 — Produto SaaS

## Módulos Impactados
- Frontend: formulário `/private/organizations/new` — campo `companyType` não está sendo enviado no payload
- Backend: endpoint `POST /easy-maintenance/api/v1/private/admin/organizations` — validação `@NotNull` em `companyType`

## Severidade
**ALTA** — Funcionalidade de criação de organização completamente inoperante na área privada de administração

---

## Descrição do Bug

Ao tentar criar uma nova organização via a tela `/private/organizations/new`, a requisição retorna HTTP **422 Unprocessable Entity** com a seguinte resposta:

```json
{
  "type": "https://easy-maintenance/api/problems/validation-error",
  "title": "Validation error",
  "status": 422,
  "detail": "One or more fields are invalid",
  "instance": "/easy-maintenance/api/v1/private/admin/organizations",
  "properties": {
    "method": "POST",
    "timestamp": "2026-05-25T16:10:11.532681248Z",
    "requestId": "a7d8a011-a0ca-494d-a209-ce31f058bdc9",
    "violations": [
      {
        "field": "companyType",
        "message": "não deve ser nulo"
      }
    ]
  }
}
```

O campo `companyType` está chegando como `null` no backend, indicando que o formulário não está enviando este campo.

---

## Passos para Reproduzir

1. Acessar `/private/organizations/new` como admin
2. Preencher todos os campos visíveis do formulário
3. Submeter o formulário
4. Observar: erro 422 retornado — `companyType` nulo

---

## Comportamento Atual (Errado)

- O campo `companyType` não é enviado no payload da requisição `POST`
- O backend rejeita a requisição com 422
- A organização **não é criada**

---

## Comportamento Esperado

- O campo `companyType` deve ser selecionado/enviado corretamente no formulário
- A organização é criada com sucesso e o admin é redirecionado para a listagem

---

## Hipótese de Root Cause

Duas hipóteses, em ordem de probabilidade:

1. **Campo ausente no formulário**: o input de `companyType` não existe ou não está renderizado na página `/private/organizations/new` — o valor nunca é coletado do usuário
2. **Mapeamento incorreto no payload**: o campo existe no formulário mas o nome/chave enviado na requisição não corresponde ao esperado pelo backend (`companyType`)

A migração **V36** adicionou o campo `company_type` à tabela `organizations`, sugerindo que este campo pode ter sido adicionado ao backend posteriormente sem o formulário admin ter sido atualizado.

---

## Critérios de Aceite

- [ ] Formulário `/private/organizations/new` exibe campo `companyType` com opções válidas
- [ ] O campo é obrigatório e exibe validação visual se não preenchido antes de submeter
- [ ] Requisição `POST` inclui `companyType` no payload com o valor selecionado
- [ ] Organização é criada com sucesso (HTTP 201)
- [ ] Admin é redirecionado para a listagem de organizações após criação

---

## Arquivos a Investigar

**Frontend:**
- `src/app/private/organizations/new/page.tsx` (ou equivalente) — verificar se campo `companyType` existe
- Tipo/interface do payload de criação de organização

**Backend:**
- DTO de criação de organização — confirmar campo `companyType` e constraint `@NotNull`
- Entidade `Organization` — ver valores aceitos pelo enum `companyType`

---

## Relacionado a

- V36 (`V36__add_company_type_organization.sql`) — migração que adicionou o campo
- EPIC-006 — Produto SaaS

## Status
🔴 Aberto — Aguardando correção (25/05/2026)
