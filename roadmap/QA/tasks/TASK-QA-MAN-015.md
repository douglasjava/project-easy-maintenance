# TASK-QA-MAN-015 — QA Manual: Meta Conversions API (dedupe de Lead + sinal de qualidade)

## Tipo
QA Manual

## Categoria
Backend + Frontend / Marketing, Tracking

## Prioridade
🟡 Médio

## Épico
[EPIC-018](../../epics/EPIC-018.md) — Tracking de Conversão para Ads (UTM, Consentimento LGPD, Página de Obrigado)

## Tasks cobertas
[TASK-157](../../tasks/TASK-157.md) — Meta Conversions API: dedupe de `Lead` + eventos `LeadQualified`/`LeadConverted`

---

## Descrição

Valida a implementação do TASK-157: reenvio do evento `Lead` pelo backend (deduplicado com o Pixel
client-side) e envio de um sinal de qualidade (`LeadQualified`/`LeadConverted`) quando um lead muda
de status no admin. Dividida em duas partes:

- **Parte A (sem credenciais reais)** — valida que o código funciona em modo no-op: nada quebra,
  nenhuma chamada à Meta é feita, o lead/status é sempre salvo. É o que dá pra testar hoje.
- **Parte B (com credenciais reais)** — valida que o evento realmente chega na Meta e dedupe
  funciona. Só é executável depois que `META_CAPI_ACCESS_TOKEN`/`META_CAPI_DATASET_ID` existirem
  (ver seção "Como obter as credenciais" no TASK-157 ou na mensagem que acompanha este documento).

Toda a implementação está na branch `feature/TASK-157-meta-capi` nos dois repos. Sem PR aberta
ainda — testar local primeiro.

---

## Pré-condições

- Checkout da branch `feature/TASK-157-meta-capi` nos dois repos (`easy-maintenance-api` e
  `easy-maintenance-web`), rodando local (api + web apontando um pro outro).
- Acesso admin (`/private/admin/leads`) pra mudar status de lead.
- DevTools do navegador (aba Network e Console) pra conferir o payload enviado a
  `POST /landing/leads` e os cookies `em_lead_event_id`/`_fbp`/`_fbc`.
- Para C6/C7 (Parte B): as duas variáveis de ambiente reais configuradas no backend local
  (`META_CAPI_ACCESS_TOKEN`, `META_CAPI_DATASET_ID`) e acesso ao Events Manager da Meta (aba
  **Test Events** do dataset `Dados_EasyMaintenance_Web`).

---

## Cenários de Teste

### C1 — Suíte automatizada, sem regressão

| Passo | Ação                   | Resultado esperado                                                                                                                                                               |
|-------|------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | `mvn test` na api      | Todos os testes passam, incluindo `Sha256HasherTest`, `MetaCapiPayloadBuilderTest`, os novos casos de `LeadServiceTest`/`LeadAdminServiceTest`                                   |
| 2     | `npx jest` no web      | Todos passam, incluindo `metaCapi.test.ts` (novo) e os novos casos de `tracking.test.ts` — as 3 falhas de `middleware.test.ts` são pré-existentes na `staging`, não relacionadas |
| 3     | `npm run build` no web | Build limpo, sem erro de TypeScript                                                                                                                                              |

---

### C2 — Sem credenciais configuradas, lead continua sendo criado normalmente (no-op)

| Passo | Ação                                                                                                       | Resultado esperado                                                                                                                      |
|-------|------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Rodar a api local **sem** `META_CAPI_ACCESS_TOKEN`/`META_CAPI_DATASET_ID` no ambiente (estado padrão hoje) | Sobe normalmente                                                                                                                        |
| 2     | Abrir `/landing`, preencher e-mail, marcar consentimento, submeter                                         | Lead criado normalmente, redireciona pra `/obrigado`                                                                                    |
| 3     | Conferir o log do backend                                                                                  | Linha `[MetaCapi] Ignorando evento 'Lead' ... access token/dataset id não configurados` em nível `DEBUG` — nenhuma exceção, nenhum erro |
| 4     | `SELECT event_id, fbp, fbc FROM landing_leads ORDER BY id DESC LIMIT 1;`                                   | `event_id` preenchido (gerado no frontend); `fbp`/`fbc` normalmente nulos em ambiente local sem Pixel real carregado — esperado         |

---

### C3 — Frontend gera e propaga o `event_id` corretamente

| Passo | Ação                                                                              | Resultado esperado                                                               |
|-------|-----------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| 1     | Abrir `/landing` com DevTools → Network aberto, preencher e submeter o formulário | Requisição `POST /landing/leads` tem `eventId` no corpo (formato UUID)           |
| 2     | Conferir Application → Cookies do navegador logo após o submit, antes do redirect | Cookie `em_lead_event_id` presente, valor igual ao `eventId` enviado             |
| 3     | Aguardar o redirect para `/obrigado`                                              | Cookie `em_lead_event_id` **não existe mais** (foi consumido no mount da página) |

---

### C4 — Falha do cliente Meta não impede a criação do lead nem a mudança de status (best-effort)

