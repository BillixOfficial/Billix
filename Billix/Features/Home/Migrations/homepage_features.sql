-- Homepage Features Migration
-- Created: 2024-12-30
--
-- This migration creates tables for:
-- 1. Referral System - Unique codes, tracking, and bonus management
-- 2. Community Polls - Daily rotating questions with view/vote tracking
-- 3. Utility Checkup - Regional utility signals (aggregate data)

-- ============================================
-- PART 1: REFERRAL SYSTEM
-- ============================================

-- Add referral-related columns to user_profiles
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS referral_code VARCHAR(8) UNIQUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS referred_by_id UUID REFERENCES auth.users(id);
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS referral_count INTEGER DEFAULT 0;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS referral_bonus_claimed BOOLEAN DEFAULT false;

-- Index for fast referral code lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_referral_code
ON user_profiles(referral_code) WHERE referral_code IS NOT NULL;

-- Referral tracking table
CREATE TABLE IF NOT EXISTS referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID NOT NULL REFERENCES auth.users(id),
  referee_id UUID NOT NULL REFERENCES auth.users(id),
  referral_code VARCHAR(8) NOT NULL,
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'rejected')),
  referrer_points_awarded INTEGER DEFAULT 100,
  referee_points_awarded INTEGER DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(referee_id)  -- A user can only be referred once
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer
ON referrals(referrer_id);

CREATE INDEX IF NOT EXISTS idx_referrals_code
ON referrals(referral_code);

-- Function to generate unique referral codes
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';  -- Removed ambiguous chars (0,O,1,I)
  result TEXT := '';
  i INTEGER;
  random_index INTEGER;
