# EPIC-028 — Cadastro de Fornecedores pelos Usuários + Pontuação

## Status
Desenhado via brainstorm com Douglas (08/09/2026), pronto para implementar. Spec em
`docs/superpowers/specs/2026-09-08-supplier-registry-design.md`. Ideia original registrada em
07/09/2026 (macro, sem desenho).

**09/09/2026 — TASK-241/242/243 implementadas e testadas** numa branch única
`feature/EPIC-028-supplier-registry` (decisão do Douglas de consolidar o épico, em vez de uma
branch/PR por task): entidades + migration (backend, `mvn test` 949/949), endpoints com dedup por
CNPJ + busca por região (backend), tela dedicada `/fornecedores` (frontend, `npm run build`/`npm
test` sem regressão). Aguardando [TASK-QA-MAN-020](../QA/tasks/TASK-QA-MAN-020.md) — QA manual
ponta a ponta — antes de abrir as PRs pra `staging`.

## Objetivo
Permitir que organizações clientes cadastrem fornecedores por conta própria, construindo um
registro com sinal de confiança real (quantas organizações usam o mesmo fornecedor) — hoje o
[EPIC-023](EPIC-023.md) só sugere fornecedores via Google Places, dado externo sem histórico real
de uso.

## ⚠️ Ponto estratégico explícito do Douglas
Esse épico **não abre mão do case futuro de capitalizar por essa porta**. `Supplier` fica como
entidade própria e extensível (não embutida/desnormalizada em outra tabela) — campos futuros
(destaque pago, selo de verificação, plano de fornecedor) entram como colunas aditivas, sem
reestruturar o que for construído agora. Como monetizar fica pra uma conversa futura; este desenho
só garante que a base de dado não precisa ser refeita quando isso acontecer.

## Descrição

`Supplier` é uma entidade **compartilhada entre organizações** (exceção deliberada ao isolamento
multi-tenant estrito do resto do produto) — deduplicada por **CNPJ obrigatório**. Quando uma
organização cadastra um fornecedor cujo CNPJ já existe, só cria um vínculo
(`SupplierOrganizationLink`) e soma na pontuação; não duplica nem sobrescreve o registro existente.

**Pontuação = contagem de organizações distintas vinculadas** (sem avaliação explícita nesta v1) —
atributo do fornecedor em si, nunca expõe quem indicou. Organização B só vê dado público do
fornecedor (nome, categoria, telefone) + a pontuação agregada, nunca histórico/nota privada de
outra organização.

**Proximidade por cidade/estado** — mesmo critério já usado no EPIC-023, sem geocodificação.

**Decisão importante**: v1 fica **separada** do fluxo de notificação do EPIC-023 (WhatsApp/e-mail
continuam só com Google Places) — o registro nasce vazio ("cold start"), integrar agora arriscaria
mexer num fluxo que acabou de ser fechado e testado ponta a ponta. Tela nova dedicada (não
integrada à busca interativa já existente na criação de manutenção).

---

## Contexto Técnico

- Módulo `supplier` já existe (`com.brainbyte.easy_maintenance.supplier`), hoje sem entidade
  persistida — `SupplierLookupService`/`SupplierSearchService` operam só sobre DTOs do Google
  Places. Este épico introduz a primeira entidade persistida do módulo, em arquivos novos, sem
  tocar nos existentes.
- `SupplierCategoryKeywords` (taxonomia já usada pelo EPIC-023) é reaproveitado como categoria do
  fornecedor cadastrado.
- Sem superfície pública — diferente do [EPIC-027](EPIC-027.md), tudo aqui é autenticado
  (`X-Org-Id`), sem necessidade de rate limiting/modelagem de acesso sem senha.

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-241](../tasks/TASK-241.md) | Backend: entidades `Supplier`/`SupplierOrganizationLink` + migration | BACKEND | 🟡 Médio |
| [TASK-242](../tasks/TASK-242.md) | Backend: endpoints `POST`/`GET /suppliers` (cadastro com dedup por CNPJ + busca por região) | BACKEND | 🟡 Médio |
| [TASK-243](../tasks/TASK-243.md) | Frontend: tela dedicada de fornecedores (lista + filtro + cadastro) | FRONTEND | 🟡 Médio |

Ordem: TASK-241 primeiro (entidade base). TASK-242 depende dela. TASK-243 depende da TASK-242
(precisa dos endpoints prontos pra integrar).

---

## Critério de Conclusão do Épico

- [ ] Organização cadastra um fornecedor novo (CNPJ inédito) — cria `Supplier` + vínculo
- [ ] Organização cadastra um fornecedor com CNPJ já existente — só vincula, soma pontuação, não
      duplica nem sobrescreve dado
- [ ] Busca por região (`city`/`state`) retorna fornecedores ordenados por pontuação
- [ ] Organização B nunca vê quem cadastrou/vinculou um fornecedor — só dado público + pontuação
      agregada
