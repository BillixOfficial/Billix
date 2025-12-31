-- Phase 4: Multi-Party Swaps, Swap-Back Protection & Priority Listings
-- Migration for Billix Trust Ladder feature expansion

-- =============================================================================
-- Multi-Party Swaps Table
-- =============================================================================
-- Supports fractional swaps, multi-party contributions, and group swaps

CREATE TABLE IF NOT EXISTS multi_party_swaps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swap_type TEXT NOT NULL CHECK (swap_type IN ('exact_match', 'fractional', 'multi_party', 'group', 'flexible')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'recruiting', 'filled', 'in_progress', 'completed', 'cancelled', 'expired')),
    organizer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    target_bill_id UUID REFERENCES user_bills(id) ON DELETE SET NULL,
    target_amount DECIMAL(10,2) NOT NULL CHECK (target_amount > 0),
    filled_amount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (filled_amount >= 0),
    min_contribution DECIMAL(10,2) CHECK (min_contribution > 0),
    max_participants INTEGER NOT NULL DEFAULT 5 CHECK (max_participants >= 2),
    group_id UUID REFERENCES swap_groups(id) ON DELETE SET NULL,
    execution_deadline TIMESTAMP WITH TIME ZONE,
    tier_required INTEGER NOT NULL DEFAULT 0 CHECK (tier_required >= 0 AND tier_required <= 3),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for multi_party_swaps
CREATE INDEX idx_multi_party_swaps_organizer ON multi_party_swaps(organizer_id);
CREATE INDEX idx_multi_party_swaps_status ON multi_party_swaps(status);
CREATE INDEX idx_multi_party_swaps_type ON multi_party_swaps(swap_type);
CREATE INDEX idx_multi_party_swaps_created ON multi_party_swaps(created_at DESC);

-- RLS for multi_party_swaps
ALTER TABLE multi_party_swaps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all active swaps"
    ON multi_party_swaps FOR SELECT
    USING (status IN ('recruiting', 'filled', 'in_progress') OR organizer_id = auth.uid());

CREATE POLICY "Users can create their own swaps"
    ON multi_party_swaps FOR INSERT
    WITH CHECK (organizer_id = auth.uid());

CREATE POLICY "Users can update their own swaps"
    ON multi_party_swaps FOR UPDATE
    USING (organizer_id = auth.uid());

-- =============================================================================
-- Swap Participants Table
-- =============================================================================
-- Tracks all participants in multi-party swaps

CREATE TABLE IF NOT EXISTS swap_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swap_id UUID NOT NULL REFERENCES multi_party_swaps(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    bill_id UUID REFERENCES user_bills(id) ON DELETE SET NULL,
    contribution_amount DECIMAL(10,2) NOT NULL CHECK (contribution_amount > 0),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('invited', 'pending', 'confirmed', 'paid', 'verified', 'declined', 'removed')),
    fee_paid BOOLEAN NOT NULL DEFAULT false,
    screenshot_url TEXT,
    screenshot_verified BOOLEAN,
    completed_at TIMESTAMP WITH TIME ZONE,
    rating_given INTEGER CHECK (rating_given >= 1 AND rating_given <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(swap_id, user_id)
);

-- Indexes for swap_participants
CREATE INDEX idx_swap_participants_swap ON swap_participants(swap_id);
CREATE INDEX idx_swap_participants_user ON swap_participants(user_id);
CREATE INDEX idx_swap_participants_status ON swap_participants(status);

-- RLS for swap_participants
ALTER TABLE swap_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view participants in their swaps"
    ON swap_participants FOR SELECT
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM multi_party_swaps
            WHERE multi_party_swaps.id = swap_participants.swap_id
            AND multi_party_swaps.organizer_id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM swap_participants sp2
            WHERE sp2.swap_id = swap_participants.swap_id
            AND sp2.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert their own participation"
    ON swap_participants FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own participation"
    ON swap_participants FOR UPDATE
    USING (user_id = auth.uid());

-- =============================================================================
-- Priority Listings Table
-- =============================================================================
-- Tracks boosted/priority swap listings

CREATE TABLE IF NOT EXISTS priority_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swap_id UUID NOT NULL REFERENCES multi_party_swaps(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    boost_multiplier DECIMAL(3,1) NOT NULL DEFAULT 1.5 CHECK (boost_multiplier >= 1 AND boost_multiplier <= 5),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for priority_listings
CREATE INDEX idx_priority_listings_swap ON priority_listings(swap_id);
CREATE INDEX idx_priority_listings_active ON priority_listings(is_active, expires_at);

-- RLS for priority_listings
ALTER TABLE priority_listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all active priority listings"
    ON priority_listings FOR SELECT
    USING (is_active = true AND expires_at > NOW());

CREATE POLICY "Users can create their own priority listings"
    ON priority_listings FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own priority listings"
    ON priority_listings FOR UPDATE
    USING (user_id = auth.uid());

-- =============================================================================
-- Protection Plans Table
-- =============================================================================
-- Stores user protection plan subscriptions

CREATE TABLE IF NOT EXISTS protection_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'inactive' CHECK (status IN ('inactive', 'active', 'pending', 'claimed', 'expired', 'cancelled')),
    activated_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    swaps_covered INTEGER NOT NULL DEFAULT 0,
    max_coverage_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    used_coverage_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    claims_allowed INTEGER NOT NULL DEFAULT 0,
    claims_used INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id, status) -- Only one active plan per user
);

