-- =============================================================================
-- Часть I. SQL-запросы по заданию
-- day_of_week: 1=Mon … 7=Sun
-- =============================================================================

SET search_path TO hospital;

CREATE OR REPLACE VIEW v_weekday AS
SELECT * FROM (VALUES
    (1, 'Monday'), (2, 'Tuesday'), (3, 'Wednesday'),
    (4, 'Thursday'), (5, 'Friday'), (6, 'Saturday'), (7, 'Sunday')
) AS t(day_of_week, weekday_name);

-- 1. Все обследования: день недели, начало, конец
SELECT
    e.name AS examination,
    w.weekday_name,
    es.start_time,
    es.end_time
FROM examination_schedule es
JOIN examination e ON e.examination_id = es.examination_id
JOIN v_weekday w ON w.day_of_week = es.day_of_week
ORDER BY e.name, es.day_of_week, es.start_time;

-- 2. Врачи, которые проводят заданное обследование (ECG)
SELECT
    d.doctor_id,
    d.last_name || ' ' || d.first_name || COALESCE(' ' || d.middle_name, '') AS doctor_fio,
    d.specialization,
    d.phone
FROM doctor_examination de
JOIN doctor d ON d.doctor_id = de.doctor_id
JOIN examination e ON e.examination_id = de.examination_id
WHERE e.name = 'ECG'
ORDER BY d.last_name;

-- 3. Расписание на заданный день недели (Wednesday = 3)
SELECT
    e.name AS examination,
    es.start_time,
    es.end_time
FROM examination_schedule es
JOIN examination e ON e.examination_id = es.examination_id
WHERE es.day_of_week = 3
ORDER BY es.start_time, e.name;

-- 4. Врачи с отделениями
SELECT
    d.doctor_id,
    d.last_name || ' ' || d.first_name AS doctor_fio,
    d.specialization,
    COALESCE(dep.name, '(unassigned)') AS department
FROM doctor d
LEFT JOIN department dep ON dep.department_id = d.department_id
ORDER BY dep.name NULLS LAST, d.last_name;

-- 5. Отделения и число палат
SELECT
    dep.name AS department,
    COUNT(w.ward_id) AS ward_count
FROM department dep
LEFT JOIN ward w ON w.department_id = dep.department_id
GROUP BY dep.department_id, dep.name
ORDER BY ward_count DESC, dep.name;

-- 6. Обследования, начинающиеся после 12:00
SELECT DISTINCT
    e.name AS examination,
    w.weekday_name,
    es.start_time,
    es.end_time
FROM examination_schedule es
JOIN examination e ON e.examination_id = es.examination_id
JOIN v_weekday w ON w.day_of_week = es.day_of_week
WHERE es.start_time > TIME '12:00'
ORDER BY es.start_time, e.name;

-- 7. Врачи, участвующие более чем в одном обследовании
SELECT
    d.doctor_id,
    d.last_name || ' ' || d.first_name AS doctor_fio,
    COUNT(*) AS examination_count
FROM doctor_examination de
JOIN doctor d ON d.doctor_id = de.doctor_id
GROUP BY d.doctor_id, d.last_name, d.first_name
HAVING COUNT(*) > 1
ORDER BY examination_count DESC, d.last_name;

-- 8. Обследования заданного врача (Petrov Igor)
SELECT
    e.name AS examination,
    e.price,
    e.duration_minutes,
    e.description
FROM doctor_examination de
JOIN doctor d ON d.doctor_id = de.doctor_id
JOIN examination e ON e.examination_id = de.examination_id
WHERE d.last_name = 'Petrov' AND d.first_name = 'Igor'
ORDER BY e.name;

-- 9. Палаты заданного отделения (Surgery)
SELECT
    w.ward_number,
    w.capacity,
    w.floor
FROM ward w
JOIN department dep ON dep.department_id = w.department_id
WHERE dep.name = 'Surgery'
ORDER BY w.ward_number;
