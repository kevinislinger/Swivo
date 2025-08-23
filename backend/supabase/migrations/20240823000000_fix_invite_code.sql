-- Fix invite code constraint and function
-- Migration timestamp: 2024-08-23 00:00:00

-- 1. Alter the invite_code_format constraint
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS invite_code_format;
ALTER TABLE sessions ADD CONSTRAINT invite_code_format CHECK (length(invite_code) BETWEEN 5 AND 6);

-- 2. Drop and recreate the create_session function with fixed invite code generation
CREATE OR REPLACE FUNCTION create_session(
  p_category_id UUID,
  p_quorum_n INTEGER DEFAULT 2
) RETURNS JSON AS $$
DECLARE
  v_session_id UUID;
  v_invite_code TEXT;
  v_session_record sessions%ROWTYPE;
BEGIN
  -- Generate a random 6-character invite code
  v_invite_code := upper(substr(md5(random()::text), 1, 6));
  
  -- Ensure the invite code is exactly 6 characters by padding if needed
  WHILE length(v_invite_code) < 6 LOOP
    v_invite_code := v_invite_code || upper(substr(md5(random()::text), 1, 1));
  END LOOP;
  
  -- Create the session
  INSERT INTO sessions (
    creator_id,
    category_id,
    quorum_n,
    invite_code
  ) VALUES (
    auth.uid(),
    p_category_id,
    p_quorum_n,
    v_invite_code
  ) RETURNING id INTO v_session_id;
  
  -- Add the creator as a participant
  INSERT INTO session_participants (
    session_id,
    user_id
  ) VALUES (
    v_session_id,
    auth.uid()
  );
  
  -- Create session options
  INSERT INTO session_options (
    session_id,
    option_id,
    order_index
  )
  SELECT 
    v_session_id,
    id,
    row_number() OVER (ORDER BY random())
  FROM options
  WHERE category_id = p_category_id;
  
  -- Get the created session
  SELECT * INTO v_session_record FROM sessions WHERE id = v_session_id;
  
  -- Return session details as JSON
  RETURN json_build_object(
    'session_id', v_session_id,
    'invite_code', v_invite_code,
    'created_at', v_session_record.created_at
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
