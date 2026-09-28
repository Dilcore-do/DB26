-- part a: database and table setup

create table employees (
    emp_id serial primary key,
    first_name varchar(50),
    last_name varchar(50),
    department varchar(50),
    salary integer,
    hire_date date,
    status varchar(20) default 'active'
);

create table departments (
    dept_id serial primary key,
    dept_name varchar(50),
    budget integer,
    manager_id integer
);

create table projects (
    project_id serial primary key,
    project_name varchar(100),
    dept_id integer,
    start_date date,
    end_date date,
    budget integer
);

-- part b: advanced insert operations

-- task 2
insert into employees
    (emp_id, first_name, last_name, department)
values
    (1, 'john', 'smith', 'it');

-- task 3
insert into employees
    (first_name, last_name, salary, status)
values
    ('alice', 'brown', default, default);

-- task 4
insert into departments
    (dept_name, budget, manager_id)
values
    ('it', 150000, 1),
    ('sales', 120000, 2),
    ('hr', 80000, 3);

-- task 5
insert into employees
    (first_name, last_name, department, salary, hire_date)
values
    ('michael', 'johnson', 'it', 50000 * 1.1, current_date);

-- task 6
create temp table temp_employees as
select *
from employees
where department = 'it';

-- part c: complex update operations

-- task 7
update employees
set salary = salary * 1.10;

-- task 8
update employees
set status = 'senior'
where salary > 60000
  and hire_date < '2020-01-01';

-- task 9
update employees
set department = case
    when salary > 80000 then 'management'
    when salary between 50000 and 80000 then 'senior'
    else 'junior'
end;

-- task 10
alter table employees
alter column department set default 'unassigned';

update employees
set department = default
where status = 'inactive';

-- task 11
update departments d
set budget = budget + (
    select coalesce(avg(e.salary), 0) * 0.20
    from employees e
    where e.department = d.dept_name
);

-- task 12
update employees
set
    salary = salary * 1.15,
    status = 'promoted'
where department = 'sales';

-- part d: advanced delete operations

-- task 13
delete from employees
where status = 'terminated';

-- task 14
delete from employees
where salary < 40000
  and hire_date > '2023-01-01'
  and department is null;

-- task 15
delete from departments
where dept_id not in (
    select distinct d.dept_id
    from departments d
    join employees e on d.dept_name = e.department
    where e.department is not null
);

-- task 16
delete from projects
where end_date < '2023-01-01'
returning *;

-- part e: operations with null values

-- task 17
insert into employees
    (first_name, last_name, salary, department)
values
    ('david', 'wilson', null, null);

-- task 18
update employees
set department = 'unassigned'
where department is null;

-- task 19
delete from employees
where salary is null
   or department is null;

-- part f: returning clause operations

-- task 20
insert into employees
    (first_name, last_name, department, salary, hire_date)
values
    ('robert', 'taylor', 'it', 70000, current_date)
returning
    emp_id,
    first_name || ' ' || last_name as full_name;

-- task 21
with updated as (
    select
        emp_id,
        salary as old_salary
    from employees
    where department = 'it'
)
update employees e
set salary = e.salary + 5000
from updated u
where e.emp_id = u.emp_id
returning
    e.emp_id,
    u.old_salary,
    e.salary as new_salary;

-- task 22
delete from employees
where hire_date < '2020-01-01'
returning *;

-- part g: advanced dml patterns

-- task 23
insert into employees
    (first_name, last_name, department, salary, hire_date)
select
    'james',
    'anderson',
    'it',
    65000,
    current_date
where not exists (
    select 1
    from employees
    where first_name = 'james'
      and last_name = 'anderson'
);

-- task 24
update employees e
set salary = salary * case
    when (
        select d.budget
        from departments d
        where d.dept_name = e.department
    ) > 100000
    then 1.10
    else 1.05
end;

-- task 25
insert into employees
    (first_name, last_name, department, salary, hire_date)
values
    ('tom', 'adams', 'it', 50000, current_date),
    ('anna', 'white', 'sales', 55000, current_date),
    ('peter', 'clark', 'hr', 45000, current_date),
    ('kate', 'lewis', 'it', 60000, current_date),
    ('mark', 'young', 'sales', 52000, current_date);

update employees
set salary = salary * 1.10
where first_name in ('tom', 'anna', 'peter', 'kate', 'mark');

-- task 26
create table employee_archive (
    like employees including all
);

insert into employee_archive
select *
from employees
where status = 'inactive';

delete from employees
where status = 'inactive';

-- task 27
update projects p
set end_date = end_date + interval '30 days'
where p.budget > 50000
  and (
      select count(*)
      from employees e
      join departments d
        on e.department = d.dept_name
      where d.dept_id = p.dept_id
  ) > 3;