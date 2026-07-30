# TASK-154 — Frontend: checkbox de consentimento LGPD + envio de UTM no form de demonstração

## Tipo
FRONTEND

## Categoria
Marketing / LGPD

## Prioridade
🟠 Alto

## Épico
[EPIC-018](../epics/EPIC-018.md) — Tracking de Conversão para Ads (UTM, Consentimento LGPD, Página de Obrigado)

## QA obrigatório
Sim — validar bloqueio de submissão sem checkbox e o payload enviado ao backend.

---

## Contexto

O form "Solicitar Demonstração" (`landing/page.tsx`, `handleSubmit`) hoje só envia `email` +
`affiliateCode`, e mostra `alert()` de sucesso. Precisa: (a) exigir consentimento explícito com a
Política de Privacidade, próximo ao botão de submit, não só um link distante no rodapé; (b) enviar
os campos de UTM já suportados pelo backend (TASK-152/153 desbloqueiam isso); (c) redirecionar para
`/obrigado` (TASK-155) em vez de `alert()`.

---

## Objetivo

Checkbox obrigatório de consentimento LGPD ao lado do botão de submit, envio de UTM +
`consentAccepted` no payload, redirect para `/obrigado` no sucesso.

---

## Escopo

### 1. Checkbox de consentimento
- Novo estado `consentChecked` (boolean, default `false`).
- Checkbox `required`, posicionado diretamente ao lado/abaixo do botão "Solicitar Demonstração"
  (não no rodapé): "Li e concordo com a [Política de Privacidade](/privacidade)." — link abre em
  nova aba para não perder o preenchimento do form.
- `handleSubmit` retorna cedo (sem chamar a API) se `!consentChecked`, com mensagem de erro visível
  inline (mesmo padrão de estado de erro já usado no restante do form).

### 2. Payload com UTM
- `handleSubmit` lê `getStoredUtm()` (TASK-153) e monta `source/medium/campaign/utmJson` (e
  `referrer: document.referrer`, `landingPath: window.location.pathname`) no `api.post
  ('/landing/leads', {...})`, junto com `consentAccepted: true`.

### 3. Redirect pós-sucesso
- Substituir `alert(...)` por `router.push('/obrigado')` (via `useRouter` do `next/navigation`).
- Manter tratamento de erro existente (alert de erro) para falha de submissão.

### 4. Testes
- Sem infraestrutura de teste de componente — validar via build/lint + teste manual (submit sem
  marcar checkbox é bloqueado; submit com checkbox marcado chega em `/obrigado`; payload de rede
  contém os campos de UTM quando a URL de origem tinha UTM).

---

## Critérios de Aceite

- [ ] Submeter o form sem marcar o checkbox não dispara a chamada à API (bloqueado no cliente)
- [ ] Checkbox desmarcado mostra mensagem clara do que falta
- [ ] Submissão com sucesso envia `consentAccepted: true` e os campos de UTM presentes no cookie
      `em_utm` (quando existentes)
- [ ] Submissão com sucesso redireciona para `/obrigado` (não mostra mais `alert()` de sucesso)
- [ ] Erro de submissão continua tratado (mensagem de erro, sem redirect)
- [ ] `npm run build` limpo

## Dependências
- **TASK-152** — backend precisa aceitar `consentAccepted` antes deste form poder enviá-lo com
  sucesso.
- **TASK-153** — helper `getStoredUtm()`.
- **TASK-155** — rota `/obrigado` precisa existir para o redirect funcionar.

## Riscos
Baixo — mudança isolada ao form já existente, aditiva no payload.

## Esforço
Baixo

## Status
Pronto para Implementar
