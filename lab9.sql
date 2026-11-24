-- PART 1: Database Setup (CityBike rental network)

DROP TABLE IF EXISTS rentals, bikes, members, stations CASCADE;

CREATE TABLE stations (
    station_id   INT PRIMARY KEY,
    station_name VARCHAR(50) NOT NULL,
    city         VARCHAR(40) NOT NULL,
    capacity     INT NOT NULL
);

CREATE TABLE bikes (
    bike_id    INT PRIMARY KEY,
    model      VARCHAR(50) NOT NULL,
    station_id INT REFERENCES stations(station_id),
    daily_rate NUMERIC(8,2) NOT NULL
);

CREATE TABLE members (
    member_id INT PRIMARY KEY,
    full_name VARCHAR(60) NOT NULL,
    city      VARCHAR(40) NOT NULL,
    joined_on DATE NOT NULL
);

CREATE TABLE rentals (
    rental_id  INT PRIMARY KEY,
    member_id  INT REFERENCES members(member_id),
    bike_id    INT REFERENCES bikes(bike_id),
    start_date DATE NOT NULL,
    end_date   DATE,
    fee        NUMERIC(8,2)
);

INSERT INTO stations VALUES
 (10, 'Central Park', 'Almaty',   4),
 (20, 'Riverside',    'Almaty',   3),
 (30, 'Expo Gate',    'Astana',   5),
 (40, 'Old Town',     'Shymkent', 2),
 (50, 'Depot',        'Astana',   0);

INSERT INTO bikes VALUES
 (101, 'City Cruiser', 10,  4.50),
 (102, 'City Cruiser', 10,  4.50),
 (103, 'Mountain X',   20,  7.00),
 (104, 'Mountain X',   30,  7.00),
 (105, 'Road Sprint',  30,  9.25),
 (106, 'Folding Mini', 40,  3.75),
 (107, 'Cargo Hauler', 20, 12.00),
 (108, 'Road Sprint',  10,  9.25);

INSERT INTO members VALUES
 (1, 'Aisha Nurlanova', 'Almaty',   DATE '2023-03-14'),
 (2, 'Daniyar Serik',   'Almaty',   DATE '2023-07-02'),
 (3, 'Marta Kowalski',  'Astana',   DATE '2024-01-20'),
 (4, 'Chen Wei',        'Astana',   DATE '2024-05-11'),
 (5, 'Omar Haddad',     'Shymkent', DATE '2024-09-30'),
 (6, 'Elena Petrova',   'Almaty',   DATE '2025-02-05');

INSERT INTO rentals VALUES
 ( 1, 1, 101, DATE '2024-04-05', DATE '2024-04-08', 13.50),
 ( 2, 1, 103, DATE '2024-06-11', DATE '2024-06-16', 35.00),
 ( 3, 1, 108, DATE '2025-02-02', DATE '2025-02-04', 18.50),
 ( 4, 1, 102, DATE '2025-05-20', DATE '2025-05-27', 31.50),
 ( 5, 2, 101, DATE '2024-05-01', DATE '2024-05-02',  4.50),
 ( 6, 2, 107, DATE '2024-11-15', DATE '2024-11-19', 48.00),
 ( 7, 2, 107, DATE '2025-03-08', DATE '2025-03-14', 72.00),
 ( 8, 3, 104, DATE '2024-02-14', DATE '2024-02-18', 28.00),
 ( 9, 3, 105, DATE '2024-08-03', DATE '2024-08-06', 27.75),
 (10, 3, 104, DATE '2025-01-09', DATE '2025-01-10',  7.00),
 (11, 3, 105, DATE '2025-06-01', DATE '2025-06-09', 74.00),
 (12, 4, 104, DATE '2024-07-19', DATE '2024-07-21', 14.00),
 (13, 4, 105, DATE '2025-04-12', DATE '2025-04-15', 27.75),
 (14, 4, 103, DATE '2025-07-23', DATE '2025-07-29', 42.00),
 (15, 5, 106, DATE '2024-10-05', DATE '2024-10-12', 26.25),
 (16, 5, 106, DATE '2025-01-18', DATE '2025-01-20',  7.50),
 (17, 5, 106, DATE '2025-08-14', DATE '2025-08-21', 26.25),
 (18, 2, 102, DATE '2025-09-02', DATE '2025-09-05', 13.50),
 (19, 1, 101, DATE '2025-10-10', NULL,              NULL),
 (20, 4, 108, DATE '2024-12-28', DATE '2025-01-03', 55.50),
 (21, 3, 103, DATE '2025-02-26', DATE '2025-03-02', 28.00),
 (22, 5, 104, DATE '2025-05-05', DATE '2025-05-08', 21.00);

