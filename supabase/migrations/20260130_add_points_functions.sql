-- Atomic function to add points (prevents race conditions)
CREATE OR REPLACE FUNCTION add_user_points(p_user_id TEXT, p_amount INT)
RETURNS TABLE(new_balance INT) AS $$
BEGIN
    UPDATE user_profiles
    SET points = COALESCE(points, 0) + p_amount
    WHERE id = p_user_id::uuid;

    RETURN QUERY
    SELECT points::INT as new_balance
    FROM user_profiles
    WHERE id = p_user_id::uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Atomic function to deduct points (prevents race conditions, enforces minimum 0)
CREATE OR REPLACE FUNCTION deduct_user_points(p_user_id TEXT, p_amount INT)
RETURNS TABLE(new_balance INT) AS $$
BEGIN
    UPDATE user_profiles
    SET points = GREATEST(0, COALESCE(points, 0) - p_amount)
    WHERE id = p_user_id::uuid;

    RETURN QUERY
    SELECT points::INT as new_balance
    FROM user_profiles
    WHERE id = p_user_id::uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION add_user_points(TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION deduct_user_points(TEXT, INT) TO authenticated;
