"""
Shared database utilities used by both the migration runner and the data pipeline.
"""

import os
import logging

import mysql.connector

logger = logging.getLogger("db")


def get_conn():
    """Return a MySQL connection configured from environment variables."""
    return mysql.connector.connect(
        host=os.environ["DB_HOST"],
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
        autocommit=False,  # Use transactions for better control
        consume_results=True,  # Automatically consume unread results
    )


def fetch_one(conn, sql, params=None):
    """Execute a query and return a single row (or None)."""
    cur = conn.cursor()
    cur.execute(sql, params or ())
    row = cur.fetchone()
    cur.close()
    return row


def fetch_all(conn, sql, params=None):
    """Execute a query and return all rows."""
    cur = conn.cursor()
    cur.execute(sql, params or ())
    rows = cur.fetchall()
    cur.close()
    return rows


def execute(conn, sql, params=None):
    """Execute a single statement (INSERT/UPDATE/DDL)."""
    cur = conn.cursor()
    try:
        cur.execute(sql, params or ())
        conn.commit()  # Commit each statement
    finally:
        cur.close()


def execute_script(conn, script_text: str):
    """Execute a multi-statement SQL script by splitting on semicolons."""
    # Clean up the script - remove comments and split on semicolons
    lines = []
    for line in script_text.split('\n'):
        line = line.strip()
        if line and not line.startswith('--'):
            lines.append(line)
    
    clean_script = ' '.join(lines)
    statements = [stmt.strip() for stmt in clean_script.split(';') if stmt.strip()]
    
    for stmt in statements:
        if stmt.strip():
            execute(conn, stmt)
