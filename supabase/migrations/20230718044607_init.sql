CREATE SCHEMA IF NOT EXISTS public;

-- 
-- Trigger
-- 
CREATE OR REPLACE FUNCTION public.add_timestamps()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
    BEGIN
        NEW.updated_at = now();
        IF (TG_OP = 'INSERT') THEN
            NEW.created_at = now();
        END IF;
        RETURN NEW;
    END;
$BODY$;

ALTER FUNCTION public.add_timestamps()
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION public.add_timestamps() TO PUBLIC;

-- 
--  Tables
-- 

-- Organizations
CREATE TABLE IF NOT EXISTS public.organizations
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    name text COLLATE pg_catalog."default",
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL
)
TABLESPACE pg_default;

CREATE TRIGGER organizations_timestamps
    BEFORE INSERT OR UPDATE 
    ON public.organizations
    FOR EACH ROW
    EXECUTE FUNCTION public.add_timestamps();

-- Members
CREATE TABLE IF NOT EXISTS public.members
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL REFERENCES public.organizations (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    CONSTRAINT members_organizations_id_user_id_key UNIQUE (organization_id, user_id)     
)
TABLESPACE pg_default;

CREATE TRIGGER members_timestamps
    BEFORE INSERT OR UPDATE 
    ON public.members
    FOR EACH ROW
    EXECUTE FUNCTION public.add_timestamps();

-- Roles
CREATE TABLE IF NOT EXISTS public.roles
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    name text COLLATE pg_catalog."default",
    slug text UNIQUE COLLATE pg_catalog."default",
    description text COLLATE pg_catalog."default",
    -- If null, indicates a system role
    organization_id uuid REFERENCES public.organizations (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL
)
TABLESPACE pg_default;

CREATE TRIGGER roles_timestamps
    BEFORE INSERT OR UPDATE 
    ON public.roles
    FOR EACH ROW
    EXECUTE FUNCTION public.add_timestamps();

-- Permissions
CREATE TABLE IF NOT EXISTS public.permissions
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    name text COLLATE pg_catalog."default",
    slug text UNIQUE COLLATE pg_catalog."default",
    description text COLLATE pg_catalog."default",
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL
)
TABLESPACE pg_default;

CREATE TRIGGER permissions_timestamps
    BEFORE INSERT OR UPDATE 
    ON public.permissions
    FOR EACH ROW
    EXECUTE FUNCTION public.add_timestamps();

