BEGIN;

select plan(5);

SELECT tests.create_supabase_user('test_owner', 'owner@test.com');
SELECT tests.create_supabase_user('test_admin', 'admin@test.com');
SELECT tests.create_supabase_user('test_read_only', 'read_only@test.com');
SELECT tests.create_supabase_user('test_not_member', 'not_member@test.com');

SELECT tests.authenticate_as('test_owner');
SELECT authz.create_organization('test org');
SELECT tests.authenticate_as('test_owner');

INSERT INTO authz.groups(organization_id, name) VALUES (
        (SELECT id FROM authz.organizations WHERE name = 'test org'),
        'test group'
);

SELECT authz.add_member_to_organization(
    (SELECT id FROM authz.organizations WHERE name = 'test org'),
    tests.get_supabase_uid('test_read_only'),
    (SELECT id FROM authz.roles WHERE slug = 'read-only')
);

-- Check user's permission before adding to group
SELECT tests.authenticate_as('test_read_only'); 
PREPARE select_user_permissions AS 
    SELECT permission FROM authz.user_permissions up 
    WHERE up.user_id = tests.get_supabase_uid('test_read_only');
SELECT results_eq('select_user_permissions', ARRAY[
        'select-organization',
        'select-member',
        'select-role',
        'select-group'
]::authz.permission[], 'read-only can only select');

SELECT authz.set_active_organization(
    (SELECT id FROM authz.organizations WHERE name = 'test org')
);

-- Edit group to add role and member
SELECT tests.authenticate_as('test_owner');

INSERT INTO authz.group_members ( organization_id, group_id, user_id ) VALUES (
    (SELECT id FROM authz.organizations WHERE name = 'test org'),
    (SELECT id FROM authz.groups WHERE name = 'test group'),
    tests.get_supabase_uid('test_read_only')
);

INSERT INTO authz.group_roles ( organization_id, group_id, role_id, scope ) VALUES (
    (SELECT id FROM authz.organizations WHERE name = 'test org'),
    (SELECT id FROM authz.groups WHERE name = 'test group'),
    (SELECT id FROM authz.roles WHERE slug = 'admin'),
    'organization'::authz.group_role_scope
);

INSERT INTO authz.group_roles ( organization_id, group_id, role_id, scope ) VALUES (
    (SELECT id FROM authz.organizations WHERE name = 'test org'),
    (SELECT id FROM authz.groups WHERE name = 'test group'),
    (SELECT id FROM authz.roles WHERE slug = 'admin'),
    'group'::authz.group_role_scope
);

-- User should now have admin permissions based on group membership
SELECT tests.authenticate_as('test_read_only'); 
PREPARE set_active_org AS SELECT authz.set_active_organization(
    (SELECT id FROM authz.organizations WHERE name = 'test org')
);
SELECT results_eq('set_active_org', ARRAY['OK']::text[]);


PREPARE select_user_permissions_with_group_membership AS 
    SELECT permission FROM authz.user_permissions up 
    WHERE up.user_id = tests.get_supabase_uid('test_read_only');
SELECT results_eq('select_user_permissions_with_group_membership', ARRAY[
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
]::authz.permission[], 'admin has all permissions except delete organization');

PREPARE select_user_permissions_for_jwt AS (SELECT (tests.get_supabase_user('test_read_only')->'raw_app_meta_data'->'organization_permissions')::text);
SELECT results_eq(
    'select_user_permissions_for_jwt',
    ARRAY[
        '["edit-organization", "select-organization", "delete-member", "add-member", "edit-member", "select-member", "delete-role", "add-role", "edit-role", "select-role", "delete-group", "add-group", "edit-group", "select-group"]'
    ]::text[], 'permissions placed on JWT'
);

PREPARE select_user_permissions_for_group_on_jwt AS (
    SELECT (tests.get_supabase_user('test_read_only')->'raw_app_meta_data'->'group_permissions'->(
        SELECT id::text FROM authz.groups WHERE name = 'test group'
    ))::text);
SELECT results_eq(
    'select_user_permissions_for_group_on_jwt',
    ARRAY[
        '["edit-organization", "select-organization", "delete-member", "add-member", "edit-member", "select-member", "delete-role", "add-role", "edit-role", "select-role", "delete-group", "add-group", "edit-group", "select-group"]'
    ]::text[], 'permissions placed on JWT'
);

SELECT tests.clear_authentication();

SELECT * FROM finish();

ROLLBACK;