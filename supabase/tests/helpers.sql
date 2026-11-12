-- Helpers usados por todos os arquivos de teste. Incluído com \ir helpers.sql
-- Criados dentro da transação do teste, então não existem em produção.

create or replace function test_create_user(
  p_id uuid,
  p_email text,
  p_anonymous boolean default false
) returns void language plpgsql as $$
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, is_anonymous, raw_user_meta_data, created_at, updated_at
  ) values (
    p_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    p_email, '', now(), p_anonymous,
    jsonb_build_object('name', split_part(p_email, '@', 1)), now(), now()
  );
end $$;

-- Faz o resto da transação rodar como o usuário informado, com RLS valendo.
-- Sem o SET ROLE, o teste roda como superusuário e a RLS é ignorada.
create or replace function test_login_as(p_id uuid) returns void language plpgsql as $$
begin
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', p_id::text, 'role', 'authenticated')::text,
    true
  );
  perform set_config('role', 'authenticated', true);
end $$;

create or replace function test_logout() returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', null, true);
end $$;
