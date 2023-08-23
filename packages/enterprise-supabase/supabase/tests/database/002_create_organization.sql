BEGIN;

select plan(3);

SELECT tests.create_supabase_user('test_owner', 'member@test.com', '555-555-5555');
SELECT tests.authenticate_as('test_owner');

PREPARE create_organization_test AS
    SELECT name FROM authz.create_organization('test org');
SELECT results_eq('create_organization_test', ARRAY['test org']);

SELECT tests.authenticate_as('test_owner');

PREPARE select_user_permissions AS 
    SELECT permission FROM authz.user_permissions up 
    WHERE up.organization_id = (SELECT id FROM authz.organizations o WHERE o.name = 'test org') 
        AND up.user_id = tests.get_supabase_uid('test_owner');

-- After the organization is created, the user should have
-- a role created with all permissions available.
SELECT results_eq('select_user_permissions', ARRAY[
        'delete-organization'::authz.permission,
        'edit-organization'::authz.permission,
        'select-organization'::authz.permission,
        'delete-member'::authz.permission,
        'add-member'::authz.permission,
        'edit-member'::authz.permission,
        'select-member'::authz.permission,
        'delete-role'::authz.permission,
        'add-role'::authz.permission,
        'edit-role'::authz.permission,
        'select-role'::authz.permission,
        'delete-group'::authz.permission,
        'add-group'::authz.permission,
        'edit-group'::authz.permission,
        'select-group'::authz.permission
    ]);

SELECT tests.authenticate_as('test_owner');

PREPARE select_member_count AS 
    SELECT count(*)::int FROM authz.members m
    WHERE m.organization_id = (
        SELECT id FROM authz.organizations o WHERE o.name = 'test org'
    );

SELECT results_eq('select_member_count', ARRAY[1], 'member created');

SELECT tests.clear_authentication();

SELECT * FROM finish();

ROLLBACK;