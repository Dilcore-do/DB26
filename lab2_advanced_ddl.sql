--PART1:
--task1.1:
create database university_main
    owner postgres
    template template0
    encoding = 'UTF8';
create database university_archive
    connection limit = 50
    template template0;
create database university_test
    is_template = true
    connection limit = 10;

--task1.2:
create tablespace student_data
    location '/data/students';
create tablespace course_data
    owner postgres
    location '/data/courses';
create database university_distributed
    tablespace student_data
    encoding 'LATIN9';


--PART2:
--task2.1:
create table students(
    student_id serial primary key,
    first_name varchar(50),
    last_name varchar(50),
    email varchar(100),
    phone char(15),
    date_of_birth date,
    enrollment_date date,
    gpa numeric(3,2),
    is_active boolean,
    graduation_year smallint
);
create table professors(
    professor_id serial primary key,
    first_name varchar(50),
    last_name varchar(50),
    email varchar(100),
    office_number varchar(20),
    hire_date date,
    salary numeric(10,2),
    is_tenured boolean,
    years_experience integer
);
create table courses(
    course_id serial primary key,
    course_code char(8),
    course_title varchar(100),
    description text,
    credits smallint,
    max_enrollment integer,
    course_fee numeric(8,2),
    is_online boolean,
    created_at timestamp
);
--task2.2:
create table class_schedule (
    schedule_id serial primary key,
    course_id integer,
    professor_id integer,
    classroom varchar(20),
    class_date date,
    start_time time,
    end_time time,
    duration interval
);
create table student_records (
    record_id serial primary key,
    student_id integer,
    course_id integer,
    semester varchar(20),
    year integer,
    grade char(2),
    attendance_percentage numeric(4,1),
    submission_timestamp timestamp with time zone,
    last_updated timestamp with time zone
);

--PART3:
--task3.1:
--modifying students:
alter table students
    add column middle_name varchar(30),
    add column student_status varchar(20),
    alter column phone type varchar(20),
    alter column student_status set default 'ACTIVE',
    alter column gpa set default 0.00;
--modifying professors:
alter table professors
    add column department_code char(5),
    add column research_area text,
    alter column years_experience type smallint,
    alter column is_tenured set default false,
    add column last_promotion_date date;
--modifying courses:
alter table courses
    add column prerequisite_course_id integer,
    add column difficulty_level smallint,
    alter column course_code type varchar(10),
    alter column credits set default 3,
    add column lab_required boolean default false;

--task3.2:
--modifying class_schedule:
alter table class_schedule
    add column room_capacity integer,
    drop column duration,
    add column session_type varchar(15),
    alter column classroom type varchar(30),
    add column equipment_needed text;
--modifying student_records:
alter table student_records
    add column extra_credit_points numeric(4,1),
    alter column grade type varchar(5),
    alter column extra_credit_points set default 0.0,
    add column final_exam_date date,
    drop column last_updated;


--PART4:
--task4.1:
create table departments (
    department_id serial primary key,
    department_name varchar(100),
    department_code char(5),
    building varchar(50),
    phone varchar(15),
    budget numeric(12,2),
    established_year integer
);
create table library_books (
    book_id serial primary key,
    isbn char(13),
    title varchar(200),
    author varchar(100),
    publisher varchar(100),
    publication_date date,
    price numeric(10,2),
    is_available boolean,
    acquisition_timestamp timestamp without time zone
);
create table student_book_loans (
    loan_id serial primary key,
    student_id integer,
    book_id integer,
    loan_date date,
    due_date date,
    return_date date,
    fine_amount numeric(10,2),
    loan_status varchar(20)
);
--task4.2:
alter table professors
    add column department_id integer;

alter table students
    add column advisor_id integer;

alter table courses
    add column department_id integer;

create table grade_scale (
    grade_id serial primary key,
    letter_grade char(2),
    min_percentage numeric(4,1),
    max_percentage numeric(4,1),
    gpa_points numeric(4,2)
);
create table semester_calendar (
    semester_id serial primary key,
    semester_name varchar(20),
    academic_year integer,
    start_date date,
    end_date date,
    registration_deadline timestamp with time zone,
    is_current boolean
);

--PART5:
--task5.1:
drop table if exists student_book_loans;

drop table if exists library_books;

drop table if exists grade_scale;

create table grade_scale (
    grade_id serial primary key,
    letter_grade char(2),
    min_percentage numeric(4,1),
    max_percentage numeric(4,1),
    gpa_points numeric(4,2),
    description text
);

drop table if exists semester_calendar cascade;

create table semester_calendar (
    semester_id serial primary key,
    semester_name varchar(20),
    academic_year integer,
    start_date date,
    end_date date,
    registration_deadline timestamp with time zone,
    is_current boolean
);
--task5.2:
drop database if exists university_test;

drop database if exists university_distributed;

create database university_backup
    template university_main;