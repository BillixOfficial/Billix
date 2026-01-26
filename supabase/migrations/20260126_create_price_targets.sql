-- Create price_targets table for "Name Your Price" feature
-- This stores user price targets for affiliate outreach and deal matching

CREATE TABLE IF NOT EXISTS price_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    bill_type TEXT NOT NULL,
    target_amount DECIMAL(10,2) NOT NULL,
    current_provider TEXT,
    current_amount DECIMAL(10,2),
    contact_preference TEXT NOT NULL DEFAULT 'push',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one target per bill type per user
    UNIQUE(user_id, bill_type)
);

-- Create index for querying by user
CREATE INDEX IF NOT EXISTS idx_price_targets_user_id ON price_targets(user_id);

-- Create index for querying by bill type (for affiliate outreach)
CREATE INDEX IF NOT EXISTS idx_price_targets_bill_type ON price_targets(bill_type);

-- Create index for finding users who want deal alerts
CREATE INDEX IF NOT EXISTS idx_price_targets_contact_preference ON price_targets(contact_preference)
    WHERE contact_preference != 'none';

-- Create composite index for outreach queries
CREATE INDEX IF NOT EXISTS idx_price_targets_outreach ON price_targets(bill_type, contact_preference, current_provider);

-- Enable Row Level Security
ALTER TABLE price_targets ENABLE ROW LEVEL SECURITY;

-- Users can only see their own price targets
CREATE POLICY "Users can view own price targets" ON price_targets
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own price targets
CREATE POLICY "Users can insert own price targets" ON price_targets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own price targets
CREATE POLICY "Users can update own price targets" ON price_targets
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own price targets
CREATE POLICY "Users can delete own price targets" ON price_targets
    FOR DELETE USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_price_targets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER trigger_update_price_targets_updated_at
    BEFORE UPDATE ON price_targets
    FOR EACH ROW
    EXECUTE FUNCTION update_price_targets_updated_at();

-- Comment on table for documentation
COMMENT ON TABLE price_targets IS 'Stores user price targets for the Name Your Price feature. Used for affiliate matching and deal outreach.';
COMMENT ON COLUMN price_targets.bill_type IS 'Type of bill: electric, internet, gas, phone, water, trash, auto_insurance, home_insurance, streaming, cable, rent';
COMMENT ON COLUMN price_targets.target_amount IS 'What the user wants to pay per month';
COMMENT ON COLUMN price_targets.current_provider IS 'Current service provider name (for negotiation/switching)';
COMMENT ON COLUMN price_targets.current_amount IS 'What the user currently pays (for calculating actual savings)';
COMMENT ON COLUMN price_targets.contact_preference IS 'How user wants to be contacted about deals: email, push, sms, none';
