-- ============================================================
-- Final Project — Amankos Abylaikhan — Fitness Club
-- Database: fitness_club_db  /  Schema: fitness_club
-- ============================================================

-- =====  DATABASE + SCHEMA  =====

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'fitness_club_db') THEN
        EXECUTE 'CREATE DATABASE fitness_club_db';
    END IF;
END $$;

CREATE SCHEMA IF NOT EXISTS fitness_club;

-- ============================================================
-- PART 2: CREATE TABLE
-- Order: parent tables first, child tables second, bridge last.
-- ============================================================

-- Optional: uncomment to drop all tables for a clean rebuild during development
-- DROP TABLE IF EXISTS
--     fitness_club.attendance,
--     fitness_club.payments,
--     fitness_club.memberships,
--     fitness_club.schedules,
--     fitness_club.equipment,
--     fitness_club.classes,
--     fitness_club.rooms,
--     fitness_club.membership_types,
--     fitness_club.trainers,
--     fitness_club.members
-- CASCADE;

-- ── Membership plan catalog ───────────────────────────────────
CREATE TABLE IF NOT EXISTS fitness_club.membership_types (
    type_id       SERIAL         PRIMARY KEY,
    name          VARCHAR(60)    NOT NULL UNIQUE,          -- unique plan name is the natural key
    duration_days INT            NOT NULL CHECK (duration_days > 0),   -- duration must be positive
    price         NUMERIC(10,2)  NOT NULL CHECK (price >= 0),          -- price cannot be negative
    description   VARCHAR(255)
);

-- ── Club rooms and halls ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS fitness_club.rooms (
    room_id   SERIAL       PRIMARY KEY,
    name      VARCHAR(60)  NOT NULL UNIQUE,
    capacity  INT          NOT NULL CHECK (capacity > 0),  -- room must hold at least 1 person
    floor     INT          NOT NULL DEFAULT 1
);

-- ── Trainer profiles ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fitness_club.trainers (
    trainer_id     SERIAL       PRIMARY KEY,
    first_name     VARCHAR(80)  NOT NULL,
    last_name      VARCHAR(80)  NOT NULL,
    -- GENERATED: full_name is computed automatically — cannot be inserted directly
    full_name      VARCHAR(161) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    email          VARCHAR(120) NOT NULL UNIQUE,           -- natural key for trainers
    phone          VARCHAR(15),
    -- CHECK: only recognised specialisations are allowed
    specialization VARCHAR(40)  NOT NULL CHECK (specialization IN ('yoga','boxing','crossfit','pilates','stretching','strength')),
    hired_date     DATE         NOT NULL CHECK (hired_date > DATE '2026-01-01'), -- must be hired after 2026-01-01
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE
);

-- ── Club member profiles ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS fitness_club.members (
    member_id     SERIAL        PRIMARY KEY,
    first_name    VARCHAR(80)   NOT NULL,
    last_name     VARCHAR(80)   NOT NULL,
    email         VARCHAR(120)  NOT NULL UNIQUE,           -- natural key for members
    phone         VARCHAR(15),
    -- CHECK: gender is restricted to three accepted values
    gender        VARCHAR(10)   NOT NULL CHECK (gender IN ('M','F','Other')),
    birth_date    DATE,
    -- DEFAULT: registration timestamp is set automatically on insert
    registered_at TIMESTAMP     NOT NULL DEFAULT NOW(),
    status        VARCHAR(20)   NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active','inactive','banned'))
);

-- ── Class types ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fitness_club.classes (
    class_id    SERIAL        PRIMARY KEY,
    name        VARCHAR(80)   NOT NULL UNIQUE,
    description VARCHAR(255),
    difficulty  VARCHAR(20)   NOT NULL DEFAULT 'beginner'
                CHECK (difficulty IN ('beginner','intermediate','advanced'))
);

-- ── Schedule: links a class, a trainer, and a room ────────────
CREATE TABLE IF NOT EXISTS fitness_club.schedules (
    schedule_id      SERIAL     PRIMARY KEY,
    class_id         INT        NOT NULL REFERENCES fitness_club.classes(class_id)    ON DELETE RESTRICT,
    trainer_id       INT        NOT NULL REFERENCES fitness_club.trainers(trainer_id) ON DELETE RESTRICT,
    room_id          INT        NOT NULL REFERENCES fitness_club.rooms(room_id)       ON DELETE RESTRICT,
    starts_at        TIMESTAMP  NOT NULL CHECK (starts_at > '2026-01-01 00:00:00'),   -- session must be after 2026-01-01
    duration_min     INT        NOT NULL DEFAULT 60 CHECK (duration_min > 0),
    max_slots        INT        NOT NULL CHECK (max_slots > 0)
);

