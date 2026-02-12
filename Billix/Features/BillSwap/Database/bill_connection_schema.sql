-- ============================================================================
-- Bill Connection Database Schema
-- ============================================================================
-- Fresh schema for the Bill Connection feature (replaces BillSwap/Trust Ladder)
--
-- Key changes from previous schema:
-- - 3-tier reputation system: Neighbor ($25), Contributor ($150), Pillar ($500)
-- - 5-phase workflow: Request → Handshake → Execution → Proof → Reputation
-- - NO collateral/trust point locking
-- - NO account numbers (Guest Pay links only)
-- - Reputation-based sanctions instead of financial penalties
--
-- Run this on a fresh database or after dropping all swap-related tables
-- ============================================================================

-- ============================================================================
-- 1. PROFILES TABLE UPDATES
-- ============================================================================
-- Add reputation-related columns to the existing profiles table

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS reputation_score INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS reputation_tier INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS successful_connections INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS monthly_connection_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_deactivated BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_permanently_banned BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_gov_id_verified BOOLEAN DEFAULT FALSE;

-- Index for reputation queries
CREATE INDEX IF NOT EXISTS idx_profiles_reputation_tier ON profiles(reputation_tier);
CREATE INDEX IF NOT EXISTS idx_profiles_deactivated ON profiles(is_deactivated) WHERE is_deactivated = true;

-- ============================================================================
-- 2. SUPPORT BILLS TABLE
-- ============================================================================
-- Bills posted to the Community Board for support
-- NOTE: No account_number field - Guest Pay links are the PRIMARY payment method

CREATE TABLE IF NOT EXISTS support_bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Bill Details
    provider TEXT,
    category TEXT NOT NULL DEFAULT 'other',
    amount DECIMAL(10, 2) NOT NULL,
    due_date TIMESTAMPTZ,
    statement_date TIMESTAMPTZ,

    -- Guest Pay (PRIMARY payment method)
    guest_pay_link TEXT,

    -- Bill Document
    document_url TEXT,

    -- Status
    status TEXT NOT NULL DEFAULT 'draft',  -- draft, posted, matched, paid, expired

    -- Tokens
    tokens_charged INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    posted_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_support_bills_user ON support_bills(user_id);
CREATE INDEX IF NOT EXISTS idx_support_bills_status ON support_bills(status);
CREATE INDEX IF NOT EXISTS idx_support_bills_posted ON support_bills(posted_at) WHERE status = 'posted';

-- RLS Policies
ALTER TABLE support_bills ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view posted bills"
    ON support_bills FOR SELECT
    USING (status = 'posted' OR user_id = auth.uid());

CREATE POLICY "Users can create own bills"
    ON support_bills FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own bills"
    ON support_bills FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete own draft bills"
    ON support_bills FOR DELETE
    USING (user_id = auth.uid() AND status = 'draft');

-- ============================================================================
-- 3. CONNECTIONS TABLE
-- ============================================================================
-- Main connection record with 5-phase workflow

CREATE TABLE IF NOT EXISTS connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Participants
    initiator_id UUID NOT NULL REFERENCES auth.users(id),
    supporter_id UUID REFERENCES auth.users(id),

    -- Bill Reference
    bill_id UUID NOT NULL REFERENCES support_bills(id) ON DELETE CASCADE,

    -- Connection Type
    connection_type TEXT NOT NULL DEFAULT 'one_way',  -- mutual, one_way

    -- Phase & Status
    phase INTEGER NOT NULL DEFAULT 1,  -- 1-5
    status TEXT NOT NULL DEFAULT 'requested',
    -- Statuses: requested, handshake, executing, proofing, completed, cancelled, disputed

    -- Proof of Support
    proof_url TEXT,
    proof_verified_at TIMESTAMPTZ,

    -- Reputation
    reputation_awarded BOOLEAN DEFAULT FALSE,

    -- Cancellation
    cancelled_at TIMESTAMPTZ,
    cancel_reason TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    matched_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_connections_initiator ON connections(initiator_id);
