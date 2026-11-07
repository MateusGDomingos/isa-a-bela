import { isOverdue } from '@/src/lib/dates';

export type OrderableTask = { due_date: string | null; created_at: string };

/** 1) atrasadas 2) com prazo, mais próximo primeiro 3) sem prazo, mais antiga primeiro. */
export function sortPendingTasks<T extends OrderableTask>(tasks: T[], today: Date): T[] {
  const rank = (task: T): number => {
    if (isOverdue(task.due_date, today)) return 0;
    return task.due_date ? 1 : 2;
  };

  return [...tasks].sort((a, b) => {
    const rankDiff = rank(a) - rank(b);
    if (rankDiff !== 0) return rankDiff;
    if (a.due_date && b.due_date && a.due_date !== b.due_date) {
      return a.due_date < b.due_date ? -1 : 1;
    }
    return a.created_at < b.created_at ? -1 : a.created_at > b.created_at ? 1 : 0;
  });
}
