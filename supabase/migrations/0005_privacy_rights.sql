-- Portabilidade (LGPD art. 18, V). security invoker: a RLS garante
-- que só sai o que é do próprio titular.
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
    'appointments', coalesce((select jsonb_agg(to_jsonb(a)) from public.appointments a), '[]'::jsonb)
  );
$$;

-- Revogação do consentimento de localização: apaga os locais e
-- preserva os valores financeiros.
create or replace function public.erase_my_places()
returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_afetados integer;
begin
  update public.transactions
     set latitude = null, longitude = null, place_name = null
   where user_id = auth.uid()
     and (latitude is not null or place_name is not null);
  get diagnostics v_afetados = row_count;

  update public.profiles set location_consent = false where id = auth.uid();
  return v_afetados;
end $$;

-- Eliminação (LGPD art. 18, VI). security definer porque apagar de auth.users
-- exige privilégio; o escopo é travado em auth.uid(), então não há como
-- apagar a conta de outra pessoa. O cascade das FKs leva todos os dados.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'sem usuário autenticado' using errcode = '28000';
  end if;
  delete from auth.users where id = v_uid;
end $$;

-- Revogar só de PUBLIC não basta no Supabase: toda função nova nasce com
-- concessão explícita por papel via ALTER DEFAULT PRIVILEGES do schema
-- public, que sobrevive a um "revoke ... from public" estreito (ver lição
-- da Tarefa 7). Sem nomear anon/authenticated/service_role aqui, a conta de
-- qualquer pessoa — até sem login — poderia ser apagada por quem chamasse
-- esta função com outro uid, já que ela corre como definer.
revoke all on function public.delete_my_account() from public, anon, authenticated, service_role;
grant execute on function public.delete_my_account() to authenticated;
