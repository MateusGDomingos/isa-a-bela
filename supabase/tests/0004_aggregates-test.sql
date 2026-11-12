begin;
\ir helpers.sql
select plan(9);

select test_create_user('11111111-1111-1111-1111-111111111111', 'isa@exemplo.com');
select test_create_user('22222222-2222-2222-2222-222222222222', 'outra@exemplo.com');

select test_login_as('11111111-1111-1111-1111-111111111111');

insert into public.transactions (user_id, kind, amount_cents, description, category_id, occurred_on)
select '11111111-1111-1111-1111-111111111111', 'income', 520000, 'Salário',
       (select id from public.categories where name = 'Salário'), '2026-11-05';

insert into public.transactions (user_id, kind, amount_cents, description, category_id, occurred_on)
select '11111111-1111-1111-1111-111111111111', 'expense', 15000, 'Mercado',
       (select id from public.categories where name = 'Alimentação'), '2026-11-06';

insert into public.transactions (user_id, kind, amount_cents, description, category_id, occurred_on)
select '11111111-1111-1111-1111-111111111111', 'expense', 5000, 'Padaria',
       (select id from public.categories where name = 'Alimentação'), '2026-11-07';

-- Estes três PRECISAM ter categoria, e não pode ser 'Alimentação'. É o que mantém os
-- baldes da pizza distintos depois da exclusão mais abaixo: 'Sem categoria' fica com os
-- 20000 cuja categoria foi excluída, e 'Compras' com os 15000 que seguem categorizados.
-- Sem categoria aqui, tudo desaba num balde único de 35000 e a asserção deixa de provar
-- que o valor da categoria excluída sobreviveu — ela passaria pelo motivo errado.
insert into public.transactions (user_id, kind, amount_cents, description, category_id,
                                 occurred_on, latitude, longitude, place_name)
values
  ('11111111-1111-1111-1111-111111111111', 'expense', 8900, 'Compra grande',
   (select id from public.categories where name = 'Compras' and kind = 'expense'),
   '2026-11-06', -21.7587, -43.3496, 'Supermercado Bahamas'),
  ('11111111-1111-1111-1111-111111111111', 'expense', 2100, 'Compra pequena',
   (select id from public.categories where name = 'Compras' and kind = 'expense'),
   '2026-11-20', -21.7589, -43.3498, 'Supermercado Bahamas'),
  ('11111111-1111-1111-1111-111111111111', 'expense', 4000, 'Farmácia',
   (select id from public.categories where name = 'Compras' and kind = 'expense'),
   '2026-11-10', -21.7600, -43.3500, 'Drogaria Central');

-- monthly_totals
select is(
  (select count(*)::int from public.monthly_totals('2026-11-15'::date, 6)),
  6, 'devolve seis linhas mesmo com lançamentos em um único mês'
);

select is(
  (select income_cents from public.monthly_totals('2026-11-15'::date, 6)
    where month = '2026-11-01'),
  520000::bigint, 'soma os ganhos do mês'
);

select is(
  (select expense_cents from public.monthly_totals('2026-11-15'::date, 6)
    where month = '2026-11-01'),
  35000::bigint, 'soma todos os gastos do mês, com e sem local'
);

select is(
  (select expense_cents from public.monthly_totals('2026-11-15'::date, 6)
    where month = '2026-09-01'),
  0::bigint, 'mês sem lançamento devolve zero, não linha ausente'
);

select is(
  (select min(month) from public.monthly_totals('2026-11-15'::date, 6)),
  '2026-06-01'::date, 'o intervalo começa cinco meses antes do mês informado'
);

-- expenses_by_category com categoria excluída
delete from public.categories where name = 'Alimentação' and kind = 'expense';

select is(
  (select total_cents from public.expenses_by_category('2026-11-01')
    where name = 'Sem categoria'),
  20000::bigint, 'gastos de categoria excluída somam em "Sem categoria"'
);

select is(
  (select sum(total_cents)::bigint from public.expenses_by_category('2026-11-01')),
  35000::bigint, 'a pizza soma o mesmo total de gastos do mês'
);

-- spending_by_place
select results_eq(
  $$ select place_name, total_cents, entries
       from public.spending_by_place('2026-11-01') $$,
  $$ values ('Supermercado Bahamas'::text, 11000::bigint, 2),
            ('Drogaria Central'::text, 4000::bigint, 1) $$,
  'agrupa por lugar, soma os valores e ordena do maior para o menor'
);

-- isolamento: os agregados respeitam a RLS
select test_logout();
select test_login_as('22222222-2222-2222-2222-222222222222');

select is(
  (select sum(income_cents + expense_cents)::bigint from public.monthly_totals('2026-11-15'::date, 6)),
  0::bigint, 'a outra pessoa recebe zeros, não os números alheios'
);

select * from finish();
rollback;
