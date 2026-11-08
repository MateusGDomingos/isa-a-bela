begin;
\ir helpers.sql
select plan(10);

select test_create_user('11111111-1111-1111-1111-111111111111', 'isa@exemplo.com');
select test_create_user('22222222-2222-2222-2222-222222222222', 'outra@exemplo.com');

select test_login_as('22222222-2222-2222-2222-222222222222');
insert into public.tasks (user_id, title)
values ('22222222-2222-2222-2222-222222222222', 'Tarefa da outra pessoa');

select test_logout();
select test_login_as('11111111-1111-1111-1111-111111111111');

insert into public.transactions (user_id, kind, amount_cents, description, occurred_on,
                                 latitude, longitude, place_name)
values ('11111111-1111-1111-1111-111111111111', 'expense', 8900, 'Mercado', '2026-11-06',
        -21.7587, -43.3496, 'Supermercado Bahamas');
insert into public.transactions (user_id, kind, amount_cents, description, occurred_on)
values ('11111111-1111-1111-1111-111111111111', 'expense', 1000, 'Sem local', '2026-11-06');
insert into public.tasks (user_id, title)
values ('11111111-1111-1111-1111-111111111111', 'Minha tarefa');
insert into public.appointments (user_id, title, starts_at)
values ('11111111-1111-1111-1111-111111111111', 'Meu compromisso', '2026-11-08 10:00-03');

-- exportação
select is(
  jsonb_array_length(public.export_my_data() -> 'transactions'),
  2, 'a exportação traz os dois lançamentos do titular'
);

select is(
  jsonb_array_length(public.export_my_data() -> 'tasks'),
  1, 'a exportação não traz a tarefa da outra pessoa'
);

select is(
  jsonb_array_length(public.export_my_data() -> 'categories'),
  13, 'a exportação traz as categorias'
);

select isnt(
  public.export_my_data() -> 'profile',
  null, 'a exportação traz o perfil'
);

-- apagar locais
select is(public.erase_my_places(), 1, 'limpa apenas o lançamento que tinha local');

select is(
  (select count(*)::int from public.transactions
    where latitude is not null or place_name is not null),
  0, 'não sobrou nenhuma coordenada nem nome de lugar'
);

select is(
  (select sum(amount_cents)::int from public.transactions),
  9900, 'os valores financeiros continuam intactos'
);

select is(
  (select location_consent from public.profiles where id = auth.uid()),
  false, 'apagar os locais também desliga o consentimento'
);

-- excluir conta
select lives_ok(
  $$ select public.delete_my_account() $$,
  'o titular consegue excluir a própria conta'
);

select test_logout();

select is(
  (select count(*)::int from public.transactions
    where user_id = '11111111-1111-1111-1111-111111111111')
  + (select count(*)::int from public.tasks
    where user_id = '11111111-1111-1111-1111-111111111111')
  + (select count(*)::int from public.appointments
    where user_id = '11111111-1111-1111-1111-111111111111')
  + (select count(*)::int from public.categories
    where user_id = '11111111-1111-1111-1111-111111111111')
  + (select count(*)::int from public.profiles
    where id = '11111111-1111-1111-1111-111111111111'),
  0, 'excluir a conta apaga perfil, categorias, lançamentos, tarefas e compromissos'
);

select * from finish();
rollback;
