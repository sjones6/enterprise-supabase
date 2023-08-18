BEGIN;
CREATE EXTENSION "basejump-supabase_test_helpers";

select plan(5);

SELECT tests.create_supabase_user('test_owner', 'owner@test.com');
SELECT tests.create_supabase_user('test_member', 'member@test.com');

SELECT tests.authenticate_as('test_owner');
SELECT authz.create_organization('test org');

-- check owners permissions
-- for delete
PREPARE has_one_permission_test AS
    SELECT * FROM authz.has_permission_in_organization(
        (SELECT id FROM authz.organizations WHERE name = 'test org'),
        'delete-organization'::authz.permission
    );
SELECT results_eq('has_one_permission_test', ARRAY[true], 'returns true if user has permission');

PREPARE has_all_permission_test AS
    SELECT * FROM authz.has_all_permissions_in_organization(
        (SELECT id FROM authz.organizations WHERE name = 'test org'),
        ARRAY[
            'delete-organization',
            'select-group',
            'edit-group'
        ]::authz.permission[]
    );
SELECT results_eq('has_all_permission_test', ARRAY[true], 'returns true if user has all permissions');


SELECT authz.add_member_to_organization(
    (SELECT id FROM authz.organizations WHERE name = 'test org'),
    tests.get_supabase_uid('test_member'),
    (SELECT id FROM authz.roles WHERE slug = 'read-only')
);

SELECT tests.clear_authentication();

SELECT tests.authenticate_as('test_member');

PREPARE select_user_permissions AS 
    SELECT permission FROM authz.user_permissions up 
    WHERE up.user_id = tests.get_supabase_uid('test_member');

-- After the organization is created, the user should have
-- a role created with all permissions available.
SELECT results_eq('select_user_permissions', ARRAY[
        'select-organization'::authz.permission,
        'select-member'::authz.permission,
        'select-role'::authz.permission,
        'select-group'::authz.permission
    ]);

PREPARE has_any_permission_in_organization_test_false AS
    SELECT * FROM authz.has_any_permission_in_organization(
        (SELECT id FROM authz.organizations WHERE name = 'test org'),
        ARRAY[
            'edit-organization',
            'delete-organization'
        ]::authz.permission[]
    );
SELECT results_eq('has_any_permission_in_organization_test_false', ARRAY[false], 'returns false if does not have any permissions');

PREPARE has_any_permission_in_organization_test_true AS
    SELECT * FROM authz.has_any_permission_in_organization(
        (SELECT id FROM authz.organizations WHERE name = 'test org'),
        ARRAY[
            'select-group',
            'delete-organization'
        ]::authz.permission[]
    );
SELECT results_eq('has_any_permission_in_organization_test_true', ARRAY[true], 'returns true if the user does has one permission');

SELECT tests.clear_authentication();

SELECT * FROM finish();

ROLLBACK;