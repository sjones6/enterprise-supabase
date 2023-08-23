BEGIN;

select plan(1);

SELECT tests.create_supabase_user('test_owner', 'owner@test.com');
SELECT tests.create_supabase_user('test_admin', 'admin@test.com');
SELECT tests.create_supabase_user('test_read_only', 'read_only@test.com');
SELECT tests.create_supabase_user('test_not_member', 'not_member@test.com');

SELECT tests.authenticate_as('test_owner');
SELECT authz.create_organization('test org');
SELECT tests.authenticate_as('test_owner');

DO $$
DECLARE
   organization_id uuid;
   group_id uuid = gen_random_uuid();
BEGIN
    SELECT id FROM authz.organizations
        INTO organization_id
        WHERE name = 'test org';

   PERFORM authz.add_member_to_organization(
        organization_id,
        tests.get_supabase_uid('test_admin'),
        (SELECT id FROM authz.roles WHERE slug = 'admin')
   );

    PERFORM authz.add_member_to_organization(
        organization_id,
        tests.get_supabase_uid('test_read_only'),
        (SELECT id FROM authz.roles WHERE slug = 'read-only')
   );

   INSERT INTO authz.groups(organization_id, name) VALUES (
        organization_id,
        'test group'
   );

    SELECT id INTO group_id FROM authz.groups WHERE name = 'test group';

   PERFORM authz.edit_group(group_id, organization_id, 'test-group', '', ARRAY[
    tests.get_supabase_uid('test_read_only'),
    tests.get_supabase_uid('test_admin')
   ]::uuid[]);
END$$;

SELECT tests.authenticate_as('test_admin');

PREPARE select_user_permissions_admin AS 
    SELECT permission FROM authz.user_permissions up 
    WHERE up.user_id = tests.get_supabase_uid('test_admin');
SELECT results_eq('select_user_permissions_admin', ARRAY[
        'edit-organization',
        'select-organization',
        'delete-member',
        'add-member',
        'edit-member',
        'select-member',
        'delete-role',
        'add-role',
        'edit-role',
        'select-role',
        'delete-group',
        'add-group',
        'edit-group',
        'select-group'
    ]::authz.permission[], 'admin has most org permissions');

SELECT tests.clear_authentication();

SELECT * FROM finish();

ROLLBACK;