-- Swivo App Sample Data

-- Sample categories
INSERT INTO categories (id, name, icon_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Restaurants', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Movies', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Activities', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Games', '')
ON CONFLICT (name) DO NOTHING;

-- Restaurant options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Italian', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Japanese', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Mexican', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Chinese', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Thai', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Indian', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Greek', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'French', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Korean', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'American', '');

-- Movie options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Action', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Comedy', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Drama', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Horror', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Sci-Fi', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Romance', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Thriller', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Animation', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Documentary', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Fantasy', '');

-- Activities options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Hiking', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Swimming', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Bowling', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Mini Golf', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Escape Room', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Karaoke', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Museum', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Board Games', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Beach', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Park', '');

-- Games options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Minecraft', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Fortnite', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Among Us', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Call of Duty', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'FIFA', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Mario Kart', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'League of Legends', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Valorant', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Roblox', ''),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Apex Legends', '');
