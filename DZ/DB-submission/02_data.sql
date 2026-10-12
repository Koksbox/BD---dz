-- =============================================================================
-- Часть I. Тестовые данные (English, >=5–10 строк по основным сущностям)
-- =============================================================================

SET search_path TO hospital;

INSERT INTO department (name, building, phone) VALUES
('Therapy', 'Building A', '+7-495-100-01-01'),
('Surgery', 'Building B', '+7-495-100-02-02'),
('Cardiology', 'Building A', '+7-495-100-03-03'),
('Neurology', 'Building C', '+7-495-100-04-04'),
('Diagnostics', 'Building D', '+7-495-100-05-05'),
('Pediatrics', 'Building C', '+7-495-100-06-06');

INSERT INTO ward (department_id, ward_number, capacity, floor) VALUES
(1, '101', 4, 1),
(1, '102', 2, 1),
(1, '103', 6, 2),
(2, '201', 3, 2),
(2, '202', 2, 2),
(2, '203', 4, 3),
(3, '301', 2, 3),
(3, '302', 4, 3),
(4, '401', 3, 4),
(4, '402', 2, 4),
(5, '501', 1, 1),
(6, '601', 4, 1);

INSERT INTO doctor (last_name, first_name, middle_name, specialization, phone, hire_date, department_id) VALUES
('Ivanov', 'Alexey', 'Petrovich', 'therapist', '+7-900-111-01-01', '2018-03-15', 1),
('Smirnova', 'Elena', 'Igorevna', 'surgeon', '+7-900-111-02-02', '2016-07-01', 2),
('Kozlov', 'Dmitry', 'Sergeevich', 'cardiologist', '+7-900-111-03-03', '2019-01-20', 3),
('Novikova', 'Maria', 'Andreevna', 'neurologist', '+7-900-111-04-04', '2020-05-12', 4),
('Petrov', 'Igor', 'Vladimirovich', 'ultrasound specialist', '+7-900-111-05-05', '2017-09-08', 5),
('Vasileva', 'Olga', 'Nikolaevna', 'radiologist', '+7-900-111-06-06', '2015-11-30', 5),
('Morozov', 'Pavel', 'Olegovich', 'pediatrician', '+7-900-111-07-07', '2021-02-14', 6),
('Fedorova', 'Anna', 'Yurevna', 'therapist', '+7-900-111-08-08', '2019-08-22', 1),
('Sokolov', 'Kirill', 'Alexeevich', 'anesthesiologist', '+7-900-111-09-09', '2014-04-03', NULL),
('Lebedeva', 'Natalia', 'Viktorovna', 'consultant', '+7-900-111-10-10', '2022-06-01', NULL);

INSERT INTO examination (name, description, price, duration_minutes) VALUES
('Abdominal ultrasound', 'Ultrasound of abdominal organs', 2500.00, 30),
('ECG', '12-lead electrocardiography', 800.00, 15),
('Brain MRI', 'Magnetic resonance imaging of the brain', 7500.00, 45),
('Chest X-ray', 'Plain chest radiography', 1200.00, 20),
('Complete blood count', 'Laboratory blood test', 500.00, 10),
('Echocardiography', 'Heart ultrasound', 3500.00, 40),
('Colonoscopy', 'Endoscopic exam of the colon', 9000.00, 60),
('Neurosonography', 'Brain ultrasound for children', 2000.00, 25);

INSERT INTO examination_schedule (examination_id, day_of_week, start_time, end_time) VALUES
(1, 1, '09:00', '12:00'),
(1, 3, '09:00', '12:00'),
(1, 5, '14:00', '17:00'),
(2, 1, '08:00', '10:00'),
(2, 2, '08:00', '10:00'),
(2, 4, '08:00', '10:00'),
(3, 2, '10:00', '14:00'),
(3, 4, '10:00', '14:00'),
(4, 1, '11:00', '13:00'),
(4, 3, '11:00', '13:00'),
(4, 5, '11:00', '13:00'),
(5, 1, '07:30', '09:00'),
(5, 2, '07:30', '09:00'),
(5, 3, '07:30', '09:00'),
(5, 4, '07:30', '09:00'),
(5, 5, '07:30', '09:00'),
(6, 3, '13:00', '16:00'),
(6, 5, '13:00', '16:00'),
(7, 2, '09:00', '12:00'),
(8, 4, '15:00', '17:00');

INSERT INTO doctor_examination (doctor_id, examination_id) VALUES
(5, 1), (5, 8), (3, 2), (3, 6), (6, 4), (6, 3), (4, 3),
(1, 5), (8, 5), (2, 7), (9, 7), (7, 8), (1, 1);
