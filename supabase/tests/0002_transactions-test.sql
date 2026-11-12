begin;
\ir helpers.sql
select plan(13);

select test_create_user('11111111-1111-1111-1111-111111111111', 'isa@exemplo.com');
select test_create_user('22222222-2222-2222-2222-222222222222', 'outra@exemplo.com');

-- guarda o id de uma categoria de cada pessoa
create temporary table ids as
select
  (select id from public.categories
     where user_id = '11111111-1111-1111-1111-111111111111'
       and name = 'Alimentação') as cat_isa,
  (select id from public.categories
     where user_id = '22222222-2222-2222-2222-222222222222'
       and name = 'Alimentação') as cat_outra;

-- a tabela temporária pertence a quem a criou (postgres); sem o grant, o
-- select role authenticated não consegue nem ler os ids depois do login
grant select on ids to authenticated;

select test_login_as('11111111-1111-1111-1111-111111111111');

select lives_ok(
  format(
    $$ insert into public.transactions
         (user_id, kind, amount_cents, description, category_id, occurred_on)
       values ('11111111-1111-1111-1111-111111111111', 'expense', 4550,
               'Açaí 🍧', %L, '2026-11-06') $$,
    (select cat_isa from ids)
  ),
  'aceita descrição com acento e emoji'
);

select throws_ok(
  format(
    $$ insert into public.transactions
         (user_id, kind, amount_cents, description, category_id, occurred_on)
       values ('11111111-1111-1111-1111-111111111111', 'expense', 1000,
               'Invasor', %L, '2026-11-06') $$,
    (select cat_outra from ids)
  ),
  '42501', null, 'recusa lançamento apontando para categoria de outra pessoa'
);

select throws_ok(
  $$ insert into public.transactions
       (user_id, kind, amount_cents, description, occurred_on)
     values ('22222222-2222-2222-2222-222222222222', 'expense', 1000, 'Alheio', '2026-11-06') $$,
  '42501', null, 'recusa lançamento no nome de outra pessoa'
);

select throws_ok(
  $$ insert into public.transactions
       (user_id, kind, amount_cents, description, occurred_on)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 0, 'Zero', '2026-11-06') $$,
  '23514', null, 'recusa valor zero'
);

select throws_ok(
  $$ insert into public.transactions
       (user_id, kind, amount_cents, description, occurred_on)
     values ('11111111-1111-1111-1111-111111111111', 'expense', -500, 'Negativo', '2026-11-06') $$,
  '23514', null, 'recusa valor negativo'
);

select throws_ok(
  $$ insert into public.transactions
       (user_id, kind, amount_cents, description, occurred_on)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 100, '   ', '2026-11-06') $$,
  '23514', null, 'recusa descrição só com espaços'
);

select throws_ok(
  $$ insert into public.transactions
       (user_id, kind, amount_cents, description, occurred_on)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 100,
             repeat('a', 121), '2026-11-06') $$,
  '23514', null, 'recusa descrição com 121 caracteres'
);

select lives_ok(
  $$ insert into public.transactions
       (user_id, kind, amount_cents, description, occurred_on)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 100,
             repeat('a', 120), '2026-11-06') $$,
  'aceita descrição com exatamente 120 caracteres'
);

select throws_ok(
  $$ insert into public.transactions
       (user_id, kind, amount_cents, description, occurred_on, latitude)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 100,
             'Meia coordenada', '2026-11-06', -21.75) $$,
  '23514', null, 'recusa latitude sem longitude'
);

select lives_ok(
  $$ insert into public.transactions
       (user_id, kind, amount_cents, description, occurred_on, latitude, longitude, place_name)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 8900,
             'Mercado', '2026-11-06', -21.7587, -43.3496, 'Supermercado Bahamas') $$,
  'aceita o par completo de coordenadas com nome do lugar'
);

select throws_ok(
  $$ insert into public.transactions
       (user_id, kind, amount_cents, description, occurred_on, latitude, longitude)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 100,
             'Fora do mundo', '2026-11-06', 120, 0) $$,
  '23514', null, 'recusa latitude fora da faixa'
);

-- excluir categoria preserva o lançamento
select lives_ok(
  format($$ delete from public.categories where id = %L $$, (select cat_isa from ids)),
  'dá para excluir a própria categoria'
);

select is(
  (select count(*)::int from public.transactions where description = 'Açaí 🍧' and category_id is null),
  1, 'excluir categoria mantém o lançamento com categoria nula'
);

select * from finish();
rollback;