-- ── Purchased memberships ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS fitness_club.memberships (
    membership_id SERIAL      PRIMARY KEY,
    member_id     INT         NOT NULL REFERENCES fitness_club.members(member_id)         ON DELETE RESTRICT,
    type_id       INT         NOT NULL REFERENCES fitness_club.membership_types(type_id)  ON DELETE RESTRICT,
    start_date    DATE        NOT NULL CHECK (start_date > DATE '2026-01-01'),             -- memberships start in 2026 or later
    end_date      DATE        NOT NULL,
    status        VARCHAR(20) NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active','expired','frozen'))
);

-- ── Payment records ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fitness_club.payments (
    payment_id    SERIAL        PRIMARY KEY,
    membership_id INT           NOT NULL REFERENCES fitness_club.memberships(membership_id) ON DELETE RESTRICT,
    amount        NUMERIC(10,2) NOT NULL CHECK (amount > 0),   -- payment amount must be positive
    paid_at       TIMESTAMP     NOT NULL DEFAULT NOW(),
    method        VARCHAR(20)   NOT NULL DEFAULT 'card'
                  CHECK (method IN ('card','cash','transfer'))
);

-- ── Equipment inventory per room ──────────────────────────────
CREATE TABLE IF NOT EXISTS fitness_club.equipment (
    equipment_id SERIAL       PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    room_id      INT          NOT NULL REFERENCES fitness_club.rooms(room_id) ON DELETE RESTRICT,
    quantity     INT          NOT NULL DEFAULT 1 CHECK (quantity >= 0),        -- quantity cannot be negative
    condition    VARCHAR(20)  NOT NULL DEFAULT 'good'
                 CHECK (condition IN ('new','good','needs_repair','retired'))
);

-- ── M:N BRIDGE: class attendance ──────────────────────────────
-- One member attends many sessions; one session is attended by many members.
-- ON DELETE CASCADE: if a schedule is removed, all attendance records for it are deleted.
CREATE TABLE IF NOT EXISTS fitness_club.attendance (
    attendance_id SERIAL     PRIMARY KEY,
    member_id     INT        NOT NULL REFERENCES fitness_club.members(member_id)     ON DELETE CASCADE,
    schedule_id   INT        NOT NULL REFERENCES fitness_club.schedules(schedule_id) ON DELETE CASCADE,
    attended_at   TIMESTAMP  NOT NULL DEFAULT NOW(),
    -- a member cannot register for the same session twice
    CONSTRAINT uq_member_schedule UNIQUE (member_id, schedule_id)
);

-- ============================================================
-- PART 3: ALTER TABLE — schema evolution
-- ============================================================

-- 1. Widen phone field: international numbers can exceed 15 characters
ALTER TABLE fitness_club.members
    ALTER COLUMN phone TYPE VARCHAR(20);

-- 2. Same widening for trainers' phone numbers
ALTER TABLE fitness_club.trainers
    ALTER COLUMN phone TYPE VARCHAR(20);

-- 3. Add notes column to schedules: trainers may leave remarks for a session
ALTER TABLE fitness_club.schedules
    ADD COLUMN IF NOT EXISTS notes VARCHAR(255);

-- 4. Rename ambiguous column duration_min to duration_minutes for clarity
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'fitness_club'
          AND table_name   = 'schedules'
          AND column_name  = 'duration_min'
    ) THEN
        ALTER TABLE fitness_club.schedules RENAME COLUMN duration_min TO duration_minutes;
    END IF;
END $$;

-- 5. Add constraint: a trainer cannot lead two sessions in the same room at the same time
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_trainer_room_time'
    ) THEN
        ALTER TABLE fitness_club.schedules
            ADD CONSTRAINT uq_trainer_room_time UNIQUE (trainer_id, room_id, starts_at);
    END IF;
END $$;

-- ============================================================
-- PART 4: INSERT — seed data
-- ============================================================

-- Reset all tables in reverse FK order; CASCADE clears dependent tables.
-- RESTART IDENTITY resets SERIAL sequences so every re-run produces identical IDs.
TRUNCATE TABLE
    fitness_club.attendance,
    fitness_club.payments,
    fitness_club.memberships,
    fitness_club.equipment,
    fitness_club.schedules,
    fitness_club.classes,
    fitness_club.rooms,
    fitness_club.trainers,
    fitness_club.members,
    fitness_club.membership_types
RESTART IDENTITY CASCADE;

