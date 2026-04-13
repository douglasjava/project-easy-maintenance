# Design: Tratamento de Erro Claro no Onboarding (TASK-016)

**Data:** 2026-04-09
**Status:** Aprovado
**Épico:** EPIC-006 — Produto SaaS
**Prioridade:** 🟠 Alto

---

## Problema

O fluxo de onboarding exibe erros genéricos ou silenciosos (ex: `console.error`, toast "Erro ao salvar dados de faturamento.") sem orientar o usuário sobre o que corrigir. Isso causa abandono — o lead que não conclui o onboarding nunca vira cliente.

---

## Objetivo

- Erros de validação de campo exibem mensagem específica diretamente abaixo do campo
- Falha do Asaas não bloqueia o trial — usuário pode pular pagamento e configurar depois
- Erros de rede mostram botão "Tentar novamente"
- Nenhum `console.error` exposto em produção
- Loading state durante operações assíncronas

---

## Decisões de Design

| Decisão | Escolha | Motivo |
|---|---|---|
| Arquitetura de erro | Utilitário centralizado (`errorMapper.ts`) | Evita duplicação sem reescrever componentes |
| Exibição de erros de campo | Inline abaixo do campo (Bootstrap `is-invalid`) | Sem redundância com toast |
| Fallback do Asaas | Tratado no backend (`OnboardingService`) — Asaas não-bloqueante | Frontend retorna sucesso mesmo com Asaas indisponível; sem lógica especial no frontend |
| Testes | Unitários do `errorMapper.ts` + validação manual | Sem estrutura de testes de componente no projeto |

---

## Arquitetura

### `src/lib/errorMapper.ts` (novo)

Função pura que transforma a resposta de erro da API (ProblemDetail RFC 7807) em estrutura pronta para o componente usar.

**Entrada:**
```ts
interface ApiError {
  type: string;       // ex: "https://easy-maintenance/api/problems/validation-error"
  status: number;
  detail: string;
  violations?: { field: string; message: string }[];
}
```

**Saída:**
```ts
interface MappedError {
  global: string | null;          // mensagem geral (toast ou banner)
  fields: Record<string, string>; // campo → mensagem inline
  retryable: boolean;             // exibir botão "Tentar novamente"?
}
```

**Mapeamento de ProblemType → comportamento:**

| ProblemType | `global` | `retryable` |
|---|---|---|
| `validation-error` | null (usa `fields`) | false |
| `conflict` | "Este dado já está cadastrado." | false |
| `service-unavailable` | "Serviço temporariamente indisponível. Tente novamente em alguns minutos." | true |
| `rate-limit-exceeded` | "Muitas tentativas. Aguarde e tente novamente." | true |
| `unexpected` | "Erro inesperado. Tente novamente." | true |
| network error (sem response) | "Sem conexão. Verifique sua internet e tente novamente." | true |

> **Nota:** `asaasFallback` foi removido do `MappedError`. Com a mudança no `OnboardingService`, falhas do Asaas em `createUser()` são tratadas internamente no backend — o endpoint retorna 200 mesmo com Asaas indisponível. O frontend não precisa de lógica especial para esse caso.

**Mapeamento de `violations[].field` → mensagem PT:**

| field | mensagem |
|---|---|
| `doc` | "CPF ou CNPJ inválido. Verifique os dígitos." |
| `billingEmail` | "E-mail de cobrança inválido." |
| `name` | "Nome é obrigatório." |
| `code` | "Nome da organização já está em uso. Escolha outro." |
| `zipCode` | "CEP inválido. Informe 8 dígitos." |
| *(qualquer outro)* | mensagem original do backend (fallback) |

---

## Componentes Alterados

### `src/app/onboarding/page.tsx`

**Estado adicionado:**
```ts
const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
const [loading, setLoading] = useState(false);
```

**Fluxo de erro no `handleSaveStep1`:**
1. `setFieldErrors({})` — limpa erros da tentativa anterior
2. `setLoading(true)` — botão desabilita, spinner aparece
3. `try`: POST `/me/onboarding/user`
4. `catch`: `errorMapper(error)` →
   - `fields` não vazio → `setFieldErrors(fields)`, campos ficam com `is-invalid` + texto abaixo
   - `global` presente → `toast.error(global)` (inclui `retryable` se aplicável)
5. `finally`: `setLoading(false)`

> Falha do Asaas é tratada no backend — o frontend não precisa de estado especial para esse caso.

