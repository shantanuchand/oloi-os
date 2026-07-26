-- Oloi OS: Knowledge Core
-- Establishes the canonical knowledge object, provenance and relationship graph.

create extension if not exists pgcrypto;
create extension if not exists vector;

create type public.knowledge_status as enum (
  'draft',
  'active',
  'deprecated',
  'archived'
);

create type public.source_kind as enum (
  'founder_observation',
  'field_note',
  'inspection',
  'traveller_feedback',
  'supplier',
  'email',
  'whatsapp',
  'document',
  'book',
  'website',
  'government',
  'research',
  'photo',
  'video',
  'system'
);

create table public.knowledge_objects (
  id uuid primary key default gen_random_uuid(),
  object_type text not null,
  title text not null,
  slug text,
  summary text,
  body text,
  status public.knowledge_status not null default 'active',
  confidence smallint not null default 50 check (confidence between 0 and 100),
  metadata jsonb not null default '{}'::jsonb,
  embedding vector(1536),
  created_by uuid,
  updated_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  constraint knowledge_objects_type_title_unique unique (object_type, title)
);

create index knowledge_objects_type_idx on public.knowledge_objects (object_type);
create index knowledge_objects_status_idx on public.knowledge_objects (status);
create index knowledge_objects_title_idx on public.knowledge_objects using gin (to_tsvector('english', title));
create index knowledge_objects_metadata_idx on public.knowledge_objects using gin (metadata);
create index knowledge_objects_embedding_idx on public.knowledge_objects using ivfflat (embedding vector_cosine_ops) with (lists = 100);

create table public.knowledge_sources (
  id uuid primary key default gen_random_uuid(),
  knowledge_object_id uuid not null references public.knowledge_objects(id) on delete cascade,
  source_kind public.source_kind not null,
  source_title text,
  source_reference text,
  source_excerpt text,
  source_date date,
  confidence smallint check (confidence between 0 and 100),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index knowledge_sources_object_idx on public.knowledge_sources (knowledge_object_id);
create index knowledge_sources_kind_idx on public.knowledge_sources (source_kind);

create table public.relationship_types (
  code text primary key,
  label text not null,
  inverse_code text,
  description text,
  is_directional boolean not null default true,
  created_at timestamptz not null default now(),
  constraint relationship_types_inverse_fk
    foreign key (inverse_code) references public.relationship_types(code)
    deferrable initially deferred
);

create table public.knowledge_relationships (
  id uuid primary key default gen_random_uuid(),
  from_object_id uuid not null references public.knowledge_objects(id) on delete cascade,
  relationship_type text not null references public.relationship_types(code),
  to_object_id uuid not null references public.knowledge_objects(id) on delete cascade,
  confidence smallint not null default 50 check (confidence between 0 and 100),
  valid_from date,
  valid_to date,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint knowledge_relationships_no_self_loop
    check (from_object_id <> to_object_id),
  constraint knowledge_relationships_unique
    unique (from_object_id, relationship_type, to_object_id, valid_from)
);

create index knowledge_relationships_from_idx on public.knowledge_relationships (from_object_id);
create index knowledge_relationships_to_idx on public.knowledge_relationships (to_object_id);
create index knowledge_relationships_type_idx on public.knowledge_relationships (relationship_type);

create table public.knowledge_versions (
  id uuid primary key default gen_random_uuid(),
  knowledge_object_id uuid not null references public.knowledge_objects(id) on delete cascade,
  version_number integer not null,
  snapshot jsonb not null,
  change_reason text,
  changed_by uuid,
  created_at timestamptz not null default now(),
  constraint knowledge_versions_unique unique (knowledge_object_id, version_number)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger knowledge_objects_set_updated_at
before update on public.knowledge_objects
for each row execute function public.set_updated_at();

create trigger knowledge_relationships_set_updated_at
before update on public.knowledge_relationships
for each row execute function public.set_updated_at();

insert into public.relationship_types (code, label, inverse_code, description, is_directional) values
  ('located_in', 'Located in', 'contains', 'Physical or administrative location relationship.', true),
  ('contains', 'Contains', 'located_in', 'Inverse of located_in.', true),
  ('works_at', 'Works at', 'employs', 'Person works at an organisation or property.', true),
  ('employs', 'Employs', 'works_at', 'Inverse of works_at.', true),
  ('recommended_for', 'Recommended for', null, 'Suitable for a traveller, journey type or use case.', true),
  ('avoids', 'Avoids', null, 'Should not be combined with or used for the target.', true),
  ('prefers', 'Prefers', null, 'Preference relationship.', true),
  ('visited', 'Visited', 'visited_by', 'Entity visited a place or supplier.', true),
  ('visited_by', 'Visited by', 'visited', 'Inverse of visited.', true),
  ('mentioned_in', 'Mentioned in', 'mentions', 'Entity appears in a source or knowledge object.', true),
  ('mentions', 'Mentions', 'mentioned_in', 'Inverse of mentioned_in.', true),
  ('part_of', 'Part of', 'has_part', 'Composition or membership relationship.', true),
  ('has_part', 'Has part', 'part_of', 'Inverse of part_of.', true),
  ('trusted_by', 'Trusted by', 'trusts', 'Trust relationship.', true),
  ('trusts', 'Trusts', 'trusted_by', 'Inverse of trusted_by.', true),
  ('referred', 'Referred', 'referred_by', 'Referral relationship.', true),
  ('referred_by', 'Referred by', 'referred', 'Inverse of referred.', true),
  ('observed', 'Observed', 'observed_by', 'Observation relationship.', true),
  ('observed_by', 'Observed by', 'observed', 'Inverse of observed.', true)
on conflict do nothing;

comment on table public.knowledge_objects is 'Canonical graph node for all durable Oloi OS knowledge.';
comment on table public.knowledge_relationships is 'Typed edges between knowledge objects.';
comment on table public.knowledge_sources is 'Provenance for each knowledge object.';
comment on table public.knowledge_versions is 'Immutable history of knowledge object changes.';
