-- author: Kaldykhanov Adilzhan
-- student id: 25B031335

set client_encoding = 'utf8';


-- part 1: check constraints[cite: 1]

-- task 1.1: basic check constraint[cite: 1]
-- creates the employees table with check constraints ensuring age is between 18 and 65, and salary is greater than 0
create table employees (
    employee_id integer,
    first_name text,
    last_name text,
    age integer check (age between 18 and 65),
    salary numeric check (salary > 0)
);

-- task 1.2: named check constraint[cite: 1]
-- creates products_catalog table with a named check constraint 'valid_discount' to validate pricing rules
create table products_catalog (
    product_id integer,
    product_name text,
    regular_price numeric,
    discount_price numeric,
    constraint valid_discount check (
        regular_price > 0 and 
        discount_price > 0 and 
        discount_price < regular_price
    )
);

-- task 1.3: multiple column check[cite: 1]
-- creates bookings table with constraints on guest count and ensures check_out_date is after check_in_date
create table bookings (
    booking_id integer,
    check_in_date date,
    check_out_date date,
    num_guests integer check (num_guests between 1 and 10),
    constraint valid_dates check (check_out_date > check_in_date)
);

-- task 1.4: testing check constraints[cite: 2]
-- successful inserts
insert into employees values (1, 'ivan', 'ivanov', 30, 1500.00);
insert into employees values (2, 'anna', 'petrova', 45, 2500.50);

insert into products_catalog values (1, 'laptop', 1000.00, 850.00);
insert into products_catalog values (2, 'phone', 500.00, 400.00);

insert into bookings values (1, '2026-06-01', '2026-06-07', 2);
insert into bookings values (2, '2026-07-10', '2026-07-15', 4);

/*
-- test results: failed attempts (commented out)
-- error: age violates between 18 and 65
insert into employees values (3, 'petr', 'sidorov', 16, 1000.00);
-- error: salary violates > 0
insert into employees values (4, 'olga', 'smirnova', 25, -500.00);
-- error: discount_price not less than regular_price (violates 'valid_discount')
insert into products_catalog values (3, 'tablet', 300.00, 350.00);
-- error: num_guests greater than 10
insert into bookings values (3, '2026-08-01', '2026-08-05', 12);
-- error: check_out_date earlier than check_in_date (violates 'valid_dates')
insert into bookings values (4, '2026-08-10', '2026-08-05', 2);
*/


-- part 2: not null constraints[cite: 2]


-- task 2.1: not null implementation[cite: 2]
-- creates customers table with mandatory fields using not null
create table customers (
    customer_id integer not null,
    email text not null,
    phone text, -- optional field, can be null
    registration_date date not null
);

-- task 2.2: combining constraints[cite: 2]
-- creates inventory table combining not null and check constraints for stock and pricing
create table inventory (
    item_id integer not null,
    item_name text not null,
    quantity integer not null check (quantity >= 0),
    unit_price numeric not null check (unit_price > 0),
    last_updated timestamp not null
);

-- task 2.3: testing not null[cite: 2]
-- successful inserts
insert into customers values (1, 'test1@mail.com', '+77011234567', '2026-01-10');
insert into inventory values (101, 'computer mouse', 50, 15.50, current_timestamp);
insert into customers values (2, 'test2@mail.com', null, '2026-01-11');

/*
-- test results: failed attempts (commented out)
-- error: email cannot be null
insert into customers values (3, null, '+77079998877', '2026-01-12');
-- error: quantity cannot be null
insert into inventory values (102, 'keyboard', null, 30.00, current_timestamp);
*/



-- part 3: unique constraints[cite: 2, 3]

-- task 3.1: single column unique[cite: 3]
-- creates users table ensuring username and email must be unique
create table users (
    user_id integer,
    username text unique,
    email text unique,
    created_at timestamp
);

-- task 3.2: multi-column unique[cite: 3]
-- creates course_enrollments with a composite unique constraint across three columns
create table course_enrollments (
    enrollment_id integer,
    student_id integer,
    course_code text,
    semester text,
    constraint unique_student_course_sem unique (student_id, course_code, semester)
);

