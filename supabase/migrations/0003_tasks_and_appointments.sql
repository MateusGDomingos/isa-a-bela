create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  due_date date,
  done boolean not null default false,
  done_at timestamptz,
  created_at timestamptz not null default now(),
  -- done_at só existe quando a tarefa está concluída
  constraint tasks_done_at_consistent check (
    (done and done_at is not null) or (not done and done_at is null)
  )
);

create index tasks_user_pending_idx on public.tasks (user_id, done, due_date);

alter table public.tasks enable row level security;

create policy tasks_select_own on public.tasks for select using (user_id = auth.uid());
create policy tasks_insert_own on public.tasks for insert with check (user_id = auth.uid());
create policy tasks_update_own on public.tasks
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy tasks_delete_own on public.tasks for delete using (user_id = auth.uid());

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  starts_at timestamptz not null,
  ends_at timestamptz,
  location text check (location is null or char_length(btrim(location)) between 1 and 120),
  notes text check (notes is null or char_length(btrim(notes)) between 1 and 500),
  reminder_minutes integer check (reminder_minutes in (10, 30, 60, 1440)),
  notification_id text,
  created_at timestamptz not null default now(),
  constraint appointments_end_after_start check (ends_at is null or ends_at > starts_at)
);

create index appointments_user_start_idx on public.appointments (user_id, starts_at);

alter table public.appointments enable row level security;

create policy appointments_select_own on public.appointments
  for select using (user_id = auth.uid());
create policy appointments_insert_own on public.appointments
  for insert with check (user_id = auth.uid());
create policy appointments_update_own on public.appointments
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy appointments_delete_own on public.appointments
  for delete using (user_id = auth.uid());
