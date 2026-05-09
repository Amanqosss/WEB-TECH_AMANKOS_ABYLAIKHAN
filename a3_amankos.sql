-- ============================================================
-- Assignment 3: dvdrental Data Manipulation Script
-- Student: Amankos Abylaikhan
-- Email:   amankos@gmail.com
-- Films:   Harry Potter and the Chamber of Secrets, Rocky, John Wick
-- ============================================================

BEGIN;



INSERT INTO film (title, language_id, rental_duration, rental_rate, last_update)
SELECT
    'Harry Potter and the Chamber of Secrets',
    (SELECT language_id FROM language WHERE name = 'English'),
    7, 4.99, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM film WHERE title = 'Harry Potter and the Chamber of Secrets'
);

INSERT INTO film (title, language_id, rental_duration, rental_rate, last_update)
SELECT
    'Rocky',
    (SELECT language_id FROM language WHERE name = 'English'),
    14, 9.99, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM film WHERE title = 'Rocky'
);

INSERT INTO film (title, language_id, rental_duration, rental_rate, last_update)
SELECT
    'John Wick',
    (SELECT language_id FROM language WHERE name = 'English'),
    21, 19.99, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM film WHERE title = 'John Wick'
);



-- ---- Actors for Harry Potter and the Chamber of Secrets ----

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Daniel', 'Radcliffe', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Daniel' AND last_name = 'Radcliffe'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Emma', 'Watson', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Emma' AND last_name = 'Watson'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Rupert', 'Grint', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Rupert' AND last_name = 'Grint'
);

-- Link Harry Potter actors to film
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Daniel' AND last_name = 'Radcliffe'),
    (SELECT film_id  FROM film  WHERE title = 'Harry Potter and the Chamber of Secrets'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Emma' AND last_name = 'Watson'),
    (SELECT film_id  FROM film  WHERE title = 'Harry Potter and the Chamber of Secrets'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Rupert' AND last_name = 'Grint'),
    (SELECT film_id  FROM film  WHERE title = 'Harry Potter and the Chamber of Secrets'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

-- ---- Actors for Rocky ----

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Sylvester', 'Stallone', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Sylvester' AND last_name = 'Stallone'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Talia', 'Shire', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Talia' AND last_name = 'Shire'
);

-- Link Rocky actors to film
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Sylvester' AND last_name = 'Stallone'),
    (SELECT film_id  FROM film  WHERE title = 'Rocky'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Talia' AND last_name = 'Shire'),
    (SELECT film_id  FROM film  WHERE title = 'Rocky'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

-- ---- Actors for John Wick ----

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Keanu', 'Reeves', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Keanu' AND last_name = 'Reeves'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Ian', 'McShane', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Ian' AND last_name = 'McShane'
);

-- Link John Wick actors to film
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Keanu' AND last_name = 'Reeves'),
    (SELECT film_id  FROM film  WHERE title = 'John Wick'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Ian' AND last_name = 'McShane'),
    (SELECT film_id  FROM film  WHERE title = 'John Wick'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;



INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    (SELECT film_id FROM film WHERE title = 'Harry Potter and the Chamber of Secrets'),
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM inventory
    WHERE film_id = (SELECT film_id FROM film WHERE title = 'Harry Potter and the Chamber of Secrets')
      AND store_id = (SELECT MIN(store_id) FROM store)
);

INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    (SELECT film_id FROM film WHERE title = 'Rocky'),
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM inventory
    WHERE film_id = (SELECT film_id FROM film WHERE title = 'Rocky')
      AND store_id = (SELECT MIN(store_id) FROM store)
);

INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    (SELECT film_id FROM film WHERE title = 'John Wick'),
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM inventory
    WHERE film_id = (SELECT film_id FROM film WHERE title = 'John Wick')
      AND store_id = (SELECT MIN(store_id) FROM store)
);



-- Verify the target customer before updating (informational)
SELECT c.customer_id, c.first_name, c.last_name,
       COUNT(DISTINCT r.rental_id)  AS rental_count,
       COUNT(DISTINCT p.payment_id) AS payment_count
FROM customer c
JOIN rental  r ON c.customer_id = r.customer_id
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT r.rental_id)  >= 43
   AND COUNT(DISTINCT p.payment_id) >= 43
ORDER BY rental_count DESC
LIMIT 1;

UPDATE customer
SET
    first_name = 'Amankos',
    last_name  = 'Abylaikhan',
    email      = 'amankos@gmail.com',
    address_id = (SELECT MIN(address_id) FROM address),
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id
    FROM customer c
    JOIN rental  r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id)  >= 43
       AND COUNT(DISTINCT p.payment_id) >= 43
    ORDER BY COUNT(DISTINCT r.rental_id) DESC
    LIMIT 1
);



-- Preview payments to be deleted
SELECT * FROM payment
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan'
);

