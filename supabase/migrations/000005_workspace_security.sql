-- Oloi OS: Workspace and access control

create type public.workspace_role as enum (
  'owner',
  'admin',
  'designer',
  'operations',
  'finance',
  'viewer'
);

create table public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.workspace_role not null default 'viewer',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

alter table public.knowledge_objects add column workspace_id uuid references public.workspaces(id) on delete cascade;
alter table public.travellers add column workspace_id uuid references public.workspaces(id) on delete cascade;
alter table public.traveller_households add column workspace_id uuid references public.workspaces(id) on delete cascade;
alter table public.journeys add column workspace_id uuid references public.workspaces(id) on delete cascade;
alter table public.suppliers add column workspace_id uuid references public.workspaces(id) on delete cascade;

create index knowledge_objects_workspace_idx on public.knowledge_objects (workspace_id);
create index travellers_workspace_idx on public.travellers (workspace_id);
create index traveller_households_workspace_idx on public.traveller_households (workspace_id);
create index journeys_workspace_idx on public.journeys (workspace_id);
create index suppliers_workspace_idx on public.suppliers (workspace_id);

create or replace function public.is_workspace_member(target_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.workspace_members wm
    where wm.workspace_id = target_workspace_id
      and wm.user_id = auth.uid()
      and wm.active = true
  );
$$;

create or replace function public.has_workspace_role(
  target_workspace_id uuid,
  allowed_roles public.workspace_role[]
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.workspace_members wm
    where wm.workspace_id = target_workspace_id
      and wm.user_id = auth.uid()
      and wm.active = true
      and wm.role = any(allowed_roles)
  );
$$;

alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.knowledge_objects enable row level security;
alter table public.knowledge_sources enable row level security;
alter table public.knowledge_relationships enable row level security;
alter table public.knowledge_versions enable row level security;
alter table public.travellers enable row level security;
alter table public.traveller_households enable row level security;
alter table public.traveller_household_members enable row level security;
alter table public.traveller_preferences enable row level security;
alter table public.traveller_constraints enable row level security;
alter table public.traveller_interactions enable row level security;
alter table public.journeys enable row level security;
alter table public.journey_travellers enable row level security;
alter table public.journey_days enable row level security;
alter table public.journey_components enable row level security;
alter table public.journey_design_decisions enable row level security;
alter table public.suppliers enable row level security;
alter table public.supplier_contacts enable row level security;
alter table public.supplier_products enable row level security;
alter table public.supplier_rates enable row level security;
alter table public.supplier_assessments enable row level security;

create policy workspaces_select_member
on public.workspaces for select
to authenticated
using (public.is_workspace_member(id));

create policy workspace_members_select_member
on public.workspace_members for select
to authenticated
using (public.is_workspace_member(workspace_id));

create policy workspace_members_manage_admin
on public.workspace_members for all
to authenticated
using (public.has_workspace_role(workspace_id, array['owner','admin']::public.workspace_role[]))
with check (public.has_workspace_role(workspace_id, array['owner','admin']::public.workspace_role[]));

create policy knowledge_objects_member_access
on public.knowledge_objects for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

create policy travellers_member_access
on public.travellers for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

create policy traveller_households_member_access
on public.traveller_households for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

create policy journeys_member_access
on public.journeys for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

create policy suppliers_member_access
on public.suppliers for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

-- Child-table policies derive workspace access from their parent records.
create policy knowledge_sources_parent_access
on public.knowledge_sources for all
to authenticated
using (exists (
  select 1 from public.knowledge_objects ko
  where ko.id = knowledge_object_id and public.is_workspace_member(ko.workspace_id)
))
with check (exists (
  select 1 from public.knowledge_objects ko
  where ko.id = knowledge_object_id and public.is_workspace_member(ko.workspace_id)
));

create policy knowledge_relationships_parent_access
on public.knowledge_relationships for all
to authenticated
using (exists (
  select 1 from public.knowledge_objects ko
  where ko.id = from_object_id and public.is_workspace_member(ko.workspace_id)
))
with check (exists (
  select 1 from public.knowledge_objects ko
  where ko.id = from_object_id and public.is_workspace_member(ko.workspace_id)
));

create policy knowledge_versions_parent_access
on public.knowledge_versions for all
to authenticated
using (exists (
  select 1 from public.knowledge_objects ko
  where ko.id = knowledge_object_id and public.is_workspace_member(ko.workspace_id)
))
with check (exists (
  select 1 from public.knowledge_objects ko
  where ko.id = knowledge_object_id and public.is_workspace_member(ko.workspace_id)
));

create policy traveller_preferences_parent_access
on public.traveller_preferences for all
to authenticated
using (exists (
  select 1 from public.travellers t
  where t.id = traveller_id and public.is_workspace_member(t.workspace_id)
))
with check (exists (
  select 1 from public.travellers t
  where t.id = traveller_id and public.is_workspace_member(t.workspace_id)
));

create policy traveller_constraints_parent_access
on public.traveller_constraints for all
to authenticated
using (exists (
  select 1 from public.travellers t
  where t.id = traveller_id and public.is_workspace_member(t.workspace_id)
))
with check (exists (
  select 1 from public.travellers t
  where t.id = traveller_id and public.is_workspace_member(t.workspace_id)
));

create policy traveller_interactions_parent_access
on public.traveller_interactions for all
to authenticated
using (exists (
  select 1 from public.travellers t
  where t.id = traveller_id and public.is_workspace_member(t.workspace_id)
))
with check (exists (
  select 1 from public.travellers t
  where t.id = traveller_id and public.is_workspace_member(t.workspace_id)
));

create policy journey_days_parent_access
on public.journey_days for all
to authenticated
using (exists (
  select 1 from public.journeys j
  where j.id = journey_id and public.is_workspace_member(j.workspace_id)
))
with check (exists (
  select 1 from public.journeys j
  where j.id = journey_id and public.is_workspace_member(j.workspace_id)
));

create policy journey_components_parent_access
on public.journey_components for all
to authenticated
using (exists (
  select 1 from public.journeys j
  where j.id = journey_id and public.is_workspace_member(j.workspace_id)
))
with check (exists (
  select 1 from public.journeys j
  where j.id = journey_id and public.is_workspace_member(j.workspace_id)
));

create policy journey_design_decisions_parent_access
on public.journey_design_decisions for all
to authenticated
using (exists (
  select 1 from public.journeys j
  where j.id = journey_id and public.is_workspace_member(j.workspace_id)
))
with check (exists (
  select 1 from public.journeys j
  where j.id = journey_id and public.is_workspace_member(j.workspace_id)
));

create policy supplier_contacts_parent_access
on public.supplier_contacts for all
to authenticated
using (exists (
  select 1 from public.suppliers s
  where s.id = supplier_id and public.is_workspace_member(s.workspace_id)
))
with check (exists (
  select 1 from public.suppliers s
  where s.id = supplier_id and public.is_workspace_member(s.workspace_id)
));

create policy supplier_products_parent_access
on public.supplier_products for all
to authenticated
using (exists (
  select 1 from public.suppliers s
  where s.id = supplier_id and public.is_workspace_member(s.workspace_id)
))
with check (exists (
  select 1 from public.suppliers s
  where s.id = supplier_id and public.is_workspace_member(s.workspace_id)
));

create trigger workspaces_set_updated_at
before update on public.workspaces
for each row execute function public.set_updated_at();

comment on function public.is_workspace_member(uuid) is 'True when the authenticated user is an active member of the workspace.';
comment on function public.has_workspace_role(uuid, public.workspace_role[]) is 'Role gate for privileged workspace operations.';
