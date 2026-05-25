# Final Project — Fitness Club Database

**Student:** Amankos Abylaikhan
**Domain:** Fitness Club
**Database:** `fitness_club_db`
**Schema:** `fitness_club`

---

## Domain Description

This database models a fitness club management system. It stores information about club members, trainers, class types, schedules, memberships, payments, equipment, and class attendance. The system tracks who purchased which membership plan, which trainer leads which class, which room it takes place in, and which members attended each session.

---

## Files

| File | Description |
|---|---|
| `01_model.pdf` | Conceptual ERD + Logical schema |
| `02_final.sql` | Full re-runnable SQL script |
| `README.md` | This file |

---

## How to Run

### Option 1 — psql (terminal)
```bash
psql -U postgres -f 02_final.sql
```

### Option 2 — pgAdmin
1. Open pgAdmin
2. Connect to your PostgreSQL server
3. File → Open → select `02_final.sql`
4. Press Execute (F5)

> The script is fully re-runnable. Running it a second time produces the same result with zero errors.

---

## Database & Schema

```sql
-- Database
fitness_club_db

-- Schema
fitness_club
```

All tables live under the `fitness_club` schema.

---

## Tables (10 total)

| Table | Description |
|---|---|
| `membership_types` | Membership plan catalog (monthly, quarterly, annual) |
| `rooms` | Club rooms and halls |
| `trainers` | Trainer profiles and specializations |
| `members` | Club member profiles |
| `classes` | Class types (yoga, boxing, crossfit, etc.) |
| `schedules` | Scheduled sessions — links class, trainer, and room |
| `memberships` | Purchased memberships — links member to a plan |
| `payments` | Payment records for memberships |
| `equipment` | Equipment inventory per room |
| `attendance` | **M:N bridge** — which members attended which sessions |

---

## Relationships

```
membership_types ──(1:N)── memberships ──(N:1)── members
                                │
                           (1:N) payments

classes  ──(1:N)──┐
trainers ──(1:N)──┼── schedules
rooms    ──(1:N)──┘        │
                      (1:N)│
                       attendance ──(N:1)── members

rooms ──(1:N)── equipment
```

**Many-to-many:** `members` ↔ `schedules` resolved through the `attendance` bridge table.

---

## Key Design Decisions

**GENERATED column**
`trainers.full_name` is computed automatically as `first_name || ' ' || last_name`. It cannot be inserted manually — PostgreSQL maintains it.

**DEFAULT values**
- `members.registered_at` defaults to `NOW()` — no manual timestamp needed on insert.
- `schedules.duration_minutes` defaults to `60`.
- `memberships.status` defaults to `'active'`.
- `payments.method` defaults to `'card'`.

**CHECK constraints**
| Constraint | Rule |
|---|---|
| Date after 2026-01-01 | `hired_date`, `start_date`, `starts_at` |
| Non-negative value | `price >= 0`, `quantity >= 0`, `amount > 0` |
| Enumerated value | `gender IN ('M','F','Other')`, `status IN (...)`, `specialization IN (...)` |
| Unique natural key | `email` on both `members` and `trainers` |
| NOT NULL | `first_name`, `last_name`, `email`, `gender` |

**ON DELETE behaviour**
- `RESTRICT` on most foreign keys — prevents accidental deletion of trainers, members, or classes that still have related records.
- `CASCADE` on `attendance` — if a schedule is deleted, all attendance records for it are automatically removed.

**Money columns**
All monetary values use `NUMERIC(10,2)` for exact arithmetic. `FLOAT` is avoided to prevent rounding errors.

**M:N bridge table**
`attendance` has its own surrogate primary key (`attendance_id SERIAL`) plus a `UNIQUE(member_id, schedule_id)` constraint to prevent a member from being registered to the same session twice.

---

## ALTER TABLE Changes

| # | Operation | What changed |
|---|---|---|
| 1 | `ALTER COLUMN TYPE` | `members.phone` widened to `VARCHAR(20)` for international numbers |
| 2 | `ALTER COLUMN TYPE` | `trainers.phone` widened to `VARCHAR(20)` |
| 3 | `ADD COLUMN` | `schedules.notes VARCHAR(255)` added for trainer remarks |
| 4 | `RENAME COLUMN` | `duration_min` renamed to `duration_minutes` for clarity |
| 5 | `ADD CONSTRAINT` | `uq_trainer_room_time` — a trainer cannot hold two classes in the same room at the same time |

---

## Roles

| Role | Privileges | Represents |
|---|---|---|
| `fitness_club_readonly` | `SELECT` on all tables | Reporting / analytics service |
| `fitness_club_writer` | `INSERT` on `attendance` and `payments` | Mobile app (check-in and payment recording) |

`UPDATE` on `payments` was revoked from `fitness_club_writer` — payment corrections must go through a separate audit-logged service.

---

## Re-runnability

The script is safe to run multiple times:
- All tables use `CREATE TABLE IF NOT EXISTS`
- `TRUNCATE ... RESTART IDENTITY CASCADE` resets data and sequences at the start of every INSERT block
- `ALTER` statements are guarded with `DO $$ IF NOT EXISTS ...` blocks
- Roles are dropped and recreated cleanly with `REASSIGN OWNED` + `DROP OWNED` + `DROP ROLE IF EXISTS`
