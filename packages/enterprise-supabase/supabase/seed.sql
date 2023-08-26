CREATE SCHEMA IF NOT EXISTS seed;

GRANT USAGE ON SCHEMA seed 
    TO postgres, anon, authenticated, service_role, dashboard_user;

GRANT USAGE, SELECT 
    ON ALL SEQUENCES IN SCHEMA seed 
    TO postgres, authenticated, service_role, dashboard_user, anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA seed
    GRANT ALL ON TABLES TO postgres, service_role, dashboard_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA seed
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;


CREATE OR REPLACE FUNCTION seed.create_user(
    email text,
    password text
) RETURNS uuid AS $$
  declare
  user_id uuid;
  encrypted_pw text;
BEGIN
  user_id := gen_random_uuid();
  encrypted_pw := crypt(password, gen_salt('bf'));
  
  INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES
    ('00000000-0000-0000-0000-000000000000', user_id, 'authenticated', 'authenticated', email, encrypted_pw, '2023-05-03 19:41:43.585805+00', '2023-04-22 13:10:03.275387+00', '2023-04-22 13:10:31.458239+00', '{"provider":"email","providers":["email"]}', '{}', '2023-05-03 19:41:43.580424+00', '2023-05-03 19:41:43.585948+00', '', '', '', '');
  
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', '2023-05-03 19:41:43.582456+00', '2023-05-03 19:41:43.582497+00', '2023-05-03 19:41:43.582497+00');

  RETURN user_id;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    user_id_owner uuid;
    user_id_ro uuid;
    user_id_owner_2 uuid;
    owner_role_id uuid;
    read_only_role_id uuid;
    org_1 uuid = gen_random_uuid();
    org_2 uuid = gen_random_uuid();
    org_3 uuid = gen_random_uuid();
    group_1 uuid = gen_random_uuid();
    group_2 uuid = gen_random_uuid();
    invitation_1 uuid = gen_random_uuid();
    password text = 'Abc123!';
BEGIN
    SELECT id INTO owner_role_id FROM authz.roles r WHERE r.slug = 'owner';
    SELECT id INTO read_only_role_id FROM authz.roles r WHERE r.slug = 'read-only';

    user_id_owner = seed.create_user('owner@seed.com', password);
    user_id_ro = seed.create_user('read-only@seed.com', password);
    user_id_owner_2 = seed.create_user('owner-2@seed.com', password);


    INSERT INTO authz.organizations (id, name) VALUES
        (org_1, 'First Org'),
        (org_2, 'Second Org'),
        (org_3, 'Third Org');

    INSERT INTO authz.members (organization_id, user_id) VALUES 
        (org_1, user_id_owner),
        (org_1, user_id_ro), 
        (org_2, user_id_owner),
        (org_2, user_id_owner_2);

    UPDATE auth.users
        SET raw_app_meta_data = raw_app_meta_data || 
                            json_build_object('organization', org_1)::jsonb
        WHERE users.id = user_id_owner;

    INSERT INTO authz.member_roles (organization_id, user_id, role_id) VALUES
        -- Org 1
        (org_1, user_id_owner, owner_role_id),

        -- Org 2
        (org_2, user_id_owner_2, owner_role_id),
        (org_2, user_id_owner, read_only_role_id);
        
    INSERT INTO authz.groups (id, organization_id, name, description) VALUES
        (group_1, org_1, 'Group 1', 'Group associated with first seed org.'),
        (group_2, org_3, 'Group 2', 'Group associated with third seed org.');

    INSERT INTO authz.group_roles (organization_id, group_id, role_id, scope) VALUES
        (org_1, group_1, read_only_role_id, 'organization'::authz.group_role_scope),
        (org_3, group_2, owner_role_id, 'group'::authz.group_role_scope);

    INSERT INTO authz.group_members (organization_id, group_id, user_id) VALUES
        -- Org 1, Group 1
        (org_1, group_1, user_id_owner),
        (org_1, group_1, user_id_ro);

    INSERT INTO authz.member_invitations (organization_id, email) VALUES 
        (org_3, 'owner@seed.com');

    INSERT INTO authz.member_invitation_groups (organization_id, email, group_id) VALUES
        (org_3, 'owner@seed.com', group_2);

    INSERT INTO authz.member_invitation_roles (organization_id, email, role_id) VALUES
        (org_3, 'owner@seed.com', read_only_role_id);
        
END $$;