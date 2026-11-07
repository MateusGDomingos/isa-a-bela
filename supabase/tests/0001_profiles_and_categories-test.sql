begin;
\ir helpers.sql
select plan(14);

select test_create_user('11111111-1111-1111-1111-111111111111', 'isa@exemplo.com');
select test_create_user('22222222-2222-2222-2222-222222222222', 'outra@exemplo.com');
select test_create_user('33333333-3333-3333-3333-333333333333', 'visitante@exemplo.com', true);

-- gatilho de conta nova
select is(
  (select count(*)::int from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  1, 'criar usuário cria o perfil'
);
select is(
  (select name from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'isa', 'o nome vem dos metadados do usuário'
);
select is(
  (select is_guest from public.profiles where id = '33333333-3333-3333-3333-333333333333'),
  true, 'usuário anônimo nasce marcado como visitante'
);
select is(
  (select is_admin from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  false, 'ninguém nasce administrador'
);
select is(
  (select count(*)::int from public.categories
    where user_id = '11111111-1111-1111-1111-111111111111'),
  13, 'conta nova recebe as 13 categorias padrão'
);
select is(
  (select count(*)::int from public.categories
    where user_id = '11111111-1111-1111-1111-111111111111' and kind = 'income'),
  4, 'quatro categorias de ganho'
);

-- RLS: isolamento entre usuários
select test_login_as('11111111-1111-1111-1111-111111111111');

select is(
  (select count(*)::int from public.profiles),
  1, 'cada pessoa só vê o próprio perfil'
);
select is(
  (select count(*)::int from public.categories),
  13, 'cada pessoa só vê as próprias categorias'
);

select lives_ok(
  $$ insert into public.categories (user_id, name, kind, color)
     values ('11111111-1111-1111-1111-111111111111', 'Pets', 'expense', '#AABBCC') $$,
  'dá para criar categoria própria'
);

select throws_ok(
  $$ insert into public.categories (user_id, name, kind, color)
     values ('22222222-2222-2222-2222-222222222222', 'Invasora', 'expense', '#AABBCC') $$,
  '42501', null, 'a RLS recusa criar categoria no nome de outra pessoa'
);

with alteradas as (
  update public.categories set name = 'Mudou'
  where user_id = '22222222-2222-2222-2222-222222222222' returning 1
)
select is(
  (select count(*)::int from alteradas),
  0, 'update não alcança categoria de outra pessoa'
);

with apagadas as (
  delete from public.categories
  where user_id = '22222222-2222-2222-2222-222222222222' returning 1
)
select is(
  (select count(*)::int from apagadas),
  0, 'delete não alcança categoria de outra pessoa'
);

-- validações de dados
select throws_ok(
  $$ insert into public.categories (user_id, name, kind, color)
     values ('11111111-1111-1111-1111-111111111111', '   ', 'expense', '#AABBCC') $$,
  '23514', null, 'nome só com espaços é recusado'
);

select throws_ok(
  $$ insert into public.categories (user_id, name, kind, color)
     values ('11111111-1111-1111-1111-111111111111', 'Cor ruim', 'expense', 'rosa') $$,
  '23514', null, 'cor fora do formato hexadecimal é recusada'
);

select * from finish();
rollback;
