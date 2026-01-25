-- Household Feature Database Migrations
-- Run these migrations in order to set up the Household feature tables

-- Migration 1: households table
CREATE TABLE IF NOT EXISTS households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  invite_code TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(6), 'hex'),
  head_of_household_id UUID REFERENCES auth.users(id),
  collective_trust_score INTEGER DEFAULT 0,
  max_members INTEGER DEFAULT 10,
  auto_pilot_enabled BOOLEAN DEFAULT false,
  fairness_mode TEXT DEFAULT 'equal' CHECK (fairness_mode IN ('equal', 'custom', 'income_based')),
  created_at TIMESTAMPTZ DEFAULT now(),
  is_active BOOLEAN DEFAULT true
);

-- Migration 2: household_members table
CREATE TABLE IF NOT EXISTS household_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('head', 'admin', 'member')),
  display_name TEXT,
  karma_score INTEGER DEFAULT 0,
  monthly_karma INTEGER DEFAULT 0,
  equity_percentage DECIMAL(5,2) DEFAULT NULL,
  joined_at TIMESTAMPTZ DEFAULT now(),
  left_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  UNIQUE(household_id, user_id)
);

-- Migration 3: household_bills table
CREATE TABLE IF NOT EXISTS household_bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  swap_bill_id UUID REFERENCES swap_bills(id) ON DELETE CASCADE,
  owner_id UUID REFERENCES auth.users(id),
  visibility TEXT DEFAULT 'household' CHECK (visibility IN ('personal', 'household', 'public')),
  is_shared BOOLEAN DEFAULT true,
  escalation_stage INTEGER DEFAULT 0, -- 0=internal, 1=alerted, 2=public
  escalation_started_at TIMESTAMPTZ,
  auto_pilot_enabled BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Migration 4: karma_events table
CREATE TABLE IF NOT EXISTS karma_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN (
    'internal_swap_completed', 'bill_paid_on_time', 'helped_roommate',
    'uploaded_shared_bill', 'nudge_responded', 'auto_pilot_save'
  )),
  karma_change INTEGER NOT NULL,
  description TEXT,
  related_bill_id UUID,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Migration 5: vault_documents table
CREATE TABLE IF NOT EXISTS vault_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  uploader_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  document_type TEXT CHECK (document_type IN ('lease', 'utility_bill', 'insurance', 'other')),
  file_url TEXT NOT NULL,
  access_level TEXT DEFAULT 'all' CHECK (access_level IN ('all', 'admin_only', 'owner_only')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Migration 6: nudge_reminders table
CREATE TABLE IF NOT EXISTS nudge_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  from_user_id UUID REFERENCES auth.users(id),
  to_user_id UUID REFERENCES auth.users(id),
  bill_id UUID REFERENCES household_bills(id),
  message TEXT,
  is_read BOOLEAN DEFAULT false,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE karma_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE vault_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE nudge_reminders ENABLE ROW LEVEL SECURITY;

-- RLS Policies for households
CREATE POLICY "Users can view households they belong to" ON households
  FOR SELECT USING (
    id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid() AND is_active = true AND left_at IS NULL
    )
  );

CREATE POLICY "Users can create households" ON households
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can update their households" ON households
  FOR UPDATE USING (
    id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid() AND role IN ('head', 'admin') AND is_active = true
    )
  );

-- RLS Policies for household_members
CREATE POLICY "Members can view household members" ON household_members
  FOR SELECT USING (
    household_id IN (
      SELECT household_id FROM household_members hm
      WHERE hm.user_id = auth.uid() AND hm.is_active = true AND hm.left_at IS NULL
    )
  );

CREATE POLICY "Users can join households" ON household_members
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own membership" ON household_members
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Admins can update member roles" ON household_members
  FOR UPDATE USING (
    household_id IN (
      SELECT household_id FROM household_members hm
      WHERE hm.user_id = auth.uid() AND hm.role IN ('head', 'admin') AND hm.is_active = true
    )
  );

-- RLS Policies for household_bills
CREATE POLICY "Members can view household bills" ON household_bills
  FOR SELECT USING (
    household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid() AND is_active = true AND left_at IS NULL
    )
    OR owner_id = auth.uid()
  );

CREATE POLICY "Owners can manage their bills" ON household_bills
  FOR ALL USING (owner_id = auth.uid());

-- RLS Policies for karma_events
CREATE POLICY "Members can view karma events" ON karma_events
  FOR SELECT USING (
    household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid() AND is_active = true AND left_at IS NULL
    )
  );

CREATE POLICY "System can insert karma events" ON karma_events
  FOR INSERT WITH CHECK (
    household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- RLS Policies for vault_documents
CREATE POLICY "Members can view accessible documents" ON vault_documents
  FOR SELECT USING (
    household_id IN (
      SELECT household_id FROM household_members hm
      WHERE hm.user_id = auth.uid() AND hm.is_active = true AND hm.left_at IS NULL
    )
    AND (
      access_level = 'all'
      OR (access_level = 'admin_only' AND EXISTS (
        SELECT 1 FROM household_members hm
        WHERE hm.household_id = vault_documents.household_id
          AND hm.user_id = auth.uid()
          AND hm.role IN ('head', 'admin')
      ))
      OR (access_level = 'owner_only' AND uploader_id = auth.uid())
    )
  );

CREATE POLICY "Members can upload documents" ON vault_documents
  FOR INSERT WITH CHECK (
    uploader_id = auth.uid()
    AND household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "Owners can delete their documents" ON vault_documents
  FOR DELETE USING (uploader_id = auth.uid());

-- RLS Policies for nudge_reminders
CREATE POLICY "Users can view their nudges" ON nudge_reminders
  FOR SELECT USING (
    from_user_id = auth.uid() OR to_user_id = auth.uid()
  );

CREATE POLICY "Members can send nudges" ON nudge_reminders
  FOR INSERT WITH CHECK (
    from_user_id = auth.uid()
    AND household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "Recipients can update nudges" ON nudge_reminders
  FOR UPDATE USING (to_user_id = auth.uid());

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_household_members_household ON household_members(household_id);
CREATE INDEX IF NOT EXISTS idx_household_members_user ON household_members(user_id);
CREATE INDEX IF NOT EXISTS idx_household_bills_household ON household_bills(household_id);
CREATE INDEX IF NOT EXISTS idx_karma_events_household ON karma_events(household_id);
CREATE INDEX IF NOT EXISTS idx_karma_events_user ON karma_events(user_id);
CREATE INDEX IF NOT EXISTS idx_vault_documents_household ON vault_documents(household_id);
CREATE INDEX IF NOT EXISTS idx_nudge_reminders_to_user ON nudge_reminders(to_user_id);

-- Function to update collective trust score
CREATE OR REPLACE FUNCTION update_household_trust_score()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE households
  SET collective_trust_score = (
    SELECT COALESCE(AVG(karma_score), 0)::INTEGER
    FROM household_members
    WHERE household_id = NEW.household_id AND is_active = true
  )
  WHERE id = NEW.household_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update trust score when karma changes
CREATE TRIGGER update_trust_score_on_karma_change
  AFTER INSERT OR UPDATE OF karma_score ON household_members
  FOR EACH ROW
  EXECUTE FUNCTION update_household_trust_score();

-- Function to reset monthly karma (run via cron at month start)
CREATE OR REPLACE FUNCTION reset_monthly_karma()
RETURNS void AS $$
BEGIN
  UPDATE household_members
  SET monthly_karma = 0
  WHERE is_active = true;
END;
$$ LANGUAGE plpgsql;
