export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.4"
  }
  public: {
    Tables: {
      condom_requests: {
        Row: {
          cancel_reason: string | null
          completed_at: string | null
          condom_quantities: Json
          created_at: string
          handled_by: string | null
          id: string
          is_delay: boolean
          lubricant_quantity: number
          message: string | null
          reference_number: string
          request_status: Database["public"]["Enums"]["request_status"]
          selected_date: string | null
          selected_service_center: Database["public"]["Enums"]["service_center"]
          selected_time: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          cancel_reason?: string | null
          completed_at?: string | null
          condom_quantities?: Json
          created_at?: string
          handled_by?: string | null
          id?: string
          is_delay?: boolean
          lubricant_quantity?: number
          message?: string | null
          reference_number: string
          request_status?: Database["public"]["Enums"]["request_status"]
          selected_date?: string | null
          selected_service_center?: Database["public"]["Enums"]["service_center"]
          selected_time?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          cancel_reason?: string | null
          completed_at?: string | null
          condom_quantities?: Json
          created_at?: string
          handled_by?: string | null
          id?: string
          is_delay?: boolean
          lubricant_quantity?: number
          message?: string | null
          reference_number?: string
          request_status?: Database["public"]["Enums"]["request_status"]
          selected_date?: string | null
          selected_service_center?: Database["public"]["Enums"]["service_center"]
          selected_time?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      doctor_appointments: {
        Row: {
          appointment_status: Database["public"]["Enums"]["appointment_status"]
          cancel_reason: string | null
          created_at: string
          handled_by: string | null
          id: string
          note: string | null
          reason: string
          reference_number: string
          selected_date: string
          selected_service_center: Database["public"]["Enums"]["service_center"]
          selected_time: string
          updated_at: string
          user_id: string
        }
        Insert: {
          appointment_status?: Database["public"]["Enums"]["appointment_status"]
          cancel_reason?: string | null
          created_at?: string
          handled_by?: string | null
          id?: string
          note?: string | null
          reason: string
          reference_number: string
          selected_date: string
          selected_service_center: Database["public"]["Enums"]["service_center"]
          selected_time: string
          updated_at?: string
          user_id: string
        }
        Update: {
          appointment_status?: Database["public"]["Enums"]["appointment_status"]
          cancel_reason?: string | null
          created_at?: string
          handled_by?: string | null
          id?: string
          note?: string | null
          reason?: string
          reference_number?: string
          selected_date?: string
          selected_service_center?: Database["public"]["Enums"]["service_center"]
          selected_time?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      inventory_logs: {
        Row: {
          action: Database["public"]["Enums"]["audit_action"]
          condom_delta: number
          created_at: string
          id: string
          lubricant_delta: number
          note: string | null
          performed_by: string | null
          reason: string | null
          reference_request_id: string | null
          service_center: Database["public"]["Enums"]["service_center"]
        }
        Insert: {
          action: Database["public"]["Enums"]["audit_action"]
          condom_delta?: number
          created_at?: string
          id?: string
          lubricant_delta?: number
          note?: string | null
          performed_by?: string | null
          reason?: string | null
          reference_request_id?: string | null
          service_center: Database["public"]["Enums"]["service_center"]
        }
        Update: {
          action?: Database["public"]["Enums"]["audit_action"]
          condom_delta?: number
          created_at?: string
          id?: string
          lubricant_delta?: number
          note?: string | null
          performed_by?: string | null
          reason?: string | null
          reference_request_id?: string | null
          service_center?: Database["public"]["Enums"]["service_center"]
        }
        Relationships: [
          {
            foreignKeyName: "inventory_logs_reference_request_id_fkey"
            columns: ["reference_request_id"]
            isOneToOne: false
            referencedRelation: "condom_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      recovery_attempts: {
        Row: {
          attempted_at: string | null
          id: string
          success: boolean | null
          user_id: string
        }
        Insert: {
          attempted_at?: string | null
          id?: string
          success?: boolean | null
          user_id: string
        }
        Update: {
          attempted_at?: string | null
          id?: string
          success?: boolean | null
          user_id?: string
        }
        Relationships: []
      }
      request_status_logs: {
        Row: {
          changed_at: string
          changed_by: string | null
          from_status: Database["public"]["Enums"]["request_status"] | null
          id: string
          request_id: string
          to_status: Database["public"]["Enums"]["request_status"]
        }
        Insert: {
          changed_at?: string
          changed_by?: string | null
          from_status?: Database["public"]["Enums"]["request_status"] | null
          id?: string
          request_id: string
          to_status: Database["public"]["Enums"]["request_status"]
        }
        Update: {
          changed_at?: string
          changed_by?: string | null
          from_status?: Database["public"]["Enums"]["request_status"] | null
          id?: string
          request_id?: string
          to_status?: Database["public"]["Enums"]["request_status"]
        }
        Relationships: [
          {
            foreignKeyName: "request_status_logs_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "condom_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      service_center_inventory: {
        Row: {
          condom_qty: number
          id: string
          last_restocked_at: string | null
          lubricant_qty: number
          service_center: Database["public"]["Enums"]["service_center"]
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          condom_qty?: number
          id?: string
          last_restocked_at?: string | null
          lubricant_qty?: number
          service_center: Database["public"]["Enums"]["service_center"]
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          condom_qty?: number
          id?: string
          last_restocked_at?: string | null
          lubricant_qty?: number
          service_center?: Database["public"]["Enums"]["service_center"]
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      staff_audit_logs: {
        Row: {
          action: Database["public"]["Enums"]["audit_action"]
          created_at: string
          id: string
          new_value: Json | null
          old_value: Json | null
          performed_by: string | null
          target_id: string
          target_table: string
        }
        Insert: {
          action: Database["public"]["Enums"]["audit_action"]
          created_at?: string
          id?: string
          new_value?: Json | null
          old_value?: Json | null
          performed_by?: string | null
          target_id: string
          target_table: string
        }
        Update: {
          action?: Database["public"]["Enums"]["audit_action"]
          created_at?: string
          id?: string
          new_value?: Json | null
          old_value?: Json | null
          performed_by?: string | null
          target_id?: string
          target_table?: string
        }
        Relationships: []
      }
      staff_notification_reads: {
        Row: {
          notification_id: string
          read_at: string
          staff_user_id: string
        }
        Insert: {
          notification_id: string
          read_at?: string
          staff_user_id: string
        }
        Update: {
          notification_id?: string
          read_at?: string
          staff_user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_reads_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "staff_notifications"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_notifications: {
        Row: {
          created_at: string
          event_type: string
          id: string
          metadata: Json
          reference_number: string
          source_id: string
          source_type: string
        }
        Insert: {
          created_at?: string
          event_type: string
          id?: string
          metadata?: Json
          reference_number?: string
          source_id: string
          source_type: string
        }
        Update: {
          created_at?: string
          event_type?: string
          id?: string
          metadata?: Json
          reference_number?: string
          source_id?: string
          source_type?: string
        }
        Relationships: []
      }
      staff_profiles: {
        Row: {
          created_at: string | null
          first_name: string | null
          id: string
          last_name: string | null
          role: Database["public"]["Enums"]["role"]
          service_center: Database["public"]["Enums"]["service_center"] | null
          staff_user_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          first_name?: string | null
          id?: string
          last_name?: string | null
          role?: Database["public"]["Enums"]["role"]
          service_center?: Database["public"]["Enums"]["service_center"] | null
          staff_user_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          first_name?: string | null
          id?: string
          last_name?: string | null
          role?: Database["public"]["Enums"]["role"]
          service_center?: Database["public"]["Enums"]["service_center"] | null
          staff_user_id?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      user_monthly_quotas: {
        Row: {
          id: string
          month: string
          updated_at: string | null
          used_condoms: number | null
          used_lubricants: number | null
          user_id: string
        }
        Insert: {
          id?: string
          month: string
          updated_at?: string | null
          used_condoms?: number | null
          used_lubricants?: number | null
          user_id: string
        }
        Update: {
          id?: string
          month?: string
          updated_at?: string | null
          used_condoms?: number | null
          used_lubricants?: number | null
          user_id?: string
        }
        Relationships: []
      }
      user_notification_reads: {
        Row: {
          notification_id: string
          read_at: string
          user_id: string
        }
        Insert: {
          notification_id: string
          read_at?: string
          user_id: string
        }
        Update: {
          notification_id?: string
          read_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_notification_reads_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "user_notifications"
            referencedColumns: ["id"]
          },
        ]
      }
      user_notifications: {
        Row: {
          created_at: string
          event_type: string
          id: string
          metadata: Json
          reference_number: string
          source_id: string
          source_type: string
          user_id: string
        }
        Insert: {
          created_at?: string
          event_type: string
          id?: string
          metadata?: Json
          reference_number?: string
          source_id: string
          source_type: string
          user_id: string
        }
        Update: {
          created_at?: string
          event_type?: string
          id?: string
          metadata?: Json
          reference_number?: string
          source_id?: string
          source_type?: string
          user_id?: string
        }
        Relationships: []
      }
      user_profiles: {
        Row: {
          created_at: string | null
          date_of_birth: string | null
          gender: string | null
          id: string
          nationality: string | null
          user_id: string
          username: string
        }
        Insert: {
          created_at?: string | null
          date_of_birth?: string | null
          gender?: string | null
          id?: string
          nationality?: string | null
          user_id: string
          username?: string
        }
        Update: {
          created_at?: string | null
          date_of_birth?: string | null
          gender?: string | null
          id?: string
          nationality?: string | null
          user_id?: string
          username?: string
        }
        Relationships: []
      }
      user_recovery_codes: {
        Row: {
          code_hash: string
          created_at: string | null
          id: string
          used: boolean | null
          used_at: string | null
          user_id: string
        }
        Insert: {
          code_hash: string
          created_at?: string | null
          id?: string
          used?: boolean | null
          used_at?: string | null
          user_id: string
        }
        Update: {
          code_hash?: string
          created_at?: string | null
          id?: string
          used?: boolean | null
          used_at?: string | null
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      create_condom_request: {
        Args: {
          p_condom_quantities: Json
          p_lubricant_quantity: number
          p_message?: string
          p_selected_date: string
          p_selected_service_center: Database["public"]["Enums"]["service_center"]
          p_selected_time?: string
          p_user_id: string
        }
        Returns: string
      }
      create_doctor_appointment: {
        Args: {
          p_date: string
          p_note?: string
          p_reason: string
          p_service_center: Database["public"]["Enums"]["service_center"]
          p_time: string
          p_user_id: string
        }
        Returns: string
      }
      dearmor: { Args: { "": string }; Returns: string }
      gen_random_uuid: { Args: never; Returns: string }
      gen_salt: { Args: { "": string }; Returns: string }
      get_audit_log:
        | {
            Args: {
              p_action?: Database["public"]["Enums"]["audit_action"]
              p_date_from?: string
              p_date_to?: string
              p_limit?: number
              p_offset?: number
              p_performed_by?: string
              p_target_table?: string
            }
            Returns: {
              action: Database["public"]["Enums"]["audit_action"]
              created_at: string
              full_name: string
              id: string
              new_value: Json
              old_value: Json
              performed_by: string
              target_full_name: string
              target_id: string
              target_table: string
            }[]
          }
        | {
            Args: {
              p_action?: Database["public"]["Enums"]["audit_action"]
              p_date_from?: string
              p_date_to?: string
              p_limit?: number
              p_offset?: number
              p_performed_by?: string
              p_target_id?: string
              p_target_table?: string
            }
            Returns: {
              action: Database["public"]["Enums"]["audit_action"]
              created_at: string
              full_name: string
              id: string
              new_value: Json
              old_value: Json
              performed_by: string
              target_full_name: string
              target_id: string
              target_table: string
            }[]
          }
        | {
            Args: {
              p_action?: string
              p_date_from?: string
              p_date_to?: string
              p_limit?: number
              p_offset?: number
              p_performed_by?: string
              p_target_id?: string
              p_target_table?: string
            }
            Returns: {
              action: Database["public"]["Enums"]["audit_action"]
              created_at: string
              full_name: string
              id: string
              new_value: Json
              old_value: Json
              performed_by: string
              target_full_name: string
              target_id: string
              target_table: string
            }[]
          }
      get_average_lead_time: {
        Args: {
          p_date_from: string
          p_date_to: string
          p_service_center?: Database["public"]["Enums"]["service_center"]
        }
        Returns: {
          overall_avg_minutes: number
          pending_to_preparing: number
          preparing_to_ready: number
          ready_to_completed: number
        }[]
      }
      get_consumption_trend: {
        Args: never
        Returns: {
          condom_used: number
          day: string
          lubricant_used: number
          service_center: Database["public"]["Enums"]["service_center"]
        }[]
      }
      get_days_until_reset: { Args: never; Returns: number }
      get_inventory_forecast: {
        Args: never
        Returns: {
          condom_daily_burn: number
          condom_days_left: number
          condom_qty: number
          lubricant_daily_burn: number
          lubricant_days_left: number
          lubricant_qty: number
          service_center: Database["public"]["Enums"]["service_center"]
        }[]
      }
      get_inventory_log: {
        Args: {
          p_action?: string
          p_date_from?: string
          p_date_to?: string
          p_limit?: number
          p_offset?: number
          p_service_center?: string
        }
        Returns: {
          action: Database["public"]["Enums"]["transaction_type"]
          condom_delta: number
          created_at: string
          full_name: string
          id: string
          lubricant_delta: number
          note: string
          performed_by: string
          reason: string
          service_center: Database["public"]["Enums"]["service_center"]
        }[]
      }
      get_peak_time_stats: {
        Args: {
          p_date_from: string
          p_date_to: string
          p_period: string
          p_service_center?: string
        }
        Returns: {
          bucket: string
          count: number
        }[]
      }
      get_request_status_log: {
        Args: {
          p_date_from?: string
          p_date_to?: string
          p_from_status?: string
          p_limit?: number
          p_offset?: number
          p_performed_by?: string
          p_reference_number?: string
          p_to_status?: string
        }
        Returns: {
          changed_at: string
          from_status: string
          full_name: string
          id: string
          performed_by: string
          reference_number: string
          request_id: string
          to_status: string
        }[]
      }
      get_service_center_demand: {
        Args: { p_date_from: string; p_date_to: string }
        Returns: {
          service_center: Database["public"]["Enums"]["service_center"]
          total_condoms: number
          total_lubricants: number
          total_requests: number
        }[]
      }
      get_service_center_demand_trend: {
        Args: never
        Returns: {
          day: string
          request_count: number
          service_center: Database["public"]["Enums"]["service_center"]
        }[]
      }
      get_staff_audit_log: {
        Args: {
          p_action?: string
          p_date_from?: string
          p_date_to?: string
          p_limit?: number
          p_offset?: number
          p_performed_by?: string
          p_target_id?: string
        }
        Returns: {
          action: Database["public"]["Enums"]["audit_action"]
          created_at: string
          full_name: string
          id: string
          new_value: Json
          old_value: Json
          performed_by: string
          target_full_name: string
          target_id: string
        }[]
      }
      get_staff_workload:
        | {
            Args: { p_date_from: string; p_date_to: string }
            Returns: {
              avg_lead_time_minutes: number
              cancelled_count: number
              completed_count: number
              full_name: string
              service_center: Database["public"]["Enums"]["service_center"]
              staff_user_id: string
            }[]
          }
        | {
            Args: {
              p_date_from: string
              p_date_to: string
              p_service_center?: string
            }
            Returns: {
              avg_lead_time_minutes: number
              cancelled_count: number
              completed_count: number
              first_name: string
              last_name: string
              overdue_count: number
              service_center: Database["public"]["Enums"]["service_center"]
              staff_user_id: string
            }[]
          }
      get_staff_workload_trend:
        | {
            Args: {
              p_date_from: string
              p_date_to: string
              p_service_center?: string
              p_staff_user_id?: string
            }
            Returns: {
              cancelled_count: number
              completed_count: number
              first_name: string
              last_name: string
              staff_user_id: string
              week_start: string
            }[]
          }
        | {
            Args: {
              p_date_from?: string
              p_date_to?: string
              p_service_center?: string
              p_staff_user_id?: string
            }
            Returns: {
              cancelled_count: number
              completed_count: number
              first_name: string
              last_name: string
              staff_user_id: string
              week_start: string
            }[]
          }
      is_admin: { Args: never; Returns: boolean }
      is_staff: { Args: never; Returns: boolean }
      is_superadmin: { Args: never; Returns: boolean }
      log_audit_event: {
        Args: {
          p_action: string
          p_new_value?: Json
          p_old_value?: Json
          p_performed_by: string
          p_target_id: string
          p_target_table: string
        }
        Returns: undefined
      }
      pgp_armor_headers: {
        Args: { "": string }
        Returns: Record<string, unknown>[]
      }
      save_recovery_codes: {
        Args: { secret_codes: string[] }
        Returns: undefined
      }
      verify_recovery_code: {
        Args: { p_recovery_code: string; p_username: string }
        Returns: Json
      }
      verify_recovery_code_and_reset_password: {
        Args: {
          p_new_password: string
          p_recovery_code: string
          p_username: string
        }
        Returns: Json
      }
      write_audit_log: {
        Args: {
          p_action: Database["public"]["Enums"]["audit_action"]
          p_new_value?: Json
          p_old_value?: Json
          p_performed_by?: string
          p_target_id: string
          p_target_table: string
        }
        Returns: undefined
      }
    }
    Enums: {
      appointment_status:
        | "pending"
        | "confirmed"
        | "cancelled_by_user"
        | "cancelled_by_staff"
        | "completed"
      audit_action:
        | "role_updated"
        | "staff_profile_updated"
        | "restock"
        | "fulfillment"
        | "adjustment"
        | "staff_created"
        | "staff_deleted"
        | "email_updated"
      request_status:
        | "pending"
        | "preparing"
        | "ready"
        | "completed"
        | "cancelled_by_user"
        | "cancelled_by_staff"
      role: "staff" | "admin" | "superadmin"
      service_center:
        | "รพ.โพนพิสัย"
        | "รพ.สต.วัดหลวง"
        | "อบต.วัดหลวง"
        | "สสจ.หนองคาย"
      transaction_type: "restock" | "fulfillment" | "adjustment"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      appointment_status: [
        "pending",
        "confirmed",
        "cancelled_by_user",
        "cancelled_by_staff",
        "completed",
      ],
      audit_action: [
        "role_updated",
        "staff_profile_updated",
        "restock",
        "fulfillment",
        "adjustment",
        "staff_created",
        "staff_deleted",
        "email_updated",
      ],
      request_status: [
        "pending",
        "preparing",
        "ready",
        "completed",
        "cancelled_by_user",
        "cancelled_by_staff",
      ],
      role: ["staff", "admin", "superadmin"],
      service_center: [
        "รพ.โพนพิสัย",
        "รพ.สต.วัดหลวง",
        "อบต.วัดหลวง",
        "สสจ.หนองคาย",
      ],
      transaction_type: ["restock", "fulfillment", "adjustment"],
    },
  },
} as const
