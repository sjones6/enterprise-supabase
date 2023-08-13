CREATE SCHEMA IF NOT EXISTS authz;

GRANT USAGE ON SCHEMA authz 
    TO postgres, anon, authenticated, service_role, dashboard_user;

GRANT USAGE, SELECT 
    ON ALL SEQUENCES IN SCHEMA authz 
    TO postgres, authenticated, service_role, dashboard_user, anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA authz
    GRANT ALL ON TABLES TO postgres, service_role, dashboard_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA authz
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

-- 
-- Trigger
-- 
CREATE OR REPLACE FUNCTION authz.add_timestamps()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
    BEGIN
        NEW.updated_at = now() at time zone 'utc';
        IF (TG_OP = 'INSERT') THEN
            NEW.created_at = now() at time zone 'utc';
        END IF;
        RETURN NEW;
    END;
$BODY$;

ALTER FUNCTION authz.add_timestamps()
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION authz.add_timestamps() TO PUBLIC;

-- 
--  Tables
-- 

-- Organizations
CREATE TABLE IF NOT EXISTS authz.organizations
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL COLLATE pg_catalog."default",
    updated_at timestamp with time zone,
    created_at timestamp with time zone
)
TABLESPACE pg_default;

CREATE TRIGGER organizations_timestamps
    BEFORE INSERT OR UPDATE 
    ON authz.organizations
    FOR EACH ROW
    EXECUTE FUNCTION authz.add_timestamps();

-- Members
CREATE TABLE IF NOT EXISTS authz.members
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL REFERENCES authz.organizations (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp with time zone,
    created_at timestamp with time zone,
    CONSTRAINT members_organizations_id_user_id_key UNIQUE (organization_id, user_id)     
)
TABLESPACE pg_default;

CREATE TRIGGER members_timestamps
    BEFORE INSERT OR UPDATE 
    ON authz.members
    FOR EACH ROW
    EXECUTE FUNCTION authz.add_timestamps();

-- Roles
CREATE TABLE IF NOT EXISTS authz.roles
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL COLLATE pg_catalog."default",
    slug text NOT NULL UNIQUE COLLATE pg_catalog."default",
    description text COLLATE pg_catalog."default",
    -- If null, indicates a system role
    organization_id uuid REFERENCES authz.organizations (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp with time zone,
    created_at timestamp with time zone
)
TABLESPACE pg_default;

CREATE TRIGGER roles_timestamps
    BEFORE INSERT OR UPDATE 
    ON authz.roles
    FOR EACH ROW
    EXECUTE FUNCTION authz.add_timestamps();

-- Permissions
CREATE TABLE IF NOT EXISTS authz.permissions
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL COLLATE pg_catalog."default",
    slug text NOT NULL UNIQUE COLLATE pg_catalog."default",
    description text NOT NULL COLLATE pg_catalog."default" DEFAULT '',
    updated_at timestamp with time zone,
    created_at timestamp with time zone
)
TABLESPACE pg_default;

CREATE TRIGGER permissions_timestamps
    BEFORE INSERT OR UPDATE 
    ON authz.permissions
    FOR EACH ROW
    EXECUTE FUNCTION authz.add_timestamps();

