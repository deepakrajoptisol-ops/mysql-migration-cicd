"""
CLI entry-point for the migration runner.

Usage:
    python -m src.migrate validate
    python -m src.migrate status  [--context dev]
    python -m src.migrate update  [--context dev]
    python -m src.migrate update_sql [--context dev]
    python -m src.migrate verify
"""

import argparse
import logging
import sys
from pathlib import Path

from dotenv import load_dotenv

from .runner import validate_cmd, status_cmd, update_cmd, verify_cmd, rollback_cmd


def _setup_logging() -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter("%(message)s"))
    for name in ("migrate", "db"):
        lgr = logging.getLogger(name)
        lgr.addHandler(handler)
        lgr.setLevel(logging.INFO)


def main() -> None:
    # Load .env file if it exists
    env_file = Path("env.local")
    if env_file.exists():
        load_dotenv(env_file)
        print(f"Loaded environment from {env_file}")
    
    _setup_logging()

    parser = argparse.ArgumentParser(
        prog="migrate",
        description="Liquibase-like MySQL migration runner",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # validate ----------------------------------------------------------------
    p_val = sub.add_parser("validate", help="Validate changelog + SQL files (offline)")
    p_val.add_argument("--changelog", default="changelog/changelog.yml")

    # status ------------------------------------------------------------------
    p_st = sub.add_parser("status", help="Show pending changesets")
    p_st.add_argument("--changelog", default="changelog/changelog.yml")
    p_st.add_argument("--context", default=None)

    # update ------------------------------------------------------------------
    p_up = sub.add_parser("update", help="Apply pending changesets")
    p_up.add_argument("--changelog", default="changelog/changelog.yml")
    p_up.add_argument("--context", default=None)
    p_up.add_argument("--no-backup", action="store_true", help="Skip automatic backup creation")

    # update_sql --------------------------------------------------------------
    p_us = sub.add_parser("update_sql", help="Dry-run: print SQL that would run")
    p_us.add_argument("--changelog", default="changelog/changelog.yml")
    p_us.add_argument("--context", default=None)

    # verify ------------------------------------------------------------------
    p_ve = sub.add_parser("verify", help="Verify applied checksums match on-disk SQL")
    p_ve.add_argument("--changelog", default="changelog/changelog.yml")

    # rollback ----------------------------------------------------------------
    p_rb = sub.add_parser("rollback", help="Rollback to a specific migration version")
    p_rb.add_argument("target_version", help="Target migration ID to rollback to")
    p_rb.add_argument("--backup-file", required=True, help="Backup file to restore from")

    args = parser.parse_args()

    try:
        if args.command == "validate":
            cs = validate_cmd(args.changelog)
            print(f"OK — validated {len(cs)} changeset(s).")

        elif args.command == "status":
            pending = status_cmd(args.changelog, context=args.context)
            print(f"{len(pending)} changeset(s) pending.")

        elif args.command == "update":
            count = update_cmd(args.changelog, context=args.context, auto_backup=not args.no_backup)
            print(f"Applied {count} changeset(s) successfully.")

        elif args.command == "update_sql":
            update_cmd(args.changelog, context=args.context, dry_run=True)

        elif args.command == "verify":
            verify_cmd(args.changelog)
            print("All checksums verified.")

        elif args.command == "rollback":
            rollback_cmd(args.target_version, args.backup_file)
            print(f"Rolled back to migration {args.target_version}.")

    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
