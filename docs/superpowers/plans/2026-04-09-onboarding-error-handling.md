# Onboarding Error Handling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir erros silenciosos/genéricos no onboarding por mensagens específicas em PT-BR, inline nos campos e com fallback de rede, sem bloquear o trial quando o Asaas falhar.

**Architecture:** Utilitário puro `errorMapper.ts` centraliza o mapeamento de ProblemDetail (RFC 7807) → mensagens PT. O backend `OnboardingService` passa a absorver falhas do Asaas internamente (não propaga 503). Os componentes de onboarding consomem o mapper e exibem erros inline via classes Bootstrap `is-invalid`/`invalid-feedback`.

**Tech Stack:** Java 21 + Spring Boot 3 (backend), Next.js 16 + TypeScript + Bootstrap 5 + react-hot-toast (frontend), Jest + ts-jest (testes unitários do mapper)

---

## Mapa de arquivos

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `easy-maintenance-api/.../OnboardingService.java` | Modificar | Asaas não-bloqueante em `createUser()` |
| `easy-maintenance-web/src/lib/errorMapper.ts` | Criar | Mapear ProblemDetail → `MappedError` |
| `easy-maintenance-web/src/lib/errorMapper.test.ts` | Criar | Testes unitários do mapper |
| `easy-maintenance-web/src/app/onboarding/page.tsx` | Modificar | `fieldErrors` state + `errorMapper` + spinner |
| `easy-maintenance-web/src/app/ai-onboarding/page.tsx` | Modificar | `errorMapper` + remover `console.error` |
| `easy-maintenance-web/package.json` | Modificar | Adicionar Jest + script `test` |
| `easy-maintenance-web/jest.config.js` | Criar | Configuração Jest + ts-jest |

---

## Task 1: Backend — Asaas não-bloqueante em OnboardingService

