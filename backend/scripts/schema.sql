-- Wine List Assistant Database Schema
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Wines table
CREATE TABLE IF NOT EXISTS wines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    producer TEXT NOT NULL,
    name TEXT NOT NULL,
    vintage INTEGER,
    region TEXT NOT NULL,
    sub_region TEXT,
    appellation TEXT,
    country TEXT NOT NULL,
    color TEXT NOT NULL CHECK (color IN ('red', 'white', 'rose', 'sparkling', 'dessert', 'fortified')),
    grape_varieties JSONB DEFAULT '[]'::jsonb,
    alcohol DECIMAL(4,2),
    label_url TEXT,
    top100_rank INTEGER,
    top100_year INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wine_id UUID NOT NULL REFERENCES wines(id) ON DELETE CASCADE,
    score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
    tasting_note TEXT NOT NULL,
    reviewer_initials TEXT NOT NULL,
    reviewer_name TEXT,
    review_date DATE NOT NULL,
    issue_date DATE,
    drink_window_start INTEGER,
    drink_window_end INTEGER,
    release_price DECIMAL(10,2),
    release_price_currency TEXT DEFAULT 'USD',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    apple_user_id TEXT UNIQUE,
    subscription_tier TEXT NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'business')),
    subscription_status TEXT NOT NULL DEFAULT 'active' CHECK (subscription_status IN ('active', 'expired', 'cancelled', 'pending')),
    subscription_expires_at TIMESTAMPTZ,
    subscription_product_id TEXT,
    scans_this_month INTEGER DEFAULT 0,
    scans_month_start DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Saved wines table
CREATE TABLE IF NOT EXISTS saved_wines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    wine_id UUID NOT NULL REFERENCES wines(id) ON DELETE CASCADE,
    notes TEXT,
    restaurant TEXT,
    price_paid DECIMAL(10,2),
    date_consumed DATE,
    personal_rating INTEGER CHECK (personal_rating >= 1 AND personal_rating <= 5),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, wine_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_wines_producer ON wines(producer);
CREATE INDEX IF NOT EXISTS idx_wines_name ON wines(name);
CREATE INDEX IF NOT EXISTS idx_wines_vintage ON wines(vintage);
CREATE INDEX IF NOT EXISTS idx_wines_region ON wines(region);
CREATE INDEX IF NOT EXISTS idx_wines_country ON wines(country);
CREATE INDEX IF NOT EXISTS idx_wines_color ON wines(color);
CREATE INDEX IF NOT EXISTS idx_wines_top100_rank ON wines(top100_rank) WHERE top100_rank IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_wines_top100_year ON wines(top100_year) WHERE top100_year IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_reviews_wine_id ON reviews(wine_id);
CREATE INDEX IF NOT EXISTS idx_reviews_score ON reviews(score);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_apple_user_id ON users(apple_user_id);

CREATE INDEX IF NOT EXISTS idx_saved_wines_user_id ON saved_wines(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_wines_wine_id ON saved_wines(wine_id);

-- Full text search index for wines
CREATE INDEX IF NOT EXISTS idx_wines_fts ON wines USING gin(
    to_tsvector('english', producer || ' ' || name || ' ' || region || ' ' || country)
);

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger
DROP TRIGGER IF EXISTS wines_updated_at ON wines;
CREATE TRIGGER wines_updated_at
    BEFORE UPDATE ON wines
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS users_updated_at ON users;
CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Row Level Security (RLS)
ALTER TABLE wines ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_wines ENABLE ROW LEVEL SECURITY;

-- Policies: Wines and reviews are publicly readable
CREATE POLICY "Wines are viewable by everyone" ON wines
    FOR SELECT USING (true);

CREATE POLICY "Reviews are viewable by everyone" ON reviews
    FOR SELECT USING (true);

-- Users can only see their own data
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);

-- Saved wines: users can only access their own
CREATE POLICY "Users can view own saved wines" ON saved_wines
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own saved wines" ON saved_wines
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own saved wines" ON saved_wines
    FOR DELETE USING (auth.uid()::text = user_id::text);

-- Service role can do everything (for API)
CREATE POLICY "Service role full access wines" ON wines
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access reviews" ON reviews
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access users" ON users
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access saved_wines" ON saved_wines
    FOR ALL USING (auth.role() = 'service_role');