| Passo | Ação                                                                                                                                                                                                | Resultado esperado                                                                                         |
|-------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|
| 1     | Configurar `META_CAPI_ACCESS_TOKEN=token-invalido-de-teste` e `META_CAPI_DATASET_ID=000000000000000` (valores inválidos, só pra forçar erro de rede/autenticação — nunca usar credencial real aqui) | —                                                                                                          |
| 2     | Repetir o submit do formulário em `/landing`                                                                                                                                                        | Lead criado normalmente, redireciona pra `/obrigado` normalmente — nenhuma diferença visível pro usuário   |
| 3     | Conferir o log do backend                                                                                                                                                                           | `WARN [MetaCapi] Falha ao enviar evento 'Lead' para o lead <id>: ...` — sem stacktrace assustador, sem 500 |
| 4     | No admin (`/private/admin/leads`), mudar o status desse lead pra "Contatado"                                                                                                                        | Status muda normalmente na tela; mesmo padrão de log de falha aparece no backend                           |

---

### C5 — Admin: mudança de status dispara o evento certo (verificável via log/mensagem, sem credencial real)

| Passo | Ação                                                                                                                            | Resultado esperado                                                          |
|-------|---------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| 1     | Sem credenciais configuradas (estado padrão), criar um lead de teste e mudar o status pra "Contatado" em `/private/admin/leads` | Log `DEBUG` menciona o evento `LeadQualified` sendo ignorado (no-op)        |
| 2     | Mudar o mesmo lead pra "Convertido"                                                                                             | Log `DEBUG` menciona `LeadConverted`                                        |
| 3     | Criar outro lead e mudar direto pra "Perdido" (`LOST`)                                                                          | **Nenhuma** linha de log de Meta CAPI aparece — não há evento para NEW/LOST |

---

### C6 — Parte B: evento chega de verdade na Meta (requer credenciais reais)

**Só executar depois que `META_CAPI_ACCESS_TOKEN`/`META_CAPI_DATASET_ID` reais estiverem configurados
localmente — ver seção "Como obter as credenciais" logo abaixo, no TASK-157.**

| Passo | Ação                                                                                             | Resultado esperado                                                                                                                       |
|-------|--------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Configurar as credenciais reais no ambiente local da api, reiniciar                              | Sobe sem erro                                                                                                                            |
| 2     | Abrir Events Manager → dataset `Dados_EasyMaintenance_Web` → aba **Test Events**, deixar aberta  | —                                                                                                                                        |
| 3     | Submeter o formulário em `/landing` com um e-mail de teste                                       | Evento `Lead` aparece em Test Events com origem "Servidor" (Conversions API), `event_id` visível                                         |
| 4     | Se o Pixel client-side também estiver ativo localmente (`NEXT_PUBLIC_META_PIXEL_ID` configurado) | O evento `Lead` do navegador e o do servidor aparecem **deduplicados** (badge "Deduplicado" no Test Events, não duas entradas separadas) |
| 5     | No admin, mudar o lead de teste pra "Contatado"                                                  | Evento `LeadQualified` aparece em Test Events, origem "Servidor"                                                                         |
| 6     | Mudar pra "Convertido"                                                                           | Evento `LeadConverted` aparece, sem `value`/`currency` (esperado, ver decisão documentada no TASK-157)                                   |

---

### C7 — Parte B: qualidade do match (fbp/fbc/email/telefone hasheados)

| Passo | Ação                                                                                     | Resultado esperado                                                                                                                                                       |
|-------|------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | No evento `Lead` recebido em Test Events (C6), abrir os detalhes do evento               | Parâmetros `em` (e-mail hasheado) e, se telefone informado, `ph` aparecem — nunca o valor em texto plano                                                                 |
| 2     | Conferir a pontuação de qualidade de correspondência ("Match Quality") exibida pela Meta | Score razoável (a Meta não garante 100%, mas deve refletir os campos enviados: IP, user-agent, e possivelmente fbp/fbc se o Pixel já tinha rodado nesse navegador antes) |

---

## Critérios de Aceite da Suite

- [X] C1: suíte automatizada (backend + frontend) sem regressão
- [X] C2: sem credenciais, lead é criado normalmente, log de no-op em `DEBUG`
- [X] C3: `event_id` gerado no frontend, propagado no payload e no cookie, consumido corretamente em `/obrigado`
- [X] C4: falha do cliente Meta (credencial inválida) não impede criação de lead nem mudança de status
- [X] C5: no-op de `LeadQualified`/`LeadConverted` logado corretamente; nenhum evento para `NEW`/`LOST`
- [X] C6 (Parte B, requer credenciais reais): eventos `Lead`/`LeadQualified`/`LeadConverted` aparecem no Test Events; dedupe funciona com o Pixel client-side
- [X] C7 (Parte B, requer credenciais reais): dados hasheados, nunca em texto plano

---

## Status
Todos os 7 cenários validados localmente por Douglas (26/08/2026), incluindo C6/C7 com credenciais
reais (`META_CAPI_ACCESS_TOKEN`/`META_CAPI_DATASET_ID` configuradas e eventos confirmados no Test
Events da Meta, com dedupe funcionando). Aprovado — pronto para PR contra `staging`.