-- task 3.3: named unique constraints[cite: 3]
-- recreates users table with explicitly named unique constraints
drop table if exists users cascade;
create table users (
    user_id integer,
    username text,
    email text,
    created_at timestamp,
    constraint unique_username unique (username),
    constraint unique_email unique (email)
);

-- successful inserts
insert into users values (1, 'john_doe', 'john@mail.com', current_timestamp);
insert into users values (2, 'alice_smith', 'alice@mail.com', current_timestamp);

/*
-- test results: failed attempts (commented out)
-- error: duplicate username violates 'unique_username'
insert into users values (3, 'john_doe', 'another@mail.com', current_timestamp);
-- error: duplicate email violates 'unique_email'
insert into users values (4, 'bob_jones', 'john@mail.com', current_timestamp);
*/



-- part 4: primary key constraints[cite: 3]

-- task 4.1: single column primary key[cite: 3]
-- creates departments table with a primary key on dept_id
create table departments (
    dept_id integer primary key, -- ensures uniqueness and prevents nulls
    dept_name text not null,
    location text
);

-- successful inserts
insert into departments values (1, 'hr', 'almaty');
insert into departments values (2, 'it', 'astana');
insert into departments values (3, 'finance', 'shymkent');

/*
-- test results: failed attempts (commented out)
-- error: duplicate dept_id (1 already exists)
insert into departments values (1, 'marketing', 'karaganda');
-- error: dept_id cannot be null
insert into departments values (null, 'legal', 'atyrau');
*/

-- task 4.2: composite primary key[cite: 3]
-- creates student_courses using a combination of student_id and course_id as primary key
create table student_courses (
    student_id integer,
    course_id integer,
    enrollment_date date,
    grade text,
    primary key (student_id, course_id)
);

-- task 4.3: comparison exercise (documented in comments)[cite: 3, 4]
/*
1. difference between unique and primary key:
   - primary key cannot contain null values, whereas unique allows a single null value.
   - a table can have only one primary key, but multiple unique constraints.
2. when to use single-column vs composite primary key:
   - single-column is used when a distinct natural or surrogate identifier exists.
   - composite is used for junction tables representing many-to-many relationships.
3. why a table can have only one primary key but multiple unique constraints:
   - an entity has one main primary identifier, but can possess multiple unique business attributes (e.g., email, phone number, username).
*/



-- part 5: foreign key constraints[cite: 4, 5]

-- task 5.1: basic foreign key[cite: 4]
-- creates employees_dept referencing departments table
create table employees_dept (
    emp_id integer primary key,
    emp_name text not null,
    dept_id integer references departments(dept_id), -- foreign key reference
    hire_date date
);

-- successful insert
insert into employees_dept values (1, 'aibek', 1, '2026-02-01');

/*
-- test results: failed attempts (commented out)
-- error: dept_id = 999 does not exist in departments table
insert into employees_dept values (2, 'dinara', 999, '2026-02-05');
*/

-- task 5.2: multiple foreign keys (library system)[cite: 4]
-- creates authors, publishers, and books tables with foreign keys and unique isbn
create table authors (
    author_id integer primary key,
    author_name text not null,
    country text
);

create table publishers (
    publisher_id integer primary key,
    publisher_name text not null,
    city text
);

create table books (
    book_id integer primary key,
    title text not null,
    author_id integer references authors(author_id),
    publisher_id integer references publishers(publisher_id),
    publication_year integer,
    isbn text unique
);

-- sample data insertion
insert into authors values (1, 'abay kunanbayev', 'kazakhstan');
insert into publishers values (1, 'mektep', 'almaty');
insert into books values (1, 'book of words', 1, 1, 1895, '978-5-699-12345-6');

-- task 5.3: on delete options (restrict vs cascade)[cite: 4, 5]
-- creates schema to demonstrate delete behaviors: restrict and cascade
create table categories (
    category_id integer primary key,
    category_name text not null
);

create table products_fk (
    product_id integer primary key,
    product_name text not null,
    category_id integer references categories(category_id) on delete restrict
);

