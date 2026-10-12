-- =============================================================================
-- Часть II. SCD Type 2 — исторические таблицы + триггеры (как на ER-диаграмме)
--
-- Версионируем (только меняющиеся атрибуты с диаграммы):
--   ward_history:                 capacity, floor
--   doctor_history:               department_id, specialization, phone
--                                 (doctor_id = бизнес-ключ; valid_to NULL = ∞)
--   examination_schedule_history: day_of_week, start_time, end_time
--   doctor_examination_history:   факт связи doctor↔examination во времени
--
-- НЕ версионируем: department, examination — справочники
-- =============================================================================

SET search_path TO hospital;

CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ---------- ward_history ----------
CREATE TABLE ward_history (
    history_id      BIGSERIAL PRIMARY KEY,
    ward_id         INTEGER NOT NULL,
    capacity        INTEGER NOT NULL,
    floor           INTEGER NOT NULL,
    valid_from      TIMESTAMP NOT NULL,
    valid_to        TIMESTAMP,              -- NULL = ∞ (текущая)
    is_current      BOOLEAN NOT NULL DEFAULT TRUE,
    operation       VARCHAR(10) NOT NULL,
    CONSTRAINT chk_ward_hist_period
        CHECK (valid_to IS NULL OR valid_from < valid_to),
    CONSTRAINT chk_ward_hist_operation
        CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

CREATE UNIQUE INDEX uq_ward_hist_current
    ON ward_history (ward_id) WHERE is_current = TRUE;

ALTER TABLE ward_history
    ADD CONSTRAINT ex_ward_hist_no_overlap
    EXCLUDE USING gist (
        ward_id WITH =,
        tsrange(valid_from, COALESCE(valid_to, 'infinity'::timestamp), '[)') WITH &&
    );

-- ---------- doctor_history (бизнес-ключ = doctor_id) ----------
CREATE TABLE doctor_history (
    history_id      BIGSERIAL PRIMARY KEY,
    doctor_id       INTEGER NOT NULL,       -- бизнес-ключ
    department_id   INTEGER,
    specialization  VARCHAR(100) NOT NULL,
    phone           VARCHAR(30),
    valid_from      TIMESTAMP NOT NULL,
    valid_to        TIMESTAMP,              -- NULL = ∞
    is_current      BOOLEAN NOT NULL DEFAULT TRUE,
    operation       VARCHAR(10) NOT NULL,
    CONSTRAINT chk_doctor_hist_period
        CHECK (valid_to IS NULL OR valid_from < valid_to),
    CONSTRAINT chk_doctor_hist_operation
        CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

CREATE UNIQUE INDEX uq_doctor_hist_current
    ON doctor_history (doctor_id) WHERE is_current = TRUE;

ALTER TABLE doctor_history
    ADD CONSTRAINT ex_doctor_hist_no_overlap
    EXCLUDE USING gist (
        doctor_id WITH =,
        tsrange(valid_from, COALESCE(valid_to, 'infinity'::timestamp), '[)') WITH &&
    );

-- ---------- examination_schedule_history ----------
CREATE TABLE examination_schedule_history (
    history_id      BIGSERIAL PRIMARY KEY,
    schedule_id     INTEGER NOT NULL,
    day_of_week     SMALLINT NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    valid_from      TIMESTAMP NOT NULL,
    valid_to        TIMESTAMP,
    is_current      BOOLEAN NOT NULL DEFAULT TRUE,
    operation       VARCHAR(10) NOT NULL,
    CONSTRAINT chk_sched_hist_period
        CHECK (valid_to IS NULL OR valid_from < valid_to),
    CONSTRAINT chk_sched_hist_operation
        CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

CREATE UNIQUE INDEX uq_sched_hist_current
    ON examination_schedule_history (schedule_id) WHERE is_current = TRUE;

ALTER TABLE examination_schedule_history
    ADD CONSTRAINT ex_sched_hist_no_overlap
    EXCLUDE USING gist (
        schedule_id WITH =,
        tsrange(valid_from, COALESCE(valid_to, 'infinity'::timestamp), '[)') WITH &&
    );

-- ---------- doctor_examination_history ----------
CREATE TABLE doctor_examination_history (
    history_id      BIGSERIAL PRIMARY KEY,
    doctor_id       INTEGER NOT NULL,
    examination_id  INTEGER NOT NULL,
    valid_from      TIMESTAMP NOT NULL,
    valid_to        TIMESTAMP,
    is_current      BOOLEAN NOT NULL DEFAULT TRUE,
    operation       VARCHAR(10) NOT NULL,
    CONSTRAINT chk_de_hist_period
        CHECK (valid_to IS NULL OR valid_from < valid_to),
    CONSTRAINT chk_de_hist_operation
        CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

CREATE UNIQUE INDEX uq_de_hist_current
    ON doctor_examination_history (doctor_id, examination_id)
    WHERE is_current = TRUE;

ALTER TABLE doctor_examination_history
    ADD CONSTRAINT ex_de_hist_no_overlap
    EXCLUDE USING gist (
        doctor_id WITH =,
        examination_id WITH =,
        tsrange(valid_from, COALESCE(valid_to, 'infinity'::timestamp), '[)') WITH &&
    );

-- =============================================================================
-- Триггеры AFTER INSERT / UPDATE / DELETE
-- =============================================================================

CREATE OR REPLACE FUNCTION trg_ward_history()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_now TIMESTAMP := clock_timestamp();
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO ward_history (ward_id, capacity, floor, valid_from, valid_to, is_current, operation)
        VALUES (NEW.ward_id, NEW.capacity, NEW.floor, v_now, NULL, TRUE, 'INSERT');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE ward_history
        SET valid_to = v_now, is_current = FALSE
        WHERE ward_id = OLD.ward_id AND is_current = TRUE;
        INSERT INTO ward_history (ward_id, capacity, floor, valid_from, valid_to, is_current, operation)
        VALUES (NEW.ward_id, NEW.capacity, NEW.floor, v_now, NULL, TRUE, 'UPDATE');
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE ward_history
        SET valid_to = v_now, is_current = FALSE, operation = 'DELETE'
        WHERE ward_id = OLD.ward_id AND is_current = TRUE;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS ward_aiud_history ON ward;
CREATE TRIGGER ward_aiud_history
AFTER INSERT OR UPDATE OR DELETE ON ward
FOR EACH ROW EXECUTE PROCEDURE trg_ward_history();

CREATE OR REPLACE FUNCTION trg_doctor_history()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_now TIMESTAMP := clock_timestamp();
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO doctor_history
            (doctor_id, department_id, specialization, phone, valid_from, valid_to, is_current, operation)
        VALUES
            (NEW.doctor_id, NEW.department_id, NEW.specialization, NEW.phone, v_now, NULL, TRUE, 'INSERT');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE doctor_history
        SET valid_to = v_now, is_current = FALSE
        WHERE doctor_id = OLD.doctor_id AND is_current = TRUE;
        INSERT INTO doctor_history
            (doctor_id, department_id, specialization, phone, valid_from, valid_to, is_current, operation)
        VALUES
            (NEW.doctor_id, NEW.department_id, NEW.specialization, NEW.phone, v_now, NULL, TRUE, 'UPDATE');
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE doctor_history
        SET valid_to = v_now, is_current = FALSE, operation = 'DELETE'
        WHERE doctor_id = OLD.doctor_id AND is_current = TRUE;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS doctor_aiud_history ON doctor;
CREATE TRIGGER doctor_aiud_history
AFTER INSERT OR UPDATE OR DELETE ON doctor
FOR EACH ROW EXECUTE PROCEDURE trg_doctor_history();

CREATE OR REPLACE FUNCTION trg_examination_schedule_history()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_now TIMESTAMP := clock_timestamp();
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO examination_schedule_history
            (schedule_id, day_of_week, start_time, end_time, valid_from, valid_to, is_current, operation)
        VALUES
            (NEW.schedule_id, NEW.day_of_week, NEW.start_time, NEW.end_time, v_now, NULL, TRUE, 'INSERT');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE examination_schedule_history
        SET valid_to = v_now, is_current = FALSE
        WHERE schedule_id = OLD.schedule_id AND is_current = TRUE;
        INSERT INTO examination_schedule_history
            (schedule_id, day_of_week, start_time, end_time, valid_from, valid_to, is_current, operation)
        VALUES
            (NEW.schedule_id, NEW.day_of_week, NEW.start_time, NEW.end_time, v_now, NULL, TRUE, 'UPDATE');
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE examination_schedule_history
        SET valid_to = v_now, is_current = FALSE, operation = 'DELETE'
        WHERE schedule_id = OLD.schedule_id AND is_current = TRUE;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS examination_schedule_aiud_history ON examination_schedule;
CREATE TRIGGER examination_schedule_aiud_history
AFTER INSERT OR UPDATE OR DELETE ON examination_schedule
FOR EACH ROW EXECUTE PROCEDURE trg_examination_schedule_history();

CREATE OR REPLACE FUNCTION trg_doctor_examination_history()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_now TIMESTAMP := clock_timestamp();
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO doctor_examination_history
            (doctor_id, examination_id, valid_from, valid_to, is_current, operation)
        VALUES (NEW.doctor_id, NEW.examination_id, v_now, NULL, TRUE, 'INSERT');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE doctor_examination_history
        SET valid_to = v_now, is_current = FALSE
        WHERE doctor_id = OLD.doctor_id AND examination_id = OLD.examination_id AND is_current = TRUE;
        INSERT INTO doctor_examination_history
            (doctor_id, examination_id, valid_from, valid_to, is_current, operation)
        VALUES (NEW.doctor_id, NEW.examination_id, v_now, NULL, TRUE, 'UPDATE');
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE doctor_examination_history
        SET valid_to = v_now, is_current = FALSE, operation = 'DELETE'
        WHERE doctor_id = OLD.doctor_id AND examination_id = OLD.examination_id AND is_current = TRUE;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS doctor_examination_aiud_history ON doctor_examination;
CREATE TRIGGER doctor_examination_aiud_history
AFTER INSERT OR UPDATE OR DELETE ON doctor_examination
FOR EACH ROW EXECUTE PROCEDURE trg_doctor_examination_history();

-- Seed был до триггеров → первичное наполнение истории
CREATE OR REPLACE FUNCTION bootstrap_history_from_current()
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_now TIMESTAMP := clock_timestamp();
BEGIN
    TRUNCATE ward_history, doctor_history,
             examination_schedule_history, doctor_examination_history
             RESTART IDENTITY;

    INSERT INTO ward_history (ward_id, capacity, floor, valid_from, valid_to, is_current, operation)
    SELECT ward_id, capacity, floor, v_now, NULL, TRUE, 'INSERT' FROM ward;

    INSERT INTO doctor_history (doctor_id, department_id, specialization, phone, valid_from, valid_to, is_current, operation)
    SELECT doctor_id, department_id, specialization, phone, v_now, NULL, TRUE, 'INSERT' FROM doctor;

    INSERT INTO examination_schedule_history (schedule_id, day_of_week, start_time, end_time, valid_from, valid_to, is_current, operation)
    SELECT schedule_id, day_of_week, start_time, end_time, v_now, NULL, TRUE, 'INSERT' FROM examination_schedule;

    INSERT INTO doctor_examination_history (doctor_id, examination_id, valid_from, valid_to, is_current, operation)
    SELECT doctor_id, examination_id, v_now, NULL, TRUE, 'INSERT' FROM doctor_examination;
END;
$$;

SELECT bootstrap_history_from_current();