-- Role_Permissions (join)
CREATE TABLE IF NOT EXISTS public.role_permissions
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    role_id uuid NOT NULL REFERENCES public.roles (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    permission_id uuid NOT NULL REFERENCES public.permissions (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL
)
TABLESPACE pg_default;

CREATE TRIGGER role_permissions_timestamps
    BEFORE INSERT OR UPDATE 
    ON public.role_permissions
    FOR EACH ROW
    EXECUTE FUNCTION public.add_timestamps();

-- Member_Roles (join)
CREATE TABLE IF NOT EXISTS public.member_roles
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    role_id uuid NOT NULL REFERENCES public.roles (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    member_id uuid NOT NULL REFERENCES public.members (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL
)
TABLESPACE pg_default;

CREATE TRIGGER member_roles_timestamps
    BEFORE INSERT OR UPDATE 
    ON public.member_roles
    FOR EACH ROW
    EXECUTE FUNCTION public.add_timestamps();


-- Groups
CREATE TABLE IF NOT EXISTS public.groups
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL COLLATE pg_catalog."default",
    description text COLLATE pg_catalog."default" DEFAULT '',
    organization_id uuid NOT NULL REFERENCES public.organizations (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL  
)
TABLESPACE pg_default;

CREATE INDEX public_groups_org_id ON public.groups(organization_id);

CREATE TRIGGER groups_timestamps
    BEFORE INSERT OR UPDATE 
    ON public.groups
    FOR EACH ROW
    EXECUTE FUNCTION public.add_timestamps();

-- Group Roles
CREATE TABLE IF NOT EXISTS public.group_roles
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    role_id uuid NOT NULL REFERENCES public.roles (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    group_id uuid NOT NULL REFERENCES public.groups (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    CONSTRAINT group_roles_group__id_role_id_key UNIQUE (group_id, role_id)   
)
TABLESPACE pg_default;

CREATE TRIGGER group_roles_timestamps
    BEFORE INSERT OR UPDATE 
    ON public.group_roles
    FOR EACH ROW
    EXECUTE FUNCTION public.add_timestamps();

-- Group Members
CREATE TABLE IF NOT EXISTS public.group_members
(
    id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    group_id uuid NOT NULL REFERENCES public.groups (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    CONSTRAINT group_members_group_id_user_id_key UNIQUE (group_id, user_id)     
)
TABLESPACE pg_default;

CREATE TRIGGER group_members_timestamps
    BEFORE INSERT OR UPDATE 
    ON public.group_members
    FOR EACH ROW
    EXECUTE FUNCTION public.add_timestamps();

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
CREATE OR REPLACE FUNCTION public.get_permissions_in_organization(
    organization_id uuid
	)
    RETURNS SETOF text
    LANGUAGE 'sql'
    COST 100
    STABLE SECURITY DEFINER 
    PARALLEL UNSAFE
    ROWS 1000
    SET search_path=public
AS $BODY$
    SELECT p.slug
      FROM permissions p
      LEFT JOIN role_permissions rp ON rp.permission_id = p.id
      WHERE rp.role_id IN (
        SELECT r.id FROM roles r
            LEFT JOIN member_roles mr ON mr.role_id = r.id
            LEFT JOIN members m ON mr.member_id = m.id
            WHERE m.user_id = auth.uid() AND m.organization_id = $1
        INTERSECT
        SELECT r.id FROM roles r
            LEFT JOIN group_roles gr ON r.id = gr.role_id
            LEFT JOIN groups g on g.id = gr.group_id
            LEFT JOIN group_members gm ON gm.group_id = g.id
            WHERE gm.user_id = auth.uid() AND g.organization_id = $1
      )
$BODY$;

ALTER FUNCTION public.get_permissions_in_organization(organization_id uuid)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION public.get_permissions_in_organization(organization_id uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_permissions_in_organization(organization_id uuid) TO authenticated;

-- 
-- Check if authenticated user has permission in an organization.
-- 
CREATE OR REPLACE FUNCTION public.has_permission_in_organization(
    organization_id uuid,
    permission text
	)
    RETURNS boolean
    LANGUAGE 'sql'
    COST 100
    STABLE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=public
AS $BODY$
    SELECT $2 IN (
        SELECT public.get_permissions_in_organization($1)
    );
$BODY$;

ALTER FUNCTION public.has_permission_in_organization(organization_id uuid, permission text)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION public.has_permission_in_organization(organization_id uuid, permission text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_permission_in_organization(organization_id uuid, permission text) TO authenticated;

-- 
-- Check if the authenticated user's permissions overlaps with any one of a list of permissions.
-- 
CREATE OR REPLACE FUNCTION public.has_any_permission_in_organization(
    organization_id uuid,
    permission text[]
	)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    STABLE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=public
AS $BODY$
    DECLARE
        has_permission boolean;
    BEGIN
        has_permission = $2 && (
            SELECT public.get_permissions_in_organization($1)
        );
        return has_permission;
    END;
$BODY$;

ALTER FUNCTION public.has_any_permission_in_organization(organization_id uuid, permission text[])
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION public.has_any_permission_in_organization(organization_id uuid, permission text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_any_permission_in_organization(organization_id uuid, permission text[]) TO authenticated;

-- 
-- Check if authenticted user has a list of permissions.
-- 
CREATE OR REPLACE FUNCTION public.has_all_permissions_in_organization(
    organization_id uuid,
    permission text[]
	)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    STABLE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=public
AS $BODY$
    DECLARE
        has_permission boolean;
    BEGIN
        has_permission = $2 <@ (
            SELECT public.get_permissions_in_organization($1)
        );
        return has_permission;
    END;
$BODY$;

ALTER FUNCTION public.has_all_permissions_in_organization(organization_id uuid, permission text[])
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION public.has_all_permissions_in_organization(organization_id uuid, permission text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_all_permissions_in_organization(organization_id uuid, permission text[]) TO authenticated;

-- 
-- Check if user has group membership
-- 
CREATE OR REPLACE FUNCTION public.has_group_membership(group_id uuid)
    RETURNS boolean
    LANGUAGE 'sql'
    STABLE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=public
AS $BODY$
    SElECT EXISTS(
        SELECT 1 FROM group_members gm WHERE gm.id = group_id AND gm.user_id = auth.uid()
    )
$BODY$;

ALTER FUNCTION public.has_group_membership(group_id uuid)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION public.has_group_membership(group_id uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_group_membership(group_id uuid) TO authenticated;

-- 
-- Check if the role is available to the designated organization
-- 
CREATE OR REPLACE FUNCTION public.role_available_in_organization(
    role_id uuid,
    organization_id uuid
	)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    STABLE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=public
AS $BODY$
    DECLARE
        role_organization_id uuid;
    BEGIN
        SELECT r.organization_id  FROM public.roles r 
            INTO role_organization_id
            WHERE r.id = role_id;
        return (organization_id IS NULL OR organization_id = role_organization_id);
    END;
$BODY$;

ALTER FUNCTION public.role_available_in_organization(role_id uuid, organization_id uuid)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION public.role_available_in_organization(role_id uuid, organization_id uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.role_available_in_organization(role_id uuid, organization_id uuid) TO authenticated;

-- 
-- Utility function to insert permissions and associated to roles
-- 
-- 
CREATE OR REPLACE FUNCTION public.insert_role_permission(role_slugs text[], name text, permission_slug text, description text)
  RETURNS void
  SET search_path=public
AS $$
DECLARE                                                     
  role_name text;  
  permission_id uuid;
BEGIN
    WITH permission AS (
        INSERT INTO public.permissions (name, slug, description) 
            VALUES ($2, $3, $4) 
            RETURNING id
    ) SELECT permission.id FROM permission INTO permission_id;
    FOREACH role_name IN ARRAY $1
    LOOP
        INSERT INTO public.role_permissions (role_id, permission_id) 
            VALUES (
                (SELECT id FROM public.roles r WHERE r.slug = role_name),
                permission_id
            );
    END LOOP;

    -- Add all permissions to the 'super-admin'
    INSERT INTO public.role_permissions (role_id, permission_id) 
        VALUES (
            (SELECT id FROM public.roles r WHERE r.slug = 'super-admin'),
            permission_id
        );
END;
$$
LANGUAGE plpgsql;

ALTER FUNCTION public.insert_role_permission(role_slugs text[], name text, permission_slug text, description text)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION public.insert_role_permission(role_slugs text[], name text, permission_slug text, description text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.insert_role_permission(role_slugs text[], name text, permission_slug text, description text) TO CURRENT_ROLE;

-- 
-- Create organization, and assign initial role to creating user
-- 
CREATE OR REPLACE FUNCTION public.create_organization(name text)
  RETURNS uuid
  LANGUAGE 'plpgsql'
  SECURITY DEFINER SET search_path = public
  AS $BODY$
  DECLARE
    organization_id uuid = gen_random_uuid();
  BEGIN
    INSERT INTO public.organizations(id, name)
      VALUES(organization_id, name);
    INSERT INTO public.members(organization_id, user_id)
      VALUES(organization_id, auth.uid());
    INSERT  INTO public.member_roles(role_id, member_id)
      VALUES(
        (SELECT id FROM public.roles r WHERE r.slug = 'owner'),
        (SELECT id FROM public.members m WHERE m.user_id = auth.uid())
      );
    return organization_id;
  END;
$BODY$;

ALTER FUNCTION public.create_organization(name text)
    OWNER TO CURRENT_ROLE;

REVOKE ALL ON FUNCTION public.create_organization(name text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_organization(name text) TO authenticated;
 
-- 
-- RLS
-- 

-- Organizations
ALTER TABLE IF EXISTS public.organizations
    OWNER to CURRENT_ROLE;

REVOKE ALL ON TABLE public.organizations FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.organizations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.organizations TO service_role;
GRANT ALL ON TABLE public.organizations TO CURRENT_ROLE;

ALTER TABLE IF EXISTS public.organizations
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Any member with role can view the organization"
    ON public.organizations 
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ( public.has_permission_in_organization(organizations.id, 'select-organization') );

CREATE POLICY "Users can create organizations"
    ON public.organizations 
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ( auth.uid() IS NOT NULL );

CREATE POLICY "Owners can delete organizations"
    ON public.organizations 
    AS RESTRICTIVE
    FOR DELETE
    TO public
    USING ( public.has_permission_in_organization(organizations.id, 'delete-organization') );

CREATE POLICY "Owners can update organizations"
    ON public.organizations 
    AS RESTRICTIVE
    FOR UPDATE
    TO public
    USING ( public.has_permission_in_organization(organizations.id, 'edit-organization') )
    WITH CHECK ( public.has_permission_in_organization(organizations.id, 'edit-organization') );

-- Members
ALTER TABLE IF EXISTS public.members
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS public.members
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.members FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.members TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.members TO service_role;
GRANT ALL ON TABLE public.members TO CURRENT_ROLE;

CREATE POLICY "Requires permission `select-member` to select member"
    ON public.members 
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ( public.has_permission_in_organization(members.organization_id, 'select-member') );

CREATE POLICY "Requires permission `add-member` to add member"
    ON public.members 
    AS RESTRICTIVE
    FOR INSERT
    TO public
    WITH CHECK ( public.has_permission_in_organization(members.organization_id, 'add-member') );

CREATE POLICY "Requires permission `delete-member` to remove member"
    ON public.members
    AS RESTRICTIVE
    FOR DELETE
    TO public
    USING ( public.has_permission_in_organization(members.organization_id, 'delete-member') );

CREATE POLICY "Requires permission `edit-member` to update member"
    ON public.members 
    AS RESTRICTIVE
    FOR UPDATE
    TO public
    USING ( public.has_permission_in_organization(members.organization_id, 'edit-member') )
    WITH CHECK ( public.has_permission_in_organization(members.organization_id, 'edit-member') );

-- Member Roles (join)
ALTER TABLE IF EXISTS public.member_roles
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS public.member_roles
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.member_roles FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.member_roles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.member_roles TO service_role;
GRANT ALL ON TABLE public.member_roles TO CURRENT_ROLE;

CREATE POLICY "Requires permission `select-member` to view members role"
    ON public.member_roles 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (
        public.has_permission_in_organization(
        (SELECT organization_id FROM public.members WHERE id = member_roles.member_id),
        'select-member'
    )
);

CREATE POLICY "Require `edit-member` in org"
    ON public.member_roles 
    AS RESTRICTIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.members WHERE id = member_roles.member_id),
            'edit-member'
        ) AND public.role_available_in_organization(
            member_roles.role_id,
            (SELECT organization_id FROM public.members WHERE id = member_roles.member_id)
        )
    );

CREATE POLICY "Requires permission `edit-member` to remove member's role"
    ON public.member_roles
    AS RESTRICTIVE
    FOR DELETE
    TO authenticated
    USING (
        public.has_permission_in_organization(
        (SELECT organization_id FROM public.members WHERE id = member_roles.member_id),
        'edit-member'
    )
);

CREATE POLICY "Requires permission `edit-member` to update a member's role"
    ON public.member_roles 
    AS RESTRICTIVE
    FOR UPDATE
    TO authenticated
    USING (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.members WHERE id = member_roles.member_id),
            'edit-member'
        ) AND (
            public.role_available_in_organization(
                member_roles.role_id,
                (SELECT organization_id FROM public.members WHERE id = member_roles.member_id)
            )
        )
    )
    WITH CHECK (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.members WHERE id = member_roles.member_id),
            'edit-member'
        ) AND (
            public.role_available_in_organization(
                member_roles.role_id,
                (SELECT organization_id FROM public.members WHERE id = member_roles.member_id)
            )
        )
    )
;

-- Roles
ALTER TABLE IF EXISTS public.roles
    OWNER to postgres;

ALTER TABLE IF EXISTS public.roles
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.roles FROM PUBLIC;
GRANT SELECT ON TABLE public.roles TO authenticated;
GRANT SELECT ON TABLE public.roles TO service_role;
GRANT ALL ON TABLE public.roles TO CURRENT_ROLE;

CREATE POLICY "Authenticated and service roles can select roles"
    ON public.roles 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated, service_role
    USING ( roles.organization_id IS NULL );

CREATE POLICY "Require `select-role` in org"
    ON public.roles 
    AS RESTRICTIVE
    FOR SELECT
    TO authenticated
    USING ( 
        public.has_permission_in_organization(
            roles.organization_id,
            'select-role'
        )
    );

CREATE POLICY "Only `CURRENT_ROLE` can insert system roles"
    ON public.roles 
    AS RESTRICTIVE
    FOR INSERT
    TO CURRENT_ROLE
    WITH CHECK ( roles.organization_id IS NULL );

CREATE POLICY "Require `insert-role` in org"
    ON public.roles 
    AS RESTRICTIVE
    FOR INSERT
    TO authenticated
    WITH CHECK ( 
        public.has_permission_in_organization(
            roles.organization_id,
            'insert-role'
        )
    );

CREATE POLICY "Only `CURRENT_ROLE` can updat system roles"
    ON public.roles 
    AS RESTRICTIVE
    FOR UPDATE
    TO CURRENT_ROLE
    USING ( roles.organization_id IS NULL )
    WITH CHECK ( roles.organization_id IS NULL );

CREATE POLICY "Require `update-role` in org"
    ON public.roles 
    AS RESTRICTIVE
    FOR UPDATE
    TO CURRENT_ROLE
    USING ( 
        public.has_permission_in_organization(
            roles.organization_id,
            'edit-role'
        )
     )
    WITH CHECK ( 
        public.has_permission_in_organization(
            roles.organization_id,
            'edit-role'
        )
     );

CREATE POLICY "Only `CURRENT_ROLE` can delete system roles"
    ON public.roles 
    AS RESTRICTIVE
    FOR DELETE
    TO CURRENT_ROLE
    USING ( roles.organization_id IS NULL );

CREATE POLICY "Require `delete-role` in org"
    ON public.roles 
    AS RESTRICTIVE
    FOR DELETE
    TO authenticated
    USING ( 
        public.has_permission_in_organization(
            roles.organization_id,
            'delete-role'
        )
     );

-- Permissions
ALTER TABLE IF EXISTS public.permissions
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS public.permissions
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.permissions FROM PUBLIC;
GRANT SELECT ON TABLE public.permissions TO authenticated;
GRANT SELECT ON TABLE public.permissions TO service_role;
GRANT ALL ON TABLE public.permissions TO CURRENT_ROLE;

CREATE POLICY "Permission select permissions"
    ON public.permissions 
    AS PERMISSIVE
    FOR SELECT
    TO CURRENT_ROLE, authenticated, service_role
    USING ( true );

CREATE POLICY "Only `CURRENT_ROLE` can insert permissions"
    ON public.permissions 
    AS RESTRICTIVE
    FOR INSERT
    TO CURRENT_ROLE
    WITH CHECK ( true );

CREATE POLICY "Only `CURRENT_ROLE` can update permissions"
    ON public.permissions 
    AS RESTRICTIVE
    FOR UPDATE
    TO CURRENT_ROLE
    USING ( true )
    WITH CHECK ( true );

CREATE POLICY "Only `CURRENT_ROLE` can delete permissions"
    ON public.permissions 
    AS RESTRICTIVE
    FOR DELETE
    TO CURRENT_ROLE
    USING ( true );

-- Role Permissions (join)
ALTER TABLE IF EXISTS public.role_permissions
    OWNER to postgres;

ALTER TABLE IF EXISTS public.role_permissions
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.role_permissions FROM PUBLIC;
GRANT SELECT ON TABLE public.role_permissions TO authenticated;
GRANT SELECT ON TABLE public.role_permissions TO service_role;
GRANT ALL ON TABLE public.role_permissions TO CURRENT_ROLE;

CREATE POLICY "Permissive select for system role_permissions"
    ON public.role_permissions 
    AS PERMISSIVE
    FOR SELECT
    TO CURRENT_ROLE, authenticated, service_role
    USING ( 
        (SELECT organization_id FROM public.roles WHERE id = role_permissions.role_id) IS NULL
     );

CREATE POLICY "Select requires `select-role` in org"
    ON public.role_permissions 
    AS RESTRICTIVE
    FOR SELECT
    TO authenticated
    USING ( 
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.roles WHERE id = role_permissions.role_id),
            'select-role'
        )
     );

CREATE POLICY "Only `CURRENT_ROLE` can insert system role_permissions"
    ON public.role_permissions 
    AS RESTRICTIVE
    FOR INSERT
    TO CURRENT_ROLE
    WITH CHECK ( 
        (SELECT organization_id FROM public.roles WHERE id = role_permissions.role_id) IS NULL
     );

CREATE POLICY "Insert requires `edit-role` in org"
    ON public.role_permissions 
    AS RESTRICTIVE
    FOR INSERT
    TO authenticated
    WITH CHECK ( 
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.roles WHERE id = role_permissions.role_id),
            'edit-role'
        )
     );

CREATE POLICY "Only `CURRENT_ROLE` can update system role_permissions"
    ON public.role_permissions 
    AS RESTRICTIVE
    FOR UPDATE
    TO CURRENT_ROLE
    USING ( 
        (SELECT organization_id FROM public.roles WHERE id = role_permissions.role_id) IS NULL
     )
    WITH CHECK ( 
        (SELECT organization_id FROM public.roles WHERE id = role_permissions.role_id) IS NULL
     );

CREATE POLICY "Update requires `edit-role` in org"
    ON public.role_permissions 
    AS RESTRICTIVE
    FOR UPDATE
    TO authenticated
    USING (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.roles WHERE id = role_permissions.role_id),
            'edit-role'
        )
    )
    WITH CHECK ( 
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.roles WHERE id = role_permissions.role_id),
            'edit-role'
        )
     );

