-- Oloi OS: Supplier Domain

create type public.supplier_status as enum (
  'prospect',
  'approved',
  'preferred',
  'restricted',
  'inactive',
  'blacklisted'
);

create table public.suppliers (
  id uuid primary key default gen_random_uuid(),
  knowledge_object_id uuid not null unique references public.knowledge_objects(id) on delete cascade,
  legal_name text,
  trading_name text not null,
  supplier_type text not null,
  status public.supplier_status not null default 'prospect',
  country text,
  city text,
  website text,
  primary_email text,
  primary_phone text,
  emergency_phone text,
  payment_terms text,
  default_currency char(3),
  credit_allowed boolean not null default false,
  tax_reference text,
  contract_start_date date,
  contract_end_date date,
  last_inspected_at date,
  next_review_at date,
  assigned_to uuid,
  internal_notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index suppliers_type_status_idx on public.suppliers (supplier_type, status);
create index suppliers_country_idx on public.suppliers (country);

create table public.supplier_contacts (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references public.suppliers(id) on delete cascade,
  full_name text not null,
  role text,
  email text,
  phone text,
  whatsapp_phone text,
  is_primary boolean not null default false,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.supplier_products (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references public.suppliers(id) on delete cascade,
  knowledge_object_id uuid unique references public.knowledge_objects(id) on delete set null,
  product_type text not null,
  name text not null,
  description text,
  location_object_id uuid references public.knowledge_objects(id) on delete set null,
  capacity integer,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint supplier_products_unique unique (supplier_id, product_type, name)
);

create index supplier_products_supplier_idx on public.supplier_products (supplier_id, active);
create index supplier_products_location_idx on public.supplier_products (location_object_id);

create table public.supplier_rates (
  id uuid primary key default gen_random_uuid(),
  supplier_product_id uuid not null references public.supplier_products(id) on delete cascade,
  rate_name text not null,
  market text,
  currency char(3) not null,
  valid_from date not null,
  valid_to date not null,
  unit_type text not null,
  nett_amount numeric(14,2) not null check (nett_amount >= 0),
  tax_amount numeric(14,2) not null default 0 check (tax_amount >= 0),
  sell_amount numeric(14,2),
  minimum_nights smallint not null default 1 check (minimum_nights > 0),
  terms text,
  source_reference text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint supplier_rates_date_order check (valid_to >= valid_from)
);

create index supplier_rates_lookup_idx
  on public.supplier_rates (supplier_product_id, valid_from, valid_to, currency);

create table public.supplier_assessments (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references public.suppliers(id) on delete cascade,
  assessed_at date not null default current_date,
  assessment_type text not null,
  assessor_id uuid,
  service_score smallint check (service_score between 1 and 10),
  guide_score smallint check (guide_score between 1 and 10),
  food_score smallint check (food_score between 1 and 10),
  accommodation_score smallint check (accommodation_score between 1 and 10),
  reliability_score smallint check (reliability_score between 1 and 10),
  privacy_score smallint check (privacy_score between 1 and 10),
  value_score smallint check (value_score between 1 and 10),
  safety_score smallint check (safety_score between 1 and 10),
  overall_score numeric(4,2),
  strengths text,
  weaknesses text,
  recommendation text,
  evidence jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index supplier_assessments_timeline_idx
  on public.supplier_assessments (supplier_id, assessed_at desc);

create trigger suppliers_set_updated_at
before update on public.suppliers
for each row execute function public.set_updated_at();

create trigger supplier_contacts_set_updated_at
before update on public.supplier_contacts
for each row execute function public.set_updated_at();

create trigger supplier_products_set_updated_at
before update on public.supplier_products
for each row execute function public.set_updated_at();

create trigger supplier_rates_set_updated_at
before update on public.supplier_rates
for each row execute function public.set_updated_at();

comment on table public.suppliers is 'Operational supplier record linked to the knowledge graph.';
comment on table public.supplier_rates is 'Versioned supplier rate periods; historical rates are preserved.';
comment on table public.supplier_assessments is 'Evidence-backed inspection and performance history.';
