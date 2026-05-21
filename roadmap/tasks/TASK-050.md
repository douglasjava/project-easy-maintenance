# TASK-050 — Criar páginas públicas de retorno do checkout (sucesso, cancelado e expirado)

## Tipo
FRONTEND

## Categoria
Billing / Conversão / UX

## Prioridade
🟠 Alto

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Descrição
Criar três páginas públicas no frontend para tratar os retornos do checkout de pagamento (Asaas), garantindo uma experiência clara para o usuário após tentativa de pagamento.

O backend já está configurado com estas URLs em produção, e usuários eram redirecionados para páginas 404 após o pagamento.

As páginas são essenciais para:
- Melhorar a conversão de pagamento
- Reduzir dúvidas do usuário após falha/cancelamento
- Direcionar o usuário para próximas ações (retry, dashboard, planos)
- Fechar o fluxo completo de billing SaaS

## Escopo

- Página de sucesso (`/checkout/success`)
- Página de cancelamento (`/checkout/cancel`)
- Página de expiração (`/checkout/exp`)
- Layout padronizado com cores e ícones por status
- Botões de ação (CTA)
- Componente reutilizável `CheckoutStatusPage`

## Critérios de Aceite

- [x] As 3 páginas são acessíveis sem autenticação
- [x] Layout responsivo (mobile-first via Bootstrap)
- [x] Segue padrão visual do sistema (Bootstrap)
- [x] CTAs funcionais (apontam para `/billing` e `/`)
- [x] Código organizado e reutilizável (`CheckoutStatusPage.tsx`)
- [x] Estrutura pronta para futura integração com API (`searchParams`)
- [x] Shell sem topbar/sidebar nas páginas checkout

## Arquivos Criados / Modificados

| Arquivo | Operação |
|---------|----------|
| `src/middleware.ts` | Adicionado `/checkout` em `PUBLIC_PATHS` |
| `src/components/Shell.tsx` | Adicionado `pathname?.startsWith("/checkout")` em `isAuth` |
| `src/components/checkout/CheckoutStatusPage.tsx` | Criado — componente reutilizável |
| `src/app/checkout/success/page.tsx` | Criado — sucesso (verde) |
| `src/app/checkout/cancel/page.tsx` | Criado — cancelado (amarelo) |
| `src/app/checkout/exp/page.tsx` | Criado — expirado (cinza) |

## Esforço
Pequeno (2-3h)

## Status
Concluído