CREATE POLICY "Only `CURRENT_ROLE` can delete system role_permissions"
    ON public.role_permissions 
    AS RESTRICTIVE
    FOR DELETE
    TO CURRENT_ROLE
    USING ( 
        (SELECT organization_id FROM public.roles WHERE id = role_permissions.role_id) IS NULL
     );

CREATE POLICY "Delete require `edit-role` in org"
    ON public.role_permissions 
    AS RESTRICTIVE
    FOR DELETE
    TO authenticated
    USING (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.roles WHERE id = role_permissions.role_id),
            'edit-role'
        )
    );


-- Groups (join)
ALTER TABLE IF EXISTS public.groups
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS public.groups
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.groups FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.groups TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.groups TO service_role;
GRANT ALL ON TABLE public.groups TO CURRENT_ROLE;

CREATE POLICY "Require `select-group` OR membership"
    ON public.groups 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (
        public.has_group_membership(groups.id) OR
        public.has_permission_in_organization(
            groups.organization_id,
            'select-group'
        )        
);

CREATE POLICY "Require `add-group` in org"
    ON public.groups 
    AS RESTRICTIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (
        public.has_permission_in_organization(
            groups.organization_id,
            'add-group'
        )
    );

CREATE POLICY "Require `delete-group` in org"
    ON public.groups
    AS RESTRICTIVE
    FOR DELETE
    TO authenticated
    USING (
        public.has_permission_in_organization(
            groups.organization_id,
            'delete-member'
    )
);

