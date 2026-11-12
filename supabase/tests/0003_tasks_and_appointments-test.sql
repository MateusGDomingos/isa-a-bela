begin;
\ir helpers.sql
select plan(11);

select test_create_user('11111111-1111-1111-1111-111111111111', 'isa@exemplo.com');
select test_create_user('22222222-2222-2222-2222-222222222222', 'outra@exemplo.com');

select test_login_as('11111111-1111-1111-1111-111111111111');

select lives_ok(
  $$ insert into public.tasks (user_id, title, due_date)
     values ('11111111-1111-1111-1111-111111111111', 'Pagar fatura do cartão', '2026-11-06') $$,
  'cria tarefa com prazo'
);

select lives_ok(
  $$ insert into public.tasks (user_id, title)
     values ('11111111-1111-1111-1111-111111111111', 'Comprar presente da mãe') $$,
  'cria tarefa sem prazo'
);

select throws_ok(
  $$ insert into public.tasks (user_id, title)
     values ('22222222-2222-2222-2222-222222222222', 'Alheia') $$,
  '42501', null, 'RLS recusa tarefa no nome de outra pessoa'
);

select throws_ok(
  $$ insert into public.tasks (user_id, title)
     values ('11111111-1111-1111-1111-111111111111', '   ') $$,
  '23514', null, 'recusa título só com espaços'
);

select throws_ok(
  $$ insert into public.tasks (user_id, title, done)
     values ('11111111-1111-1111-1111-111111111111', 'Sem data de conclusão', true) $$,
  '23514', null, 'concluída sem done_at é recusada'
);

select lives_ok(
  $$ insert into public.appointments
       (user_id, title, starts_at, ends_at, location, reminder_minutes)
     values ('11111111-1111-1111-1111-111111111111', 'Dentista',
             '2026-11-08 14:30-03', '2026-11-08 15:30-03', 'Clínica Sorriso', 30) $$,
  'cria compromisso com lembrete de 30 minutos'
);

select throws_ok(
  $$ insert into public.appointments (user_id, title, starts_at, ends_at)
     values ('11111111-1111-1111-1111-111111111111', 'Tempo invertido',
             '2026-11-08 15:00-03', '2026-11-08 14:00-03') $$,
  '23514', null, 'recusa fim antes do início'
);

select throws_ok(
  $$ insert into public.appointments (user_id, title, starts_at, ends_at)
     values ('11111111-1111-1111-1111-111111111111', 'Duração zero',
             '2026-11-08 15:00-03', '2026-11-08 15:00-03') $$,
  '23514', null, 'recusa fim igual ao início'
);

select lives_ok(
  $$ insert into public.appointments (user_id, title, starts_at)
     values ('11111111-1111-1111-1111-111111111111', 'Só começo', '2026-11-09 09:00-03') $$,
  'aceita compromisso sem hora de fim'
);

select throws_ok(
  $$ insert into public.appointments (user_id, title, starts_at, reminder_minutes)
     values ('11111111-1111-1111-1111-111111111111', 'Lembrete inválido',
             '2026-11-09 09:00-03', 45) $$,
  '23514', null, 'recusa lembrete fora das opções da interface'
);

-- isolamento de leitura
select test_logout();
select test_login_as('22222222-2222-2222-2222-222222222222');
select is(
  (select count(*)::int from public.tasks) + (select count(*)::int from public.appointments),
  0, 'a outra pessoa não vê nenhuma tarefa nem compromisso alheio'
);

select * from finish();
rollback;
