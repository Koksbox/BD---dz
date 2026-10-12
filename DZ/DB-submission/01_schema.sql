-- =============================================================================
-- Часть I. Схема БД «Больница» (PostgreSQL)
-- ER: department, ward, doctor, examination, doctor_examination, examination_schedule
-- =============================================================================

DROP SCHEMA IF EXISTS hospital CASCADE;
CREATE SCHEMA hospital;
SET search_path TO hospital;

CREATE TABLE department (
    department_id   SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    building        VARCHAR(100),
    phone           VARCHAR(30),
    CONSTRAINT uq_department_name UNIQUE (name)
);

CREATE TABLE ward (
    ward_id         SERIAL PRIMARY KEY,
    ward_number     VARCHAR(20) NOT NULL,
    capacity        INTEGER NOT NULL,
    floor           INTEGER NOT NULL,
    department_id   INTEGER NOT NULL,
    CONSTRAINT fk_ward_department
        FOREIGN KEY (department_id) REFERENCES department (department_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_ward_in_department UNIQUE (department_id, ward_number),
    CONSTRAINT chk_ward_capacity CHECK (capacity > 0),
    CONSTRAINT chk_ward_floor CHECK (floor >= 0)
);

CREATE TABLE doctor (
    doctor_id       SERIAL PRIMARY KEY,
    last_name       VARCHAR(50) NOT NULL,
    first_name      VARCHAR(50) NOT NULL,
    middle_name     VARCHAR(50),
    specialization  VARCHAR(100) NOT NULL,
    phone           VARCHAR(30),
    hire_date       DATE NOT NULL DEFAULT CURRENT_DATE,
    department_id   INTEGER,
    CONSTRAINT fk_doctor_department
        FOREIGN KEY (department_id) REFERENCES department (department_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT uq_doctor_phone UNIQUE (phone)
);

CREATE TABLE examination (
    examination_id      SERIAL PRIMARY KEY,
    name                VARCHAR(150) NOT NULL,
    description         TEXT,
    price               NUMERIC(10, 2) NOT NULL DEFAULT 0,
    duration_minutes    INTEGER NOT NULL DEFAULT 30,
    CONSTRAINT uq_examination_name UNIQUE (name),
    CONSTRAINT chk_examination_price CHECK (price >= 0),
    CONSTRAINT chk_examination_duration CHECK (duration_minutes > 0)
);

-- day_of_week: 1=Mon … 7=Sun; расписание отдельно от справочника examinations
CREATE TABLE examination_schedule (
    schedule_id     SERIAL PRIMARY KEY,
    examination_id  INTEGER NOT NULL,
    day_of_week     SMALLINT NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    CONSTRAINT fk_schedule_examination
        FOREIGN KEY (examination_id) REFERENCES examination (examination_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_schedule_weekday CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_schedule_time_order CHECK (start_time < end_time),
    CONSTRAINT uq_schedule_slot UNIQUE (examination_id, day_of_week, start_time)
);

-- M:N врач ↔ обследование
CREATE TABLE doctor_examination (
    doctor_id       INTEGER NOT NULL,
    examination_id  INTEGER NOT NULL,
    CONSTRAINT pk_doctor_examination PRIMARY KEY (doctor_id, examination_id),
    CONSTRAINT fk_de_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctor (doctor_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_de_examination
        FOREIGN KEY (examination_id) REFERENCES examination (examination_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX idx_ward_department ON ward (department_id);
CREATE INDEX idx_doctor_department ON doctor (department_id);
CREATE INDEX idx_schedule_exam ON examination_schedule (examination_id);
CREATE INDEX idx_schedule_weekday ON examination_schedule (day_of_week);
CREATE INDEX idx_de_examination ON doctor_examination (examination_id);
