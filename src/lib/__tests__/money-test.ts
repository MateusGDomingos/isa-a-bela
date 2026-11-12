import { formatBRL, parseAmountToCents, sumCents } from '@/src/lib/money';

describe('formatBRL', () => {
  it('formata centavos no padrão brasileiro', () => {
    expect(formatBRL(123456)).toBe('R$ 1.234,56');
    expect(formatBRL(0)).toBe('R$ 0,00');
    expect(formatBRL(5)).toBe('R$ 0,05');
    expect(formatBRL(100000000)).toBe('R$ 1.000.000,00');
  });

  it('mostra valor negativo com o sinal antes do símbolo', () => {
    expect(formatBRL(-2500)).toBe('-R$ 25,00');
  });
});

describe('parseAmountToCents', () => {
  it('aceita o formato que sai do teclado brasileiro', () => {
    expect(parseAmountToCents('1.234,56')).toBe(123456);
    expect(parseAmountToCents('1234,56')).toBe(123456);
    expect(parseAmountToCents('R$ 12,00')).toBe(1200);
    expect(parseAmountToCents('12')).toBe(1200);
    expect(parseAmountToCents('12,5')).toBe(1250);
    expect(parseAmountToCents('0,05')).toBe(5);
  });

  it('trata ponto como separador de milhar quando vem com 3 dígitos', () => {
    expect(parseAmountToCents('1.234')).toBe(123400);
    expect(parseAmountToCents('1.234.567')).toBe(123456700);
  });

  it('aceita ponto como decimal quando não parece milhar', () => {
    expect(parseAmountToCents('12.5')).toBe(1250);
    expect(parseAmountToCents('12.50')).toBe(1250);
  });

  it('recusa entrada inválida em vez de devolver NaN', () => {
    expect(parseAmountToCents('')).toBeNull();
    expect(parseAmountToCents('   ')).toBeNull();
    expect(parseAmountToCents('abc')).toBeNull();
    expect(parseAmountToCents('R$')).toBeNull();
    expect(parseAmountToCents('-5')).toBeNull();
    expect(parseAmountToCents('0')).toBeNull();
    expect(parseAmountToCents('0,00')).toBeNull();
    expect(parseAmountToCents('1,234')).toBeNull();
  });

  it('ignora espaço comum e espaço rígido colados do navegador', () => {
    expect(parseAmountToCents('R$ 1.234,56')).toBe(123456);
    expect(parseAmountToCents('R$ \u00a01.234,56')).toBe(123456);
  });

  it('recusa valor que não cabe na coluna do banco', () => {
    expect(parseAmountToCents('21474836,47')).toBe(2147483647);
    expect(parseAmountToCents('21474836,48')).toBeNull();
    expect(parseAmountToCents('99.999.999,99')).toBeNull();
  });
});

describe('sumCents', () => {
  it('soma sem erro de arredondamento', () => {
    expect(sumCents([10, 20])).toBe(30);
    expect(sumCents([])).toBe(0);
    expect(sumCents([1, 1, 1])).toBe(3);
  });
});
