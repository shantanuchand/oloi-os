-- Oloi OS local development seed.
-- Uses stable UUIDs so tests and examples can reference the same records.

insert into public.workspaces (id, name, slug)
values ('00000000-0000-0000-0000-000000000001', 'Oloi Shorua', 'oloi-shorua')
on conflict (id) do nothing;

insert into public.knowledge_objects (
  id,
  workspace_id,
  object_type,
  title,
  slug,
  summary,
  confidence,
  metadata
) values
  (
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'destination',
    'Masai Mara',
    'masai-mara',
    'Core East African safari destination.',
    100,
    '{"country":"Kenya"}'::jsonb
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    'supplier',
    'Example Mara Camp',
    'example-mara-camp',
    'Development-only example supplier.',
    20,
    '{"seed":true}'::jsonb
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000001',
    'traveller',
    'Jane Doe',
    'jane-doe',
    'Development-only example traveller.',
    20,
    '{"seed":true}'::jsonb
  ),
  (
    '10000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000001',
    'journey',
    'Jane Doe Kenya Journey',
    'jane-doe-kenya-journey',
    'Development-only example journey.',
    20,
    '{"seed":true}'::jsonb
  )
on conflict (id) do nothing;

insert into public.knowledge_relationships (
  from_object_id,
  relationship_type,
  to_object_id,
  confidence,
  metadata
) values (
  '10000000-0000-0000-0000-000000000002',
  'located_in',
  '10000000-0000-0000-0000-000000000001',
  20,
  '{"seed":true}'::jsonb
)
on conflict do nothing;

insert into public.travellers (
  id,
  workspace_id,
  knowledge_object_id,
  status,
  title,
  first_name,
  last_name,
  primary_email,
  country_of_residence,
  metadata
) values (
  '20000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000003',
  'prospect',
  'Ms',
  'Jane',
  'Doe',
  'janedoe@example.com',
  'United Arab Emirates',
  '{"seed":true}'::jsonb
)
on conflict (id) do nothing;

insert into public.suppliers (
  id,
  workspace_id,
  knowledge_object_id,
  trading_name,
  supplier_type,
  status,
  country,
  default_currency,
  metadata
) values (
  '30000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000002',
  'Example Mara Camp',
  'accommodation',
  'prospect',
  'Kenya',
  'USD',
  '{"seed":true}'::jsonb
)
on conflict (id) do nothing;

insert into public.journeys (
  id,
  workspace_id,
  knowledge_object_id,
  code,
  title,
  status,
  lead_traveller_id,
  proposed_start_date,
  proposed_end_date,
  adults,
  currency,
  target_budget,
  narrative_intent,
  metadata
) values (
  '40000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000004',
  'DEV-0001',
  'Jane Doe Kenya Journey',
  'discovery',
  '20000000-0000-0000-0000-000000000001',
  current_date + 90,
  current_date + 96,
  2,
  'USD',
  12000,
  'A private, unhurried first safari.',
  '{"seed":true}'::jsonb
)
on conflict (id) do nothing;