BEGIN
  FOR i IN 1..8 LOOP
    random_index := floor(random() * length(chars) + 1)::INTEGER;
    result := result || substr(chars, random_index, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate referral code on user creation
CREATE OR REPLACE FUNCTION auto_generate_referral_code()
RETURNS TRIGGER AS $$
DECLARE
  new_code TEXT;
  attempts INTEGER := 0;
BEGIN
  -- Only generate if referral_code is null
  IF NEW.referral_code IS NULL THEN
    LOOP
      new_code := generate_referral_code();
      attempts := attempts + 1;

      -- Check if code already exists
      IF NOT EXISTS (SELECT 1 FROM user_profiles WHERE referral_code = new_code) THEN
        NEW.referral_code := new_code;
        EXIT;
      END IF;

      -- Safety limit
      IF attempts > 10 THEN
        RAISE EXCEPTION 'Could not generate unique referral code after 10 attempts';
      END IF;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_referral_code ON user_profiles;
CREATE TRIGGER trigger_auto_referral_code
BEFORE INSERT OR UPDATE ON user_profiles
FOR EACH ROW
WHEN (NEW.referral_code IS NULL)
EXECUTE FUNCTION auto_generate_referral_code();

-- Function to process a referral (called when referee completes signup)
CREATE OR REPLACE FUNCTION process_referral(
  p_referee_id UUID,
  p_referral_code VARCHAR(8)
)
RETURNS JSONB AS $$
DECLARE
  v_referrer_id UUID;
  v_referrer_count INTEGER;
  v_bonus_points INTEGER := 0;
  v_result JSONB;
BEGIN
  -- Find the referrer by code
  SELECT user_id, referral_count
  INTO v_referrer_id, v_referrer_count
  FROM user_profiles
  WHERE referral_code = p_referral_code;

  IF v_referrer_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid referral code');
  END IF;

  -- Check if referrer has hit the cap (5 referrals)
  IF v_referrer_count >= 5 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Referrer has reached maximum referrals');
  END IF;

  -- Check if referee was already referred
  IF EXISTS (SELECT 1 FROM referrals WHERE referee_id = p_referee_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'User already has a referrer');
  END IF;

  -- Create referral record
  INSERT INTO referrals (referrer_id, referee_id, referral_code)
  VALUES (v_referrer_id, p_referee_id, p_referral_code);

  -- Update referee's referred_by
  UPDATE user_profiles
  SET referred_by_id = v_referrer_id
  WHERE user_id = p_referee_id;

  -- Update referrer's count
  UPDATE user_profiles
  SET referral_count = referral_count + 1
  WHERE user_id = v_referrer_id
  RETURNING referral_count INTO v_referrer_count;

  -- Check if referrer hit 5 referrals for bonus
  IF v_referrer_count = 5 THEN
    v_bonus_points := 500;
    UPDATE user_profiles
    SET referral_bonus_claimed = true
    WHERE user_id = v_referrer_id;
  END IF;

  -- Award points to referrer (100 base + optional 500 bonus)
  UPDATE user_profiles
  SET points_balance = points_balance + 100 + v_bonus_points
  WHERE user_id = v_referrer_id;

  -- Award points to referee (100)
  UPDATE user_profiles
  SET points_balance = points_balance + 100
  WHERE user_id = p_referee_id;

  RETURN jsonb_build_object(
    'success', true,
    'referrer_points', 100 + v_bonus_points,
    'referee_points', 100,
    'bonus_awarded', v_bonus_points > 0,
    'referrer_total_referrals', v_referrer_count
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 2: COMMUNITY POLLS
-- ============================================

-- Community polls table
CREATE TABLE IF NOT EXISTS community_polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  option_a TEXT NOT NULL,
  option_b TEXT NOT NULL,
  category TEXT CHECK (category IN ('lifestyle', 'spending', 'sustainability', 'provider', 'tech', 'general')),
  view_count INTEGER DEFAULT 0,
  vote_count_a INTEGER DEFAULT 0,
  vote_count_b INTEGER DEFAULT 0,
  active_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(active_date)  -- Only one poll per day
);

CREATE INDEX IF NOT EXISTS idx_community_polls_active_date
ON community_polls(active_date);

-- Poll responses table
CREATE TABLE IF NOT EXISTS poll_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES community_polls(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  selected_option TEXT NOT NULL CHECK (selected_option IN ('a', 'b')),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(poll_id, user_id)  -- One vote per user per poll
);

CREATE INDEX IF NOT EXISTS idx_poll_responses_poll
ON poll_responses(poll_id);

CREATE INDEX IF NOT EXISTS idx_poll_responses_user
ON poll_responses(user_id);

-- Trigger to update vote counts when a response is submitted
CREATE OR REPLACE FUNCTION update_poll_vote_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.selected_option = 'a' THEN
      UPDATE community_polls SET vote_count_a = vote_count_a + 1 WHERE id = NEW.poll_id;
    ELSE
      UPDATE community_polls SET vote_count_b = vote_count_b + 1 WHERE id = NEW.poll_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_poll_vote_count ON poll_responses;
CREATE TRIGGER trigger_poll_vote_count
AFTER INSERT ON poll_responses
FOR EACH ROW
EXECUTE FUNCTION update_poll_vote_count();

-- Function to increment view count (called when poll is displayed)
CREATE OR REPLACE FUNCTION increment_poll_view(p_poll_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE community_polls
  SET view_count = view_count + 1
  WHERE id = p_poll_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get today's poll
CREATE OR REPLACE FUNCTION get_todays_poll()
RETURNS SETOF community_polls AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM community_polls
  WHERE active_date = CURRENT_DATE
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 3: UTILITY CHECKUP (Regional Signals)
-- ============================================

-- Regional utility signals (aggregate data, not personal)
CREATE TABLE IF NOT EXISTS regional_utility_signals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zip_prefix TEXT NOT NULL,  -- First 3 digits (e.g., '070')
  category TEXT NOT NULL CHECK (category IN ('energy', 'gas', 'water', 'internet', 'mobile')),
  signal_type TEXT NOT NULL CHECK (signal_type IN ('stable', 'early_signal', 'cost_pressure', 'limited_data')),
  confidence_level INTEGER DEFAULT 0 CHECK (confidence_level >= 0 AND confidence_level <= 100),
  sample_size INTEGER DEFAULT 0,
  avg_change_percent NUMERIC(5,2),  -- Average % change in recent period
  trend_direction TEXT CHECK (trend_direction IN ('up', 'down', 'flat', 'unknown')),
  insight_text TEXT,  -- Human-readable insight
  data_freshness_days INTEGER DEFAULT 0,  -- How old is the data
  last_updated TIMESTAMPTZ DEFAULT now(),
  UNIQUE(zip_prefix, category)
);

CREATE INDEX IF NOT EXISTS idx_regional_signals_lookup
ON regional_utility_signals(zip_prefix, category);

-- Function to determine signal type based on data
CREATE OR REPLACE FUNCTION calculate_signal_type(
  p_sample_size INTEGER,
  p_avg_change NUMERIC,
  p_confidence INTEGER
)
RETURNS TEXT AS $$
BEGIN
  -- Limited data: Less than 10 samples or very low confidence
  IF p_sample_size < 10 OR p_confidence < 30 THEN
    RETURN 'limited_data';
  END IF;

  -- Cost pressure: Significant increase detected
  IF p_avg_change > 5 AND p_confidence >= 60 THEN
    RETURN 'cost_pressure';
  END IF;

  -- Early signal: Moderate change or moderate confidence
  IF (p_avg_change > 2 AND p_confidence >= 40) OR
     (p_avg_change <= -2 AND p_confidence >= 40) THEN
    RETURN 'early_signal';
  END IF;

  -- Stable: Low change, good confidence
  RETURN 'stable';
END;
$$ LANGUAGE plpgsql;

-- Function to refresh regional signals (called periodically)
CREATE OR REPLACE FUNCTION refresh_regional_signals()
RETURNS void AS $$
BEGIN
  -- This would aggregate data from marketplace_deals and bills
  -- For now, we'll populate with placeholder logic
  INSERT INTO regional_utility_signals (
    zip_prefix, category, signal_type, confidence_level,
    sample_size, avg_change_percent, trend_direction, insight_text
  )
  SELECT
    zip_prefix,
    category,
    calculate_signal_type(COUNT(*)::INTEGER, AVG(monthly_amount),
      CASE WHEN COUNT(*) >= 50 THEN 80 WHEN COUNT(*) >= 20 THEN 60 ELSE 40 END),
    CASE WHEN COUNT(*) >= 50 THEN 80 WHEN COUNT(*) >= 20 THEN 60 ELSE 40 END,
    COUNT(*)::INTEGER,
    0,  -- Would calculate actual change
    'flat',
    'Regional utility data aggregated from community uploads'
  FROM marketplace_deals
  GROUP BY zip_prefix, category
  ON CONFLICT (zip_prefix, category) DO UPDATE SET
    signal_type = EXCLUDED.signal_type,
    confidence_level = EXCLUDED.confidence_level,
    sample_size = EXCLUDED.sample_size,
    last_updated = NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE regional_utility_signals ENABLE ROW LEVEL SECURITY;

-- Referrals: Users can view their own referrals
CREATE POLICY "referrals_select_own" ON referrals
  FOR SELECT USING (
    referrer_id = auth.uid() OR referee_id = auth.uid()
  );

CREATE POLICY "referrals_insert_service" ON referrals
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Community Polls: Anyone can read polls
CREATE POLICY "polls_select_all" ON community_polls
  FOR SELECT USING (true);

-- Poll Responses: Users can see their own and insert their own
CREATE POLICY "poll_responses_select_own" ON poll_responses
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "poll_responses_insert_own" ON poll_responses
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());

