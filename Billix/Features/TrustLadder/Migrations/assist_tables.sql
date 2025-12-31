-- =====================================================
-- BILL ASSIST FEATURE - DATABASE MIGRATION
-- =====================================================
-- Peer-to-peer bill assistance marketplace tables
-- Billix acts as facilitator only - users negotiate terms
-- Created: 2024-12-31
-- =====================================================

-- =====================================================
-- 1. ASSIST REQUESTS TABLE
-- =====================================================
-- Core table for bill assistance requests

CREATE TABLE IF NOT EXISTS assist_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL DEFAULT 'active',

    -- Bill Information
    bill_id UUID REFERENCES user_bills(id) ON DELETE SET NULL,
    bill_category VARCHAR(100) NOT NULL,
    bill_provider VARCHAR(255) NOT NULL,
    bill_amount DECIMAL(10, 2) NOT NULL,
    bill_due_date DATE NOT NULL,
    bill_screenshot_url TEXT,
    bill_screenshot_verified BOOLEAN DEFAULT false,

    -- Request Details
    amount_requested DECIMAL(10, 2) NOT NULL,
    urgency VARCHAR(20) NOT NULL DEFAULT 'medium',
    description TEXT,
    preferred_terms JSONB,

    -- Helper (populated when matched)
    helper_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    agreed_terms JSONB,
    matched_at TIMESTAMPTZ,

    -- Fee Tracking
    requester_fee_paid BOOLEAN DEFAULT false,
    helper_fee_paid BOOLEAN DEFAULT false,
    requester_fee_transaction_id VARCHAR(255),
    helper_fee_transaction_id VARCHAR(255),

    -- Payment Proof
    payment_screenshot_url TEXT,
    payment_verified BOOLEAN DEFAULT false,
    payment_verified_at TIMESTAMPTZ,

    -- Ratings (1-5 stars)
    requester_rating INT CHECK (requester_rating >= 1 AND requester_rating <= 5),
    helper_rating INT CHECK (helper_rating >= 1 AND helper_rating <= 5),
    requester_review TEXT,
    helper_review TEXT,

    -- Repayment Tracking (for loans)
    total_repaid DECIMAL(10, 2) DEFAULT 0,
    last_repayment_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    -- Constraints
    CONSTRAINT valid_status CHECK (status IN (
        'draft', 'active', 'matched', 'fee_pending', 'fee_paid',
        'negotiating', 'terms_accepted', 'payment_pending', 'payment_sent',
        'completed', 'repaying', 'repaid', 'disputed', 'cancelled', 'expired', 'failed'
    )),
    CONSTRAINT valid_urgency CHECK (urgency IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT positive_amounts CHECK (bill_amount > 0 AND amount_requested > 0),
    CONSTRAINT amount_not_exceed_bill CHECK (amount_requested <= bill_amount)
);

-- Indexes for assist_requests
CREATE INDEX idx_assist_requests_requester ON assist_requests(requester_id);
CREATE INDEX idx_assist_requests_helper ON assist_requests(helper_id);
CREATE INDEX idx_assist_requests_status ON assist_requests(status);
CREATE INDEX idx_assist_requests_urgency ON assist_requests(urgency);
CREATE INDEX idx_assist_requests_created ON assist_requests(created_at DESC);
CREATE INDEX idx_assist_requests_active ON assist_requests(status) WHERE status = 'active';

-- =====================================================
-- 2. ASSIST OFFERS TABLE
-- =====================================================
-- Offers made by potential helpers

CREATE TABLE IF NOT EXISTS assist_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assist_request_id UUID NOT NULL REFERENCES assist_requests(id) ON DELETE CASCADE,
    offerer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    proposed_terms JSONB NOT NULL,
    message TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- One offer per user per request
    UNIQUE(assist_request_id, offerer_id),

    CONSTRAINT valid_offer_status CHECK (status IN (
        'pending', 'accepted', 'rejected', 'withdrawn', 'expired'
    ))
);

-- Indexes for assist_offers
CREATE INDEX idx_assist_offers_request ON assist_offers(assist_request_id);
CREATE INDEX idx_assist_offers_offerer ON assist_offers(offerer_id);
CREATE INDEX idx_assist_offers_status ON assist_offers(status);