SELECT (SELECT COUNT(*) FROM stations) AS stations,
       (SELECT COUNT(*) FROM bikes)    AS bikes,
       (SELECT COUNT(*) FROM members)  AS members,
       (SELECT COUNT(*) FROM rentals)  AS rentals;
-- Output: stations=5, bikes=8, members=6, rentals=22

-- PART 2: Your First Function

-- Exercise 2.1: A function over one row
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT)
RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date
    INTO v_days
    FROM rentals
    WHERE rental_id = p_rental_id;

    RETURN v_days;
END;
$$ LANGUAGE plpgsql;

SELECT rental_days(2);   -- Output: 5
SELECT rental_days(11);  -- Output: 8
SELECT rental_days(19);  -- Output: NULL
SELECT rental_days(999); -- Output: NULL

/*
Answer 2.1:
- For rental 19, the function returns NULL because the row exists, but its end_date column is NULL (open rental), and any arithmetic with NULL evaluates to NULL.
- For rental 999, the function also returns NULL, but because no row with rental_id = 999 exists in the table; SELECT ... INTO finds zero rows and leaves v_days as NULL.
- Therefore, the two NULLs are NOT produced for the same reason.
*/

-- Exercise 2.2: A function over many rows
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT)
RETURNS BIGINT AS $$
DECLARE
    v_cnt BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO v_cnt
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_cnt;
END;
$$ LANGUAGE plpgsql;

SELECT member_rental_count(1);  -- Output: 5
SELECT member_rental_count(5);  -- Output: 4
SELECT member_rental_count(6);  -- Output: 0
SELECT member_rental_count(99); -- Output: 0

/*
Answer 2.2:
The aggregate function COUNT(*) always counts the number of input rows matched by the query. When a member does not exist (or has no rentals), the filtered set has zero rows, and COUNT(*) over an empty set is defined to return 0 rather than NULL.
*/

-- Exercise 2.3: Returning text
CREATE OR REPLACE FUNCTION station_city(p_station_id INT)
RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR;
BEGIN
    SELECT city
    INTO v_city
    FROM stations
    WHERE station_id = p_station_id;

    RETURN v_city;
END;
$$ LANGUAGE plpgsql;

SELECT station_city(30); -- Output: Astana
SELECT station_city(77); -- Output: NULL

-- Exercise 2.4: Using a function inside a query
SELECT
    rental_id,
    member_id,
    rental_days(rental_id) AS duration_days
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY duration_days DESC, rental_id ASC;

/*
Output 2.4:
 rental_id | member_id | duration_days
-----------+-----------+---------------
        11 |         3 |             8
         4 |         1 |             7
        15 |         5 |             7
        17 |         5 |             7
         7 |         2 |             6
        14 |         4 |             6
        20 |         4 |             6
         2 |         1 |             5
*/

-- PART 3: Parameter Modes

-- Exercise 3.1: IN parameters
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
DECLARE
    v_discounted NUMERIC;
BEGIN
    v_discounted := ROUND(p_fee * (1 - p_percent / 100.0), 2);
    RETURN v_discounted;
END;
$$ LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15); -- Output: 62.90

-- Exercise 3.2: OUT parameters
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id INT,
    OUT rental_cnt INT,
    OUT total_fee NUMERIC,
    OUT last_start DATE
)
AS $$
BEGIN
    SELECT
        COUNT(*)::INT,
        COALESCE(SUM(fee), 0),
        MAX(start_date)
    INTO rental_cnt, total_fee, last_start
    FROM rentals
    WHERE member_id = p_member_id;
END;
$$ LANGUAGE plpgsql;

SELECT member_stats(3);
-- Output: (5,164.75,2025-06-01)

SELECT * FROM member_stats(3);
-- Output:
--  rental_cnt | total_fee | last_start
-- ------------+-----------+------------
--           5 |    164.75 | 2025-06-01

SELECT * FROM member_stats(6);
-- Output:
--  rental_cnt | total_fee | last_start
-- ------------+-----------+------------
--           0 |         0 | NULL

/*
Answer 3.2:
- "SELECT member_stats(3);" returns a single composite column (a record tuple), whereas "SELECT * FROM member_stats(3);" expands the OUT parameters into separate named columns (rental_cnt, total_fee, last_start).
- Inside a larger query, "SELECT * FROM member_stats(...)" (or LATERAL member_stats(...)) is preferred because you can directly reference each output column by name and join or filter on it cleanly.
- For member 6, it returns: rental_cnt = 0, total_fee = 0, last_start = NULL.
*/