-- Regional Signals: Anyone can read aggregate data
CREATE POLICY "regional_signals_select_all" ON regional_utility_signals
  FOR SELECT USING (true);

-- ============================================
-- SEED DATA: Initial Poll Questions
-- ============================================

-- Insert poll questions for the next 30 days (rotating)
INSERT INTO community_polls (question, option_a, option_b, category, active_date)
VALUES
  -- Lifestyle questions
  ('Do you keep your thermostat the same year-round?', 'Yes, consistent', 'No, I adjust seasonally', 'lifestyle', CURRENT_DATE),
  ('Which matters more when picking a provider?', 'Lower price', 'Better service', 'provider', CURRENT_DATE + INTERVAL '1 day'),
  ('Do you track your monthly utility costs?', 'Yes, regularly', 'No, not really', 'spending', CURRENT_DATE + INTERVAL '2 days'),
  ('Would you switch providers to save $20/month?', 'Yes, worth it', 'No, too much hassle', 'provider', CURRENT_DATE + INTERVAL '3 days'),
  ('Do you use smart home devices to save energy?', 'Yes', 'No', 'tech', CURRENT_DATE + INTERVAL '4 days'),
  ('Is your internet speed worth the cost?', 'Yes, fair value', 'No, overpaying', 'spending', CURRENT_DATE + INTERVAL '5 days'),
  ('Do you prefer paperless billing?', 'Yes, digital only', 'No, paper preferred', 'tech', CURRENT_DATE + INTERVAL '6 days'),
  ('Have you ever negotiated a bill down?', 'Yes, successfully', 'No, never tried', 'spending', CURRENT_DATE + INTERVAL '7 days'),
  ('Would you pay more for 100% renewable energy?', 'Yes', 'No', 'sustainability', CURRENT_DATE + INTERVAL '8 days'),
  ('Do you turn off lights when leaving a room?', 'Always', 'Sometimes/Never', 'sustainability', CURRENT_DATE + INTERVAL '9 days'),
  ('Is bundling services worth the discount?', 'Yes, I bundle', 'No, prefer flexibility', 'spending', CURRENT_DATE + INTERVAL '10 days'),
  ('Do you check your utility bills for errors?', 'Every month', 'Rarely/Never', 'spending', CURRENT_DATE + INTERVAL '11 days'),
  ('Would you try a new provider with no contract?', 'Yes, worth trying', 'No, too risky', 'provider', CURRENT_DATE + INTERVAL '12 days'),
  ('Do you think utility companies are transparent?', 'Yes, mostly', 'No, not at all', 'general', CURRENT_DATE + INTERVAL '13 days'),
  ('Have you compared your rates to neighbors?', 'Yes', 'No', 'spending', CURRENT_DATE + INTERVAL '14 days'),
  ('Do you use autopay for bills?', 'Yes, for everything', 'No, manual control', 'tech', CURRENT_DATE + INTERVAL '15 days'),
  ('Would community solar interest you?', 'Yes, sounds great', 'No, not interested', 'sustainability', CURRENT_DATE + INTERVAL '16 days'),
  ('Is your mobile plan a good value?', 'Yes', 'No, paying too much', 'spending', CURRENT_DATE + INTERVAL '17 days'),
  ('Do you care about your utility carbon footprint?', 'Yes, a lot', 'Not really', 'sustainability', CURRENT_DATE + INTERVAL '18 days'),
  ('Would you switch for better customer service?', 'Yes', 'No, price matters more', 'provider', CURRENT_DATE + INTERVAL '19 days'),
  ('Do you use energy during off-peak hours?', 'Yes, intentionally', 'No, whenever needed', 'lifestyle', CURRENT_DATE + INTERVAL '20 days'),
  ('Have utility costs affected your budget?', 'Yes, significantly', 'No, manageable', 'spending', CURRENT_DATE + INTERVAL '21 days'),
  ('Do you know your average kWh usage?', 'Yes', 'No idea', 'general', CURRENT_DATE + INTERVAL '22 days'),
  ('Would you lease solar panels?', 'Yes, interested', 'No, prefer ownership', 'sustainability', CURRENT_DATE + INTERVAL '23 days'),
  ('Is 5G home internet worth considering?', 'Yes', 'No, fiber preferred', 'tech', CURRENT_DATE + INTERVAL '24 days'),
  ('Do you read the fine print on utility contracts?', 'Always', 'Never', 'general', CURRENT_DATE + INTERVAL '25 days'),
  ('Would you join a group buying program?', 'Yes, if savings guaranteed', 'No, too complicated', 'spending', CURRENT_DATE + INTERVAL '26 days'),
  ('Do you trust utility comparison sites?', 'Yes', 'No', 'general', CURRENT_DATE + INTERVAL '27 days'),
  ('Are you satisfied with your current providers?', 'Yes, overall', 'No, would switch', 'provider', CURRENT_DATE + INTERVAL '28 days'),
  ('Do you think energy prices will rise in 2025?', 'Yes, definitely', 'No, will stabilize', 'general', CURRENT_DATE + INTERVAL '29 days')
