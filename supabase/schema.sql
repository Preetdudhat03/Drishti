-- ============================================================================
-- DRISHTI AI RETINAL SCREENING PLATFORM — SUPABASE DATABASE SCHEMA
-- SIH 2026 Tele-Ophthalmology & Distributed AI Screening Database
-- Production-Ready, Non-Destructive Schema with RBAC, Facilities & Document Verification
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. PROFILES TABLE (Linked with Supabase Auth & Role Identity)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    full_name TEXT,
    role TEXT NOT NULL CHECK (role IN ('Health Worker', 'Ophthalmologist / Clinician', 'Administrator', 'Auditor', 'HEALTH_WORKER', 'OPHTHALMOLOGIST', 'ADMIN')),
    organization TEXT,
    facility_id TEXT DEFAULT 'PHC-RAMGARH-01',
    professional_id TEXT,
    phone TEXT,
    avatar_url TEXT,
    district TEXT DEFAULT 'Ramgarh',
    state TEXT DEFAULT 'Jharkhand',
    address TEXT DEFAULT '',
    pin_code TEXT DEFAULT '829122',
    gender TEXT DEFAULT 'Not Specified',
    preferred_language TEXT DEFAULT 'English / Hindi',
    profile_completion INT DEFAULT 80,
    verification_status TEXT DEFAULT 'UNDER_REVIEW' CHECK (verification_status IN ('PENDING', 'UNDER_REVIEW', 'VERIFIED', 'REQUIRES_ACTION', 'REJECTED')),
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safely add any new columns to existing profiles table without modifying existing data
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'full_name') THEN
        ALTER TABLE public.profiles ADD COLUMN full_name TEXT;
        UPDATE public.profiles SET full_name = name WHERE full_name IS NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'organization') THEN
        ALTER TABLE public.profiles ADD COLUMN organization TEXT;
        UPDATE public.profiles SET organization = facility_id WHERE organization IS NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'professional_id') THEN
        ALTER TABLE public.profiles ADD COLUMN professional_id TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'avatar_url') THEN
        ALTER TABLE public.profiles ADD COLUMN avatar_url TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'district') THEN
        ALTER TABLE public.profiles ADD COLUMN district TEXT DEFAULT 'Ramgarh';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'state') THEN
        ALTER TABLE public.profiles ADD COLUMN state TEXT DEFAULT 'Jharkhand';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'address') THEN
        ALTER TABLE public.profiles ADD COLUMN address TEXT DEFAULT '';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'pin_code') THEN
        ALTER TABLE public.profiles ADD COLUMN pin_code TEXT DEFAULT '829122';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'gender') THEN
        ALTER TABLE public.profiles ADD COLUMN gender TEXT DEFAULT 'Not Specified';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'preferred_language') THEN
        ALTER TABLE public.profiles ADD COLUMN preferred_language TEXT DEFAULT 'English / Hindi';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'profile_completion') THEN
        ALTER TABLE public.profiles ADD COLUMN profile_completion INT DEFAULT 80;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'verification_status') THEN
        ALTER TABLE public.profiles ADD COLUMN verification_status TEXT DEFAULT 'UNDER_REVIEW';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_active') THEN
        ALTER TABLE public.profiles ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'last_login_at') THEN
        ALTER TABLE public.profiles ADD COLUMN last_login_at TIMESTAMPTZ;
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 2. FACILITIES TABLE (PHC / CHC / District Hospital Profiles)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.facilities (
    id BIGSERIAL PRIMARY KEY,
    facility_name TEXT NOT NULL,
    facility_type TEXT NOT NULL DEFAULT 'Primary Health Centre (PHC)',
    facility_identifier TEXT UNIQUE NOT NULL,
    address TEXT NOT NULL,
    village_town TEXT,
    district TEXT NOT NULL,
    state TEXT NOT NULL,
    pin_code TEXT NOT NULL,
    contact_number TEXT,
    official_email TEXT,
    number_of_screening_staff INT DEFAULT 1,
    camera_available BOOLEAN DEFAULT TRUE,
    camera_manufacturer TEXT DEFAULT 'Remidio / Forus Health',
    camera_model TEXT DEFAULT 'FOP NM-01 Retinal Camera',
    connectivity_type TEXT DEFAULT 'ONLINE',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_facilities_identifier ON public.facilities(facility_identifier);

-- ----------------------------------------------------------------------------
-- 3. PROFESSIONAL PROFILES TABLE (Ophthalmologists & Specialists)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.professional_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    qualification TEXT NOT NULL DEFAULT 'MS / DNB (Ophthalmology)',
    specialization TEXT NOT NULL DEFAULT 'Vitreo-Retinal Surgeon',
    registration_number TEXT NOT NULL,
    registration_authority TEXT NOT NULL DEFAULT 'National Medical Commission (NMC)',
    years_experience INT DEFAULT 5,
    facility_name TEXT NOT NULL DEFAULT 'District Eye Centre',
    facility_id TEXT,
    professional_phone TEXT,
    professional_email TEXT,
    consultation_location TEXT DEFAULT 'Main OPD, Eye Hospital',
    district TEXT NOT NULL DEFAULT 'Ranchi',
    state TEXT NOT NULL DEFAULT 'Jharkhand',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_prof_user UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_prof_user_id ON public.professional_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_prof_reg_no ON public.professional_profiles(registration_number);

-- ----------------------------------------------------------------------------
-- 4. VERIFICATION DOCUMENTS TABLE (Private Storage References & Review)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.verification_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    facility_id TEXT,
    document_type TEXT NOT NULL,
    document_title TEXT NOT NULL,
    file_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    mime_type TEXT DEFAULT 'application/pdf',
    file_size_bytes BIGINT DEFAULT 0,
    verification_status TEXT NOT NULL DEFAULT 'UNDER_REVIEW' 
        CHECK (verification_status IN ('NOT_UPLOADED', 'UPLOADED', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED')),
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT,
    is_mandatory BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_docs_user_id ON public.verification_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_docs_verification_status ON public.verification_documents(verification_status);

-- ----------------------------------------------------------------------------
-- 5. SCREENINGS TABLE (Primary Clinical Intake & Session State)
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
-- 6. QUALITY ASSESSMENTS TABLE (Safety Gate Metrics)
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
-- 7. AI PREDICTIONS TABLE (PyTorch ResNet-18 Results)
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
-- 8. EXPLAINABILITY RESULTS TABLE (Layer4 Grad-CAM Metadata)
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
-- 9. CLINICIAN REVIEWS TABLE (Human-in-the-Loop Sign-off)
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
-- 10. AUDIT EVENTS TABLE (Immutable Clinical Traceability Log)
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
-- 11. ROW LEVEL SECURITY (RLS) POLICIES (IDEMPOTENT)
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.professional_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_documents ENABLE ROW LEVEL SECURITY;
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
DROP POLICY IF EXISTS "Allow public delete screenings" ON public.screenings;

DROP POLICY IF EXISTS "Allow public read quality" ON public.quality_assessments;
DROP POLICY IF EXISTS "Allow public insert quality" ON public.quality_assessments;

DROP POLICY IF EXISTS "Allow public read predictions" ON public.ai_predictions;
DROP POLICY IF EXISTS "Allow public insert predictions" ON public.ai_predictions;

DROP POLICY IF EXISTS "Allow public read explainability" ON public.explainability_results;
DROP POLICY IF EXISTS "Allow public insert explainability" ON public.explainability_results;

DROP POLICY IF EXISTS "Allow public read reviews" ON public.clinician_reviews;
DROP POLICY IF EXISTS "Allow public insert reviews" ON public.clinician_reviews;
DROP POLICY IF EXISTS "Allow public update reviews" ON public.clinician_reviews;

DROP POLICY IF EXISTS "Allow public insert audit" ON public.audit_events;
DROP POLICY IF EXISTS "Allow public read audit" ON public.audit_events;

DROP POLICY IF EXISTS "Allow public read profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow user update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow user insert own profile" ON public.profiles;

DROP POLICY IF EXISTS "Allow public read facilities" ON public.facilities;
DROP POLICY IF EXISTS "Allow authenticated insert facilities" ON public.facilities;
DROP POLICY IF EXISTS "Allow authenticated update facilities" ON public.facilities;

DROP POLICY IF EXISTS "Allow user read own professional profile" ON public.professional_profiles;
DROP POLICY IF EXISTS "Allow user insert own professional profile" ON public.professional_profiles;
DROP POLICY IF EXISTS "Allow user update own professional profile" ON public.professional_profiles;

DROP POLICY IF EXISTS "Allow user read own documents" ON public.verification_documents;
DROP POLICY IF EXISTS "Allow user insert own documents" ON public.verification_documents;
DROP POLICY IF EXISTS "Allow user update own documents" ON public.verification_documents;

-- Re-create policies
CREATE POLICY "Allow public read screenings" ON public.screenings FOR SELECT TO public USING (true);
CREATE POLICY "Allow public insert screenings" ON public.screenings FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow public update screenings" ON public.screenings FOR UPDATE TO public USING (true);
CREATE POLICY "Allow public delete screenings" ON public.screenings FOR DELETE TO public USING (true);

CREATE POLICY "Allow public read quality" ON public.quality_assessments FOR SELECT TO public USING (true);
CREATE POLICY "Allow public insert quality" ON public.quality_assessments FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow public read predictions" ON public.ai_predictions FOR SELECT TO public USING (true);
CREATE POLICY "Allow public insert predictions" ON public.ai_predictions FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow public read explainability" ON public.explainability_results FOR SELECT TO public USING (true);
CREATE POLICY "Allow public insert explainability" ON public.explainability_results FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow public read reviews" ON public.clinician_reviews FOR SELECT TO public USING (true);
CREATE POLICY "Allow public insert reviews" ON public.clinician_reviews FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow public update reviews" ON public.clinician_reviews FOR UPDATE TO public USING (true);

CREATE POLICY "Allow public insert audit" ON public.audit_events FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow public read audit" ON public.audit_events FOR SELECT TO public USING (true);

CREATE POLICY "Allow public read profiles" ON public.profiles FOR SELECT TO public USING (true);
CREATE POLICY "Allow user insert own profile" ON public.profiles FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow user update own profile" ON public.profiles FOR UPDATE TO public USING (true);

CREATE POLICY "Allow public read facilities" ON public.facilities FOR SELECT TO public USING (true);
CREATE POLICY "Allow authenticated insert facilities" ON public.facilities FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated update facilities" ON public.facilities FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Allow user read own professional profile" ON public.professional_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow user insert own professional profile" ON public.professional_profiles FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow user update own professional profile" ON public.professional_profiles FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Allow user read own documents" ON public.verification_documents FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow user insert own documents" ON public.verification_documents FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow user update own documents" ON public.verification_documents FOR UPDATE TO authenticated USING (true);

-- ----------------------------------------------------------------------------
-- 12. STORAGE BUCKETS SETUP (IDEMPOTENT)
-- ----------------------------------------------------------------------------
-- Fundus Images Bucket (Public / CDN)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('fundus-images', 'fundus-images', true)
ON CONFLICT (id) DO NOTHING;

-- Verification Documents Bucket (Private & Confidential)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-documents', 'profile-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies
DROP POLICY IF EXISTS "Allow public uploads to fundus-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read from fundus-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated uploads to profile-documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow user read own profile-documents" ON storage.objects;

CREATE POLICY "Allow public uploads to fundus-images"
ON storage.objects FOR INSERT TO public
WITH CHECK (bucket_id = 'fundus-images');

CREATE POLICY "Allow public read from fundus-images"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'fundus-images');

CREATE POLICY "Allow authenticated uploads to profile-documents"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'profile-documents');

CREATE POLICY "Allow user read own profile-documents"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'profile-documents');

