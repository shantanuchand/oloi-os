-- Oloi OS security foundation
-- No business or client data belongs in this migration.

create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";
create extension if not exists postgis;
create extension if not exists vector;

-- Keep sensitive internal objects outside the API-exposed public schema.
create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;

-- Stop arbitrary object creation in the public schema.
revoke create on schema public from public;
revoke create on schema public from anon;
revoke create on schema public from authenticated;

-- Secure defaults for future objects created by the database owner.
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke all on functions from anon, authenticated;

-- Shared timestamp trigger for future tables.
create or replace function app_private.set_updated_at()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

revoke all on function app_private.set_updated_at() from public, anon, authenticated;

-- Append-only audit record. Application users receive no direct access.
create table if not exists app_private.audit_log (
  audit_id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default timezone('utc', now()),
  actor_user_id uuid,
  actor_role text,
  action text not null,
  table_schema text not null,
  table_name text not null,
  record_id text,
  old_record jsonb,
  new_record jsonb,
  request_id text,
  source text
);

alter table app_private.audit_log enable row level security;
revoke all on app_private.audit_log from public, anon, authenticated;

comment on schema app_private is 'Server-only Oloi OS functions, audit data and security objects.';
comment on table app_private.audit_log is 'Append-only audit history; never exposed directly to browser clients.';