CREATE POLICY "Require `edit-group` in org"
    ON public.groups 
    AS RESTRICTIVE
    FOR UPDATE
    TO authenticated
    USING (
        public.has_permission_in_organization(
            groups.organization_id,
            'edit-group'
        )
    )
    WITH CHECK (
        public.has_permission_in_organization(
            groups.organization_id,
            'edit-group'
        )
    )
;

-- Groups Members (join)
ALTER TABLE IF EXISTS public.group_members
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS public.group_members
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.group_members FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.group_members TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.group_members TO service_role;
GRANT ALL ON TABLE public.group_members TO CURRENT_ROLE;

CREATE POLICY "Require `select-group` OR membership"
    ON public.group_members 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (
        group_members.user_id = auth.uid() OR 
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.groups g WHERE g.id = group_members.group_id),
            'select-group'
    )
);

CREATE POLICY "Require `edit-group` to add"
    ON public.group_members 
    AS RESTRICTIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.groups g WHERE g.id = group_members.group_id),
            'edit-group'
        )
    );

CREATE POLICY "Require `edit-group` to delete"
    ON public.group_members
    AS RESTRICTIVE
    FOR DELETE
    TO authenticated
    USING (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.groups g WHERE g.id = group_members.group_id),
            'edit-group'
        )
    );

