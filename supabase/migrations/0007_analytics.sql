-- Eventos de uso. O user_id existe para permitir revogação e exclusão,
-- não para identificar ninguém no painel: o painel lê só analytics_daily.
-- Nenhum conteúdo de lançamento, tarefa ou compromisso é registrado aqui.
create table public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null check (event_type in ('app_open', 'tab_view', 'record_created', 'error')),
  detail text check (detail is null or char_length(detail) <= 80),
  city text not null default '',
  region text not null default '',
  occurred_on date not null default current_date,
  created_at timestamptz not null default now()
);

create index analytics_events_day_idx on public.analytics_events (occurred_on);

alter table public.analytics_events enable row level security;
-- Nenhuma política: nem leitura, nem escrita pelo app. Só a Edge Function,
-- que usa a chave de serviço e por isso contorna a RLS.

create table public.analytics_daily (
  day date not null,
  city text not null default '',
  region text not null default '',
  event_type text not null,
  detail text not null default '',
  total integer not null,
  primary key (day, city, region, event_type, detail)
);

alter table public.analytics_daily enable row level security;

create policy analytics_daily_admin_read on public.analytics_daily
  for select using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  );

create or replace function public.rollup_analytics(p_day date default current_date - 1)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_linhas integer;
begin
  delete from public.analytics_daily where day = p_day;

  insert into public.analytics_daily (day, city, region, event_type, detail, total)
  select occurred_on, city, region, event_type, coalesce(detail, ''), count(*)::integer
    from public.analytics_events
   where occurred_on = p_day
   group by occurred_on, city, region, event_type, coalesce(detail, '');

  get diagnostics v_linhas = row_count;
  return v_linhas;
end $$;

revoke all on function public.rollup_analytics(date) from public, anon, authenticated, service_role;

-- Retenção de 90 dias (seção 8 da spec).
create or replace function public.purge_old_analytics(p_days integer default 90)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_apagados integer;
begin
  -- `<=` e não `<`: com `<`, p_days = 90 retém hoje mais 90 dias anteriores, ou seja
  -- 91 dias distintos, e a política de privacidade promete 90.
  delete from public.analytics_events
   where occurred_on <= current_date - p_days;
  get diagnostics v_apagados = row_count;

  -- O agregado "por dia e cidade" também é retido por 90 dias (seção 8 da spec).
  -- Sem apagar aqui, analytics_daily sobrevive indefinidamente à purga dos eventos
  -- que o originaram.
  delete from public.analytics_daily where day <= current_date - p_days;

  return v_apagados;
end $$;

-- Só o agendador chama. Sem o revoke, `purge_old_analytics(0)` apaga todos os
-- eventos de uma vez, de todos os usuários.
revoke all on function public.purge_old_analytics(integer) from public, anon, authenticated, service_role;

-- Revogação do consentimento de métricas: apaga os eventos do titular.
create or replace function public.erase_my_analytics()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_apagados integer;
  v_dias date[];
  v_dia date;
begin
  if v_uid is null then
    raise exception 'sem usuário autenticado' using errcode = '28000';
  end if;

  -- Guarda os dias que o titular tocou ANTES de apagar: depois do delete não há
  -- mais como saber quais linhas de analytics_daily precisam ser recompostas.
  select array_agg(distinct occurred_on) into v_dias
    from public.analytics_events where user_id = v_uid;

  delete from public.analytics_events where user_id = v_uid;
  get diagnostics v_apagados = row_count;

  -- Os eventos do titular já se foram, então o rollup desses dias recalcula o
  -- agregado sem a contribuição dele — correto por construção, sem precisar
  -- subtrair nada à mão. Isso é o que faz analytics_daily também esquecer
  -- quem revogou, e não só analytics_events.
  if v_dias is not null then
    foreach v_dia in array v_dias loop
      perform public.rollup_analytics(v_dia);
    end loop;
  end if;

  update public.profiles set analytics_consent = false where id = v_uid;
  return v_apagados;
end $$;

revoke all on function public.erase_my_analytics() from public, anon, authenticated, service_role;
grant execute on function public.erase_my_analytics() to authenticated;

-- analytics_events não tem política nenhuma, por desenho: nem o app nem o painel a
-- leem. Mas o titular tem direito de receber os próprios eventos na exportação
-- (LGPD art. 18, V), então este helper — e só ele — enxerga as linhas dele.
create or replace function public.export_my_analytics()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(e)), '[]'::jsonb)
    from public.analytics_events e
   where e.user_id = auth.uid();
$$;

revoke all on function public.export_my_analytics() from public, anon, authenticated, service_role;
grant execute on function public.export_my_analytics() to authenticated;

-- Completa export_my_data (criada em 0005_privacy_rights.sql) com a sexta chave.
-- Precisa estar aqui, e não em 0005: analytics_events e export_my_analytics só
-- existem a partir desta migration, e uma função `language sql` resolve seu corpo
-- contra o catálogo no momento do CREATE FUNCTION, não no primeiro uso. security
-- invoker continua certo para as outras cinco chaves — a RLS garante que só sai o
-- que é do próprio titular; analytics_events é a única exceção, e por isso entra
-- via export_my_analytics(), um helper definer escopado em auth.uid(), e não por
-- subselect direto aqui.
create or replace function public.export_my_data()
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  select jsonb_build_object(
    'exported_at', now(),
    'profile', (select to_jsonb(p) from public.profiles p where p.id = auth.uid()),
    'categories', coalesce((select jsonb_agg(to_jsonb(c)) from public.categories c), '[]'::jsonb),
    'transactions', coalesce((select jsonb_agg(to_jsonb(t)) from public.transactions t), '[]'::jsonb),
    'tasks', coalesce((select jsonb_agg(to_jsonb(k)) from public.tasks k), '[]'::jsonb),
    'appointments', coalesce((select jsonb_agg(to_jsonb(a)) from public.appointments a), '[]'::jsonb),
    'analytics_events', public.export_my_analytics()
  );
$$;

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.schedule(
      'rollup-analytics',
      '20 4 * * *',
      $cron$ select public.rollup_analytics() $cron$
    );
    perform cron.schedule(
      'purge-old-analytics',
      '40 4 * * *',
      $cron$ select public.purge_old_analytics(90) $cron$
    );
  else
    raise notice 'pg_cron indisponível: agende rollup e purge no painel do Supabase';
  end if;
end $$;
