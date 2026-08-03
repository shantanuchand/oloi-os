-- Oloi OS: Journey Domain

create type public.journey_status as enum (
  'enquiry',
  'discovery',
  'designing',
  'proposal_sent',
  'revision',
  'confirmed',
  'in_travel',
  'completed',
  'lost',
  'cancelled'
);

create type public.journey_component_type as enum (
  'accommodation',
  'transfer',
  'flight',
  'activity',
  'meal',
  'guide',
  'vehicle',
  'service',
  'free_time',
  'note'
);

create table public.journeys (
  id uuid primary key default gen_random_uuid(),
  knowledge_object_id uuid not null unique references public.knowledge_objects(id) on delete cascade,
  code text unique,
  title text not null,
  status public.journey_status not null default 'enquiry',
  lead_traveller_id uuid references public.travellers(id) on delete set null,
  household_id uuid references public.traveller_households(id) on delete set null,
  assigned_to uuid,
  enquiry_received_at timestamptz,
  proposed_start_date date,
  proposed_end_date date,
  confirmed_start_date date,
  confirmed_end_date date,
  adults smallint not null default 1 check (adults >= 0),
  children smallint not null default 0 check (children >= 0),
  infants smallint not null default 0 check (infants >= 0),
  currency char(3),
  target_budget numeric(14,2),
  quoted_total numeric(14,2),
  confirmed_total numeric(14,2),
  internal_cost numeric(14,2),
  narrative_intent text,
  design_rationale text,
  loss_reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint journeys_date_order check (
    proposed_end_date is null or proposed_start_date is null or proposed_end_date >= proposed_start_date
  ),
  constraint journeys_confirmed_date_order check (
    confirmed_end_date is null or confirmed_start_date is null or confirmed_end_date >= confirmed_start_date
  )
);

create index journeys_status_idx on public.journeys (status);
create index journeys_lead_traveller_idx on public.journeys (lead_traveller_id);
create index journeys_dates_idx on public.journeys (confirmed_start_date, confirmed_end_date);

create table public.journey_travellers (
  journey_id uuid not null references public.journeys(id) on delete cascade,
  traveller_id uuid not null references public.travellers(id) on delete restrict,
  role text not null default 'traveller',
  rooming_group text,
  is_primary_contact boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  primary key (journey_id, traveller_id)
);

create table public.journey_days (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references public.journeys(id) on delete cascade,
  day_number smallint not null check (day_number > 0),
  journey_date date,
  title text,
  location_object_id uuid references public.knowledge_objects(id) on delete set null,
  narrative text,
  pace_score smallint check (pace_score between 1 and 10),
  intensity_score smallint check (intensity_score between 1 and 10),
  recovery_score smallint check (recovery_score between 1 and 10),
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint journey_days_unique unique (journey_id, day_number)
);

create table public.journey_components (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references public.journeys(id) on delete cascade,
  journey_day_id uuid references public.journey_days(id) on delete cascade,
  component_type public.journey_component_type not null,
  sequence_number integer not null default 1,
  title text not null,
  supplier_object_id uuid references public.knowledge_objects(id) on delete set null,
  product_object_id uuid references public.knowledge_objects(id) on delete set null,
  start_at timestamptz,
  end_at timestamptz,
  start_location_object_id uuid references public.knowledge_objects(id) on delete set null,
  end_location_object_id uuid references public.knowledge_objects(id) on delete set null,
  description text,
  traveller_facing_notes text,
  internal_notes text,
  currency char(3),
  unit_cost numeric(14,2),
  quantity numeric(10,2) not null default 1,
  sell_price numeric(14,2),
  booking_status text not null default 'not_requested',
  confirmation_reference text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint journey_components_time_order check (
    end_at is null or start_at is null or end_at >= start_at
  )
);

create index journey_components_journey_idx on public.journey_components (journey_id);
create index journey_components_day_idx on public.journey_components (journey_day_id, sequence_number);
create index journey_components_supplier_idx on public.journey_components (supplier_object_id);

create table public.journey_design_decisions (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references public.journeys(id) on delete cascade,
  decision_type text not null,
  question text,
  decision text not null,
  rationale text not null,
  alternatives jsonb not null default '[]'::jsonb,
  assumptions jsonb not null default '[]'::jsonb,
  risks jsonb not null default '[]'::jsonb,
  confidence smallint not null default 50 check (confidence between 0 and 100),
  decided_by uuid,
  created_at timestamptz not null default now()
);

create index journey_design_decisions_journey_idx
  on public.journey_design_decisions (journey_id, created_at desc);

create trigger journeys_set_updated_at
before update on public.journeys
for each row execute function public.set_updated_at();

create trigger journey_days_set_updated_at
before update on public.journey_days
for each row execute function public.set_updated_at();

create trigger journey_components_set_updated_at
before update on public.journey_components
for each row execute function public.set_updated_at();

comment on table public.journeys is 'A traveller journey from enquiry through post-travel completion.';
comment on table public.journey_days is 'Narrative and rhythm structure for each journey day.';
comment on table public.journey_components is 'Bookable and non-bookable elements composing a journey.';
comment on table public.journey_design_decisions is 'Explainable record of why the journey was designed this way.';
