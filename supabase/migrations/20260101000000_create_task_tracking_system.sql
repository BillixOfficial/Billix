-- Task Tracking System Migration
-- Creates tables, indexes, RLS policies for comprehensive task tracking
-- Version: 1.0
-- Date: 2026-01-01

BEGIN;

-- =====================================================
-- 1. CREATE TABLES
-- =====================================================

-- Table: task_definitions
-- Defines all available tasks in the system (seeded data)
CREATE TABLE IF NOT EXISTS task_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_key TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,  -- 'daily', 'weekly', 'unlimited', 'one_time'
    task_type TEXT NOT NULL,  -- 'check_in', 'bill_upload', 'poll', 'quiz', 'tip', 'game', 'referral', 'social'
    points INT NOT NULL,
    icon_name TEXT,
    custom_image TEXT,
    icon_color TEXT,
    cta_text TEXT NOT NULL,  -- "Start", "Vote now >", etc.

    -- Reset configuration
    reset_type TEXT NOT NULL,  -- 'daily', 'weekly', 'never'
    reset_day_of_week INT,  -- 0=Sunday for weekly tasks

    -- Progress tracking
    requires_count INT DEFAULT 1,  -- e.g., 5 for "upload 5 bills"

    -- Metadata
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table: user_task_completions
-- Event log of all task completion events
CREATE TABLE IF NOT EXISTS user_task_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    task_key TEXT NOT NULL REFERENCES task_definitions(task_key),

    -- Completion tracking
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    claimed_at TIMESTAMPTZ,  -- NULL = completed but not claimed
    points_awarded INT,

    -- Progress context (for multi-step tasks)
    progress_count INT DEFAULT 1,  -- For tasks like "5 bills"

    -- Metadata for tracking
    source_id UUID,  -- Reference to bill upload, game session, etc.
    metadata JSONB,  -- Flexible storage for extra data

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table: user_task_progress
-- Tracks progress toward multi-step tasks (e.g., "upload 5 bills this week")
CREATE TABLE IF NOT EXISTS user_task_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    task_key TEXT NOT NULL REFERENCES task_definitions(task_key),

    -- Progress tracking
    current_count INT DEFAULT 0,
    required_count INT NOT NULL,

    -- Reset tracking
    period_start TIMESTAMPTZ NOT NULL,  -- Start of current period (day/week)
    period_end TIMESTAMPTZ NOT NULL,    -- End of current period

    -- Status
    is_completed BOOLEAN DEFAULT false,
    is_claimed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    claimed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure one progress record per user per task per period
    UNIQUE(user_id, task_key, period_start)
);

-- Table: user_streaks
-- Tracks daily login streaks and milestones
CREATE TABLE IF NOT EXISTS user_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Streak tracking
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    last_check_in DATE,

    -- Milestones
    total_check_ins INT DEFAULT 0,
    milestone_7_days BOOLEAN DEFAULT false,
    milestone_30_days BOOLEAN DEFAULT false,
    milestone_100_days BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id)
);

-- =====================================================
-- 2. CREATE INDEXES
-- =====================================================

-- Indexes for task_definitions
CREATE INDEX IF NOT EXISTS idx_task_definitions_category ON task_definitions(category);
CREATE INDEX IF NOT EXISTS idx_task_definitions_active ON task_definitions(is_active);
CREATE INDEX IF NOT EXISTS idx_task_definitions_sort ON task_definitions(sort_order);

-- Indexes for user_task_completions
CREATE INDEX IF NOT EXISTS idx_user_completions_user ON user_task_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_completions_task ON user_task_completions(task_key);
CREATE INDEX IF NOT EXISTS idx_user_completions_date ON user_task_completions(completed_at);
CREATE INDEX IF NOT EXISTS idx_user_completions_claimed ON user_task_completions(claimed_at);
CREATE INDEX IF NOT EXISTS idx_user_completions_user_task ON user_task_completions(user_id, task_key);
CREATE INDEX IF NOT EXISTS idx_user_completions_reset ON user_task_completions(user_id, task_key, completed_at);