create table orders (
    order_id integer primary key,
    order_date date not null
);

create table order_items (
    item_id integer primary key,
    order_id integer references orders(order_id) on delete cascade,
    product_id integer references products_fk(product_id),
    quantity integer check (quantity > 0)
);

-- sample data insertion
insert into categories values (1, 'electronics');
insert into products_fk values (10, 'smartphone', 1);
insert into orders values (500, '2026-10-01');
insert into order_items values (1, 500, 10, 2);

/*
-- test results and behavior documentation:
1. delete from categories where category_id = 1; 
   -- fails due to 'on delete restrict' constraint because products are still linked to this category.
2. delete from orders where order_id = 500; 
   -- succeeds; corresponding child records in order_items are automatically deleted due to 'on delete cascade'.
*/



-- part 6: practical application — e-commerce database design[cite: 5, 6]

-- creates customers_ec table with primary key and unique email constraint
create table customers_ec (
    customer_id integer primary key,
    name text not null,
    email text unique not null,
    phone text,
    registration_date date not null
);

-- creates products_ec table with price and stock check constraints
create table products_ec (
    product_id integer primary key,
    name text not null,
    description text,
    price numeric not null check (price >= 0),
    stock_quantity integer not null check (stock_quantity >= 0)
);

-- creates orders_ec table with foreign key to customers and status check constraint
create table orders_ec (
    order_id integer primary key,
    customer_id integer not null references customers_ec(customer_id) on delete restrict,
    order_date date not null,
    total_amount numeric not null check (total_amount >= 0),
    status text not null check (status in ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

-- creates order_details table linking orders and products with cascade/restrict rules
create table order_details (
    order_detail_id integer primary key,
    order_id integer not null references orders_ec(order_id) on delete cascade,
    product_id integer not null references products_ec(product_id) on delete restrict,
    quantity integer not null check (quantity > 0),
    unit_price numeric not null check (unit_price >= 0)
);

-- sample records insertion (5 per table)
insert into customers_ec values 
(1, 'daniyar ospanov', 'daniyar@mail.com', '+77011112233', '2026-01-15'),
(2, 'aliya nurzhanova', 'aliya@mail.com', '+77022223344', '2026-02-20'),
(3, 'timur karimov', 'timur@mail.com', '+77033334455', '2026-03-10'),
(4, 'madina serik', 'madina@mail.com', '+77044445566', '2026-04-05'),
(5, 'yerlan sagyndyk', 'erlan@mail.com', '+77055556677', '2026-05-01');

insert into products_ec values 
(101, 'wireless headphones', 'bluetooth 5.3 with anc', 25000.00, 15),
(102, 'mechanical keyboard', 'rgb backlight, blue switches', 35000.00, 10),
(103, 'gaming mouse', '16000 dpi, optical sensor', 18000.00, 25),
(104, 'monitor 27"', 'ips panel, 165hz', 120000.00, 5),
(105, 'external ssd 1tb', 'usb 3.2 gen 2', 50000.00, 20);

insert into orders_ec values 
(1001, 1, '2026-10-01', 60000.00, 'delivered'),
(1002, 2, '2026-10-05', 35000.00, 'shipped'),
(1003, 3, '2026-10-08', 18000.00, 'processing'),
(1004, 4, '2026-10-10', 120000.00, 'pending'),
(1005, 5, '2026-10-11', 50000.00, 'pending');

insert into order_details values 
(1, 1001, 101, 1, 25000.00),
(2, 1001, 103, 1, 18000.00),
(3, 1002, 102, 1, 35000.00),
(4, 1003, 103, 1, 18000.00),
(5, 1004, 104, 1, 120000.00);

/*
-- test results: constraint verification queries (commented out)
-- check status validation error: 
-- insert into orders_ec values (1006, 1, '2026-10-12', 1000.00, 'unknown');
-- check quantity validation error: 
-- insert into order_details values (6, 1005, 105, 0, 50000.00);
-- check email unique validation error: 
-- insert into customers_ec values (6, 'test user', 'daniyar@mail.com', '+77009998877', '2026-10-12');
*/