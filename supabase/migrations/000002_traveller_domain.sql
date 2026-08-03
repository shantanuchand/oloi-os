-- Oloi OS: Traveller Domain

create type public.traveller_status as enum (
  'prospect',
  'active',
  'past',
  'dormant',
  'do_not_contact'
);

create type public.preference_strength as enum (
  'weak',
  'moderate',
  'strong',
  'essential',
  'avoid'
);

create table public.travellers (
  id uuid primary key default gen_random_uuid(),
  knowledge_object_id uuid not null unique references public.knowledge_objects(id) on delete cascade,
  status public.traveller_status not null default 'prospect',
  title text,
  first_name text not null,
  middle_name text,
  last_name text,
  preferred_name text,
  date_of_birth date,
  nationality text,
  gender text,
  primary_email text,
  primary_phone text,
  whatsapp_phone text,
  country_of_residence text,
  city_of_residence text,
  occupation text,
  company text,
  referral_source text,
  assigned_to uuid,
  vip_level smallint not null default 0 check (vip_level between 0 and 5),
  preferred_contact_channel text,
  preferred_contact_time text,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index travellers_name_idx on public.travellers (last_name, first_name);
create index travellers_email_idx on public.travellers (lower(primary_email));
create index travellers_phone_idx on public.travellers (primary_phone);
create index travellers_status_idx on public.travellers (status);

create table public.traveller_households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  primary_traveller_id uuid references public.travellers(id) on delete set null,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.traveller_household_members (
  household_id uuid not null references public.traveller_households(id) on delete cascade,
  traveller_id uuid not null references public.travellers(id) on delete cascade,
  relationship_to_primary text,
  is_decision_maker boolean not null default false,
  is_primary_contact boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (household_id, traveller_id)
);

create table public.traveller_preferences (
  id uuid primary key default gen_random_uuid(),
  traveller_id uuid not null references public.travellers(id) on delete cascade,
  category text not null,
  preference_key text not null,
  preference_value jsonb not null,
  strength public.preference_strength not null default 'moderate',
  confidence smallint not null default 50 check (confidence between 0 and 100),
  source_id uuid references public.knowledge_sources(id) on delete set null,
  valid_from date,
  valid_to date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint traveller_preferences_unique
    unique (traveller_id, category, preference_key, valid_from)
);

create index traveller_preferences_lookup_idx
  on public.traveller_preferences (traveller_id, category, preference_key);

create table public.traveller_constraints (
  id uuid primary key default gen_random_uuid(),
  traveller_id uuid not null references public.travellers(id) on delete cascade,
  constraint_type text not null,
  severity text not null default 'important',
  details text not null,
  effective_from date,
  effective_to date,
  verified boolean not null default false,
  source_id uuid references public.knowledge_sources(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index traveller_constraints_lookup_idx
  on public.traveller_constraints (traveller_id, constraint_type);

create table public.traveller_interactions (
  id uuid primary key default gen_random_uuid(),
  traveller_id uuid not null references public.travellers(id) on delete cascade,
  interaction_type text not null,
  channel text,
  occurred_at timestamptz not null,
  subject text,
  summary text,
  sentiment text,
  action_required boolean not null default false,
  action_due_at timestamptz,
  source_reference text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index traveller_interactions_timeline_idx
  on public.traveller_interactions (traveller_id, occurred_at desc);

create trigger travellers_set_updated_at
before update on public.travellers
for each row execute function public.set_updated_at();

create trigger traveller_households_set_updated_at
before update on public.traveller_households
for each row execute function public.set_updated_at();

create trigger traveller_preferences_set_updated_at
before update on public.traveller_preferences
for each row execute function public.set_updated_at();

create trigger traveller_constraints_set_updated_at
before update on public.traveller_constraints
for each row execute function public.set_updated_at();

comment on table public.travellers is 'Operational traveller identity linked to the knowledge graph.';
comment on table public.traveller_preferences is 'Time-aware preferences with confidence and provenance.';
comment on table public.traveller_constraints is 'Medical, dietary, mobility, legal and practical journey constraints.';
comment on table public.traveller_interactions is 'Communication and relationship timeline.';
