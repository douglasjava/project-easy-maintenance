# TASK-045 — Criar middleware.ts para guards de autenticação

## Tipo
FRONTEND

## Categoria
Performance / Segurança / Next.js

## Prioridade
🟡 Médio

## Fase
2 — Estabilização Pós-Lançamento

## Épico
EPIC-009 — Performance Frontend

## Descrição
A validação de autenticação ocorre atualmente no cliente, dentro de `src/components/Shell.tsx`, após o JavaScript ser carregado e a hidratação ser concluída. Isso introduz um ciclo extra de render antes do redirecionamento e cria um "flash" da página protegida antes do redirect para `/login`.

**Comportamento atual:**
1. Browser carrega a página
2. Next.js hidrata o React
3. Shell.tsx executa no cliente, lê `localStorage`
4. Se não autenticado → `router.replace('/login')` (tarde demais)

**Comportamento esperado com middleware:**
1. Request chega ao servidor/edge
2. `middleware.ts` verifica presença do cookie de sessão
3. Se ausente → `NextResponse.redirect('/login')` (antes de qualquer HTML ser enviado)

**Escopo do middleware:**
- Proteger rotas autenticadas: todas exceto `/login`, `/landing`, `/forgot-password`, `/reset-password`, `/onboarding`, `/ai-onboarding`
- Rota admin (`/private/*`): verificar header/cookie `adminToken`
- Não substituir toda a lógica do Shell — apenas o redirecionamento inicial

**Implementação base:**
```ts
// src/middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const PUBLIC_ROUTES = ['/login', '/landing', '/forgot-password', '/reset-password', '/onboarding', '/ai-onboarding', '/select-organization'];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  const isPublic = PUBLIC_ROUTES.some(r => pathname.startsWith(r));
  if (isPublic) return NextResponse.next();

  const sessionCookie = request.cookies.get('session'); // nome real do cookie HttpOnly
  if (!sessionCookie) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next|api|public|favicon).*)'],
};
```

**Nota:** O nome exato do cookie HttpOnly deve ser alinhado com a implementação de TASK-002 (migração JWT para cookie HttpOnly).

## Critérios de Aceite
- [ ] `src/middleware.ts` criado e configurado com matcher correto
- [ ] Acesso a rota protegida sem cookie redireciona para `/login` sem flash de conteúdo
- [ ] Rotas públicas continuam acessíveis sem autenticação
- [ ] Rota `/private/login` acessível sem cookie de sessão
- [ ] Shell.tsx pode ter sua lógica de redirect simplificada (não removida completamente — serve como fallback)
- [ ] Não interfere com o fluxo de cookie HttpOnly implementado em TASK-002

## Esforço
Médio (meio dia de implementação + testes de fluxo)

## Status
Concluído

## Impacto Esperado
Médio-Alto — elimina flash de conteúdo protegido, melhora performance percebida no carregamento inicial e adiciona camada de segurança no edge.