-- =====================================================
-- 3. ASSIST MESSAGES TABLE
-- =====================================================
-- In-app messaging for negotiation

CREATE TABLE IF NOT EXISTS assist_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assist_request_id UUID NOT NULL REFERENCES assist_requests(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message_type VARCHAR(30) NOT NULL DEFAULT 'text',
    content TEXT,
    terms_data JSONB,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_message_type CHECK (message_type IN (
        'text', 'terms_proposal', 'terms_accepted', 'terms_rejected',
        'system', 'payment_sent', 'payment_verified', 'repayment_received'
    ))
);

-- Indexes for assist_messages
CREATE INDEX idx_assist_messages_request ON assist_messages(assist_request_id);
CREATE INDEX idx_assist_messages_sender ON assist_messages(sender_id);
CREATE INDEX idx_assist_messages_created ON assist_messages(created_at);

-- =====================================================
-- 4. ASSIST REPAYMENTS TABLE
-- =====================================================
-- Track loan repayments

CREATE TABLE IF NOT EXISTS assist_repayments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assist_request_id UUID NOT NULL REFERENCES assist_requests(id) ON DELETE CASCADE,
    payer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(100),
    screenshot_url TEXT,
    verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT positive_repayment CHECK (amount > 0)
);

-- Indexes for assist_repayments
CREATE INDEX idx_assist_repayments_request ON assist_repayments(assist_request_id);
CREATE INDEX idx_assist_repayments_payer ON assist_repayments(payer_id);

-- =====================================================
-- 5. ASSIST DISPUTES TABLE
-- =====================================================
-- Disputes filed for assist requests

CREATE TABLE IF NOT EXISTS assist_disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assist_request_id UUID NOT NULL REFERENCES assist_requests(id) ON DELETE CASCADE,
    reported_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason VARCHAR(50) NOT NULL,
    description TEXT,
    evidence_urls TEXT[],
    status VARCHAR(20) DEFAULT 'open',
    resolution TEXT,
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_dispute_reason CHECK (reason IN (
        'ghost', 'fake_screenshot', 'wrong_amount', 'wrong_provider',
        'no_repayment', 'harassment', 'scam', 'other'
    )),
    CONSTRAINT valid_dispute_status CHECK (status IN (
        'open', 'investigating', 'resolved', 'dismissed'
    ))
);

-- Indexes for assist_disputes
CREATE INDEX idx_assist_disputes_request ON assist_disputes(assist_request_id);
CREATE INDEX idx_assist_disputes_reporter ON assist_disputes(reported_by);
CREATE INDEX idx_assist_disputes_status ON assist_disputes(status);

-- =====================================================
-- 6. ASSIST FEE TRANSACTIONS TABLE
-- =====================================================
-- StoreKit transaction records for connection fees

CREATE TABLE IF NOT EXISTS assist_fee_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    assist_request_id UUID NOT NULL REFERENCES assist_requests(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL, -- 'requester' or 'helper'
    product_id VARCHAR(100) NOT NULL,
    transaction_id VARCHAR(255) NOT NULL UNIQUE,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'completed',
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_role CHECK (role IN ('requester', 'helper')),
    CONSTRAINT valid_fee_status CHECK (status IN ('pending', 'completed', 'refunded', 'failed'))
);

-- Indexes for assist_fee_transactions
CREATE INDEX idx_assist_fee_user ON assist_fee_transactions(user_id);
CREATE INDEX idx_assist_fee_request ON assist_fee_transactions(assist_request_id);

-- =====================================================
-- 7. UPDATE USER_TRUST_STATUS TABLE
-- =====================================================
-- Add assist-specific tracking columns

