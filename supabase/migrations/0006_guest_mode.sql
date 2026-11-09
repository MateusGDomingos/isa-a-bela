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
  -- As nove categorias que o demo usa. 'Outros' fica de fora de propósito: é a
  -- categoria de escape, e um demo que cai nela não demonstra nada.
  v_cat_alimentacao uuid;
  v_cat_moradia uuid;
  v_cat_transporte uuid;
  v_cat_saude uuid;
  v_cat_educacao uuid;
  v_cat_beleza uuid;
  v_cat_lazer uuid;
  v_cat_compras uuid;
  v_cat_salario uuid;
  -- Dois lançamentos sem local e um com local giram por mês, num ciclo de três.
  -- Sem isso o demo repete a mesma pizza e o mesmo mapa seis vezes, e quem folheia
  -- os meses percebe que o dado é semeado.
  v_cat_gira_a uuid; v_desc_gira_a text; v_val_gira_a integer;
  v_cat_gira_b uuid; v_desc_gira_b text; v_val_gira_b integer;
  v_lugar_a text; v_lat_a numeric; v_lon_a numeric;
  v_desc_b text;  v_val_b integer;
  v_lugar_b text; v_lat_b numeric; v_lon_b numeric;
begin
  select id into v_cat_alimentacao from public.categories
    where user_id = p_user and name = 'Alimentação' and kind = 'expense';
  select id into v_cat_moradia from public.categories
    where user_id = p_user and name = 'Moradia' and kind = 'expense';
  select id into v_cat_transporte from public.categories
    where user_id = p_user and name = 'Transporte' and kind = 'expense';
  select id into v_cat_saude from public.categories
    where user_id = p_user and name = 'Saúde' and kind = 'expense';
  select id into v_cat_educacao from public.categories
    where user_id = p_user and name = 'Educação' and kind = 'expense';
  select id into v_cat_beleza from public.categories
    where user_id = p_user and name = 'Beleza' and kind = 'expense';
  select id into v_cat_lazer from public.categories
    where user_id = p_user and name = 'Lazer' and kind = 'expense';
  select id into v_cat_compras from public.categories
    where user_id = p_user and name = 'Compras' and kind = 'expense';
  select id into v_cat_salario from public.categories
    where user_id = p_user and name = 'Salário' and kind = 'income';

  -- Seis meses de histórico, incluindo o mês corrente. SETE lançamentos por mês
  -- (cinco sem local, dois com local) — é de onde saem as contagens 42 e 12 nos
  -- testes. Mexer na quantidade de linhas por mês exige atualizar os dois números.
  for v_mes in 0..5 loop
    v_dia := (date_trunc('month', current_date) - make_interval(months => v_mes))::date;

    -- Ciclo de três meses: a composição da pizza muda a cada mês.
    v_cat_gira_a := case v_mes % 3 when 0 then v_cat_transporte
                                   when 1 then v_cat_saude
                                   else v_cat_educacao end;
    v_desc_gira_a := case v_mes % 3 when 0 then 'Combustível'
                                    when 1 then 'Farmácia'
                                    else 'Curso online' end;
    v_val_gira_a := case v_mes % 3 when 0 then 12000 when 1 then 8700 else 14900 end;

    v_cat_gira_b := case v_mes % 3 when 0 then v_cat_beleza
                                   when 1 then v_cat_lazer
                                   else v_cat_compras end;
    v_desc_gira_b := case v_mes % 3 when 0 then 'Salão'
                                    when 1 then 'Cinema'
                                    else 'Roupas' end;
    v_val_gira_b := case v_mes % 3 when 0 then 9000 + v_mes * 500
                                   when 1 then 7600
                                   else 19900 end;

    -- Ciclo dos lugares, para o mapa ter pinos em pontos diferentes e o ranking
    -- não ser sempre o mesmo par.
    -- Nomes inventados e coordenadas com duas casas decimais (resolução de ~1km, do
    -- tamanho de um bairro), não quatro (resolução de ~10m, do tamanho de uma
    -- esquina). Um demo público não precisa — e não deve — apontar o endereço real
    -- de quem o escreveu.
    v_lugar_a := case v_mes % 3 when 0 then 'Mercadinho da Esquina'
                                when 1 then 'Empório Boa Vista'
                                else 'Feira do Bairro' end;
    v_lat_a := case v_mes % 3 when 0 then -21.75 when 1 then -21.78 else -21.72 end;
    v_lon_a := case v_mes % 3 when 0 then -43.33 when 1 then -43.40 else -43.28 end;

    v_lugar_b := case v_mes % 2 when 0 then 'Cafeteria Girassol' else 'Padaria Estrela' end;
    v_desc_b  := case v_mes % 2 when 0 then 'Café' else 'Pão e leite' end;
    v_val_b   := case v_mes % 2 when 0 then 4300 else 3100 end;
    v_lat_b   := case v_mes % 2 when 0 then -21.80 else -21.70 end;
    v_lon_b   := case v_mes % 2 when 0 then -43.35 else -43.31 end;

    -- Cinco sem local: salário, aluguel, compras do mês e os dois que giram.
    insert into public.transactions
      (user_id, kind, amount_cents, description, category_id, occurred_on)
    values
      (p_user, 'income', 520000, 'Salário', v_cat_salario, v_dia + 4),
      (p_user, 'expense', 148000, 'Aluguel', v_cat_moradia, v_dia + 2),
      (p_user, 'expense', 38500, 'Compras do mês', v_cat_alimentacao, v_dia + 5),
      (p_user, 'expense', v_val_gira_a, v_desc_gira_a, v_cat_gira_a, v_dia + 9),
      (p_user, 'expense', v_val_gira_b, v_desc_gira_b, v_cat_gira_b, v_dia + 14);

    -- Dois com local, para o mapa ter o que mostrar.
    insert into public.transactions
      (user_id, kind, amount_cents, description, category_id, occurred_on,
       latitude, longitude, place_name)
    values
      (p_user, 'expense', 15400, 'Mercado', v_cat_alimentacao, v_dia + 7,
       v_lat_a, v_lon_a, v_lugar_a),
      (p_user, 'expense', v_val_b, v_desc_b, v_cat_alimentacao, v_dia + 12,
       v_lat_b, v_lon_b, v_lugar_b);
  end loop;

  insert into public.tasks (user_id, title, due_date)
  values
    (p_user, 'Pagar fatura do cartão', current_date - 2),
    (p_user, 'Comprar presente da mãe', current_date + 3),
    (p_user, 'Agendar revisão do carro', null);

  insert into public.tasks (user_id, title, due_date, done, done_at)
  values (p_user, 'Renovar assinatura', current_date - 10, true, now() - interval '9 days');

  -- `(data::text || ' hh:mm')::timestamp at time zone 'America/Sao_Paulo'` interpreta
  -- o horário como hora de parede em São Paulo e só então converte para o instante
  -- absoluto (timestamptz) que a coluna guarda. `(data)::timestamptz + interval` como
  -- estava antes ancora em UTC: o almoço do meio-dia nascia marcado para as 9h e o
  -- dentista das 14h30 para as 11h30 em qualquer dispositivo no fuso do Brasil — um
  -- demo que existe para mostrar a tela Início não pode abrir com os horários errados.
  insert into public.appointments
    (user_id, title, starts_at, ends_at, location, reminder_minutes)
  values
    (p_user, 'Dentista',
     ((current_date + 2)::text || ' 14:30')::timestamp at time zone 'America/Sao_Paulo',
     ((current_date + 2)::text || ' 15:30')::timestamp at time zone 'America/Sao_Paulo',
     'Clínica Sorriso', 30),
    (p_user, 'Almoço com a Bia',
     ((current_date + 4)::text || ' 12:00')::timestamp at time zone 'America/Sao_Paulo',
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
