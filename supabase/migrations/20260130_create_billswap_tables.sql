-- BillSwap Database Schema
-- Creates tables for the bill swap marketplace feature

-- ============================================
-- SWAP BILLS TABLE
-- User's bills available for swapping
-- ============================================
CREATE TABLE IF NOT EXISTS swap_bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    due_date TIMESTAMPTZ,
    provider_name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('electric', 'gas', 'water', 'internet', 'phone', 'cable', 'trash', 'other')),
    zip_code TEXT,
    status TEXT DEFAULT 'unmatched' CHECK (status IN ('unmatched', 'matched', 'paid')),
    image_url TEXT,
    account_number TEXT, -- Hidden until handshake commitment
    guest_pay_link TEXT,
    -- OCR verification fields
    bill_analysis JSONB, -- Full OCR result from BillUploadService
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for matching queries
CREATE INDEX idx_swap_bills_matching ON swap_bills(status, amount, due_date) WHERE status = 'unmatched';
CREATE INDEX idx_swap_bills_user ON swap_bills(user_id);

-- ============================================
-- SWAPS TABLE
-- Active swap transactions between two users
-- ============================================
CREATE TABLE IF NOT EXISTS swaps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_a_id UUID NOT NULL REFERENCES swap_bills(id) ON DELETE CASCADE,
    bill_b_id UUID NOT NULL REFERENCES swap_bills(id) ON DELETE CASCADE,
    user_a_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_b_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'expired', 'completed', 'dispute')),
    -- Handshake commitment (both must commit to activate)
    user_a_paid_fee BOOLEAN DEFAULT false,
    user_b_paid_fee BOOLEAN DEFAULT false,
    user_a_committed_at TIMESTAMPTZ,
    user_b_committed_at TIMESTAMPTZ,
    -- Payment completion
    user_a_paid_partner BOOLEAN DEFAULT false,
    user_b_paid_partner BOOLEAN DEFAULT false,
    proof_a_url TEXT,
    proof_b_url TEXT,
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours'),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Ensure different users
    CONSTRAINT different_users CHECK (user_a_id != user_b_id),
    CONSTRAINT different_bills CHECK (bill_a_id != bill_b_id)
);

CREATE INDEX idx_swaps_status ON swaps(status);
CREATE INDEX idx_swaps_user_a ON swaps(user_a_id);
CREATE INDEX idx_swaps_user_b ON swaps(user_b_id);
CREATE INDEX idx_swaps_expires ON swaps(expires_at) WHERE status = 'pending';

-- ============================================
-- SWAP DEALS TABLE
-- Structured terms for swaps (negotiable)
-- ============================================
CREATE TABLE IF NOT EXISTS swap_deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swap_id UUID NOT NULL REFERENCES swaps(id) ON DELETE CASCADE,
    proposer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    version INT DEFAULT 1 CHECK (version >= 1 AND version <= 4), -- Max 3 counter-offers
    who_pays_first TEXT DEFAULT 'simultaneous' CHECK (who_pays_first IN ('userAPaysFirst', 'userBPaysFirst', 'simultaneous')),
    amount_a DECIMAL(10,2),
    amount_b DECIMAL(10,2),
    deadline_a TIMESTAMPTZ,
    deadline_b TIMESTAMPTZ,
    proof_required TEXT DEFAULT 'screenshot' CHECK (proof_required IN ('screenshot', 'screenshotWithConfirmation')),
    fallback_if_late TEXT DEFAULT 'trustPointPenalty' CHECK (fallback_if_late IN ('trustPointPenalty', 'eligibilityLock', 'creditStake')),
    status TEXT DEFAULT 'proposed' CHECK (status IN ('proposed', 'countered', 'accepted', 'rejected', 'expired')),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours'),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_swap_deals_swap ON swap_deals(swap_id);
CREATE INDEX idx_swap_deals_status ON swap_deals(status) WHERE status = 'proposed' OR status = 'countered';

