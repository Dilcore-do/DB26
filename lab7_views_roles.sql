-- Part 1: Database setup 

DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE employees (
    emp_id    INT PRIMARY KEY,
    emp_name  VARCHAR(50),
    dept_id   INT,
    salary    DECIMAL(10, 2)
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
(1, 'John Smith',     101, 50000),
(2, 'Jane Doe',       102, 60000),
(3, 'Mike Johnson',   101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown',      NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT',        'Building A'),
(102, 'HR',        'Building B'),
(103, 'Finance',   'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign',   101, 100000),
(2, 'Employee Training',  102, 50000),
(3, 'Budget Analysis',    103, 75000),
(4, 'Cloud Migration',    101, 150000),
(5, 'AI Research',        NULL, 200000);

-- Part 2: Creating basic views

-- Exercise 2.1: simple view (only employees that have a department)
CREATE VIEW employee_details AS
SELECT e.emp_id, e.emp_name, e.salary, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;
-- Answer: 4 rows. Tom Brown is not shown because his dept_id is NULL,
-- so the INNER JOIN finds no matching department for him.


-- Exercise 2.2: view with aggregation (all departments, even empty ones)
CREATE VIEW dept_statistics AS
SELECT d.dept_id,
       d.dept_name,
       COUNT(e.emp_id)          AS employee_count,
       ROUND(AVG(e.salary), 2)  AS avg_salary,
       MAX(e.salary)            AS max_salary,
       MIN(e.salary)            AS min_salary
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC;
-- Marketing has employee_count = 0 and NULL for avg/max/min.


-- Exercise 2.3: view with multiple joins
CREATE VIEW project_overview AS
SELECT p.project_id,
       p.project_name,
       p.budget,
       d.dept_name,
       d.location,
       COUNT(e.emp_id) AS team_size
FROM projects p
LEFT JOIN departments d ON d.dept_id = p.dept_id
LEFT JOIN employees   e ON e.dept_id = d.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name, d.location;

SELECT * FROM project_overview;


-- Exercise 2.4: view with filtering
CREATE VIEW high_earners AS
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
LEFT JOIN departments d ON d.dept_id = e.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners;
-- Answer: yes, you see all employees with salary > 55000 (Jane Doe and
-- Sarah Williams). A view stores only the query, so it always reflects
-- the current data. Mike Johnson (exactly 55000) is not included.

-- Part 3: Modifying and managing views

-- Exercise 3.1: replace a view (new column must be added at the END)
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_id, e.emp_name, e.salary, d.dept_name, d.location,
       CASE
           WHEN e.salary > 60000 THEN 'High'
           WHEN e.salary > 50000 THEN 'Medium'
           ELSE 'Standard'
       END AS salary_grade
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;


-- Exercise 3.2: rename a view
ALTER VIEW high_earners RENAME TO top_performers;

SELECT * FROM top_performers;


-- Exercise 3.3: create and drop a view
CREATE VIEW temp_view AS
SELECT emp_id, emp_name, salary
FROM employees
WHERE salary < 50000;

SELECT * FROM temp_view;

DROP VIEW temp_view;

-- Part 4: Updatable views

-- Exercise 4.1: simple updatable view
CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;


-- Exercise 4.2: update through a view
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

SELECT * FROM employees WHERE emp_name = 'John Smith';
-- Answer: yes, the underlying table was updated (salary = 52000), because
-- the view is simple (one table, no aggregation, no DISTINCT).


-- Exercise 4.3: insert through a view
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

SELECT * FROM employees WHERE emp_id = 6;
-- Answer: the insert succeeds and the row appears in employees.


-- Exercise 4.4: view with LOCAL CHECK OPTION
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

-- This should fail. It is wrapped in a DO block so the script keeps going.
DO $$
BEGIN
    INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
    VALUES (7, 'Bob Wilson', 103, 60000);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error (%): %', SQLSTATE, SQLERRM;
END $$;
-- Answer: ERROR: new row violates check option for view "it_employees".
-- The new row has dept_id = 103, which does not satisfy the view's
-- condition dept_id = 101. CHECK OPTION forbids changes through the view
-- that would make the row invisible in it.

-- Part 5: Materialized views

-- Exercise 5.1: materialized view (employees and projects are
-- pre-aggregated separately to avoid row multiplication)
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id,
       d.dept_name,
       COALESCE(e.cnt, 0)       AS total_employees,
       COALESCE(e.sal, 0)       AS total_salaries,
       COALESCE(p.cnt, 0)       AS total_projects,
       COALESCE(p.bud, 0)       AS total_project_budget
FROM departments d
LEFT JOIN (SELECT dept_id, COUNT(*) AS cnt, SUM(salary) AS sal
           FROM employees
           GROUP BY dept_id) e ON e.dept_id = d.dept_id
LEFT JOIN (SELECT dept_id, COUNT(*) AS cnt, SUM(budget) AS bud
           FROM projects
           GROUP BY dept_id) p ON p.dept_id = d.dept_id
WITH DATA;

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;


-- Exercise 5.2: refresh
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

-- Before refresh: IT still shows the old numbers
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

REFRESH MATERIALIZED VIEW dept_summary_mv;

-- After refresh: IT includes Charlie Brown (one more employee, +54000)
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;
-- Answer: a materialized view stores a snapshot. It does not see new data
-- until REFRESH is run. A regular view would show Charlie immediately.


-- Exercise 5.3: concurrent refresh (requires a UNIQUE index)
CREATE UNIQUE INDEX idx_dept_summary_mv_dept_id
ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
-- Answer: CONCURRENTLY does not block SELECT queries on the materialized
-- view while it is being refreshed (a plain REFRESH takes an exclusive
-- lock). The price: it needs a unique index and is slower.


-- Exercise 5.4: materialized view WITH NO DATA
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       COUNT(e.emp_id) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON d.dept_id = p.dept_id
LEFT JOIN employees   e ON e.dept_id = d.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name
WITH NO DATA;

-- Querying it fails (wrapped in DO so the script continues)
DO $$
BEGIN
    PERFORM 1 FROM project_stats_mv;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error (%): %', SQLSTATE, SQLERRM;
END $$;
-- Answer: ERROR: materialized view "project_stats_mv" has not been
-- populated. HINT: Use the REFRESH MATERIALIZED VIEW command.
-- Fix:
REFRESH MATERIALIZED VIEW project_stats_mv;

SELECT * FROM project_stats_mv;

-- Part 6: Database roles

-- Exercise 6.1: basic roles
CREATE ROLE analyst NOLOGIN;
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE USER report_user PASSWORD 'report456';   -- CREATE USER = CREATE ROLE ... LOGIN

SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';


-- Exercise 6.2: roles with specific attributes
CREATE ROLE db_creator   CREATEDB   LOGIN PASSWORD 'creator789';
CREATE ROLE user_manager CREATEROLE LOGIN PASSWORD 'manager101';
CREATE ROLE admin_user   SUPERUSER  LOGIN PASSWORD 'admin999';


-- Exercise 6.3: grant privileges
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;


-- Exercise 6.4: group roles
CREATE ROLE hr_team      NOLOGIN;
CREATE ROLE finance_team NOLOGIN;
CREATE ROLE it_team      NOLOGIN;

CREATE USER hr_user1      PASSWORD 'hr001';
CREATE USER hr_user2      PASSWORD 'hr002';
CREATE USER finance_user1 PASSWORD 'fin001';

GRANT hr_team      TO hr_user1;
GRANT hr_team      TO hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;


-- Exercise 6.5: revoke privileges
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;


-- Exercise 6.6: modify role attributes
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;

-- Part 7: Advanced role management

-- Exercise 7.1: role hierarchy
CREATE ROLE read_only NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

GRANT INSERT, UPDATE ON employees TO senior_analyst;


-- Exercise 7.2: object ownership
CREATE ROLE project_manager LOGIN PASSWORD 'pm123';

ALTER VIEW  dept_statistics OWNER TO project_manager;
ALTER TABLE projects        OWNER TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';

-- Note: dept_statistics reads employees/departments with the OWNER's
-- rights, so project_manager would need SELECT on those tables for other
-- users (e.g. finance_team) to query the view successfully.


-- Exercise 7.3: reassign and drop roles
CREATE ROLE temp_owner LOGIN;
CREATE TABLE temp_table (id INT);
ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;   -- use your superuser name if it differs
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;


-- Exercise 7.4: views as row/column-level access control
CREATE VIEW hr_employee_view AS
SELECT *
FROM employees
WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;

-- Part 8: Practical scenarios

-- Exercise 8.1: department dashboard
-- ("active projects" = all projects, there is no status column)
CREATE VIEW dept_dashboard AS
SELECT d.dept_name,
       d.location,
       COALESCE(e.cnt, 0)                         AS employee_count,
       ROUND(COALESCE(e.avg_sal, 0), 2)           AS avg_salary,
       COALESCE(p.cnt, 0)                         AS active_projects,
       COALESCE(p.bud, 0)                         AS total_project_budget,
       CASE
           WHEN COALESCE(e.cnt, 0) = 0 THEN 0
           ELSE ROUND(COALESCE(p.bud, 0) / e.cnt, 2)
       END                                        AS budget_per_employee
FROM departments d
LEFT JOIN (SELECT dept_id, COUNT(*) AS cnt, AVG(salary) AS avg_sal
           FROM employees
           GROUP BY dept_id) e ON e.dept_id = d.dept_id
LEFT JOIN (SELECT dept_id, COUNT(*) AS cnt, SUM(budget) AS bud
           FROM projects
           GROUP BY dept_id) p ON p.dept_id = d.dept_id;

SELECT * FROM dept_dashboard;


-- Exercise 8.2: audit view
ALTER TABLE projects
ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE VIEW high_budget_projects AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       p.created_date,
       CASE
           WHEN p.budget > 150000 THEN 'Critical Review Required'
           WHEN p.budget > 100000 THEN 'Management Approval Needed'
           ELSE 'Standard Process'
       END AS approval_status
FROM projects p
LEFT JOIN departments d ON d.dept_id = p.dept_id
WHERE p.budget > 75000;

SELECT * FROM high_budget_projects;


-- Exercise 8.3: access control system

-- Level 1: viewer
CREATE ROLE viewer_role NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;   -- includes views

-- Level 2: entry
CREATE ROLE entry_role NOLOGIN;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

-- Level 3: analyst
CREATE ROLE analyst_role NOLOGIN;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

-- Level 4: manager
CREATE ROLE manager_role NOLOGIN;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

-- Users
CREATE USER alice   PASSWORD 'alice123';
CREATE USER bob     PASSWORD 'bob123';
CREATE USER charlie PASSWORD 'charlie123';

GRANT viewer_role  TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;

-- Check memberships
SELECT r.rolname AS member, g.rolname AS member_of
FROM pg_auth_members m
JOIN pg_roles r ON r.oid = m.member
JOIN pg_roles g ON g.oid = m.roleid
WHERE r.rolname IN ('alice', 'bob', 'charlie',
                    'entry_role', 'analyst_role', 'manager_role')
ORDER BY r.rolname;
