-- Dados de exemplo com datas relativas a hoje, para a demonstração
-- nunca abrir vazia nem envelhecer.
create or replace function public.seed_guest_data(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mes integer;
  v_dia date;
  v_cat_alimentacao uuid;
  v_cat_transporte uuid;
  v_cat_beleza uuid;
  v_cat_lazer uuid;
  v_cat_salario uuid;
begin
  select id into v_cat_alimentacao from public.categories
    where user_id = p_user and name = 'Alimentação' and kind = 'expense';
  select id into v_cat_transporte from public.categories
    where user_id = p_user and name = 'Transporte' and kind = 'expense';
  select id into v_cat_beleza from public.categories
    where user_id = p_user and name = 'Beleza' and kind = 'expense';
  select id into v_cat_lazer from public.categories
    where user_id = p_user and name = 'Lazer' and kind = 'expense';
  select id into v_cat_salario from public.categories
    where user_id = p_user and name = 'Salário' and kind = 'income';

  -- seis meses de histórico, incluindo o mês corrente
  for v_mes in 0..5 loop
    v_dia := (date_trunc('month', current_date) - make_interval(months => v_mes))::date;

    insert into public.transactions
      (user_id, kind, amount_cents, description, category_id, occurred_on)
    values
      (p_user, 'income', 520000, 'Salário', v_cat_salario, v_dia + 4),
      (p_user, 'expense', 38500, 'Compras do mês', v_cat_alimentacao, v_dia + 5),
      (p_user, 'expense', 12000, 'Combustível', v_cat_transporte, v_dia + 9),
      (p_user, 'expense', 9000 + v_mes * 500, 'Salão', v_cat_beleza, v_dia + 14),
      (p_user, 'expense', 7600, 'Cinema', v_cat_lazer, v_dia + 19);

    -- alguns gastos com local, para o mapa ter o que mostrar
    insert into public.transactions
      (user_id, kind, amount_cents, description, category_id, occurred_on,
       latitude, longitude, place_name)
    values
      (p_user, 'expense', 15400, 'Mercado', v_cat_alimentacao, v_dia + 7,
       -21.7587, -43.3496, 'Supermercado Bahamas'),
      (p_user, 'expense', 4300, 'Café', v_cat_alimentacao, v_dia + 12,
       -21.7612, -43.3471, 'Café da Praça');
  end loop;

  insert into public.tasks (user_id, title, due_date)
  values
    (p_user, 'Pagar fatura do cartão', current_date - 2),
    (p_user, 'Comprar presente da mãe', current_date + 3),
    (p_user, 'Agendar revisão do carro', null);

  insert into public.tasks (user_id, title, due_date, done, done_at)
  values (p_user, 'Renovar assinatura', current_date - 10, true, now() - interval '9 days');

  insert into public.appointments
    (user_id, title, starts_at, ends_at, location, reminder_minutes)
  values
    (p_user, 'Dentista',
     (current_date + 2)::timestamptz + interval '14 hours 30 minutes',
     (current_date + 2)::timestamptz + interval '15 hours 30 minutes',
     'Clínica Sorriso', 30),
    (p_user, 'Almoço com a Bia',
     (current_date + 4)::timestamptz + interval '12 hours',
     null, 'Restaurante Itália', 60);
end $$;

-- Função interna: só handle_new_user a chama. Sem o revoke, qualquer pessoa
-- despeja dados de exemplo na conta de outra.
revoke all on function public.seed_guest_data(uuid) from public, anon, authenticated, service_role;

-- handle_new_user passa a semear o visitante. As categorias padrão continuam
-- vindo de seed_default_categories (migration 0001), não repetidas aqui.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_guest boolean := coalesce(new.is_anonymous, false);
begin
  insert into public.profiles (id, name, is_guest)
  values (
    new.id,
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'name'), ''), 'Visitante'),
    v_guest
  );

  perform public.seed_default_categories(new.id);

  if v_guest then
    perform public.seed_guest_data(new.id);
  end if;

  return new;
end $$;

-- Retenção do modo visitante: 7 dias. Função separada do agendamento
-- para poder ser testada.
create or replace function public.delete_stale_guests(p_days integer default 7)
returns integer
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_apagados integer;
begin
  with removidos as (
    delete from auth.users u
     where coalesce(u.is_anonymous, false)
       and u.created_at < now() - make_interval(days => p_days)
    returning 1
  )
  select count(*)::integer into v_apagados from removidos;
  return v_apagados;
end $$;

-- Só o agendador chama. Sem o revoke, qualquer pessoa executa
-- `delete_stale_guests(0)` e apaga TODAS as contas de visitante de uma vez.
revoke all on function public.delete_stale_guests(integer) from public, anon, authenticated, service_role;

-- Agendamento diário às 4h. Em ambiente local o pg_cron pode não existir,
-- então o agendamento é condicional e a função acima continua testável.
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.schedule(
      'delete-stale-guests',
      '0 4 * * *',
      $cron$ select public.delete_stale_guests(7) $cron$
    );
  else
    raise notice 'pg_cron indisponível: agende delete_stale_guests no painel do Supabase';
  end if;
end $$;
