-- This migration creates the initial database schema for the Swivo app
-- Migration timestamp: 2024-08-20 00:00:00

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types
CREATE TYPE session_status AS ENUM ('open', 'matched', 'closed');

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT NOT NULL DEFAULT concat('anon-', substr(md5(random()::text), 0, 8)),
    apns_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 50)
);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    icon_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT category_name_unique UNIQUE (name)
);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    quorum_n INTEGER NOT NULL,
    status session_status DEFAULT 'open',
    matched_option_id UUID,
    invite_code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    matched_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT quorum_range CHECK (quorum_n >= 2 AND quorum_n <= 5),
    CONSTRAINT invite_code_format CHECK (length(invite_code) = 6)
);

-- Session participants table
CREATE TABLE IF NOT EXISTS session_participants (
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (session_id, user_id)
);

-- Options table
CREATE TABLE IF NOT EXISTS options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Session options table
CREATE TABLE IF NOT EXISTS session_options (
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES options(id) ON DELETE CASCADE,
    order_index INTEGER NOT NULL,
    PRIMARY KEY (session_id, option_id)
);

-- Likes table
CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES options(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_session_option_user UNIQUE (session_id, option_id, user_id)
);

-- Indexes for performance
CREATE INDEX idx_session_participants_session_id ON session_participants(session_id);
CREATE INDEX idx_likes_session_option ON likes(session_id, option_id);
CREATE INDEX idx_options_category_id ON options(category_id);
CREATE INDEX idx_session_options_session_id ON session_options(session_id);
