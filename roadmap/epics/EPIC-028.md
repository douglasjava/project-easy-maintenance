# EPIC-028 — Cadastro de Fornecedores pelos Usuários + Pontuação

## Status
Desenhado via brainstorm com Douglas (08/09/2026), pronto para implementar. Spec em
`docs/superpowers/specs/2026-09-08-supplier-registry-design.md`. Ideia original registrada em
07/09/2026 (macro, sem desenho).

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
