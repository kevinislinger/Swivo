-- Swivo App Sample Data

-- Sample categories
INSERT INTO categories (id, name, icon_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Restaurants', 'restaurant.png'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Movies', 'movie.png'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Activities', 'activity.png'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Games', 'game.png')
ON CONFLICT (name) DO NOTHING;

-- Restaurant options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Italian', 'italian.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Japanese', 'japanese.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Mexican', 'mexican.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Chinese', 'chinese.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Thai', 'thai.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Indian', 'indian.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Greek', 'greek.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'French', 'french.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Korean', 'korean.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'American', 'american.jpg');

-- Movie options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Action', 'action.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Comedy', 'comedy.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Drama', 'drama.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Horror', 'horror.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Sci-Fi', 'scifi.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Romance', 'romance.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Thriller', 'thriller.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Animation', 'animation.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Documentary', 'documentary.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Fantasy', 'fantasy.jpg');

-- Activities options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Hiking', 'hiking.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Swimming', 'swimming.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Bowling', 'bowling.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Mini Golf', 'minigolf.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Escape Room', 'escaperoom.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Karaoke', 'karaoke.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Museum', 'museum.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Board Games', 'boardgames.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Beach', 'beach.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Park', 'park.jpg');

-- Games options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Minecraft', 'minecraft.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Fortnite', 'fortnite.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Among Us', 'amongus.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Call of Duty', 'callofduty.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'FIFA', 'fifa.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Mario Kart', 'mariokart.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'League of Legends', 'lol.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Valorant', 'valorant.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Roblox', 'roblox.jpg'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Apex Legends', 'apex.jpg');
