# ER «Больница» + SCD Type 2

Источник: `er_diagramma.jpg` (как в PR / задании).

## Сравнение с диаграммой

| Элемент | На диаграмме | В SQL |
|---|---|---|
| `department` | name, building, phone | ✅ |
| `ward` | ward_number, capacity, floor, department_id | ✅ |
| `doctor` | ФИО, specialization, phone UNIQUE, hire_date, department_id | ✅ |
| `examination` | name, description, price, duration_minutes | ✅ |
| `doctor_examination` | PK(doctor_id, examination_id) | ✅ |
| `examination_schedule` | day_of_week, start_time, end_time | ✅ |
| `ward_history` | ward_id, capacity, floor + SCD | ✅ только эти поля |
| `doctor_history` | doctor_id (бизнес-ключ), department_id, specialization, phone + SCD; valid_to NULL=∞ | ✅ |
| `examination_schedule_history` | schedule_id, day_of_week, start/end + SCD | ✅ |
| `doctor_examination_history` | doctor_id, examination_id + SCD | ✅ |
| История у department / examination | нет | ✅ нет |

```mermaid
erDiagram
    department ||--o{ ward : "1:N"
    department ||--o{ doctor : "1:N"
    examination ||--o{ examination_schedule : "1:N"
    doctor ||--o{ doctor_examination : "M:N"
    examination ||--o{ doctor_examination : "M:N"
    ward ||--o{ ward_history : SCD2
    doctor ||--o{ doctor_history : SCD2
    examination_schedule ||--o{ examination_schedule_history : SCD2
    doctor_examination ||--o{ doctor_examination_history : SCD2

    department {
        int department_id PK
        string name UK
        string building
        string phone
    }
    ward {
        int ward_id PK
        string ward_number
        int capacity
        int floor
        int department_id FK
    }
    doctor {
        int doctor_id PK
        string last_name
        string first_name
        string middle_name
        string specialization
        string phone UK
        date hire_date
        int department_id FK
    }
    examination {
        int examination_id PK
        string name UK
        string description
        numeric price
        int duration_minutes
    }
    doctor_examination {
        int doctor_id PK_FK
        int examination_id PK_FK
    }
    examination_schedule {
        int schedule_id PK
        int examination_id FK
        int day_of_week
        time start_time
        time end_time
    }
    ward_history {
        bigint history_id PK
        int ward_id
        int capacity
        int floor
        timestamp valid_from
        timestamp valid_to
        bool is_current
        string operation
    }
    doctor_history {
        bigint history_id PK
        int doctor_id "бизнес-ключ"
        int department_id
        string specialization
        string phone
        timestamp valid_from
        timestamp valid_to "NULL=∞"
        bool is_current
        string operation
    }
    examination_schedule_history {
        bigint history_id PK
        int schedule_id
        int day_of_week
        time start_time
        time end_time
        timestamp valid_from
        timestamp valid_to
        bool is_current
        string operation
    }
    doctor_examination_history {
        bigint history_id PK
        int doctor_id
        int examination_id
        timestamp valid_from
        timestamp valid_to
        bool is_current
        string operation
    }
```