CREATE INDEX IF NOT EXISTS idx_connections_supporter ON connections(supporter_id);
CREATE INDEX IF NOT EXISTS idx_connections_bill ON connections(bill_id);
CREATE INDEX IF NOT EXISTS idx_connections_status ON connections(status);
CREATE INDEX IF NOT EXISTS idx_connections_active ON connections(status)
    WHERE status IN ('requested', 'handshake', 'executing', 'proofing');

-- RLS Policies
ALTER TABLE connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own connections"
    ON connections FOR SELECT
    USING (initiator_id = auth.uid() OR supporter_id = auth.uid());

CREATE POLICY "Users can view requested connections"
    ON connections FOR SELECT
    USING (status = 'requested');

CREATE POLICY "Initiators can create connections"
    ON connections FOR INSERT
    WITH CHECK (initiator_id = auth.uid());

CREATE POLICY "Participants can update connections"
    ON connections FOR UPDATE
    USING (initiator_id = auth.uid() OR supporter_id = auth.uid());

-- ============================================================================
-- 4. CONNECTION TERMS TABLE
-- ============================================================================
-- Simplified terms - one-round acceptance, no negotiation

CREATE TABLE IF NOT EXISTS connection_terms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    connection_id UUID NOT NULL REFERENCES connections(id) ON DELETE CASCADE,
    proposer_id UUID NOT NULL REFERENCES auth.users(id),

    -- Terms
    bill_amount DECIMAL(10, 2) NOT NULL,
    deadline TIMESTAMPTZ NOT NULL,
    proof_required TEXT NOT NULL DEFAULT 'screenshot',

    -- Status
    status TEXT NOT NULL DEFAULT 'proposed',  -- proposed, accepted, rejected, expired

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL  -- 24 hours to respond
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_connection_terms_connection ON connection_terms(connection_id);
CREATE INDEX IF NOT EXISTS idx_connection_terms_status ON connection_terms(status);
CREATE INDEX IF NOT EXISTS idx_connection_terms_expires ON connection_terms(expires_at)
    WHERE status = 'proposed';

-- RLS Policies
ALTER TABLE connection_terms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Connection participants can view terms"
    ON connection_terms FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM connections c
            WHERE c.id = connection_id
            AND (c.initiator_id = auth.uid() OR c.supporter_id = auth.uid())
        )
    );

CREATE POLICY "Connection participants can create terms"
    ON connection_terms FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM connections c
            WHERE c.id = connection_id
            AND (c.initiator_id = auth.uid() OR c.supporter_id = auth.uid())
        )
    );

CREATE POLICY "Connection participants can update terms"
    ON connection_terms FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM connections c
            WHERE c.id = connection_id
            AND (c.initiator_id = auth.uid() OR c.supporter_id = auth.uid())
        )
    );

-- ============================================================================
-- 5. CONNECTION EVENTS TABLE
-- ============================================================================
-- Audit log for all connection events

CREATE TABLE IF NOT EXISTS connection_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    connection_id UUID NOT NULL REFERENCES connections(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES auth.users(id),

    -- Event Details
    event_type TEXT NOT NULL,
    payload JSONB,

    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_connection_events_connection ON connection_events(connection_id);
CREATE INDEX IF NOT EXISTS idx_connection_events_type ON connection_events(event_type);
CREATE INDEX IF NOT EXISTS idx_connection_events_created ON connection_events(created_at);

-- RLS Policies
ALTER TABLE connection_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Connection participants can view events"
    ON connection_events FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM connections c
            WHERE c.id = connection_id
            AND (c.initiator_id = auth.uid() OR c.supporter_id = auth.uid())
        )
    );

CREATE POLICY "System can insert events"
    ON connection_events FOR INSERT
    WITH CHECK (true);  -- Controlled via service role

-- ============================================================================
-- 6. REPUTATION SANCTIONS TABLE
-- ============================================================================
-- Log of reputation sanctions for audit and appeals