-- ── Membership plan catalog ───────────────────────────────────
INSERT INTO fitness_club.membership_types (name, duration_days, price, description) VALUES
    ('Monthly',          30,   15000.00, 'Basic plan — 1 month access'),
    ('Quarterly',        90,   39000.00, '3-month plan with a discount'),
    ('Annual',          365,  120000.00, 'Full-year plan — best value'),
    ('Single visit',      1,   2500.00,  'One-time drop-in, no membership required');

-- ── Club rooms ────────────────────────────────────────────────
INSERT INTO fitness_club.rooms (name, capacity, floor) VALUES
    ('Weight room',   20, 1),
    ('Yoga studio',   15, 2),
    ('Boxing hall',   12, 1),
    ('Cardio floor',  25, 2);

-- ── Trainers ──────────────────────────────────────────────────
INSERT INTO fitness_club.trainers (first_name, last_name, email, phone, specialization, hired_date) VALUES
    ('Aigerim', 'Bekova',    'aigerim.bekova@fitclub.kz',  '+77011112233', 'yoga',     DATE '2026-02-01'),
    ('Dauren',  'Seitkali',  'dauren.seitkali@fitclub.kz', '+77022223344', 'boxing',   DATE '2026-02-15'),
    ('Alina',   'Ivanova',   'alina.ivanova@fitclub.kz',   '+77033334455', 'crossfit', DATE '2026-03-01'),
    ('Nurlan',  'Omarov',    'nurlan.omarov@fitclub.kz',   '+77044445566', 'strength', DATE '2026-03-10');

-- ── Club members ──────────────────────────────────────────────
INSERT INTO fitness_club.members (first_name, last_name, email, phone, gender, birth_date) VALUES
    ('Asel',   'Nurmagambetova', 'asel.nur@mail.kz',   '+77051112233', 'F', DATE '1995-06-15'),
    ('Berik',  'Zhaksybekov',    'berik.zh@mail.kz',   '+77052223344', 'M', DATE '1990-03-22'),
    ('Karina', 'Sokolova',       'karina.s@mail.kz',   '+77053334455', 'F', DATE '1998-11-05'),
    ('Timur',  'Akhmetov',       'timur.akh@mail.kz',  '+77054445566', 'M', DATE '1993-07-18'),
    ('Dinara', 'Kassymova',      'dinara.kas@mail.kz', '+77055556677', 'F', DATE '2000-01-30');

-- ── Class types ───────────────────────────────────────────────
INSERT INTO fitness_club.classes (name, description, difficulty) VALUES
    ('Hatha yoga',      'Classic yoga for beginners',                    'beginner'),
    ('Adult boxing',    'Basic boxing techniques and bag work',          'intermediate'),
    ('Morning CrossFit','High-intensity functional training',            'advanced'),
    ('Strength training','Free weights and machine-based resistance work','intermediate'),
    ('Stretching',      'Full-body flexibility for all levels',          'beginner');

-- ── Schedules: FK values resolved by subquery on natural keys ─
INSERT INTO fitness_club.schedules (class_id, trainer_id, room_id, starts_at, duration_minutes, max_slots) VALUES
    (
        (SELECT class_id   FROM fitness_club.classes  WHERE name  = 'Hatha yoga'),
        (SELECT trainer_id FROM fitness_club.trainers WHERE email = 'aigerim.bekova@fitclub.kz'),
        (SELECT room_id    FROM fitness_club.rooms    WHERE name  = 'Yoga studio'),
        '2026-03-10 09:00:00', 60, 12
    ),
    (
        (SELECT class_id   FROM fitness_club.classes  WHERE name  = 'Adult boxing'),
        (SELECT trainer_id FROM fitness_club.trainers WHERE email = 'dauren.seitkali@fitclub.kz'),
        (SELECT room_id    FROM fitness_club.rooms    WHERE name  = 'Boxing hall'),
        '2026-03-10 11:00:00', 60, 10
    ),
    (
        (SELECT class_id   FROM fitness_club.classes  WHERE name  = 'Morning CrossFit'),
        (SELECT trainer_id FROM fitness_club.trainers WHERE email = 'alina.ivanova@fitclub.kz'),
        (SELECT room_id    FROM fitness_club.rooms    WHERE name  = 'Weight room'),
        '2026-03-11 07:00:00', 45, 15
    ),
    (
        (SELECT class_id   FROM fitness_club.classes  WHERE name  = 'Strength training'),
        (SELECT trainer_id FROM fitness_club.trainers WHERE email = 'nurlan.omarov@fitclub.kz'),
        (SELECT room_id    FROM fitness_club.rooms    WHERE name  = 'Weight room'),
        '2026-03-12 18:00:00', 75, 20
    ),
    (
        (SELECT class_id   FROM fitness_club.classes  WHERE name  = 'Stretching'),
        (SELECT trainer_id FROM fitness_club.trainers WHERE email = 'aigerim.bekova@fitclub.kz'),
        (SELECT room_id    FROM fitness_club.rooms    WHERE name  = 'Yoga studio'),
        '2026-03-13 10:00:00', 50, 12
    );

