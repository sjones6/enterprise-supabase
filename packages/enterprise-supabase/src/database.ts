export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: {
      group_members: {
        Row: {
          created_at: string | null;
          group_id: string;
          id: string;
          member_id: string;
          updated_at: string | null;
        };
        Insert: {
          created_at?: string | null;
          group_id: string;
          id?: string;
          member_id: string;
          updated_at?: string | null;
        };
        Update: {
          created_at?: string | null;
          group_id?: string;
          id?: string;
          member_id?: string;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "group_members_group_id_fkey";
            columns: ["group_id"];
            referencedRelation: "groups";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "group_members_member_id_fkey";
            columns: ["member_id"];
            referencedRelation: "members";
            referencedColumns: ["id"];
          }
        ];
      };
      group_roles: {
        Row: {
          created_at: string | null;
          group_id: string;
          id: string;
          role_id: string;
          updated_at: string | null;
        };
        Insert: {
          created_at?: string | null;
          group_id: string;
          id?: string;
          role_id: string;
          updated_at?: string | null;
        };
        Update: {
          created_at?: string | null;
          group_id?: string;
          id?: string;
          role_id?: string;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "group_roles_group_id_fkey";
            columns: ["group_id"];
            referencedRelation: "groups";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "group_roles_role_id_fkey";
            columns: ["role_id"];
            referencedRelation: "roles";
            referencedColumns: ["id"];
          }
        ];
      };
      groups: {
        Row: {
          created_at: string | null;
          description: string;
          id: string;
          name: string;
          organization_id: string;
          updated_at: string | null;
        };
        Insert: {
          created_at?: string | null;
          description?: string;
          id?: string;
          name: string;
          organization_id: string;
          updated_at?: string | null;
        };
        Update: {
          created_at?: string | null;
          description?: string;
          id?: string;
          name?: string;
          organization_id?: string;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "groups_organization_id_fkey";
            columns: ["organization_id"];
            referencedRelation: "organizations";
            referencedColumns: ["id"];
          }
        ];
      };
      member_roles: {
        Row: {
          created_at: string | null;
          id: string;
          member_id: string;
          role_id: string;
          updated_at: string | null;
        };
        Insert: {
          created_at?: string | null;
          id?: string;
          member_id: string;
          role_id: string;
          updated_at?: string | null;
        };
        Update: {
          created_at?: string | null;
          id?: string;
          member_id?: string;
          role_id?: string;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "member_roles_member_id_fkey";
            columns: ["member_id"];
            referencedRelation: "members";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "member_roles_role_id_fkey";
            columns: ["role_id"];
            referencedRelation: "roles";
            referencedColumns: ["id"];
          }
        ];
      };
      members: {
        Row: {
          created_at: string | null;
          id: string;
          organization_id: string;
          updated_at: string | null;
          user_id: string;
        };
        Insert: {
          created_at?: string | null;
          id?: string;
          organization_id: string;
          updated_at?: string | null;
          user_id: string;
        };
        Update: {
          created_at?: string | null;
          id?: string;
          organization_id?: string;
          updated_at?: string | null;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "members_organization_id_fkey";
            columns: ["organization_id"];
            referencedRelation: "organizations";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "members_user_id_fkey";
            columns: ["user_id"];
            referencedRelation: "users";
            referencedColumns: ["id"];
          }
        ];
      };
      organizations: {
        Row: {
          created_at: string | null;
          id: string;
          name: string;
          updated_at: string | null;
        };
        Insert: {
          created_at?: string | null;
          id?: string;
          name: string;
          updated_at?: string | null;
        };
        Update: {
          created_at?: string | null;
          id?: string;
          name?: string;
          updated_at?: string | null;
        };
        Relationships: [];
      };
      permissions: {
        Row: {
          created_at: string | null;
          description: string;
          id: string;
          name: string;
          slug: string;
          updated_at: string | null;
        };
        Insert: {
          created_at?: string | null;
          description?: string;
          id?: string;
          name: string;
          slug: string;
          updated_at?: string | null;
        };
        Update: {
          created_at?: string | null;
          description?: string;
          id?: string;
          name?: string;
          slug?: string;
          updated_at?: string | null;
        };
        Relationships: [];
      };
      role_permissions: {
        Row: {
          created_at: string | null;
          id: string;
          permission_id: string;
          role_id: string;
          updated_at: string | null;
        };
        Insert: {
          created_at?: string | null;
          id?: string;
          permission_id: string;
          role_id: string;
          updated_at?: string | null;
        };
        Update: {
          created_at?: string | null;
          id?: string;
          permission_id?: string;
          role_id?: string;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "role_permissions_permission_id_fkey";
            columns: ["permission_id"];
            referencedRelation: "permissions";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "role_permissions_role_id_fkey";
            columns: ["role_id"];
            referencedRelation: "roles";
            referencedColumns: ["id"];
          }
        ];
      };
      roles: {
        Row: {
          created_at: string | null;
          description: string | null;
          id: string;
          name: string;
          organization_id: string | null;
          slug: string;
          updated_at: string | null;
        };
        Insert: {
          created_at?: string | null;
          description?: string | null;
          id?: string;
          name: string;
          organization_id?: string | null;
          slug: string;
          updated_at?: string | null;
        };
        Update: {
          created_at?: string | null;
          description?: string | null;
          id?: string;
          name?: string;
          organization_id?: string | null;
          slug?: string;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "roles_organization_id_fkey";
            columns: ["organization_id"];
            referencedRelation: "organizations";
            referencedColumns: ["id"];
          }
        ];
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      create_organization: {
        Args: {
          name: string;
        };
        Returns: {
          created_at: string | null;
          id: string;
          name: string;
          updated_at: string | null;
        };
      };
      get_permissions_in_organization: {
        Args: {
          organization_id: string;
        };
        Returns: string[];
      };
      has_all_permissions_in_organization: {
        Args: {
          organization_id: string;
          permission: string[];
        };
        Returns: boolean;
      };
      has_any_permission_in_organization: {
        Args: {
          organization_id: string;
          permission: string[];
        };
        Returns: boolean;
      };
      has_group_membership: {
        Args: {
          group_id: string;
        };
        Returns: boolean;
      };
      has_permission_in_organization: {
        Args: {
          organization_id: string;
          permission: string;
        };
        Returns: boolean;
      };
      insert_role_permission: {
        Args: {
          role_slugs: string[];
          name: string;
          permission_slug: string;
          description: string;
        };
        Returns: undefined;
      };
      role_available_in_organization: {
        Args: {
          role_id: string;
          organization_id: string;
        };
        Returns: boolean;
      };
    };
    Enums: {
      [_ in never]: never;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
}
