-- Swivo App Triggers and Functions

-- Trigger function to prevent joining a session when it's full
CREATE OR REPLACE FUNCTION check_session_participant_limit()
RETURNS TRIGGER AS $$
DECLARE
  current_count INTEGER;
  max_participants INTEGER;
BEGIN
  -- Get the current number of participants
  SELECT COUNT(*) INTO current_count
  FROM session_participants
  WHERE session_id = NEW.session_id;
  
  -- Get the quorum_n (maximum participants)
  SELECT quorum_n INTO max_participants
  FROM sessions
  WHERE id = NEW.session_id;
  
  -- Check if adding this participant would exceed the limit
  IF current_count >= max_participants THEN
    RAISE EXCEPTION 'Session is full: participant count (%) has reached the quorum limit (%)', 
                    current_count, max_participants;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to session_participants table
DROP TRIGGER IF EXISTS enforce_session_participant_limit ON session_participants;
CREATE TRIGGER enforce_session_participant_limit
BEFORE INSERT ON session_participants
FOR EACH ROW
EXECUTE FUNCTION check_session_participant_limit();

-- Trigger function for matching algorithm
CREATE OR REPLACE FUNCTION check_match_on_like()
RETURNS TRIGGER AS $$
DECLARE
  quorum_n INTEGER;
  like_count INTEGER;
BEGIN
  -- Get the quorum_n for this session
  SELECT s.quorum_n INTO quorum_n
  FROM sessions s
  WHERE s.id = NEW.session_id;
  
  -- Count likes for this option in this session
  SELECT COUNT(DISTINCT l.user_id) INTO like_count
  FROM likes l
  WHERE l.session_id = NEW.session_id AND l.option_id = NEW.option_id;
  
  -- If we've reached the quorum, update the session as matched
  IF like_count >= quorum_n THEN
    UPDATE sessions
    SET status = 'matched',
        matched_option_id = NEW.option_id,
        matched_at = NOW()
    WHERE id = NEW.session_id AND status = 'open';
    
    -- Here we would call an edge function to send notifications
    -- This will be implemented separately
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to likes table
DROP TRIGGER IF EXISTS check_match_trigger ON likes;
CREATE TRIGGER check_match_trigger
AFTER INSERT ON likes
FOR EACH ROW
EXECUTE FUNCTION check_match_on_like();