-- ============================================
-- SWAP EVENTS TABLE
-- Immutable audit trail for disputes
-- ============================================
CREATE TABLE IF NOT EXISTS swap_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swap_id UUID NOT NULL REFERENCES swaps(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- NULL for system events
    event_type TEXT NOT NULL CHECK (event_type IN (
        -- Deal negotiation
        'dealProposed', 'dealCountered', 'dealAccepted', 'dealRejected',
        -- Payment
        'paymentProofSubmitted', 'paymentConfirmed', 'paymentDisputed',
        -- Extensions
        'extensionRequested', 'extensionApproved', 'extensionDenied',
        -- Disputes
        'disputeOpened', 'disputeResolved', 'disputeEscalated',
        -- Collateral
        'collateralLocked', 'collateralReleased', 'collateralForfeited',
        -- Lifecycle
        'swapActivated', 'swapCompleted', 'swapCancelled', 'swapExpired',
        -- Chat
        'chatUnlocked', 'messageReported'
    )),
    payload JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_swap_events_swap ON swap_events(swap_id);
CREATE INDEX idx_swap_events_type ON swap_events(event_type);

-- ============================================
-- EXTENSION REQUESTS TABLE
-- Deadline extension requests
-- ============================================
CREATE TABLE IF NOT EXISTS extension_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swap_id UUID NOT NULL REFERENCES swaps(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT CHECK (reason IN ('payScheduleConflict', 'emergency', 'providerDelay', 'other')),
    custom_note TEXT,
    original_deadline TIMESTAMPTZ NOT NULL,
    requested_deadline TIMESTAMPTZ NOT NULL,
    partial_payment_amount DECIMAL(10,2),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied', 'expired')),
    responder_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    responded_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours'),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_extension_requests_swap ON extension_requests(swap_id);
CREATE INDEX idx_extension_requests_status ON extension_requests(status) WHERE status = 'pending';

-- ============================================
-- SWAP TRUST TABLE
-- User trust scores and tier progression
-- ============================================
CREATE TABLE IF NOT EXISTS swap_trust (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tier INT DEFAULT 1 CHECK (tier >= 1 AND tier <= 4),
    total_swaps INT DEFAULT 0,
    successful_swaps INT DEFAULT 0,
    disputed_swaps INT DEFAULT 0,
    missed_deadlines INT DEFAULT 0,
    trust_points INT DEFAULT 0,
    eligibility_locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE swap_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE swaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE swap_deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE swap_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE extension_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE swap_trust ENABLE ROW LEVEL SECURITY;

-- SWAP BILLS: Users can see their own + unmatched bills from others
CREATE POLICY swap_bills_select ON swap_bills FOR SELECT USING (
    user_id = auth.uid() OR status = 'unmatched'
);
CREATE POLICY swap_bills_insert ON swap_bills FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY swap_bills_update ON swap_bills FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY swap_bills_delete ON swap_bills FOR DELETE USING (user_id = auth.uid() AND status = 'unmatched');

-- SWAPS: Users can see/modify swaps they're part of
CREATE POLICY swaps_select ON swaps FOR SELECT USING (
    user_a_id = auth.uid() OR user_b_id = auth.uid()
);
CREATE POLICY swaps_insert ON swaps FOR INSERT WITH CHECK (
    user_a_id = auth.uid() OR user_b_id = auth.uid()
);
CREATE POLICY swaps_update ON swaps FOR UPDATE USING (
    user_a_id = auth.uid() OR user_b_id = auth.uid()
);

-- SWAP DEALS: Users can see/modify deals for swaps they're in
CREATE POLICY swap_deals_select ON swap_deals FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM swaps
        WHERE swaps.id = swap_deals.swap_id
        AND (swaps.user_a_id = auth.uid() OR swaps.user_b_id = auth.uid())
    )
);
CREATE POLICY swap_deals_insert ON swap_deals FOR INSERT WITH CHECK (proposer_id = auth.uid());
CREATE POLICY swap_deals_update ON swap_deals FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM swaps
        WHERE swaps.id = swap_deals.swap_id
        AND (swaps.user_a_id = auth.uid() OR swaps.user_b_id = auth.uid())
    )
);

-- SWAP EVENTS: Users can see events for swaps they're in (immutable, no update/delete)
CREATE POLICY swap_events_select ON swap_events FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM swaps
        WHERE swaps.id = swap_events.swap_id
        AND (swaps.user_a_id = auth.uid() OR swaps.user_b_id = auth.uid())
    )
);
CREATE POLICY swap_events_insert ON swap_events FOR INSERT WITH CHECK (
    actor_id = auth.uid() OR actor_id IS NULL
);

