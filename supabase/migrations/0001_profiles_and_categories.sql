create extension if not exists pgtap with schema extensions;
create extension if not exists pgcrypto with schema extensions;

-- ---------- profiles ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  is_guest boolean not null default false,
  is_admin boolean not null default false,
  privacy_accepted_at timestamptz,
  privacy_version text,
  location_consent boolean not null default false,
  analytics_consent boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Sem política de insert nem delete: quem cria é o gatilho, quem apaga é o cascade.
create policy profiles_select_own on public.profiles
  for select using (id = auth.uid());

create policy profiles_update_own on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- ---------- categories ----------
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 40),
  kind text not null check (kind in ('expense', 'income')),
  color text not null check (color ~ '^#[0-9A-Fa-f]{6}$'),
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, name, kind)
);

create index categories_user_kind_idx on public.categories (user_id, kind);

alter table public.categories enable row level security;

create policy categories_select_own on public.categories
  for select using (user_id = auth.uid());
create policy categories_insert_own on public.categories
  for insert with check (user_id = auth.uid());
create policy categories_update_own on public.categories
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy categories_delete_own on public.categories
  for delete using (user_id = auth.uid());

-- ---------- conta nova ----------
-- A lista de categorias padrão vive numa função própria porque a migration
-- 0006 substitui handle_new_user para semear o visitante. Sem essa extração,
-- as 13 linhas seriam repetidas literalmente nas duas migrations.
create or replace function public.seed_default_categories(p_user uuid)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.categories (user_id, name, kind, color, is_default)
  values
    (p_user, 'Alimentação', 'expense', '#C2456E', true),
    (p_user, 'Moradia',     'expense', '#8E5E7A', true),
    (p_user, 'Transporte',  'expense', '#5E7A8E', true),
    (p_user, 'Saúde',       'expense', '#2F9E7E', true),
    (p_user, 'Beleza',      'expense', '#EB7A9C', true),
    (p_user, 'Lazer',       'expense', '#D9A13B', true),
    (p_user, 'Compras',     'expense', '#A05EC2', true),
    (p_user, 'Educação',    'expense', '#3B6FC2', true),
    (p_user, 'Outros',      'expense', '#9A7482', true),
    (p_user, 'Salário',     'income',  '#2F9E7E', true),
    (p_user, 'Freelance',   'income',  '#3B9EC2', true),
    (p_user, 'Presente',    'income',  '#EB7A9C', true),
    (p_user, 'Outros',      'income',  '#9A7482', true);
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.profiles (id, name, is_guest)
  values (
    new.id,
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'name'), ''), 'Visitante'),
    coalesce(new.is_anonymous, false)
  );

  perform public.seed_default_categories(new.id);
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
