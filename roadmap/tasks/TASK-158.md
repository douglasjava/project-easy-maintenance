# TASK-158 — Frontend: página pública de Termos de Uso

## Tipo
FRONTEND

## Categoria
Jurídico / Compliance

## Prioridade
🟠 Alto

## Épico
Nenhum — achado pré-existente (flagado no TASK-151 e no EPIC-018) resolvido nesta task.

## QA obrigatório
Sim — validar acesso anônimo e conteúdo jurídico com Douglas.

---

## Contexto

O link "Termos de Uso" no rodapé da landing (`href="#"`) estava quebrado desde antes do TASK-151 —
não existia nenhum conteúdo de Termos de Uso no repositório. Foi flagado como bug pré-existente,
fora de escopo, tanto no TASK-151 quanto no EPIC-018 (sem conteúdo jurídico pra linkar).

Douglas confirmou os dados necessários pra escrever o documento:
- Entidade legal: **BRAINBYTE CONSULTORIA TI LTDA**, CNPJ **50.047.256/0001-22**
- Sem política de reembolso (cancelamento interrompe cobranças futuras, não devolve valores já pagos)
- Trial de 14 dias (já confirmado via TASK-087)

---

## Objetivo

Criar `/termos`, com o mesmo padrão visual de `/privacidade`, cobrindo: identificação das partes,
objeto do contrato, cadastro, trial/planos/cobrança, cancelamento/reembolso, uso aceitável, dados/
privacidade (link pra `/privacidade`), propriedade intelectual, disponibilidade/limitação de
responsabilidade, rescisão, alterações, lei aplicável e contato.

---

## Escopo

### 1. `src/app/termos/page.tsx`
Nova página pública, mesmo padrão de `privacidade/page.tsx` (nav simples com `Logo`, `metadata`
com `canonical`).

### 2. Correção do `Shell.tsx`
Adicionar `pathname?.endsWith("/termos")` à condição `isAuth` — mesma classe de bug corrigida no
TASK-151 (`/privacidade`) e TASK-155 (`/obrigado`): sem isso, visitante anônimo é redirecionado
pro `/login`.

### 3. `sitemap.ts`
Adicionar `/termos` (mesma prioridade/frequência de `/privacidade`).

### 4. Link do rodapé
`landing/page.tsx`: trocar `href="#"` por `/termos` no link "Termos de Uso".

---

## Critérios de Aceite

- [x] `/termos` acessível sem login, sem redirect pro `/login`
- [x] Conteúdo identifica corretamente a parte contratante (razão social + CNPJ)
- [x] Cobre trial, formas de pagamento, cancelamento/reembolso, uso aceitável, propriedade
      intelectual, limitação de responsabilidade e lei aplicável
- [x] Link "Termos de Uso" no rodapé da landing aponta pra `/termos`
- [x] `/termos` presente no `sitemap.ts`
- [x] `npm run build` limpo

## Riscos

**Este é um rascunho, não substitui revisão jurídica.** Cobre os termos que Douglas confirmou
(entidade legal, trial, política de reembolso) mais estrutura padrão de Termos de Uso de SaaS B2B,
mas as cláusulas de limitação de responsabilidade e proteção ao consumidor devem ser revisadas por
um advogado antes de serem usadas com clientes pagantes reais — ainda mais relevante por não haver
nenhum cliente pagante hoje (ver decisão de escopo do EPIC-018 sobre isso), ou seja, dá tempo de
corrigir com calma antes do primeiro contrato real.

## Esforço
Baixo

## Status
Em Validação — [PR #30](https://github.com/douglasjava/easy-maintenance-web/pull/30) aprovada e
mergeada em `staging`; [PR #31](https://github.com/douglasjava/easy-maintenance-web/pull/31)
(`staging` → `main`) aberta. Falta merge final em `main` e a revisão jurídica do conteúdo (ver
Riscos).
