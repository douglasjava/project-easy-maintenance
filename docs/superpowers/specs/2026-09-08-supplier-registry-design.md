# EPIC-028 — Cadastro de Fornecedores pelos Usuários + Pontuação

**Data:** 08/09/2026
**Status:** Aprovado por Douglas (brainstorm conduzido nesta data)

## Motivação

Ideia registrada em 07/09/2026 (macro, sem desenho): o [EPIC-023](../../../roadmap/epics/EPIC-023.md)
(completo, em `main`) só sugere fornecedores via Google Places — dado externo, sem histórico real
de uso. A ideia é deixar os próprios clientes cadastrarem fornecedores que já usam e confiam,
construindo um registro com sinal de confiança real (quantas organizações usam o mesmo fornecedor),
que pode ser indicado pra outras organizações próximas geograficamente.

**Ponto estratégico explícito do Douglas**: esse épico é um case futuro de monetização — não
decidido como vira dinheiro ainda, mas o desenho não pode fechar essa porta (ver princípio de
desenho ao final).

## Contexto (levantado antes do desenho)

- Módulo `supplier` já existe (`com.brainbyte.easy_maintenance.supplier`), usado por
  `SupplierLookupService` (busca cacheada pra notificação, EPIC-023) e `SupplierSearchService`
  (busca interativa na tela de criar manutenção) — hoje **sem entidade persistida**, ambos operam
  sobre DTOs vindos da API do Google Places. Este épico introduz a primeira entidade persistida
  desse módulo.
- `SupplierCategoryKeywords` (usado pelo EPIC-023 pra mapear `item_type` → categoria de busca) é
  reaproveitado como taxonomia de categoria do fornecedor cadastrado — mantém vocabulário
  consistente entre os dois fluxos, mesmo eles ficando operacionalmente separados por ora.
- Diferente do EPIC-027, este épico **não tem superfície pública** — todo mundo que interage já é
  usuário autenticado da organização (`X-Org-Id`), então não precisa de `RateLimiterService` nem de
  modelagem de acesso sem senha.
- Todo o resto do sistema aplica isolamento multi-tenant estrito (organização nunca vê dado de
  outra). Este épico introduz, deliberadamente, a primeira exceção: uma entidade **compartilhada**
  entre organizações — decisão de produto explícita, não descuido de arquitetura.

## Decisões de escopo (brainstorm, 08/09/2026)

1. **O que a organização B vê do fornecedor da organização A**: só dado público do fornecedor
   (nome, categoria, telefone/contato — o tipo de dado que já vem do Google Places hoje). Nunca
   expõe quem cadastrou, nota ou histórico privado de outra organização.
2. **Pontuação é atributo do fornecedor, não de quem indicou** — contagem de quantas organizações
   distintas já cadastraram/vincularam aquele fornecedor. Sinal de confiança agregado e anônimo
   (decisão de Douglas: reputação é característica do fornecedor, independente de quem indicou).
3. **Deduplicação por CNPJ, obrigatório.** Identificador formal, único, sem ambiguidade — mesmo
   aceitando que fornecedor informal/autônomo sem CNPJ fica fora do cadastro compartilhado nesta
   v1.
4. **Proximidade por cidade/estado** — mesmo critério já usado no EPIC-023
   (`organization.city`/`state`), sem geocodificação/raio real. Fornecedor de manutenção predial
   geralmente atende a cidade toda, não um raio de metros — aproximação já é razoável.
5. **Pontuação alimentada só por contagem de vínculo** — sem avaliação explícita (nota/comentário)
   nesta v1. Cada organização que cadastra/vincula um fornecedor soma 1 na pontuação dele,
   independente de avaliação de qualidade.
6. **Separado do fluxo de notificação do EPIC-023 nesta v1.** EPIC-023 continua só com Google
   Places — misturar agora arriscaria mostrar fornecedor sem pontuação real (registro nasce vazio,
   "cold start") ou complicar o fallback de um fluxo que acabou de ser fechado e testado ponta a
   ponta. Integração vira episódio futuro, quando o registro já tiver dado real.
7. **Tela nova dedicada** (não integrada à busca interativa já existente na criação de
   manutenção) — mais simples de isolar, mesmo ficando desconectada do momento exato em que a
   pessoa precisa de um fornecedor. Pode conectar depois, junto da decisão do item 6.
8. **Reaproveita o módulo `supplier` existente** — arquivos novos dentro dele (entidade, serviço,
   controller, DTOs), sem modificar os arquivos do fluxo Google Places existente. Mantém coesão de
   domínio ("fornecedor" é um conceito só, com duas fontes de dado) sem duplicar o conceito num
   módulo paralelo.

---

## Arquitetura

### Modelo de dado

**`Supplier`** — entidade nova, **compartilhada** (sem coluna `organization_id`/`X-Org-Id` como
dono — é intencional, não uma falha de isolamento):

