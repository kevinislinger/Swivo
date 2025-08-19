-- Swivo App Helper Functions

-- Function to create a new session
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
  v_invite_code := upper(substr(md5(random()::text), 0, 6));
  
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

-- Function to join a session by invite code
CREATE OR REPLACE FUNCTION join_session(
  p_invite_code TEXT
) RETURNS JSON AS $$
DECLARE
  v_session_id UUID;
  v_session_status session_status;
  v_matched_option_id UUID;
BEGIN
  -- Find the session
  SELECT id, status, matched_option_id 
  INTO v_session_id, v_session_status, v_matched_option_id
  FROM sessions
  WHERE invite_code = upper(p_invite_code);
  
  -- Check if session exists
  IF v_session_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Session not found'
    );
  END IF;
  
  -- Check if session is still open
  IF v_session_status != 'open' THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Session is ' || v_session_status::text,
      'session_id', v_session_id,
      'matched_option_id', v_matched_option_id
    );
  END IF;
  
  -- Try to join the session
  BEGIN
    INSERT INTO session_participants (
      session_id,
      user_id
    ) VALUES (
      v_session_id,
      auth.uid()
    );
    
    RETURN json_build_object(
      'success', true,
      'session_id', v_session_id
    );
  EXCEPTION WHEN OTHERS THEN
    -- Handle errors (like session full, already joined, etc)
    RETURN json_build_object(
      'success', false,
      'message', SQLERRM
    );
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to like an option
CREATE OR REPLACE FUNCTION like_option(
  p_session_id UUID,
  p_option_id UUID
) RETURNS JSON AS $$
DECLARE
  v_session_status session_status;
  v_matched_option_id UUID;
  v_match_found BOOLEAN := false;
BEGIN
  -- Check if session is open
  SELECT status, matched_option_id INTO v_session_status, v_matched_option_id
  FROM sessions
  WHERE id = p_session_id;
  
  IF v_session_status != 'open' THEN
    RETURN json_build_object(
      'success', false,
      'match_found', true,
      'matched_option_id', v_matched_option_id,
      'message', 'Session is already ' || v_session_status::text
    );
  END IF;
  
  -- Insert like
  BEGIN
    INSERT INTO likes (
      session_id,
      option_id,
      user_id
    ) VALUES (
      p_session_id,
      p_option_id,
      auth.uid()
    );
  EXCEPTION WHEN unique_violation THEN
    -- Like already exists, ignore
    NULL;
  END;
  
  -- Check if session status changed to matched after our like
  -- This happens via the trigger we created
  SELECT status = 'matched', matched_option_id INTO v_match_found, v_matched_option_id
  FROM sessions
  WHERE id = p_session_id;
  
  RETURN json_build_object(
    'success', true,
    'match_found', v_match_found,
    'matched_option_id', v_matched_option_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update APNS token
CREATE OR REPLACE FUNCTION update_apns_token(
  p_token TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE users
  SET apns_token = p_token
  WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to close a session (for session creator)
CREATE OR REPLACE FUNCTION close_session(
  p_session_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
  v_is_creator BOOLEAN;
BEGIN
  -- Check if user is the creator
  SELECT creator_id = auth.uid() INTO v_is_creator
  FROM sessions
  WHERE id = p_session_id;
  
  IF NOT v_is_creator THEN
    RETURN false;
  END IF;
  
  -- Close the session
  UPDATE sessions
  SET status = 'closed'
  WHERE id = p_session_id AND creator_id = auth.uid();
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
