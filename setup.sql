-- ═════════════════════════════════════════════════════════════
--  Our Bucket List — one-time database setup
--
--  STEP 1: Edit the TWO emails in the INSERT below (your Google
--          account emails, exactly as Google knows them).
--  STEP 2: Paste this whole file into Supabase → SQL Editor → Run.
--
--  Safe to re-run any time (e.g. to change the allowed emails).
--  Everything below the insert is boilerplate — no edits needed.
-- ═════════════════════════════════════════════════════════════

-- Who is allowed in ───────────────────────────────────────────
create table if not exists public.allowed_users (
  email text primary key
);

delete from public.allowed_users;
insert into public.allowed_users (email) values
  ('Rhklite2012@hotmail.com'),        -- ← EDIT
  ('ydmandyliu@gmail.com');     -- ← EDIT

-- The list data (same key/value model the app has always used) ─
create table if not exists public.kv (
  key        text primary key,
  value      text not null,
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh on every write
create or replace function public.touch_updated_at()
returns trigger language plpgsql as
$$ begin new.updated_at = now(); return new; end $$;

drop trigger if exists kv_touch on public.kv;
create trigger kv_touch before update on public.kv
  for each row execute function public.touch_updated_at();

-- Allowlist check (runs server-side inside the policies) ──────
create or replace function public.is_allowed()
returns boolean
language sql stable security definer
set search_path = public as
$$
  select exists (
    select 1 from public.allowed_users
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  )
$$;

grant execute on function public.is_allowed() to authenticated;

-- Row Level Security: ONLY the two allowed accounts can touch kv
alter table public.kv enable row level security;
alter table public.allowed_users enable row level security;

drop policy if exists "kv select allowed" on public.kv;
drop policy if exists "kv insert allowed" on public.kv;
drop policy if exists "kv update allowed" on public.kv;
drop policy if exists "kv delete allowed" on public.kv;
create policy "kv select allowed" on public.kv
  for select to authenticated using (public.is_allowed());
create policy "kv insert allowed" on public.kv
  for insert to authenticated with check (public.is_allowed());
create policy "kv update allowed" on public.kv
  for update to authenticated using (public.is_allowed()) with check (public.is_allowed());
create policy "kv delete allowed" on public.kv
  for delete to authenticated using (public.is_allowed());

-- Each signed-in user may see only their OWN allowlist row —
-- the app uses this to show "you're in" vs "not on the list".
drop policy if exists "see own allowlist row" on public.allowed_users;
create policy "see own allowlist row" on public.allowed_users
  for select to authenticated
  using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

-- Tighten grants: signed-out visitors get nothing at all
revoke all on public.kv from anon;
revoke all on public.allowed_users from anon;
grant select, insert, update, delete on public.kv to authenticated;
grant select on public.allowed_users to authenticated;

-- Live sync between your two phones (safe if already added) ───
do $$
begin
  alter publication supabase_realtime add table public.kv;
exception when duplicate_object then null;
end $$;

-- Done. You can close this tab.
