"""
Data quality / validation module.

Runs checks programmatically (the reference SQL lives in sql/validation/
for documentation) and records every result in ops_dq_results.

Checks:
  DQ-1  orphan_orders         – orders with no matching customer
  DQ-2  duplicate_order_ids   – duplicate PKs in staging
  DQ-3  fact_recon_count      – fact row count == joinable staging count
  DQ-4  null_required_fields  – null / empty required columns
  DQ-5  negative_amounts      – order amounts ≤ 0
"""

import json
import logging

from ..db import fetch_one, execute

logger = logging.getLogger("pipeline")


def _record(conn, run_id: str, name: str, passed: bool,
            metric=None, threshold=None, details: str | None = None) -> None:
    execute(conn, """
        INSERT INTO ops_dq_results
            (run_id, check_name, status, metric_value, threshold, details)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (
        run_id, name,
        "pass" if passed else "fail",
        metric, threshold, details,
    ))


def run_validations(conn, run_id: str) -> bool:
    """Execute all DQ checks and return True if every check passes."""
    failures = 0

    # DQ-1: orphan orders ----------------------------------------------------
    (orphan_count,) = fetch_one(conn, """
        SELECT COUNT(*)
        FROM stg_orders o
        LEFT JOIN stg_customers c ON c.customer_id = o.customer_id
        WHERE c.customer_id IS NULL
    """)
    ok = orphan_count == 0
    _record(conn, run_id, "orphan_orders", ok,
            metric=orphan_count, threshold=0,
            details='{"rule":"every order must have a customer"}')
    if not ok:
        failures += 1
        logger.error(json.dumps({
            "event": "dq_fail", "check": "orphan_orders",
            "orphan_count": int(orphan_count),
        }))

    # DQ-2: duplicate order IDs -----------------------------------------------
    (dup_count,) = fetch_one(conn, """
        SELECT COUNT(*) FROM (
            SELECT order_id FROM stg_orders
            GROUP BY order_id HAVING COUNT(*) > 1
        ) x
    """)
    ok = dup_count == 0
    _record(conn, run_id, "duplicate_order_ids", ok,
            metric=dup_count, threshold=0,
            details='{"rule":"order_id must be unique"}')
    if not ok:
        failures += 1
        logger.error(json.dumps({
            "event": "dq_fail", "check": "duplicate_order_ids",
            "dup_count": int(dup_count),
        }))

    # DQ-3: fact reconciliation ------------------------------------------------
    (stg_joinable,) = fetch_one(conn, """
        SELECT COUNT(*)
        FROM stg_orders o
        INNER JOIN stg_customers c ON c.customer_id = o.customer_id
    """)
    (fact_count,) = fetch_one(conn, "SELECT COUNT(*) FROM fact_order")
    ok = fact_count == stg_joinable
    _record(conn, run_id, "fact_recon_count", ok,
            metric=fact_count, threshold=stg_joinable,
            details='{"rule":"fact rows == joinable staging rows"}')
    if not ok:
        failures += 1
        logger.error(json.dumps({
            "event": "dq_fail", "check": "fact_recon_count",
            "fact": int(fact_count), "stg_joinable": int(stg_joinable),
        }))

    # DQ-4: null required fields -----------------------------------------------
    (null_count,) = fetch_one(conn, """
        SELECT COUNT(*) FROM stg_customers
        WHERE full_name IS NULL OR full_name = ''
           OR email     IS NULL OR email     = ''
           OR country   IS NULL OR country   = ''
    """)
    ok = null_count == 0
    _record(conn, run_id, "null_required_fields", ok,
            metric=null_count, threshold=0,
            details='{"rule":"full_name, email, country must be non-empty"}')
    if not ok:
        failures += 1
        logger.error(json.dumps({
            "event": "dq_fail", "check": "null_required_fields",
            "null_count": int(null_count),
        }))

    # DQ-5: negative / zero amounts -------------------------------------------
    (bad_amt,) = fetch_one(conn, """
        SELECT COUNT(*) FROM stg_orders WHERE amount <= 0
    """)
    ok = bad_amt == 0
    _record(conn, run_id, "negative_amounts", ok,
            metric=bad_amt, threshold=0,
            details='{"rule":"order amount must be positive"}')
    if not ok:
        failures += 1
        logger.error(json.dumps({
            "event": "dq_fail", "check": "negative_amounts",
            "bad_count": int(bad_amt),
        }))

    # Summary -----------------------------------------------------------------
    total = 5
    passed = total - failures
    logger.info(json.dumps({
        "event": "dq_summary", "run_id": run_id,
        "total": total, "passed": passed, "failed": failures,
    }))
    return failures == 0
