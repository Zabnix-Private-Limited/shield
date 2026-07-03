# SHIELD Phase 0 Database Inventory

**Date:** 2026-07-03  
**Phase:** 0 - Discovery and Inventory  
**Primary sources:** `current_schema.md`, `backend/prisma/schema.prisma`

## Baseline Totals

- Tables declared in `current_schema.md`: `52`
- Index declarations discovered: `171`
- Foreign-key `ALTER TABLE` declarations discovered: `66`
- Live schema truth source: `current_schema.md`
- Secondary implementation model: `backend/prisma/schema.prisma`

## Domain Groups

### Identity, Access, and Audit

- `users`
- `roles`
- `permissions`
- `role_permissions`
- `auth_devices`
- `auth_sessions`
- `login_history`
- `audit_logs`
- `device_push_tokens`

### Customer, Membership, and Card

- `customers`
- `customer_contacts`
- `customer_status_history`
- `memberships`
- `membership_types`
- `shield_cards`

### Wallet, Pricing, Credit, and Referral

- `wallets`
- `wallet_transactions`
- `cash_wallet_transactions`
- `reward_point_transactions`
- `benefit_ledger_transactions`
- `pricing_rule_audits`
- `service_benefit_rules`
- `reward_point_rules`
- `reward_redemption_rules`
- `credit_accounts`
- `credit_transactions`
- `referral_reward_events`
- `commercial_settings`

### Provider, Business, and Operational Entities

- `businesses`
- `departments`
- `service_providers`
- `provider_profiles`
- `provider_profile_branch_assignments`
- `agent_preferences`
- `agent_branch_assignments`

### Clinical, Appointment, and Purchase Flow

- `appointments`
- `consultations`
- `prescriptions`
- `lab_reports`
- `dental_records`
- `purchases`
- `purchase_items`
- `products`
- `product_categories`

### Document Intelligence and CRM

- `documents`
- `document_classifications`
- `document_extractions`
- `document_processing_logs`
- `crm_activities`
- `crm_tasks`
- `complaints`
- `notifications`

## Schema-Level Findings

- The schema already reflects a serious ERP domain surface with distinct identity, membership, wallet, credit, referral, provider, document-intelligence, CRM, and reporting foundations.
- SHIELD’s ledger rules are materially present in the schema: `wallet_transactions.sub_ledger_type`, dedicated reward and benefit ledgers, and pricing audit tables exist as separate structures.
- `current_schema.md` and `schema.prisma` must be reconciled carefully in Phase 9 rather than assuming either is fully sufficient on its own.
- The schema is broad enough that Phase 9 should inventory table-to-module ownership and nullable/constraint quality by domain, not only table existence.
