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
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      appointment_status_logs: {
        Row: {
          appointment_id: string
          changed_at: string
          changed_by: string | null
          from_status: Database["public"]["Enums"]["appointment_status"] | null
          id: string
          to_status: Database["public"]["Enums"]["appointment_status"]
        }
        Insert: {
          appointment_id: string
          changed_at?: string
          changed_by?: string | null
          from_status?: Database["public"]["Enums"]["appointment_status"] | null
          id?: string
          to_status: Database["public"]["Enums"]["appointment_status"]
        }
        Update: {
          appointment_id?: string
          changed_at?: string
          changed_by?: string | null
          from_status?: Database["public"]["Enums"]["appointment_status"] | null
          id?: string
          to_status?: Database["public"]["Enums"]["appointment_status"]
        }
        Relationships: [
          {
            foreignKeyName: "appointment_status_logs_appointment_id_fkey"
            columns: ["appointment_id"]
            isOneToOne: false
            referencedRelation: "doctor_appointments"
            referencedColumns: ["id"]
          },
        ]
      }
      articles: {
        Row: {
          body: string
          category: string
          created_at: string | null
          created_by: string | null
          draft_body: string | null
          draft_category: string | null
          draft_thumbnail_url: string | null
          draft_title: string | null
          hidden_at: string | null
          hidden_by: string | null
          id: string
          published_at: string | null
          published_by: string | null
          status: Database["public"]["Enums"]["article_status"]
          thumbnail_url: string | null
          title: string
          updated_at: string | null
          updated_by: string | null
        }
        Insert: {
          body?: string
          category?: string
          created_at?: string | null
          created_by?: string | null
          draft_body?: string | null
          draft_category?: string | null
          draft_thumbnail_url?: string | null
          draft_title?: string | null
          hidden_at?: string | null
          hidden_by?: string | null
          id?: string
          published_at?: string | null
          published_by?: string | null
          status?: Database["public"]["Enums"]["article_status"]
          thumbnail_url?: string | null
          title: string
          updated_at?: string | null
          updated_by?: string | null
        }
        Update: {
          body?: string
          category?: string
          created_at?: string | null
          created_by?: string | null
          draft_body?: string | null
          draft_category?: string | null
          draft_thumbnail_url?: string | null
          draft_title?: string | null
          hidden_at?: string | null
          hidden_by?: string | null
          id?: string
          published_at?: string | null
          published_by?: string | null
          status?: Database["public"]["Enums"]["article_status"]
          thumbnail_url?: string | null
          title?: string
          updated_at?: string | null
          updated_by?: string | null
        }
        Relationships: []
      }
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
          selected_service_center: string
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
          selected_service_center: string
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
          selected_service_center?: string
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
          selected_service_center: string
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
          selected_service_center: string
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
          selected_service_center?: string
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
          service_center: string
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
          service_center: string
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
          service_center?: string
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
          service_center: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          condom_qty?: number
          id?: string
          last_restocked_at?: string | null
          lubricant_qty?: number
          service_center: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          condom_qty?: number
          id?: string
          last_restocked_at?: string | null
          lubricant_qty?: number
          service_center?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "service_center_inventory_service_center_fkey"
            columns: ["service_center"]
            isOneToOne: true
            referencedRelation: "service_centers"
            referencedColumns: ["name"]
          },
        ]
      }
      service_centers: {
        Row: {
          address: string | null
          appointment_service_enabled: boolean
          appointment_times: string[]
          condom_service_enabled: boolean
          contacts: Json
          created_at: string
          description: string | null
          display_order: number
          image_url: string | null
          is_active: boolean
          latitude: number | null
          longitude: number | null
          name: string
          operating_hours: string | null
          pickup_times: string[]
          updated_at: string
        }
        Insert: {
          address?: string | null
          appointment_service_enabled?: boolean
          appointment_times?: string[]
          condom_service_enabled?: boolean
          contacts?: Json
          created_at?: string
          description?: string | null
          display_order?: number
          image_url?: string | null
          is_active?: boolean
          latitude?: number | null
          longitude?: number | null
          name: string
          operating_hours?: string | null
          pickup_times?: string[]
          updated_at?: string
        }
        Update: {
          address?: string | null
          appointment_service_enabled?: boolean
          appointment_times?: string[]
          condom_service_enabled?: boolean
          contacts?: Json
          created_at?: string
          description?: string | null
          display_order?: number
          image_url?: string | null
          is_active?: boolean
          latitude?: number | null
          longitude?: number | null
          name?: string
          operating_hours?: string | null
          pickup_times?: string[]
          updated_at?: string
        }
        Relationships: []
      }
      staff_change_logs: {
        Row: {
          action: Database["public"]["Enums"]["audit_action"]
          created_at: string
          id: string
          new_value: Json | null
          old_value: Json | null
          performed_by: string | null
          target_id: string
          target_name: string | null
          target_staff_user_id: string | null
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
          target_name?: string | null
          target_staff_user_id?: string | null
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
          target_name?: string | null
          target_staff_user_id?: string | null
          target_table?: string
        }
        Relationships: []
      }
      staff_notification_hidden: {
        Row: {
          hidden_at: string
          notification_id: string
          staff_user_id: string
        }
        Insert: {
          hidden_at?: string
          notification_id: string
          staff_user_id: string
        }
        Update: {
          hidden_at?: string
          notification_id?: string
          staff_user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_notification"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "staff_notifications"
            referencedColumns: ["id"]
          },
        ]
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
            foreignKeyName: "staff_notification_reads_notification_id_fkey"
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
          service_center: string | null
          source_id: string
          source_type: string
        }
        Insert: {
          created_at?: string
          event_type: string
          id?: string
          metadata?: Json
          service_center?: string | null
          source_id: string
          source_type: string
        }
        Update: {
          created_at?: string
          event_type?: string
          id?: string
          metadata?: Json
          service_center?: string | null
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
          line_display_name: string | null
          line_picture_url: string | null
          line_user_id: string | null
          role: Database["public"]["Enums"]["role"]
          service_centers: string[] | null
          staff_user_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          first_name?: string | null
          id?: string
          last_name?: string | null
          line_display_name?: string | null
          line_picture_url?: string | null
          line_user_id?: string | null
          role?: Database["public"]["Enums"]["role"]
          service_centers?: string[] | null
          staff_user_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          first_name?: string | null
          id?: string
          last_name?: string | null
          line_display_name?: string | null
          line_picture_url?: string | null
          line_user_id?: string | null
          role?: Database["public"]["Enums"]["role"]
          service_centers?: string[] | null
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
          health_coverage: string | null
          id: string
          nationality: string | null
          nickname: string | null
          phone_number: string | null
          user_id: string
          username: string
        }
        Insert: {
          created_at?: string | null
          date_of_birth?: string | null
          gender?: string | null
          health_coverage?: string | null
          id?: string
          nationality?: string | null
          nickname?: string | null
          phone_number?: string | null
          user_id: string
          username?: string
        }
        Update: {
          created_at?: string | null
          date_of_birth?: string | null
          gender?: string | null
          health_coverage?: string | null
          id?: string
          nationality?: string | null
          nickname?: string | null
          phone_number?: string | null
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
      add_service_center: { Args: { p_name: string }; Returns: undefined }
      create_condom_request: {
        Args: {
          p_condom_quantities: Json
          p_lubricant_quantity: number
          p_message?: string
          p_selected_date: string
          p_selected_service_center: string
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
          p_service_center: string
          p_time: string
          p_user_id: string
        }
        Returns: string
      }
      delete_service_center: { Args: { p_name: string }; Returns: undefined }
      get_appointment_status_log: {
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
          appointment_id: string
          changed_at: string
          from_status: string
          full_name: string
          id: string
          performed_by: string
          reference_number: string
          to_status: string
        }[]
      }
      get_article_detail: {
        Args: { p_article_id: string }
        Returns: {
          body: string
          category: string
          created_by_name: string
          id: string
          published_at: string
          thumbnail_url: string | null
          title: string
        }[]
      }
      get_average_lead_time: {
        Args: {
          p_date_from: string
          p_date_to: string
          p_service_center?: string
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
          service_center: string
        }[]
      }
      get_days_until_reset: { Args: never; Returns: number }
      get_my_service_centers: { Args: never; Returns: string[] | null }
      get_inventory_forecast: {
        Args: never
        Returns: {
          condom_daily_burn: number
          condom_days_left: number
          condom_qty: number
          is_active: boolean
          lubricant_daily_burn: number
          lubricant_days_left: number
          lubricant_qty: number
          service_center: string
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
          action: Database["public"]["Enums"]["audit_action"]
          condom_delta: number
          created_at: string
          full_name: string
          id: string
          lubricant_delta: number
          note: string
          performed_by: string
          reason: string
          service_center: string
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
      get_published_articles: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          category: string
          created_by_name: string
          excerpt: string
          id: string
          published_at: string
          thumbnail_url: string | null
          title: string
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
          service_center: string
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
          service_center: string
        }[]
      }
      get_service_centers: {
        Args: never
        Returns: {
          address: string | null
          appointment_service_enabled: boolean
          appointment_times: string[]
          condom_service_enabled: boolean
          contacts: Json
          created_at: string
          description: string | null
          display_order: number
          image_url: string | null
          is_active: boolean
          latitude: number | null
          longitude: number | null
          name: string
          operating_hours: string | null
          pickup_times: string[]
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "service_centers"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_staff_change_log: {
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
          target_name: string | null
          target_staff_user_id: string | null
        }[]
      }
      get_staff_workload: {
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
          service_center: string
          staff_user_id: string
        }[]
      }
      get_staff_workload_trend: {
        Args: {
          p_date_from?: string
          p_date_to?: string
          p_service_center?: string
          p_staff_user_id?: string
        }
        Returns: {
          cancelled_count: number
          completed_count: number
          staff_user_id: string
          week_start: string
        }[]
      }
      init_service_center_inventory: {
        Args: { p_name: string }
        Returns: undefined
      }
      is_admin: { Args: never; Returns: boolean }
      is_staff: { Args: never; Returns: boolean }
      is_superadmin: { Args: never; Returns: boolean }
      save_recovery_codes: {
        Args: { secret_codes: string[] }
        Returns: undefined
      }
      toggle_service_center_active: {
        Args: { p_is_active: boolean; p_name: string }
        Returns: undefined
      }
      upsert_service_center: {
        Args: {
          p_address?: string
          p_appointment_service_enabled?: boolean
          p_appointment_times?: string[]
          p_condom_service_enabled?: boolean
          p_contacts?: Json
          p_description?: string
          p_display_order?: number
          p_image_url?: string
          p_latitude?: number
          p_longitude?: number
          p_name: string
          p_operating_hours?: string
          p_pickup_times?: string[]
        }
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
      write_staff_change_log: {
        Args: {
          p_action: Database["public"]["Enums"]["audit_action"]
          p_new_value?: Json
          p_old_value?: Json
          p_performed_by?: string
          p_target_id: string
          p_target_name?: string
          p_target_staff_user_id?: string
          p_target_table: string
        }
        Returns: undefined
      }
    }
    Enums: {
      appointment_status:
        | "pending"
        | "confirmed"
        | "completed"
        | "cancelled_by_user"
        | "cancelled_by_staff"
      article_status: "draft" | "published" | "hidden"
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
        "completed",
        "cancelled_by_user",
        "cancelled_by_staff",
      ],
      article_status: ["draft", "published", "hidden"],
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
      transaction_type: ["restock", "fulfillment", "adjustment"],
    },
  },
} as const
