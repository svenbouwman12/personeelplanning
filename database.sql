-- Personeelsplanner Database Schema
-- MySQL Database Setup Script

-- Database aanmaken (optioneel - uncomment als je een nieuwe database wilt maken)
-- CREATE DATABASE IF NOT EXISTS personeelsplanner;
-- USE personeelsplanner;

-- Tabel voor gebruikers
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'employee') NOT NULL DEFAULT 'employee',
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Tabel voor diensten/roosters
CREATE TABLE IF NOT EXISTS shifts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    day DATE NOT NULL,
    timeslot VARCHAR(20) NOT NULL,
    start_time TIME,
    end_time TIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_date (user_id, day),
    INDEX idx_date (day),
    UNIQUE KEY unique_shift (user_id, day, timeslot)
);

-- Tabel voor inklok gegevens
CREATE TABLE IF NOT EXISTS clockings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    clock_in DATETIME NOT NULL,
    clock_out DATETIME NULL,
    break_start DATETIME NULL,
    break_end DATETIME NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_clock_in (user_id, clock_in),
    INDEX idx_clock_in (clock_in),
    INDEX idx_clock_out (clock_out)
);

-- Demo data invoegen
INSERT INTO users (username, password, role, first_name, last_name, email) VALUES
('admin', 'admin123', 'admin', 'Admin', 'User', 'admin@personeelsplanner.nl'),
('sven', 'sven123', 'employee', 'Sven', 'Jansen', 'sven@personeelsplanner.nl'),
('anna', 'anna123', 'employee', 'Anna', 'de Vries', 'anna@personeelsplanner.nl'),
('tom', 'tom123', 'employee', 'Tom', 'Bakker', 'tom@personeelsplanner.nl')
ON DUPLICATE KEY UPDATE 
    password = VALUES(password),
    role = VALUES(role),
    first_name = VALUES(first_name),
    last_name = VALUES(last_name),
    email = VALUES(email);

-- Voorbeeld rooster data (optioneel)
-- INSERT INTO shifts (user_id, day, timeslot, start_time, end_time) VALUES
-- (2, '2024-01-15', '09:00-13:00', '09:00:00', '13:00:00'),
-- (3, '2024-01-15', '13:00-17:00', '13:00:00', '17:00:00'),
-- (4, '2024-01-15', '17:00-21:00', '17:00:00', '21:00:00');

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
            TIMESTAMPDIFF(MINUTE, c.clock_in, c.clock_out) / 60.0
        ELSE 
            TIMESTAMPDIFF(MINUTE, c.clock_in, NOW()) / 60.0
    END AS hours_worked,
    CASE 
        WHEN c.clock_out IS NOT NULL THEN 'completed'
        ELSE 'active'
    END AS status
FROM clockings c
JOIN users u ON c.user_id = u.id
ORDER BY c.clock_in DESC;

-- Stored procedures voor veelgebruikte operaties

-- Procedure om een gebruiker toe te voegen
DELIMITER //
CREATE PROCEDURE AddUser(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    IN p_role ENUM('admin', 'employee'),
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_email VARCHAR(255)
)
BEGIN
    INSERT INTO users (username, password, role, first_name, last_name, email)
    VALUES (p_username, p_password, p_role, p_first_name, p_last_name, p_email);
    SELECT LAST_INSERT_ID() AS user_id;
END //
DELIMITER ;

-- Procedure om een dienst toe te voegen
DELIMITER //
CREATE PROCEDURE AddShift(
    IN p_user_id INT,
    IN p_day DATE,
    IN p_timeslot VARCHAR(20),
    IN p_start_time TIME,
    IN p_end_time TIME
)
BEGIN
    INSERT INTO shifts (user_id, day, timeslot, start_time, end_time)
    VALUES (p_user_id, p_day, p_timeslot, p_start_time, p_end_time)
    ON DUPLICATE KEY UPDATE
        timeslot = VALUES(timeslot),
        start_time = VALUES(start_time),
        end_time = VALUES(end_time),
        updated_at = CURRENT_TIMESTAMP;
END //
DELIMITER ;

-- Procedure om in te klokken
DELIMITER //
CREATE PROCEDURE ClockIn(IN p_user_id INT)
BEGIN
    -- Controleer of er al een actieve sessie is
    IF EXISTS (SELECT 1 FROM clockings WHERE user_id = p_user_id AND clock_out IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User is already clocked in';
    ELSE
        INSERT INTO clockings (user_id, clock_in) VALUES (p_user_id, NOW());
        SELECT LAST_INSERT_ID() AS clocking_id;
    END IF;
END //
DELIMITER ;

-- Procedure om uit te klokken
DELIMITER //
CREATE PROCEDURE ClockOut(IN p_user_id INT)
BEGIN
    UPDATE clockings 
    SET clock_out = NOW() 
    WHERE user_id = p_user_id AND clock_out IS NULL 
    ORDER BY clock_in DESC 
    LIMIT 1;
    
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No active clocking session found';
    END IF;
END //
DELIMITER ;

-- Triggers voor automatische updates

-- Trigger om updated_at te updaten bij wijzigingen in users tabel
DELIMITER //
CREATE TRIGGER users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
BEGIN 
    SET NEW.updated_at = CURRENT_TIMESTAMP; 
END //
DELIMITER ;

-- Trigger om updated_at te updaten bij wijzigingen in shifts tabel
DELIMITER //
CREATE TRIGGER shifts_updated_at 
    BEFORE UPDATE ON shifts 
    FOR EACH ROW 
BEGIN 
    SET NEW.updated_at = CURRENT_TIMESTAMP; 
END //
DELIMITER ;

-- Trigger om updated_at te updaten bij wijzigingen in clockings tabel
DELIMITER //
CREATE TRIGGER clockings_updated_at 
    BEFORE UPDATE ON clockings 
    FOR EACH ROW 
BEGIN 
    SET NEW.updated_at = CURRENT_TIMESTAMP; 
END //
DELIMITER ;

-- Indexes voor betere performance
CREATE INDEX idx_shifts_day_timeslot ON shifts(day, timeslot);
CREATE INDEX idx_clockings_user_date ON clockings(user_id, DATE(clock_in));
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(is_active);

-- Comments voor documentatie
ALTER TABLE users COMMENT = 'Gebruikers tabel met admin en werknemer rollen';
ALTER TABLE shifts COMMENT = 'Dienstrooster met toegewezen werknemers per tijdslot';
ALTER TABLE clockings COMMENT = 'Inklok/uitklok gegevens met tijdsregistratie';
