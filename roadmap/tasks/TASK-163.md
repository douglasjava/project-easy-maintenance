# TASK-163 — Backend: `LandingLead.status` de `String` livre pra enum `LeadStatus`

## Tipo
BACKEND

## Categoria
Admin / Leads

## Prioridade
🟠 Alto

## Épico
[EPIC-021](../epics/EPIC-021.md) — Painel de Leads (visão agregada + mini-CRM de status)

## QA obrigatório
Sim — validar que leads existentes (todos `"NEW"`) continuam legíveis depois da migração, e que
`LeadService.createLead` continua funcionando sem alteração de comportamento.

---

## Contexto

`LandingLead.status` é hoje uma `String` livre, sempre `"NEW"` (não existe nenhum código que grava
outro valor). O painel de leads precisa de um status de verdade — `NEW`, `CONTACTED`,
`CONVERTED`, `LOST` — validado, não texto livre.

---

## Objetivo

Converter o campo pra `@Enumerated(EnumType.STRING)`, sem quebrar o fluxo de criação existente.

---

## Escopo

### 1. Enum
- `leads/domain/enums/LeadStatus.java`: `NEW, CONTACTED, CONVERTED, LOST` (mesmo padrão bare enum
  de `BillingStatus`/`ExpenseCategory`).

### 2. Entidade
- `LandingLead.status`: troca de `private String status = "NEW"` pra
  `@Enumerated(EnumType.STRING) @Builder.Default private LeadStatus status = LeadStatus.NEW`.

### 3. Migração
- Coluna já é `VARCHAR` compatível com os nomes do enum (`"NEW"` já é um valor válido) — migração
  é só documentacional/sem transformação de dado (ex.: garantir tamanho de coluna suficiente pro
  maior nome do enum, `CONVERTED` tem 9 caracteres, se a coluna atual for menor que isso precisa
  de `ALTER TABLE`).

### 4. Ajustes decorrentes
- `LeadService.createLead`: `.status(LeadStatus.NEW)` no lugar do literal `"NEW"`.
- `LeadResponse` (DTO): campo `status` passa a ser `LeadStatus` em vez de `String` (serializa como
  string da mesma forma, sem quebrar o contrato JSON pro frontend da landing que já consome esse
  response).

### 5. Testes
- `LeadServiceTest` (já existe) continua passando sem alteração de asserts (o valor serializado
  continua `"NEW"`).
- Teste novo garantindo que a coluna aceita todos os 4 valores do enum.

---

## Critérios de Aceite

- [ ] `LandingLead.status` é `LeadStatus`, não `String`
- [ ] Leads criados continuam com status `NEW` por padrão
- [ ] `LeadServiceTest` existente passa sem alteração de comportamento
- [ ] Suíte completa do backend sem regressão

## Dependências
Nenhuma.

## Riscos
Baixo — todo dado existente já é `"NEW"`, um valor válido do enum; não há transformação de dado
arriscada.

## Esforço
Baixo

## Status
Pronto para Implementar
