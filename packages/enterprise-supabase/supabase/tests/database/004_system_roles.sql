BEGIN;

select plan(9);

SELECT tests.create_supabase_user('test_owner', 'owner@test.com');
SELECT tests.create_supabase_user('test_admin', 'admin@test.com');
SELECT tests.create_supabase_user('test_read_only', 'read_only@test.com');
SELECT tests.create_supabase_user('test_not_member', 'not_member@test.com');

SELECT tests.authenticate_as('test_owner');
SELECT authz.create_organization('test org');

-- System roles
PREPARE select_roles AS 
    SELECT slug FROM authz.roles WHERE organization_id IS NULL;
SELECT results_eq('select_roles', ARRAY[
        'owner',
        'admin',
        'read-only'
    ]);

PREPARE select_owner_permissions AS 
    SELECT p.slug FROM authz.permissions p
        LEFT JOIN authz.role_permissions rp ON p.id = rp.permission_id 
        WHERE rp.role_id = (SELECT id FROM authz.roles r WHERE r.slug = 'owner');
SELECT results_eq('select_owner_permissions', ARRAY[
        'delete-organization',
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
    ]::authz.permission[], 'owner role has all permissions');

PREPARE select_admin_permissions AS 
    SELECT p.slug FROM authz.permissions p
        LEFT JOIN authz.role_permissions rp ON p.id = rp.permission_id 
        WHERE rp.role_id = (SELECT id FROM authz.roles r WHERE r.slug = 'admin');
SELECT results_eq('select_admin_permissions', ARRAY[
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
    ]::authz.permission[], 'admin role has all permissions except delete organization');

PREPARE select_read_only_role_permissions AS 
    SELECT p.slug FROM authz.permissions p
        LEFT JOIN authz.role_permissions rp ON p.id = rp.permission_id 
        WHERE rp.role_id = (SELECT id FROM authz.roles r WHERE r.slug = 'read-only');
SELECT results_eq('select_read_only_role_permissions', ARRAY[
        'select-organization',
        'select-member',
        'select-role',
        'select-group'
    ]::authz.permission[], 'read-only role can only select');

-- Admin permissions
SELECT authz.add_member_to_organization(
    (SELECT id FROM authz.organizations WHERE name = 'test org'),
    tests.get_supabase_uid('test_admin'),
    (SELECT id FROM authz.roles WHERE slug = 'admin')
);

SELECT tests.authenticate_as('test_admin');

PREPARE select_user_role_admin AS 
    SELECT slug FROM authz.roles r
        LEFT JOIN authz.member_roles mr ON mr.role_id = r.id  
        WHERE mr.user_id = tests.get_supabase_uid('test_admin');
SELECT results_eq('select_user_role_admin', ARRAY['admin'], 'user has admin role');

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
    ]::authz.permission[], 'admin has most all org permissions except delete-organization');

-- Read only permissions
SELECT tests.authenticate_as('test_owner');

SELECT authz.add_member_to_organization(
    (SELECT id FROM authz.organizations WHERE name = 'test org'),
    tests.get_supabase_uid('test_read_only'),
    (SELECT id FROM authz.roles WHERE slug = 'read-only')
);

SELECT tests.authenticate_as('test_read_only');

PREPARE select_user_role_read_only AS 
    SELECT slug FROM authz.roles r
        LEFT JOIN authz.member_roles mr ON mr.role_id = r.id  
        WHERE mr.user_id = tests.get_supabase_uid('test_read_only');
SELECT results_eq('select_user_role_read_only', ARRAY['read-only'], 'user has read-only role');

PREPARE select_user_permissions_read_only AS 
    SELECT permission FROM authz.user_permissions up 
    WHERE up.user_id = tests.get_supabase_uid('test_read_only');
SELECT results_eq('select_user_permissions_read_only', ARRAY[
        'select-organization',
        'select-member',
        'select-role',
        'select-group'
    ]::authz.permission[]), 'read only users can only perform selects';

-- Not a member
PREPARE select_user_permissions_non_member AS 
    SELECT permission FROM authz.user_permissions up 
    WHERE up.user_id = tests.get_supabase_uid('test_not_member');
SELECT results_eq('select_user_permissions_non_member', ARRAY[]::authz.permission[], 'members have no permissions');

SELECT tests.clear_authentication();

SELECT * FROM finish();

ROLLBACK;