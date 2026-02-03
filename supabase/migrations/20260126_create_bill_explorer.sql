-- Bill Explorer Marketplace Tables
-- Individual bill listings with time-based rotation algorithm

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- EXPLORE BILL LISTINGS TABLE
-- =============================================
-- Individual bill listings for the marketplace
-- Bills are automatically created from bill uploads and BillSwap listings

CREATE TABLE IF NOT EXISTS explore_bill_listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    anonymous_id TEXT NOT NULL, -- "User #4821" for privacy
    source_type TEXT NOT NULL CHECK (source_type IN ('bill_report', 'swap_bill')),
    source_id UUID, -- Reference to original bill_reports or swap_bills table

    -- Bill Details
    bill_type TEXT NOT NULL CHECK (bill_type IN ('electric', 'gas', 'water', 'internet', 'phone', 'cable', 'rent', 'insurance')),
    provider TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    billing_period TEXT, -- 'Monthly', 'Quarterly', etc.

    -- Location (anonymized to city level)
    city TEXT NOT NULL,
    state TEXT NOT NULL,

    -- Comparison Data
    percentile INTEGER CHECK (percentile >= 0 AND percentile <= 100),
    trend TEXT CHECK (trend IN ('increased', 'decreased', 'stable')),
    historical_min DECIMAL(10, 2),
    historical_max DECIMAL(10, 2),

    -- Context
    housing_type TEXT, -- 'Apartment', 'House', 'Condo', 'Townhouse'
    occupants INTEGER,
    square_footage TEXT, -- "~800 sqft"
    user_note TEXT,

    -- Verification & Engagement
    is_verified BOOLEAN DEFAULT false,
    vote_score INTEGER DEFAULT 0,
    tip_count INTEGER DEFAULT 0,

    -- Rotation Algorithm
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_boosted_at TIMESTAMPTZ,

    -- Soft delete
    deleted_at TIMESTAMPTZ
);

-- Indexes for performance
CREATE INDEX idx_explore_listings_bill_type ON explore_bill_listings(bill_type);
CREATE INDEX idx_explore_listings_location ON explore_bill_listings(city, state);
CREATE INDEX idx_explore_listings_created ON explore_bill_listings(created_at DESC);
CREATE INDEX idx_explore_listings_boosted ON explore_bill_listings(last_boosted_at DESC NULLS LAST);
CREATE INDEX idx_explore_listings_user ON explore_bill_listings(user_id);
CREATE INDEX idx_explore_listings_source ON explore_bill_listings(source_type, source_id);

-- =============================================
-- BILL INTERACTIONS TABLE
-- =============================================
-- Tracks user votes and bookmarks for bill listings

CREATE TABLE IF NOT EXISTS bill_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES explore_bill_listings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    vote TEXT CHECK (vote IN ('up', 'down')),
    is_bookmarked BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- One interaction per user per listing
    UNIQUE(listing_id, user_id)
);

-- Indexes
CREATE INDEX idx_bill_interactions_listing ON bill_interactions(listing_id);
CREATE INDEX idx_bill_interactions_user ON bill_interactions(user_id);
CREATE INDEX idx_bill_interactions_bookmarked ON bill_interactions(user_id, is_bookmarked) WHERE is_bookmarked = true;

-- =============================================
-- ANONYMOUS QUESTIONS TABLE
-- =============================================
-- Q&A system for bill listings

CREATE TABLE IF NOT EXISTS anonymous_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES explore_bill_listings(id) ON DELETE CASCADE,
    asker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    asker_anonymous_id TEXT NOT NULL, -- "User #1234"

    question TEXT NOT NULL,
    answer TEXT,
    answered_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_anonymous_questions_listing ON anonymous_questions(listing_id);
CREATE INDEX idx_anonymous_questions_asker ON anonymous_questions(asker_id);

-- =============================================
-- FUNCTIONS
-- =============================================

