-- Esta suíte documenta o isolamento positivo (alterar ou apagar dado alheio afeta zero
-- linhas; transferir linha própria para outra conta é recusado) e pega a regressão de RLS
-- desligada. Ela NÃO pega a edição de uma política isolada: o esquema tem defesa em
-- profundidade e quebrar só uma das três proteções (using do select, using do update,
-- with check do update) não abre caminho — ver o relatório da Tarefa 9b para a evidência
-- (três rodadas de experimento, cada uma refutando a premissa anterior).
--
-- Por isso a alteração/exclusão conta linhas afetadas em vez de esperar exceção (a RLS
-- filtra essas duas operações em silêncio), e por isso existe uma asserção dedicada que
-- lê o catálogo para pegar a RLS desligada diretamente, em vez de por efeito colateral.
begin;
\ir helpers.sql
select plan(13);

-- A regressão que realmente importa, pega direto em vez de por efeito colateral:
-- RLS desligada em qualquer tabela de `public`. Também protege o futuro — tabela nova
-- criada sem `enable row level security` quebra aqui, na hora, em vez de vazar em silêncio.
select is(
  (select count(*)::int
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p')
      and not c.relrowsecurity),
  0, 'toda tabela de public tem RLS habilitada'
);

select test_create_user('11111111-1111-1111-1111-111111111111', 'isa@exemplo.com');
select test_create_user('22222222-2222-2222-2222-222222222222', 'outra@exemplo.com');

-- Dados da outra pessoa, criados aqui como superusuário (antes do login, sem RLS).
insert into public.transactions (user_id, kind, amount_cents, description, occurred_on)
values ('22222222-2222-2222-2222-222222222222', 'expense', 1000, 'Gasto dela', '2026-11-06');

insert into public.tasks (user_id, title)
values ('22222222-2222-2222-2222-222222222222', 'Tarefa dela');

insert into public.appointments (user_id, title, starts_at)
values ('22222222-2222-2222-2222-222222222222', 'Compromisso dela', '2026-11-08 10:00-03');

-- Dados da própria usuária 1, pra ter sujeito nas asserções de transferência (Step 1b).
insert into public.transactions (user_id, kind, amount_cents, description, occurred_on)
values ('11111111-1111-1111-1111-111111111111', 'expense', 2000, 'Gasto dela mesma', '2026-11-06');

insert into public.tasks (user_id, title)
values ('11111111-1111-1111-1111-111111111111', 'Tarefa própria');

insert into public.appointments (user_id, title, starts_at)
values ('11111111-1111-1111-1111-111111111111', 'Compromisso próprio', '2026-11-08 11:00-03');

select test_login_as('11111111-1111-1111-1111-111111111111');

-- ---------- transactions ----------
with afetadas as (
  update public.transactions set amount_cents = 1
   where user_id = '22222222-2222-2222-2222-222222222222'
  returning 1
)
select is((select count(*)::int from afetadas), 0,
  'update não alcança lançamento de outra pessoa');

with afetadas as (
  delete from public.transactions
   where user_id = '22222222-2222-2222-2222-222222222222'
  returning 1
)
select is((select count(*)::int from afetadas), 0,
  'delete não alcança lançamento de outra pessoa');

-- ---------- tasks ----------
with afetadas as (
  update public.tasks set title = 'Invadida'
   where user_id = '22222222-2222-2222-2222-222222222222'
  returning 1
)
select is((select count(*)::int from afetadas), 0,
  'update não alcança tarefa de outra pessoa');

with afetadas as (
  delete from public.tasks
   where user_id = '22222222-2222-2222-2222-222222222222'
  returning 1
)
select is((select count(*)::int from afetadas), 0,
  'delete não alcança tarefa de outra pessoa');

-- ---------- appointments ----------
with afetadas as (
  update public.appointments set title = 'Invadido'
   where user_id = '22222222-2222-2222-2222-222222222222'
  returning 1
)
select is((select count(*)::int from afetadas), 0,
  'update não alcança compromisso de outra pessoa');

with afetadas as (
  delete from public.appointments
   where user_id = '22222222-2222-2222-2222-222222222222'
  returning 1
)
select is((select count(*)::int from afetadas), 0,
  'delete não alcança compromisso de outra pessoa');

-- ---------- categories ----------
-- `color` em vez de `name`: `name` tem unique(user_id, name, kind), e renomear todas as
-- categorias padrão da vítima para o mesmo literal colide com essa constraint se a RLS
-- estiver desligada — a asserção degradaria de um "not ok" limpo para uma transação
-- abortada por 23505. `color` não tem essa restrição.
with afetadas as (
  update public.categories set color = '#000000'
   where user_id = '22222222-2222-2222-2222-222222222222'
  returning 1
)
select is((select count(*)::int from afetadas), 0,
  'update não alcança categoria de outra pessoa');

with afetadas as (
  delete from public.categories
   where user_id = '22222222-2222-2222-2222-222222222222'
  returning 1
)
select is((select count(*)::int from afetadas), 0,
  'delete não alcança categoria de outra pessoa');

-- ---------- transferência de linha própria para outra conta ----------
-- A cláusula `with check` governa a linha NOVA. Sem ela, a pessoa reatribui uma linha
-- própria para a conta de outra, injetando dado alheio — e a política de select não
-- protege contra isso, porque a linha de origem é legitimamente visível.
select throws_ok(
  $$ update public.transactions set user_id = '22222222-2222-2222-2222-222222222222'
      where user_id = auth.uid() $$,
  '42501', null, 'não dá para transferir lançamento próprio para outra conta'
);

select throws_ok(
  $$ update public.tasks set user_id = '22222222-2222-2222-2222-222222222222'
      where user_id = auth.uid() $$,
  '42501', null, 'não dá para transferir tarefa própria para outra conta'
);

select throws_ok(
  $$ update public.appointments set user_id = '22222222-2222-2222-2222-222222222222'
      where user_id = auth.uid() $$,
  '42501', null, 'não dá para transferir compromisso próprio para outra conta'
);

select throws_ok(
  $$ update public.categories set user_id = '22222222-2222-2222-2222-222222222222'
      where user_id = auth.uid() $$,
  '42501', null, 'não dá para transferir categoria própria para outra conta'
);

-- As linhas da outra pessoa continuam lá, conferidas sem RLS.
select test_logout();

select * from finish();
rollback;