-- Role_Permissions (join)
CREATE TABLE IF NOT EXISTS authz.role_permissions
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    role_id uuid NOT NULL REFERENCES authz.roles (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    permission_id uuid NOT NULL REFERENCES authz.permissions (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp with time zone,
    created_at timestamp with time zone
)
TABLESPACE pg_default;

CREATE TRIGGER role_permissions_timestamps
    BEFORE INSERT OR UPDATE 
    ON authz.role_permissions
    FOR EACH ROW
    EXECUTE FUNCTION authz.add_timestamps();

-- Member_Roles (join)
CREATE TABLE IF NOT EXISTS authz.member_roles
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    role_id uuid NOT NULL REFERENCES authz.roles (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    member_id uuid NOT NULL REFERENCES authz.members (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp with time zone,
    created_at timestamp with time zone
)
TABLESPACE pg_default;

CREATE TRIGGER member_roles_timestamps
    BEFORE INSERT OR UPDATE 
    ON authz.member_roles
    FOR EACH ROW
    EXECUTE FUNCTION authz.add_timestamps();


-- Groups
CREATE TABLE IF NOT EXISTS authz.groups
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL COLLATE pg_catalog."default",
    description text NOT NULL COLLATE pg_catalog."default" DEFAULT '',
    organization_id uuid NOT NULL REFERENCES authz.organizations (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp with time zone,
    created_at timestamp with time zone  
)
TABLESPACE pg_default;

CREATE INDEX public_groups_org_id ON authz.groups(organization_id);

CREATE TRIGGER groups_timestamps
    BEFORE INSERT OR UPDATE 
    ON authz.groups
    FOR EACH ROW
    EXECUTE FUNCTION authz.add_timestamps();

-- Group Roles
CREATE TABLE IF NOT EXISTS authz.group_roles
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    role_id uuid NOT NULL REFERENCES authz.roles (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    group_id uuid NOT NULL REFERENCES authz.groups (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp with time zone,
    created_at timestamp with time zone,
    CONSTRAINT group_roles_group__id_role_id_key UNIQUE (group_id, role_id)   
)
TABLESPACE pg_default;

CREATE TRIGGER group_roles_timestamps
    BEFORE INSERT OR UPDATE 
    ON authz.group_roles
    FOR EACH ROW
    EXECUTE FUNCTION authz.add_timestamps();

-- Group Members
CREATE TABLE IF NOT EXISTS authz.group_members
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    group_id uuid NOT NULL REFERENCES authz.groups (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    member_id uuid NOT NULL REFERENCES authz.members (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp with time zone,
    created_at timestamp with time zone,
    CONSTRAINT group_members_group_id_member_id_key UNIQUE (group_id, member_id)     
)
TABLESPACE pg_default;

CREATE TRIGGER group_members_timestamps
    BEFORE INSERT OR UPDATE 
    ON authz.group_members
    FOR EACH ROW
    EXECUTE FUNCTION authz.add_timestamps();

-- 
-- Functions
-- 

-- 
-- List users permissions for organization
-- Check permission for organization
-- 

-- 
-- Get all permissions in an organization
-- 
CREATE TYPE authz.permissions_row AS (
    id uuid,
    name text,
    description text,
    slug text,
    updated_at timestamp with time zone,
    created_at timestamp with time zone
);

CREATE OR REPLACE FUNCTION authz.get_permissions_in_organization(
    organization_id uuid
	)
    RETURNS SETOF authz.permissions_row
    LANGUAGE 'sql'
    COST 100
    STABLE SECURITY DEFINER 
    PARALLEL UNSAFE
    ROWS 1000
    SET search_path=authz
AS $BODY$
    SELECT (p.id, p.name, p.description, p.slug, p.updated_at, p.created_at)
      FROM permissions p
      LEFT JOIN role_permissions rp ON rp.permission_id = p.id
      WHERE rp.role_id IN (
        SELECT r.id FROM roles r
            LEFT JOIN member_roles mr ON mr.role_id = r.id
            LEFT JOIN members m ON mr.member_id = m.id
            WHERE m.user_id = auth.uid() AND m.organization_id = $1
        UNION
        SELECT r.id FROM roles r
            LEFT JOIN group_roles gr ON r.id = gr.role_id
            LEFT JOIN groups g on g.id = gr.group_id
            LEFT JOIN group_members gm ON gm.group_id = g.id
            LEFT JOIN members m ON m.id = gm.member_id
            WHERE m.user_id = auth.uid() AND g.organization_id = $1
      )
$BODY$;

ALTER FUNCTION authz.get_permissions_in_organization(organization_id uuid)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION authz.get_permissions_in_organization(organization_id uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authz.get_permissions_in_organization(organization_id uuid) TO authenticated;

-- 
-- Get all permission slugs in an organization
-- 
CREATE OR REPLACE FUNCTION authz.get_permission_slugs_in_organization(
    organization_id uuid
	)
    RETURNS SETOF text
    LANGUAGE 'sql'
    COST 100
    STABLE SECURITY DEFINER 
    PARALLEL UNSAFE
    ROWS 1000
    SET search_path=authz
AS $BODY$
    SELECT slug FROM authz.get_permissions_in_organization(organization_id);
$BODY$;

ALTER FUNCTION authz.get_permission_slugs_in_organization(organization_id uuid)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION authz.get_permission_slugs_in_organization(organization_id uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authz.get_permission_slugs_in_organization(organization_id uuid) TO authenticated;

-- 
-- Check if authenticated user has permission in an organization.
-- 
CREATE OR REPLACE FUNCTION authz.has_permission_in_organization(
    organization_id uuid,
    permission text
	)
    RETURNS boolean
    LANGUAGE 'sql'
    COST 100
    STABLE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=authz
AS $BODY$
    SELECT $2 IN (
        SELECT authz.get_permission_slugs_in_organization($1)
    );
$BODY$;

ALTER FUNCTION authz.has_permission_in_organization(organization_id uuid, permission text)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION authz.has_permission_in_organization(organization_id uuid, permission text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authz.has_permission_in_organization(organization_id uuid, permission text) TO authenticated;

-- 
-- Check if the authenticated user's permissions overlaps with any one of a list of permissions.
-- 
CREATE OR REPLACE FUNCTION authz.has_any_permission_in_organization(
    organization_id uuid,
    permission text[]
	)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    STABLE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=authz
AS $BODY$
    DECLARE
        has_permission boolean;
    BEGIN
        has_permission = $2 && (
            SELECT authz.get_permission_slugs_in_organization($1)
        );
        return has_permission;
    END;
$BODY$;

ALTER FUNCTION authz.has_any_permission_in_organization(organization_id uuid, permission text[])
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION authz.has_any_permission_in_organization(organization_id uuid, permission text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authz.has_any_permission_in_organization(organization_id uuid, permission text[]) TO authenticated;

-- 
-- Check if authenticted user has a list of permissions.
-- 
CREATE OR REPLACE FUNCTION authz.has_all_permissions_in_organization(
    organization_id uuid,
    permission text[]
	)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    STABLE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=authz
AS $BODY$
    DECLARE
        has_permission boolean;
    BEGIN
        has_permission = $2 <@ (
            SELECT authz.get_permission_slugs_in_organization($1)
        );
        return has_permission;
    END;
$BODY$;

ALTER FUNCTION authz.has_all_permissions_in_organization(organization_id uuid, permission text[])
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION authz.has_all_permissions_in_organization(organization_id uuid, permission text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authz.has_all_permissions_in_organization(organization_id uuid, permission text[]) TO authenticated;

-- 
-- Check if user has group membership
-- 
CREATE OR REPLACE FUNCTION authz.has_group_membership(group_id uuid)
    RETURNS boolean
    LANGUAGE 'sql'
    STABLE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=authz
AS $BODY$
    SElECT EXISTS(
        SELECT 1 FROM group_members gm
            LEFT JOIN authz.members m ON m.id = gm.member_id
            WHERE gm.id = group_id AND m.user_id = auth.uid()
    )
$BODY$;

ALTER FUNCTION authz.has_group_membership(group_id uuid)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION authz.has_group_membership(group_id uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authz.has_group_membership(group_id uuid) TO authenticated;

-- 
-- Check if the role is available to the designated organization
-- 
CREATE OR REPLACE FUNCTION authz.role_available_in_organization(
    role_id uuid,
    organization_id uuid
	)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    STABLE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=authz
AS $BODY$
    DECLARE
        role_organization_id uuid;
    BEGIN
        SELECT r.organization_id  FROM authz.roles r 
            INTO role_organization_id
            WHERE r.id = role_id;
        return (organization_id IS NULL OR organization_id = role_organization_id);
    END;
$BODY$;

ALTER FUNCTION authz.role_available_in_organization(role_id uuid, organization_id uuid)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION authz.role_available_in_organization(role_id uuid, organization_id uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authz.role_available_in_organization(role_id uuid, organization_id uuid) TO authenticated;

-- 
-- Utility function to insert permissions and associated to roles
-- 
-- 
CREATE OR REPLACE FUNCTION authz.insert_role_permission(role_slugs text[], name text, permission_slug text, description text)
  RETURNS void
  SET search_path=authz
AS $$
DECLARE                                                     
  role_name text;  
  permission_id uuid;
BEGIN
    WITH permission AS (
        INSERT INTO authz.permissions (name, slug, description) 
            VALUES ($2, $3, $4) 
            RETURNING id
    ) SELECT permission.id FROM permission INTO permission_id;
    FOREACH role_name IN ARRAY $1
    LOOP
        INSERT INTO authz.role_permissions (role_id, permission_id) 
            VALUES (
                (SELECT id FROM authz.roles r WHERE r.slug = role_name),
                permission_id
            );
    END LOOP;

    -- Add all permissions to the 'super-admin'
    INSERT INTO authz.role_permissions (role_id, permission_id) 
        VALUES (
            (SELECT id FROM authz.roles r WHERE r.slug = 'super-admin'),
            permission_id
        );
END;
$$
LANGUAGE plpgsql;

ALTER FUNCTION authz.insert_role_permission(role_slugs text[], name text, permission_slug text, description text)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION authz.insert_role_permission(role_slugs text[], name text, permission_slug text, description text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authz.insert_role_permission(role_slugs text[], name text, permission_slug text, description text) TO CURRENT_ROLE;

-- 
-- Create organization, and assign initial role to creating user
-- 
CREATE OR REPLACE FUNCTION authz.create_organization(name text)
  RETURNS authz.organizations
  LANGUAGE 'plpgsql'
  SECURITY DEFINER SET search_path=authz
  AS $BODY$
  DECLARE
    organization_id uuid = gen_random_uuid();
    member_id uuid = gen_random_uuid();
    organization organizations;
  BEGIN

    -- create the organization
    INSERT INTO authz.organizations(id, name)
      VALUES(organization_id, name);

    --   create membership in the organization
    INSERT INTO authz.members(id, organization_id, user_id)
      VALUES(member_id, organization_id, auth.uid());

    --   make the creator the owner in the new org
    INSERT  INTO authz.member_roles(role_id, member_id)
      VALUES(
        (SELECT id FROM authz.roles r WHERE r.slug = 'owner'),
        member_id
      );
    SELECT * FROM authz.organizations INTO organization WHERE id = organization_id;
    return organization;
  END;
$BODY$;

ALTER FUNCTION authz.create_organization(name text)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION authz.create_organization(name text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authz.create_organization(name text) TO authenticated;
 

-- 
-- Set the user's active organization
-- 
CREATE OR REPLACE FUNCTION authz.set_active_organization(active_organization_id uuid)
    RETURNS "text"
    LANGUAGE "plpgsql"
    SECURITY DEFINER 
    SET search_path=authz
    AS $$
    DECLARE
        is_member boolean;
    BEGIN

        SElECT EXISTS(
            SELECT 1 FROM members m
                WHERE m.user_id = auth.uid() AND m.organization_id = active_organization_id
        ) INTO is_member;
        IF is_member = TRUE THEN
            UPDATE auth.users SET raw_app_meta_data = 
            raw_app_meta_data || 
                json_build_object('organization', active_organization_id)::jsonb where id = auth.uid();
            RETURN 'OK';
        END IF;
        
        RAISE EXCEPTION 'User is not member of organization --> %', active_organization_id
            USING HINT = 'Please check your organization ID';
    END;
$$;

ALTER FUNCTION authz.set_active_organization(active_organization_id uuid)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION authz.set_active_organization(active_organization_id uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authz.set_active_organization(active_organization_id uuid) TO authenticated;

-- 
-- RLS
-- 

-- Organizations
ALTER TABLE IF EXISTS authz.organizations
    OWNER to CURRENT_ROLE;

REVOKE ALL ON TABLE authz.organizations FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.organizations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.organizations TO service_role;
GRANT ALL ON TABLE authz.organizations TO CURRENT_ROLE;

ALTER TABLE IF EXISTS authz.organizations
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Require `select-organization` in org"
    ON authz.organizations 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ( authz.has_permission_in_organization(organizations.id, 'select-organization') );

CREATE POLICY "Users can create organizations"
    ON authz.organizations 
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ( auth.uid() IS NOT NULL );

CREATE POLICY "Require `delete-organization` in org"
    ON authz.organizations 
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING ( authz.has_permission_in_organization(organizations.id, 'delete-organization') );

CREATE POLICY "Require `edit-organization` in org"
    ON authz.organizations 
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING ( authz.has_permission_in_organization(organizations.id, 'edit-organization') )
    WITH CHECK ( authz.has_permission_in_organization(organizations.id, 'edit-organization') );

-- Members
ALTER TABLE IF EXISTS authz.members
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS authz.members
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE authz.members FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.members TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.members TO service_role;
GRANT ALL ON TABLE authz.members TO CURRENT_ROLE;

CREATE POLICY "Requires permission `select-member` to select member"
    ON authz.members 
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ( authz.has_permission_in_organization(members.organization_id, 'select-member') );

CREATE POLICY "Requires permission `add-member` to add member"
    ON authz.members 
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ( authz.has_permission_in_organization(members.organization_id, 'add-member') );

CREATE POLICY "Requires permission `delete-member` to remove member"
    ON authz.members
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ( authz.has_permission_in_organization(members.organization_id, 'delete-member') );

CREATE POLICY "Requires permission `edit-member` to update member"
    ON authz.members 
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ( authz.has_permission_in_organization(members.organization_id, 'edit-member') )
    WITH CHECK ( authz.has_permission_in_organization(members.organization_id, 'edit-member') );

-- Member Roles (join)
ALTER TABLE IF EXISTS authz.member_roles
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS authz.member_roles
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE authz.member_roles FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.member_roles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.member_roles TO service_role;
GRANT ALL ON TABLE authz.member_roles TO CURRENT_ROLE;

CREATE POLICY "Requires permission `select-member` to view members role"
    ON authz.member_roles 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (
        authz.has_permission_in_organization(
        (SELECT organization_id FROM authz.members WHERE id = member_roles.member_id),
        'select-member'
    )
);

CREATE POLICY "Require `edit-member` in org"
    ON authz.member_roles 
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.members WHERE id = member_roles.member_id),
            'edit-member'
        ) AND authz.role_available_in_organization(
            member_roles.role_id,
            (SELECT organization_id FROM authz.members WHERE id = member_roles.member_id)
        )
    );

CREATE POLICY "Requires permission `edit-member` to remove member's role"
    ON authz.member_roles
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING (
        authz.has_permission_in_organization(
        (SELECT organization_id FROM authz.members WHERE id = member_roles.member_id),
        'edit-member'
    )
);

CREATE POLICY "Requires permission `edit-member` to update a member's role"
    ON authz.member_roles 
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.members WHERE id = member_roles.member_id),
            'edit-member'
        ) AND (
            authz.role_available_in_organization(
                member_roles.role_id,
                (SELECT organization_id FROM authz.members WHERE id = member_roles.member_id)
            )
        )
    )
    WITH CHECK (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.members WHERE id = member_roles.member_id),
            'edit-member'
        ) AND (
            authz.role_available_in_organization(
                member_roles.role_id,
                (SELECT organization_id FROM authz.members WHERE id = member_roles.member_id)
            )
        )
    )
;

-- Roles
ALTER TABLE IF EXISTS authz.roles
    OWNER to postgres;

ALTER TABLE IF EXISTS authz.roles
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE authz.roles FROM PUBLIC;
GRANT SELECT ON TABLE authz.roles TO authenticated;
GRANT SELECT ON TABLE authz.roles TO service_role;
GRANT ALL ON TABLE authz.roles TO CURRENT_ROLE;

CREATE POLICY "Authenticated and service roles can select roles"
    ON authz.roles 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated, service_role
    USING ( roles.organization_id IS NULL );

CREATE POLICY "Require `select-role` in org"
    ON authz.roles 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ( 
        authz.has_permission_in_organization(
            roles.organization_id,
            'select-role'
        )
    );

CREATE POLICY "Only `CURRENT_ROLE` can insert system roles"
    ON authz.roles 
    AS PERMISSIVE
    FOR INSERT
    TO CURRENT_ROLE
    WITH CHECK ( roles.organization_id IS NULL );

CREATE POLICY "Require `insert-role` in org"
    ON authz.roles 
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK ( 
        authz.has_permission_in_organization(
            roles.organization_id,
            'insert-role'
        )
    );

CREATE POLICY "Only `CURRENT_ROLE` can updat system roles"
    ON authz.roles 
    AS PERMISSIVE
    FOR UPDATE
    TO CURRENT_ROLE
    USING ( roles.organization_id IS NULL )
    WITH CHECK ( roles.organization_id IS NULL );

CREATE POLICY "Require `update-role` in org"
    ON authz.roles 
    AS PERMISSIVE
    FOR UPDATE
    TO CURRENT_ROLE
    USING ( 
        authz.has_permission_in_organization(
            roles.organization_id,
            'edit-role'
        )
     )
    WITH CHECK ( 
        authz.has_permission_in_organization(
            roles.organization_id,
            'edit-role'
        )
     );

CREATE POLICY "Only `CURRENT_ROLE` can delete system roles"
    ON authz.roles 
    AS PERMISSIVE
    FOR DELETE
    TO CURRENT_ROLE
    USING ( roles.organization_id IS NULL );

CREATE POLICY "Require `delete-role` in org"
    ON authz.roles 
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING ( 
        authz.has_permission_in_organization(
            roles.organization_id,
            'delete-role'
        )
     );

-- Permissions
ALTER TABLE IF EXISTS authz.permissions
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS authz.permissions
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE authz.permissions FROM PUBLIC;
GRANT SELECT ON TABLE authz.permissions TO authenticated;
GRANT SELECT ON TABLE authz.permissions TO service_role;
GRANT ALL ON TABLE authz.permissions TO CURRENT_ROLE;

CREATE POLICY "Permission select permissions"
    ON authz.permissions 
    AS PERMISSIVE
    FOR SELECT
    TO CURRENT_ROLE, authenticated, service_role
    USING ( true );

CREATE POLICY "Only `CURRENT_ROLE` can insert permissions"
    ON authz.permissions 
    AS PERMISSIVE
    FOR INSERT
    TO CURRENT_ROLE
    WITH CHECK ( true );

CREATE POLICY "Only `CURRENT_ROLE` can update permissions"
    ON authz.permissions 
    AS PERMISSIVE
    FOR UPDATE
    TO CURRENT_ROLE
    USING ( true )
    WITH CHECK ( true );

CREATE POLICY "Only `CURRENT_ROLE` can delete permissions"
    ON authz.permissions 
    AS PERMISSIVE
    FOR DELETE
    TO CURRENT_ROLE
    USING ( true );

-- Role Permissions (join)
ALTER TABLE IF EXISTS authz.role_permissions
    OWNER to postgres;

ALTER TABLE IF EXISTS authz.role_permissions
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE authz.role_permissions FROM PUBLIC;
GRANT SELECT ON TABLE authz.role_permissions TO authenticated;
GRANT SELECT ON TABLE authz.role_permissions TO service_role;
GRANT ALL ON TABLE authz.role_permissions TO CURRENT_ROLE;

CREATE POLICY "Permissive select for system role_permissions"
    ON authz.role_permissions 
    AS PERMISSIVE
    FOR SELECT
    TO CURRENT_ROLE, authenticated, service_role
    USING ( 
        (SELECT organization_id FROM authz.roles WHERE id = role_permissions.role_id) IS NULL
     );

CREATE POLICY "Select requires `select-role` in org"
    ON authz.role_permissions 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ( 
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.roles WHERE id = role_permissions.role_id),
            'select-role'
        )
     );

CREATE POLICY "Only `CURRENT_ROLE` can insert system role_permissions"
    ON authz.role_permissions 
    AS PERMISSIVE
    FOR INSERT
    TO CURRENT_ROLE
    WITH CHECK ( 
        (SELECT organization_id FROM authz.roles WHERE id = role_permissions.role_id) IS NULL
     );

CREATE POLICY "Insert requires `edit-role` in org"
    ON authz.role_permissions 
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK ( 
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.roles WHERE id = role_permissions.role_id),
            'edit-role'
        )
     );

CREATE POLICY "Only `CURRENT_ROLE` can update system role_permissions"
    ON authz.role_permissions 
    AS PERMISSIVE
    FOR UPDATE
    TO CURRENT_ROLE
    USING ( 
        (SELECT organization_id FROM authz.roles WHERE id = role_permissions.role_id) IS NULL
     )
    WITH CHECK ( 
        (SELECT organization_id FROM authz.roles WHERE id = role_permissions.role_id) IS NULL
     );

CREATE POLICY "Update requires `edit-role` in org"
    ON authz.role_permissions 
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.roles WHERE id = role_permissions.role_id),
            'edit-role'
        )
    )
    WITH CHECK ( 
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.roles WHERE id = role_permissions.role_id),
            'edit-role'
        )
     );