-- Exercise 3.3: INOUT parameters
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC)
AS $$
BEGIN
    p_fee := p_fee + 5.00;
END;
$$ LANGUAGE plpgsql;

SELECT apply_late_fee(fee) AS updated_fee
FROM rentals
WHERE rental_id = 1;
-- Output: 18.50

/*
Answer 3.3:
Because p_fee is declared with the INOUT mode, PostgreSQL automatically treats it as both an input argument and an output return column. When a function has OUT or INOUT parameters, the final values of those parameters are returned automatically when the block finishes without needing a RETURNS clause or RETURN statement.
*/

-- Exercise 3.4: VARIADIC parameters
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC
)
AS $$
BEGIN
    SELECT
        SUM(p_fees[g.i]),
        ROUND(AVG(p_fees[g.i]), 2),
        MAX(p_fees[g.i])
    INTO total, average, largest
    FROM generate_subscripts(p_fees, 1) AS g(i);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
-- Output:
--  total | average | largest
-- -------+---------+---------
--  98.50 |   24.63 |   35.00

SELECT * FROM fee_summary();
-- Output:
--  total | average | largest
-- -------+---------+---------
--   NULL |    NULL |    NULL

/*
Answer 3.4:
- Calling fee_summary() with no arguments passes an empty array, so generate_subscripts produces zero rows and all three aggregates (SUM, AVG, MAX) return NULL.
- A VARIADIC parameter must be last because it collects all remaining trailing arguments of that type into an array; if parameters followed it, PostgreSQL could not tell where the variadic list ends and the subsequent parameters begin.
*/

-- Exercise 3.5: Choosing a mode
/*
Answer 3.5:
(a) IN: The row ID is read-only input needed only to look up the record and is not modified for the caller.
(b) INOUT: The caller supplies an initial running balance, and the function updates that same value and returns it back.
(c) VARIADIC: It allows callers to pass an arbitrary number of station IDs naturally as comma-separated arguments collected into an array.
(d) OUT: Two separate OUT parameters allow returning both aggregate statistics from a single query pass without defining a custom composite type or table.
*/

-- PART 4: Default Values and Function Overloading

-- Exercise 4.1: A function with one parameter
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1); -- Output: 98.50
SELECT total_fees(6); -- Output: 0

-- Exercise 4.2: Overloading the name
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01'); -- Output: 98.50
SELECT total_fees(1, DATE '2025-01-01'); -- Output: 50.00

-- Inspecting overloaded signatures in catalog (equivalent to \df total_fees in psql):
SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS signature_args
FROM pg_proc p
WHERE p.proname = 'total_fees'
ORDER BY signature_args;

-- Exercise 4.3: Giving a parameter a default value
CREATE OR REPLACE FUNCTION total_fees(
    p_member_id INT,
    p_from_date DATE DEFAULT DATE '2025-01-01'
)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- The call below intentionally fails with ambiguity (commented out so the script runs cleanly end-to-end):
-- SELECT total_fees(1);

/*
Answer 4.3 (Exact Error Message & Explanation):
ERROR:  function total_fees(integer) is not unique
LINE 1: SELECT total_fees(1);
               ^
HINT:  Could not choose a best candidate function. You might need to add explicit type casts.

Explanation:
Once p_from_date has a DEFAULT value, total_fees(INT, DATE) can also be invoked with a single INTEGER argument. PostgreSQL now sees two equally valid candidates for total_fees(1)—the original 1-argument total_fees(INT) and the 2-argument total_fees(INT, DATE) using its default—so it refuses to guess which one you meant.
*/

-- Exercise 4.4: Resolving the ambiguity
DROP FUNCTION total_fees(INTEGER);

SELECT total_fees(1); -- Output: 50.00

/*
Answer 4.4:
- Now the two-parameter version total_fees(INT, DATE) with DEFAULT DATE '2025-01-01' answers the call, returning 50.00 (Aisha's fees from 2025-01-01 onward: 18.50 + 31.50).
- Dropping the other version (total_fees(INTEGER, DATE)) would NOT have given the same answer: it would have left total_fees(INTEGER), which sums all rentals regardless of date and returns 98.50.
*/

-- Exercise 4.5: Overloading on type, not just on count
CREATE OR REPLACE FUNCTION total_fees(p_member_name VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0)
    INTO v_total
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    WHERE m.full_name = p_member_name;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova'); -- Output: 98.50
SELECT total_fees(1);                  -- Output: 50.00

