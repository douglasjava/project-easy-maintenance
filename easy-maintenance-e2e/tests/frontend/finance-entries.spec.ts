import { test, expect } from '@playwright/test';
import { TENANT_D_OPERATING } from '../../fixtures/tenant';
import { loginViaUi } from '../../helpers/frontend-login';

// EPIC-032: fluxo completo do módulo financeiro -- lançar receita, lançar despesa, ver refletido
// na lista e na Prestação de Contas, cancelar um lançamento e confirmar que some do saldo.
// Depende de uma API/MySQL e2e rodando (mesmo requisito dos demais specs de frontend/).
test.describe.configure({ mode: 'serial' });

test.describe('Financeiro — EPIC-032', () => {
  test('cria receita e despesa, reflete na lista e na Prestação de Contas', async ({ page }) => {
    await loginViaUi(page, TENANT_D_OPERATING);
    await page.goto('/financeiro');

    await expect(page.getByRole('heading', { name: 'Financeiro' })).toBeVisible({ timeout: 15_000 });

    // Lança receita
    await page.getByRole('button', { name: 'Nova receita' }).click();
    await page.locator('select').first().selectOption('TAXA_CONDOMINIAL');
    await page.getByPlaceholder('0,00').fill('500,00');
    await page.getByRole('button', { name: 'Lançar' }).click();
    await expect(page.getByText('Lançamento criado com sucesso!')).toBeVisible();

    // Lança despesa
    await page.getByRole('button', { name: 'Nova despesa' }).click();
    await page.locator('select').first().selectOption('CONTA_CONSUMO');
    await page.getByPlaceholder('0,00').fill('80,00');
    await page.getByRole('button', { name: 'Lançar' }).click();
    await expect(page.getByText('Lançamento criado com sucesso!')).toBeVisible();

    // Ambos aparecem na lista
    await expect(page.getByText('R$ 500,00')).toBeVisible();
    await expect(page.getByText('R$ 80,00')).toBeVisible();

    // Prestação de Contas reflete o saldo
    await page.goto('/reports');
    await page.getByRole('button', { name: 'Visualizar relatório' }).click();
    await expect(page.getByText('Receitas')).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText('R$ 500,00')).toBeVisible();
  });

  test('cancelar lançamento remove da lista ativa', async ({ page }) => {
    await loginViaUi(page, TENANT_D_OPERATING);
    await page.goto('/financeiro');

    await page.getByRole('button', { name: 'Nova receita' }).click();
    await page.locator('select').first().selectOption('MULTA');
    await page.getByPlaceholder('0,00').fill('30,00');
    await page.getByRole('button', { name: 'Lançar' }).click();
    await expect(page.getByText('Lançamento criado com sucesso!')).toBeVisible();

    const row = page.locator('tr', { hasText: 'R$ 30,00' });
    await row.getByRole('button', { name: 'Cancelar' }).click();
    await page.getByRole('textbox').last().fill('Lançado em duplicidade por engano');
    await page.getByRole('button', { name: 'Confirmar cancelamento' }).click();

    await expect(page.getByText('Lançamento cancelado.')).toBeVisible();
    await expect(page.locator('tr', { hasText: 'R$ 30,00' })).toHaveCount(0);
  });
});
