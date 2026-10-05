import { test, expect } from '@playwright/test';
import { TENANT_D_OPERATING } from '../../fixtures/tenant';
import { loginViaUi } from '../../helpers/frontend-login';

// EPIC-032: fluxo completo do módulo financeiro -- lançar receita, lançar despesa, ver refletido
// na lista e na Prestação de Contas, cancelar um lançamento e confirmar que some.
// Depende de uma API/MySQL e2e rodando (mesmo requisito dos demais specs de frontend/).
//
// Achados de code review corrigidos aqui:
// - `/reports` abre na aba "overview" por padrão (reports/page.tsx:112) -- a aba da Prestação de
//   Contas só existe com `?tab=prestacao` (suportado desde TASK-307, reports/page.tsx:115).
// - A seed e2e não limpa `financial_entries` entre execuções, então valores fixos ("R$ 500,00")
//   colidem com execuções anteriores e violam o modo estrito do Playwright (mais de um elemento
//   igual na tela). Usa valores únicos por execução (derivados de Date.now()) em vez de fixos.
// - `react-hot-toast` tem duração padrão de ~2s -- criar dois lançamentos em sequência rápida
//   deixa dois toasts "Lançamento criado com sucesso!" visíveis ao mesmo tempo, o que também
//   viola o modo estrito. Usa `.last()` pra sempre pegar o toast mais recente.
test.describe.configure({ mode: 'serial' });

function uniqueCents(base: number): string {
  // 2 últimos dígitos de Date.now() somados à base -- único o suficiente entre execuções
  // consecutivas sem exigir limpeza de banco, e ainda formata como moeda válida.
  const unique = base + (Date.now() % 100);
  return (unique / 100).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

test.describe('Financeiro — EPIC-032', () => {
  test('cria receita e despesa, reflete na lista e na Prestação de Contas', async ({ page }) => {
    const revenueValue = uniqueCents(50000); // ~R$ 500,xx
    const expenseValue = uniqueCents(8000); // ~R$ 80,xx

    await loginViaUi(page, TENANT_D_OPERATING);
    await page.goto('/financeiro');

    await expect(page.getByRole('heading', { name: 'Financeiro' })).toBeVisible({ timeout: 15_000 });

    // Lança receita
    await page.getByRole('button', { name: 'Nova receita' }).click();
    await page.locator('.modal-dialog select').selectOption('TAXA_CONDOMINIAL');
    await page.getByPlaceholder('0,00').fill(revenueValue);
    await page.getByRole('button', { name: 'Lançar' }).click();
    await expect(page.getByText('Lançamento criado com sucesso!').last()).toBeVisible();

    // Lança despesa
    await page.getByRole('button', { name: 'Nova despesa' }).click();
    await page.locator('.modal-dialog select').selectOption('CONTA_CONSUMO');
    await page.getByPlaceholder('0,00').fill(expenseValue);
    await page.getByRole('button', { name: 'Lançar' }).click();
    await expect(page.getByText('Lançamento criado com sucesso!').last()).toBeVisible();

    // Ambos aparecem na lista
    await expect(page.getByText(`R$ ${revenueValue}`)).toBeVisible();
    await expect(page.getByText(`R$ ${expenseValue}`)).toBeVisible();

    // Prestação de Contas reflete os lançamentos -- aba certa via query param (TASK-307)
    await page.goto('/reports?tab=prestacao');
    await page.getByRole('button', { name: 'Visualizar relatório' }).click();
    await expect(page.getByText('Receitas')).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText(`R$ ${revenueValue}`)).toBeVisible();
  });

  test('cancelar lançamento remove da lista ativa', async ({ page }) => {
    const value = uniqueCents(3000); // ~R$ 30,xx

    await loginViaUi(page, TENANT_D_OPERATING);
    await page.goto('/financeiro');

    await page.getByRole('button', { name: 'Nova receita' }).click();
    await page.locator('.modal-dialog select').selectOption('MULTA');
    await page.getByPlaceholder('0,00').fill(value);
    await page.getByRole('button', { name: 'Lançar' }).click();
    await expect(page.getByText('Lançamento criado com sucesso!').last()).toBeVisible();

    const row = page.locator('tr', { hasText: `R$ ${value}` });
    await row.getByRole('button', { name: 'Cancelar' }).click();
    await page.locator('.modal-dialog textarea').fill('Lançado em duplicidade por engano');
    await page.getByRole('button', { name: 'Confirmar cancelamento' }).click();

    await expect(page.getByText('Lançamento cancelado.')).toBeVisible();
    await expect(page.locator('tr', { hasText: `R$ ${value}` })).toHaveCount(0);
  });
});
