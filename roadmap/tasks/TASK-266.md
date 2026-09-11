# TASK-266 — BACKEND: Gestão do cadastro via link mágico (público)

## Tipo
BACKEND

## Categoria
Fornecedores / Marketplace

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — coberto pela rodada de QA manual única no final do épico.

---

## Contexto

Decisão de escopo #3 do spec: fornecedor gerencia telefone/categoria sem precisar de login —
autenticação por link mágico (`SupplierAccessToken`, gerado na ativação — TASK-265).

## Escopo

- `GET /easy-maintenance/api/v1/public/suppliers/manage/{token}` — consulta perfil + status da
  assinatura.
- `PUT /easy-maintenance/api/v1/public/suppliers/manage/{token}` — atualiza telefone/categoria
  (campos parciais, só atualiza o que veio preenchido).
- Rate limit: 30 req/min por IP (mais permissivo que o self-register — não dispara cobrança).

## Critérios de Aceite

- [x] Token válido retorna perfil + `subscriptionStatus` correto
- [x] Token inválido → `NotFoundException`
- [x] Atualização parcial (só telefone, ou só categoria) funciona

## Dependências
TASK-261 (`SupplierAccessTokenRepository`), TASK-265 (gera o token que este endpoint consome).

## Riscos
Baixo — sem autenticação de usuário (por design, é o próprio link que autentica), mas sem dado
sensível exposto (nunca expõe outros fornecedores nem dado de organização).

## Esforço
Pequeno

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `supplier_billing/application/dto/SupplierManageResponse.java` | perfil + `subscriptionStatus` |
| `supplier_billing/application/dto/UpdateSupplierProfileRequest.java` | `phone`/`category` opcionais |
| `supplier_billing/application/service/SupplierSelfManageService.java` | `get(token)`/`update(token, request)` |
| `test/.../supplier_billing/application/service/SupplierSelfManageServiceTest.java` | 3 testes |

### Arquivos modificados
`SupplierPublicController.java` (novos endpoints), `application.properties` (rate limit
`supplier-manage`).

### Verificação
`mvn test` (suíte completa) → PASS, sem regressão.

## Status
🟢 Implementado e testado.
