BEGIN;

select plan(16);

SELECT tests.create_supabase_user('test_owner', 'owner@test.com');
SELECT tests.create_supabase_user('test_admin', 'admin@test.com');
SELECT tests.create_supabase_user('test_read_only', 'ro@test.com');

SELECT tests.authenticate_as('test_owner');
SELECT authz.create_organization('test org');
SELECT tests.authenticate_as('test_owner');

SELECT authz.set_active_organization(
    (SELECT id FROM authz.organizations WHERE name = 'test org')
);

-- re-establish permissions
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

   INSERT INTO authz.groups(id, organization_id, name) VALUES (
        group_id,
        organization_id,
        'test group'
   );

   INSERT INTO authz.group_roles(organization_id, group_id, role_id, scope) VALUES (
        organization_id,
        group_id,
        (SELECT id FROM authz.roles WHERE slug = 'read-only'),
        'organization'::authz.group_role_scope
   );

    INSERT INTO authz.group_roles(organization_id, group_id, role_id, scope) VALUES (
        organization_id,
        group_id,
        (SELECT id FROM authz.roles WHERE slug = 'admin'),
        'group'::authz.group_role_scope
   );

   INSERT INTO authz.group_members ( organization_id, group_id, user_id ) VALUES (
        organization_id,
        group_id,
        tests.get_supabase_uid('test_read_only')
   ), (
        organization_id,
        group_id,
        tests.get_supabase_uid('test_admin')
   );
END$$;

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


SELECT tests.authenticate_as('test_read_only');
SELECT authz.set_active_organization(
    (SELECT id FROM authz.organizations WHERE name = 'test org')
);
SELECT tests.authenticate_as('test_read_only');

PREPARE select_user_permissions AS 
    SELECT permission FROM authz.user_permissions up 
    WHERE up.user_id = tests.get_supabase_uid('test_read_only');

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

-- 
-- Group Permissions Checks
-- 
PREPARE has_one_permission_in_group_test_db AS
    SELECT * FROM authz.has_permission_in_group(
        (SELECT id FROM authz.groups WHERE name = 'test group'),
        -- this group has a group-scoped admin role
        'add-member'::authz.permission,
        'db'::authz.strategy
    );
SELECT results_eq('has_one_permission_in_group_test_db', ARRAY[true], 'returns true if user has permission for group in DB');

PREPARE has_one_permission_in_group_test AS
    SELECT * FROM authz.has_permission_in_group(
        (SELECT id FROM authz.groups WHERE name = 'test group'),
        'add-member'::authz.permission,
        'jwt'::authz.strategy
    );
SELECT results_eq('has_one_permission_in_group_test', ARRAY[true], 'returns true if user has permission for group on JWT');

PREPARE has_any_permission_in_group_db AS
    SELECT * FROM authz.has_any_permission_in_group(
        (SELECT id FROM authz.groups WHERE name = 'test group'),
        -- this group has a group-scoped admin role
        ARRAY['add-member', 'delete-organization']::authz.permission[],
        'db'::authz.strategy
    );
SELECT results_eq('has_any_permission_in_group_db', ARRAY[true], 'returns true if user has ANY permission for group in DB');

PREPARE has_any_permission_in_group_db_false AS
    SELECT * FROM authz.has_any_permission_in_group(
        (SELECT id FROM authz.groups WHERE name = 'test group'),
        -- this group has a group-scoped admin role
        ARRAY['delete-organization']::authz.permission[],
        'db'::authz.strategy
    );
SELECT results_eq('has_any_permission_in_group_db_false', ARRAY[false], 'returns false if user does not have any permission in group');

PREPARE has_any_permission_in_group_jwt_test_false AS
    SELECT * FROM authz.has_any_permission_in_group(
        (SELECT id FROM authz.groups WHERE name = 'test group'),
        ARRAY['delete-organization']::authz.permission[],
        'jwt'::authz.strategy
    );
SELECT results_eq('has_any_permission_in_group_jwt_test_false', ARRAY[false], 'returns false if does not have ANY permission in group on JWT');


PREPARE has_any_permission_in_group_jwt_test AS
    SELECT * FROM authz.has_any_permission_in_group(
        (SELECT id FROM authz.groups WHERE name = 'test group'),
        ARRAY['add-member', 'delete-organization']::authz.permission[],
        'jwt'::authz.strategy
    );
SELECT results_eq('has_any_permission_in_group_jwt_test', ARRAY[true], 'returns true if user has any permission for group on JWT');


PREPARE has_all_permissions_in_group_db AS
    SELECT * FROM authz.has_all_permissions_in_group(
        (SELECT id FROM authz.groups WHERE name = 'test group'),
        -- this group has a group-scoped admin role
        ARRAY['add-member', 'select-organization']::authz.permission[],
        'db'::authz.strategy
    );
SELECT results_eq('has_all_permissions_in_group_db', ARRAY[true], 'returns true if user has ALL permission for group in DB');

PREPARE has_all_permissions_in_group_db_false AS
    SELECT * FROM authz.has_all_permissions_in_group(
        (SELECT id FROM authz.groups WHERE name = 'test group'),
        -- this group has a group-scoped admin role
        ARRAY['delete-organization']::authz.permission[],
        'db'::authz.strategy
    );
SELECT results_eq('has_all_permissions_in_group_db_false', ARRAY[false], 'returns false if user does not have all permission in group');


PREPARE has_all_permissions_in_group_jwt_test AS
    SELECT * FROM authz.has_all_permissions_in_group(
        (SELECT id FROM authz.groups WHERE name = 'test group'),
        ARRAY['add-member', 'select-organization']::authz.permission[],
        'jwt'::authz.strategy
    );
SELECT results_eq('has_all_permissions_in_group_jwt_test', ARRAY[true], 'returns true if has all permissions in group on JWT');


PREPARE has_all_permissions_in_group_jwt_test_false AS
    SELECT * FROM authz.has_all_permissions_in_group(
        (SELECT id FROM authz.groups WHERE name = 'test group'),
        ARRAY['add-member', 'delete-organization']::authz.permission[],
        'jwt'::authz.strategy
    );
SELECT results_eq('has_all_permissions_in_group_jwt_test_false', ARRAY[false], 'returns false if does not have all permissions in group on JWT');


SELECT tests.clear_authentication();

SELECT * FROM finish();

ROLLBACK;