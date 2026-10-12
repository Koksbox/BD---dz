# Как сдать в [anst-foto/DB](https://github.com/anst-foto/DB) через Pull Request

Однокурсники сдают так: **fork → файлы в корень → Pull Request**  
([список PR](https://github.com/anst-foto/DB/pulls)).

Уже есть PR #6 «ER - diagramma Бикметов Эмиль» от `aaqmk` только с картинкой.  
Нужно **доложить** SQL + отчёт в тот же fork и обновить PR (или открыть новый).

## Состав сдачи (корень репозитория)

```
er_diagramma.jpg      # ER с SCD2
01_schema.sql
02_data.sql
03_queries.sql
04_history.sql         # история + триггеры + bootstrap
05_history_demo.sql    # демо UPDATE/DELETE + срезы
REPORT.md
```

Файлы уже лежат в этой папке `DB-submission/`.

## Шаги

### 1. Fork (если ещё нет)

Открой https://github.com/anst-foto/DB → **Fork**  
(у Бикметова fork уже есть: https://github.com/aaqmk/DB)

### 2. Скопировать файлы в fork

```powershell
git clone https://github.com/aaqmk/DB.git
cd DB
copy c:\Users\RPO23\source\repos\DZ\DB-submission\* .
# не затирай README задания, если хочешь — оставь; файлы сдачи добавь рядом
git add er_diagramma.jpg 01_schema.sql 02_data.sql 03_queries.sql 04_history.sql 05_history_demo.sql REPORT.md
git commit -m "Hospital DB: schema, data, queries, SCD2 history, report"
git push origin main
```

### 3. Pull Request

Если PR #6 уже открыт в `anst-foto/DB` — после `push` он **обновится сам**.  
Иначе: на GitHub → **Contribute → Open pull request**  
Заголовок, например: `Больница — схема, запросы, SCD Type 2 (Бикметов)`.

### 4. Проверка локально (по желанию)

```text
CREATE DATABASE hospital_db;
psql -U postgres -d hospital_db -f 01_schema.sql
psql -U postgres -d hospital_db -f 02_data.sql
psql -U postgres -d hospital_db -f 04_history.sql
psql -U postgres -d hospital_db -f 03_queries.sql
psql -U postgres -d hospital_db -f 05_history_demo.sql
```

Или: `HospitalPython` → `python main.py` (тот же SQL).
