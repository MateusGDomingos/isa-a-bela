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
begin
  if v_uid is null then
    raise exception 'sem usuário autenticado' using errcode = '28000';
  end if;

  delete from public.analytics_events where user_id = v_uid;
  get diagnostics v_apagados = row_count;

  update public.profiles set analytics_consent = false where id = v_uid;
  return v_apagados;
end $$;

revoke all on function public.erase_my_analytics() from public, anon, authenticated, service_role;
grant execute on function public.erase_my_analytics() to authenticated;

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
