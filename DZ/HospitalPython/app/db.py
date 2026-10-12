"""PostgreSQL helpers: connect, execute SQL files, fetch results."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

import psycopg
from psycopg.rows import dict_row

# Dollar-quoted tags like $$ ... $$ or $body$ ... $body$
_DOLLAR_TAG = re.compile(r"\$([A-Za-z_][A-Za-z0-9_]*)?\$")


def connect(database_url: str) -> psycopg.Connection:
    """Open a connection; autocommit=False so scripts run in transactions."""
    return psycopg.connect(database_url, row_factory=dict_row)


def split_sql(script: str) -> list[str]:
    """
    Split a SQL script into statements on ';' outside strings / dollar quotes.
    Strips line comments (--) and block comments (/* */).
    """
    statements: list[str] = []
    buf: list[str] = []
    i = 0
    n = len(script)
    in_single = False
    in_dollar: str | None = None

    while i < n:
        ch = script[i]

        # Line comment
        if not in_single and in_dollar is None and ch == "-" and i + 1 < n and script[i + 1] == "-":
            while i < n and script[i] != "\n":
                i += 1
            continue

        # Block comment
        if not in_single and in_dollar is None and ch == "/" and i + 1 < n and script[i + 1] == "*":
            i += 2
            while i + 1 < n and not (script[i] == "*" and script[i + 1] == "/"):
                i += 1
            i = min(i + 2, n)
            continue

        # Single-quoted string
        if in_dollar is None and ch == "'":
            buf.append(ch)
            if in_single:
                # SQL escape: '' inside string
                if i + 1 < n and script[i + 1] == "'":
                    buf.append("'")
                    i += 2
                    continue
                in_single = False
            else:
                in_single = True
            i += 1
            continue

        # Dollar quoting
        if not in_single:
            m = _DOLLAR_TAG.match(script, i)
            if m:
                tag = m.group(0)
                if in_dollar is None:
                    in_dollar = tag
                    buf.append(tag)
                    i = m.end()
                    continue
                if tag == in_dollar:
                    in_dollar = None
                    buf.append(tag)
                    i = m.end()
                    continue

        # Statement terminator
        if ch == ";" and not in_single and in_dollar is None:
            stmt = "".join(buf).strip()
            if stmt:
                statements.append(stmt)
            buf = []
            i += 1
            continue

        buf.append(ch)
        i += 1

    tail = "".join(buf).strip()
    if tail:
        statements.append(tail)
    return statements


def execute_file(conn: psycopg.Connection, path: Path) -> None:
    """Execute every statement in a SQL file (DDL/DML)."""
    script = path.read_text(encoding="utf-8")
    statements = split_sql(script)
    with conn.cursor() as cur:
        for stmt in statements:
            cur.execute(stmt)
    conn.commit()


def execute_script_with_results(
    conn: psycopg.Connection,
    path: Path,
) -> list[tuple[str, list[str], list[dict[str, Any]]]]:
    """
    Execute a multi-statement script.
    For SELECT / WITH / SHOW / TABLE — collect column names and rows.
    Returns list of (preview_sql, columns, rows).
    """
    script = path.read_text(encoding="utf-8")
    statements = split_sql(script)
    collected: list[tuple[str, list[str], list[dict[str, Any]]]] = []

    with conn.cursor() as cur:
        for stmt in statements:
            cur.execute(stmt)
            if cur.description is not None:
                columns = [d.name for d in cur.description]
                rows = list(cur.fetchall())
                preview = " ".join(stmt.split())
                if len(preview) > 120:
                    preview = preview[:117] + "..."
                collected.append((preview, columns, rows))
    conn.commit()
    return collected


def fetchall(
    conn: psycopg.Connection,
    sql: str,
    params: Any = None,
) -> tuple[list[str], list[dict[str, Any]]]:
    """Run one query and return (columns, rows)."""
    with conn.cursor() as cur:
        cur.execute(sql, params)
        if cur.description is None:
            return [], []
        columns = [d.name for d in cur.description]
        rows = list(cur.fetchall())
    return columns, rows