**Renderização de campo com erro (padrão Bootstrap):**
```tsx
<input
  className={`form-control ${fieldErrors.doc ? 'is-invalid' : ''}`}
  value={doc}
  onChange={...}
/>
{fieldErrors.doc && (
  <div className="invalid-feedback">{fieldErrors.doc}</div>
)}
```

**Loading state (Bootstrap nativo):**
```tsx
<button disabled={loading}>
  {loading
    ? <span className="spinner-border spinner-border-sm" />
    : 'Continuar'}
</button>
```

### `src/app/ai-onboarding/page.tsx`

Escopo menor — sem fluxo de pagamento, sem campos de CPF. Mudanças:
- Usar `errorMapper` para erros globais (rede, rate-limit, service-unavailable)
- Remover `console.error` dos blocos `catch`
- Adicionar `loading` state nos botões de submissão

---

## Testes

### `src/lib/errorMapper.test.ts` (novo)

Testes unitários Jest cobrindo:
- `validation-error` com violations → `fields` populado, `global` null
- `service-unavailable` → `global` com mensagem específica, `retryable=true`
- `conflict` → `global` com mensagem específica, `retryable=false`
- `rate-limit-exceeded` → `retryable=true`
- Erro de rede (sem `response`) → mensagem de conexão, `retryable=true`
- Field desconhecido → fallback para mensagem original do backend

Validação manual dos critérios de aceite conforme checklist da task.

---

## Mudança obrigatória no Backend

`OnboardingService.createUser()` atualmente falha completamente se o Asaas estiver indisponível — a transação reverte e o `BillingSubscription` (trial) não é criado. Se o trial não existe, o Step 2 (`createOrganization`) falha com `NotFoundException`.

**Solução:** tornar a criação do customer Asaas não-bloqueante dentro de `createUser()`:

```java
// OnboardingService.createUser() — trecho alterado
if (account.getExternalCustomerId() == null) {
    try {
        var customer = IOnboardingMapper.INSTANCE.toCustomerDTO(account);
        var externalCustomerId = providerFactory.get(PaymentProvider.ASAAS).createExternalCustomer(customer);
        account.setExternalCustomerId(externalCustomerId);
    } catch (Exception e) {
        log.warn("Asaas indisponível durante onboarding para userId {}. Continuando sem externalCustomerId.", user.getId());
        // externalCustomerId permanece null — configurável depois
    }
}
```

Resultado: se Asaas falha, o `BillingAccount` e o `BillingSubscription` (trial) ainda são criados localmente. O usuário completa o onboarding normalmente. O `externalCustomerId` pode ser preenchido depois quando o usuário configurar o pagamento.

**Contrato de API não muda.** O endpoint `/me/onboarding/user` retorna o mesmo `AccountUserResponse`. A diferença é que em caso de falha do Asaas, retorna sucesso (200) em vez de 503.

---

## Arquivos Impactados

| Arquivo | Ação |
|---|---|
| `src/lib/errorMapper.ts` | Criar (frontend) |
| `src/lib/errorMapper.test.ts` | Criar (frontend) |
| `src/app/onboarding/page.tsx` | Editar (frontend) |
| `src/app/ai-onboarding/page.tsx` | Editar (frontend) |
| `OnboardingService.java` | Editar (backend) — Asaas não-bloqueante |

**Não alterado:** contratos de API, `apiClient.ts`, `AuthContext.tsx`, outros componentes.

---

## Critérios de Aceite (da task)

- [ ] Erros de validação do backend mapeados para mensagens PT específicas (não toast genérico)
- [ ] CPF/CNPJ inválido mostra mensagem diretamente no campo
- [ ] Falha do Asaas não bloqueia o onboarding — usuário pode prosseguir sem pagamento
- [ ] Erros de rede mostram botão "Tentar novamente"
- [ ] Nenhum `console.error` nos fluxos de onboarding
- [ ] Loading state durante operações assíncronas

---

## Riscos

- **Baixo:** Limpeza de `fieldErrors` ao re-submeter — garantir que `setFieldErrors({})` é chamado antes de cada tentativa para não mostrar erros antigos
- **Baixo:** `OnboardingService.createUser()` com Asaas não-bloqueante altera comportamento atual de "falha geral em cascata" para "continua sem Asaas" — monitorar logs de `warn` em produção para detectar clientes sem `externalCustomerId`