/*
Answer 4.5:
- Adding total_fees(VARCHAR) does not cause an ambiguity error because its first parameter has a string type rather than INTEGER, so PostgreSQL resolves calls unambiguously by argument type.
- total_fees('Aisha Nurlanova') calls total_fees(VARCHAR), which joins members and rentals across all dates and returns 98.50.
- total_fees(1) calls total_fees(INT, DATE DEFAULT '2025-01-01'), which filters rentals with start_date >= '2025-01-01' and returns 50.00.
*/

-- PART 5: Functions That Return a Table

-- Exercise 5.1: Search by pattern
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (
    found_id INT,
    found_model VARCHAR,
    found_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.bike_id,
        b.model,
        b.daily_rate
    FROM bikes b
    WHERE b.model ILIKE p_pattern
    ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
-- Output:
--  found_id | found_model | found_rate
-- ----------+-------------+------------
--       105 | Road Sprint |       9.25
--       108 | Road Sprint |       9.25

SELECT * FROM find_bikes('%Mini');
-- Output:
--  found_id | found_model  | found_rate
-- ----------+--------------+------------
--       106 | Folding Mini |       3.75

SELECT find_bikes('%road%');
-- Output:
--         find_bikes
-- -------------------------
--  (105,"Road Sprint",9.25)
--  (108,"Road Sprint",9.25)

/*
Answer 5.1:
Running "SELECT find_bikes('%road%');" without FROM calls the set-returning function in the SELECT target list, so each returned row is packaged into a single composite tuple column named find_bikes instead of being expanded into three separate columns (found_id, found_model, found_rate).
*/

-- Exercise 5.2: A table from a join
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (
    rental_id INT,
    bike_model VARCHAR,
    station_name VARCHAR,
    duration_days INT,
    fee NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.rental_id,
        b.model,
        s.station_name,
        (r.end_date - r.start_date)::INT,
        r.fee
    FROM rentals r
    JOIN bikes b ON b.bike_id = r.bike_id
    LEFT JOIN stations s ON s.station_id = b.station_id
    WHERE r.member_id = p_member_id
    ORDER BY r.start_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM member_history(3);
-- Output:
--  rental_id | bike_model  | station_name | duration_days |  fee
-- -----------+-------------+--------------+---------------+-------
--          8 | Mountain X  | Expo Gate    |             4 | 28.00
--          9 | Road Sprint | Expo Gate    |             3 | 27.75
--         10 | Mountain X  | Expo Gate    |             1 |  7.00
--         21 | Mountain X  | Riverside    |             5 | 28.00
--         11 | Road Sprint | Expo Gate    |             8 | 74.00

-- Exercise 5.3: When the column names collide
-- Problematic version (creates fine, fails at call time; commented out after verification):
/*
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

Exact Error Message:
ERROR:  column reference "bike_id" is ambiguous
LINE 1: SELECT bike_id, model FROM bikes WHERE station_id = p_statio...
               ^
DETAIL:  It could refer to either a PL/pgSQL variable or a table column.
QUERY:  SELECT bike_id, model FROM bikes WHERE station_id = p_station_id
CONTEXT:  PL/pgSQL function bike_list(integer) line 3 at RETURN QUERY

Why the error appears only at call time:
CREATE FUNCTION only stores the function body as text and performs basic syntax validation. PL/pgSQL parses and plans embedded SQL statements lazily on first execution, which is when it discovers the name collision between the RETURNS TABLE output variables (bike_id, model) and the columns of table bikes.
*/

-- Fix 1: Renaming the output columns
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model
    FROM bikes b
    WHERE b.station_id = p_station_id
    ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- Fix 2: Keeping the output column names and qualifying table columns with an alias
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model
    FROM bikes AS b
    WHERE b.station_id = p_station_id
    ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);
-- Output:
--  bike_id |    model
-- ---------+--------------
--      101 | City Cruiser
--      102 | City Cruiser
--      108 | Road Sprint

-- Exercise 5.4: Casting the output
/*
Answer 5.4 (Exact Error Message without ::INT cast):
If COUNT(*) is returned directly for an INT column without casting, PostgreSQL raises:
ERROR:  structure of query does not match function result type
DETAIL:  Returned type bigint does not match expected type integer in column 2.
CONTEXT:  PL/pgSQL function station_board(character varying) line 3 at RETURN QUERY
*/

CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (
    s_name VARCHAR,
    s_bikes INT,
    s_free INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.station_name::VARCHAR,
        COUNT(b.bike_id)::INT AS s_bikes,
        (s.capacity - COUNT(b.bike_id))::INT AS s_free
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');
-- Output:
--     s_name    | s_bikes | s_free
-- --------------+---------+--------
--  Central Park |       3 |      1
--  Riverside    |       2 |      1

SELECT * FROM station_board('Astana');
-- Output:
--   s_name   | s_bikes | s_free
-- -----------+---------+--------
--  Expo Gate |       2 |      3
--  Depot     |       0 |      0

-- PART 6: Block Structure, DO Blocks and Subblocks

-- Exercise 6.1: An anonymous block
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report $$;
-- Output: NOTICE:  The rentals table holds 22 rows.

/*
Answer 6.1:
If the label after END does not match the opening <<label>>, PostgreSQL immediately fails with a syntax/compilation error:
ERROR:  end label "wrong_name" does not match label "rental_report"
*/

-- Exercise 6.2: A subblock and a hidden variable
DO $$
<<outer_block>>
DECLARE
    fee_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO fee_total FROM rentals;
    RAISE NOTICE '1. Outer fee_total before subblock: %', fee_total;

    <<inner_block>>
    DECLARE
        fee_total NUMERIC;
    BEGIN
        SELECT COALESCE(SUM(fee), 0)
        INTO fee_total
        FROM rentals
        WHERE start_date >= DATE '2025-01-01';

        RAISE NOTICE '2. Subblock own fee_total: %', fee_total;
        RAISE NOTICE '3. Outer fee_total via label: %', outer_block.fee_total;
    END inner_block;

    RAISE NOTICE '4. Outer fee_total after subblock: %', fee_total;
END outer_block $$;

/*
Answer 6.2:
- Printed values:
  1. 535.25
  2. 283.25
  3. 535.25
  4. 535.25
- No, the assignment inside the subblock did NOT change the outer variable.
- This shows that declarations are block-scoped: declaring a variable with the same name in a subblock creates a distinct local variable that shadows the outer one for the duration of the subblock without overwriting it.
*/

-- Exercise 6.3: Declarations are local
/*
First attempt (reading subblock 1's local variable from subblock 2):
DO $$
BEGIN
    BEGIN
        DECLARE
            v_local_only INT := 42;
        BEGIN
            RAISE NOTICE 'Subblock 1: %', v_local_only;
        END;
    END;

    BEGIN
        RAISE NOTICE 'Subblock 2: %', v_local_only;
    END;
END $$;

Recorded Error:
ERROR:  column "v_local_only" does not exist
LINE 1: SELECT v_local_only
               ^
*/

-- Fixed version: declaration moved up into the outer block
DO $$
DECLARE
    v_shared_val INT := 42;
BEGIN
    BEGIN
        RAISE NOTICE 'Subblock 1 sees: %', v_shared_val;
    END;

    BEGIN
        RAISE NOTICE 'Subblock 2 sees: %', v_shared_val;
    END;
END $$;
-- Output:
-- NOTICE:  Subblock 1 sees: 42
-- NOTICE:  Subblock 2 sees: 42

-- Exercise 6.4: From a block to a function
CREATE OR REPLACE FUNCTION fee_split(
    p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total NUMERIC
)
AS $$
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO before_total
    FROM rentals
    WHERE start_date < p_from_date;

    SELECT COALESCE(SUM(fee), 0)
    INTO after_total
    FROM rentals
    WHERE start_date >= p_from_date;
END;
$$ LANGUAGE plpgsql;

SELECT
    before_total,
    after_total,
    before_total + after_total AS combined,
    (SELECT COALESCE(SUM(fee), 0) FROM rentals) AS table_total
FROM fee_split(DATE '2025-01-01');
-- Output:
--  before_total | after_total | combined | table_total
-- --------------+-------------+----------+-------------
--        252.00 |      283.25 |   535.25 |      535.25

-- PART 7: Practical Scenarios

-- Exercise 7.1: Station occupancy
CREATE OR REPLACE FUNCTION station_load(
    p_station_id INT,
    OUT bikes_parked INT,
    OUT capacity_pct NUMERIC
)
AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT capacity
    INTO v_capacity
    FROM stations
    WHERE station_id = p_station_id;

    SELECT COUNT(*)::INT
    INTO bikes_parked
    FROM bikes
    WHERE station_id = p_station_id;

    IF v_capacity IS NULL OR v_capacity = 0 THEN
        capacity_pct := 0.0;
    ELSE
        capacity_pct := ROUND((bikes_parked::NUMERIC / v_capacity::NUMERIC) * 100.0, 1);
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
FROM stations s, LATERAL station_load(s.station_id) l
ORDER BY s.station_id;
-- Output:
--  station_id | station_name | bikes_parked | capacity_pct
-- ------------+--------------+--------------+--------------
--          10 | Central Park |            3 |         75.0
--          20 | Riverside    |            2 |         66.7
--          30 | Expo Gate    |            2 |         40.0
--          40 | Old Town     |            1 |         50.0
--          50 | Depot        |            0 |          0.0

/*
Answer 7.1:
When capacity = 0 (Station 50, Depot), the function returns 0.0 for capacity_pct instead of raising division-by-zero. Returning 0.0 keeps the numeric column clean and safe for downstream aggregations or UI display when zero bikes are parked at a zero-capacity depot.
*/

-- Exercise 7.2: Top members, with a default
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (
    member_name VARCHAR,
    rental_count BIGINT,
    total_spent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.full_name,
        COUNT(r.rental_id) AS rental_count,
        COALESCE(SUM(r.fee), 0) AS total_spent
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    GROUP BY m.member_id, m.full_name
    ORDER BY total_spent DESC, m.member_id ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM top_members();
-- Output:
--   member_name   | rental_count | total_spent
-- ----------------+--------------+-------------
--  Marta Kowalski |            5 |      164.75
--  Chen Wei       |            4 |      139.25
--  Daniyar Serik  |            4 |      138.00

SELECT * FROM top_members(6);
-- Output:
--    member_name   | rental_count | total_spent
-- -----------------+--------------+-------------
--  Marta Kowalski  |            5 |      164.75
--  Chen Wei        |            4 |      139.25
--  Daniyar Serik   |            4 |      138.00
--  Aisha Nurlanova |            5 |       98.50
--  Omar Haddad     |            4 |       81.00
--  Elena Petrova   |            0 |           0

/*
Answer 7.2:
Aisha Nurlanova has 5 rentals (more than Chen Wei and Daniyar Serik, who each have 4 rentals), yet she is ranked 4th below them. This is not a bug because the function ranks members by total_spent DESC ($98.50 vs. $139.25 and $138.00), not by rental_count, and one of Aisha's 5 rentals is still open with a NULL fee.
*/

-- Exercise 7.3: An invoice for an open rental
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (
    member_name VARCHAR,
    bike_model VARCHAR,
    days INT,
    amount_owed NUMERIC,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.full_name,
        b.model,
        (COALESCE(r.end_date, CURRENT_DATE) - r.start_date)::INT AS days,
        ROUND(((COALESCE(r.end_date, CURRENT_DATE) - r.start_date)::NUMERIC * b.daily_rate), 2) AS amount_owed,
        CASE
            WHEN r.end_date IS NULL THEN 'OPEN'
            ELSE 'CLOSED'
        END AS status
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    JOIN bikes b ON b.bike_id = r.bike_id
    WHERE r.rental_id = p_rental_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);
-- Output:
--   member_name   | bike_model  | days | amount_owed | status
-- ----------------+-------------+------+-------------+--------
--  Marta Kowalski | Road Sprint |    8 |       74.00 | CLOSED

SELECT * FROM rental_invoice(19);
-- Output (depends on CURRENT_DATE; e.g. on 2026-11-24: 410 days * 4.50 = 1845.00, status = OPEN):
--    member_name   |  bike_model  | days | amount_owed | status
-- -----------------+--------------+------+-------------+--------
--  Aisha Nurlanova | City Cruiser |  410 |     1845.00 | OPEN

/*
Answer 7.3:
- Yes, for rental 11 the calculated amount_owed is 74.00, which equals the stored fee in the rentals table.
- For rental 19, end_date is NULL, so the query substitutes CURRENT_DATE; each new calendar day increases (CURRENT_DATE - start_date) by 1 day and adds one daily_rate ($4.50) to amount_owed.
- Because the result depends on CURRENT_DATE and changes over time for identical input arguments, the function CANNOT be marked IMMUTABLE (it must be STABLE or VOLATILE).
*/

-- Exercise 7.4: A report per city
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (
    member_count BIGINT,
    rental_count BIGINT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT m.member_id) AS member_count,
        COUNT(r.rental_id) AS rental_count,
        COALESCE(SUM(r.fee), 0) AS total_revenue
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (
    member_count BIGINT,
    rental_count BIGINT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT m.member_id) AS member_count,
        COUNT(r.rental_id) AS rental_count,
        COALESCE(SUM(r.fee), 0) AS total_revenue
    FROM members m
    LEFT JOIN rentals r
        ON r.member_id = m.member_id
       AND r.start_date >= p_from_date
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
-- Output:
--  member_count | rental_count | total_revenue
-- --------------+--------------+---------------
--             3 |           10 |        236.50

SELECT * FROM city_report('Almaty', DATE '2025-01-01');
-- Output:
--  member_count | rental_count | total_revenue
-- --------------+--------------+---------------
--             3 |            5 |        135.50

/*
Answer 7.4:
- The date condition belongs in the LEFT JOIN's ON clause, not in the WHERE clause.
- When placed in the ON clause, Almaty reports member_count = 3 (including Elena Petrova, who has 0 rentals).
- If placed in the WHERE clause ("WHERE m.city = p_city AND r.start_date >= p_from_date"), the LEFT JOIN effectively turns into an INNER JOIN because rows with NULL r.start_date are eliminated, dropping Elena Petrova and reducing Almaty's member_count from 3 to 2.
*/


-- ============================================================================
-- LAB QUESTIONS (Answers 1 to 10)
-- ============================================================================
/*
1. Function Name vs. Signature:
   A function's name is just its identifier (e.g., total_fees), whereas its signature is the combination of the function name and its ordered list of input argument types (e.g., total_fees(integer, date)). Because overloaded functions share the same name, PostgreSQL requires the signature in DROP FUNCTION to know which specific overload to remove.

2. Purpose of Dollar Quoting ($$):
   Dollar quoting delimits the function body so you do not have to escape single quotes inside SQL string literals by doubling them ('').
   Example that would be awkward without $$:
   CREATE FUNCTION almaty_count() RETURNS BIGINT AS $$
   BEGIN
       RETURN (SELECT COUNT(*) FROM stations WHERE city = 'Almaty' AND station_name <> 'Depot');
   END;
   $$ LANGUAGE plpgsql;

3. Multiple OUT Parameters vs. RETURNS TABLE:
   Choose multiple OUT parameters when a function returns a single row of summary values (scalar tuple) without needing RETURN QUERY. Choose RETURNS TABLE(...) when the function returns a multi-row result set generated by a query (via RETURN QUERY or RETURN NEXT) with explicit column names and types.

4. Why VARIADIC Must Be Last:
   A VARIADIC parameter absorbs all remaining trailing arguments of the same type into an array. If another parameter followed it—for example, fn(VARIADIC nums INT[], flag INT)—a call like fn(1, 2, 3) would be impossible to resolve because PostgreSQL could not tell whether 3 belongs to nums or to flag.

5. RETURN vs. RETURN QUERY:
   RETURN expression returns a single value (or exits a void/OUT-parameter function) and immediately terminates execution. RETURN QUERY SELECT ... appends all rows produced by the query to the function's output set and continues executing subsequent statements in the block.

6. Risk of Adding DEFAULT Parameters:
   Adding a DEFAULT value allows a function to be called with fewer arguments, which can match the argument count and types of an existing overload and cause an "is not unique" ambiguity error. In production, avoid adding defaults that collide with existing signatures, check pg_proc before altering overloads, or use distinct function names.

7. Subblock Variable Lifetime & Shadowed Outer Variables:
   When a subblock ends, any variable declared inside it goes out of scope and is destroyed. To read a shadowed outer variable from inside a subblock, attach a <<label>> to the outer block and qualify the variable name as outer_label.variable_name.

8. Advantage and Disadvantage of Business Rules in Stored Functions:
   Advantage: Centralizes business logic in one place inside the database (shared consistently across all clients with fewer network round trips).
   Disadvantage: Harder to version-control, unit-test, and port across different DBMSs, while shifting CPU load onto the database server.

9. Trusted vs. Untrusted Languages:
   A trusted language (such as PL/pgSQL) runs inside the database sandbox and cannot access the host OS, file system, or network, so regular database users with CREATE privileges on a schema can write functions in it. An untrusted language (such as PL/Python or C) can interact directly with the operating system and external resources, so only a database superuser is allowed to create functions in it.

10. Changing Argument Types with CREATE OR REPLACE FUNCTION:
    CREATE OR REPLACE FUNCTION only replaces an existing function if both its name and its exact input argument types match. If you change the argument types, PostgreSQL leaves the old function intact and creates a brand-new overloaded function, which can lead to stale definitions and unexpected call ambiguity.
*/


-- ============================================================================
-- OPTIONAL ADDITIONAL CHALLENGES (1 to 5)
-- ============================================================================

-- Challenge 1: busiest_station
CREATE OR REPLACE FUNCTION busiest_station(p_from_date DATE DEFAULT DATE '2024-01-01')
RETURNS TABLE (
    station_id INT,
    station_name VARCHAR,
    city VARCHAR,
    total_rental_days BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.station_id,
        s.station_name,
        s.city,
        COALESCE(SUM(COALESCE(r.end_date, CURRENT_DATE) - r.start_date), 0)::BIGINT AS total_rental_days
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    LEFT JOIN rentals r
        ON r.bike_id = b.bike_id
       AND r.start_date >= p_from_date
    GROUP BY s.station_id, s.station_name, s.city
    ORDER BY total_rental_days DESC, s.station_id ASC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM busiest_station();

-- Challenge 2: Loop over members with FOR ... IN SELECT ... LOOP
CREATE OR REPLACE FUNCTION summarize_members_notice()
RETURNS VOID AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT
            m.member_id,
            m.full_name,
            COUNT(r.rental_id) AS rental_cnt,
            COALESCE(SUM(r.fee), 0) AS total_spent
        FROM members m
        LEFT JOIN rentals r ON r.member_id = m.member_id
        GROUP BY m.member_id, m.full_name
        ORDER BY m.member_id
    LOOP
        RAISE NOTICE 'Member #% (%): % rentals, total spent = %',
            rec.member_id, rec.full_name, rec.rental_cnt, rec.total_spent;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT summarize_members_notice();
-- Comparison: A single set-based SELECT query is far faster, cleaner, and easier for applications to consume than row-by-row procedural looping with RAISE NOTICE; ship the single SELECT query in production.

-- Challenge 3: rental_days raising an exception for unknown IDs
CREATE OR REPLACE FUNCTION rental_days_strict(p_rental_id INT)
RETURNS INT AS $$
DECLARE
    v_start DATE;
    v_end DATE;
BEGIN
    SELECT start_date, end_date
    INTO v_start, v_end
    FROM rentals
    WHERE rental_id = p_rental_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Rental ID % not found', p_rental_id;
    END IF;

    RETURN v_end - v_start;
END;
$$ LANGUAGE plpgsql;

SELECT rental_days_strict(2);
-- Analysis: Raising an exception is great for single-record validation, but inside a large set-based query one bad ID will abort the entire query instead of cleanly returning NULL.

-- Challenge 4: Overloading fee_report(INT), fee_report(VARCHAR), and fee_report(TEXT)
CREATE OR REPLACE FUNCTION fee_report(p_member_id INT)
RETURNS NUMERIC AS $$
BEGIN
    RETURN COALESCE((SELECT SUM(fee) FROM rentals WHERE member_id = p_member_id), 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fee_report(p_city VARCHAR)
RETURNS NUMERIC AS $$
BEGIN
    RETURN COALESCE((
        SELECT SUM(r.fee)
        FROM rentals r
        JOIN members m ON m.member_id = r.member_id
        WHERE m.city = p_city
    ), 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fee_report(p_pattern TEXT)
RETURNS NUMERIC AS $$
BEGIN
    RETURN COALESCE((
        SELECT SUM(r.fee)
        FROM rentals r
        JOIN members m ON m.member_id = r.member_id
        WHERE m.full_name ILIKE ('%' || p_pattern || '%')
    ), 0);
END;
$$ LANGUAGE plpgsql;

-- Explanation: Creating fee_report(TEXT) succeeds because TEXT and VARCHAR have distinct OIDs in pg_proc. However, calling fee_report('Almaty') with an untyped string literal will now prefer TEXT (the preferred type in the string category) or cause ambiguity depending on casts, making calls error-prone.

-- Challenge 5: CREATE PROCEDURE and CALL to close an open rental
CREATE OR REPLACE PROCEDURE close_rental(
    p_rental_id INT,
    p_end_date DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_date DATE;
    v_daily_rate NUMERIC(8,2);
    v_fee NUMERIC(8,2);
BEGIN
    SELECT r.start_date, b.daily_rate
    INTO v_start_date, v_daily_rate
    FROM rentals r
    JOIN bikes b ON b.bike_id = r.bike_id
    WHERE r.rental_id = p_rental_id
      AND r.end_date IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Open rental % not found or already closed', p_rental_id;
    END IF;

    IF p_end_date < v_start_date THEN
        RAISE EXCEPTION 'End date % cannot precede start date %', p_end_date, v_start_date;
    END IF;

    v_fee := ROUND(((p_end_date - v_start_date)::NUMERIC * v_daily_rate), 2);

    UPDATE rentals
    SET end_date = p_end_date,
        fee = v_fee
    WHERE rental_id = p_rental_id;
END;
$$;

-- Example call (kept commented out to preserve original dataset state):
-- CALL close_rental(19, DATE '2025-10-15');
-- Explanation: Unlike a function, a procedure is invoked with CALL (not inside SELECT) and can manage transactions directly (e.g., execute COMMIT and ROLLBACK inside its body).