CREATE POLICY "Only `CURRENT_ROLE` can delete system role_permissions"
    ON authz.role_permissions 
    AS PERMISSIVE
    FOR DELETE
    TO CURRENT_ROLE
    USING ( 
        (SELECT organization_id FROM authz.roles WHERE id = role_permissions.role_id) IS NULL
     );

CREATE POLICY "Delete require `edit-role` in org"
    ON authz.role_permissions 
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.roles WHERE id = role_permissions.role_id),
            'edit-role'
        )
    );


-- Groups
ALTER TABLE IF EXISTS authz.groups
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS authz.groups
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE authz.groups FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.groups TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.groups TO service_role;
GRANT ALL ON TABLE authz.groups TO CURRENT_ROLE;

CREATE POLICY "Require `select-group` OR membership"
    ON authz.groups 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (
        authz.has_group_membership(groups.id) OR
        authz.has_permission_in_organization(
            groups.organization_id,
            'select-group'
        )        
);

CREATE POLICY "Require `add-group` in org"
    ON authz.groups 
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (
        authz.has_permission_in_organization(
            groups.organization_id,
            'add-group'
        )
    );

CREATE POLICY "Require `delete-group` in org"
    ON authz.groups
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING (
        authz.has_permission_in_organization(
            groups.organization_id,
            'delete-member'
    )
);