-- Indexes for protection_plans
CREATE INDEX idx_protection_plans_user ON protection_plans(user_id);
CREATE INDEX idx_protection_plans_status ON protection_plans(status);

-- RLS for protection_plans
ALTER TABLE protection_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own protection plans"
    ON protection_plans FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can create their own protection plans"
    ON protection_plans FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own protection plans"
    ON protection_plans FOR UPDATE
    USING (user_id = auth.uid());

-- =============================================================================
-- Protection Claims Table
-- =============================================================================
-- Stores protection claim requests

CREATE TABLE IF NOT EXISTS protection_claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES protection_plans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    swap_id UUID REFERENCES multi_party_swaps(id) ON DELETE SET NULL,
    reason TEXT NOT NULL CHECK (reason IN ('job_loss', 'medical_emergency', 'family_emergency', 'unexpected_expense', 'income_reduction', 'other')),
    reason_details TEXT,
    status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'under_review', 'approved', 'denied', 'processed')),
    claim_amount DECIMAL(10,2) NOT NULL CHECK (claim_amount > 0),
    approved_amount DECIMAL(10,2),
    documentation_url TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for protection_claims
CREATE INDEX idx_protection_claims_plan ON protection_claims(plan_id);
CREATE INDEX idx_protection_claims_user ON protection_claims(user_id);
CREATE INDEX idx_protection_claims_status ON protection_claims(status);

-- RLS for protection_claims
ALTER TABLE protection_claims ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own claims"
    ON protection_claims FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can create their own claims"
    ON protection_claims FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own claims"
    ON protection_claims FOR UPDATE
    USING (user_id = auth.uid());

-- =============================================================================
-- Swap Groups Table (for Group Swaps feature)
-- =============================================================================

CREATE TABLE IF NOT EXISTS swap_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_public BOOLEAN NOT NULL DEFAULT false,
    max_members INTEGER DEFAULT 20,
    member_count INTEGER NOT NULL DEFAULT 1,
    total_swaps_completed INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for swap_groups
CREATE INDEX idx_swap_groups_creator ON swap_groups(creator_id);
CREATE INDEX idx_swap_groups_public ON swap_groups(is_public);

-- RLS for swap_groups
ALTER TABLE swap_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view public groups"
    ON swap_groups FOR SELECT
    USING (is_public = true OR creator_id = auth.uid());

CREATE POLICY "Users can create groups"
    ON swap_groups FOR INSERT
    WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Creators can update their groups"
    ON swap_groups FOR UPDATE
    USING (creator_id = auth.uid());

-- =============================================================================
-- Group Members Table
-- =============================================================================

CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES swap_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'moderator', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(group_id, user_id)
);

-- Indexes for group_members
CREATE INDEX idx_group_members_group ON group_members(group_id);
CREATE INDEX idx_group_members_user ON group_members(user_id);

-- RLS for group_members
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their group membership"
    ON group_members FOR SELECT
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM group_members gm2
            WHERE gm2.group_id = group_members.group_id
            AND gm2.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can join public groups"
    ON group_members FOR INSERT
    WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM swap_groups
            WHERE swap_groups.id = group_members.group_id
            AND (swap_groups.is_public = true OR swap_groups.creator_id = auth.uid())
        )
    );

-- =============================================================================
-- Functions & Triggers
-- =============================================================================

-- Function to update multi_party_swaps.updated_at
CREATE OR REPLACE FUNCTION update_multi_party_swap_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_multi_party_swap_timestamp
    BEFORE UPDATE ON multi_party_swaps
    FOR EACH ROW
    EXECUTE FUNCTION update_multi_party_swap_timestamp();

-- Function to auto-expire priority listings
CREATE OR REPLACE FUNCTION expire_priority_listings()
RETURNS void AS $$
BEGIN
    UPDATE priority_listings
    SET is_active = false
    WHERE is_active = true AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to auto-expire protection plans
CREATE OR REPLACE FUNCTION expire_protection_plans()
RETURNS void AS $$
BEGIN
    UPDATE protection_plans
    SET status = 'expired'
    WHERE status = 'active' AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to update group member count
CREATE OR REPLACE FUNCTION update_group_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE swap_groups SET member_count = member_count + 1 WHERE id = NEW.group_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE swap_groups SET member_count = member_count - 1 WHERE id = OLD.group_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_group_member_count
    AFTER INSERT OR DELETE ON group_members
    FOR EACH ROW
    EXECUTE FUNCTION update_group_member_count();

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE multi_party_swaps IS 'Stores fractional, multi-party, group, and flexible swaps';
COMMENT ON TABLE swap_participants IS 'Tracks all participants in multi-party swaps with their contributions';
COMMENT ON TABLE priority_listings IS 'Boost/priority listings for increased swap visibility';
COMMENT ON TABLE protection_plans IS 'Swap-back protection plans for users';
COMMENT ON TABLE protection_claims IS 'Claims filed against protection plans for hardship situations';
COMMENT ON TABLE swap_groups IS 'Groups for coordinated swap activities';
COMMENT ON TABLE group_members IS 'Membership tracking for swap groups';
