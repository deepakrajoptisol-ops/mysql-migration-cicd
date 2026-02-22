"""
Pipeline orchestrator — runs the full pipeline:

    ingest → transform → validate

With:
  - Run-level audit (ops_pipeline_runs)
  - Failure handling and status recording
  - Idempotent design (safe to re-run)
"""

import json
import logging
import os
import uuid

from ..db import get_conn, execute
from .ingest import ingest_customers, ingest_orders
from .transform import build_dimensions, build_facts
from .validate import run_validations

logger = logging.getLogger("pipeline")


def run_pipeline(env_name: str = "dev",
                 data_dir: str = "data/raw",
                 sql_dir: str = "sql") -> str:
    """
    Orchestrate the full pipeline.

    Returns the *run_id* on success; raises on failure.
    """
    run_id  = str(uuid.uuid4())
    git_sha = os.getenv("GITHUB_SHA")
    actor   = os.getenv("GITHUB_ACTOR", "local")

    conn = get_conn()

    # Record pipeline start ---------------------------------------------------
    execute(conn, """
        INSERT INTO ops_pipeline_runs
            (run_id, env_name, status, git_sha, actor)
        VALUES (%s, %s, 'running', %s, %s)
    """, (run_id, env_name, git_sha, actor))

    try:
        # Step 1: Ingest ------------------------------------------------------
        logger.info(json.dumps({"event": "pipeline_step", "step": "ingest", "run_id": run_id}))
        cust_count  = ingest_customers(os.path.join(data_dir, "customers.csv"), conn)
        order_count = ingest_orders(os.path.join(data_dir, "orders.csv"), conn)

        # Step 2: Transform ---------------------------------------------------
        logger.info(json.dumps({"event": "pipeline_step", "step": "transform", "run_id": run_id}))
        build_dimensions(conn, sql_dir)
        build_facts(conn, run_id, sql_dir)

        # Step 3: Validate ----------------------------------------------------
        logger.info(json.dumps({"event": "pipeline_step", "step": "validate", "run_id": run_id}))
        all_passed = run_validations(conn, run_id)

        if not all_passed:
            raise RuntimeError(
                "Data quality checks failed — see ops_dq_results for details."
            )

        # Success -------------------------------------------------------------
        execute(conn, """
            UPDATE ops_pipeline_runs
            SET status = 'succeeded', finished_at = NOW(),
                details = JSON_OBJECT(
                    'customers_ingested', %s,
                    'orders_ingested', %s
                )
            WHERE run_id = %s
        """, (cust_count, order_count, run_id))

        logger.info(json.dumps({
            "event": "pipeline_complete", "run_id": run_id,
            "customers": cust_count, "orders": order_count,
        }))

    except Exception as exc:
        try:
            execute(conn, """
                UPDATE ops_pipeline_runs
                SET status = 'failed', finished_at = NOW(),
                    details = JSON_SET(
                        COALESCE(details, '{}'), '$.error', %s
                    )
                WHERE run_id = %s
            """, (str(exc), run_id))
        except Exception:
            pass  # best-effort audit
        raise

    finally:
        conn.close()

    return run_id
