BEGIN;
CREATE EXTENSION "basejump-supabase_test_helpers";

select plan(3);

select has_schema('authz', 'Authorization schema should exist');

select has_table('authz', 'organizations', 'Organization table should exit');

select tests.rls_enabled('authz', 'organizations');

SELECT * FROM finish();

ROLLBACK;