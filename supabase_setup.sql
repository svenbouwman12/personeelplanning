-- Supabase Personeelsplanner Setup
-- Gebruik dit script in de Supabase SQL Editor

-- Enable Row Level Security (RLS) voor alle tabellen
-- Dit is belangrijk voor Supabase security

-- Tabel voor gebruikers
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'employee' CHECK (role IN ('admin', 'employee')),
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Tabel voor diensten/roosters
CREATE TABLE IF NOT EXISTS shifts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    day DATE NOT NULL,
    timeslot TEXT NOT NULL,
    start_time TIME,
    end_time TIME,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT unique_shift UNIQUE (user_id, day, timeslot)
);

-- Tabel voor inklok gegevens
CREATE TABLE IF NOT EXISTS clockings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    clock_in TIMESTAMPTZ NOT NULL,
    clock_out TIMESTAMPTZ,
    break_start TIMESTAMPTZ,
    break_end TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE clockings ENABLE ROW LEVEL SECURITY;

-- RLS Policies (aanpasbaar naar je security behoeften)
-- Voor nu: iedereen kan alles lezen en schrijven (voor demo doeleinden)
-- In productie zou je dit moeten beperken

-- Users policies
CREATE POLICY "Users can read all users" ON users FOR SELECT USING (true);
CREATE POLICY "Users can insert users" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update users" ON users FOR UPDATE USING (true);
CREATE POLICY "Users can delete users" ON users FOR DELETE USING (true);

-- Shifts policies
CREATE POLICY "Users can read all shifts" ON shifts FOR SELECT USING (true);
CREATE POLICY "Users can insert shifts" ON shifts FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update shifts" ON shifts FOR UPDATE USING (true);
CREATE POLICY "Users can delete shifts" ON shifts FOR DELETE USING (true);

-- Clockings policies
CREATE POLICY "Users can read all clockings" ON clockings FOR SELECT USING (true);
CREATE POLICY "Users can insert clockings" ON clockings FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update clockings" ON clockings FOR UPDATE USING (true);
CREATE POLICY "Users can delete clockings" ON clockings FOR DELETE USING (true);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);

CREATE INDEX IF NOT EXISTS idx_shifts_user_date ON shifts(user_id, day);
CREATE INDEX IF NOT EXISTS idx_shifts_day ON shifts(day);
CREATE INDEX IF NOT EXISTS idx_shifts_day_timeslot ON shifts(day, timeslot);

CREATE INDEX IF NOT EXISTS idx_clockings_user_clock_in ON clockings(user_id, clock_in);
CREATE INDEX IF NOT EXISTS idx_clockings_clock_in ON clockings(clock_in);
CREATE INDEX IF NOT EXISTS idx_clockings_clock_out ON clockings(clock_out);

-- Demo data
INSERT INTO users (username, password, role, first_name, last_name, email) VALUES
('admin', 'admin123', 'admin', 'Admin', 'User', 'admin@personeelsplanner.nl'),
('sven', 'sven123', 'employee', 'Sven', 'Jansen', 'sven@personeelsplanner.nl'),
('anna', 'anna123', 'employee', 'Anna', 'de Vries', 'anna@personeelsplanner.nl'),
('tom', 'tom123', 'employee', 'Tom', 'Bakker', 'tom@personeelsplanner.nl')
ON CONFLICT (username) DO UPDATE SET
    password = EXCLUDED.password,
    role = EXCLUDED.role,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    email = EXCLUDED.email,
    updated_at = NOW();

-- Functions voor automatische updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shifts_updated_at 
    BEFORE UPDATE ON shifts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clockings_updated_at 
    BEFORE UPDATE ON clockings 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Utility functions
CREATE OR REPLACE FUNCTION clock_in(p_user_id BIGINT)
RETURNS BIGINT AS $$
DECLARE
    clocking_id BIGINT;
BEGIN
    -- Check if user is already clocked in
    IF EXISTS (SELECT 1 FROM clockings WHERE user_id = p_user_id AND clock_out IS NULL) THEN
        RAISE EXCEPTION 'User is already clocked in';
    END IF;
    
    INSERT INTO clockings (user_id, clock_in) 
    VALUES (p_user_id, NOW())
    RETURNING id INTO clocking_id;
    
    RETURN clocking_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION clock_out(p_user_id BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
    latest_clocking_id BIGINT;
BEGIN
    -- Zoek de laatste actieve sessie
    SELECT id INTO latest_clocking_id
    FROM clockings 
    WHERE user_id = p_user_id AND clock_out IS NULL 
    ORDER BY clock_in DESC 
    LIMIT 1;
    
    IF latest_clocking_id IS NULL THEN
        RAISE EXCEPTION 'No active clocking session found';
    END IF;
    
    -- Update de gevonden sessie
    UPDATE clockings 
    SET clock_out = NOW() 
    WHERE id = latest_clocking_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Test de setup
SELECT 'Database setup completed successfully!' as status;
