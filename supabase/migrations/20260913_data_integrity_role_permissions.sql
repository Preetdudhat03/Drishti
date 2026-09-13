-- ============================================================================
-- DRISHTI MIGRATION: 20260913_data_integrity_role_permissions.sql
-- Non-Destructive Schema Upgrade for Authoritative SHA-256, Inference Provenance,
-- Separate Workflow Status vs. Clinical Decision, and Role Separation (RBAC)
-- ============================================================================

-- 1. Safely add Data Integrity & Inference Provenance Columns to public.screenings
DO $$ 
BEGIN
    -- Server and Client SHA-256 hashes
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'screenings' AND column_name = 'server_sha256') THEN
        ALTER TABLE public.screenings ADD COLUMN server_sha256 TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'screenings' AND column_name = 'client_sha256') THEN
        ALTER TABLE public.screenings ADD COLUMN client_sha256 TEXT;
    END IF;

    -- Image dimensions
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'screenings' AND column_name = 'image_dimensions') THEN
        ALTER TABLE public.screenings ADD COLUMN image_dimensions JSONB DEFAULT '[512, 512]'::jsonb;
    END IF;

    -- Clinical decision outcome (distinct from workflow status)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'screenings' AND column_name = 'clinical_decision') THEN
        ALTER TABLE public.screenings ADD COLUMN clinical_decision TEXT DEFAULT 'PENDING';
    END IF;

    -- Reviewer assignment and claiming for concurrency protection
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'screenings' AND column_name = 'assigned_reviewer_id') THEN
        ALTER TABLE public.screenings ADD COLUMN assigned_reviewer_id TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'screenings' AND column_name = 'claimed_at') THEN
        ALTER TABLE public.screenings ADD COLUMN claimed_at TIMESTAMPTZ;
    END IF;
END $$;

-- Drop outdated status check constraint so newer workflow statuses (AI_COMPLETED, REVIEW_PENDING, OPHTHALMOLOGIST_REVIEW) are accepted
ALTER TABLE public.screenings DROP CONSTRAINT IF EXISTS screenings_status_check;

-- 2. Safely add Inference Metadata to public.ai_predictions
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_predictions' AND column_name = 'inference_id') THEN
        ALTER TABLE public.ai_predictions ADD COLUMN inference_id TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_predictions' AND column_name = 'server_sha256') THEN
        ALTER TABLE public.ai_predictions ADD COLUMN server_sha256 TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_predictions' AND column_name = 'crop_box') THEN
        ALTER TABLE public.ai_predictions ADD COLUMN crop_box JSONB;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_predictions' AND column_name = 'preprocessing_version') THEN
        ALTER TABLE public.ai_predictions ADD COLUMN preprocessing_version TEXT DEFAULT 'fundus-v1';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_predictions' AND column_name = 'raw_logits') THEN
        ALTER TABLE public.ai_predictions ADD COLUMN raw_logits JSONB;
    END IF;
END $$;

-- 3. Indexes for fast queue and concurrency lookups
CREATE INDEX IF NOT EXISTS idx_screenings_server_sha256 ON public.screenings(server_sha256);
CREATE INDEX IF NOT EXISTS idx_screenings_assigned_reviewer ON public.screenings(assigned_reviewer_id);
CREATE INDEX IF NOT EXISTS idx_screenings_clinical_decision ON public.screenings(clinical_decision);

-- 4. Role-Based RLS Policies Enforcement
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Screenings: Health Workers can insert screenings. Ophthalmologists cannot create screenings.
DROP POLICY IF EXISTS "Enforce role create screenings" ON public.screenings;
CREATE POLICY "Enforce role create screenings" ON public.screenings 
FOR INSERT TO authenticated 
WITH CHECK (
    public.get_current_user_role() IN ('Health Worker', 'HEALTH_WORKER', 'Administrator', 'ADMIN')
    OR public.get_current_user_role() IS NULL
);

-- Clinician Reviews: Only Ophthalmologists & Admins can insert/update clinical decisions
DROP POLICY IF EXISTS "Enforce role create reviews" ON public.clinician_reviews;
CREATE POLICY "Enforce role create reviews" ON public.clinician_reviews 
FOR INSERT TO authenticated 
WITH CHECK (
    public.get_current_user_role() IN ('Ophthalmologist / Clinician', 'OPHTHALMOLOGIST', 'Administrator', 'ADMIN')
    OR public.get_current_user_role() IS NULL
);
