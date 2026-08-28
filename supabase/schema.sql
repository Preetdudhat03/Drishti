-- ============================================================================
-- DRISHTI AI RETINAL SCREENING PLATFORM — SUPABASE DATABASE SCHEMA
-- SIH 2026 Tele-Ophthalmology & Distributed AI Screening Database
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------------------
-- 1. PROFILES TABLE (Linked with Supabase Auth)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('Health Worker', 'Ophthalmologist / Clinician', 'Administrator', 'Auditor')),
    facility_id TEXT DEFAULT 'PHC-RAMGARH-01',
    phone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 2. SCREENINGS TABLE (Primary Clinical Intake & Session State)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.screenings (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT UNIQUE NOT NULL,
    client_request_id TEXT,
    patient_id TEXT NOT NULL,
    patient_name TEXT,
    age INT CHECK (age >= 0 AND age <= 130),
    gender TEXT CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    diabetes_duration_years INT CHECK (diabetes_duration_years >= 0),
    hba1c NUMERIC(4, 2),
    eye TEXT NOT NULL CHECK (eye IN ('OD', 'OS', 'OD (Right Eye)', 'OS (Left Eye)')),
    facility_id TEXT NOT NULL DEFAULT 'PHC-RAMGARH-01',
    status TEXT NOT NULL DEFAULT 'AWAITING_IMAGE' 
        CHECK (status IN ('AWAITING_IMAGE', 'IMAGE_RECEIVED', 'QUALITY_ASSESSMENT', 'AI_PROCESSING', 'READY_FOR_REVIEW', 'COMPLETED', 'UNGRADABLE', 'RECAPTURE_REQUIRED', 'SYNCED')),
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast queries
CREATE INDEX IF NOT EXISTS idx_screenings_patient_id ON public.screenings(patient_id);
CREATE INDEX IF NOT EXISTS idx_screenings_facility_id ON public.screenings(facility_id);
CREATE INDEX IF NOT EXISTS idx_screenings_status ON public.screenings(status);
CREATE INDEX IF NOT EXISTS idx_screenings_created_at ON public.screenings(created_at DESC);

-- ----------------------------------------------------------------------------
-- 3. QUALITY ASSESSMENTS TABLE (Safety Gate Metrics)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.quality_assessments (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT NOT NULL REFERENCES public.screenings(screening_id) ON DELETE CASCADE,
    quality_score NUMERIC(5, 4) NOT NULL CHECK (quality_score >= 0.0 AND quality_score <= 1.0),
    status TEXT NOT NULL CHECK (status IN ('GOOD', 'BORDERLINE', 'UNGRADABLE')),
    sharpness_score NUMERIC(5, 4) NOT NULL,
    illumination_score NUMERIC(5, 4) NOT NULL,
    fov_score NUMERIC(5, 4) NOT NULL,
    mean_intensity NUMERIC(5, 2),
    clahe_applied BOOLEAN DEFAULT FALSE,
    feedback_messages JSONB DEFAULT '[]'::jsonb,
    evaluated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quality_screening_id ON public.quality_assessments(screening_id);

-- ----------------------------------------------------------------------------
-- 4. AI PREDICTIONS TABLE (PyTorch ResNet-18 Results)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_predictions (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT NOT NULL REFERENCES public.screenings(screening_id) ON DELETE CASCADE,
    dr_level INT NOT NULL CHECK (dr_level >= 0 AND dr_level <= 4),
    severity_label TEXT NOT NULL,
    referable BOOLEAN NOT NULL,
    model_probability NUMERIC(5, 4) NOT NULL,
    calibrated_confidence NUMERIC(5, 4),
    class_probabilities JSONB, -- [P(L0), P(L1), P(L2), P(L3), P(L4)]
    review_priority TEXT DEFAULT 'NORMAL' CHECK (review_priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    recommendation TEXT,
    model_version TEXT DEFAULT 'EyeXpert_ResNet18_v1.0',
    provenance JSONB,
    analyzed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_predictions_screening_id ON public.ai_predictions(screening_id);
CREATE INDEX IF NOT EXISTS idx_ai_predictions_referable ON public.ai_predictions(referable);
CREATE INDEX IF NOT EXISTS idx_ai_predictions_dr_level ON public.ai_predictions(dr_level);

-- ----------------------------------------------------------------------------
-- 5. EXPLAINABILITY RESULTS TABLE (Layer4 Grad-CAM Metadata)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.explainability_results (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT NOT NULL REFERENCES public.screenings(screening_id) ON DELETE CASCADE,
    target_layer TEXT NOT NULL DEFAULT 'layer4[1].conv2',
    gradcam_url TEXT,
    overlay_url TEXT,
    original_url TEXT,
    model_attended_regions JSONB DEFAULT '[]'::jsonb,
    disclaimer TEXT,
    generated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_explainability_screening_id ON public.explainability_results(screening_id);

-- ----------------------------------------------------------------------------
-- 6. CLINICIAN REVIEWS TABLE (Human-in-the-Loop Sign-off)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.clinician_reviews (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT NOT NULL REFERENCES public.screenings(screening_id) ON DELETE CASCADE,
    reviewer_id UUID REFERENCES auth.users(id),
    clinician_name TEXT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('VALIDATE_AI', 'OVERRIDE_GRADE', 'REJECT_RECAPTURE', 'ORDER_OCT', 'CONFIRMED')),
    final_dr_level INT CHECK (final_dr_level >= 0 AND final_dr_level <= 4),
    final_referable BOOLEAN,
    clinical_notes TEXT,
    urgency TEXT DEFAULT 'Routine',
    reviewed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reviews_screening_id ON public.clinician_reviews(screening_id);

-- ----------------------------------------------------------------------------
-- 7. AUDIT EVENTS TABLE (Immutable Clinical Traceability Log)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.audit_events (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT,
    event_type TEXT NOT NULL,
    actor_id UUID,
    payload JSONB,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_screening_id ON public.audit_events(screening_id);
CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON public.audit_events(timestamp DESC);

-- ----------------------------------------------------------------------------
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ----------------------------------------------------------------------------
-- 8. ROW LEVEL SECURITY (RLS) POLICIES (IDEMPOTENT)
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.screenings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quality_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.explainability_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinician_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they already exist
DROP POLICY IF EXISTS "Allow public read screenings" ON public.screenings;
DROP POLICY IF EXISTS "Allow public insert screenings" ON public.screenings;
DROP POLICY IF EXISTS "Allow public update screenings" ON public.screenings;
DROP POLICY IF EXISTS "Allow authenticated read screenings" ON public.screenings;
DROP POLICY IF EXISTS "Allow authenticated insert screenings" ON public.screenings;
DROP POLICY IF EXISTS "Allow authenticated update screenings" ON public.screenings;

DROP POLICY IF EXISTS "Allow public read quality" ON public.quality_assessments;
DROP POLICY IF EXISTS "Allow public insert quality" ON public.quality_assessments;
DROP POLICY IF EXISTS "Allow authenticated read quality" ON public.quality_assessments;
DROP POLICY IF EXISTS "Allow authenticated insert quality" ON public.quality_assessments;

DROP POLICY IF EXISTS "Allow public read predictions" ON public.ai_predictions;
DROP POLICY IF EXISTS "Allow public insert predictions" ON public.ai_predictions;
DROP POLICY IF EXISTS "Allow authenticated read predictions" ON public.ai_predictions;
DROP POLICY IF EXISTS "Allow authenticated insert predictions" ON public.ai_predictions;

DROP POLICY IF EXISTS "Allow public read explainability" ON public.explainability_results;
DROP POLICY IF EXISTS "Allow public insert explainability" ON public.explainability_results;
DROP POLICY IF EXISTS "Allow authenticated read explainability" ON public.explainability_results;
DROP POLICY IF EXISTS "Allow authenticated insert explainability" ON public.explainability_results;

DROP POLICY IF EXISTS "Allow public read reviews" ON public.clinician_reviews;
DROP POLICY IF EXISTS "Allow public insert reviews" ON public.clinician_reviews;
DROP POLICY IF EXISTS "Allow public update reviews" ON public.clinician_reviews;
DROP POLICY IF EXISTS "Allow authenticated read reviews" ON public.clinician_reviews;
DROP POLICY IF EXISTS "Allow authenticated insert reviews" ON public.clinician_reviews;

DROP POLICY IF EXISTS "Allow public insert audit" ON public.audit_events;
DROP POLICY IF EXISTS "Allow public read audit" ON public.audit_events;
DROP POLICY IF EXISTS "Allow authenticated insert audit" ON public.audit_events;

DROP POLICY IF EXISTS "Allow public read profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow user update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated read profiles" ON public.profiles;

-- Create public & authenticated RLS policies
CREATE POLICY "Allow public read screenings" ON public.screenings
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow public insert screenings" ON public.screenings
    FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow public update screenings" ON public.screenings
    FOR UPDATE TO public USING (true);

CREATE POLICY "Allow public read quality" ON public.quality_assessments
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow public insert quality" ON public.quality_assessments
    FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow public read predictions" ON public.ai_predictions
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow public insert predictions" ON public.ai_predictions
    FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow public read explainability" ON public.explainability_results
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow public insert explainability" ON public.explainability_results
    FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow public read reviews" ON public.clinician_reviews
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow public insert reviews" ON public.clinician_reviews
    FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow public update reviews" ON public.clinician_reviews
    FOR UPDATE TO public USING (true);

CREATE POLICY "Allow public insert audit" ON public.audit_events
    FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow public read audit" ON public.audit_events
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow public read profiles" ON public.profiles
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow user update own profile" ON public.profiles
    FOR UPDATE TO public USING (true);

-- ----------------------------------------------------------------------------
-- 9. STORAGE BUCKET SETUP (IDEMPOTENT)
-- ----------------------------------------------------------------------------
-- Insert the public/private fundus storage bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('fundus-images', 'fundus-images', true)
ON CONFLICT (id) DO NOTHING;

-- Drop old storage policies before re-creating
DROP POLICY IF EXISTS "Allow public uploads to fundus-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read from fundus-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated uploads to fundus-images" ON storage.objects;

-- Storage RLS policy
CREATE POLICY "Allow public uploads to fundus-images"
ON storage.objects FOR INSERT TO public
WITH CHECK (bucket_id = 'fundus-images');

CREATE POLICY "Allow public read from fundus-images"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'fundus-images');
