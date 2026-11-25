-- Execute uma vez no SQL Editor do projeto Supabase.
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  service_date timestamptz not null default now(),
  service text not null,
  order_number text,
  meter_type text,
  meter_number text,
  reading numeric,
  lat text,
  lng text,
  notes text,
  photo_path text
);

alter table public.services
  add column if not exists service_date timestamptz not null default now();

create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  kind text not null,
  phase text,
  conductor text,
  unit text not null default 'un',
  quantity numeric not null default 0,
  target numeric not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.services enable row level security;
alter table public.materials enable row level security;

drop policy if exists "Team members access their services" on public.services;
create policy "Team members access their services" on public.services
  for all to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "Team members access their materials" on public.materials;
create policy "Team members access their materials" on public.materials
  for all to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('service-photos', 'service-photos', false, 5242880, array['image/jpeg'])
on conflict (id) do update set public = false, file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg'];

drop policy if exists "Users access their service photos" on storage.objects;
create policy "Users access their service photos" on storage.objects
  for select to authenticated using (
    bucket_id = 'service-photos' and (storage.foldername(name))[1] = (select auth.uid())::text
  );
drop policy if exists "Users upload their service photos" on storage.objects;
create policy "Users upload their service photos" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'service-photos' and (storage.foldername(name))[1] = (select auth.uid())::text
  );
drop policy if exists "Users update their service photos" on storage.objects;
create policy "Users update their service photos" on storage.objects
  for update to authenticated using (
    bucket_id = 'service-photos' and (storage.foldername(name))[1] = (select auth.uid())::text
  ) with check (
    bucket_id = 'service-photos' and (storage.foldername(name))[1] = (select auth.uid())::text
  );
drop policy if exists "Users delete their service photos" on storage.objects;
create policy "Users delete their service photos" on storage.objects
  for delete to authenticated using (
    bucket_id = 'service-photos' and (storage.foldername(name))[1] = (select auth.uid())::text
  );