- [ ] Tela dedicada funcional (lista + filtro por categoria + formulário de cadastro)
- [ ] `SupplierLookupService`/`SupplierSearchService` (fluxo Google Places) permanecem intocados
- [ ] `mvn test`/`npm run build` sem regressão

---

## Fora de Escopo

- Integração com o fluxo de notificação do EPIC-023 (WhatsApp/e-mail).
- Avaliação explícita (nota/comentário) — pontuação é só contagem de vínculo.
- Raio geográfico real (lat/long) — fica em cidade/estado.
- Fornecedor sem CNPJ (informal/autônomo).
- Edição/atualização de dado de um fornecedor já cadastrado por outra organização.
- Qualquer mecanismo de monetização em si (só a base de dado fica pronta pra isso).

## Riscos
Qualidade do dado (fornecedor cadastrado manualmente pode estar errado/desatualizado, v1 não
sobrescreve) — risco aceito conscientemente. Cold start (registro nasce vazio, pontuação só fica
significativa depois de uso real — por isso a integração com EPIC-023 fica pra depois). Baixo risco
pro restante do sistema — módulo já existente, arquivos novos aditivos, nenhum fluxo existente é
alterado.

---

## Ideias Futuras (registradas sem brainstorm, 22/09/2026)

Levantadas durante o QA do Pix Automático (Fase 2, TASK-278). Nenhuma das duas foi desenhada ainda —
registro pra não perder, não é compromisso de próxima sprint.

- **[TASK-279](../tasks/TASK-279.md) — Busca de fornecedor por raio geográfico real (lat/long)**,
  não mais match literal de `city`/`state`. Hoje `SupplierRepository.findByRegionVisibleTo` exige
  `city`/`state` idênticos — um fornecedor de "São Paulo/SP" não aparece pra organização de
  "Guarulhos/SP" mesmo sendo vizinhas. Já era um item de "Fora de Escopo" explícito desde o design
  original (acima) — fica pior em regiões metropolitanas fragmentadas em muitos municípios
  pequenos. Precisaria de geocodificação (lat/long no cadastro) + cálculo de distância na query.

- **[TASK-280](../tasks/TASK-280.md) — Fornecedor consegue ver os orçamentos solicitados a ele.**
  `supplier_budget_requests` (TASK-263, "Solicitar Orçamento") já grava cada pedido
  (`supplierId`/`organizationCode`/`summary`/`createdAt`) desde a Fase 2 — mas nada lê essa tabela
  de volta hoje (`SupplierBudgetRequestRepository` não tem nenhum finder além do CRUD padrão, sem
  controller/endpoint de listagem). Dado que já é coletado e pago (R$15,99/mês) sem entregar valor
  nenhum de volta pro fornecedor — exibir a lista na tela `/fornecedores/gerenciar/[token]` (já
  existe, sem login) é ganho direto de percepção de valor pro assinante, achado relevante dado o
  motivo original do Pix Automático (reduzir churn/atrito do fornecedor pagante).

## Divulgação para fornecedores (brainstorm 24/09/2026)

Pedido do Douglas em duas partes, tratadas como subprojetos separados:

- **[TASK-285](../tasks/TASK-285.md) — Página pública `/para-fornecedores`** (subprojeto A):
  divulgação + preço + políticas claras + FAQ, 100% frontend. Spec aprovado em
  `docs/superpowers/specs/2026-09-24-pagina-para-fornecedores-design.md`. Decisões: cancelamento a
  qualquer momento sem multa, zero comissão, sem garantia de volume de pedidos, nenhuma prova
  social numérica.
- **[TASK-280](../tasks/TASK-280.md) — kanban de pedidos de orçamento do fornecedor** (subprojeto
  B): brainstorm próprio depois da TASK-285.
- Backlog gerado no brainstorm: **[TASK-286](../tasks/TASK-286.md)** (manter visível até o fim do
  período pago após cancelar — hoje sai na hora) e **[TASK-287](../tasks/TASK-287.md)** (gravar
  UTM no cadastro de fornecedor).
- **24/09/2026 — TASK-285 implementada**, PR [web#94](https://github.com/douglasjava/easy-maintenance-web/pull/94)
  (`staging`). Revisão final achou gap de backend: fornecedor com débito falho nunca vira `PAST_DUE`
  e nunca é suspenso → **[TASK-288](../tasks/TASK-288.md)** (🟠 Alto).
- **24/09/2026 — TASK-280 implementada** (kanban de pedidos do fornecedor, subprojeto B): PRs
  [api#116](https://github.com/douglasjava/easy-maintenance-api/pull/116) e
  [web#95](https://github.com/douglasjava/easy-maintenance-web/pull/95) contra `staging`.
- **24/09/2026 — TASK-288 implementada** (fornecedor com débito falho agora é suspenso após 3 dias de
  tolerância e reativado ao pagar): PRs [api#117](https://github.com/douglasjava/easy-maintenance-api/pull/117)
  e [web#96](https://github.com/douglasjava/easy-maintenance-web/pull/96) contra `staging`.
