-- 03_queries.sql
-- Запросы по заданию

-- 1. Все обследования с днем недели и временем
SELECT e.name,
       CASE s.day_of_week
           WHEN 1 THEN 'Понедельник'
           WHEN 2 THEN 'Вторник'
           WHEN 3 THEN 'Среда'
           WHEN 4 THEN 'Четверг'
           WHEN 5 THEN 'Пятница'
           WHEN 6 THEN 'Суббота'
           WHEN 7 THEN 'Воскресенье'
       END AS day_name,
       s.start_time,
       s.end_time
FROM examinations e
JOIN exam_schedule s ON s.examination_id = e.id
ORDER BY s.day_of_week, s.start_time;

-- 2. Врачи, которые проводят конкретное обследование
-- Для примера берем ЭКГ
SELECT d.full_name, d.specialty
FROM doctors d
JOIN doctor_examinations de ON de.doctor_id = d.id
JOIN examinations e ON e.id = de.examination_id
WHERE e.name = 'ЭКГ';

-- 3. Расписание на заданный день недели
-- 1 = понедельник
SELECT e.name, s.start_time, s.end_time
FROM exam_schedule s
JOIN examinations e ON e.id = s.examination_id
WHERE s.day_of_week = 1
ORDER BY s.start_time;

-- 4. Врачи и их отделения
SELECT d.full_name, dep.name AS department
FROM doctors d
LEFT JOIN doctor_departments dd ON dd.doctor_id = d.id
LEFT JOIN departments dep ON dep.id = dd.department_id
ORDER BY d.full_name;

-- 5. Отделения и количество палат
SELECT dep.name, COUNT(w.id) AS wards_count
FROM departments dep
LEFT JOIN wards w ON w.department_id = dep.id
GROUP BY dep.id, dep.name
ORDER BY dep.name;

-- 6. Обследования, которые начинаются после заданного времени
-- Для примера после 10:00
SELECT e.name, s.day_of_week, s.start_time
FROM exam_schedule s
JOIN examinations e ON e.id = s.examination_id
WHERE s.start_time > '10:00'
ORDER BY s.start_time;

-- 7. Врачи, участвующие больше чем в одном обследовании
SELECT d.full_name, COUNT(*) AS examinations_count
FROM doctors d
JOIN doctor_examinations de ON de.doctor_id = d.id
GROUP BY d.id, d.full_name
HAVING COUNT(*) > 1
ORDER BY examinations_count DESC;

-- 8. Обследования, которые проводит заданный врач
-- Для примера Иванов Иван Иванович
SELECT e.name
FROM examinations e
JOIN doctor_examinations de ON de.examination_id = e.id
JOIN doctors d ON d.id = de.doctor_id
WHERE d.full_name = 'Иванов Иван Иванович';

-- 9. Палаты заданного отделения
SELECT w.room_number, w.ward_type, w.capacity
FROM wards w
JOIN departments dep ON dep.id = w.department_id
WHERE dep.name = 'Кардиологическое отделение'
ORDER BY w.room_number;
