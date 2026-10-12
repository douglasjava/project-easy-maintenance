# TASK-331 — Onboarding: campo de celular + opt-in explícito (espelhar padrão de Perfil)

## Tipo
FULL_STACK (form onboarding + validação backend + persistência multi-tenant)

## Prioridade
🟠 Alto — pré-requisito direto da TASK-332 (ativação via WhatsApp)

## Contexto
Feedback de teste de onboarding (11/10/2026): usuários sentiram falta de já informar o celular
durante o cadastro, em vez de só depois na tela de Perfil. A ideia (validada com Douglas) é
adiantar essa captura para o onboarding e, com opt-in explícito, permitir o disparo automático de
uma mensagem do assistente via WhatsApp (ver TASK-332).

Hoje o vínculo de número + consentimento já existe na tela de Perfil (TASK-301, EPIC-031 Onda 1).
Esta task reaproveita o mesmo componente/copy/validação, só movendo a captura para o fluxo de
onboarding.

## Proposta
- Adicionar campo de celular (com máscara/validação de formato BR) na tela de onboarding.
- Checkbox de opt-in explícito e destacado — mesmo texto/padrão legal já usado em Perfil (TASK-301),
  não pode ser pré-marcado nem redação ambígua (LGPD).
- Backend: persistir número + flag de consentimento vinculados ao usuário/organização
  (`X-Org-Id`), reaproveitando a validação/entidade já usada pelo endpoint de Perfil em vez de
  duplicar lógica.
- Onboarding deve funcionar normalmente (sem quebrar o fluxo) se o usuário deixar o campo vazio ou
  recusar o opt-in — campo não pode ser obrigatório para concluir o cadastro.

## Riscos / pontos de atenção
- LGPD: opt-in precisa ser claro e não pode ser condição para acesso ao produto.
- Evitar duplicar validação de telefone/consentimento que já existe em Perfil — reaproveitar.
- Número pode já existir vinculado a outra conta/organização — tratar o mesmo caso de conflito que
  Perfil já trata hoje.

## Critérios de Aceite
- [ ] Campo de celular aparece no onboarding, com validação de formato
- [ ] Opt-in explícito, desmarcado por padrão, com copy igual/equivalente ao de Perfil
- [ ] Onboarding conclui normalmente mesmo sem telefone/opt-in
- [ ] Número + consentimento persistidos corretamente com isolamento multi-tenant
- [ ] Sem regressão no fluxo de Perfil (TASK-301) que hoje faz o mesmo vínculo
