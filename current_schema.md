CREATE SCHEMA "public";
CREATE TABLE "appointments" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"customer_id" bigint,
	"provider_id" bigint,
	"appointment_type" varchar(50),
	"appointment_date" timestamp with time zone,
	"status" varchar(50),
	"remarks" text
);
CREATE TABLE "audit_logs" (
	"id" bigserial PRIMARY KEY,
	"user_id" bigint,
	"action" varchar(255),
	"entity_type" varchar(100),
	"entity_id" bigint,
	"old_data" jsonb,
	"new_data" jsonb,
	"ip_address" varchar(100),
	"device_info" text,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "auth_devices" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"owner_type" varchar(30) NOT NULL,
	"owner_id" varchar(50) NOT NULL,
	"customer_id" bigint,
	"user_id" bigint,
	"fingerprint_hash" varchar(128) NOT NULL,
	"device_id" varchar(120),
	"device_name" varchar(255),
	"platform" varchar(50),
	"browser" varchar(100),
	"os" varchar(100),
	"ip_address" varchar(100),
	"user_agent" text,
	"is_trusted" boolean DEFAULT false NOT NULL,
	"first_seen_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"last_seen_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "auth_sessions" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"session_id" uuid NOT NULL,
	"subject_id" varchar(120) NOT NULL,
	"owner_type" varchar(30) NOT NULL,
	"owner_id" varchar(50) NOT NULL,
	"customer_id" bigint,
	"user_id" bigint,
	"auth_device_id" bigint,
	"principal_type" varchar(30) NOT NULL,
	"role_code" varchar(50),
	"user_type" varchar(30),
	"access_scope" varchar(30),
	"permissions" jsonb,
	"firebase_uid" varchar(128),
	"auth_provider" varchar(30),
	"email" varchar(255),
	"mobile" varchar(20),
	"branch_business_id" varchar(50),
	"login_method" varchar(50),
	"refresh_token_hash" varchar(128) NOT NULL,
	"refresh_token_expires_at" timestamp with time zone NOT NULL,
	"last_seen_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"ip_address" varchar(100),
	"user_agent" text,
	"revoked_at" timestamp with time zone,
	"revoked_reason" text,
	"is_current" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "benefit_ledger_transactions" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"wallet_id" bigint NOT NULL,
	"transaction_type" varchar(50) NOT NULL,
	"amount" numeric(15, 2) NOT NULL,
	"service_type" varchar(50),
	"reference_type" varchar(100),
	"reference_id" bigint,
	"remarks" text,
	"created_by" bigint,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"metadata" jsonb
);
CREATE TABLE "businesses" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"code" varchar(50) NOT NULL,
	"name" varchar(255) NOT NULL,
	"business_type" varchar(100),
	"status" varchar(50) DEFAULT 'ACTIVE',
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "cash_wallet_transactions" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"wallet_id" bigint NOT NULL,
	"transaction_type" varchar(50) NOT NULL,
	"amount" numeric(15, 2) NOT NULL,
	"reference_type" varchar(100),
	"reference_id" bigint,
	"remarks" text,
	"created_by" bigint,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"metadata" jsonb
);
CREATE TABLE "commercial_settings" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"code" varchar(100) NOT NULL,
	"value_type" varchar(30) NOT NULL,
	"value_text" text,
	"value_number" numeric(15, 2),
	"value_boolean" boolean,
	"status" varchar(50) DEFAULT 'ACTIVE' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "complaints" (
	"id" bigserial PRIMARY KEY,
	"customer_id" bigint,
	"complaint_type" varchar(100),
	"description" text,
	"status" varchar(50),
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "consultations" (
	"id" bigserial PRIMARY KEY,
	"customer_id" bigint,
	"appointment_id" bigint,
	"doctor_name" varchar(255),
	"diagnosis" text,
	"notes" text
);
CREATE TABLE "credit_accounts" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"customer_id" bigint,
	"credit_limit" numeric(15, 2),
	"available_credit" numeric(15, 2),
	"outstanding_amount" numeric(15, 2),
	"status" varchar(50)
);
CREATE TABLE "credit_transactions" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"credit_account_id" bigint,
	"transaction_type" varchar(50),
	"amount" numeric(15, 2),
	"remarks" text,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "crm_activities" (
	"id" bigserial PRIMARY KEY,
	"customer_id" bigint,
	"activity_type" varchar(50),
	"notes" text,
	"created_by" bigint,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "crm_tasks" (
	"id" bigserial PRIMARY KEY,
	"customer_id" bigint,
	"assigned_to" bigint,
	"due_date" timestamp with time zone,
	"status" varchar(50),
	"notes" text
);
CREATE TABLE "customer_contacts" (
	"id" bigserial PRIMARY KEY,
	"customer_id" bigint NOT NULL,
	"name" varchar(255),
	"relation" varchar(100),
	"mobile" varchar(20),
	"is_primary" boolean DEFAULT false,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "customer_status_history" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"customer_id" bigint NOT NULL,
	"old_status" varchar(50),
	"new_status" varchar(50),
	"changed_by" bigint,
	"remarks" text,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "customers" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"customer_code" varchar(50),
	"aadhaar_number" varchar(20),
	"first_name" varchar(255),
	"last_name" varchar(255),
	"dob" date,
	"gender" varchar(20),
	"mobile" varchar(20) NOT NULL,
	"email" varchar(255),
	"address_line1" text,
	"address_line2" text,
	"city" varchar(100),
	"district" varchar(100),
	"state" varchar(100),
	"pincode" varchar(20),
	"status" varchar(50),
	"created_by" bigint,
	"approved_by" bigint,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"deleted_at" timestamp with time zone,
	"blood_group" varchar(10),
	"agent_code" varchar(50) NOT NULL,
	"referral_code" varchar(50),
	"referred_by_id" bigint,
	"firebase_uid" varchar(128),
	"last_login_at" timestamp with time zone
);
CREATE TABLE "dental_records" (
	"id" bigserial PRIMARY KEY,
	"customer_id" bigint,
	"appointment_id" bigint,
	"treatment_name" varchar(255),
	"notes" text
);
CREATE TABLE "departments" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"business_id" bigint NOT NULL,
	"code" varchar(50),
	"name" varchar(255),
	"status" varchar(50),
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "device_push_tokens" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL CONSTRAINT "device_push_tokens_uuid_key" UNIQUE,
	"customer_id" bigint NOT NULL,
	"token" text NOT NULL CONSTRAINT "device_push_tokens_token_key" UNIQUE,
	"platform" varchar(30) NOT NULL,
	"device_label" varchar(120),
	"is_active" boolean DEFAULT true NOT NULL,
	"last_seen_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"auth_device_id" bigint
);
CREATE TABLE "document_classifications" (
	"id" bigserial PRIMARY KEY,
	"document_id" bigint,
	"classification" varchar(100),
	"confidence" numeric(5, 2)
);
CREATE TABLE "document_extractions" (
	"id" bigserial PRIMARY KEY,
	"document_id" bigint,
	"extracted_text" text,
	"confidence_score" numeric(5, 2),
	"extraction_status" varchar(50),
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "document_processing_logs" (
	"id" bigserial PRIMARY KEY,
	"document_id" bigint,
	"stage" varchar(100),
	"status" varchar(50),
	"remarks" text,
	"processed_at" timestamp with time zone
);
CREATE TABLE "documents" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"customer_id" bigint,
	"uploaded_by" bigint,
	"document_type" varchar(100),
	"file_name" varchar(255),
	"storage_path" text,
	"file_size" bigint,
	"mime_type" varchar(100),
	"status" varchar(50),
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "lab_reports" (
	"id" bigserial PRIMARY KEY,
	"customer_id" bigint,
	"appointment_id" bigint,
	"document_id" bigint,
	"report_date" date
);
CREATE TABLE "login_history" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"owner_type" varchar(30) NOT NULL,
	"owner_id" varchar(50) NOT NULL,
	"customer_id" bigint,
	"user_id" bigint,
	"auth_device_id" bigint,
	"session_id" uuid,
	"login_method" varchar(50),
	"status" varchar(30) NOT NULL,
	"reason" text,
	"ip_address" varchar(100),
	"user_agent" text,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "membership_types" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"code" varchar(50),
	"name" varchar(255),
	"joining_fee" numeric(12, 2),
	"discount_percentage" numeric(5, 2),
	"credit_eligible" boolean,
	"status" varchar(50)
);
CREATE TABLE "memberships" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"customer_id" bigint,
	"membership_type_id" bigint,
	"membership_number" varchar(100),
	"joining_fee" numeric(12, 2),
	"activation_date" date,
	"expiry_date" date,
	"status" varchar(50),
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "notifications" (
	"id" bigserial PRIMARY KEY,
	"customer_id" bigint,
	"title" varchar(255),
	"message" text,
	"channel" varchar(50),
	"status" varchar(50),
	"sent_at" timestamp with time zone
);
CREATE TABLE "permissions" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"code" varchar(100),
	"name" varchar(255),
	"description" text
);
CREATE TABLE "prescriptions" (
	"id" bigserial PRIMARY KEY,
	"customer_id" bigint,
	"consultation_id" bigint,
	"document_id" bigint,
	"issue_date" date
);
CREATE TABLE "pricing_rule_audits" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"wallet_id" bigint,
	"customer_id" bigint,
	"service_type" varchar(50) NOT NULL,
	"original_amount" numeric(15, 2) NOT NULL,
	"benefit_applied" numeric(15, 2) DEFAULT '0' NOT NULL,
	"membership_discount_applied" numeric(15, 2) DEFAULT '0' NOT NULL,
	"reward_points_earned" numeric(15, 2) DEFAULT '0' NOT NULL,
	"reward_points_redeemed" numeric(15, 2) DEFAULT '0' NOT NULL,
	"reward_credit_applied" numeric(15, 2) DEFAULT '0' NOT NULL,
	"cash_wallet_deducted" numeric(15, 2) DEFAULT '0' NOT NULL,
	"final_payable_amount" numeric(15, 2) DEFAULT '0' NOT NULL,
	"matched_rule_code" varchar(100),
	"preloading_used" boolean DEFAULT false NOT NULL,
	"metadata" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "product_categories" (
	"id" bigserial PRIMARY KEY,
	"name" varchar(255)
);
CREATE TABLE "products" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"product_code" varchar(100),
	"product_name" varchar(255),
	"brand" varchar(255),
	"category_id" bigint,
	"unit" varchar(50)
);
CREATE TABLE "agent_preferences" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"user_id" bigint NOT NULL,
	"theme_preference" varchar(50),
	"language_preference" varchar(20),
	"timezone" varchar(100),
	"availability" jsonb,
	"working_hours" jsonb,
	"working_area" jsonb,
	"emergency_contact" jsonb,
	"notification_preferences" jsonb,
	"dashboard_layout" jsonb,
	"profile_preferences" jsonb,
	"device_preferences" jsonb,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"deleted_at" timestamp with time zone
);
CREATE TABLE "agent_branch_assignments" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"user_id" bigint NOT NULL,
	"business_id" bigint NOT NULL,
	"status" varchar(50) DEFAULT 'PENDING' NOT NULL,
	"is_primary" boolean DEFAULT false NOT NULL,
	"requested_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"approved_at" timestamp with time zone,
	"transferred_at" timestamp with time zone,
	"inactive_at" timestamp with time zone,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE "provider_profile_branch_assignments" (
	"provider_profile_id" bigint,
	"business_id" bigint,
	"is_primary" boolean DEFAULT false NOT NULL,
	"assigned_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT "provider_profile_branch_assignments_pkey" PRIMARY KEY("provider_profile_id","business_id")
);
CREATE TABLE "provider_profiles" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"user_id" bigint NOT NULL,
	"display_name" varchar(255),
	"contact_email" varchar(255),
	"contact_phone" varchar(20),
	"profile_photo_storage_path" text,
	"profile_photo_file_name" varchar(255),
	"signature_storage_path" text,
	"signature_file_name" varchar(255),
	"qualifications" text,
	"specialization" varchar(255),
	"registration_details" jsonb,
	"consultation_availability" jsonb,
	"working_hours" jsonb,
	"notification_preferences" jsonb,
	"print_preferences" jsonb,
	"theme_preference" varchar(50),
	"language_preference" varchar(20),
	"default_printer" varchar(255),
	"timezone" varchar(100),
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"deleted_at" timestamp with time zone
);
CREATE TABLE "purchase_items" (
	"id" bigserial PRIMARY KEY,
	"purchase_id" bigint,
	"product_id" bigint,
	"quantity" numeric(12, 2),
	"unit_price" numeric(15, 2),
	"total_price" numeric(15, 2),
	"item_type" varchar(50) DEFAULT 'MEDICINE',
	"item_name" varchar(255),
	"metadata" jsonb
);
CREATE TABLE "purchases" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"customer_id" bigint,
	"provider_id" bigint,
	"invoice_number" varchar(255),
	"total_amount" numeric(15, 2),
	"discount_amount" numeric(15, 2),
	"payable_amount" numeric(15, 2),
	"purchase_date" timestamp with time zone,
	"appointment_id" bigint,
	"purchase_kind" varchar(50) DEFAULT 'GENERAL',
	"payment_status" varchar(50) DEFAULT 'PENDING',
	"payment_summary" jsonb,
	"billing_snapshot" jsonb
);
CREATE TABLE "referral_reward_events" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL CONSTRAINT "referral_reward_events_uuid_key" UNIQUE,
	"referrer_customer_id" bigint NOT NULL,
	"referred_customer_id" bigint NOT NULL CONSTRAINT "referral_reward_events_referred_customer_id_key" UNIQUE,
	"referral_code" varchar(50),
	"status" varchar(30) DEFAULT 'PENDING' NOT NULL,
	"reward_points" numeric(15, 2) DEFAULT '0' NOT NULL,
	"qualifying_reference_type" varchar(100),
	"qualifying_reference_id" bigint,
	"notes" text,
	"verified_at" timestamp with time zone,
	"qualified_at" timestamp with time zone,
	"rewarded_at" timestamp with time zone,
	"rejected_at" timestamp with time zone,
	"rejected_reason" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expired_at" timestamp with time zone
);
CREATE TABLE "reward_point_rules" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"action_code" varchar(100) NOT NULL,
	"display_name" varchar(255) NOT NULL,
	"points" numeric(12, 2) NOT NULL,
	"requires_approval" boolean DEFAULT false NOT NULL,
	"status" varchar(50) DEFAULT 'ACTIVE' NOT NULL,
	"metadata" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "reward_point_transactions" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"wallet_id" bigint NOT NULL,
	"transaction_type" varchar(50) NOT NULL,
	"action_code" varchar(100),
	"points" numeric(15, 2) NOT NULL,
	"reason" text,
	"reference_type" varchar(100),
	"reference_id" bigint,
	"status" varchar(30) DEFAULT 'APPROVED' NOT NULL,
	"created_by" bigint,
	"approved_by" bigint,
	"approved_at" timestamp with time zone,
	"expires_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"metadata" jsonb
);
CREATE TABLE "reward_redemption_rules" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL CONSTRAINT "reward_redemption_rules_uuid_key" UNIQUE,
	"code" varchar(50) NOT NULL CONSTRAINT "reward_redemption_rules_code_key" UNIQUE,
	"points_required" numeric(12, 2) NOT NULL,
	"cash_credit_amount" numeric(12, 2) NOT NULL,
	"minimum_points" numeric(12, 2) DEFAULT '0' NOT NULL,
	"maximum_points_per_month" numeric(12, 2) DEFAULT '0' NOT NULL,
	"expiry_months" integer DEFAULT 24 NOT NULL,
	"credit_ledger_type" varchar(50) DEFAULT 'CASH' NOT NULL,
	"status" varchar(50) DEFAULT 'ACTIVE' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "role_permissions" (
	"role_id" bigint,
	"permission_id" bigint,
	CONSTRAINT "role_permissions_pkey" PRIMARY KEY("role_id","permission_id")
);
CREATE TABLE "roles" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"code" varchar(50),
	"name" varchar(255),
	"description" text,
	"user_type" varchar(30),
	"default_scope" varchar(30),
	"is_system_role" boolean DEFAULT false
);
CREATE TABLE "service_benefit_rules" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL CONSTRAINT "service_benefit_rules_uuid_key" UNIQUE,
	"service_type" varchar(50) NOT NULL CONSTRAINT "service_benefit_rules_service_type_key" UNIQUE,
	"is_benefit_eligible" boolean DEFAULT false NOT NULL,
	"max_benefit_amount" numeric(12, 2) DEFAULT '0' NOT NULL,
	"qualifies_referral_reward" boolean DEFAULT true NOT NULL,
	"reward_points_on_service" numeric(12, 2) DEFAULT '0' NOT NULL,
	"status" varchar(50) DEFAULT 'ACTIVE' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"wallets_allowed" varchar(120) DEFAULT 'CASH',
	"allow_external_payment" boolean DEFAULT true NOT NULL
);
CREATE TABLE "service_providers" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"business_id" bigint,
	"provider_name" varchar(255),
	"provider_type" varchar(100),
	"status" varchar(50)
);
CREATE TABLE "shield_cards" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"customer_id" bigint,
	"card_number" varchar(100),
	"qr_code" text,
	"status" varchar(50),
	"issued_business_id" bigint,
	"issued_at" timestamp with time zone
);
CREATE TABLE "users" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid NOT NULL,
	"employee_code" varchar(50),
	"first_name" varchar(255),
	"last_name" varchar(255),
	"mobile" varchar(20),
	"email" varchar(255),
	"password_hash" text,
	"role_id" bigint,
	"department_id" bigint,
	"status" varchar(50),
	"last_login_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"deleted_at" timestamp with time zone,
	"firebase_uid" varchar(128),
	"auth_provider" varchar(30),
	"user_type" varchar(30),
	"access_scope" varchar(30),
	"branch_business_id" bigint
);
CREATE TABLE "wallet_transactions" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"wallet_id" bigint,
	"transaction_type" varchar(50),
	"sub_ledger_type" varchar(50) DEFAULT 'CASH',
	"amount" numeric(15, 2),
	"reference_type" varchar(100),
	"reference_id" bigint,
	"remarks" text,
	"created_by" bigint,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"is_customer_visible" boolean DEFAULT true,
	"expires_at" timestamp with time zone,
	"metadata" jsonb
);
CREATE TABLE "wallets" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid,
	"customer_id" bigint,
	"status" varchar(50),
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX "appointments_pkey" ON "appointments" ("id");
CREATE UNIQUE INDEX "appointments_uuid_key" ON "appointments" ("uuid");
CREATE INDEX "idx_agent_branch_assignment_business" ON "agent_branch_assignments" ("business_id");
CREATE INDEX "idx_agent_branch_assignment_status" ON "agent_branch_assignments" ("status");
CREATE INDEX "idx_agent_branch_assignment_user" ON "agent_branch_assignments" ("user_id");
CREATE UNIQUE INDEX "agent_branch_assignments_pkey" ON "agent_branch_assignments" ("id");
CREATE UNIQUE INDEX "agent_branch_assignments_user_business_key" ON "agent_branch_assignments" ("user_id","business_id");
CREATE UNIQUE INDEX "agent_branch_assignments_uuid_key" ON "agent_branch_assignments" ("uuid");
CREATE UNIQUE INDEX "agent_preferences_pkey" ON "agent_preferences" ("id");
CREATE UNIQUE INDEX "agent_preferences_user_id_key" ON "agent_preferences" ("user_id");
CREATE UNIQUE INDEX "agent_preferences_uuid_key" ON "agent_preferences" ("uuid");
CREATE INDEX "idx_appointment_customer" ON "appointments" ("customer_id");
CREATE INDEX "idx_appointment_date" ON "appointments" ("appointment_date");
CREATE INDEX "idx_appointment_provider" ON "appointments" ("provider_id");
CREATE INDEX "idx_appointment_status" ON "appointments" ("status");
CREATE UNIQUE INDEX "audit_logs_pkey" ON "audit_logs" ("id");
CREATE UNIQUE INDEX "auth_devices_pkey" ON "auth_devices" ("id");
CREATE UNIQUE INDEX "auth_devices_uuid_key" ON "auth_devices" ("uuid");
CREATE INDEX "idx_auth_devices_customer" ON "auth_devices" ("customer_id");
CREATE INDEX "idx_auth_devices_last_seen" ON "auth_devices" ("last_seen_at");
CREATE INDEX "idx_auth_devices_user" ON "auth_devices" ("user_id");
CREATE UNIQUE INDEX "uq_auth_devices_owner_fingerprint" ON "auth_devices" ("owner_type","owner_id","fingerprint_hash");
CREATE UNIQUE INDEX "auth_sessions_pkey" ON "auth_sessions" ("id");
CREATE UNIQUE INDEX "auth_sessions_refresh_token_hash_key" ON "auth_sessions" ("refresh_token_hash");
CREATE UNIQUE INDEX "auth_sessions_session_id_key" ON "auth_sessions" ("session_id");
CREATE UNIQUE INDEX "auth_sessions_uuid_key" ON "auth_sessions" ("uuid");
CREATE INDEX "idx_auth_sessions_auth_device" ON "auth_sessions" ("auth_device_id");
CREATE INDEX "idx_auth_sessions_current" ON "auth_sessions" ("is_current");
CREATE INDEX "idx_auth_sessions_customer" ON "auth_sessions" ("customer_id");
CREATE INDEX "idx_auth_sessions_owner" ON "auth_sessions" ("owner_type","owner_id");
CREATE INDEX "idx_auth_sessions_refresh_expiry" ON "auth_sessions" ("refresh_token_expires_at");
CREATE INDEX "idx_auth_sessions_user" ON "auth_sessions" ("user_id");
CREATE UNIQUE INDEX "benefit_ledger_transactions_pkey" ON "benefit_ledger_transactions" ("id");
CREATE UNIQUE INDEX "benefit_ledger_transactions_uuid_key" ON "benefit_ledger_transactions" ("uuid");
CREATE INDEX "idx_benefit_ledger_transactions_date" ON "benefit_ledger_transactions" ("created_at");
CREATE INDEX "idx_benefit_ledger_transactions_service" ON "benefit_ledger_transactions" ("service_type");
CREATE INDEX "idx_benefit_ledger_transactions_wallet" ON "benefit_ledger_transactions" ("wallet_id");
CREATE UNIQUE INDEX "businesses_code_key" ON "businesses" ("code");
CREATE UNIQUE INDEX "businesses_pkey" ON "businesses" ("id");
CREATE UNIQUE INDEX "businesses_uuid_key" ON "businesses" ("uuid");
CREATE UNIQUE INDEX "cash_wallet_transactions_pkey" ON "cash_wallet_transactions" ("id");
CREATE UNIQUE INDEX "cash_wallet_transactions_uuid_key" ON "cash_wallet_transactions" ("uuid");
CREATE INDEX "idx_cash_wallet_transactions_date" ON "cash_wallet_transactions" ("created_at");
CREATE INDEX "idx_cash_wallet_transactions_type" ON "cash_wallet_transactions" ("transaction_type");
CREATE INDEX "idx_cash_wallet_transactions_wallet" ON "cash_wallet_transactions" ("wallet_id");
CREATE UNIQUE INDEX "commercial_settings_code_key" ON "commercial_settings" ("code");
CREATE UNIQUE INDEX "commercial_settings_pkey" ON "commercial_settings" ("id");
CREATE UNIQUE INDEX "commercial_settings_uuid_key" ON "commercial_settings" ("uuid");
CREATE UNIQUE INDEX "complaints_pkey" ON "complaints" ("id");
CREATE UNIQUE INDEX "consultations_pkey" ON "consultations" ("id");
CREATE UNIQUE INDEX "credit_accounts_customer_id_key" ON "credit_accounts" ("customer_id");
CREATE UNIQUE INDEX "credit_accounts_pkey" ON "credit_accounts" ("id");
CREATE UNIQUE INDEX "credit_accounts_uuid_key" ON "credit_accounts" ("uuid");
CREATE UNIQUE INDEX "credit_transactions_pkey" ON "credit_transactions" ("id");
CREATE UNIQUE INDEX "credit_transactions_uuid_key" ON "credit_transactions" ("uuid");
CREATE UNIQUE INDEX "crm_activities_pkey" ON "crm_activities" ("id");
CREATE UNIQUE INDEX "crm_tasks_pkey" ON "crm_tasks" ("id");
CREATE UNIQUE INDEX "customer_contacts_pkey" ON "customer_contacts" ("id");
CREATE UNIQUE INDEX "customer_status_history_pkey" ON "customer_status_history" ("id");
CREATE UNIQUE INDEX "customer_status_history_uuid_key" ON "customer_status_history" ("uuid");
CREATE INDEX "idx_customer_status_history_customer" ON "customer_status_history" ("customer_id");
CREATE INDEX "idx_customer_status_history_date" ON "customer_status_history" ("created_at");
CREATE UNIQUE INDEX "customers_aadhaar_number_key" ON "customers" ("aadhaar_number");
CREATE UNIQUE INDEX "customers_customer_code_key" ON "customers" ("customer_code");
CREATE UNIQUE INDEX "customers_mobile_key" ON "customers" ("mobile");
CREATE UNIQUE INDEX "customers_pkey" ON "customers" ("id");
CREATE UNIQUE INDEX "customers_referral_code_key" ON "customers" ("referral_code");
CREATE UNIQUE INDEX "customers_uuid_key" ON "customers" ("uuid");
CREATE INDEX "idx_customer_aadhaar" ON "customers" ("aadhaar_number");
CREATE UNIQUE INDEX "idx_customer_firebase_uid" ON "customers" ("firebase_uid");
CREATE INDEX "idx_customer_mobile" ON "customers" ("mobile");
CREATE UNIQUE INDEX "dental_records_pkey" ON "dental_records" ("id");
CREATE UNIQUE INDEX "departments_pkey" ON "departments" ("id");
CREATE UNIQUE INDEX "departments_uuid_key" ON "departments" ("uuid");
CREATE UNIQUE INDEX "device_push_tokens_pkey" ON "device_push_tokens" ("id");
CREATE UNIQUE INDEX "device_push_tokens_token_key" ON "device_push_tokens" ("token");
CREATE UNIQUE INDEX "device_push_tokens_uuid_key" ON "device_push_tokens" ("uuid");
CREATE INDEX "idx_device_push_tokens_customer" ON "device_push_tokens" ("customer_id");
CREATE INDEX "idx_device_push_tokens_platform" ON "device_push_tokens" ("platform");
CREATE UNIQUE INDEX "document_classifications_pkey" ON "document_classifications" ("id");
CREATE UNIQUE INDEX "document_extractions_pkey" ON "document_extractions" ("id");
CREATE UNIQUE INDEX "document_processing_logs_pkey" ON "document_processing_logs" ("id");
CREATE UNIQUE INDEX "documents_pkey" ON "documents" ("id");
CREATE UNIQUE INDEX "documents_uuid_key" ON "documents" ("uuid");
CREATE UNIQUE INDEX "lab_reports_pkey" ON "lab_reports" ("id");
CREATE INDEX "idx_login_history_auth_device" ON "login_history" ("auth_device_id");
CREATE INDEX "idx_login_history_created_at" ON "login_history" ("created_at");
CREATE INDEX "idx_login_history_customer" ON "login_history" ("customer_id");
CREATE INDEX "idx_login_history_owner" ON "login_history" ("owner_type","owner_id");
CREATE INDEX "idx_login_history_user" ON "login_history" ("user_id");
CREATE UNIQUE INDEX "login_history_pkey" ON "login_history" ("id");
CREATE UNIQUE INDEX "login_history_uuid_key" ON "login_history" ("uuid");
CREATE UNIQUE INDEX "membership_types_code_key" ON "membership_types" ("code");
CREATE UNIQUE INDEX "membership_types_pkey" ON "membership_types" ("id");
CREATE UNIQUE INDEX "membership_types_uuid_key" ON "membership_types" ("uuid");
CREATE UNIQUE INDEX "memberships_customer_id_key" ON "memberships" ("customer_id");
CREATE UNIQUE INDEX "memberships_membership_number_key" ON "memberships" ("membership_number");
CREATE UNIQUE INDEX "memberships_pkey" ON "memberships" ("id");
CREATE UNIQUE INDEX "memberships_uuid_key" ON "memberships" ("uuid");
CREATE UNIQUE INDEX "notifications_pkey" ON "notifications" ("id");
CREATE UNIQUE INDEX "permissions_code_key" ON "permissions" ("code");
CREATE UNIQUE INDEX "permissions_pkey" ON "permissions" ("id");
CREATE UNIQUE INDEX "permissions_uuid_key" ON "permissions" ("uuid");
CREATE UNIQUE INDEX "prescriptions_pkey" ON "prescriptions" ("id");
CREATE INDEX "idx_pricing_rule_audits_customer" ON "pricing_rule_audits" ("customer_id");
CREATE INDEX "idx_pricing_rule_audits_date" ON "pricing_rule_audits" ("created_at");
CREATE INDEX "idx_pricing_rule_audits_service" ON "pricing_rule_audits" ("service_type");
CREATE INDEX "idx_pricing_rule_audits_wallet" ON "pricing_rule_audits" ("wallet_id");
CREATE UNIQUE INDEX "pricing_rule_audits_pkey" ON "pricing_rule_audits" ("id");
CREATE UNIQUE INDEX "pricing_rule_audits_uuid_key" ON "pricing_rule_audits" ("uuid");
CREATE UNIQUE INDEX "product_categories_pkey" ON "product_categories" ("id");
CREATE UNIQUE INDEX "products_pkey" ON "products" ("id");
CREATE UNIQUE INDEX "products_uuid_key" ON "products" ("uuid");
CREATE INDEX "idx_provider_profile_branch_business" ON "provider_profile_branch_assignments" ("business_id");
CREATE UNIQUE INDEX "provider_profile_branch_assignments_pkey" ON "provider_profile_branch_assignments" ("provider_profile_id","business_id");
CREATE UNIQUE INDEX "provider_profiles_pkey" ON "provider_profiles" ("id");
CREATE UNIQUE INDEX "provider_profiles_user_id_key" ON "provider_profiles" ("user_id");
CREATE UNIQUE INDEX "provider_profiles_uuid_key" ON "provider_profiles" ("uuid");
CREATE UNIQUE INDEX "purchase_items_pkey" ON "purchase_items" ("id");
CREATE INDEX "idx_purchases_appointment" ON "purchases" ("appointment_id");
CREATE INDEX "idx_purchases_kind" ON "purchases" ("purchase_kind");
CREATE INDEX "idx_purchases_payment_status" ON "purchases" ("payment_status");
CREATE UNIQUE INDEX "purchases_pkey" ON "purchases" ("id");
CREATE UNIQUE INDEX "purchases_uuid_key" ON "purchases" ("uuid");
CREATE INDEX "idx_referral_reward_events_referrer" ON "referral_reward_events" ("referrer_customer_id");
CREATE INDEX "idx_referral_reward_events_status" ON "referral_reward_events" ("status");
CREATE UNIQUE INDEX "referral_reward_events_pkey" ON "referral_reward_events" ("id");
CREATE UNIQUE INDEX "referral_reward_events_referred_customer_id_key" ON "referral_reward_events" ("referred_customer_id");
CREATE UNIQUE INDEX "referral_reward_events_uuid_key" ON "referral_reward_events" ("uuid");
CREATE UNIQUE INDEX "reward_point_rules_action_code_key" ON "reward_point_rules" ("action_code");
CREATE UNIQUE INDEX "reward_point_rules_pkey" ON "reward_point_rules" ("id");
CREATE UNIQUE INDEX "reward_point_rules_uuid_key" ON "reward_point_rules" ("uuid");
CREATE INDEX "idx_reward_point_transactions_action" ON "reward_point_transactions" ("action_code");
CREATE INDEX "idx_reward_point_transactions_date" ON "reward_point_transactions" ("created_at");
CREATE INDEX "idx_reward_point_transactions_status" ON "reward_point_transactions" ("status");
CREATE INDEX "idx_reward_point_transactions_wallet" ON "reward_point_transactions" ("wallet_id");
CREATE UNIQUE INDEX "reward_point_transactions_pkey" ON "reward_point_transactions" ("id");
CREATE UNIQUE INDEX "reward_point_transactions_uuid_key" ON "reward_point_transactions" ("uuid");
CREATE UNIQUE INDEX "reward_redemption_rules_code_key" ON "reward_redemption_rules" ("code");
CREATE UNIQUE INDEX "reward_redemption_rules_pkey" ON "reward_redemption_rules" ("id");
CREATE UNIQUE INDEX "reward_redemption_rules_uuid_key" ON "reward_redemption_rules" ("uuid");
CREATE UNIQUE INDEX "role_permissions_pkey" ON "role_permissions" ("role_id","permission_id");
CREATE UNIQUE INDEX "roles_code_key" ON "roles" ("code");
CREATE UNIQUE INDEX "roles_pkey" ON "roles" ("id");
CREATE UNIQUE INDEX "roles_uuid_key" ON "roles" ("uuid");
CREATE UNIQUE INDEX "service_benefit_rules_pkey" ON "service_benefit_rules" ("id");
CREATE UNIQUE INDEX "service_benefit_rules_service_type_key" ON "service_benefit_rules" ("service_type");
CREATE UNIQUE INDEX "service_benefit_rules_uuid_key" ON "service_benefit_rules" ("uuid");
CREATE UNIQUE INDEX "service_providers_pkey" ON "service_providers" ("id");
CREATE UNIQUE INDEX "service_providers_uuid_key" ON "service_providers" ("uuid");
CREATE UNIQUE INDEX "shield_cards_card_number_key" ON "shield_cards" ("card_number");
CREATE UNIQUE INDEX "shield_cards_customer_id_key" ON "shield_cards" ("customer_id");
CREATE UNIQUE INDEX "shield_cards_pkey" ON "shield_cards" ("id");
CREATE UNIQUE INDEX "shield_cards_uuid_key" ON "shield_cards" ("uuid");
CREATE INDEX "idx_user_branch_business" ON "users" ("branch_business_id");
CREATE INDEX "idx_user_email" ON "users" ("email");
CREATE UNIQUE INDEX "idx_user_firebase_uid" ON "users" ("firebase_uid");
CREATE INDEX "idx_user_mobile" ON "users" ("mobile");
CREATE INDEX "idx_user_role" ON "users" ("role_id");
CREATE UNIQUE INDEX "users_email_key" ON "users" ("email");
CREATE UNIQUE INDEX "users_mobile_key" ON "users" ("mobile");
CREATE UNIQUE INDEX "users_pkey" ON "users" ("id");
CREATE UNIQUE INDEX "users_uuid_key" ON "users" ("uuid");
CREATE INDEX "idx_wallet_transaction_date" ON "wallet_transactions" ("created_at");
CREATE INDEX "idx_wallet_transaction_type" ON "wallet_transactions" ("transaction_type");
CREATE INDEX "idx_wallet_transaction_wallet" ON "wallet_transactions" ("wallet_id");
CREATE UNIQUE INDEX "wallet_transactions_pkey" ON "wallet_transactions" ("id");
CREATE UNIQUE INDEX "wallet_transactions_uuid_key" ON "wallet_transactions" ("uuid");
CREATE UNIQUE INDEX "wallets_customer_id_key" ON "wallets" ("customer_id");
CREATE UNIQUE INDEX "wallets_pkey" ON "wallets" ("id");
CREATE UNIQUE INDEX "wallets_uuid_key" ON "wallets" ("uuid");
ALTER TABLE "appointments" ADD CONSTRAINT "appointments_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "appointments" ADD CONSTRAINT "appointments_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "service_providers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "agent_branch_assignments" ADD CONSTRAINT "agent_branch_assignments_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "businesses"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "agent_branch_assignments" ADD CONSTRAINT "agent_branch_assignments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "agent_preferences" ADD CONSTRAINT "agent_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "benefit_ledger_transactions" ADD CONSTRAINT "benefit_ledger_transactions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "benefit_ledger_transactions" ADD CONSTRAINT "benefit_ledger_transactions_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "wallets"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "cash_wallet_transactions" ADD CONSTRAINT "cash_wallet_transactions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "cash_wallet_transactions" ADD CONSTRAINT "cash_wallet_transactions_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "wallets"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "complaints" ADD CONSTRAINT "complaints_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "consultations" ADD CONSTRAINT "consultations_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "appointments"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "consultations" ADD CONSTRAINT "consultations_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "credit_accounts" ADD CONSTRAINT "credit_accounts_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "credit_transactions" ADD CONSTRAINT "credit_transactions_credit_account_id_fkey" FOREIGN KEY ("credit_account_id") REFERENCES "credit_accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "crm_activities" ADD CONSTRAINT "crm_activities_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "crm_activities" ADD CONSTRAINT "crm_activities_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "crm_tasks" ADD CONSTRAINT "crm_tasks_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "crm_tasks" ADD CONSTRAINT "crm_tasks_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "customer_contacts" ADD CONSTRAINT "customer_contacts_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "customer_status_history" ADD CONSTRAINT "customer_status_history_changed_by_fkey" FOREIGN KEY ("changed_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "customer_status_history" ADD CONSTRAINT "customer_status_history_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "customers" ADD CONSTRAINT "customers_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "customers" ADD CONSTRAINT "customers_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "customers" ADD CONSTRAINT "customers_referred_by_id_fkey" FOREIGN KEY ("referred_by_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "dental_records" ADD CONSTRAINT "dental_records_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "appointments"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "dental_records" ADD CONSTRAINT "dental_records_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "departments" ADD CONSTRAINT "departments_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "businesses"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "document_classifications" ADD CONSTRAINT "document_classifications_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "documents"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "document_extractions" ADD CONSTRAINT "document_extractions_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "documents"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "document_processing_logs" ADD CONSTRAINT "document_processing_logs_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "documents"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "documents" ADD CONSTRAINT "documents_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "documents" ADD CONSTRAINT "documents_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "lab_reports" ADD CONSTRAINT "lab_reports_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "appointments"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "lab_reports" ADD CONSTRAINT "lab_reports_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "lab_reports" ADD CONSTRAINT "lab_reports_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "documents"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_membership_type_id_fkey" FOREIGN KEY ("membership_type_id") REFERENCES "membership_types"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "prescriptions" ADD CONSTRAINT "prescriptions_consultation_id_fkey" FOREIGN KEY ("consultation_id") REFERENCES "consultations"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "prescriptions" ADD CONSTRAINT "prescriptions_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "prescriptions" ADD CONSTRAINT "prescriptions_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "documents"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "pricing_rule_audits" ADD CONSTRAINT "pricing_rule_audits_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "pricing_rule_audits" ADD CONSTRAINT "pricing_rule_audits_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "wallets"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "products" ADD CONSTRAINT "products_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "product_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "provider_profile_branch_assignments" ADD CONSTRAINT "provider_profile_branch_assignments_business_fkey" FOREIGN KEY ("business_id") REFERENCES "businesses"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "provider_profile_branch_assignments" ADD CONSTRAINT "provider_profile_branch_assignments_profile_fkey" FOREIGN KEY ("provider_profile_id") REFERENCES "provider_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "provider_profiles" ADD CONSTRAINT "provider_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "purchase_items" ADD CONSTRAINT "purchase_items_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "purchase_items" ADD CONSTRAINT "purchase_items_purchase_id_fkey" FOREIGN KEY ("purchase_id") REFERENCES "purchases"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "purchases" ADD CONSTRAINT "purchases_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "appointments"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "purchases" ADD CONSTRAINT "purchases_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "purchases" ADD CONSTRAINT "purchases_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "service_providers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "reward_point_transactions" ADD CONSTRAINT "reward_point_transactions_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "reward_point_transactions" ADD CONSTRAINT "reward_point_transactions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "reward_point_transactions" ADD CONSTRAINT "reward_point_transactions_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "wallets"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "permissions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "service_providers" ADD CONSTRAINT "service_providers_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "businesses"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "shield_cards" ADD CONSTRAINT "shield_cards_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "shield_cards" ADD CONSTRAINT "shield_cards_issued_business_id_fkey" FOREIGN KEY ("issued_business_id") REFERENCES "businesses"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "users" ADD CONSTRAINT "users_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "users" ADD CONSTRAINT "users_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "wallet_transactions" ADD CONSTRAINT "wallet_transactions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "wallet_transactions" ADD CONSTRAINT "wallet_transactions_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "wallets"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "wallets" ADD CONSTRAINT "wallets_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;


