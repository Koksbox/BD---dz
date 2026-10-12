-- 01_schema.sql
-- Учебная база данных "Больница"
-- PostgreSQL

DROP TABLE IF EXISTS doctor_examinations CASCADE;
DROP TABLE IF EXISTS doctor_departments CASCADE;
DROP TABLE IF EXISTS exam_schedule CASCADE;
DROP TABLE IF EXISTS wards CASCADE;
DROP TABLE IF EXISTS examinations CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE wards (
    id SERIAL PRIMARY KEY,
    department_id INTEGER NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    room_number VARCHAR(20) NOT NULL,
    ward_type VARCHAR(50) NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    UNIQUE (department_id, room_number)
);

CREATE TABLE doctors (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE
);

-- Врач может работать в нескольких отделениях,
-- и в одном отделении может быть несколько врачей.
CREATE TABLE doctor_departments (
    doctor_id INTEGER NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    department_id INTEGER NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    PRIMARY KEY (doctor_id, department_id)
);

CREATE TABLE examinations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE,
    description TEXT
);

-- Расписание вынесено отдельно, потому что одно обследование
-- может проводиться несколько раз в неделю.
CREATE TABLE exam_schedule (
    id SERIAL PRIMARY KEY,
    examination_id INTEGER NOT NULL REFERENCES examinations(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CHECK (start_time < end_time)
);

-- Связь многие-ко-многим: один врач может проводить несколько
-- обследований, одно обследование могут проводить несколько врачей.
CREATE TABLE doctor_examinations (
    doctor_id INTEGER NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    examination_id INTEGER NOT NULL REFERENCES examinations(id) ON DELETE CASCADE,
    PRIMARY KEY (doctor_id, examination_id)
);