-- EXTENSION REQUESTS: Users can see/modify for swaps they're in
CREATE POLICY extension_requests_select ON extension_requests FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM swaps
        WHERE swaps.id = extension_requests.swap_id
        AND (swaps.user_a_id = auth.uid() OR swaps.user_b_id = auth.uid())
    )
);
CREATE POLICY extension_requests_insert ON extension_requests FOR INSERT WITH CHECK (requester_id = auth.uid());
CREATE POLICY extension_requests_update ON extension_requests FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM swaps
        WHERE swaps.id = extension_requests.swap_id
        AND (swaps.user_a_id = auth.uid() OR swaps.user_b_id = auth.uid())
    )
);

-- SWAP TRUST: Users can see their own trust, read-only for others
CREATE POLICY swap_trust_select ON swap_trust FOR SELECT USING (true);
CREATE POLICY swap_trust_insert ON swap_trust FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY swap_trust_update ON swap_trust FOR UPDATE USING (user_id = auth.uid());

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to get user's swap tier limit
CREATE OR REPLACE FUNCTION get_swap_tier_limit(p_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    user_tier INT;
BEGIN
    SELECT tier INTO user_tier FROM swap_trust WHERE user_id = p_user_id;

    -- Conservative tier limits
    RETURN CASE user_tier
        WHEN 1 THEN 25.00   -- New: $25 max
        WHEN 2 THEN 50.00   -- Established: $50 max
        WHEN 3 THEN 100.00  -- Trusted: $100 max
        WHEN 4 THEN 150.00  -- Veteran: $150 max
        ELSE 25.00
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can swap (not locked)
CREATE OR REPLACE FUNCTION can_user_swap(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    locked_until TIMESTAMPTZ;
BEGIN
    SELECT eligibility_locked_until INTO locked_until
    FROM swap_trust WHERE user_id = p_user_id;

    IF locked_until IS NULL THEN
        RETURN true;
    END IF;

    RETURN locked_until < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user tier based on completed swaps
CREATE OR REPLACE FUNCTION update_swap_tier()
RETURNS TRIGGER AS $$
BEGIN
    -- Only on swap completion
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Update both users' trust records
        UPDATE swap_trust
        SET
            total_swaps = total_swaps + 1,
            successful_swaps = successful_swaps + 1,
            trust_points = trust_points + 10,
            tier = CASE
                WHEN successful_swaps + 1 >= 25 AND disputed_swaps = 0 THEN 4
                WHEN successful_swaps + 1 >= 10 AND disputed_swaps = 0 THEN 3
                WHEN successful_swaps + 1 >= 3 AND disputed_swaps = 0 THEN 2
                ELSE tier
            END,
            updated_at = NOW()
        WHERE user_id IN (NEW.user_a_id, NEW.user_b_id);
    END IF;

    -- On dispute
    IF NEW.status = 'dispute' AND OLD.status != 'dispute' THEN
        UPDATE swap_trust
        SET
            disputed_swaps = disputed_swaps + 1,
            trust_points = GREATEST(0, trust_points - 50),
            eligibility_locked_until = NOW() + INTERVAL '7 days',
            tier = GREATEST(1, tier - 1),
            updated_at = NOW()
        WHERE user_id IN (NEW.user_a_id, NEW.user_b_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for tier updates
CREATE TRIGGER swap_status_change_trigger
    AFTER UPDATE OF status ON swaps
    FOR EACH ROW
    EXECUTE FUNCTION update_swap_tier();

-- Function to auto-expire pending swaps
CREATE OR REPLACE FUNCTION expire_pending_swaps()
RETURNS void AS $$
BEGIN
    UPDATE swaps
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'pending'
    AND expires_at < NOW();

    -- Also mark the bills as unmatched again
    UPDATE swap_bills
    SET status = 'unmatched', updated_at = NOW()
    WHERE id IN (
        SELECT bill_a_id FROM swaps WHERE status = 'expired'
        UNION
        SELECT bill_b_id FROM swaps WHERE status = 'expired'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- GRANTS
-- ============================================
GRANT EXECUTE ON FUNCTION get_swap_tier_limit(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_user_swap(UUID) TO authenticated;

-- ============================================
-- INITIALIZE TRUST RECORDS FOR EXISTING USERS
-- ============================================
INSERT INTO swap_trust (user_id, tier, total_swaps, successful_swaps)
SELECT id, 1, 0, 0 FROM auth.users
ON CONFLICT (user_id) DO NOTHING;
