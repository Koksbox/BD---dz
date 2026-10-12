# Hospital DB — Python + PostgreSQL (Visual Studio)

Учебный проект по БД «Больница»:

- **Часть I** — схема больницы (3NF), seed на английском, 9 SQL-запросов
- **Часть II** — историчность **SCD Type 2**, триггеры PL/pgSQL, as-of срезы

Точка входа: `main.py`. SQL = `DB-submission/` (сдача в GitHub как у однокурсников).

## Стек

- Python 3.11+
- PostgreSQL 14+ (`btree_gist`, PL/pgSQL)
- `psycopg` + `python-dotenv`

Сдача: fork [anst-foto/DB](https://github.com/anst-foto/DB) → PR ([примеры](https://github.com/anst-foto/DB/pulls)). Пакет: `../DB-submission/`.

## Структура

```
HospitalPython/
  main.py
  sql/   # 01_schema, 02_data, 03_queries, 04_history, 05_history_demo
  docs/er_diagramma.jpg
```

## Модель = ER-диаграмма (история только по полям с картинки)

| История | Поля версии |
|---|---|
| `doctor_history` | `doctor_id` (бизнес-ключ), `department_id`, `specialization`, `phone` |
| `ward_history` | `ward_id`, `capacity`, `floor` |
| `examination_schedule_history` | `schedule_id`, `day_of_week`, `start_time`, `end_time` |
| `doctor_examination_history` | `doctor_id`, `examination_id` |

`valid_to NULL = ∞`. Без истории: `department`, `examination`.

## Быстрый старт

### 1. PostgreSQL

1. Установите [PostgreSQL](https://www.postgresql.org/download/windows/).
2. Создайте БД:

```sql
CREATE DATABASE hospital_db;
```

(через pgAdmin или `psql -U postgres`)

3. Пользователь должен иметь право `CREATE EXTENSION` (для `btree_gist`) — обычно роль `postgres`.

### 2. Python-окружение

Нужен **обычный** CPython 3.11+ (не free-threaded `python3.14t` — для него нет `psycopg-binary`).

В корне проекта `HospitalPython`:

```powershell
cd c:\Users\RPO23\source\repos\DZ\HospitalPython
# явно обычный python.exe, не *t.exe:
& "C:\Program Files\Python314\python.exe" -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 3. Конфиг

```powershell
copy .env.example .env
```

Откройте `.env` и укажите пароль:

```
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/hospital_db
```

Пароль **не** хранится в коде. Файл `.env` в `.gitignore`.

### 4. Запуск

```powershell
python main.py
```

Порядок выполнения:

1. `01_schema.sql` — схема
2. `02_data.sql` — тестовые данные
3. `04_history.sql` — SCD2 + триггеры + bootstrap
4. `03_queries.sql` — 9 запросов части I
5. `05_history_demo.sql` — демо UPDATE/DELETE + as-of срезы

При ошибке — traceback в консоль, код выхода `1`.

---

## Visual Studio

### Вариант A — Open Folder (рекомендуется)

1. **File → Open → Folder…** → выберите `HospitalPython`
2. Установите расширение **Python** (если ещё нет)
3. Выберите интерпретатор: `.venv\Scripts\python.exe` (Ctrl+Shift+P → *Python: Select Interpreter*)
4. Убедитесь, что `.env` заполнен
5. **Startup file** = `main.py`, **Working Directory** = корень проекта  
   (уже задано в `.vscode/launch.json`)
6. Нажмите **F5** или Run → Start Debugging → *HospitalPython: main.py*

### Вариант B — Python Application project

1. Create a new **Python Application** project (или Add Existing)
2. Set **Startup File** = `main.py`
3. Project Properties → **Working Directory** = `$(ProjectDir)` / корень `HospitalPython`
4. F5

### VS Code

Тот же `.vscode/launch.json`: откройте папку `HospitalPython`, F5.

---

## Пример вывода (запрос 2 — врачи по ECG)

```
--- 2. Doctors who perform a given examination (ECG) ---
SQL: SELECT d.doctor_id, d.last_name || ' ' || d.first_name || ... WHERE e.name = 'ECG' ...
+------------+-------------------------------+---------------+-----------+
| doctor_id  | doctor_fio                    | specialty     | role      |
+------------+-------------------------------+---------------+-----------+
| 3          | Kozlov Dmitry Sergeevich      | cardiologist  | performer |
+------------+-------------------------------+---------------+-----------+
(1 row)
```

Полные таблицы также пишутся в `results/part1_q02.txt` и `.csv`.

---

## Данные (кратко)

- Отделения, обследования, роли, типы палат — **English**
- ≥5–10 записей по основным сущностям
- Врач ↔ обследование — **M:N**; расписание отдельно от справочника
- CHECK: `start_time < end_time`, `weekday` 1..7, `capacity > 0`

## Исходные SQL

Скопированы из `c:\Users\RPO23\Documents\HospitalDB`.  
Файл `00_install_all.sql` рассчитан на `psql` (`\i`) — раннер его не использует.