ALTER TABLE user_trust_status
ADD COLUMN IF NOT EXISTS total_assists_given INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_assists_received INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS assist_rating_as_helper DECIMAL(3, 2),
ADD COLUMN IF NOT EXISTS assist_rating_as_requester DECIMAL(3, 2),
ADD COLUMN IF NOT EXISTS total_amount_assisted DECIMAL(12, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS successful_repayments INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS failed_repayments INT DEFAULT 0;

-- =====================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE assist_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE assist_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE assist_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE assist_repayments ENABLE ROW LEVEL SECURITY;
ALTER TABLE assist_disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE assist_fee_transactions ENABLE ROW LEVEL SECURITY;

-- Assist Requests Policies
CREATE POLICY "Users can view active requests" ON assist_requests
    FOR SELECT USING (
        status = 'active' OR
        requester_id = auth.uid() OR
        helper_id = auth.uid()
    );

CREATE POLICY "Users can create their own requests" ON assist_requests
    FOR INSERT WITH CHECK (requester_id = auth.uid());

CREATE POLICY "Users can update their own requests" ON assist_requests
    FOR UPDATE USING (
        requester_id = auth.uid() OR
        helper_id = auth.uid()
    );

-- Assist Offers Policies
CREATE POLICY "Users can view offers on their requests or their own offers" ON assist_offers
    FOR SELECT USING (
        offerer_id = auth.uid() OR
        assist_request_id IN (
            SELECT id FROM assist_requests WHERE requester_id = auth.uid()
        )
    );

CREATE POLICY "Users can create offers" ON assist_offers
    FOR INSERT WITH CHECK (offerer_id = auth.uid());

CREATE POLICY "Users can update their own offers" ON assist_offers
    FOR UPDATE USING (offerer_id = auth.uid());

-- Assist Messages Policies
CREATE POLICY "Participants can view messages" ON assist_messages
    FOR SELECT USING (
        assist_request_id IN (
            SELECT id FROM assist_requests
            WHERE requester_id = auth.uid() OR helper_id = auth.uid()
        )
    );

CREATE POLICY "Participants can send messages" ON assist_messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND
        assist_request_id IN (
            SELECT id FROM assist_requests
            WHERE requester_id = auth.uid() OR helper_id = auth.uid()
        )
    );

-- Assist Repayments Policies
CREATE POLICY "Participants can view repayments" ON assist_repayments
    FOR SELECT USING (
        payer_id = auth.uid() OR
        assist_request_id IN (
            SELECT id FROM assist_requests WHERE helper_id = auth.uid()
        )
    );

CREATE POLICY "Payers can record repayments" ON assist_repayments
    FOR INSERT WITH CHECK (payer_id = auth.uid());

-- Assist Disputes Policies
CREATE POLICY "Users can view their disputes" ON assist_disputes
    FOR SELECT USING (
        reported_by = auth.uid() OR
        assist_request_id IN (
            SELECT id FROM assist_requests
            WHERE requester_id = auth.uid() OR helper_id = auth.uid()
        )
    );

CREATE POLICY "Users can create disputes" ON assist_disputes
    FOR INSERT WITH CHECK (reported_by = auth.uid());

-- Fee Transactions Policies
CREATE POLICY "Users can view their fee transactions" ON assist_fee_transactions
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can record their fee payments" ON assist_fee_transactions
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- =====================================================
-- 9. TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_assist_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER assist_requests_updated_at
    BEFORE UPDATE ON assist_requests
    FOR EACH ROW EXECUTE FUNCTION update_assist_updated_at();

CREATE TRIGGER assist_offers_updated_at
    BEFORE UPDATE ON assist_offers
    FOR EACH ROW EXECUTE FUNCTION update_assist_updated_at();

-- =====================================================
-- 10. TRIGGER TO UPDATE REPAYMENT TOTAL
-- =====================================================

CREATE OR REPLACE FUNCTION update_assist_repayment_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE assist_requests
    SET
        total_repaid = (
            SELECT COALESCE(SUM(amount), 0)
            FROM assist_repayments
            WHERE assist_request_id = NEW.assist_request_id AND verified = true
        ),
        last_repayment_at = NOW()
    WHERE id = NEW.assist_request_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER assist_repayment_total_trigger
    AFTER INSERT OR UPDATE ON assist_repayments
    FOR EACH ROW EXECUTE FUNCTION update_assist_repayment_total();

-- =====================================================
-- 11. FUNCTION TO CHECK ASSIST ELIGIBILITY
-- =====================================================

