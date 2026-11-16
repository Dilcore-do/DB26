-- Part 1: Database setup
DROP TABLE IF EXISTS projects  CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP VIEW  IF EXISTS index_documentation;

CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);

CREATE TABLE employees (
    emp_id    INT PRIMARY KEY,
    emp_name  VARCHAR(100),
    dept_id   INT,
    salary    DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    proj_id   INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget    DECIMAL(12,2),
    dept_id   INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
(101, 'IT',         'Building A'),
(102, 'HR',         'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees VALUES
(1, 'John Smith',     101, 50000),
(2, 'Jane Doe',       101, 55000),
(3, 'Mike Johnson',   102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown',      103, 60000);

INSERT INTO projects VALUES
(201, 'Website Redesign',    75000,  101),
(202, 'Database Migration',  120000, 101),
(203, 'HR System Upgrade',   50000,  102);

-- Part 2: Creating basic indexes

-- Exercise 2.1: simple B-tree index
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';
-- Answer: 2 indexes: employees_pkey (created automatically for the
-- PRIMARY KEY) and emp_salary_idx (created by us).


-- Exercise 2.2: index on a foreign key column
CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;
-- Answer: PostgreSQL does NOT index foreign key columns automatically.
-- An index on the FK column helps because:
--   1) JOINs on dept_id can find matching rows quickly;
--   2) queries filtering by the FK (WHERE dept_id = ...) are faster;
--   3) when a row in departments is deleted or its key updated, the
--      database must check employees for referencing rows, and without
--      an index that check scans the whole employees table.
-- (On a 5-row table the planner still picks a Seq Scan, because reading
-- one page is cheaper than using the index. See Part 8.3.)


-- Exercise 2.3: view index information
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- Answer (at this point):
--   departments : departments_pkey   <- automatic (PRIMARY KEY)
--   employees   : emp_dept_idx       <- ours
--   employees   : emp_salary_idx     <- ours
--   employees   : employees_pkey     <- automatic (PRIMARY KEY)
--   projects    : projects_pkey      <- automatic (PRIMARY KEY)
-- The three *_pkey indexes were created automatically.

-- Part 3: Multicolumn indexes

-- Exercise 3.1
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;
-- Answer: for a query that filters ONLY by salary this index is not
-- useful (in practice). The leading column of the index is dept_id, and
-- the entries are sorted by dept_id first. Without a condition on dept_id
-- the database cannot jump to a narrow part of the index; it would have
-- to scan the whole index, which is rarely better than a Seq Scan.
-- For salary-only queries use a separate index on salary.


-- Exercise 3.2: column order
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

-- Query 1
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
-- Query 2
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
-- Answer: the order of conditions in WHERE does not matter: both queries
-- are identical for the planner and return the same rows.
-- The order of COLUMNS in the index does matter:
--   (dept_id, salary): equality on the first column narrows the search to
--                      one dept_id block, then the range on salary is read
--                      inside it in sorted order. Ideal for these queries.
--   (salary, dept_id): the range salary > 50000 covers many entries, and
--                      dept_id can only be checked while scanning them.
-- Rule: put columns used with "=" first, range columns after them, and
-- the most frequently filtered column first.

-- Part 4: Unique indexes

-- Exercise 4.1
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com'     WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com'       WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com'   WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com'      WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- Expected failure (wrapped in DO so the script continues)
DO $$
BEGIN
    INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
    VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'Error: %', SQLERRM;
END $$;
-- Answer: ERROR: duplicate key value violates unique constraint
-- "emp_email_unique_idx"
-- DETAIL: Key (email)=(john.smith@company.com) already exists.


-- Exercise 4.2: unique index vs UNIQUE constraint
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';
-- Answer: yes. PostgreSQL automatically created the index
-- employees_phone_key: a UNIQUE B-tree index. A UNIQUE constraint is
-- enforced through a unique index.

-- Part 5: Indexes and sorting