CREATE POLICY "Require `edit-group` in org"
    ON authz.groups 
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (
        authz.has_permission_in_organization(
            groups.organization_id,
            'edit-group'
        )
    )
    WITH CHECK (
        authz.has_permission_in_organization(
            groups.organization_id,
            'edit-group'
        )
    )
;

-- Groups Members (join)
ALTER TABLE IF EXISTS authz.group_members
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS authz.group_members
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE authz.group_members FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.group_members TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.group_members TO service_role;
GRANT ALL ON TABLE authz.group_members TO CURRENT_ROLE;

CREATE POLICY "Require `select-group` OR membership"
    ON authz.group_members 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (
        authz.has_group_membership(group_members.group_id) OR 
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_members.group_id),
            'select-group'
    )
);

CREATE POLICY "Require `edit-group` to add"
    ON authz.group_members 
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_members.group_id),
            'edit-group'
        )
    );

CREATE POLICY "Require `edit-group` to delete"
    ON authz.group_members
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_members.group_id),
            'edit-group'
        )
    );

CREATE POLICY "Require `edit-group` to update"
    ON authz.group_members 
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_members.group_id),
            'edit-group'
        )
    )
    WITH CHECK (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_members.group_id),
            'edit-group'
        )
    )
;

-- Group Roles
ALTER TABLE IF EXISTS authz.group_roles
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS authz.group_roles
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE authz.group_roles FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.group_roles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE authz.group_roles TO service_role;
GRANT ALL ON TABLE authz.group_roles TO CURRENT_ROLE;