-- ── Memberships: FK values resolved by subquery ───────────────
INSERT INTO fitness_club.memberships (member_id, type_id, start_date, end_date, status) VALUES
    (
        (SELECT member_id FROM fitness_club.members          WHERE email = 'asel.nur@mail.kz'),
        (SELECT type_id   FROM fitness_club.membership_types WHERE name  = 'Monthly'),
        DATE '2026-03-01', DATE '2026-03-31', 'active'
    ),
    (
        (SELECT member_id FROM fitness_club.members          WHERE email = 'berik.zh@mail.kz'),
        (SELECT type_id   FROM fitness_club.membership_types WHERE name  = 'Quarterly'),
        DATE '2026-02-01', DATE '2026-04-30', 'active'
    ),
    (
        (SELECT member_id FROM fitness_club.members          WHERE email = 'karina.s@mail.kz'),
        (SELECT type_id   FROM fitness_club.membership_types WHERE name  = 'Annual'),
        DATE '2026-01-15', DATE '2027-01-14', 'active'
    ),
    (
        (SELECT member_id FROM fitness_club.members          WHERE email = 'timur.akh@mail.kz'),
        (SELECT type_id   FROM fitness_club.membership_types WHERE name  = 'Monthly'),
        DATE '2026-02-10', DATE '2026-03-09', 'expired'
    ),
    (
        (SELECT member_id FROM fitness_club.members          WHERE email = 'dinara.kas@mail.kz'),
        (SELECT type_id   FROM fitness_club.membership_types WHERE name  = 'Quarterly'),
        DATE '2026-03-05', DATE '2026-06-03', 'active'
    );

-- ── Payments: FK resolved via JOIN on member email ────────────
INSERT INTO fitness_club.payments (membership_id, amount, method) VALUES
    (
        (SELECT ms.membership_id FROM fitness_club.memberships ms
         JOIN fitness_club.members m ON m.member_id = ms.member_id
         WHERE m.email = 'asel.nur@mail.kz' LIMIT 1),
        15000.00, 'card'
    ),
    (
        (SELECT ms.membership_id FROM fitness_club.memberships ms
         JOIN fitness_club.members m ON m.member_id = ms.member_id
         WHERE m.email = 'berik.zh@mail.kz' LIMIT 1),
        39000.00, 'transfer'
    ),
    (
        (SELECT ms.membership_id FROM fitness_club.memberships ms
         JOIN fitness_club.members m ON m.member_id = ms.member_id
         WHERE m.email = 'karina.s@mail.kz' LIMIT 1),
        120000.00, 'card'
    ),
    (
        (SELECT ms.membership_id FROM fitness_club.memberships ms
         JOIN fitness_club.members m ON m.member_id = ms.member_id
         WHERE m.email = 'timur.akh@mail.kz' LIMIT 1),
        15000.00, 'cash'
    ),
    (
        (SELECT ms.membership_id FROM fitness_club.memberships ms
         JOIN fitness_club.members m ON m.member_id = ms.member_id
         WHERE m.email = 'dinara.kas@mail.kz' LIMIT 1),
        39000.00, 'card'
    );

-- ── Equipment inventory ───────────────────────────────────────
INSERT INTO fitness_club.equipment (name, room_id, quantity, condition) VALUES
    ('Dumbbell set 5–30 kg',
        (SELECT room_id FROM fitness_club.rooms WHERE name = 'Weight room'),   5, 'good'),
    ('Olympic barbell',
        (SELECT room_id FROM fitness_club.rooms WHERE name = 'Weight room'),   4, 'good'),
    ('Heavy punching bag',
        (SELECT room_id FROM fitness_club.rooms WHERE name = 'Boxing hall'),   6, 'good'),
    ('Yoga mat',
        (SELECT room_id FROM fitness_club.rooms WHERE name = 'Yoga studio'),  15, 'new'),
    ('Treadmill',
        (SELECT room_id FROM fitness_club.rooms WHERE name = 'Cardio floor'),  8, 'good'),
    ('Stationary bike',
        (SELECT room_id FROM fitness_club.rooms WHERE name = 'Cardio floor'),  6, 'needs_repair');

