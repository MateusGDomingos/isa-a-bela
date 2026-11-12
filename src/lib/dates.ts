export type DayGroup<T> = { day: string; items: T[] };

const pad = (value: number): string => String(value).padStart(2, '0');

/** Data no calendário local. Nunca use toISOString() para isso: ele converte para UTC. */
export function toISODate(date: Date): string {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

const MONTH_LABEL = new Intl.DateTimeFormat('pt-BR', { month: 'long', year: 'numeric' });

export function monthLabel(date: Date): string {
  // O Intl do pt-BR devolve "novembro de 2026"; a interface usa sem o "de".
  return MONTH_LABEL.format(date).replace(' de ', ' ');
}

export function monthBounds(date: Date): { first: string; last: string } {
  const first = new Date(date.getFullYear(), date.getMonth(), 1);
  const last = new Date(date.getFullYear(), date.getMonth() + 1, 0);
  return { first: toISODate(first), last: toISODate(last) };
}

/**
 * Anda `delta` meses e devolve o PRIMEIRO dia do mês destino.
 * Manter o dia original faria 31/01 + 1 mês virar 03/03, porque o Date
 * normaliza o excesso para o mês seguinte. O seletor de mês da aba
 * Finanças só se interessa pelo mês, então o dia 1 é a resposta correta.
 */
export function shiftMonth(date: Date, delta: number): Date {
  return new Date(date.getFullYear(), date.getMonth() + delta, 1);
}

export function groupByDay<T>(items: T[], getISODate: (item: T) => string): DayGroup<T>[] {
  const buckets = new Map<string, T[]>();
  for (const item of items) {
    const day = getISODate(item);
    const bucket = buckets.get(day);
    if (bucket) bucket.push(item);
    else buckets.set(day, [item]);
  }
  return [...buckets.entries()]
    .sort(([a], [b]) => (a < b ? 1 : a > b ? -1 : 0))
    .map(([day, grouped]) => ({ day, items: grouped }));
}

export function isOverdue(dueDate: string | null, today: Date): boolean {
  if (!dueDate) return false;
  return dueDate < toISODate(today);
}

export function reminderInstant(startsAtISO: string, minutesBefore: number): Date {
  return new Date(new Date(startsAtISO).getTime() - minutesBefore * 60_000);
}
