# TASK-QA-BUG-017 — IA Onboarding e dica do SAMU exibidos mesmo com `aiEnabled: false`

## Tipo
BUGFIX — FRONTEND

## Severidade
MÉDIA

## Prioridade
🟠 Alto

## Épico
EPIC-006 — Qualidade e UX

---

## Descrição do Bug

Quando `access-context` retorna `aiEnabled: false` para a organização ativa, o botão flutuante do **SAMU é corretamente ocultado** (via `ChatWidget.tsx`), mas três outros pontos da interface continuam exibindo conteúdo relacionado à IA sem verificar a flag:

| Local | Elemento incoerente |
|---|---|
| `Sidebar.tsx` — seção "Ações" | Item de navegação **"IA Onboarding"** sempre renderizado |
| `Sidebar.tsx` — rodapé | Texto **"🤖 Dica: use o SAMU para tirar dúvidas e encontrar prazos."** sempre visível |
| `QuickActions.tsx` — Dashboard | Card de acesso rápido **"IA Onboarding"** sempre renderizado |

## Comportamento Esperado

Quando `aiEnabled: false`:
- O item "IA Onboarding" **não aparece** no menu lateral
- A dica do SAMU **não aparece** no rodapé do menu lateral
- O card "IA Onboarding" **não aparece** em "Acesso rápido" no dashboard

Quando `aiEnabled: true`: comportamento atual mantido.

## Comportamento Atual

- Botão SAMU flutuante → oculto corretamente ✅
- Item "IA Onboarding" no Sidebar → **sempre visível** ❌
- Dica "use o SAMU" no rodapé → **sempre visível** ❌
- Card "IA Onboarding" em QuickActions → **sempre visível** ❌

---

## Causa Raiz

`ChatWidget.tsx` verifica `features?.aiEnabled` na linha 80. Os outros três componentes não fazem essa verificação:

- **`Sidebar.tsx`**: já usa `useCurrentOrganizationAccess()` mas desestrutura apenas `permissions`, ignorando `features`.
- **`QuickActions.tsx`**: componente estático sem acesso ao contexto de features.

---

## Arquivos Afetados

| Arquivo | Mudança necessária |
|---|---|
| `src/components/Sidebar.tsx` | Desestruturar `features` de `useCurrentOrganizationAccess()`; filtrar item "IA Onboarding" do array `items`; ocultar dica do SAMU no rodapé quando `!features?.aiEnabled` |
| `src/components/dashboard/QuickActions.tsx` | Adicionar `"use client"`; usar `useCurrentOrganizationAccess()` para obter `features`; filtrar card "IA Onboarding" quando `!features?.aiEnabled` |

`DashboardContent.tsx` não precisa de mudança — é apenas consumer de `QuickActions`.

---

## Padrão de Referência

`ChatWidget.tsx` implementa corretamente o guard:

```tsx
// src/ia/ChatWidget.tsx:80
if (isLoading || !features?.aiEnabled) {
  return null;
}
```

Mesma semântica deve ser aplicada nos três pontos acima.

---

## Critérios de Aceite

- [x] Com `aiEnabled: false`: item "IA Onboarding" ausente no Sidebar ✅
- [x] Com `aiEnabled: false`: dica "use o SAMU" ausente no rodapé do Sidebar ✅
- [x] Com `aiEnabled: false`: card "IA Onboarding" ausente em QuickActions ✅
- [x] Com `aiEnabled: true`: os três elementos continuam visíveis normalmente ✅
- [x] Loading state: durante `isLoading`, `features` é `null` → `features?.aiEnabled` é `undefined` → itens IA não exibidos ✅
- [x] Nenhuma regressão nas outras entradas do menu e dos cards de acesso rápido ✅

---

## Esforço Estimado
Baixo — 2 arquivos, mudanças cirúrgicas. Sem alteração de backend ou contrato de API.