**Files:**
- Modify: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/onboarding/application/service/OnboardingService.java:59-63`

- [ ] **Step 1: Localizar o bloco de criação do customer Asaas**

  Abrir o arquivo. O bloco que precisa mudar está em `createUser()`, linhas 59–63:
  ```java
  if (account.getExternalCustomerId() == null) {
      var customer = IOnboardingMapper.INSTANCE.toCustomerDTO(account);
      var externalCustomerId = providerFactory.get(PaymentProvider.ASAAS).createExternalCustomer(customer);
      account.setExternalCustomerId(externalCustomerId);
  }
  ```

- [ ] **Step 2: Envolver a chamada Asaas em try-catch**

  Substituir o bloco acima por:
  ```java
  if (account.getExternalCustomerId() == null) {
      try {
          var customer = IOnboardingMapper.INSTANCE.toCustomerDTO(account);
          var externalCustomerId = providerFactory.get(PaymentProvider.ASAAS).createExternalCustomer(customer);
          account.setExternalCustomerId(externalCustomerId);
      } catch (Exception e) {
          log.warn("Asaas indisponível durante onboarding para userId {}. Continuando sem externalCustomerId. Erro: {}",
                  user.getId(), e.getMessage());
      }
  }
  ```
  O `@Transactional` ainda garante rollback em erros fora deste bloco. O `externalCustomerId` permanece `null` e pode ser configurado depois.

- [ ] **Step 3: Compilar o backend e verificar**

  No diretório `easy-maintenance-api`:
  ```bash
  ./mvnw compile -q
  ```
  Esperado: `BUILD SUCCESS` sem erros de compilação.

- [ ] **Step 4: Commit**

  ```bash
  git add easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/onboarding/application/service/OnboardingService.java
  git commit -m "fix: make Asaas customer creation non-blocking in onboarding"
  ```

---

## Task 2: Frontend — Criar `errorMapper.ts`

**Files:**
- Create: `easy-maintenance-web/src/lib/errorMapper.ts`

- [ ] **Step 1: Criar o arquivo `errorMapper.ts`**

  Criar `easy-maintenance-web/src/lib/errorMapper.ts` com o seguinte conteúdo:

  ```typescript
  export interface MappedError {
    global: string | null;
    fields: Record<string, string>;
    retryable: boolean;
  }

  const FIELD_MESSAGES: Record<string, string> = {
    doc: "CPF ou CNPJ inválido. Verifique os dígitos.",
    billingEmail: "E-mail de cobrança inválido.",
    name: "Nome é obrigatório.",
    code: "Nome da organização já está em uso. Escolha outro.",
    zipCode: "CEP inválido. Informe 8 dígitos.",
  };

  const PROBLEM_BASE = "https://easy-maintenance/api/problems/";

  function extractSlug(type: string | undefined): string {
    if (!type) return "unexpected";
    return type.startsWith(PROBLEM_BASE)
      ? type.slice(PROBLEM_BASE.length)
      : "unexpected";
  }

  export function mapError(error: unknown): MappedError {
    const axiosError = error as {
      response?: {
        data?: {
          type?: string;
          violations?: Array<{ field: string; message: string }>;
        };
      };
    };

    // Sem resposta da API — erro de rede
    if (!axiosError?.response) {
      return {
        global: "Sem conexão. Verifique sua internet e tente novamente.",
        fields: {},
        retryable: true,
      };
    }

    const data = axiosError.response.data ?? {};
    const slug = extractSlug(data.type);

    if (slug === "validation-error") {
      const fields: Record<string, string> = {};
      for (const v of data.violations ?? []) {
        fields[v.field] = FIELD_MESSAGES[v.field] ?? v.message;
      }
      return { global: null, fields, retryable: false };
    }

    if (slug === "conflict") {
      return {
        global: "Este dado já está cadastrado.",
        fields: {},
        retryable: false,
      };
    }

    if (slug === "service-unavailable") {
      return {
        global: "Serviço temporariamente indisponível. Tente novamente em alguns minutos.",
        fields: {},
        retryable: true,
      };
    }

    if (slug === "rate-limit-exceeded") {
      return {
        global: "Muitas tentativas. Aguarde e tente novamente.",
        fields: {},
        retryable: true,
      };
    }

    return {
      global: "Erro inesperado. Tente novamente.",
      fields: {},
      retryable: true,
    };
  }
  ```

- [ ] **Step 2: Verificar que o TypeScript compila**

  No diretório `easy-maintenance-web`:
  ```bash
  npx tsc --noEmit
  ```
  Esperado: sem erros de tipo.

- [ ] **Step 3: Commit**

  ```bash
  git add easy-maintenance-web/src/lib/errorMapper.ts
  git commit -m "feat: add errorMapper utility for onboarding error handling"
  ```

---

## Task 3: Frontend — Configurar Jest e escrever testes do `errorMapper`

**Files:**
- Modify: `easy-maintenance-web/package.json`
- Create: `easy-maintenance-web/jest.config.js`
- Create: `easy-maintenance-web/src/lib/errorMapper.test.ts`

- [ ] **Step 1: Instalar dependências de teste**

  No diretório `easy-maintenance-web`:
  ```bash
  npm install --save-dev jest ts-jest @types/jest
  ```
  Esperado: pacotes instalados, `package.json` atualizado com as devDependencies.

- [ ] **Step 2: Adicionar script de test no `package.json`**

  No arquivo `easy-maintenance-web/package.json`, adicionar `"test": "jest"` na seção `scripts`:
  ```json
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "test": "jest"
  },
  ```

- [ ] **Step 3: Criar `jest.config.js`**

  Criar `easy-maintenance-web/jest.config.js`:
  ```js
  /** @type {import('jest').Config} */
  module.exports = {
    preset: 'ts-jest',
    testEnvironment: 'node',
    testMatch: ['**/*.test.ts'],
  };
  ```

- [ ] **Step 4: Escrever os testes**

  Criar `easy-maintenance-web/src/lib/errorMapper.test.ts`:
  ```typescript
  import { mapError } from "./errorMapper";

  function makeAxiosError(type: string, violations?: Array<{ field: string; message: string }>) {
    return {
      response: {
        data: { type: `https://easy-maintenance/api/problems/${type}`, violations },
      },
    };
  }

  describe("mapError", () => {
    it("returns network error message when there is no response", () => {
      const result = mapError({});
      expect(result.global).toBe("Sem conexão. Verifique sua internet e tente novamente.");
      expect(result.retryable).toBe(true);
      expect(result.fields).toEqual({});
    });

    it("maps validation-error with known field to PT message", () => {
      const error = makeAxiosError("validation-error", [
        { field: "doc", message: "invalid document" },
      ]);
      const result = mapError(error);
      expect(result.global).toBeNull();
      expect(result.fields.doc).toBe("CPF ou CNPJ inválido. Verifique os dígitos.");
      expect(result.retryable).toBe(false);
    });

    it("falls back to backend message for unknown field in validation-error", () => {
      const error = makeAxiosError("validation-error", [
        { field: "unknownField", message: "campo inválido do backend" },
      ]);
      const result = mapError(error);
      expect(result.fields.unknownField).toBe("campo inválido do backend");
    });

    it("maps validation-error with multiple fields", () => {
      const error = makeAxiosError("validation-error", [
        { field: "doc", message: "invalid" },
        { field: "billingEmail", message: "invalid email" },
      ]);
      const result = mapError(error);
      expect(result.fields.doc).toBe("CPF ou CNPJ inválido. Verifique os dígitos.");
      expect(result.fields.billingEmail).toBe("E-mail de cobrança inválido.");
      expect(result.global).toBeNull();
    });

    it("maps conflict to specific message, not retryable", () => {
      const error = makeAxiosError("conflict");
      const result = mapError(error);
      expect(result.global).toBe("Este dado já está cadastrado.");
      expect(result.retryable).toBe(false);
      expect(result.fields).toEqual({});
    });

    it("maps service-unavailable as retryable", () => {
      const error = makeAxiosError("service-unavailable");
      const result = mapError(error);
      expect(result.global).toBe("Serviço temporariamente indisponível. Tente novamente em alguns minutos.");
      expect(result.retryable).toBe(true);
    });

    it("maps rate-limit-exceeded as retryable", () => {
      const error = makeAxiosError("rate-limit-exceeded");
      const result = mapError(error);
      expect(result.global).toBe("Muitas tentativas. Aguarde e tente novamente.");
      expect(result.retryable).toBe(true);
    });

    it("maps unexpected errors as retryable with generic message", () => {
      const error = makeAxiosError("unexpected");
      const result = mapError(error);
      expect(result.global).toBe("Erro inesperado. Tente novamente.");
      expect(result.retryable).toBe(true);
    });

    it("returns generic error for unknown problem type", () => {
      const error = makeAxiosError("some-unknown-type");
      const result = mapError(error);
      expect(result.global).toBe("Erro inesperado. Tente novamente.");
      expect(result.retryable).toBe(true);
    });
  });
  ```

- [ ] **Step 5: Rodar os testes**

  ```bash
  cd easy-maintenance-web && npm test
  ```
  Esperado: 9 testes passando, 0 falhando:
  ```
  PASS  src/lib/errorMapper.test.ts
    mapError
      ✓ returns network error message when there is no response
      ✓ maps validation-error with known field to PT message
      ✓ falls back to backend message for unknown field in validation-error
      ✓ maps validation-error with multiple fields
      ✓ maps conflict to specific message, not retryable
      ✓ maps service-unavailable as retryable
      ✓ maps rate-limit-exceeded as retryable
      ✓ maps unexpected errors as retryable with generic message
      ✓ returns generic error for unknown problem type
  ```

- [ ] **Step 6: Commit**

  ```bash
  git add easy-maintenance-web/package.json easy-maintenance-web/jest.config.js easy-maintenance-web/src/lib/errorMapper.test.ts
  git commit -m "test: add unit tests for errorMapper"
  ```

---

## Task 4: Frontend — Atualizar `onboarding/page.tsx`

**Files:**
- Modify: `easy-maintenance-web/src/app/onboarding/page.tsx`

O arquivo atual tem dois handlers: `handleStep1` (dados de faturamento) e `handleStep2` (organização). Ambos fazem `console.error` + `toast.error` genérico. Nesta task:
- Adicionamos `fieldErrors` state
- Ambos os handlers passam a usar `mapError`
- Campos com erro recebem `is-invalid` + `invalid-feedback`
- Botões recebem spinner Bootstrap (já têm `disabled={loading}`)

- [ ] **Step 1: Adicionar import do `mapError` e states `fieldErrors` + `retryableError`**

  No topo do arquivo, adicionar o import após os imports existentes:
  ```tsx
  import { mapError } from "@/lib/errorMapper";
  ```

  No corpo do componente, após `const [loading, setLoading] = useState(false);`, adicionar:
  ```tsx
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [retryableError, setRetryableError] = useState<string | null>(null);
  ```

- [ ] **Step 2: Atualizar `handleStep1` para usar `mapError`**

  Substituir o bloco `catch` do `handleStep1` (linha ~161–164):
  ```tsx
  // ANTES:
  } catch (error: any) {
      console.error(error);
      toast.error(error?.response?.data?.message || "Erro ao salvar dados de faturamento.");
  }
  ```
  Por:
  ```tsx
  // DEPOIS:
  } catch (error: unknown) {
      const mapped = mapError(error);
      if (Object.keys(mapped.fields).length > 0) {
          setFieldErrors(mapped.fields);
      } else if (mapped.retryable && mapped.global) {
          setRetryableError(mapped.global);
      } else if (mapped.global) {
          toast.error(mapped.global);
      }
  }
  ```

  E adicionar `setFieldErrors({})` + `setRetryableError(null)` no início do try:
  ```tsx
  const handleStep1 = async (e: React.FormEvent) => {
      e.preventDefault();
      setFieldErrors({});
      setRetryableError(null);
      setLoading(true);
      try {
        // ... resto igual
  ```

- [ ] **Step 3: Atualizar `handleStep2` para usar `mapError`**

  Substituir o bloco `catch` do `handleStep2` (linha ~217–220):
  ```tsx
  // ANTES:
  } catch (error: any) {
      console.error(error);
      toast.error(error?.response?.data?.message || "Erro ao criar organização.");
  }
  ```
  Por:
  ```tsx
  // DEPOIS:
  } catch (error: unknown) {
      const mapped = mapError(error);
      if (Object.keys(mapped.fields).length > 0) {
          setFieldErrors(mapped.fields);
      } else if (mapped.retryable && mapped.global) {
          setRetryableError(mapped.global);
      } else if (mapped.global) {
          toast.error(mapped.global);
      }
  }
  ```

  E adicionar `setFieldErrors({})` + `setRetryableError(null)` no início do try do `handleStep2`:
  ```tsx
  const handleStep2 = async (e: React.FormEvent) => {
      e.preventDefault();
      setFieldErrors({});
      setRetryableError(null);
      setLoading(true);
      try {
        // ... resto igual
  ```

- [ ] **Step 4: Adicionar `is-invalid` e `invalid-feedback` nos campos do Step 1**

  Para cada campo do Step 1 que tem correspondente no `FIELD_MESSAGES` do mapper, adicionar a classe condicional e o div de feedback.

  **Campo `name` (Nome do Responsável):**
  ```tsx
  <input
      type="text"
      className={`form-control ${fieldErrors.name ? "is-invalid" : ""}`}
      required
      value={billingData.name}
      onChange={e => setBillingData({ ...billingData, name: e.target.value })}
  />
  {fieldErrors.name && <div className="invalid-feedback">{fieldErrors.name}</div>}
  ```

  **Campo `billingEmail` (E-mail de Faturamento):**
  ```tsx
  <input
      type="email"
      className={`form-control ${fieldErrors.billingEmail ? "is-invalid" : ""}`}
      required
      value={billingData.billingEmail}
      onChange={e => setBillingData({ ...billingData, billingEmail: e.target.value })}
  />
  {fieldErrors.billingEmail && <div className="invalid-feedback">{fieldErrors.billingEmail}</div>}
  ```

  **Campo `doc` (CPF):**
  ```tsx
  <input
      type="text"
      className={`form-control ${fieldErrors.doc ? "is-invalid" : ""}`}
      required
      value={billingData.doc}
      onChange={e => setBillingData({ ...billingData, doc: e.target.value })}
  />
  {fieldErrors.doc && <div className="invalid-feedback">{fieldErrors.doc}</div>}
  ```

  **Campo `zipCode` (CEP) no Step 1:**
  ```tsx
  <input
      type="text"
      className={`form-control ${fieldErrors.zipCode ? "is-invalid" : ""}`}
      required
      value={billingData.zipCode}
      onChange={e => setBillingData({ ...billingData, zipCode: e.target.value })}
      onBlur={handleBillingCepBlur}
  />
  {fieldErrors.zipCode && <div className="invalid-feedback">{fieldErrors.zipCode}</div>}
  ```

- [ ] **Step 5: Adicionar `is-invalid` nos campos do Step 2**

  **Campo `code` (Nome da Organização — mapeado como `name` no payload mas como `code` no backend):**

  Nota: o backend valida o campo `code` no request da organização. O nome do campo no `orgData` é `orgName`, mas o payload enviado usa `name: orgData.orgName`. Verificar a validação do DTO de organização para confirmar qual campo o backend retorna nas violations. Com base no `OnboardingDTO.AccountOrganizationRequest`, o campo validado é `code` (o `crypto.randomUUID()`) e `name` (orgName). Adicionar para `name`:

  ```tsx
  <input
      type="text"
      className={`form-control ${fieldErrors.name ? "is-invalid" : ""}`}
      required
      value={orgData.orgName}
      onChange={e => setOrgData({ ...orgData, orgName: e.target.value })}
  />
  {fieldErrors.name && <div className="invalid-feedback">{fieldErrors.name}</div>}
  ```

  **Campo `zipCode` (CEP) no Step 2:**
  ```tsx
  <input
      type="text"
      className={`form-control ${fieldErrors.zipCode ? "is-invalid" : ""}`}
      required
      value={orgData.orgZipCode}
      onChange={e => setOrgData({ ...orgData, orgZipCode: e.target.value })}
      onBlur={handleOrgCepBlur}
  />
  {fieldErrors.zipCode && <div className="invalid-feedback">{fieldErrors.zipCode}</div>}
  ```

- [ ] **Step 6: Renderizar alert "Tentar novamente" nos forms**

  Nos dois steps do formulário, adicionar o alert com botão logo acima do `<div className="d-flex justify-content-end mt-5">` (Step 1) e `<div className="d-flex justify-content-between mt-5">` (Step 2).

  **Dentro do form do Step 1**, antes do div dos botões:
  ```tsx
  {retryableError && (
      <div className="alert alert-danger d-flex align-items-center justify-content-between mt-4" role="alert">
          <span>{retryableError}</span>
          <button type="submit" className="btn btn-sm btn-outline-danger ms-3">
              Tentar novamente
          </button>
      </div>
  )}
  ```

  **Dentro do form do Step 2**, antes do div dos botões:
  ```tsx
  {retryableError && (
      <div className="alert alert-danger d-flex align-items-center justify-content-between mt-4" role="alert">
          <span>{retryableError}</span>
          <button type="submit" className="btn btn-sm btn-outline-danger ms-3">
              Tentar novamente
          </button>
      </div>
  )}
  ```

  O `type="submit"` dentro do `<form>` re-submete o form quando clicado, o que é exatamente o comportamento de retry desejado.

- [ ] **Step 7: Adicionar spinner nos botões de submissão**

  **Botão do Step 1** (linha ~431–440) — substituir o texto de loading por spinner:
  ```tsx
  <button
      type="submit"
      className="btn btn-primary px-5 py-2 fw-bold"
      disabled={loading}
      style={{ backgroundColor: "#0B5ED7" }}
  >
      {loading ? (
          <>
              <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
              Processando...
          </>
      ) : (
          "Próximo →"
      )}
  </button>
  ```

  **Botão do Step 2** (linha ~591–599) — substituir o texto de loading por spinner:
  ```tsx
  <button
      type="submit"
      className="btn btn-primary px-5 py-2 fw-bold"
      disabled={loading}
      style={{ backgroundColor: "#0B5ED7" }}
  >
      {loading ? (
          <>
              <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
              Criando...
          </>
      ) : (
          "Próximo →"
      )}
  </button>
  ```

- [ ] **Step 8: Verificar compilação TypeScript**

  ```bash
  cd easy-maintenance-web && npx tsc --noEmit
  ```
  Esperado: sem erros.

- [ ] **Step 9: Commit**

  ```bash
  git add easy-maintenance-web/src/app/onboarding/page.tsx
  git commit -m "feat: add inline field errors, retry alert and loading spinner to onboarding wizard"
  ```

---

## Task 5: Frontend — Atualizar `ai-onboarding/page.tsx`

**Files:**
- Modify: `easy-maintenance-web/src/app/ai-onboarding/page.tsx`

Este componente já tem spinner nos botões e `loading` state. Mudanças menores: remover `console.error` e usar `mapError` para mensagem de toast.

- [ ] **Step 1: Adicionar import do `mapError`**

  No topo do arquivo, adicionar após os imports existentes:
  ```tsx
  import { mapError } from "@/lib/errorMapper";
  ```

- [ ] **Step 2: Atualizar `handleGenerate` para usar `mapError`**

  Substituir o catch do `handleGenerate` (linha ~63–66):
  ```tsx
  // ANTES:
  } catch (err: any) {
      toast.error("Falha ao gerar pré-cadastros. Tente novamente.");
      console.error(err);
  }
  ```
  Por:
  ```tsx
  // DEPOIS:
  } catch (err: unknown) {
      const mapped = mapError(err);
      toast.error(mapped.global ?? "Falha ao gerar pré-cadastros. Tente novamente.");
  }
  ```

- [ ] **Step 3: Atualizar `handleApply` para usar `mapError`**

  Substituir o catch do `handleApply` (linha ~119–122):
  ```tsx
  // ANTES:
  } catch (err: any) {
      toast.error("Falha ao aplicar configurações. Tente novamente.");
      console.error(err);
  }
  ```
  Por:
  ```tsx
  // DEPOIS:
  } catch (err: unknown) {
      const mapped = mapError(err);
      toast.error(mapped.global ?? "Falha ao aplicar configurações. Tente novamente.");
  }
  ```

- [ ] **Step 4: Verificar compilação TypeScript**

  ```bash
  cd easy-maintenance-web && npx tsc --noEmit
  ```
  Esperado: sem erros.

- [ ] **Step 5: Commit**

  ```bash
  git add easy-maintenance-web/src/app/ai-onboarding/page.tsx
  git commit -m "feat: use errorMapper in ai-onboarding, remove console.error"
  ```

---

## Checklist de Validação Final

Após todos os commits, verificar manualmente:

- [ ] Submeter Step 1 com CPF inválido → mensagem aparece **abaixo do campo**, não como toast
- [ ] Submeter com e-mail inválido → mensagem abaixo do campo `billingEmail`
- [ ] Ao clicar "Próximo" → spinner aparece no botão durante a requisição
- [ ] Resubmeter após corrigir erro → erros antigos não ficam visíveis
- [ ] Simular erro de rede (desligar WiFi ou usar devtools offline) → toast "Sem conexão..."
- [ ] Nenhum `console.error` aparece no console do browser durante erros de onboarding
- [ ] Backend com Asaas fora do ar → `createUser` retorna 200, onboarding prossegue normalmente
- [ ] Rodar `npm test` no frontend → 9 testes passando
