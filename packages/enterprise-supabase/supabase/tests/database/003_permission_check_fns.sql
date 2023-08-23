BEGIN;

select plan(8);

SELECT tests.create_supabase_user('test_owner', 'owner@test.com');
SELECT tests.create_supabase_user('test_member', 'member@test.com');

SELECT tests.authenticate_as('test_owner');
SELECT authz.create_organization('test org');
SELECT tests.authenticate_as('test_owner');

SELECT authz.set_active_organization(
    (SELECT id FROM authz.organizations WHERE name = 'test org')
);

-- re-establish permissions
SELECT tests.authenticate_as('test_owner');

-- check owners permissions
-- for delete

PREPARE has_one_permission_test_db AS
    SELECT * FROM authz.has_permission_in_organization(
        (SELECT id FROM authz.organizations WHERE name = 'test org'),
        'add-member'::authz.permission,
        'db'::authz.strategy
    );
SELECT results_eq('has_one_permission_test_db', ARRAY[true], 'returns true if user has permission in DB');

PREPARE has_one_permission_test AS
    SELECT * FROM authz.has_permission_in_organization(
        (SELECT id FROM authz.organizations WHERE name = 'test org'),
        'add-member'::authz.permission
    );
SELECT results_eq('has_one_permission_test', ARRAY[true], 'returns true if user has permission on JWT');

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


PREPARE add_member_to_org_verify_members AS SELECT user_id FROM authz.add_member_to_organization(
    (SELECT id FROM authz.organizations WHERE name = 'test org'),
    tests.get_supabase_uid('test_member'),
    (SELECT id FROM authz.roles WHERE slug = 'read-only')
);
SELECT results_eq('add_member_to_org_verify_members', ARRAY[
        tests.get_supabase_uid('test_member')
    ], 'member is added');

PREPARE add_member_to_org AS SELECT user_id FROM authz.members m
    WHERE m.organization_id = (SELECT id FROM authz.organizations WHERE name = 'test org');
SELECT results_eq('add_member_to_org', ARRAY[
        tests.get_supabase_uid('test_owner'),
        tests.get_supabase_uid('test_member')
    ], 'verify members added');
    

SELECT tests.authenticate_as('test_member');
SELECT authz.set_active_organization(
    (SELECT id FROM authz.organizations WHERE name = 'test org')
);
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