CREATE POLICY "Require `edit-group` to update"
    ON public.group_members 
    AS RESTRICTIVE
    FOR UPDATE
    TO authenticated
    USING (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.groups g WHERE g.id = group_members.group_id),
            'edit-group'
        )
    )
    WITH CHECK (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.groups g WHERE g.id = group_members.group_id),
            'edit-group'
        )
    )
;

-- Group Roles
ALTER TABLE IF EXISTS public.group_roles
    OWNER to CURRENT_ROLE;

ALTER TABLE IF EXISTS public.group_roles
    ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.group_roles FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.group_roles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.group_roles TO service_role;
GRANT ALL ON TABLE public.group_roles TO CURRENT_ROLE;

CREATE POLICY "Require `select-group` / membership"
    ON public.group_roles 
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (
        public.has_group_membership(group_roles.group_id) OR
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.groups g WHERE g.id = group_roles.group_id),
            'select-group'
    )
);

CREATE POLICY "Require `edit-group` to add"
    ON public.group_roles 
    AS RESTRICTIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.groups g WHERE g.id = group_roles.group_id),
            'edit-group'
        ) AND
        public.role_available_in_organization(
            group_roles.role_id,
            (SELECT organization_id FROM public.groups g WHERE g.id = group_roles.group_id)
        )
    );

