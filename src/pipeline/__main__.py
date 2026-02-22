"""
CLI entry-point for the data pipeline.

Usage:
    python -m src.pipeline run [--env dev] [--data-dir data/raw] [--sql-dir sql]
"""

import argparse
import logging
import sys
from pathlib import Path

from dotenv import load_dotenv

from .runner import run_pipeline


def _setup_logging() -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter("%(message)s"))
    for name in ("pipeline", "db"):
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
        prog="pipeline",
        description="End-to-end data pipeline: ingest → transform → validate",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_run = sub.add_parser("run", help="Run full pipeline")
    p_run.add_argument("--env",      default="dev",       help="Environment name")
    p_run.add_argument("--data-dir", default="data/raw",  help="Path to raw CSV files")
    p_run.add_argument("--sql-dir",  default="sql",       help="Path to SQL directory")

    args = parser.parse_args()

    try:
        if args.command == "run":
            run_id = run_pipeline(args.env, args.data_dir, args.sql_dir)
            print(f"Pipeline completed successfully.  run_id={run_id}")
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
