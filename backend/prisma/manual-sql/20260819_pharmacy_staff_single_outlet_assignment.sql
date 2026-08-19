-- DATABASE_OWNER_ACTION_REQUIRED: YES
-- Safe Addition of Foreign Key Constraint: users.branch_business_id -> businesses.id

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_users_branch_business'
          AND table_name = 'users'
    ) THEN
        ALTER TABLE "users"
        ADD CONSTRAINT "fk_users_branch_business"
        FOREIGN KEY ("branch_business_id")
        REFERENCES "businesses" ("id")
        ON DELETE SET NULL
        ON UPDATE CASCADE;
    END IF;
END $$;
