# TASK-200 — Full-stack: campo de descrição livre no registro de manutenção

## Tipo
FULL_STACK

## Categoria
Core / Manutenções

## Prioridade
🟠 Alto

## Épico
Nenhum — melhoria pontual num fluxo central já existente (registro de manutenção). Os candidatos
mais próximos (EPIC-006 "Produto SaaS", EPIC-016 "Cancelamento de Manutenções") não são o lugar
certo: EPIC-016 está concluído e é sobre correção/cancelamento, não sobre enriquecer o registro
original. Sem épico específico é melhor do que forçar um encaixe.

## QA obrigatório
Sim — QA manual: registrar uma manutenção com descrição preenchida, confirmar que aparece no
histórico do item e na lista de manutenções; registrar uma sem descrição, confirmar que não quebra
nada (campo opcional).

---

## Contexto

Achado por Douglas (25/08/2026): a tela de registrar manutenção não tem campo de descrição livre —
confirmado no código, não existe em lugar nenhum (nem na entidade `Maintenance`, nem no
`RegisterMaintenanceRequest`). Hoje uma manutenção registra só: item, data, tipo (preventiva/
corretiva/inspeção/teste/emergencial), responsável, custo e próxima data — nada sobre **o que** foi
feito de verdade.

Isso é uma lacuna real, não só estética: o argumento de venda nº 1 documentado em
`docs/produto/contexto-comercial.md` é *"A ABNT exige, você comprova"* — um registro com só
data+tipo+custo não é comprovação de manutenção, é só um lançamento financeiro. Motivador imediato:
Douglas conseguiu um cliente para validar em trial e quer isso disponível o quanto antes.

## Objetivo

Campo de descrição livre (texto), opcional, no registro de manutenção — capturado na tela, salvo no
banco, exibido no histórico do item e na lista de manutenções.

## Escopo

### 1. Backend — `easy-maintenance-api`

**Migration** (próximo número livre em `db/migration/`, confirmar contra o estado real da pasta):
```sql
ALTER TABLE maintenances ADD COLUMN description VARCHAR(1000) NULL;
```
Limite de 1000 caracteres — descrição do que foi feito, não um relatório longo (isso já existe via
anexo de relatório/PDF).

**`Maintenance.java`** (entidade): novo campo
```java
@Column(name = "description", length = 1000)
private String description;
```

**`RegisterMaintenanceRequest.java`**: novo campo opcional
```java
@Schema(description = "Descrição do que foi feito na manutenção", example = "Trocado filtro de óleo e verificado nível de combustível do gerador")
@Size(max = 1000)
String description
```

**`MaintenanceResponse.java`**: novo campo `description` na resposta (atenção ao construtor
compacto extra já existente na classe — atualizar ou remover se ficar redundante com o principal).

**`IMaintenanceMapper.java`** / `MaintenanceService.register(...)`: mapear o campo novo (mesmo
padrão dos campos opcionais já existentes como `performedBy`/`costCents` — sem validação de negócio
especial, só passagem direta).

### 2. Frontend — `easy-maintenance-web`

**`src/app/maintenances/new/page.tsx`**: novo campo no "Passo 1 — Dados da manutenção" (mesmo card
dos outros campos), `<textarea>` full-width (`col-12`), label "Descrição (opcional)", placeholder
"O que foi feito? Ex.: trocado filtro de óleo do gerador" — entra no `body` do `onSubmit` junto dos
demais campos opcionais (`description: description || null`).

**`src/components/maintenances/maintenanceDisplay.tsx`**: exibir a descrição (quando preenchida) no
card/linha de exibição de uma manutenção — componente já compartilhado entre histórico do item
(`items/[id]/page.tsx`) e lista de manutenções (`maintenances/page.tsx`), então um ajuste nesse
componente cobre os dois lugares.

### 3. Testes

- Backend: teste de serviço cobrindo registro com descrição preenchida e sem descrição (null),
  confirmando persistência e retorno no response.
- Frontend: `npm run build` limpo; QA manual (ver acima).

## Critérios de Aceite

- [x] Campo `description` existe em `maintenances`, nullable, até 1000 caracteres (V96)
- [x] Tela de registro tem campo de descrição, opcional, sem quebrar o fluxo quando vazio
- [x] Descrição aparece no histórico do item (ícone indicador com tooltip) e na lista de
      manutenções (texto completo no modal "Ver detalhes") quando preenchida
- [x] `mvn test` (800/800) e `npm run build` sem regressão

## Fora de Escopo

- Exibir a descrição no PDF de Prestação de Contas (`PrestacaoContasPdfDocument.tsx`) — avaliar
  depois se fizer sentido, não faz parte desta task pra manter o escopo pequeno como pedido.
- Descrição obrigatória — fica opcional, como os demais campos livres do formulário
  (`performedBy`/custo), pra não travar quem só quer lançar rápido.
- Edição de descrição depois de registrada — segue a mesma regra já estabelecida na EPIC-016
  (correção é via cancelamento + recadastro, não edição direta).

## Dependências
Nenhuma.

## Riscos
Baixo — coluna aditiva nullable, campo opcional em request/response já existentes, sem mudança de
contrato pra quem já consome a API sem esse campo.

## Esforço
Baixo

## Status
🟡 Em validação — implementado em `feature/TASK-200-maintenance-description` nos dois repos,
aguardando teste manual do Douglas antes de abrir PR (pedido explícito: "pode implementar criar
uma branch nova depois de pronto vou testar localmente").

- api: `5f162c7` — migration V96, entidade/DTO/mapper/service, 2 testes novos (800/800 passando)
- web: `ad9e034` — textarea no registro (Passo 1), exibição no modal de detalhes de
  `/maintenances`, ícone indicador no histórico do item (`items/[id]`)
