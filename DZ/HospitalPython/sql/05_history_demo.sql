-- =============================================================================
-- Часть II. Демо UPDATE/DELETE + запросы-срезы по истории
-- Запускать после 01 → 02 → 04
-- =============================================================================

SET search_path TO hospital;

SELECT '=== Doctor #3 before transfer ===' AS step;
SELECT doctor_id, last_name, specialization, department_id, phone
FROM doctor WHERE doctor_id = 3;

SELECT '=== Doctor #3 history (start) ===' AS step;
SELECT history_id, department_id, specialization, phone, valid_from, valid_to, is_current, operation
FROM doctor_history WHERE doctor_id = 3 ORDER BY valid_from;

-- 1) Перевод кардиолога Kozlov: Cardiology (3) → Therapy (1)
SELECT pg_sleep(1);
UPDATE doctor
SET department_id = 1,
    specialization = 'cardiologist-therapist'
WHERE doctor_id = 3;

-- 2) Переоборудование палаты 201 (ward_id = 4)
SELECT pg_sleep(1);
UPDATE ward
SET capacity = 5,
    floor = 3
WHERE ward_id = 4;

-- 3) Сдвиг слота расписания
SELECT pg_sleep(1);
UPDATE examination_schedule
SET start_time = TIME '10:00',
    end_time   = TIME '13:00'
WHERE schedule_id = 1;

-- 4) Удаление связи M:N (в истории — закрытие версии)
SELECT pg_sleep(1);
DELETE FROM doctor_examination
WHERE doctor_id = 1 AND examination_id = 1;

-- 5) Удаление слота расписания
SELECT pg_sleep(1);
DELETE FROM examination_schedule WHERE schedule_id = 20;

SELECT '=== Doctor #3 history after transfer ===' AS step;
SELECT history_id, department_id, specialization, phone, valid_from, valid_to, is_current, operation
FROM doctor_history WHERE doctor_id = 3 ORDER BY valid_from;

SELECT '=== Ward #4 history ===' AS step;
SELECT history_id, capacity, floor, valid_from, valid_to, is_current, operation
FROM ward_history WHERE ward_id = 4 ORDER BY valid_from;

SELECT '=== Schedule #1 history ===' AS step;
SELECT history_id, day_of_week, start_time, end_time, valid_from, valid_to, is_current, operation
FROM examination_schedule_history WHERE schedule_id = 1 ORDER BY valid_from;

SELECT '=== Deleted link history ===' AS step;
SELECT history_id, doctor_id, examination_id, valid_from, valid_to, is_current, operation
FROM doctor_examination_history
WHERE doctor_id = 1 AND examination_id = 1
ORDER BY valid_from;

-- ---------- Запросы-срезы ----------

-- Все версии врача #3
SELECT history_id, department_id, specialization, phone,
       valid_from, valid_to, is_current, operation
FROM doctor_history
WHERE doctor_id = 3
ORDER BY valid_from;

-- Срез «как было» сразу после первой версии
WITH first_ver AS (
    SELECT MIN(valid_from) AS t0 FROM doctor_history WHERE doctor_id = 3
)
SELECT h.*
FROM doctor_history h
CROSS JOIN first_ver f
WHERE h.doctor_id = 3
  AND h.valid_from <= f.t0 + INTERVAL '0.5 second'
  AND (h.valid_to IS NULL OR h.valid_to > f.t0 + INTERVAL '0.5 second');

-- Палата #4: первая версия vs текущая
WITH bounds AS (
    SELECT MIN(valid_from) AS t_first FROM ward_history WHERE ward_id = 4
)
SELECT 'as of first version' AS as_of_label, h.capacity, h.floor, h.valid_from, h.valid_to
FROM ward_history h CROSS JOIN bounds b
WHERE h.ward_id = 4
  AND h.valid_from <= b.t_first
  AND (h.valid_to IS NULL OR h.valid_to > b.t_first)
UNION ALL
SELECT 'current (is_current)', h.capacity, h.floor, h.valid_from, h.valid_to
FROM ward_history h
WHERE h.ward_id = 4 AND h.is_current = TRUE;

-- Текущие версии vs live-таблица (должны совпадать)
SELECT 'history.is_current' AS source, h.doctor_id, h.specialization, h.department_id, h.phone
FROM doctor_history h WHERE h.is_current = TRUE
ORDER BY h.doctor_id;

SELECT 'doctor (live)' AS source, d.doctor_id, d.specialization, d.department_id, d.phone
FROM doctor d ORDER BY d.doctor_id;

-- Расхождения (ожидается 0 строк)
SELECT h.doctor_id
FROM doctor_history h
JOIN doctor d ON d.doctor_id = h.doctor_id
WHERE h.is_current = TRUE
  AND (
        h.specialization IS DISTINCT FROM d.specialization
     OR h.department_id IS DISTINCT FROM d.department_id
     OR h.phone IS DISTINCT FROM d.phone
  );

-- M:N as-of: кто проводил Abdominal ultrasound в начале истории
WITH target AS (
    SELECT examination_id FROM examination WHERE name = 'Abdominal ultrasound'
),
as_of AS (
    SELECT MIN(h.valid_from) + INTERVAL '0.1 second' AS ts
    FROM doctor_examination_history h
    JOIN target t ON t.examination_id = h.examination_id
)
SELECT
    d.last_name || ' ' || d.first_name AS doctor_fio,
    e.name AS examination,
    h.valid_from, h.valid_to, h.operation, a.ts AS as_of_ts
FROM doctor_examination_history h
JOIN target t ON t.examination_id = h.examination_id
JOIN doctor d ON d.doctor_id = h.doctor_id
JOIN examination e ON e.examination_id = h.examination_id
CROSS JOIN as_of a
WHERE h.valid_from <= a.ts
  AND (h.valid_to IS NULL OR h.valid_to > a.ts)
ORDER BY d.last_name;

-- Текущие исполнители того же обследования
SELECT d.last_name || ' ' || d.first_name AS doctor_fio
FROM doctor_examination de
JOIN doctor d ON d.doctor_id = de.doctor_id
JOIN examination e ON e.examination_id = de.examination_id
WHERE e.name = 'Abdominal ultrasound'
ORDER BY d.last_name;