-- Indexes for user_task_progress
CREATE INDEX IF NOT EXISTS idx_task_progress_user ON user_task_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_task_progress_period ON user_task_progress(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_task_progress_active ON user_task_progress(user_id, is_claimed) WHERE is_claimed = false;
CREATE INDEX IF NOT EXISTS idx_task_progress_user_task ON user_task_progress(user_id, task_key);

-- Indexes for user_streaks
CREATE INDEX IF NOT EXISTS idx_user_streaks_user ON user_streaks(user_id);

-- =====================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE task_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_task_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_task_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4. CREATE RLS POLICIES
-- =====================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view active tasks" ON task_definitions;
DROP POLICY IF EXISTS "Users can view own completions" ON user_task_completions;
DROP POLICY IF EXISTS "Users can insert own completions" ON user_task_completions;
DROP POLICY IF EXISTS "Users can view own progress" ON user_task_progress;
DROP POLICY IF EXISTS "Users can modify own progress" ON user_task_progress;
DROP POLICY IF EXISTS "Users can view own streaks" ON user_streaks;
DROP POLICY IF EXISTS "Users can modify own streaks" ON user_streaks;

-- task_definitions: Public read for active tasks
CREATE POLICY "Anyone can view active tasks"
ON task_definitions FOR SELECT
USING (is_active = true);

-- user_task_completions: Users see only their own
CREATE POLICY "Users can view own completions"
ON user_task_completions FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own completions"
ON user_task_completions FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- user_task_progress: Users see only their own
CREATE POLICY "Users can view own progress"
ON user_task_progress FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can modify own progress"
ON user_task_progress FOR ALL
USING (auth.uid() = user_id);

-- user_streaks: Users see only their own
CREATE POLICY "Users can view own streaks"
ON user_streaks FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can modify own streaks"
ON user_streaks FOR ALL
USING (auth.uid() = user_id);

-- =====================================================
-- 5. SEED TASK DEFINITIONS
-- =====================================================

INSERT INTO task_definitions (task_key, title, description, category, task_type, points, icon_name, custom_image, icon_color, cta_text, reset_type, requires_count, sort_order) VALUES

-- DAILY TASKS
('daily_check_in', 'Check in today', 'Tap to earn your daily bonus and build your streak', 'daily', 'check_in', 50, 'checkmark.circle.fill', NULL, '#10B981', 'Check In', 'daily', 1, 1),
('daily_upload_bill', 'Upload a bill', 'Scan or quick add a bill to track your expenses', 'daily', 'bill_upload', 200, 'doc.fill', NULL, '#3B82F6', 'Upload Bill', 'daily', 1, 2),

-- QUICK EARNINGS (Daily reset)
('daily_poll_vote', 'Share your opinion', 'Vote in the daily poll to see what other members think', 'daily', 'poll', 5, 'chart.bar.fill', 'BarGraph', '#3B82F6', 'Vote now >', 'daily', 1, 10),
('daily_read_tip', 'Save smarter', 'Read today''s quick tip to help you manage your budget better', 'daily', 'tip', 10, 'lightbulb.fill', 'LightBulbMoney', '#F59E0B', 'Read tip >', 'daily', 1, 11),
('daily_complete_quiz', 'Test your knowledge', 'Answer three quick trivia questions to earn bonus points', 'daily', 'quiz', 15, 'graduationcap.fill', 'GraduationCap', '#8B5CF6', 'Start quiz >', 'daily', 1, 12),

-- ONE-TIME TASKS
('one_time_follow_social', 'Stay connected', 'Follow our page to get the latest updates and bonus codes', 'one_time', 'social', 5, 'heart.fill', 'FollowHeart', '#EC4899', 'Follow us >', 'never', 1, 20),

-- WEEKLY TASKS
('weekly_upload_5_bills', 'Upload 5 bills', 'Upload 5 bills this week to earn a big bonus', 'weekly', 'bill_upload', 1000, 'doc.on.doc.fill', NULL, '#10B981', 'Upload Bills', 'weekly', 5, 30),
('weekly_play_7_games', 'Play Price Guessr 7x', 'Play Price Guessr 7 times this week to earn bonus points', 'weekly', 'game', 500, 'gamecontroller.fill', NULL, '#F59E0B', 'Play Now', 'weekly', 7, 31),

-- UNLIMITED TASKS
('unlimited_refer_friend', 'Refer a friend', 'Invite a friend to join Billix and earn big rewards', 'unlimited', 'referral', 2000, 'person.2.fill', NULL, '#8B5CF6', 'Invite Friend', 'never', 1, 40)

ON CONFLICT (task_key) DO NOTHING;

COMMIT;

-- =====================================================
-- NOTES
-- =====================================================
-- Database functions are too long for single migration.
-- Create them separately using Supabase SQL Editor:
-- 1. get_user_tasks()
-- 2. increment_task_progress()
-- 3. claim_task_reward()
-- 4. check_in_daily()
