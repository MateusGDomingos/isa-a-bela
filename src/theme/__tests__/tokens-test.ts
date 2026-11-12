import { colors, fonts, radii, spacing } from '@/src/theme/tokens';

describe('tokens do tema Rosa Elegante', () => {
  it('traz exatamente as cores aprovadas na spec', () => {
    expect(colors.background).toBe('#FFF6F8');
    expect(colors.surface).toBe('#FFFFFF');
    expect(colors.line).toBe('#F4DFE6');
    expect(colors.accent).toBe('#C2456E');
    expect(colors.accentSoft).toBe('#FBE1E9');
    expect(colors.text).toBe('#3B1F2B');
    expect(colors.textMuted).toBe('#9A7482');
    expect(colors.balanceGradient).toEqual(['#EB7A9C', '#C2456E']);
  });

  it('usa Playfair itálico só para o nome e Inter para o resto', () => {
    expect(fonts.brand).toBe('PlayfairDisplay_600SemiBold_Italic');
    expect(fonts.body).toBe('Inter_400Regular');
    expect(fonts.bodyStrong).toBe('Inter_600SemiBold');
  });

  it('tem o raio 24 do rodapé flutuante', () => {
    expect(radii.tabBar).toBe(24);
  });

  it('usa escala de espaçamento múltipla de 4', () => {
    for (const value of Object.values(spacing)) {
      expect(value % 4).toBe(0);
    }
  });

  // Object.values() passa mesmo se uma chave nomeada desaparecer; as Tarefas 5 e 6
  // dependem dos NOMES, então eles precisam de asserção própria.
  it('expõe as chaves de espaçamento e raio que as telas consomem', () => {
    for (const key of ['xs', 'sm', 'md', 'lg', 'xl', 'xxl'] as const) {
      expect(spacing[key]).toBeGreaterThan(0);
    }
    for (const key of ['card', 'item', 'tabBar', 'pill'] as const) {
      expect(radii[key]).toBeGreaterThan(0);
    }
  });

  it('expõe as cores que os ícones e os componentes base consomem', () => {
    for (const key of [
      'background',
      'surface',
      'line',
      'accent',
      'accentSoft',
      'text',
      'textMuted',
      'danger',
      'income',
      'expense',
      'noCategory',
    ] as const) {
      expect(colors[key]).toMatch(/^#[0-9A-Fa-f]{6}$/);
    }
  });
});
