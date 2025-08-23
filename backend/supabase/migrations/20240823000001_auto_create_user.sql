-- Add trigger to automatically create users when someone signs up
-- Migration timestamp: 2024-08-23 00:00:01

-- Create trigger function to handle new user signups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert into our custom users table
  INSERT INTO public.users (id, username)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'username', concat('anon-', substr(md5(random()::text), 1, 8))));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- For existing users in auth.users that don't have corresponding records in public.users
-- This handles users who have already signed up but don't have records in our custom table
DO $$
DECLARE
  auth_user RECORD;
BEGIN
  FOR auth_user IN 
    SELECT * FROM auth.users
    WHERE NOT EXISTS (
      SELECT 1 FROM public.users WHERE id = auth.users.id
    )
  LOOP
    INSERT INTO public.users (id, username)
    VALUES (auth_user.id, COALESCE(auth_user.raw_user_meta_data->>'username', concat('anon-', substr(md5(random()::text), 1, 8))));
  END LOOP;
END;
$$ LANGUAGE plpgsql;