-- ── Attendance (M:N bridge) — populated via INSERT ... SELECT ─
-- Members are joined to sessions through their email and class name.
-- No hard-coded IDs anywhere.
INSERT INTO fitness_club.attendance (member_id, schedule_id)
SELECT m.member_id, s.schedule_id
FROM (VALUES
    ('asel.nur@mail.kz',   'Hatha yoga',       '2026-03-10 09:00:00'),
    ('asel.nur@mail.kz',   'Stretching',       '2026-03-13 10:00:00'),
    ('berik.zh@mail.kz',   'Adult boxing',     '2026-03-10 11:00:00'),
    ('berik.zh@mail.kz',   'Strength training','2026-03-12 18:00:00'),
    ('karina.s@mail.kz',   'Hatha yoga',       '2026-03-10 09:00:00'),
    ('karina.s@mail.kz',   'Morning CrossFit', '2026-03-11 07:00:00'),
    ('timur.akh@mail.kz',  'Strength training','2026-03-12 18:00:00'),
    ('dinara.kas@mail.kz', 'Hatha yoga',       '2026-03-10 09:00:00'),
    ('dinara.kas@mail.kz', 'Stretching',       '2026-03-13 10:00:00')
) AS x(email, class_name, starts_at)
JOIN fitness_club.members   m ON m.email      = x.email
JOIN fitness_club.classes   c ON c.name       = x.class_name
JOIN fitness_club.schedules s ON s.class_id   = c.class_id
                              AND s.starts_at  = x.starts_at::TIMESTAMP;

-- ============================================================
-- PART 5: UPDATE
-- ============================================================

-- Simple UPDATE: mark members with an expired membership as inactive.
-- Business reason: members whose membership has expired should not appear
-- as active in the system — they are excluded from check-in and notifications.
UPDATE fitness_club.members
SET status = 'inactive'
WHERE member_id IN (
    SELECT DISTINCT member_id
    FROM fitness_club.memberships
    WHERE status = 'expired'
);

-- UPDATE ... FROM: set membership status to 'expired' when end_date has passed.
-- Business reason: after the nightly maintenance job, any membership whose
-- end_date is in the past must be automatically closed to prevent unauthorised access.
UPDATE fitness_club.memberships ms
SET status = 'expired'
FROM fitness_club.members m
WHERE ms.member_id = m.member_id
  AND ms.end_date < CURRENT_DATE
  AND ms.status = 'active';

-- ============================================================
-- PART 5: DELETE
-- ============================================================

-- Business reason: remove frozen memberships that ended more than 90 days ago.
-- These are considered archive waste — no refund possible, no reactivation allowed.
-- Wrapped in BEGIN ... ROLLBACK so demo data survives for the defense.
BEGIN;
    DELETE FROM fitness_club.memberships
    WHERE status = 'frozen'
      AND end_date < CURRENT_DATE - INTERVAL '90 days'
    RETURNING membership_id, member_id, status, end_date;
ROLLBACK;

-- ============================================================
-- PART 6: GRANT / REVOKE
-- ============================================================

-- Re-runnable role cleanup — must run before CREATE ROLE to avoid "already exists" errors
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'fitness_club_readonly') THEN
        REASSIGN OWNED BY fitness_club_readonly TO CURRENT_USER;
        DROP OWNED BY fitness_club_readonly;
        DROP ROLE fitness_club_readonly;
    END IF;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'fitness_club_writer') THEN
        REASSIGN OWNED BY fitness_club_writer TO CURRENT_USER;
        DROP OWNED BY fitness_club_writer;
        DROP ROLE fitness_club_writer;
    END IF;
END $$;

-- Two application roles
CREATE ROLE fitness_club_readonly;
CREATE ROLE fitness_club_writer;

-- Schema USAGE must be granted before any table-level privileges take effect
GRANT USAGE ON SCHEMA fitness_club TO fitness_club_readonly, fitness_club_writer;

-- Read-only role: used by the reporting and analytics service
GRANT SELECT ON ALL TABLES IN SCHEMA fitness_club TO fitness_club_readonly;

-- Writer role: used by the mobile app to record check-ins and process payments
GRANT INSERT, UPDATE ON fitness_club.attendance TO fitness_club_writer;
GRANT INSERT, UPDATE ON fitness_club.payments   TO fitness_club_writer;

-- REVOKE: after a post-incident review it was decided that the mobile app
-- must not be able to UPDATE existing payment records.
-- All payment corrections must go through a separate audit-logged back-office service.
REVOKE UPDATE ON fitness_club.payments FROM fitness_club_writer;
