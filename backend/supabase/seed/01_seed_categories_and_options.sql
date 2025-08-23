-- Swivo App Seed Data

-- Sample categories
INSERT INTO categories (id, name, icon_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Restaurants', 'restaurant.png'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Movies', 'movie.png'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Activities', 'activity.png'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Games', 'game.png')
ON CONFLICT (name) DO NOTHING;

-- Restaurant options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Italian', 'https://images.unsplash.com/photo-1546549032-9571cd6b27df?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Japanese', 'https://images.unsplash.com/photo-1617196034183-421b4917c92d?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Mexican', 'https://images.unsplash.com/photo-1606525437679-037aca74a3e9?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Chinese', 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Thai', 'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Indian', 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Greek', 'https://images.unsplash.com/photo-1600565193348-f74bd3c7ccdf?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'French', 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Korean', 'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'American', 'https://images.unsplash.com/photo-1551782450-17144efb9c50?w=800');

-- Movie options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Action', 'https://images.unsplash.com/photo-1513106580091-1d82408b8cd6?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Comedy', 'https://images.unsplash.com/photo-1543584756-31232a7a5a3b?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Drama', 'https://images.unsplash.com/photo-1485846234645-a62644f84728?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Horror', 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Sci-Fi', 'https://images.unsplash.com/photo-1501951653466-8df816debe46?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Romance', 'https://images.unsplash.com/photo-1485846147915-69f12fbd03b9?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Thriller', 'https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Animation', 'https://images.unsplash.com/photo-1515634928627-2a4e0dae3ddf?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Documentary', 'https://images.unsplash.com/photo-1468421870903-4df1664ac249?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Fantasy', 'https://images.unsplash.com/photo-1518709911915-712d5fd04677?w=800');

-- Activities options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Hiking', 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Swimming', 'https://images.unsplash.com/photo-1560090995-01632a28895b?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Bowling', 'https://images.unsplash.com/photo-1545056453-f0359c3df6db?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Mini Golf', 'https://images.unsplash.com/photo-1561125110-a1e56218ee5c?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Escape Room', 'https://images.unsplash.com/photo-1569706415418-d194093aa4a0?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Karaoke', 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Museum', 'https://images.unsplash.com/photo-1565060169192-33e5f392f6dd?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Board Games', 'https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Beach', 'https://images.unsplash.com/photo-1473186578172-c141e6798cf4?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Park', 'https://images.unsplash.com/photo-1519331379826-f10be5486c6f?w=800');

-- Games options
INSERT INTO options (category_id, label, image_url) VALUES
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Minecraft', 'https://images.unsplash.com/photo-1587573089734-599a5f7ad8b6?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Fortnite', 'https://images.unsplash.com/photo-1589241062272-c0a000072dfa?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Among Us', 'https://images.unsplash.com/photo-1607853202273-797f1c22a38e?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Call of Duty', 'https://images.unsplash.com/photo-1602673221577-0b56d7ce446b?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'FIFA', 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Mario Kart', 'https://images.unsplash.com/photo-1586336910920-98f0611ddaac?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'League of Legends', 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Valorant', 'https://images.unsplash.com/photo-1580327344181-c1163234e5a0?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Roblox', 'https://images.unsplash.com/photo-1588475441020-7aad4461631c?w=800'),
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Apex Legends', 'https://images.unsplash.com/photo-1552820728-8b83bb6b773f?w=800');
