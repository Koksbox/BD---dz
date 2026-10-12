"""Load DATABASE_URL from environment / .env file."""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent
SQL_DIR = PROJECT_ROOT / "sql"
RESULTS_DIR = PROJECT_ROOT / "results"

load_dotenv(PROJECT_ROOT / ".env")


def get_database_url() -> str:
    url = os.getenv("DATABASE_URL", "").strip()
    if not url:
        raise RuntimeError(
            "DATABASE_URL is not set. Copy .env.example to .env "
            "and put your PostgreSQL connection string there."
        )
    return url