-- Exercise 5.1
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
-- Answer: a B-tree index stores values already sorted. With an index in
-- the needed order, PostgreSQL can read rows in the right order directly
-- and skip the separate sort step (especially useful with LIMIT: the
-- top N rows are taken from the start of the index).
-- (For a single column a plain ascending index can also be read
-- backwards; DESC matters most in multicolumn indexes with mixed order.)


-- Exercise 5.2: NULL ordering
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;
-- By default a B-tree stores values ASC with NULLs LAST. The index above
-- stores NULLs first, so it matches ORDER BY budget NULLS FIRST and the
-- sort can be avoided.

-- Part 6: Indexes on expressions

-- Exercise 6.1
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
-- Answer: without this index PostgreSQL does a sequential scan: it reads
-- every row and computes LOWER(emp_name) for each one, then compares.
-- A normal index on emp_name cannot be used here, because the query
-- compares the RESULT of the function, not the column itself.


-- Exercise 6.2
ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;
-- Returns John Smith and Sarah Williams. The expression in the query must
-- match the expression in the index exactly, otherwise the index is not used.

-- Part 7: Managing indexes

-- Exercise 7.1: rename
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees';


-- Exercise 7.2: drop a redundant index
DROP INDEX emp_salary_dept_idx;
-- Answer: an index should be dropped when it is redundant (another index
-- already covers the same queries), unused, or when the table is write-heavy.
-- Every index slows down INSERT/UPDATE/DELETE and takes disk space.


-- Exercise 7.3: reindex
REINDEX INDEX employees_salary_index;
-- REINDEX rebuilds the index from scratch. It is useful after bulk
-- INSERT/DELETE operations, when an index has become bloated, or after
-- significant data modifications.

-- Part 8: Practical scenarios

-- Exercise 8.1: optimize a slow query
-- Index for the WHERE clause (partial index: only rows with salary > 50000)
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
-- Index for the JOIN:      emp_dept_idx          (already created)
-- Index for the ORDER BY:  emp_salary_desc_idx   (already created)

SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;


-- Exercise 8.2: partial index
CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;
-- Answer: a partial index contains only the rows that satisfy its WHERE
-- condition, so it is smaller, faster to scan, takes less disk space, and
-- is cheaper to maintain (rows outside the condition do not touch it).
-- The planner uses it only if the query condition implies the index
-- condition (e.g. budget > 80000 or budget > 100000 works; budget > 50000 does not).


-- Exercise 8.3: EXPLAIN
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
-- Answer: on this tiny table the plan shows "Seq Scan on employees".
-- This tells us the planner estimates that reading the whole table (one
-- page) is cheaper than going through an index. Indexes pay off on large
-- tables where the condition selects a small fraction of the rows.
-- To see an Index Scan, force it or use a big table (next block):

SET enable_seqscan = off;
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
RESET enable_seqscan;

-- Same experiment on a large table (use these for your EXPLAIN screenshots):
DROP TABLE IF EXISTS big_employees;
CREATE TABLE big_employees AS
SELECT g AS emp_id,
       'Employee ' || g AS emp_name,
       101 + (g % 3)    AS dept_id,
       30000 + (g % 50000) AS salary
FROM generate_series(1, 500000) g;
ANALYZE big_employees;

-- WITHOUT an index: Seq Scan
EXPLAIN ANALYZE SELECT * FROM big_employees WHERE emp_id = 250000;

CREATE INDEX big_emp_id_idx ON big_employees(emp_id);
ANALYZE big_employees;

-- WITH the index: Index Scan, much faster
EXPLAIN ANALYZE SELECT * FROM big_employees WHERE emp_id = 250000;

-- Part 9: Index types comparison

-- Exercise 9.1: hash index
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';
-- Answer: a HASH index supports only equality (=). Use it when you
-- search only by exact match on a column (especially long values) and
-- never need range queries or sorting. In most cases B-tree is the
-- better default: it handles = as well as <, >, BETWEEN and ORDER BY.


