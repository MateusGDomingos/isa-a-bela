begin;
\ir helpers.sql
select plan(9);

-- conta comum não recebe dados de exemplo
select test_create_user('11111111-1111-1111-1111-111111111111', 'isa@exemplo.com');
select is(
  (select count(*)::int from public.transactions
    where user_id = '11111111-1111-1111-1111-111111111111'),
  0, 'conta comum nasce vazia'
);

-- visitante recebe
select test_create_user('33333333-3333-3333-3333-333333333333', 'visitante@exemplo.com', true);

select is(
  (select count(*)::int from public.transactions
    where user_id = '33333333-3333-3333-3333-333333333333'),
  42, 'visitante nasce com seis meses de lançamentos (7 por mês)'
);

select is(
  (select count(distinct date_trunc('month', occurred_on))::int from public.transactions
    where user_id = '33333333-3333-3333-3333-333333333333'),
  6, 'os lançamentos cobrem seis meses distintos'
);

select is(
  (select count(*)::int from public.transactions
    where user_id = '33333333-3333-3333-3333-333333333333' and place_name is not null),
  12, 'parte dos gastos tem local, para o mapa ter conteúdo'
);

select ok(
  (select count(*) from public.transactions
    where user_id = '33333333-3333-3333-3333-333333333333'
      and date_trunc('month', occurred_on) = date_trunc('month', current_date)) > 0,
  'há lançamentos no mês corrente'
);

select is(
  (select count(*)::int from public.tasks
    where user_id = '33333333-3333-3333-3333-333333333333' and not done
      and due_date < current_date),
  1, 'existe exatamente uma tarefa atrasada no exemplo'
);

select ok(
  (select count(*) from public.appointments
    where user_id = '33333333-3333-3333-3333-333333333333'
      and starts_at > now()) >= 2,
  'há compromissos futuros para a tela Início mostrar'
);

-- retenção
select is(public.delete_stale_guests(7), 0, 'visitante recém-criado não é apagado');

update auth.users set created_at = now() - interval '8 days'
 where id = '33333333-3333-3333-3333-333333333333';

select is(public.delete_stale_guests(7), 1, 'visitante com mais de 7 dias é apagado');

select * from finish();
rollback;
