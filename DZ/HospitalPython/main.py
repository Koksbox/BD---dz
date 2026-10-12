"""
Hospital DB — entry point.

Run from project root:
    python main.py

Or press F5 in Visual Studio / VS Code (see .vscode/launch.json).
"""

from __future__ import annotations

import sys
import traceback


def main() -> int:
    try:
        from app.runner import run_all

        run_all()
        return 0
    except Exception:
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