CREATE POLICY "Require `edit-group` to delete"
    ON public.group_roles
    AS RESTRICTIVE
    FOR DELETE
    TO authenticated
    USING (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.groups g WHERE g.id = group_roles.group_id),
            'edit-group'
        ) AND
        public.role_available_in_organization(
            group_roles.role_id,
            (SELECT organization_id FROM public.groups g WHERE g.id = group_roles.group_id)
        )
    );

CREATE POLICY "Require `edit-group` to update"
    ON public.group_roles 
    AS RESTRICTIVE
    FOR UPDATE
    TO authenticated
    USING (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.groups g WHERE g.id = group_roles.group_id),
            'edit-group'
        ) AND
        public.role_available_in_organization(
            group_roles.role_id,
            (SELECT organization_id FROM public.groups g WHERE g.id = group_roles.group_id)
        )
    )
    WITH CHECK (
        public.has_permission_in_organization(
            (SELECT organization_id FROM public.groups g WHERE g.id = group_roles.group_id),
            'edit-group'
        ) AND
        public.role_available_in_organization(
            group_roles.role_id,
            (SELECT organization_id FROM public.groups g WHERE g.id = group_roles.group_id)
        )
    )
;


-- 
-- Create Default Roles 
-- 
INSERT INTO public.roles (name, slug, description) VALUES
    ('Super Admin', 'super-admin', 'Admin rights over all organizations'),
    ('Owner', 'owner', 'Full ownership rights in the organization'),
    ('Editor' , 'editor', 'Edit records in the organization'),
    ('Read-only', 'read-only', 'Read-only rights to the organization');

