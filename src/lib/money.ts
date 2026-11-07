const BRL = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
  minimumFractionDigits: 2,
});

/** Formata centavos inteiros como moeda brasileira. */
export function formatBRL(cents: number): string {
  // O Intl do pt-BR separa "R$" do número com espaço rígido (U+00A0) e produz
  // "-R$ 25,00" para negativos, que é o formato desejado. O replace troca o
  // espaço rígido pelo espaço comum que a interface e os testes esperam.
  return BRL.format(cents / 100).replace(/\u00a0/g, ' ');
}

/**
 * Converte o texto digitado em centavos inteiros.
 * Devolve null para qualquer entrada que não represente um valor positivo.
 *
 * Regra do separador: o último "," é sempre decimal. Um "." só é decimal
 * quando não houver "," e os dígitos depois dele não forem exatamente 3
 * (porque "1.234" no Brasil significa mil duzentos e trinta e quatro).
 */
export function parseAmountToCents(input: string): number | null {
  // \s não cobre o espaço rígido em todo runtime, então U+00A0 entra explícito.
  const cleaned = input.replace(/[\s\u00a0]/g, '').replace(/^R\$/i, '');
  if (!/^[0-9.,]+$/.test(cleaned)) return null;

  const hasComma = cleaned.includes(',');
  let integerPart: string;
  let decimalPart: string;

  if (hasComma) {
    const [head, ...rest] = cleaned.split(',');
    if (rest.length !== 1) return null;
    integerPart = (head ?? '').replace(/\./g, '');
    decimalPart = rest[0] ?? '';
  } else {
    const dots = cleaned.split('.');
    const last = dots.length > 1 ? (dots[dots.length - 1] ?? '') : '';
    const looksLikeThousands = dots.length > 1 && last.length === 3;
    if (dots.length > 1 && !looksLikeThousands) {
      integerPart = dots.slice(0, -1).join('');
      decimalPart = last;
    } else {
      integerPart = cleaned.replace(/\./g, '');
      decimalPart = '';
    }
  }

  if (!/^[0-9]+$/.test(integerPart)) return null;
  if (decimalPart !== '' && !/^[0-9]{1,2}$/.test(decimalPart)) return null;

  const cents = Number(integerPart) * 100 + Number(decimalPart.padEnd(2, '0') || '0');
  if (!Number.isSafeInteger(cents) || cents <= 0) return null;
  return cents;
}

export function sumCents(values: number[]): number {
  return values.reduce((total, value) => total + value, 0);
}
