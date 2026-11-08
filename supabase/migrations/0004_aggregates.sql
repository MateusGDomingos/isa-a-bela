-- Devolve SEMPRE uma linha por mês do intervalo, inclusive meses sem lançamento,
-- para o gráfico de barras não perder meses e desalinhar os rótulos.
create or replace function public.monthly_totals(end_month date, months integer default 6)
returns table (month date, income_cents bigint, expense_cents bigint)
language sql
stable
security invoker
set search_path = public
as $$
  with limites as (
    select
      date_trunc('month', end_month)::date as ultimo,
      (date_trunc('month', end_month)
        - make_interval(months => least(greatest(months, 1), 24) - 1))::date as primeiro
  ),
  meses as (
    select generate_series(
      (select primeiro from limites),
      (select ultimo from limites),
      interval '1 month'
    )::date as month
  )
  select
    m.month,
    coalesce(sum(t.amount_cents) filter (where t.kind = 'income'), 0)::bigint,
    coalesce(sum(t.amount_cents) filter (where t.kind = 'expense'), 0)::bigint
  from meses m
  left join public.transactions t
    on date_trunc('month', t.occurred_on)::date = m.month
  group by m.month
  order by m.month;
$$;

-- Lançamento cuja categoria foi excluída tem category_id nulo e precisa continuar
-- somando no total do mês, exibido como "Sem categoria".
create or replace function public.expenses_by_category(p_month date)
returns table (category_id uuid, name text, color text, total_cents bigint)
language sql
stable
security invoker
set search_path = public
as $$
  select
    c.id,
    coalesce(c.name, 'Sem categoria'),
    coalesce(c.color, '#C7C2CB'),
    sum(t.amount_cents)::bigint
  from public.transactions t
  left join public.categories c on c.id = t.category_id
  where t.kind = 'expense'
    and date_trunc('month', t.occurred_on) = date_trunc('month', p_month)
  group by c.id, c.name, c.color
  order by 4 desc, 2 asc;
$$;

create or replace function public.spending_by_place(p_month date)
returns table (
  place_name text,
  total_cents bigint,
  entries integer,
  latitude numeric,
  longitude numeric
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    t.place_name,
    sum(t.amount_cents)::bigint,
    count(*)::integer,
    round(avg(t.latitude), 6),
    round(avg(t.longitude), 6)
  from public.transactions t
  where t.kind = 'expense'
    and t.place_name is not null
    and t.latitude is not null
    and date_trunc('month', t.occurred_on) = date_trunc('month', p_month)
  group by t.place_name
  order by 2 desc
  limit 50;
$$;
