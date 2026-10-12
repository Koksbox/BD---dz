"""Orchestrate schema install, seed, queries, history demo."""

from __future__ import annotations

import csv
from pathlib import Path
from typing import Any

import psycopg

from app.db import connect, execute_file, execute_script_with_results
from config import RESULTS_DIR, SQL_DIR, get_database_url

# Align with DB-submission / peer PR layout
INSTALL_SCRIPTS = [
    "01_schema.sql",
    "02_data.sql",
    "04_history.sql",
]

QUERY_TITLES_PART1 = [
    "1. All examinations with day_of_week, start and end time",
    "2. Doctors who perform a given examination (ECG)",
    "3. Examination schedule for Wednesday",
    "4. Doctors with their departments",
    "5. Departments and ward counts",
    "6. Examinations that start after 12:00",
    "7. Doctors participating in more than one examination",
    "8. Examinations performed by Petrov Igor",
    "9. Wards of Surgery department",
]


def _format_cell(value: Any) -> str:
    if value is None:
        return "NULL"
    return str(value)


def format_table(columns: list[str], rows: list[dict[str, Any]]) -> str:
    if not columns:
        return "(no columns)\n"

    str_rows = [[_format_cell(r.get(c)) for c in columns] for r in rows]
    widths = [len(c) for c in columns]
    for row in str_rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(cell))

    def fmt_row(cells: list[str]) -> str:
        return "| " + " | ".join(cell.ljust(widths[i]) for i, cell in enumerate(cells)) + " |"

    sep = "+-" + "-+-".join("-" * w for w in widths) + "-+"
    lines = [sep, fmt_row(columns), sep]
    if not str_rows:
        lines.append("| " + "(0 rows)".ljust(sum(widths) + 3 * (len(widths) - 1)) + " |")
    else:
        for row in str_rows:
            lines.append(fmt_row(row))
    lines.append(sep)
    lines.append(f"({len(rows)} row{'s' if len(rows) != 1 else ''})")
    return "\n".join(lines)


def print_section(title: str) -> None:
    bar = "=" * 72
    print(f"\n{bar}\n{title}\n{bar}")


def save_result(
    name: str,
    columns: list[str],
    rows: list[dict[str, Any]],
    title: str = "",
) -> None:
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    safe = "".join(ch if ch.isalnum() or ch in "-_" else "_" for ch in name)
    txt_path = RESULTS_DIR / f"{safe}.txt"
    csv_path = RESULTS_DIR / f"{safe}.csv"

    body = format_table(columns, rows)
    header = f"{title}\n\n" if title else ""
    txt_path.write_text(header + body + "\n", encoding="utf-8")

    with csv_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({c: row.get(c) for c in columns})


def run_install(conn: psycopg.Connection) -> None:
    for name in INSTALL_SCRIPTS:
        path = SQL_DIR / name
        print_section(f"Execute {name}")
        execute_file(conn, path)
        print(f"OK: {path.name}")


def run_part1_queries(conn: psycopg.Connection) -> None:
    path = SQL_DIR / "03_queries.sql"
    print_section("Part I — queries (03_queries.sql)")
    results = execute_script_with_results(conn, path)
    select_results = [(p, c, r) for p, c, r in results if c]
    for idx, (preview, columns, rows) in enumerate(select_results):
        title = QUERY_TITLES_PART1[idx] if idx < len(QUERY_TITLES_PART1) else f"Query {idx + 1}"
        print(f"\n--- {title} ---")
        print(f"SQL: {preview}")
        print(format_table(columns, rows))
        save_result(f"part1_q{idx + 1:02d}", columns, rows, title=title)


def run_history_demo(conn: psycopg.Connection) -> None:
    path = SQL_DIR / "05_history_demo.sql"
    print_section("Part II — history demo + slices (05_history_demo.sql)")
    results = execute_script_with_results(conn, path)
    n = 0
    current_title: str | None = None
    for preview, columns, rows in results:
        if not columns:
            continue
        if len(columns) == 1 and len(rows) == 1 and columns[0] == "step":
            current_title = str(rows[0]["step"])
            print(f"\n--- {current_title} ---")
            continue
        if len(columns) == 1 and columns[0] == "pg_sleep":
            continue
        n += 1
        title = current_title or f"Result #{n}"
        current_title = None
        print(f"\n--- {title} ---")
        print(f"SQL: {preview}")
        print(format_table(columns, rows))
        save_result(f"history_{n:02d}", columns, rows, title=title)


def run_all() -> None:
    url = get_database_url()
    print_section("Connect to PostgreSQL")
    safe_url = url
    if "@" in url and ":" in url.split("@", 1)[0]:
        prefix, rest = url.rsplit("@", 1)
        if "://" in prefix:
            scheme, userinfo = prefix.split("://", 1)
            user = userinfo.split(":", 1)[0]
            safe_url = f"{scheme}://{user}:****@{rest}"
    print(f"DATABASE_URL = {safe_url}")

    with connect(url) as conn:
        run_install(conn)
        run_part1_queries(conn)
        run_history_demo(conn)

    print_section("Done")
    print(f"Query results also saved under: {RESULTS_DIR}")
