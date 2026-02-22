"""
Evaluate Liquibase-like preconditions against a live MySQL connection.

Supported checks:
    tableExists   – INFORMATION_SCHEMA lookup
    columnExists  – INFORMATION_SCHEMA lookup
    indexExists   – INFORMATION_SCHEMA.STATISTICS lookup
    sqlCheck      – arbitrary SELECT that must return expectedResult

onFail behaviour:
    HALT     – raise RuntimeError (abort the changeset and the run)
    MARK_RAN – skip the changeset and record it as MARK_RAN
    WARN     – log a warning and proceed with execution
"""

import json
import logging

from ..db import fetch_one

logger = logging.getLogger("migrate")


# ---------------------------------------------------------------------------
# Individual check helpers
# ---------------------------------------------------------------------------

def _table_exists(conn, table_name: str) -> bool:
    row = fetch_one(conn, """
        SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = %s
    """, (table_name,))
    return row[0] > 0


def _column_exists(conn, table_name: str, column_name: str) -> bool:
    row = fetch_one(conn, """
        SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = %s AND COLUMN_NAME = %s
    """, (table_name, column_name))
    return row[0] > 0


def _index_exists(conn, table_name: str, index_name: str) -> bool:
    row = fetch_one(conn, """
        SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = %s AND INDEX_NAME = %s
    """, (table_name, index_name))
    return row[0] > 0


def _sql_check(conn, sql: str, expected: str) -> bool:
    row = fetch_one(conn, sql)
    if row is None:
        return False
    return str(row[0]) == str(expected)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def evaluate_preconditions(conn, preconditions: list[dict]) -> str:
    """
    Evaluate a list of precondition dicts.

    Returns
    -------
    "PROCEED" – all checks passed (or warned); apply the changeset.
    "SKIP"    – at least one check returned MARK_RAN; skip the changeset.
    """
    for pre in preconditions:
        on_fail = pre.get("onFail", "HALT").upper()
        passed = False
        check_name = "unknown"

        if "tableExists" in pre:
            tbl = pre["tableExists"]["tableName"]
            check_name = f"tableExists({tbl})"
            passed = _table_exists(conn, tbl)

        elif "columnExists" in pre:
            cfg = pre["columnExists"]
            check_name = f"columnExists({cfg['tableName']}.{cfg['columnName']})"
            passed = _column_exists(conn, cfg["tableName"], cfg["columnName"])

        elif "indexExists" in pre:
            cfg = pre["indexExists"]
            check_name = f"indexExists({cfg['tableName']}.{cfg['indexName']})"
            passed = _index_exists(conn, cfg["tableName"], cfg["indexName"])

        elif "sqlCheck" in pre:
            cfg = pre["sqlCheck"]
            check_name = f"sqlCheck({cfg['sql'][:60]})"
            passed = _sql_check(conn, cfg["sql"], cfg.get("expectedResult", "1"))

        else:
            logger.warning(json.dumps({
                "event": "unknown_precondition", "precondition": str(pre),
            }))
            continue

        if passed:
            logger.info(json.dumps({"event": "precondition_passed", "check": check_name}))
            continue

        # --- check failed ------------------------------------------------------
        if on_fail == "HALT":
            raise RuntimeError(f"Precondition failed (HALT): {check_name}")
        elif on_fail == "MARK_RAN":
            logger.warning(json.dumps({
                "event": "precondition_mark_ran", "check": check_name,
            }))
            return "SKIP"
        elif on_fail == "WARN":
            logger.warning(json.dumps({
                "event": "precondition_warn", "check": check_name,
            }))
        else:
            raise RuntimeError(f"Unknown onFail value: {on_fail}")

    return "PROCEED"