| Campo | Tipo | Observação |
|---|---|---|
| `id` | Long | PK |
| `cnpj` | String, único, obrigatório | Chave de deduplicação |
| `name` | String | — |
| `phone` | String | — |
| `category` | String/Enum | Mesma taxonomia de `SupplierCategoryKeywords` |
| `city` | String | Usado no filtro de proximidade |
| `state` | String | Usado no filtro de proximidade |
| `registrationCount` | Integer | A pontuação — nº de organizações distintas vinculadas |
| `createdAt`/`updatedAt` | Instant | Padrão já usado em todo o schema |

**`SupplierOrganizationLink`** — join entre `Supplier` e `Organization`:

| Campo | Tipo | Observação |
|---|---|---|
| `supplierId` | Long (FK) | — |
| `organizationId` | Long (FK) | — |
| `createdAt` | Instant | — |

Constraint única em `(supplierId, organizationId)` — impede a mesma organização contar mais de uma
vez na pontuação, e permite listar "fornecedores que a minha organização já cadastrou".

### Endpoints (autenticados — JWT + `X-Org-Id`, mesmo padrão do resto do sistema)

- `POST /suppliers` — corpo: `cnpj`, `name`, `phone`, `category`, `city`, `state`. Se já existe um
  `Supplier` com esse CNPJ: cria só o `SupplierOrganizationLink` (idempotente — se o vínculo já
  existir pra essa organização, não soma pontuação de novo) e **não sobrescreve** os dados já
  cadastrados (nome/telefone ficam com o primeiro cadastro — decisão simples pra v1, evita conflito
  de "qual organização está certa sobre o telefone do fornecedor"). Se não existe: cria `Supplier` +
  `SupplierOrganizationLink`.
- `GET /suppliers?city=&state=&category=` — lista fornecedores da região (mesmo `city`/`state` da
  organização do token, ou informado explicitamente), ordenado por `registrationCount` desc.

### Backend — dentro do módulo `supplier` existente

Arquivos novos, sem tocar nos existentes:
- `domain/Supplier.java`, `domain/SupplierOrganizationLink.java` — primeira entidade persistida do
  módulo.
- `application/service/SupplierRegistryService.java` — cadastro (dedup por CNPJ) + busca por
  região. Nome distinto de `SupplierLookupService`/`SupplierSearchService` (que continuam
  intocados, operando só sobre Google Places).
- `application/dto/` — `RegisterSupplierRequest`, `SupplierRegistryResponse`.
- `infrastructure/web/SupplierRegistryController.java` — os 2 endpoints, autenticados.
- `infrastructure/persistence/` — repositories JPA pras duas entidades novas.

### Frontend — tela nova dedicada

Nova rota (`/fornecedores` ou `/suppliers`, nome exato a definir na implementação) dentro do
layout autenticado normal: lista de fornecedores da região (filtrável por categoria) + formulário
de cadastro (CNPJ, nome, telefone, categoria — cidade/estado herdados da organização logada).

---

## Princípio de desenho pro futuro (não fechar a porta de monetização)

`Supplier` fica como entidade própria e extensível, não embutida/desnormalizada em outra tabela.
Campos futuros (ex.: `sponsored`/destaque pago, `verified`/selo de verificação, plano de fornecedor)
entram como colunas aditivas nessa mesma entidade, sem reestruturar o que for construído agora. A
decisão de **como** monetizar fica pra quando houver essa conversa — este desenho só garante que a
base de dado não precisa ser refeita quando isso acontecer.

## Fora de Escopo (v1)

- Integração com o fluxo de notificação do EPIC-023 (WhatsApp/e-mail) — fica separado.
- Avaliação explícita (nota/comentário) — pontuação é só contagem de vínculo.
- Raio geográfico real (lat/long) — fica em cidade/estado.
- Fornecedor sem CNPJ (informal/autônomo).
- Edição/atualização de dado de um fornecedor já cadastrado por outra organização.
- Qualquer mecanismo de monetização em si (destaque pago, cobrança por lead) — só a base de dado
  fica pronta pra isso, não a implementação.

## Riscos

- **Qualidade do dado**: fornecedor cadastrado manualmente por um cliente pode estar
  errado/desatualizado, e a v1 não sobrescreve dado já existente — sem esse cuidado, a confiança no
  registro cai rápido. Risco aceito conscientemente nesta v1 (sem avaliação/correção colaborativa
  ainda).
- **Cold start**: registro nasce vazio, pontuação só fica significativa depois de uso real — é
  exatamente por isso que a integração com o EPIC-023 fica pra depois (item 6 das decisões).
- Baixo risco pro restante do sistema — módulo já existente, arquivos novos aditivos, nenhum fluxo
  existente (`SupplierLookupService`/`SupplierSearchService`) é alterado.