-- Delete payments
DELETE FROM payment
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan'
);

-- Preview rentals to be deleted
SELECT * FROM rental
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan'
);

-- Delete rentals
DELETE FROM rental
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan'
);



-- ---- Rental: Harry Potter and the Chamber of Secrets ----

INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT
    '2017-01-15 10:00:00',
    (
        SELECT i.inventory_id FROM inventory i
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'Harry Potter and the Chamber of Secrets'
          AND i.store_id = (SELECT MIN(store_id) FROM store)
        LIMIT 1
    ),
    (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan'),
    '2017-01-15 10:00:00'::TIMESTAMP + (
        SELECT rental_duration FROM film WHERE title = 'Harry Potter and the Chamber of Secrets'
    ) * INTERVAL '1 day',
    (SELECT MIN(staff_id) FROM staff),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM rental
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
      AND inventory_id = (
          SELECT i.inventory_id FROM inventory i
          JOIN film f ON i.film_id = f.film_id
          WHERE f.title = 'Harry Potter and the Chamber of Secrets'
            AND i.store_id = (SELECT MIN(store_id) FROM store)
          LIMIT 1
      )
)
RETURNING rental_id, rental_date, inventory_id, customer_id, return_date;

-- ---- Rental: Rocky ----

INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT
    '2017-02-10 11:00:00',
    (
        SELECT i.inventory_id FROM inventory i
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'Rocky'
          AND i.store_id = (SELECT MIN(store_id) FROM store)
        LIMIT 1
    ),
    (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan'),
    '2017-02-10 11:00:00'::TIMESTAMP + (
        SELECT rental_duration FROM film WHERE title = 'Rocky'
    ) * INTERVAL '1 day',
    (SELECT MIN(staff_id) FROM staff),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM rental
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
      AND inventory_id = (
          SELECT i.inventory_id FROM inventory i
          JOIN film f ON i.film_id = f.film_id
          WHERE f.title = 'Rocky'
            AND i.store_id = (SELECT MIN(store_id) FROM store)
          LIMIT 1
      )
);

-- ---- Rental: John Wick ----

INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT
    '2017-03-05 14:00:00',
    (
        SELECT i.inventory_id FROM inventory i
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'John Wick'
          AND i.store_id = (SELECT MIN(store_id) FROM store)
        LIMIT 1
    ),
    (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan'),
    '2017-03-05 14:00:00'::TIMESTAMP + (
        SELECT rental_duration FROM film WHERE title = 'John Wick'
    ) * INTERVAL '1 day',
    (SELECT MIN(staff_id) FROM staff),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM rental
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
      AND inventory_id = (
          SELECT i.inventory_id FROM inventory i
          JOIN film f ON i.film_id = f.film_id
          WHERE f.title = 'John Wick'
            AND i.store_id = (SELECT MIN(store_id) FROM store)
          LIMIT 1
      )
);

-- ---- Payment: Harry Potter and the Chamber of Secrets ----

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan'),
    (SELECT MIN(staff_id) FROM staff),
    (
        SELECT r.rental_id FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'Harry Potter and the Chamber of Secrets'
          AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
        LIMIT 1
    ),
    4.99,
    '2017-01-15 10:30:00'
WHERE NOT EXISTS (
    SELECT 1 FROM payment
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
      AND rental_id = (
          SELECT r.rental_id FROM rental r
          JOIN inventory i ON r.inventory_id = i.inventory_id
          JOIN film f ON i.film_id = f.film_id
          WHERE f.title = 'Harry Potter and the Chamber of Secrets'
            AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
          LIMIT 1
      )
);

-- ---- Payment: Rocky ----

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan'),
    (SELECT MIN(staff_id) FROM staff),
    (
        SELECT r.rental_id FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'Rocky'
          AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
        LIMIT 1
    ),
    9.99,
    '2017-02-10 11:30:00'
WHERE NOT EXISTS (
    SELECT 1 FROM payment
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
      AND rental_id = (
          SELECT r.rental_id FROM rental r
          JOIN inventory i ON r.inventory_id = i.inventory_id
          JOIN film f ON i.film_id = f.film_id
          WHERE f.title = 'Rocky'
            AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
          LIMIT 1
      )
);

-- ---- Payment: John Wick ----

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan'),
    (SELECT MIN(staff_id) FROM staff),
    (
        SELECT r.rental_id FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'John Wick'
          AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
        LIMIT 1
    ),
    19.99,
    '2017-03-05 14:30:00'
WHERE NOT EXISTS (
    SELECT 1 FROM payment
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
      AND rental_id = (
          SELECT r.rental_id FROM rental r
          JOIN inventory i ON r.inventory_id = i.inventory_id
          JOIN film f ON i.film_id = f.film_id
          WHERE f.title = 'John Wick'
            AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Amankos' AND last_name = 'Abylaikhan')
          LIMIT 1
      )
);

COMMIT;
