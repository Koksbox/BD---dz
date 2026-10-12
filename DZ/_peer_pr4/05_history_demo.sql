-- 05_history_demo.sql
-- Небольшая демонстрация работы историчности

-- 1. Меняем время одного обследования
UPDATE exam_schedule
SET start_time = '10:30',
    end_time = '13:30'
WHERE id = 3;

-- Проверяем все версии этой строки расписания
SELECT history_id, schedule_id, examination_id,
       day_of_week, start_time, end_time,
       valid_from, valid_to, is_current, operation
FROM exam_schedule_history
WHERE schedule_id = 3
ORDER BY valid_from;

-- 2. Убираем врача из одного обследования
DELETE FROM doctor_examinations
WHERE doctor_id = 1 AND examination_id = 2;

-- Проверяем историю связи
SELECT *
FROM doctor_examination_history
WHERE doctor_id = 1 AND examination_id = 2
ORDER BY valid_from;

-- 3. Добавляем врачу новое отделение
INSERT INTO doctor_departments (doctor_id, department_id)
VALUES (3, 5);

-- Текущие версии отделений врача
SELECT *
FROM doctor_department_history
WHERE doctor_id = 3
  AND is_current = TRUE;

-- ===== Запросы по истории =====

-- Все версии выбранного расписания
SELECT *
FROM exam_schedule_history
WHERE schedule_id = 3
ORDER BY valid_from;

-- Состояние расписания на заданный момент времени.
-- Вместо CURRENT_TIMESTAMP можно поставить, например:
-- TIMESTAMP '2026-10-01 12:00:00'
SELECT *
FROM exam_schedule_history
WHERE schedule_id = 3
  AND valid_from <= CURRENT_TIMESTAMP
  AND (valid_to IS NULL OR valid_to > CURRENT_TIMESTAMP);

-- Только текущие версии расписания
SELECT *
FROM exam_schedule_history
WHERE is_current = TRUE
ORDER BY schedule_id;

-- Кто проводил обследование с id = 2 на заданный момент времени
SELECT d.full_name, e.name
FROM doctor_examination_history h
JOIN doctors d ON d.id = h.doctor_id
JOIN examinations e ON e.id = h.examination_id
WHERE h.examination_id = 2
  AND h.valid_from <= CURRENT_TIMESTAMP
  AND (h.valid_to IS NULL OR h.valid_to > CURRENT_TIMESTAMP)
ORDER BY d.full_name;

-- В каких отделениях работал врач с id = 1 на заданный момент времени
SELECT d.full_name, dep.name
FROM doctor_department_history h
JOIN doctors d ON d.id = h.doctor_id
JOIN departments dep ON dep.id = h.department_id
WHERE h.doctor_id = 1
  AND h.valid_from <= CURRENT_TIMESTAMP
  AND (h.valid_to IS NULL OR h.valid_to > CURRENT_TIMESTAMP);
