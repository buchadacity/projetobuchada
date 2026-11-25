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

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.services, public.materials to authenticated;

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

/* Consultas privadas da base de medidores importada da planilha da equipe. */
alter table public.services add column if not exists reading_03 numeric;
alter table public.services add column if not exists reading_24 numeric;
alter table public.services add column if not exists resolved boolean not null default false;

create table if not exists public.meter_locations (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  installation_no text not null,
  meter_no text,
  latitude double precision not null,
  longitude double precision not null,
  pole_no text,
  street_address text,
  house_number text,
  complement text,
  address_complement text,
  building text,
  room text,
  neighborhood text,
  city text,
  polo text
);

create index if not exists meter_locations_user_installation_idx on public.meter_locations(user_id, installation_no);
create index if not exists meter_locations_user_meter_idx on public.meter_locations(user_id, meter_no);
create index if not exists meter_locations_address_idx on public.meter_locations using gin (to_tsvector('simple', coalesce(street_address,'') || ' ' || coalesce(house_number,'') || ' ' || coalesce(complement,'') || ' ' || coalesce(address_complement,'') || ' ' || coalesce(neighborhood,'') || ' ' || coalesce(city,'')));

alter table public.meter_locations enable row level security;
drop policy if exists "Team members access their meter locations" on public.meter_locations;
create policy "Team members access their meter locations" on public.meter_locations
  for all to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.meter_locations to authenticated;
grant usage, select on sequence public.meter_locations_id_seq to authenticated;

create or replace function public.search_meter_locations(search_term text)
returns table (
  installation_no text, meter_no text, latitude double precision, longitude double precision,
  pole_no text, street_address text, house_number text, complement text,
  address_complement text, building text, room text, neighborhood text, city text, polo text
)
language sql stable security invoker set search_path = public
as $$
  select m.installation_no, m.meter_no, m.latitude, m.longitude, m.pole_no,
         m.street_address, m.house_number, m.complement, m.address_complement,
         m.building, m.room, m.neighborhood, m.city, m.polo
  from public.meter_locations m
  where m.user_id = (select auth.uid())
    and (
      m.installation_no ilike '%' || trim(search_term) || '%'
      or coalesce(m.meter_no,'') ilike '%' || trim(search_term) || '%'
      or concat_ws(' ',m.street_address,m.house_number,m.complement,m.address_complement,m.building,m.room,m.neighborhood,m.city,m.polo) ilike '%' || trim(search_term) || '%'
    )
  order by case when m.installation_no = trim(search_term) then 0
                when m.meter_no = trim(search_term) then 1 else 2 end,
           m.installation_no
  limit 50;
$$;
grant execute on function public.search_meter_locations(text) to authenticated;

-- Permite retomar a importação sem duplicar linhas se a conexão cair.
alter table public.meter_locations add column if not exists source_row integer;
create unique index if not exists meter_locations_user_source_row_uidx on public.meter_locations(user_id, source_row);
