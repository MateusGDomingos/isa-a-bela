import {
  groupByDay,
  isOverdue,
  monthBounds,
  monthLabel,
  reminderInstant,
  shiftMonth,
  toISODate,
} from '@/src/lib/dates';

describe('toISODate', () => {
  it('usa o calendário local, não o UTC', () => {
    // 23h30 de 06/11/2026 em Brasília (UTC-3) é 02h30 de 07/11 em UTC.
    // A pessoa lançou no dia 6 e espera ver no dia 6.
    const lateNight = new Date(2026, 10, 6, 23, 30, 0);
    expect(toISODate(lateNight)).toBe('2026-11-06');
  });

  it('preenche mês e dia com zero à esquerda', () => {
    expect(toISODate(new Date(2026, 0, 5))).toBe('2026-01-05');
  });
});

describe('monthLabel', () => {
  it('escreve o mês em português', () => {
    expect(monthLabel(new Date(2026, 10, 6))).toBe('novembro 2026');
    expect(monthLabel(new Date(2026, 2, 1))).toBe('março 2026');
  });
});

describe('monthBounds', () => {
  it('devolve o primeiro e o último dia do mês', () => {
    expect(monthBounds(new Date(2026, 10, 15))).toEqual({
      first: '2026-11-01',
      last: '2026-11-30',
    });
  });

  it('acerta fevereiro em ano bissexto', () => {
    expect(monthBounds(new Date(2028, 1, 10))).toEqual({
      first: '2028-02-01',
      last: '2028-02-29',
    });
  });
});

describe('shiftMonth', () => {
  it('devolve sempre o primeiro dia do mês destino', () => {
    expect(toISODate(shiftMonth(new Date(2026, 10, 30), 1))).toBe('2026-12-01');
    expect(toISODate(shiftMonth(new Date(2026, 0, 15), -1))).toBe('2025-12-01');
  });

  it('não estoura para o mês seguinte quando o dia não existe no destino', () => {
    // 31 de janeiro menos um mês não pode virar 3 de março
    expect(toISODate(shiftMonth(new Date(2026, 0, 31), 1))).toBe('2026-02-01');
  });
});

describe('groupByDay', () => {
  it('agrupa por dia, do mais recente para o mais antigo', () => {
    const items = [
      { id: 'a', on: '2026-11-05' },
      { id: 'b', on: '2026-11-06' },
      { id: 'c', on: '2026-11-05' },
    ];
    expect(groupByDay(items, (i) => i.on)).toEqual([
      { day: '2026-11-06', items: [{ id: 'b', on: '2026-11-06' }] },
      {
        day: '2026-11-05',
        items: [
          { id: 'a', on: '2026-11-05' },
          { id: 'c', on: '2026-11-05' },
        ],
      },
    ]);
  });

  it('devolve lista vazia para entrada vazia', () => {
    expect(groupByDay([], (i: { on: string }) => i.on)).toEqual([]);
  });
});

describe('isOverdue', () => {
  const hoje = new Date(2026, 10, 6, 14, 0, 0);

  it('considera atrasado só o prazo anterior a hoje', () => {
    expect(isOverdue('2026-11-05', hoje)).toBe(true);
    expect(isOverdue('2026-11-06', hoje)).toBe(false);
    expect(isOverdue('2026-11-07', hoje)).toBe(false);
  });

  it('tarefa sem prazo nunca está atrasada', () => {
    expect(isOverdue(null, hoje)).toBe(false);
  });
});

describe('reminderInstant', () => {
  it('subtrai os minutos do início do compromisso', () => {
    const resultado = reminderInstant('2026-11-08T14:30:00.000Z', 30);
    expect(resultado.toISOString()).toBe('2026-11-08T14:00:00.000Z');
  });

  it('aceita um dia antes', () => {
    const resultado = reminderInstant('2026-11-08T14:30:00.000Z', 1440);
    expect(resultado.toISOString()).toBe('2026-11-07T14:30:00.000Z');
  });
});
