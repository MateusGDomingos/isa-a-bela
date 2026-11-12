create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('expense', 'income')),
  amount_cents integer not null check (amount_cents > 0),
  description text not null check (char_length(btrim(description)) between 1 and 120),
  category_id uuid references public.categories(id) on delete set null,
  occurred_on date not null,
  latitude numeric(9, 6),
  longitude numeric(9, 6),
  place_name text check (place_name is null or char_length(btrim(place_name)) between 1 and 120),
  created_at timestamptz not null default now(),
  -- latitude e longitude andam juntas: meia coordenada não localiza nada
  constraint transactions_coords_complete check (
    (latitude is null and longitude is null) or (latitude is not null and longitude is not null)
  ),
  constraint transactions_lat_range check (latitude is null or latitude between -90 and 90),
  constraint transactions_lon_range check (longitude is null or longitude between -180 and 180)
);

create index transactions_user_month_idx on public.transactions (user_id, occurred_on);
create index transactions_user_place_idx on public.transactions (user_id, place_name)
  where place_name is not null;

-- Impede vincular um lançamento à categoria de outra pessoa.
-- security invoker: a RLS de categories já filtra pelo dono.
create or replace function public.owns_category(p_category_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select p_category_id is null
     or exists (select 1 from public.categories c where c.id = p_category_id);
$$;

alter table public.transactions enable row level security;

create policy transactions_select_own on public.transactions
  for select using (user_id = auth.uid());

create policy transactions_insert_own on public.transactions
  for insert with check (user_id = auth.uid() and public.owns_category(category_id));

create policy transactions_update_own on public.transactions
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid() and public.owns_category(category_id));

create policy transactions_delete_own on public.transactions
  for delete using (user_id = auth.uid());