CREATE POLICY "Require `select-group` / membership"
    ON authz.group_roles 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (
        authz.has_group_membership(group_roles.group_id) OR
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_roles.group_id),
            'select-group'
    )
);

CREATE POLICY "Require `edit-group` to add"
    ON authz.group_roles 
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_roles.group_id),
            'edit-group'
        ) AND
        authz.role_available_in_organization(
            group_roles.role_id,
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_roles.group_id)
        )
    );

CREATE POLICY "Require `edit-group` to delete"
    ON authz.group_roles
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_roles.group_id),
            'edit-group'
        ) AND
        authz.role_available_in_organization(
            group_roles.role_id,
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_roles.group_id)
        )
    );

CREATE POLICY "Require `edit-group` to update"
    ON authz.group_roles 
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_roles.group_id),
            'edit-group'
        ) AND
        authz.role_available_in_organization(
            group_roles.role_id,
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_roles.group_id)
        )
    )
    WITH CHECK (
        authz.has_permission_in_organization(
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_roles.group_id),
            'edit-group'
        ) AND
        authz.role_available_in_organization(
            group_roles.role_id,
            (SELECT organization_id FROM authz.groups g WHERE g.id = group_roles.group_id)
        )
    )
;


-- 
-- Create Default Roles 
-- 
INSERT INTO authz.roles (name, slug, description) VALUES
    ('Super Admin', 'super-admin', 'Admin rights over all organizations'),
    ('Owner', 'owner', 'Full ownership rights in the organization'),
    ('Editor' , 'editor', 'Edit records in the organization'),
    ('Read-only', 'read-only', 'Read-only rights to the organization');

