-- Part 1: Database Setup

CREATE TABLE employees (
    emp_id   INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id  INT,
    salary   DECIMAL(10, 2)
);

CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);

CREATE TABLE projects (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id      INT,
    budget       DECIMAL(10, 2)
);

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith',     101,  50000),
(2, 'Jane Doe',       102,  60000),
(3, 'Mike Johnson',   101,  55000),
(4, 'Sarah Williams', 103,  65000),
(5, 'Tom Brown',      NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT',        'Building A'),
(102, 'HR',        'Building B'),
(103, 'Finance',   'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign',   101,  100000),
(2, 'Employee Training',  102,  50000),
(3, 'Budget Analysis',    103,  75000),
(4, 'Cloud Migration',    101,  150000),
(5, 'AI Research',        NULL, 200000);

-- Part 2: CROSS JOIN

-- Exercise 2.1
SELECT e.emp_name, d.dept_name
FROM employees e CROSS JOIN departments d;
-- Answer: 5 x 4 = 20 rows (N = 5 employees, M = 4 departments).

-- Exercise 2.2 a) comma notation
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

-- Exercise 2.2 b) INNER JOIN ... ON TRUE
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

-- Exercise 2.3: all employees x all projects (availability matrix)
SELECT e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;
-- 5 x 5 = 25 rows.

-- Part 3: INNER JOIN

-- Exercise 3.1
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
-- Answer: 4 rows. Tom Brown is excluded because his dept_id is NULL,
-- and NULL = anything is never true, so he has no matching department.

-- Exercise 3.2
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);
-- Answer: with USING the join column dept_id appears only once in the
-- output (with SELECT *), while with ON both e.dept_id and d.dept_id appear.

-- Exercise 3.3
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;
-- NATURAL joins on all columns with the same name (here only dept_id).

-- Exercise 3.4
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;
-- 6 rows: John and Mike (IT) x 2 projects, Jane (HR) x 1, Sarah (Finance) x 1.

-- Part 4: LEFT JOIN

-- Exercise 4.1
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
-- Answer: Tom Brown is present; emp_dept, dept_dept and dept_name are NULL.

-- Exercise 4.2
SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id);

-- Exercise 4.3: employees without a department
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;
-- Result: Tom Brown.

-- Exercise 4.4: employee count per department (including 0)
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;
-- IT = 2, HR = 1, Finance = 1, Marketing = 0.

-- Part 5: RIGHT JOIN

-- Exercise 5.1
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- Exercise 5.2: same result using LEFT JOIN (tables swapped)
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id;

-- Exercise 5.3: departments without employees
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;
-- Result: Marketing (Building D).

-- Part 6: FULL JOIN

-- Exercise 6.1
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
-- Answer: NULLs on the left side (employee columns): Marketing department
-- (no employees). NULLs on the right side (department columns): Tom Brown
-- (no department).

-- Exercise 6.2
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;
-- Marketing has no projects; the 'AI Research' project has no department.

-- Exercise 6.3: orphaned records
SELECT
    CASE
        WHEN e.emp_id IS NULL THEN 'Department without employees'
        WHEN d.dept_id IS NULL THEN 'Employee without department'
        ELSE 'Matched'
    END AS record_status,
    e.emp_name,
    d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

-- Part 7: ON vs WHERE

-- Exercise 7.1: filter in ON (LEFT JOIN)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';
-- All 5 employees are returned; dept_name is filled only for IT employees
-- (John, Mike), the others get NULL.

-- Exercise 7.2: filter in WHERE (LEFT JOIN)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- Only 2 rows (John, Mike). The WHERE filter runs after the join and removes
-- rows with NULL or other locations, so the LEFT JOIN behaves like an INNER JOIN.

-- Exercise 7.3: same queries with INNER JOIN
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- Answer: No difference (both return John and Mike). An inner join only keeps
-- rows that satisfy all conditions, so it does not matter whether the filter
-- is in ON or WHERE. For outer joins, ON decides which rows get matched,
-- while WHERE removes rows from the final result.

-- Part 8: Complex JOIN scenarios

-- Exercise 8.1
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p  ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

-- Exercise 8.2: self join
ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3    WHERE emp_id = 1;
UPDATE employees SET manager_id = 3    WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3    WHERE emp_id = 4;
UPDATE employees SET manager_id = 3    WHERE emp_id = 5;

SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- Exercise 8.3: departments with average salary above 50000
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;
-- IT = 52500, HR = 60000, Finance = 65000 (all three pass).

-- ============================================================
-- Lab Questions
-- ============================================================
-- 1. INNER JOIN returns only rows that have a match in both tables.
--    LEFT JOIN returns all rows of the left table and fills the right
--    side with NULLs when there is no match.
--
-- 2. CROSS JOIN is useful for generating all combinations: availability
--    matrices (employees x projects), product x size x color catalogs,
--    calendars (dates x time slots), test data.
--
-- 3. In an outer join, ON decides which rows are matched (unmatched rows of
--    the preserved table are still kept with NULLs), while WHERE filters the
--    final result and can delete those NULL-extended rows. In an inner join
--    non-matching rows are dropped anyway, so both positions give the same
--    result.
--
-- 4. 5 x 10 = 50 rows, so COUNT(*) returns 50.
--
-- 5. NATURAL JOIN automatically joins on all columns that have the same
--    name in both tables.
--
-- 6. Risks: adding or renaming a column later can silently change the join
--    condition; unrelated columns with the same name (e.g. "name", "id")
--    get joined by accident; if there are no common columns it turns into a
--    CROSS JOIN; the code is harder to read and maintain.
--
-- 7. SELECT * FROM B RIGHT JOIN A ON A.id = B.id;
--
-- 8. Use FULL OUTER JOIN when you need all rows from both tables whether or
--    not they match: data reconciliation, finding orphaned records on both
--    sides, comparing two data sets.

-- Additional Challenges

-- Challenge 1: simulate FULL OUTER JOIN with UNION of LEFT and RIGHT joins
SELECT e.emp_name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
UNION
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- Challenge 2: employees in departments with more than one project
SELECT e.emp_name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IN (
    SELECT dept_id
    FROM projects
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
    HAVING COUNT(*) > 1
);
-- Result: John Smith and Mike Johnson (IT has 2 projects).

-- Challenge 3: organizational hierarchy (employee -> manager -> manager's manager)
SELECT
    e.emp_name  AS employee,
    m1.emp_name AS manager,
    m2.emp_name AS managers_manager
FROM employees e
LEFT JOIN employees m1 ON e.manager_id = m1.emp_id
LEFT JOIN employees m2 ON m1.manager_id = m2.emp_id;

-- Challenge 3 (alternative, any depth): recursive CTE
WITH RECURSIVE org AS (
    SELECT emp_id, emp_name, manager_id, 0 AS level
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, e.emp_name, e.manager_id, o.level + 1
    FROM employees e
    JOIN org o ON e.manager_id = o.emp_id
)
SELECT level, emp_name
FROM org
ORDER BY level, emp_name;

-- Challenge 4: all pairs of employees in the same department
SELECT
    e1.emp_name AS employee_1,
    e2.emp_name AS employee_2,
    d.dept_name
FROM employees e1
JOIN employees e2 ON e1.dept_id = e2.dept_id AND e1.emp_id < e2.emp_id
JOIN departments d ON e1.dept_id = d.dept_id;
-- Result: John Smith + Mike Johnson (IT).