-- Function to generate anonymous ID for a user
CREATE OR REPLACE FUNCTION generate_anonymous_id(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    hash_val INTEGER;
BEGIN
    -- Generate a consistent 4-digit number from UUID
    hash_val := abs(('x' || substring(user_uuid::text, 1, 8))::bit(32)::int) % 9000 + 1000;
    RETURN 'User #' || hash_val::text;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to update vote score when interaction changes
CREATE OR REPLACE FUNCTION update_listing_vote_score()
RETURNS TRIGGER AS $$
BEGIN
    -- Recalculate vote score for the listing
    UPDATE explore_bill_listings
    SET vote_score = (
        SELECT COALESCE(SUM(
            CASE
                WHEN vote = 'up' THEN 1
                WHEN vote = 'down' THEN -1
                ELSE 0
            END
        ), 0)
        FROM bill_interactions
        WHERE listing_id = COALESCE(NEW.listing_id, OLD.listing_id)
    )
    WHERE id = COALESCE(NEW.listing_id, OLD.listing_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger to update vote score
DROP TRIGGER IF EXISTS trigger_update_vote_score ON bill_interactions;
CREATE TRIGGER trigger_update_vote_score
    AFTER INSERT OR UPDATE OR DELETE ON bill_interactions
    FOR EACH ROW
    EXECUTE FUNCTION update_listing_vote_score();

-- Function to update tip count when question is answered
CREATE OR REPLACE FUNCTION update_listing_tip_count()
RETURNS TRIGGER AS $$
BEGIN
    -- Recalculate tip count (number of answered questions)
    UPDATE explore_bill_listings
    SET tip_count = (
        SELECT COUNT(*)
        FROM anonymous_questions
        WHERE listing_id = COALESCE(NEW.listing_id, OLD.listing_id)
        AND answer IS NOT NULL
    )
    WHERE id = COALESCE(NEW.listing_id, OLD.listing_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger to update tip count
DROP TRIGGER IF EXISTS trigger_update_tip_count ON anonymous_questions;
CREATE TRIGGER trigger_update_tip_count
    AFTER INSERT OR UPDATE OR DELETE ON anonymous_questions
    FOR EACH ROW
    EXECUTE FUNCTION update_listing_tip_count();

-- Function to boost old listings (called by cron job)
CREATE OR REPLACE FUNCTION boost_old_listings(days_threshold INTEGER DEFAULT 7, max_boost INTEGER DEFAULT 50)
RETURNS INTEGER AS $$
DECLARE
    boosted_count INTEGER;
BEGIN
    WITH old_listings AS (
        SELECT id
        FROM explore_bill_listings
        WHERE deleted_at IS NULL
        AND COALESCE(last_boosted_at, created_at) < NOW() - (days_threshold || ' days')::INTERVAL
        ORDER BY COALESCE(last_boosted_at, created_at) ASC
        LIMIT max_boost
    )
    UPDATE explore_bill_listings
    SET last_boosted_at = NOW()
    WHERE id IN (SELECT id FROM old_listings);

    GET DIAGNOSTICS boosted_count = ROW_COUNT;
    RETURN boosted_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================

ALTER TABLE explore_bill_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE anonymous_questions ENABLE ROW LEVEL SECURITY;

-- Listings: Anyone can view, only owner can update/delete
CREATE POLICY "Listings are viewable by everyone"
    ON explore_bill_listings FOR SELECT
    USING (deleted_at IS NULL);

CREATE POLICY "Users can create their own listings"
    ON explore_bill_listings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own listings"
    ON explore_bill_listings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can soft-delete their own listings"
    ON explore_bill_listings FOR DELETE
    USING (auth.uid() = user_id);

-- Interactions: Users manage their own interactions
CREATE POLICY "Users can view their own interactions"
    ON bill_interactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own interactions"
    ON bill_interactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own interactions"
    ON bill_interactions FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own interactions"
    ON bill_interactions FOR DELETE
    USING (auth.uid() = user_id);

-- Questions: Anyone can view, askers create, listing owners answer
CREATE POLICY "Questions are viewable by everyone"
    ON anonymous_questions FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can ask questions"
    ON anonymous_questions FOR INSERT
    WITH CHECK (auth.uid() = asker_id);

CREATE POLICY "Listing owners can answer questions"
    ON anonymous_questions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM explore_bill_listings
            WHERE id = anonymous_questions.listing_id
            AND user_id = auth.uid()
        )
    );