-- 
-- Create Default Permissions and Roles
--

-- Organizations
SELECT authz.insert_role_permission(
    ARRAY['owner'],
    'Delete organization',
    'delete-organization',
    'Delete the organization'
);
SELECT authz.insert_role_permission(
    ARRAY['owner'],
    'Edit organization',
    'edit-organization',
    'Edit the organization'
);
SELECT authz.insert_role_permission(
    ARRAY['owner', 'editor', 'read-only'],
    'Select organization',
    'select-organization',
    'View the organization'
);

-- Members
SELECT authz.insert_role_permission(
    ARRAY['owner'],
    'Remove member',
    'delete-member',
    'Remove a member from the organization'
);
SELECT authz.insert_role_permission(
    ARRAY['owner'],
    'Add member',
    'add-member',
    'Add a member to the organization'
);
SELECT authz.insert_role_permission(
    ARRAY['owner', 'editor', 'read-only'],
    'Edit member',
    'edit-member',
    'Update a member in the organization'
);
SELECT authz.insert_role_permission(
    ARRAY['owner', 'editor', 'read-only'],
    'Select member',
    'select-member',
    'Select members in the organization'
);

-- Roles
SELECT authz.insert_role_permission(
    ARRAY['owner'],
    'Remove role',
    'delete-role',
    'Remove a role'
);
SELECT authz.insert_role_permission(
    ARRAY['owner'],
    'Add role',
    'add-role',
    'Add a role to the organization'
);
SELECT authz.insert_role_permission(
    ARRAY['owner'],
    'Edit role',
    'edit-role',
    'Update a role in the organization'
);
SELECT authz.insert_role_permission(
    ARRAY['owner', 'editor', 'read-only'],
    'Select role',
    'select-role',
    'Select roles'
);

-- Groups
SELECT authz.insert_role_permission(
    ARRAY['owner'],
    'Remove group',
    'delete-group',
    'Remove a group'
);
SELECT authz.insert_role_permission(
    ARRAY['owner'],
    'Add group',
    'add-group',
    'Add a group to the organization'
);
SELECT authz.insert_role_permission(
    ARRAY['owner'],
    'Edit group',
    'edit-group',
    'Update a group in the organization'
);
SELECT authz.insert_role_permission(
    ARRAY['owner', 'editor', 'read-only'],
    'Select group',
    'select-group',
    'Select group'
);