ON CONFLICT (active_date) DO NOTHING;

-- ============================================
-- SEED DATA: Sample Regional Signals
-- ============================================

INSERT INTO regional_utility_signals (
  zip_prefix, category, signal_type, confidence_level,
  sample_size, avg_change_percent, trend_direction, insight_text
)
VALUES
  ('070', 'energy', 'stable', 75, 142, 1.2, 'flat', 'Energy costs in your area have been stable over the past 90 days'),
  ('070', 'internet', 'early_signal', 55, 89, 3.5, 'up', 'Some users reporting slight increases in internet costs'),
  ('070', 'gas', 'cost_pressure', 68, 67, 8.2, 'up', 'Natural gas costs trending higher this quarter'),
  ('071', 'energy', 'stable', 82, 203, 0.8, 'flat', 'Energy rates remain consistent in this region'),
  ('071', 'mobile', 'limited_data', 25, 8, NULL, 'unknown', 'Not enough data to determine trends'),
  ('072', 'energy', 'early_signal', 61, 95, 4.1, 'up', 'Early signs of rate adjustments in the region'),
  ('072', 'water', 'stable', 70, 54, -0.5, 'down', 'Water costs slightly lower than regional average'),
  ('100', 'energy', 'cost_pressure', 72, 156, 7.5, 'up', 'Energy costs elevated compared to 6 months ago'),
  ('100', 'internet', 'stable', 78, 234, 0.3, 'flat', 'Internet pricing remains competitive in this market'),
  ('100', 'mobile', 'early_signal', 58, 112, 2.8, 'up', 'Mobile carriers adjusting plans in some areas')
ON CONFLICT (zip_prefix, category) DO NOTHING;

COMMIT;
