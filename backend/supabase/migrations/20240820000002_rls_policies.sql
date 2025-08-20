-- This migration adds Row Level Security policies for the Swivo app
-- Migration timestamp: 2024-08-20 00:00:02

-- Enable Row Level Security for all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE options ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- Create helper function to check if user is a session participant
CREATE OR REPLACE FUNCTION is_session_participant(session_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM session_participants
    WHERE session_id = session_uuid
    AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create helper function to check if user is a session creator
CREATE OR REPLACE FUNCTION is_session_creator(session_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM sessions
    WHERE id = session_uuid
    AND creator_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Users policies
-- Users can read their own profile and other users' info in the same session
CREATE POLICY users_select_policy ON users
  FOR SELECT USING (
    id = auth.uid() OR 
    EXISTS (
      SELECT 1 FROM session_participants sp
      WHERE sp.user_id = users.id
      AND EXISTS (
        SELECT 1 FROM session_participants sp2
        WHERE sp2.session_id = sp.session_id
        AND sp2.user_id = auth.uid()
      )
    )
  );

-- Users can update only their own profile
CREATE POLICY users_update_policy ON users
  FOR UPDATE USING (id = auth.uid());

-- Categories policies
-- Anyone can read categories
CREATE POLICY categories_select_policy ON categories
  FOR SELECT USING (true);

-- Sessions policies
-- Users can see sessions they created or participate in
CREATE POLICY sessions_select_policy ON sessions
  FOR SELECT USING (
    creator_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM session_participants sp
      WHERE sp.session_id = sessions.id
      AND sp.user_id = auth.uid()
    )
  );

-- Only the creator can update their session
CREATE POLICY sessions_update_policy ON sessions
  FOR UPDATE USING (creator_id = auth.uid());

-- Anyone can insert a new session
CREATE POLICY sessions_insert_policy ON sessions
  FOR INSERT WITH CHECK (creator_id = auth.uid());

-- Session participants policies
-- Participants can see who's in their sessions
CREATE POLICY session_participants_select_policy ON session_participants
  FOR SELECT USING (
    is_session_participant(session_id) OR
    is_session_creator(session_id)
  );

-- Options policies
-- Anyone can read options
CREATE POLICY options_select_policy ON options
  FOR SELECT USING (true);

-- Session options policies
-- Users can see options for sessions they're in
CREATE POLICY session_options_select_policy ON session_options
  FOR SELECT USING (
    is_session_participant(session_id) OR
    is_session_creator(session_id)
  );

-- Likes policies
-- Users can see likes for sessions they're in
CREATE POLICY likes_select_policy ON likes
  FOR SELECT USING (
    is_session_participant(session_id) OR
    is_session_creator(session_id)
  );

-- Users can only insert likes for sessions they're in
CREATE POLICY likes_insert_policy ON likes
  FOR INSERT WITH CHECK (
    user_id = auth.uid() AND
    is_session_participant(session_id)
  );
