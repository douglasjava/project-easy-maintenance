# TASK-319 — Nova Empresa: tipo aparece como "CONDOMINIO" mas é enviado vazio (erro 422)

## Tipo
BUGFIX (Frontend)

## Prioridade
🟠 Alto — quem não mexe no campo não consegue criar a empresa

## QA obrigatório
Sim.

## Contexto
Achado no regressivo da [TASK-317](TASK-317.md) (28/09/2026), pela tela `/organizations/new`:
- o estado inicial do formulário é `companyType: ""` e o `<select>` não tem opção vazia;
- o navegador **mostra** a primeira opção ("CONDOMINIO"), mas o valor enviado é vazio;
- a API responde **422** (`companyType: não deve ser nulo`) e a empresa não é criada.
Quem troca o tipo manualmente (ou escolhe outro e volta) consegue criar — por isso passou despercebido.

Arquivo: `easy-maintenance-web/src/app/organizations/new/page.tsx` (linhas 27, 88 e 170).

## Correção sugerida
- Iniciar `companyType` com `"CONDOMINIUM"` (o valor que a tela já mostra) **ou** adicionar a opção
  "Selecione o tipo" e bloquear o envio sem escolha, com mensagem.
- Mostrar a mensagem de validação do 422 na tela (hoje só vai para o console).
- Conferir se os outros formulários com `<select>` de tipo (onboarding, admin) têm o mesmo padrão.

## Critérios de aceite
- [ ] Criar empresa sem mexer no tipo funciona (ou a tela pede o tipo antes de enviar).
- [ ] Erro de validação da API aparece para o usuário.
- [ ] Mobile ok.

## Status
Backlog