-- Exercise 9.2: B-tree vs Hash
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx  ON projects USING HASH (proj_name);

-- Equality search (both can be used)
SELECT * FROM projects WHERE proj_name = 'Website Redesign';
-- Range search (only B-tree can be used)
SELECT * FROM projects WHERE proj_name > 'Database';
-- Hash cannot serve the range query, because hashing destroys ordering.

-- Part 10: Cleanup and best practices

-- Exercise 10.1: list all indexes and sizes
SELECT schemaname, tablename, indexname,
       pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- Answer (measured on PostgreSQL 16): the largest index is
-- big_emp_id_idx (about 11 MB), because it indexes 500,000 rows. The
-- indexes on the small tables are tiny: each B-tree is 16 kB (a metadata
-- page plus one data page), and each HASH index is 32 kB (it preallocates
-- more pages). Index size grows with the number of rows and with the
-- width of the indexed columns.
-- (If you run this query after dropping big_employees, the largest ones
-- are the two hash indexes, 32 kB each.)


-- Exercise 10.2: drop unnecessary indexes
DROP INDEX IF EXISTS proj_name_hash_idx;   -- duplicate of the B-tree index
DROP TABLE IF EXISTS big_employees;        -- demo table is no longer needed


-- Exercise 10.3: document the indexes
CREATE VIEW index_documentation AS
SELECT tablename,
       indexname,
       indexdef,
       'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;


-- Summary questions
-- 1. Default index type: B-tree.
-- 2. Create an index when a column is: (a) used often in WHERE filters on
--    a large table; (b) used in JOIN conditions / is a foreign key;
--    (c) used in ORDER BY; (d) must be unique (UNIQUE index).
-- 3. Do NOT create an index: (a) on small tables (Seq Scan is faster);
--    (b) on columns that are rarely queried, or on write-heavy tables
--    where the extra maintenance cost outweighs the read benefit;
--    (c) on columns with very few distinct values (e.g. boolean) when the
--    query selects a large share of the rows.
-- 4. On INSERT, UPDATE and DELETE every affected index must be updated too,
--    so writes become slower and indexes can bloat over time.
-- 5. Use EXPLAIN (or EXPLAIN ANALYZE) and look for "Index Scan" /
--    "Index Only Scan" / "Bitmap Index Scan" instead of "Seq Scan".

-- Additional challenges (optional)

-- 1. Index for finding employees hired in a specific month
CREATE INDEX emp_hire_month_idx ON employees(EXTRACT(MONTH FROM hire_date));
SELECT emp_name, hire_date FROM employees
WHERE EXTRACT(MONTH FROM hire_date) = 1;

-- 2. Composite unique index on dept_id and email
CREATE UNIQUE INDEX emp_dept_email_unique_idx ON employees(dept_id, email);

-- 3. EXPLAIN ANALYZE with and without an index: see the big_employees
--    experiment in Exercise 8.3 (Seq Scan before, Index Scan after).

-- 4. Covering index: INCLUDE stores extra columns in the index so the
--    query can be answered from the index alone (Index Only Scan).
CREATE INDEX emp_dept_covering_idx ON employees(dept_id) INCLUDE (emp_name, salary);
EXPLAIN SELECT emp_name, salary FROM employees WHERE dept_id = 101;


-- =====================================================================
-- Reflection: when to use indexes
-- =====================================================================
-- Indexes are worth creating on large tables for columns that are often
-- used in WHERE, JOIN, ORDER BY, and for uniqueness. B-tree is the right
-- default; hash is only for pure equality; expression indexes help when
-- queries filter by a function of a column (LOWER, EXTRACT); partial
-- indexes are good for a frequently queried subset of rows. Every index
-- costs disk space and slows writes, so remove redundant or unused ones
-- and always verify with EXPLAIN that the planner actually uses them.
