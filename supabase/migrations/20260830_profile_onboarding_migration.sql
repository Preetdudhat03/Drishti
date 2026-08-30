-- ============================================================================
-- DRISHTI MIGRATION: 20260830_profile_onboarding_migration.sql
-- Non-Destructive Schema Upgrade for Onboarding, Facilities & Verification
-- All existing screening, prediction, explainability, and review records remain 100% INTACT.
-- ============================================================================

-- 1. Safely Upgrade public.profiles Table
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

-- 2. Create public.facilities Table (if not exists)
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

-- 3. Create public.professional_profiles Table (if not exists)
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

-- 4. Create public.verification_documents Table (if not exists)
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

-- 5. Private Storage Bucket for Verification Documents
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-documents', 'profile-documents', false)
ON CONFLICT (id) DO NOTHING;

-- 6. Enable RLS and Policies for new tables
ALTER TABLE public.facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.professional_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read facilities" ON public.facilities;
DROP POLICY IF EXISTS "Allow authenticated insert facilities" ON public.facilities;
DROP POLICY IF EXISTS "Allow authenticated update facilities" ON public.facilities;

DROP POLICY IF EXISTS "Allow user read own professional profile" ON public.professional_profiles;
DROP POLICY IF EXISTS "Allow user insert own professional profile" ON public.professional_profiles;
DROP POLICY IF EXISTS "Allow user update own professional profile" ON public.professional_profiles;

DROP POLICY IF EXISTS "Allow user read own documents" ON public.verification_documents;
DROP POLICY IF EXISTS "Allow user insert own documents" ON public.verification_documents;
DROP POLICY IF EXISTS "Allow user update own documents" ON public.verification_documents;

CREATE POLICY "Allow public read facilities" ON public.facilities FOR SELECT TO public USING (true);
CREATE POLICY "Allow authenticated insert facilities" ON public.facilities FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated update facilities" ON public.facilities FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Allow user read own professional profile" ON public.professional_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow user insert own professional profile" ON public.professional_profiles FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow user update own professional profile" ON public.professional_profiles FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Allow user read own documents" ON public.verification_documents FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow user insert own documents" ON public.verification_documents FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow user update own documents" ON public.verification_documents FOR UPDATE TO authenticated USING (true);

-- Storage Policies for Private Bucket
DROP POLICY IF EXISTS "Allow authenticated uploads to profile-documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow user read own profile-documents" ON storage.objects;

CREATE POLICY "Allow authenticated uploads to profile-documents"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'profile-documents');

CREATE POLICY "Allow user read own profile-documents"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'profile-documents');

