-- =============================================
-- POLLS SYSTEM MIGRATION
-- Created: 2026-01-02
-- Purpose: Daily community polls for Quick Earnings feature
-- Points: 5pts per poll completion
-- =============================================

-- =============================================
-- TABLE: community_polls
-- Stores daily poll questions with two options
-- =============================================
CREATE TABLE community_polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question TEXT NOT NULL,
    option_a TEXT NOT NULL,
    option_b TEXT NOT NULL,
    category TEXT,
    view_count INT DEFAULT 0,
    vote_count_a INT DEFAULT 0,
    vote_count_b INT DEFAULT 0,
    active_date DATE NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- TABLE: poll_responses
-- Stores user votes (one vote per user per poll)
-- =============================================
CREATE TABLE poll_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID REFERENCES community_polls(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    selected_option TEXT CHECK (selected_option IN ('a', 'b')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(poll_id, user_id)
);

-- =============================================
-- INDEX: Optimize daily poll lookup
-- =============================================
CREATE INDEX idx_polls_active_date ON community_polls(active_date);
CREATE INDEX idx_poll_responses_user_id ON poll_responses(user_id);
CREATE INDEX idx_poll_responses_poll_id ON poll_responses(poll_id);

-- =============================================
-- RLS POLICIES
-- =============================================
ALTER TABLE community_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_responses ENABLE ROW LEVEL SECURITY;

-- Anyone can view polls
CREATE POLICY "Anyone can view polls"
ON community_polls FOR SELECT
USING (true);

-- Users can view their own responses
CREATE POLICY "Users view own responses"
ON poll_responses FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own responses
CREATE POLICY "Users insert own responses"
ON poll_responses FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- =============================================
-- TRIGGER: Auto-update vote counts
-- =============================================
CREATE OR REPLACE FUNCTION update_poll_vote_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.selected_option = 'a' THEN
        UPDATE community_polls
        SET vote_count_a = vote_count_a + 1
        WHERE id = NEW.poll_id;
    ELSIF NEW.selected_option = 'b' THEN
        UPDATE community_polls
        SET vote_count_b = vote_count_b + 1
        WHERE id = NEW.poll_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_update_poll_vote_counts
AFTER INSERT ON poll_responses
FOR EACH ROW EXECUTE FUNCTION update_poll_vote_counts();

-- =============================================
-- SEED DATA: 30 Daily Polls (Jan 1-30, 2026)
-- =============================================

INSERT INTO community_polls (question, option_a, option_b, category, active_date) VALUES
-- Week 1: Saving & Budgeting
('Would you rather...', 'Save $1000 now', 'Save $100/month for a year', 'finance', '2026-01-01'),
('What''s your biggest money challenge?', 'Sticking to my budget', 'Building emergency fund', 'budgeting', '2026-01-02'),
('How do you track expenses?', 'Mobile app', 'Spreadsheet/paper', 'budgeting', '2026-01-03'),
('Which savings goal is more important?', 'Emergency fund (3-6 months)', 'Retirement contributions', 'saving', '2026-01-04'),
('When grocery shopping, do you...', 'Always use a list', 'Buy what looks good', 'shopping', '2026-01-05'),
('Your approach to dining out?', 'Special occasions only', 'Weekly treat yourself', 'lifestyle', '2026-01-06'),
('Coffee habits?', 'Make at home', 'Buy from café', 'lifestyle', '2026-01-07'),

-- Week 2: Spending & Lifestyle
('Subscription services: Do you...', 'Review and cancel unused', 'Keep them all active', 'spending', '2026-01-08'),
('When you get unexpected money...', 'Save it immediately', 'Treat yourself first', 'finance', '2026-01-09'),
('How often do you check your bank balance?', 'Daily or weekly', 'Monthly or less', 'budgeting', '2026-01-10'),
('Online shopping: Do you...', 'Wait 24hrs before buying', 'Buy immediately if you like it', 'shopping', '2026-01-11'),
('Which would you eliminate first?', 'Streaming services', 'Food delivery apps', 'spending', '2026-01-12'),
('Your credit card strategy?', 'Pay off monthly (no interest)', 'Carry a balance sometimes', 'finance', '2026-01-13'),
('Brand loyalty: Do you...', 'Always buy generic/store brand', 'Prefer name brands', 'shopping', '2026-01-14'),

-- Week 3: Goals & Priorities
('Side hustle or main job raise?', '$500/month side income', '$500/year salary raise', 'income', '2026-01-15'),
('Financial education: You prefer...', 'Books and podcasts', 'YouTube and TikTok', 'learning', '2026-01-16'),
('Splitting bills with friends?', 'Split evenly always', 'Pay for what you ordered', 'social', '2026-01-17'),
('Tax refund approach?', 'Put it all in savings', 'Spend half, save half', 'finance', '2026-01-18'),
('Impulse purchase limit?', 'Under $20 is okay', 'Under $50 is fine', 'spending', '2026-01-19'),
('Shopping for clothes?', 'Thrift/secondhand first', 'New from stores', 'shopping', '2026-01-20'),
('Bill payments: Do you...', 'Automate everything', 'Manually pay each one', 'budgeting', '2026-01-21'),

-- Week 4: Future Planning
('Retirement planning: You are...', 'Already contributing regularly', 'Planning to start soon', 'retirement', '2026-01-22'),
('Cash or card for daily spending?', 'Mostly cash', 'Mostly card/digital', 'spending', '2026-01-23'),
('Financial goal for this year?', 'Save $5,000+', 'Pay off debt', 'goals', '2026-01-24'),
('Your budgeting style?', 'Strict categories & limits', 'Flexible spending awareness', 'budgeting', '2026-01-25'),
('Investing: Are you...', 'Already investing regularly', 'Researching how to start', 'investing', '2026-01-26'),
('When buying expensive items...', 'Research for weeks', 'Decide within a day', 'shopping', '2026-01-27'),
('Entertainment spending?', 'Budget $50-100/month', 'No specific budget', 'lifestyle', '2026-01-28'),
('Financial apps: Do you use...', '3+ money management apps', '1-2 apps or none', 'tech', '2026-01-29'),
('Your 2026 money mantra?', 'Save more, spend less', 'Earn more, invest smarter', 'goals', '2026-01-30');

-- =============================================
-- VERIFICATION QUERIES
-- =============================================
-- SELECT COUNT(*) FROM community_polls; -- Should be 30
-- SELECT * FROM community_polls ORDER BY active_date;
-- SELECT * FROM community_polls WHERE active_date = CURRENT_DATE;