-- 
-- Create Default Permissions and Roles
--

-- Organizations
SELECT public.insert_role_permission(
    ARRAY['owner'],
    'Delete organization',
    'delete-organization',
    'Delete the organization'
);
SELECT public.insert_role_permission(
    ARRAY['owner'],
    'Edit organization',
    'edit-organization',
    'Edit the organization'
);
SELECT public.insert_role_permission(
    ARRAY['owner', 'editor', 'read-only'],
    'Select organization',
    'select-organization',
    'View the organization'
);

-- Members
SELECT public.insert_role_permission(
    ARRAY['owner'],
    'Remove member',
    'delete-member',
    'Remove a member from the organization'
);
SELECT public.insert_role_permission(
    ARRAY['owner'],
    'Add member',
    'add-member',
    'Add a member to the organization'
);
SELECT public.insert_role_permission(
    ARRAY['owner', 'editor', 'read-only'],
    'Edit member',
    'edit-member',
    'Update a member in the organization'
);
SELECT public.insert_role_permission(
    ARRAY['owner', 'editor', 'read-only'],
    'Select member',
    'select-member',
    'Select members in the organization'
);

-- Roles
SELECT public.insert_role_permission(
    ARRAY['owner'],
    'Remove role',
    'delete-role',
    'Remove a role'
);
SELECT public.insert_role_permission(
    ARRAY['owner'],
    'Add role',
    'add-role',
    'Add a role to the organization'
);
SELECT public.insert_role_permission(
    ARRAY['owner'],
    'Edit role',
    'edit-role',
    'Update a role in the organization'
);
SELECT public.insert_role_permission(
    ARRAY['owner', 'editor', 'read-only'],
    'Select role',
    'select-role',
    'Select roles'
);

-- Groups
SELECT public.insert_role_permission(
    ARRAY['owner'],
    'Remove group',
    'delete-group',
    'Remove a group'
);
SELECT public.insert_role_permission(
    ARRAY['owner'],
    'Add group',
    'add-group',
    'Add a group to the organization'
);
SELECT public.insert_role_permission(
    ARRAY['owner'],
    'Edit group',
    'edit-group',
    'Update a group in the organization'
);
SELECT public.insert_role_permission(
    ARRAY['owner', 'editor', 'read-only'],
    'Select group',
    'select-group',
    'Select group'
);