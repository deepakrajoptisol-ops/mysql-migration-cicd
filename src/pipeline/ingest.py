"""
Ingestion module — loads raw CSV data into staging tables.

Features:
  - Idempotent via INSERT … ON DUPLICATE KEY UPDATE (upsert).
  - Incremental via watermark checkpoints stored in ops_checkpoints.
  - Handles missing/bad data rows gracefully (skip + log).
"""

import csv
import json
import logging

from ..db import fetch_one, execute

logger = logging.getLogger("pipeline")


def _get_watermark(conn, dataset: str) -> str:
    """Return the last-processed watermark for a dataset, or epoch if none."""
    row = fetch_one(
        conn,
        "SELECT last_watermark FROM ops_checkpoints WHERE dataset_name = %s",
        (dataset,),
    )
    return row[0] if row else "1970-01-01 00:00:00"


def _set_watermark(conn, dataset: str, watermark: str) -> None:
    execute(conn, """
        INSERT INTO ops_checkpoints (dataset_name, last_watermark)
        VALUES (%s, %s)
        ON DUPLICATE KEY UPDATE last_watermark = VALUES(last_watermark)
    """, (dataset, watermark))


def ingest_customers(csv_path: str, conn) -> int:
    """Upsert customers from *csv_path* into stg_customers.  Returns row count."""
    last_wm = _get_watermark(conn, "customers")
    count = 0
    max_wm = last_wm

    with open(csv_path, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            updated = row.get("updated_at", "")
            if not updated:
                logger.warning(json.dumps({
                    "event": "skip_row", "reason": "missing updated_at",
                    "customer_id": row.get("customer_id"),
                }))
                continue
            if updated <= last_wm:
                continue  # already processed (incremental)

            # Validate required fields
            if not row.get("customer_id") or not row.get("full_name"):
                logger.warning(json.dumps({
                    "event": "skip_row", "reason": "missing required field",
                    "row": row,
                }))
                continue

            execute(conn, """
                INSERT INTO stg_customers
                    (customer_id, full_name, email, country, updated_at)
                VALUES (%s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                    full_name  = VALUES(full_name),
                    email      = VALUES(email),
                    country    = VALUES(country),
                    updated_at = VALUES(updated_at)
            """, (
                row["customer_id"], row["full_name"],
                row.get("email", ""), row.get("country", ""),
                updated,
            ))
            count += 1
            max_wm = max(max_wm, updated)

    _set_watermark(conn, "customers", max_wm)
    logger.info(json.dumps({
        "event": "ingest_customers", "rows": count, "watermark": max_wm,
    }))
    return count


def ingest_orders(csv_path: str, conn) -> int:
    """Upsert orders from *csv_path* into stg_orders.  Returns row count."""
    last_wm = _get_watermark(conn, "orders")
    count = 0
    max_wm = last_wm

    with open(csv_path, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            updated = row.get("updated_at", "")
            if not updated:
                logger.warning(json.dumps({
                    "event": "skip_row", "reason": "missing updated_at",
                    "order_id": row.get("order_id"),
                }))
                continue
            if updated <= last_wm:
                continue

            if not row.get("order_id") or not row.get("customer_id"):
                logger.warning(json.dumps({
                    "event": "skip_row", "reason": "missing required field",
                    "row": row,
                }))
                continue

            try:
                amount = float(row.get("amount", 0))
            except (ValueError, TypeError):
                logger.warning(json.dumps({
                    "event": "skip_row", "reason": "invalid amount",
                    "order_id": row["order_id"],
                }))
                continue

            execute(conn, """
                INSERT INTO stg_orders
                    (order_id, customer_id, order_date, amount,
                     currency, status, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                    customer_id = VALUES(customer_id),
                    order_date  = VALUES(order_date),
                    amount      = VALUES(amount),
                    currency    = VALUES(currency),
                    status      = VALUES(status),
                    updated_at  = VALUES(updated_at)
            """, (
                row["order_id"], row["customer_id"],
                row.get("order_date", ""), amount,
                row.get("currency", "USD"),
                row.get("status", "pending"),
                updated,
            ))
            count += 1
            max_wm = max(max_wm, updated)

    _set_watermark(conn, "orders", max_wm)
    logger.info(json.dumps({
        "event": "ingest_orders", "rows": count, "watermark": max_wm,
    }))
    return count
