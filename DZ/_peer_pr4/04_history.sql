-- 04_history.sql
-- Часть II. Историчность (SCD Type 2)
-- PostgreSQL

-- Для этой учебной работы я храню историю:
-- 1) расписания обследований;
-- 2) связи врач-обследование;
-- 3) связи врач-отделение.
-- Справочники и ФИО врача не версионирую, чтобы не усложнять работу.

DROP TABLE IF EXISTS exam_schedule_history CASCADE;
DROP TABLE IF EXISTS doctor_examination_history CASCADE;
DROP TABLE IF EXISTS doctor_department_history CASCADE;

CREATE TABLE exam_schedule_history (
    history_id BIGSERIAL PRIMARY KEY,
    schedule_id INTEGER NOT NULL,
    examination_id INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP NULL,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    CHECK (start_time < end_time),
    CHECK (valid_to IS NULL OR valid_from < valid_to)
);

CREATE UNIQUE INDEX ux_exam_schedule_history_current
ON exam_schedule_history(schedule_id)
WHERE is_current = TRUE;

CREATE TABLE doctor_examination_history (
    history_id BIGSERIAL PRIMARY KEY,
    doctor_id INTEGER NOT NULL,
    examination_id INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP NULL,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    CHECK (valid_to IS NULL OR valid_from < valid_to)
);

CREATE UNIQUE INDEX ux_doctor_exam_history_current
ON doctor_examination_history(doctor_id, examination_id)
WHERE is_current = TRUE;

CREATE TABLE doctor_department_history (
    history_id BIGSERIAL PRIMARY KEY,
    doctor_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP NULL,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    CHECK (valid_to IS NULL OR valid_from < valid_to)
);

CREATE UNIQUE INDEX ux_doctor_department_history_current
ON doctor_department_history(doctor_id, department_id)
WHERE is_current = TRUE;

-- Заполняем первую текущую версию из уже существующих данных.
INSERT INTO exam_schedule_history
(schedule_id, examination_id, day_of_week, start_time, end_time, operation)
SELECT id, examination_id, day_of_week, start_time, end_time, 'INSERT'
FROM exam_schedule;

INSERT INTO doctor_examination_history
(doctor_id, examination_id, operation)
SELECT doctor_id, examination_id, 'INSERT'
FROM doctor_examinations;

INSERT INTO doctor_department_history
(doctor_id, department_id, operation)
SELECT doctor_id, department_id, 'INSERT'
FROM doctor_departments;


-- ===== Триггер для расписания =====

CREATE OR REPLACE FUNCTION trg_exam_schedule_history()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO exam_schedule_history
        (schedule_id, examination_id, day_of_week, start_time, end_time,
         valid_from, valid_to, is_current, operation)
        VALUES
        (NEW.id, NEW.examination_id, NEW.day_of_week, NEW.start_time, NEW.end_time,
         CURRENT_TIMESTAMP, NULL, TRUE, 'INSERT');

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE exam_schedule_history
        SET valid_to = CURRENT_TIMESTAMP,
            is_current = FALSE
        WHERE schedule_id = OLD.id
          AND is_current = TRUE;

        INSERT INTO exam_schedule_history
        (schedule_id, examination_id, day_of_week, start_time, end_time,
         valid_from, valid_to, is_current, operation)
        VALUES
        (NEW.id, NEW.examination_id, NEW.day_of_week, NEW.start_time, NEW.end_time,
         CURRENT_TIMESTAMP, NULL, TRUE, 'UPDATE');

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE exam_schedule_history
        SET valid_to = CURRENT_TIMESTAMP,
            is_current = FALSE,
            operation = 'DELETE'
        WHERE schedule_id = OLD.id
          AND is_current = TRUE;

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER exam_schedule_history_trigger
AFTER INSERT OR UPDATE OR DELETE ON exam_schedule
FOR EACH ROW EXECUTE FUNCTION trg_exam_schedule_history();


-- ===== Триггер для связи врач-обследование =====

CREATE OR REPLACE FUNCTION trg_doctor_examination_history()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO doctor_examination_history
        (doctor_id, examination_id, valid_from, valid_to, is_current, operation)
        VALUES
        (NEW.doctor_id, NEW.examination_id, CURRENT_TIMESTAMP, NULL, TRUE, 'INSERT');

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE doctor_examination_history
        SET valid_to = CURRENT_TIMESTAMP,
            is_current = FALSE,
            operation = 'DELETE'
        WHERE doctor_id = OLD.doctor_id
          AND examination_id = OLD.examination_id
          AND is_current = TRUE;

        RETURN OLD;

    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE doctor_examination_history
        SET valid_to = CURRENT_TIMESTAMP,
            is_current = FALSE
        WHERE doctor_id = OLD.doctor_id
          AND examination_id = OLD.examination_id
          AND is_current = TRUE;

        INSERT INTO doctor_examination_history
        (doctor_id, examination_id, valid_from, valid_to, is_current, operation)
        VALUES
        (NEW.doctor_id, NEW.examination_id, CURRENT_TIMESTAMP, NULL, TRUE, 'UPDATE');

        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER doctor_examination_history_trigger
AFTER INSERT OR UPDATE OR DELETE ON doctor_examinations
FOR EACH ROW EXECUTE FUNCTION trg_doctor_examination_history();


-- ===== Триггер для связи врач-отделение =====

CREATE OR REPLACE FUNCTION trg_doctor_department_history()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO doctor_department_history
        (doctor_id, department_id, valid_from, valid_to, is_current, operation)
        VALUES
        (NEW.doctor_id, NEW.department_id, CURRENT_TIMESTAMP, NULL, TRUE, 'INSERT');

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE doctor_department_history
        SET valid_to = CURRENT_TIMESTAMP,
            is_current = FALSE,
            operation = 'DELETE'
        WHERE doctor_id = OLD.doctor_id
          AND department_id = OLD.department_id
          AND is_current = TRUE;

        RETURN OLD;

    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE doctor_department_history
        SET valid_to = CURRENT_TIMESTAMP,
            is_current = FALSE
        WHERE doctor_id = OLD.doctor_id
          AND department_id = OLD.department_id
          AND is_current = TRUE;

        INSERT INTO doctor_department_history
        (doctor_id, department_id, valid_from, valid_to, is_current, operation)
        VALUES
        (NEW.doctor_id, NEW.department_id, CURRENT_TIMESTAMP, NULL, TRUE, 'UPDATE');

        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER doctor_department_history_trigger
AFTER INSERT OR UPDATE OR DELETE ON doctor_departments
FOR EACH ROW EXECUTE FUNCTION trg_doctor_department_history();