CREATE OR REPLACE FUNCTION check_assist_eligibility(user_uuid UUID)
RETURNS TABLE (
    can_request BOOLEAN,
    can_offer BOOLEAN,
    reasons TEXT[]
) AS $$
DECLARE
    user_status RECORD;
    eligibility_reasons TEXT[] := ARRAY[]::TEXT[];
    is_eligible_request BOOLEAN := true;
    is_eligible_offer BOOLEAN := true;
    active_request_count INT;
BEGIN
    -- Get user trust status
    SELECT * INTO user_status FROM user_trust_status WHERE user_id = user_uuid;

    -- Check if user exists
    IF user_status IS NULL THEN
        RETURN QUERY SELECT false, false, ARRAY['User not found']::TEXT[];
        RETURN;
    END IF;

    -- Check if banned
    IF user_status.is_banned THEN
        eligibility_reasons := array_append(eligibility_reasons, 'Account is banned');
        is_eligible_request := false;
        is_eligible_offer := false;
    END IF;

    -- Check verification status
    IF NOT (user_status.verification_status->>'email')::BOOLEAN THEN
        eligibility_reasons := array_append(eligibility_reasons, 'Email not verified');
        is_eligible_request := false;
        is_eligible_offer := false;
    END IF;

    IF NOT (user_status.verification_status->>'phone')::BOOLEAN THEN
        eligibility_reasons := array_append(eligibility_reasons, 'Phone not verified');
        is_eligible_request := false;
        is_eligible_offer := false;
    END IF;

    -- Check minimum swaps (2 required)
    IF user_status.total_successful_swaps < 2 THEN
        eligibility_reasons := array_append(eligibility_reasons,
            format('Need %s more successful swaps', 2 - user_status.total_successful_swaps));
        is_eligible_request := false;
        is_eligible_offer := false;
    END IF;

    -- Check trust points for offering (minimum 300)
    IF user_status.trust_points < 300 THEN
        eligibility_reasons := array_append(eligibility_reasons,
            format('Need %s more trust points to offer help', 300 - user_status.trust_points));
        is_eligible_offer := false;
    END IF;

    -- Check active request limit (max 2)
    SELECT COUNT(*) INTO active_request_count
    FROM assist_requests
    WHERE requester_id = user_uuid
    AND status IN ('active', 'matched', 'fee_pending', 'fee_paid', 'negotiating', 'terms_accepted', 'payment_pending', 'payment_sent');

    IF active_request_count >= 2 THEN
        eligibility_reasons := array_append(eligibility_reasons, 'Maximum 2 active requests allowed');
        is_eligible_request := false;
    END IF;

    RETURN QUERY SELECT is_eligible_request, is_eligible_offer, eligibility_reasons;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 12. FUNCTION TO AUTO-EXPIRE OLD REQUESTS
-- =====================================================

CREATE OR REPLACE FUNCTION expire_old_assist_requests()
RETURNS void AS $$
BEGIN
    -- Expire active requests older than 7 days
    UPDATE assist_requests
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'active'
    AND created_at < NOW() - INTERVAL '7 days';

    -- Expire pending offers older than 48 hours
    UPDATE assist_offers
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'pending'
    AND created_at < NOW() - INTERVAL '48 hours';

    -- Mark as ghost if fee not paid within 72 hours of match
    UPDATE assist_requests
    SET status = 'failed', updated_at = NOW()
    WHERE status IN ('matched', 'fee_pending')
    AND matched_at < NOW() - INTERVAL '72 hours';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 13. COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE assist_requests IS 'Bill assistance requests - peer-to-peer help marketplace';
COMMENT ON TABLE assist_offers IS 'Offers from potential helpers on assist requests';
COMMENT ON TABLE assist_messages IS 'In-app messaging for assist request negotiations';
COMMENT ON TABLE assist_repayments IS 'Repayment records for loan-type assists';
COMMENT ON TABLE assist_disputes IS 'Disputes filed for assist requests';
COMMENT ON TABLE assist_fee_transactions IS 'StoreKit connection fee payment records';

COMMENT ON COLUMN assist_requests.preferred_terms IS 'JSONB: {assist_type, interest_rate, repayment_date, installment_count, notes}';
COMMENT ON COLUMN assist_requests.agreed_terms IS 'Final negotiated terms agreed by both parties';
COMMENT ON COLUMN assist_offers.proposed_terms IS 'Terms proposed by the helper in their offer';
