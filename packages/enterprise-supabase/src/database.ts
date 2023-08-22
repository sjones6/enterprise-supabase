export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  authz: {
    Tables: {
      group_members: {
        Row: {
          created_at: string | null
          group_id: string
          organization_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          group_id: string
          organization_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          group_id?: string
          organization_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "group_members_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_members_organization_id_group_id_fkey"
            columns: ["organization_id", "group_id"]
            referencedRelation: "groups"
            referencedColumns: ["organization_id", "id"]
          },
          {
            foreignKeyName: "group_members_organization_id_user_id_fkey"
            columns: ["organization_id", "user_id"]
            referencedRelation: "members"
            referencedColumns: ["organization_id", "user_id"]
          },
          {
            foreignKeyName: "group_members_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      group_roles: {
        Row: {
          created_at: string | null
          group_id: string
          organization_id: string
          role_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          group_id: string
          organization_id: string
          role_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          group_id?: string
          organization_id?: string
          role_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "group_roles_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_roles_organization_id_group_id_fkey"
            columns: ["organization_id", "group_id"]
            referencedRelation: "groups"
            referencedColumns: ["organization_id", "id"]
          },
          {
            foreignKeyName: "group_roles_role_id_fkey"
            columns: ["role_id"]
            referencedRelation: "roles"
            referencedColumns: ["id"]
          }
        ]
      }
      groups: {
        Row: {
          created_at: string | null
          description: string
          id: string
          name: string
          organization_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string
          id?: string
          name: string
          organization_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string
          id?: string
          name?: string
          organization_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "groups_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          }
        ]
      }
      member_invitation_groups: {
        Row: {
          created_at: string | null
          email: string
          group_id: string
          organization_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          email: string
          group_id: string
          organization_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          email?: string
          group_id?: string
          organization_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "member_invitation_groups_organization_id_email_fkey"
            columns: ["organization_id", "email"]
            referencedRelation: "member_invitations"
            referencedColumns: ["organization_id", "email"]
          },
          {
            foreignKeyName: "member_invitation_groups_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "member_invitation_groups_organization_id_group_id_fkey"
            columns: ["organization_id", "group_id"]
            referencedRelation: "groups"
            referencedColumns: ["organization_id", "id"]
          }
        ]
      }
      member_invitation_roles: {
        Row: {
          created_at: string | null
          email: string
          organization_id: string
          role_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          email: string
          organization_id: string
          role_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          email?: string
          organization_id?: string
          role_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "member_invitation_roles_organization_id_email_fkey"
            columns: ["organization_id", "email"]
            referencedRelation: "member_invitations"
            referencedColumns: ["organization_id", "email"]
          },
          {
            foreignKeyName: "member_invitation_roles_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "member_invitation_roles_role_id_fkey"
            columns: ["role_id"]
            referencedRelation: "roles"
            referencedColumns: ["id"]
          }
        ]
      }
      member_invitations: {
        Row: {
          created_at: string | null
          email: string
          expires_at: string | null
          organization_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          email: string
          expires_at?: string | null
          organization_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          email?: string
          expires_at?: string | null
          organization_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "member_invitations_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          }
        ]
      }
      member_roles: {
        Row: {
          created_at: string | null
          organization_id: string
          role_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          organization_id: string
          role_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          organization_id?: string
          role_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "member_roles_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "member_roles_organization_id_user_id_fkey"
            columns: ["organization_id", "user_id"]
            referencedRelation: "members"
            referencedColumns: ["organization_id", "user_id"]
          },
          {
            foreignKeyName: "member_roles_role_id_fkey"
            columns: ["role_id"]
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "member_roles_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      members: {
        Row: {
          created_at: string | null
          organization_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          organization_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          organization_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "members_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "members_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      organizations: {
        Row: {
          created_at: string | null
          id: string
          name: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          name: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          name?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      permissions: {
        Row: {
          created_at: string | null
          description: string
          id: string
          name: string
          slug: Database["authz"]["Enums"]["permission"]
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string
          id?: string
          name: string
          slug: Database["authz"]["Enums"]["permission"]
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string
          id?: string
          name?: string
          slug?: Database["authz"]["Enums"]["permission"]
          updated_at?: string | null
        }
        Relationships: []
      }
      role_permissions: {
        Row: {
          created_at: string | null
          id: string
          permission_id: string
          role_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          permission_id: string
          role_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          permission_id?: string
          role_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "role_permissions_permission_id_fkey"
            columns: ["permission_id"]
            referencedRelation: "permissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "role_permissions_role_id_fkey"
            columns: ["role_id"]
            referencedRelation: "roles"
            referencedColumns: ["id"]
          }
        ]
      }
      roles: {
        Row: {
          created_at: string | null
          description: string | null
          id: string
          name: string
          organization_id: string | null
          slug: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          id?: string
          name: string
          organization_id?: string | null
          slug: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          id?: string
          name?: string
          organization_id?: string | null
          slug?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "roles_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          }
        ]
      }
      user_permissions: {
        Row: {
          created_at: string | null
          organization_id: string
          permission: Database["authz"]["Enums"]["permission"]
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          organization_id: string
          permission: Database["authz"]["Enums"]["permission"]
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          organization_id?: string
          permission?: Database["authz"]["Enums"]["permission"]
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_permissions_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_permissions_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      add_member_to_group: {
        Args: {
          organization_id: string
          group_id: string
          user_id: string
        }
        Returns: {
          created_at: string | null
          group_id: string
          organization_id: string
          updated_at: string | null
          user_id: string
        }
      }
      add_member_to_organization: {
        Args: {
          organization_id: string
          user_id: string
          role_id?: string
        }
        Returns: {
          created_at: string | null
          organization_id: string
          updated_at: string | null
          user_id: string
        }
      }
      create_organization: {
        Args: {
          name: string
        }
        Returns: {
          created_at: string | null
          id: string
          name: string
          updated_at: string | null
        }
      }
      edit_group: {
        Args: {
          group_id: string
          organization_id: string
          name?: string
          description?: string
          add_members?: string[]
          remove_members?: string[]
          add_roles?: string[]
          remove_roles?: string[]
        }
        Returns: boolean
      }
      get_members_for_roles: {
        Args: {
          role_ids: string[]
        }
        Returns: {
          created_at: string | null
          organization_id: string
          updated_at: string | null
          user_id: string
        }[]
      }
      get_permission_slugs_in_organization: {
        Args: {
          organization_id: string
        }
        Returns: Database["authz"]["Enums"]["permission"][]
      }
      get_permissions_in_organization:
        | {
            Args: {
              organization_id: string
              user_id: string
            }
            Returns: Database["authz"]["CompositeTypes"]["permissions_row"][]
          }
        | {
            Args: {
              organization_id: string
            }
            Returns: Database["authz"]["CompositeTypes"]["permissions_row"][]
          }
      has_all_permissions_in_organization: {
        Args: {
          organization_id: string
          permissions: Database["authz"]["Enums"]["permission"][]
        }
        Returns: boolean
      }
      has_any_permission_in_organization: {
        Args: {
          organization_id: string
          permission: Database["authz"]["Enums"]["permission"][]
        }
        Returns: boolean
      }
      has_group_membership: {
        Args: {
          organization_id: string
          group_id: string
        }
        Returns: boolean
      }
      has_permission_in_organization: {
        Args: {
          organization_id: string
          permission: Database["authz"]["Enums"]["permission"]
        }
        Returns: boolean
      }
      insert_role_permission: {
        Args: {
          role_slugs: string[]
          name: string
          permission_slug: Database["authz"]["Enums"]["permission"]
          description: string
        }
        Returns: undefined
      }
      role_available_in_organization: {
        Args: {
          organization_id: string
          role_id: string
        }
        Returns: boolean
      }
      set_active_organization: {
        Args: {
          active_organization_id: string
        }
        Returns: string
      }
      update_users_permissions:
        | {
            Args: {
              user_id: string
              organization_id: string
            }
            Returns: undefined
          }
        | {
            Args: {
              user_id: string
            }
            Returns: undefined
          }
    }
    Enums: {
      permission:
        | "delete-organization"
        | "edit-organization"
        | "select-organization"
        | "delete-member"
        | "add-member"
        | "edit-member"
        | "select-member"
        | "delete-role"
        | "add-role"
        | "edit-role"
        | "select-role"
        | "delete-group"
        | "add-group"
        | "edit-group"
        | "select-group"
    }
    CompositeTypes: {
      permissions_row: {
        id: string
        name: string
        description: string
        slug: Database["authz"]["Enums"]["permission"]
        updated_at: string
        created_at: string
      }
    }
  }
  public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

