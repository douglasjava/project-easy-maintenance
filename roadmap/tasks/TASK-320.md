# TASK-320 — `@RequireTenant` não faz nada: implementar ou remover

## Tipo
INFRA / CONFIG (Backend, qualidade de segurança)

## Prioridade
🟡 Médio — hoje não abre falha sozinho, mas dá falsa sensação de proteção

## QA obrigatório
Sim — mexe no caminho de todas as requisições com organização.

## Contexto
Levantado na [TASK-317](TASK-317.md) (28/09/2026). A anotação `kernel/tenant/RequireTenant` nasceu no commit inicial do
projeto (`5d05686`, 12/11/2025) como uma anotação vazia, e **nunca existiu código que a leia** (nenhum aspect,
interceptor ou filtro em todo o histórico). Ela está em 43 lugares.

O que protege de verdade é o `TenantFilter` (exige `X-Org-Id` e confere se o usuário é membro), que tem uma lista de
caminhos liberados. Numa rota desses caminhos, a anotação não garante nada — a autorização precisa ser explícita.

## Opções
1. **Implementar** (recomendado): um `HandlerInterceptor` que, para métodos/classes com `@RequireTenant`, exige
   `TenantContext` preenchido (senão 400/403). Assim a anotação passa a valer mesmo se a rota cair num bypass.
2. **Remover** a anotação dos 43 lugares e documentar que a proteção é do `TenantFilter`.

## Também
- Revisar a lista de caminhos liberados do `TenantFilter` (comparação mais estrita). Detalhes no PR da TASK-317.
- Teste que falhe se uma rota nova sob um bypass não tiver autorização explícita.

## Critérios de aceite
- [ ] `@RequireTenant` tem efeito comprovado por teste, ou foi removida.
- [ ] Bypass do `TenantFilter` por prefixo exato, com teste.
- [ ] Regressivo E2E (`tests/auth/*`) sem regressão.

## Status
Backlog