CREATE TABLE IF NOT EXISTS reputation_sanctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),

    -- Sanction Details
    reason TEXT NOT NULL,  -- fake_receipt, no_payment, harassment, abandoned_connection, other
    penalty INTEGER NOT NULL,
    connection_id UUID REFERENCES connections(id),
    details TEXT,

    -- Outcome
    was_deactivated BOOLEAN DEFAULT FALSE,
    was_banned BOOLEAN DEFAULT FALSE,

    -- Appeal
    appeal_status TEXT,  -- null, pending, approved, denied
    appeal_notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    appealed_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_reputation_sanctions_user ON reputation_sanctions(user_id);
CREATE INDEX IF NOT EXISTS idx_reputation_sanctions_connection ON reputation_sanctions(connection_id);
CREATE INDEX IF NOT EXISTS idx_reputation_sanctions_created ON reputation_sanctions(created_at);

-- RLS Policies
ALTER TABLE reputation_sanctions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own sanctions"
    ON reputation_sanctions FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "System can insert sanctions"
    ON reputation_sanctions FOR INSERT
    WITH CHECK (true);  -- Controlled via service role

-- ============================================================================
-- 7. STORAGE BUCKET FOR PROOFS
-- ============================================================================
-- Create a storage bucket for connection proof images

INSERT INTO storage.buckets (id, name, public)
VALUES ('connection-proofs', 'connection-proofs', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies
CREATE POLICY "Anyone can view proofs"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'connection-proofs');

CREATE POLICY "Authenticated users can upload proofs"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'connection-proofs'
        AND auth.role() = 'authenticated'
    );

-- ============================================================================
-- 8. FUNCTIONS
-- ============================================================================

-- Function to reset monthly connection counts (run via cron)
CREATE OR REPLACE FUNCTION reset_monthly_connection_counts()
RETURNS void AS $$
BEGIN
    UPDATE profiles SET monthly_connection_count = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to expire old terms
CREATE OR REPLACE FUNCTION expire_pending_terms()
RETURNS void AS $$
BEGIN
    UPDATE connection_terms
    SET status = 'expired'
    WHERE status = 'proposed'
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate tier from verification status
CREATE OR REPLACE FUNCTION calculate_reputation_tier(
    is_prime BOOLEAN,
    is_gov_verified BOOLEAN,
    successful_connections INTEGER
)
RETURNS INTEGER AS $$
BEGIN
    -- Tier 3 (Pillar): 15+ successful connections as Contributor
    IF is_prime AND is_gov_verified AND successful_connections >= 15 THEN
        RETURN 3;
    -- Tier 2 (Contributor): Verified Prime + Gov ID
    ELSIF is_prime AND is_gov_verified THEN
        RETURN 2;
    -- Tier 1 (Neighbor): Default
    ELSE
        RETURN 1;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- 9. TRIGGERS
-- ============================================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER support_bills_updated_at
    BEFORE UPDATE ON support_bills
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER connections_updated_at
    BEFORE UPDATE ON connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- 10. TIER LIMITS REFERENCE
-- ============================================================================
-- This is for documentation - actual limits enforced in application code
--
-- Tier 1 (Neighbor):
--   - Max amount: $25
--   - Velocity limit: 1 connection per month
--   - Requirements: Basic account
--
-- Tier 2 (Contributor):
--   - Max amount: $150
--   - Velocity limit: Unlimited
--   - Requirements: Verified Prime + Government ID
--
-- Tier 3 (Pillar):
--   - Max amount: $500
--   - Velocity limit: Unlimited
--   - Requirements: 15 successful connections as Contributor
--
-- ============================================================================

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================
--
-- This is a FRESH schema. If migrating from the old BillSwap system:
-- 1. Export any data you want to preserve
-- 2. Drop old tables: swaps, swap_bills, swap_deals, collateral_locks, trust_points
-- 3. Run this schema
-- 4. Import preserved data with appropriate transformations
--
-- The user has specified "fresh database start" so no migration is needed.
-- ============================================================================
