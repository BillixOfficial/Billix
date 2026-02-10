-- Update BillSwap Tier Requirements & Billix Score
-- Changes progression from 3→10→25 to 5→15→35→50
-- Adds Billix Score increment (+2 per successful swap)

-- ============================================
-- UPDATE TIER PROGRESSION FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_swap_tier()
RETURNS TRIGGER AS $$
BEGIN
    -- Only on swap completion
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Update both users' trust records with HARDER requirements
        -- Tier progression: 5 → 15 → 35 → 50 swaps
        UPDATE swap_trust
        SET
            total_swaps = total_swaps + 1,
            successful_swaps = successful_swaps + 1,
            trust_points = trust_points + 10,
            tier = CASE
                WHEN successful_swaps + 1 >= 50 AND disputed_swaps = 0 THEN 4  -- Veteran
                WHEN successful_swaps + 1 >= 35 AND disputed_swaps = 0 THEN 3  -- Trusted
                WHEN successful_swaps + 1 >= 15 AND disputed_swaps = 0 THEN 2  -- Established
                WHEN successful_swaps + 1 >= 5 AND disputed_swaps = 0 THEN 2   -- Established
                ELSE tier
            END,
            updated_at = NOW()
        WHERE user_id IN (NEW.user_a_id, NEW.user_b_id);

        -- INCREMENT BILLIX SCORE (+2 per successful swap, max 100)
        -- This updates the profiles table which is displayed on the profile page
        UPDATE profiles
        SET
            trust_score = LEAST(100, COALESCE(trust_score, 0) + 2),
            updated_at = NOW()
        WHERE user_id IN (NEW.user_a_id, NEW.user_b_id);
    END IF;

    -- On dispute - keep existing logic
    IF NEW.status = 'dispute' AND OLD.status != 'dispute' THEN
        UPDATE swap_trust
        SET
            disputed_swaps = disputed_swaps + 1,
            trust_points = GREATEST(0, trust_points - 50),
            eligibility_locked_until = NOW() + INTERVAL '7 days',
            tier = GREATEST(1, tier - 1),
            updated_at = NOW()
        WHERE user_id IN (NEW.user_a_id, NEW.user_b_id);

        -- Also reduce Billix Score on dispute (-10 points)
        UPDATE profiles
        SET
            trust_score = GREATEST(0, COALESCE(trust_score, 0) - 10),
            updated_at = NOW()
        WHERE user_id IN (NEW.user_a_id, NEW.user_b_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION TO GET SWAPS NEEDED FOR NEXT TIER
-- ============================================

CREATE OR REPLACE FUNCTION get_swaps_for_next_tier(p_user_id UUID)
RETURNS INT AS $$
DECLARE
    user_tier INT;
    user_swaps INT;
    next_tier_requirement INT;
BEGIN
    SELECT tier, successful_swaps INTO user_tier, user_swaps
    FROM swap_trust WHERE user_id = p_user_id;

    -- Tier requirements: 5 → 15 → 35 → 50
    next_tier_requirement := CASE user_tier
        WHEN 1 THEN 5    -- Need 5 for Tier 2
        WHEN 2 THEN 15   -- Need 15 for Tier 3
        WHEN 3 THEN 35   -- Need 35 for Tier 4
        WHEN 4 THEN 50   -- Already max (Veteran)
        ELSE 5
    END;

    RETURN GREATEST(0, next_tier_requirement - COALESCE(user_swaps, 0));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_swaps_for_next_tier(UUID) TO authenticated;

-- ============================================
-- RESET EXISTING USERS' BILLIX SCORES TO 0
-- (Fresh start as per user requirement)
-- ============================================

UPDATE profiles SET trust_score = 0 WHERE trust_score IS NULL OR trust_score > 0;
