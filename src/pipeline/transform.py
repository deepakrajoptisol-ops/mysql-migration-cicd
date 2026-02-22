"""
Transformation module — builds curated (star-schema) tables from staging.

Reads SQL files from sql/transform/ and executes them against MySQL.
Demonstrates:
  - SCD Type 2 dimension management  (build_dims.sql)
  - Fact-table join + idempotent upsert  (build_facts.sql)
"""

import json
import logging
from pathlib import Path

from ..db import execute, execute_script

logger = logging.getLogger("pipeline")


def build_dimensions(conn, sql_dir: str = "sql") -> None:
    """Execute the SCD-2 dimension-build SQL."""
    sql_path = Path(sql_dir) / "transform" / "build_dims.sql"
    sql_text = sql_path.read_text(encoding="utf-8")
    execute_script(conn, sql_text)
    logger.info(json.dumps({"event": "transform_dims_complete"}))


def build_facts(conn, run_id: str, sql_dir: str = "sql") -> None:
    """Execute the fact-table build SQL.

    Sets the MySQL session variable ``@run_id`` so the SQL can stamp
    every row with the pipeline run identifier.
    """
    sql_path = Path(sql_dir) / "transform" / "build_facts.sql"
    sql_text = sql_path.read_text(encoding="utf-8")

    # Set session variable for the SQL script
    execute(conn, "SET @run_id = %s", (run_id,))
    execute_script(conn, sql_text)
    logger.info(json.dumps({"event": "transform_facts_complete", "run_id": run_id}))
