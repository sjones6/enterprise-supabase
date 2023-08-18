BEGIN;
CREATE EXTENSION "basejump-supabase_test_helpers";

select plan(25);

select has_schema('authz', 'Authorization schema should exist');

select has_table('authz', 'organizations', 'Organization table should exist');
select tests.rls_enabled('authz', 'organizations');

select has_table('authz', 'members', 'Members table should exist');
select tests.rls_enabled('authz', 'members');

select has_table('authz', 'member_roles', 'Member Roles table should exist');
select tests.rls_enabled('authz', 'member_roles');

select has_table('authz', 'member_invitations', 'Member Invitation table should exist');
select tests.rls_enabled('authz', 'member_invitations');

select has_table('authz', 'member_invitation_roles', 'Member Invitation Roless table should exist');
select tests.rls_enabled('authz', 'member_invitation_roles');

select has_table('authz', 'member_invitation_groups', 'Member Invitation Groups table should exist');
select tests.rls_enabled('authz', 'member_invitation_groups');

select has_table('authz', 'groups', 'Groups table should exist');
select tests.rls_enabled('authz', 'groups');

select has_table('authz', 'group_roles', 'Group Roles table should exist');
select tests.rls_enabled('authz', 'group_roles');

select has_table('authz', 'group_members', 'Group Members table should exist');
select tests.rls_enabled('authz', 'group_members');

select has_table('authz', 'permissions', 'Permissions table should exist');
select tests.rls_enabled('authz', 'permissions');

select has_table('authz', 'roles', 'Roles table should exist');
select tests.rls_enabled('authz', 'roles');

select has_table('authz', 'user_permissions', 'User Permissions table should exist');
select tests.rls_enabled('authz', 'user_permissions');

SELECT * FROM finish();

ROLLBACK;