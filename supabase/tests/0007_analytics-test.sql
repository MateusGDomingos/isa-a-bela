begin;
\ir helpers.sql
select plan(10);

select test_create_user('11111111-1111-1111-1111-111111111111', 'isa@exemplo.com');
select test_create_user('99999999-9999-9999-9999-999999999999', 'admin@exemplo.com');
update public.profiles set is_admin = true where id = '99999999-9999-9999-9999-999999999999';

insert into public.analytics_events (user_id, event_type, detail, city, region, occurred_on)
values
  ('11111111-1111-1111-1111-111111111111', 'app_open', null, 'Juiz de Fora', 'MG', current_date - 1),
  ('11111111-1111-1111-1111-111111111111', 'tab_view', 'financas', 'Juiz de Fora', 'MG', current_date - 1),
  ('11111111-1111-1111-1111-111111111111', 'tab_view', 'financas', 'Juiz de Fora', 'MG', current_date - 1),
  ('99999999-9999-9999-9999-999999999999', 'app_open', null, 'Belo Horizonte', 'MG', current_date - 1),
  ('11111111-1111-1111-1111-111111111111', 'app_open', null, 'Juiz de Fora', 'MG', current_date - 200);

-- a tabela de eventos é fechada para o app
select test_login_as('11111111-1111-1111-1111-111111111111');
select is(
  (select count(*)::int from public.analytics_events),
  0, 'usuário comum não lê nenhum evento'
);
select throws_ok(
  $$ insert into public.analytics_events (user_id, event_type)
     values ('11111111-1111-1111-1111-111111111111', 'app_open') $$,
  '42501', null, 'o app não escreve direto na tabela de eventos'
);

select test_logout();
select test_login_as('99999999-9999-9999-9999-999999999999');
select is(
  (select count(*)::int from public.analytics_events),
  0, 'nem o administrador lê os eventos individuais'
);

select test_logout();

-- consolidação
select is(public.rollup_analytics(current_date - 1), 3, 'consolida em três combinações');

select is(
  (select total from public.analytics_daily
    where event_type = 'tab_view' and detail = 'financas' and city = 'Juiz de Fora'),
  2, 'soma as duas visitas à aba Finanças'
);

select test_login_as('99999999-9999-9999-9999-999999999999');
select is(
  (select count(*)::int from public.analytics_daily),
  3, 'o administrador lê o painel agregado'
);
select hasnt_column('public', 'analytics_daily', 'user_id',
  'o painel agregado não tem coluna de usuário');
select test_logout();

-- Esta asserção precisa vir DEPOIS do rollup. Antes dele a tabela está vazia, e a
-- verificação passaria mesmo que a política de admin não existisse — provaria apenas
-- que uma tabela vazia tem zero linhas.
select test_login_as('11111111-1111-1111-1111-111111111111');
select is(
  (select count(*)::int from public.analytics_daily),
  0, 'usuário sem is_admin não lê o painel, nem com o painel populado'
);
select test_logout();

-- retenção e revogação
select is(public.purge_old_analytics(90), 1, 'apaga o evento com mais de 90 dias');

select test_login_as('11111111-1111-1111-1111-111111111111');
select is(public.erase_my_analytics(), 3, 'revogar apaga os três eventos do titular');
select test_logout();

select * from finish();
rollback;
