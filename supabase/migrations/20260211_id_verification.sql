-- Migration: Manual ID Verification System
-- Creates storage bucket, submissions table, RLS policies, and auto-update trigger

-- =====================================================
-- 1. CREATE PRIVATE STORAGE BUCKET FOR ID DOCUMENTS
-- =====================================================

-- Create private bucket for ID verification documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('id-verification', 'id-verification', false)
ON CONFLICT (id) DO NOTHING;

-- Only authenticated users can upload their own docs (into their user folder)
CREATE POLICY "Users can upload their ID docs"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'id-verification'
    AND auth.role() = 'authenticated'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Only the user can view their own docs (stored in user_id folder)
CREATE POLICY "Users can view their own ID docs"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'id-verification'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own docs if needed
CREATE POLICY "Users can delete their own ID docs"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'id-verification'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- 2. CREATE ID VERIFICATION SUBMISSIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS id_verification_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    selfie_url TEXT NOT NULL,
    id_front_url TEXT NOT NULL,
    id_back_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    rejection_reason TEXT,
    reviewed_by UUID REFERENCES auth.users(id),
    submitted_at TIMESTAMPTZ DEFAULT now(),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),

    -- Index for faster queries
    CONSTRAINT unique_pending_per_user UNIQUE (user_id, status)
        WHERE status = 'pending'  -- Only allow one pending submission per user
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_id_verification_user_id ON id_verification_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_id_verification_status ON id_verification_submissions(status);

-- =====================================================
-- 3. RLS POLICIES FOR SUBMISSIONS TABLE
-- =====================================================

ALTER TABLE id_verification_submissions ENABLE ROW LEVEL SECURITY;

-- Users can view their own submissions
CREATE POLICY "Users can view own submissions"
ON id_verification_submissions FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own submissions
CREATE POLICY "Users can insert own submissions"
ON id_verification_submissions FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 4. TRIGGER TO AUTO-UPDATE PROFILE ON APPROVAL
-- =====================================================

-- Function to sync verification status to profiles table
CREATE OR REPLACE FUNCTION sync_id_verification_status()
RETURNS TRIGGER AS $$
BEGIN
    -- When status changes to 'approved', mark profile as verified
    IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
        UPDATE profiles
        SET
            is_gov_id_verified = true,
            id_verified = true,
            id_verified_at = now()
        WHERE user_id = NEW.user_id;
    END IF;

    -- When status changes to 'rejected', ensure profile is not verified
    IF NEW.status = 'rejected' THEN
        UPDATE profiles
        SET
            is_gov_id_verified = false,
            id_verified = false
        WHERE user_id = NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for approval
CREATE TRIGGER on_verification_status_change
AFTER INSERT OR UPDATE OF status ON id_verification_submissions
FOR EACH ROW
EXECUTE FUNCTION sync_id_verification_status();

-- =====================================================
-- 5. WEBHOOK SETUP (Manual Step Required)
-- =====================================================
-- To enable email notifications when new submissions arrive:
--
-- 1. Deploy the Edge Function:
--    supabase functions deploy notify-id-submission
--
-- 2. In Supabase Dashboard, go to Database > Webhooks
--
-- 3. Create a new webhook with these settings:
--    - Name: notify-id-submission
--    - Table: id_verification_submissions
--    - Events: INSERT
--    - Type: Supabase Edge Function
--    - Function: notify-id-submission
--
-- 4. Ensure RESEND_API_KEY is set in your Edge Function secrets:
--    supabase secrets set RESEND_API_KEY=your_resend_api_key

-- =====================================================
-- 6. HELPER FUNCTION TO GET VERIFICATION STATUS
-- =====================================================

-- Function to get user's current verification status
CREATE OR REPLACE FUNCTION get_verification_status(p_user_id UUID)
RETURNS TABLE (
    is_verified BOOLEAN,
    submission_status TEXT,
    rejection_reason TEXT,
    submitted_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(p.is_gov_id_verified, false) as is_verified,
        s.status as submission_status,
        s.rejection_reason,
        s.submitted_at
    FROM profiles p
    LEFT JOIN (
        SELECT * FROM id_verification_submissions
        WHERE id_verification_submissions.user_id = p_user_id
        ORDER BY created_at DESC
        LIMIT 1
    ) s ON true
    WHERE p.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
