# Отчёт: БД «Больница» + историчность (SCD Type 2)

Автор: Бикметов Эмиль  
СУБД: **PostgreSQL**  
ER-диаграмма: `er_diagramma.jpg`

---

## Часть I. Предметная область

В больнице проводятся обследования по расписанию (день недели, время начала/окончания). Врачи проводят обследования. Врачи могут быть закреплены за отделениями; отделения состоят из палат.

Нужно получать сведения: о расписании обследований; о врачах и их участии в обследованиях; об отделениях и палатах.

### Сущности и атрибуты

| Таблица | PK | Атрибуты |
|---|---|---|
| `department` | `department_id` | `name` UNIQUE, `building`, `phone` |
| `ward` | `ward_id` | `ward_number`, `capacity`, `floor`, `department_id` FK |
| `doctor` | `doctor_id` | ФИО, `specialization`, `phone` UNIQUE, `hire_date`, `department_id` FK (NULL допустим) |
| `examination` | `examination_id` | `name` UNIQUE, `description`, `price`, `duration_minutes` |
| `examination_schedule` | `schedule_id` | `examination_id` FK, `day_of_week` 1–7, `start_time`, `end_time` |
| `doctor_examination` | (`doctor_id`,`examination_id`) | связка M:N |

### Связи

- `department` 1:N `ward`
- `department` 1:N `doctor` (врач может быть без отделения)
- `examination` 1:N `examination_schedule`
- `doctor` M:N `examination` через `doctor_examination`

### Почему расписание — отдельная таблица

Одно обследование может проводиться **несколько раз в неделю** (и несколько раз в день). Если день/время хранить в `examination`, появятся дубли названий и аномалии обновления. Каталог (`examination`) стабилен; меняется только `examination_schedule`.

### Ограничения

- `CHECK (capacity > 0)`, `CHECK (day_of_week BETWEEN 1 AND 7)`, `CHECK (start_time < end_time)`
- `UNIQUE (name)` у department/examination; `UNIQUE (phone)` у doctor
- `UNIQUE (department_id, ward_number)`, `UNIQUE (examination_id, day_of_week, start_time)`

### Нормализация (3NF)

Атрибуты зависят только от ключа своей таблицы. Повторяющиеся группы (слоты расписания, участие врачей) вынесены в отдельные таблицы. Избыточности названий обследований в расписании нет.

### Запросы

Скрипт `03_queries.sql` — все 9 пунктов задания (фильтры на English: ECG, Wednesday, Petrov Igor, Surgery, after 12:00).

---

## Часть II. Историчность (SCD Type 2)

### Что версионируем и почему

| Сущность | История | Обоснование |
|---|---|---|
| `doctor` | **да** → `doctor_history` | смена отделения / specialization / phone нужна для срезов «кто где работал на дату» |
| `ward` | **да** → `ward_history` | capacity / floor меняются при переоборудовании |
| `examination_schedule` | **да** → `examination_schedule_history` | день и время слота меняются |
| `doctor_examination` | **да** → `doctor_examination_history` | M:N — кто проводил обследование **в какой период** |
| `department` | **нет** | справочник; правка названия = SCD1 |
| `examination` | **нет** | справочник типов; price/duration правятся без версий (SCD1) |

В истории храним **только меняющиеся атрибуты** (как на ER-диаграмме), не всю строку актуальной таблицы.  
ФИО и `hire_date` врача не версионируем: при типичных сценариях это не «версии состояния».

### SCD Type 2

- `history_id` — суррогатный ключ версии  
- бизнес-ключ (`doctor_id` / `ward_id` / `schedule_id` / пара doctor+examination)  
- `valid_from`, `valid_to` (**NULL = ∞**, открытый интервал = текущая версия)  
- `is_current`  
- `operation` ∈ {INSERT, UPDATE, DELETE}

Ограничения: `valid_from < valid_to`; частичный UNIQUE на текущую версию; `EXCLUDE` + `btree_gist` против пересечения интервалов.

### Триггеры

На актуальных таблицах `AFTER INSERT OR UPDATE OR DELETE`:

- INSERT → открыть версию  
- UPDATE → закрыть старую (`valid_to`, `is_current=FALSE`) + открыть новую  
- DELETE → закрыть текущую (логическое удаление в истории)

Скрипт: `04_history.sql` (таблицы + триггеры + bootstrap после seed).

### Демо и срезы

`05_history_demo.sql`: перевод врача, изменение палаты/слота, DELETE связей; запросы всех версий, as-of, сверка `is_current` с live, M:N as-of.

---

## Как запустить (PostgreSQL)

```text
psql -U postgres -d hospital_db -f 01_schema.sql
psql -U postgres -d hospital_db -f 02_data.sql
psql -U postgres -d hospital_db -f 04_history.sql
psql -U postgres -d hospital_db -f 03_queries.sql
psql -U postgres -d hospital_db -f 05_history_demo.sql
```

Либо Python-раннер: `HospitalPython/main.py` (см. соседний проект).

## Файлы сдачи

| Файл | Содержание |
|---|---|
| `er_diagramma.jpg` | ER + SCD2 |
| `01_schema.sql` | таблицы части I |
| `02_data.sql` | тестовые данные |
| `03_queries.sql` | 9 запросов |
| `04_history.sql` | история + триггеры |
| `05_history_demo.sql` | демо + срезы |
| `REPORT.md` | этот отчёт |
