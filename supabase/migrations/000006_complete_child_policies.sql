-- Oloi OS: Complete RLS policies for child tables enabled in 000005.

create policy traveller_household_members_parent_access
on public.traveller_household_members for all
to authenticated
using (exists (
  select 1 from public.traveller_households h
  where h.id = household_id and public.is_workspace_member(h.workspace_id)
))
with check (exists (
  select 1 from public.traveller_households h
  where h.id = household_id and public.is_workspace_member(h.workspace_id)
));

create policy journey_travellers_parent_access
on public.journey_travellers for all
to authenticated
using (exists (
  select 1 from public.journeys j
  where j.id = journey_id and public.is_workspace_member(j.workspace_id)
))
with check (exists (
  select 1 from public.journeys j
  where j.id = journey_id and public.is_workspace_member(j.workspace_id)
));

create policy supplier_rates_parent_access
on public.supplier_rates for all
to authenticated
using (exists (
  select 1
  from public.supplier_products p
  join public.suppliers s on s.id = p.supplier_id
  where p.id = supplier_product_id
    and public.is_workspace_member(s.workspace_id)
))
with check (exists (
  select 1
  from public.supplier_products p
  join public.suppliers s on s.id = p.supplier_id
  where p.id = supplier_product_id
    and public.is_workspace_member(s.workspace_id)
));

create policy supplier_assessments_parent_access
on public.supplier_assessments for all
to authenticated
using (exists (
  select 1 from public.suppliers s
  where s.id = supplier_id and public.is_workspace_member(s.workspace_id)
))
with check (exists (
  select 1 from public.suppliers s
  where s.id = supplier_id and public.is_workspace_member(s.workspace_id)
));
