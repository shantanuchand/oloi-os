begin;

select plan(18);

select has_table('public', 'knowledge_objects', 'knowledge_objects exists');
select has_table('public', 'knowledge_relationships', 'knowledge_relationships exists');
select has_table('public', 'knowledge_sources', 'knowledge_sources exists');
select has_table('public', 'travellers', 'travellers exists');
select has_table('public', 'traveller_preferences', 'traveller_preferences exists');
select has_table('public', 'journeys', 'journeys exists');
select has_table('public', 'journey_days', 'journey_days exists');
select has_table('public', 'journey_components', 'journey_components exists');
select has_table('public', 'suppliers', 'suppliers exists');
select has_table('public', 'supplier_products', 'supplier_products exists');
select has_table('public', 'supplier_rates', 'supplier_rates exists');
select has_table('public', 'workspaces', 'workspaces exists');
select has_table('public', 'workspace_members', 'workspace_members exists');

select col_is_pk('public', 'knowledge_objects', 'id', 'knowledge_objects.id is primary key');
select col_is_fk('public', 'travellers', 'knowledge_object_id', 'traveller links to knowledge object');
select col_is_fk('public', 'journeys', 'lead_traveller_id', 'journey links to lead traveller');
select col_is_fk('public', 'supplier_products', 'supplier_id', 'product links to supplier');
select has_function('public', 'is_workspace_member', array['uuid'], 'workspace membership function exists');

select * from finish();
rollback;
