import { sortPendingTasks } from '@/src/lib/tasks-order';

const hoje = new Date(2026, 10, 6, 10, 0, 0);

describe('sortPendingTasks', () => {
  it('coloca atrasadas primeiro, depois prazo mais próximo, depois sem prazo', () => {
    const tarefas = [
      { id: 'sem-prazo-nova', due_date: null, created_at: '2026-11-05T10:00:00Z' },
      { id: 'prazo-longe', due_date: '2026-12-01', created_at: '2026-11-01T10:00:00Z' },
      { id: 'atrasada', due_date: '2026-11-01', created_at: '2026-10-20T10:00:00Z' },
      { id: 'sem-prazo-antiga', due_date: null, created_at: '2026-10-01T10:00:00Z' },
      { id: 'prazo-hoje', due_date: '2026-11-06', created_at: '2026-11-06T10:00:00Z' },
    ];

    expect(sortPendingTasks(tarefas, hoje).map((t) => t.id)).toEqual([
      'atrasada',
      'prazo-hoje',
      'prazo-longe',
      'sem-prazo-antiga',
      'sem-prazo-nova',
    ]);
  });

  it('desempata duas atrasadas pela mais antiga', () => {
    const tarefas = [
      { id: 'b', due_date: '2026-11-04', created_at: '2026-11-01T10:00:00Z' },
      { id: 'a', due_date: '2026-11-02', created_at: '2026-11-01T10:00:00Z' },
    ];
    expect(sortPendingTasks(tarefas, hoje).map((t) => t.id)).toEqual(['a', 'b']);
  });

  it('não altera a lista recebida', () => {
    const tarefas = [
      { id: 'x', due_date: null, created_at: '2026-11-01T10:00:00Z' },
      { id: 'y', due_date: '2026-11-01', created_at: '2026-11-01T10:00:00Z' },
    ];
    const copia = [...tarefas];
    sortPendingTasks(tarefas, hoje);
    expect(tarefas).toEqual(copia);
  });
});
