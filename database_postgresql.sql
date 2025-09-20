-- Personeelsplanner Database Schema
-- PostgreSQL/Supabase Database Setup Script

-- Tabel voor gebruikers
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'employee' CHECK (role IN ('admin', 'employee')),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Tabel voor diensten/roosters
CREATE TABLE IF NOT EXISTS shifts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    day DATE NOT NULL,
    timeslot VARCHAR(20) NOT NULL,
    start_time TIME,
    end_time TIME,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT unique_shift UNIQUE (user_id, day, timeslot)
);

-- Tabel voor inklok gegevens
CREATE TABLE IF NOT EXISTS clockings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    clock_in TIMESTAMP WITH TIME ZONE NOT NULL,
    clock_out TIMESTAMP WITH TIME ZONE,
    break_start TIMESTAMP WITH TIME ZONE,
    break_end TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes voor betere performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);

CREATE INDEX IF NOT EXISTS idx_shifts_user_date ON shifts(user_id, day);
CREATE INDEX IF NOT EXISTS idx_shifts_day ON shifts(day);
CREATE INDEX IF NOT EXISTS idx_shifts_day_timeslot ON shifts(day, timeslot);

CREATE INDEX IF NOT EXISTS idx_clockings_user_clock_in ON clockings(user_id, clock_in);
CREATE INDEX IF NOT EXISTS idx_clockings_clock_in ON clockings(clock_in);
CREATE INDEX IF NOT EXISTS idx_clockings_clock_out ON clockings(clock_out);
CREATE INDEX IF NOT EXISTS idx_clockings_user_date ON clockings(user_id, DATE(clock_in));

-- Demo data invoegen
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
    updated_at = CURRENT_TIMESTAMP;

-- Views voor handige queries

-- View voor actieve gebruikers met hun rollen
CREATE OR REPLACE VIEW active_users AS
SELECT 
    id,
    username,
    role,
    CONCAT(first_name, ' ', last_name) AS full_name,
    email,
    created_at
FROM users 
WHERE is_active = TRUE;

-- View voor rooster overzicht
CREATE OR REPLACE VIEW schedule_overview AS
SELECT 
    s.id,
    s.day,
    s.timeslot,
    s.start_time,
    s.end_time,
    u.username,
    u.first_name,
    u.last_name,
    u.role
FROM shifts s
JOIN users u ON s.user_id = u.id
WHERE u.is_active = TRUE
ORDER BY s.day, s.start_time;

-- View voor inklok overzicht met gewerkte uren
CREATE OR REPLACE VIEW clocking_overview AS
SELECT 
    c.id,
    c.user_id,
    u.username,
    u.first_name,
    u.last_name,
    c.clock_in,
    c.clock_out,
    CASE 
        WHEN c.clock_out IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (c.clock_out - c.clock_in)) / 3600.0
        ELSE 
            EXTRACT(EPOCH FROM (NOW() - c.clock_in)) / 3600.0
    END AS hours_worked,
    CASE 
        WHEN c.clock_out IS NOT NULL THEN 'completed'
        ELSE 'active'
    END AS status
FROM clockings c
JOIN users u ON c.user_id = u.id
ORDER BY c.clock_in DESC;

-- Functions voor automatische updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers voor automatische updates
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

-- Stored procedures voor veelgebruikte operaties

-- Function om een gebruiker toe te voegen
CREATE OR REPLACE FUNCTION add_user(
    p_username VARCHAR(50),
    p_password VARCHAR(255),
    p_role VARCHAR(20),
    p_first_name VARCHAR(100),
    p_last_name VARCHAR(100),
    p_email VARCHAR(255)
)
RETURNS INTEGER AS $$
DECLARE
    user_id INTEGER;
BEGIN
    INSERT INTO users (username, password, role, first_name, last_name, email)
    VALUES (p_username, p_password, p_role, p_first_name, p_last_name, p_email)
    RETURNING id INTO user_id;
    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Function om een dienst toe te voegen
CREATE OR REPLACE FUNCTION add_shift(
    p_user_id INTEGER,
    p_day DATE,
    p_timeslot VARCHAR(20),
    p_start_time TIME,
    p_end_time TIME
)
RETURNS INTEGER AS $$
DECLARE
    shift_id INTEGER;
BEGIN
    INSERT INTO shifts (user_id, day, timeslot, start_time, end_time)
    VALUES (p_user_id, p_day, p_timeslot, p_start_time, p_end_time)
    ON CONFLICT (user_id, day, timeslot) 
    DO UPDATE SET
        timeslot = EXCLUDED.timeslot,
        start_time = EXCLUDED.start_time,
        end_time = EXCLUDED.end_time,
        updated_at = CURRENT_TIMESTAMP
    RETURNING id INTO shift_id;
    RETURN shift_id;
END;
$$ LANGUAGE plpgsql;

-- Function om in te klokken
CREATE OR REPLACE FUNCTION clock_in(p_user_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    clocking_id INTEGER;
BEGIN
    -- Controleer of er al een actieve sessie is
    IF EXISTS (SELECT 1 FROM clockings WHERE user_id = p_user_id AND clock_out IS NULL) THEN
        RAISE EXCEPTION 'User is already clocked in';
    END IF;
    
    INSERT INTO clockings (user_id, clock_in) 
    VALUES (p_user_id, NOW())
    RETURNING id INTO clocking_id;
    
    RETURN clocking_id;
END;
$$ LANGUAGE plpgsql;

-- Function om uit te klokken
CREATE OR REPLACE FUNCTION clock_out(p_user_id INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE clockings 
    SET clock_out = NOW() 
    WHERE user_id = p_user_id AND clock_out IS NULL 
    ORDER BY clock_in DESC 
    LIMIT 1;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No active clocking session found';
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Comments voor documentatie
COMMENT ON TABLE users IS 'Gebruikers tabel met admin en werknemer rollen';
COMMENT ON TABLE shifts IS 'Dienstrooster met toegewezen werknemers per tijdslot';
COMMENT ON TABLE clockings IS 'Inklok/uitklok gegevens met tijdsregistratie';

COMMENT ON COLUMN users.role IS 'Rol van de gebruiker: admin of employee';
COMMENT ON COLUMN shifts.timeslot IS 'Tijdslot zoals "09:00-13:00"';
COMMENT ON COLUMN clockings.clock_in IS 'Tijdstip van inklokken';
COMMENT ON COLUMN clockings.clock_out IS 'Tijdstip van uitklokken (NULL als nog actief)';
