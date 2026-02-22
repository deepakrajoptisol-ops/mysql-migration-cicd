"""
Core migration runner — Liquibase-like commands.

Commands
--------
validate   – validate the changelog YAML + referenced SQL files (offline).
status     – show pending changesets for a given context.
update     – apply pending changesets (lock → audit → policy → preconditions → execute).
update_sql – dry-run: print the SQL that *would* run.
verify     – confirm all applied checksums match the current SQL files.
"""

import json
import logging
import os
import uuid

from ..db import get_conn, fetch_one, fetch_all, execute, execute_script
from .changelog import load_changelog, resolve_sql, checksum
from .preconditions import evaluate_preconditions
from .policy import check_policy

logger = logging.getLogger("migrate")


# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------

def _bootstrap_tables(conn) -> None:
    """Create the DATABASECHANGELOGLOCK, DATABASECHANGELOG, and
    ops_migration_runs tables if they do not yet exist."""

    execute(conn, """
        CREATE TABLE IF NOT EXISTS DATABASECHANGELOGLOCK (
            ID          INT        NOT NULL PRIMARY KEY,
            LOCKED      TINYINT(1) NOT NULL DEFAULT 0,
            LOCKGRANTED DATETIME   NULL,
            LOCKEDBY    VARCHAR(255) NULL
        ) ENGINE=InnoDB
    """)
    # Ensure the singleton lock row exists
    if not fetch_one(conn, "SELECT ID FROM DATABASECHANGELOGLOCK WHERE ID = 1"):
        execute(conn, "INSERT INTO DATABASECHANGELOGLOCK (ID, LOCKED) VALUES (1, 0)")

    execute(conn, """
        CREATE TABLE IF NOT EXISTS DATABASECHANGELOG (
            ID            VARCHAR(255) NOT NULL,
            AUTHOR        VARCHAR(255) NOT NULL,
            FILENAME      VARCHAR(500) NOT NULL,
            DATEEXECUTED  DATETIME     NOT NULL,
            ORDEREXECUTED INT          NOT NULL,
            EXECTYPE      VARCHAR(10)  NOT NULL,
            MD5SUM        CHAR(64)     NULL,
            DESCRIPTION   VARCHAR(255) NULL,
            COMMENTS      TEXT         NULL,
            LABELS        VARCHAR(255) NULL,
            CONTEXTS      VARCHAR(255) NULL,
            PRIMARY KEY (ID, AUTHOR)
        ) ENGINE=InnoDB
    """)

    execute(conn, """
        CREATE TABLE IF NOT EXISTS ops_migration_runs (
            run_id        CHAR(36)     PRIMARY KEY,
            env_name      VARCHAR(32)  NOT NULL,
            git_sha       CHAR(40)     NULL,
            actor         VARCHAR(128) NULL,
            started_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            finished_at   TIMESTAMP    NULL,
            status        ENUM('running','succeeded','failed','rolled_back') NOT NULL,
            backup_ref    VARCHAR(512) NULL,
            error_message TEXT         NULL,
            details       JSON         NULL
        ) ENGINE=InnoDB
    """)


# ---------------------------------------------------------------------------
# Locking  (Liquibase-style table lock + MySQL advisory lock)
# ---------------------------------------------------------------------------

def _acquire_lock(conn, locked_by: str = "migrate-runner") -> None:
    # Advisory lock — prevents two processes on the same MySQL server
    row = fetch_one(conn, "SELECT GET_LOCK('schema_migration_lock', 60)")
    if not row or row[0] != 1:
        raise RuntimeError("Could not acquire MySQL advisory lock (GET_LOCK)")

    # Liquibase-style row lock
    lock_row = fetch_one(conn, "SELECT LOCKED FROM DATABASECHANGELOGLOCK WHERE ID = 1")
    if lock_row and lock_row[0] == 1:
        execute(conn, "SELECT RELEASE_LOCK('schema_migration_lock')")
        raise RuntimeError(
            "DATABASECHANGELOGLOCK is already held by another process"
        )

    execute(conn, """
        UPDATE DATABASECHANGELOGLOCK
        SET LOCKED = 1, LOCKGRANTED = NOW(), LOCKEDBY = %s
        WHERE ID = 1
    """, (locked_by,))


def _release_lock(conn) -> None:
    try:
        execute(conn, """
            UPDATE DATABASECHANGELOGLOCK
            SET LOCKED = 0, LOCKGRANTED = NULL, LOCKEDBY = NULL
            WHERE ID = 1
        """)
    finally:
        execute(conn, "SELECT RELEASE_LOCK('schema_migration_lock')")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_applied(conn) -> dict:
    """Return a dict keyed by (id, author) → {checksum, execType}."""
    rows = fetch_all(conn, """
        SELECT ID, AUTHOR, MD5SUM, EXECTYPE
        FROM DATABASECHANGELOG
        ORDER BY ORDEREXECUTED
    """)
    return {
        (r[0], r[1]): {"checksum": r[2], "execType": r[3]}
        for r in rows
    }


def _next_order(conn) -> int:
    row = fetch_one(conn, "SELECT COALESCE(MAX(ORDEREXECUTED), 0) + 1 FROM DATABASECHANGELOG")
    return row[0]


def _matches_context(changeset: dict, context: str | None) -> bool:
    """Return True if the changeset should run in the given context."""
    if context is None:
        return True  # no filter ⇒ run everything
    cs_contexts = changeset.get("contexts", [])
    if not cs_contexts:
        return True  # changeset has no context restriction
    return context in cs_contexts


# ============================= COMMANDS =====================================

def validate_cmd(changelog_path: str = "changelog/changelog.yml",
                 base_dir: str = ".") -> list[dict]:
    """Validate changelog structure and referenced SQL files (offline)."""
    changesets = load_changelog(changelog_path)
    errors: list[str] = []

    for cs in changesets:
        try:
            resolve_sql(cs, base_dir)
        except FileNotFoundError as exc:
            errors.append(str(exc))

        # light precondition-syntax validation
        for pre in cs.get("preconditions", []):
            known_keys = {"tableExists", "columnExists", "indexExists", "sqlCheck", "onFail"}
            if not known_keys & set(pre.keys()):
                errors.append(
                    f"Changeset {cs['id']}: unknown precondition keys {set(pre.keys())}"
                )

    if errors:
        for e in errors:
            logger.error(e)
        raise RuntimeError(f"Validation failed with {len(errors)} error(s)")

    logger.info(json.dumps({"event": "validate_ok", "changesets": len(changesets)}))
    return changesets


def status_cmd(changelog_path: str = "changelog/changelog.yml",
               base_dir: str = ".",
               context: str | None = None) -> list[dict]:
    """Show which changesets are pending."""
    changesets = load_changelog(changelog_path)
    conn = get_conn()
    try:
        _bootstrap_tables(conn)
        applied = _get_applied(conn)
    finally:
        conn.close()

    pending: list[dict] = []
    for cs in changesets:
        if not _matches_context(cs, context):
            continue
        key = (cs["id"], cs["author"])
        if key in applied:
            continue
        pending.append(cs)

    for cs in pending:
        logger.info(json.dumps({
            "event":   "pending_changeset",
            "id":      cs["id"],
            "author":  cs["author"],
            "sqlFile": cs["sqlFile"],
            "risk":    cs["risk"],
        }))
    return pending


def update_cmd(changelog_path: str = "changelog/changelog.yml",
               base_dir: str = ".",
               context: str | None = None,
               dry_run: bool = False) -> int:
    """Apply pending changesets.  Returns the count of changesets applied."""
    actor      = os.getenv("GITHUB_ACTOR", "local")
    env_name   = os.getenv("ENV_NAME", "dev")
    git_sha    = os.getenv("GITHUB_SHA")
    backup_ref = os.getenv("BACKUP_FILE")
    run_id     = str(uuid.uuid4())

    changesets = load_changelog(changelog_path)
    conn = get_conn()
    _bootstrap_tables(conn)

    # Record run start
    execute(conn, """
        INSERT INTO ops_migration_runs
            (run_id, env_name, git_sha, actor, status, backup_ref)
        VALUES (%s, %s, %s, %s, 'running', %s)
    """, (run_id, env_name, git_sha, actor, backup_ref))

    _acquire_lock(conn, locked_by=f"{actor}@{env_name}")
    applied_count = 0

    try:
        applied = _get_applied(conn)

        for cs in changesets:
            if not _matches_context(cs, context):
                continue

            key = (cs["id"], cs["author"])
            sql_text = resolve_sql(cs, base_dir)
            cs_checksum = checksum(sql_text)

            # Already applied? -----------------------------------------------
            if key in applied:
                old = applied[key]
                if old["execType"] == "MARK_RAN":
                    continue
                if old["checksum"] != cs_checksum:
                    raise RuntimeError(
                        f"Checksum mismatch for changeset '{cs['id']}' by "
                        f"'{cs['author']}'. Expected {old['checksum']}, got "
                        f"{cs_checksum}. Do NOT edit applied migrations; "
                        f"create a new changeset instead."
                    )
                continue  # already applied successfully

            # Policy gate -----------------------------------------------------
            check_policy(sql_text, cs)

            # Preconditions ---------------------------------------------------
            exec_type = evaluate_preconditions(conn, cs.get("preconditions", []))
            if exec_type == "SKIP":
                order = _next_order(conn)
                execute(conn, """
                    INSERT INTO DATABASECHANGELOG
                        (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED,
                         EXECTYPE, MD5SUM, LABELS, CONTEXTS)
                    VALUES (%s, %s, %s, NOW(), %s, 'MARK_RAN', %s, %s, %s)
                """, (
                    cs["id"], cs["author"], cs["sqlFile"], order,
                    cs_checksum,
                    ",".join(cs["labels"]),
                    ",".join(cs["contexts"]),
                ))
                logger.info(json.dumps({
                    "event": "changeset_mark_ran", "id": cs["id"],
                }))
                continue

            # Dry run? --------------------------------------------------------
            if dry_run:
                logger.info(json.dumps({
                    "event": "dry_run", "id": cs["id"],
                    "sql_length": len(sql_text),
                }))
                print(f"-- Changeset {cs['id']} by {cs['author']}")
                print(sql_text)
                print()
                continue

            # Apply -----------------------------------------------------------
            logger.info(json.dumps({
                "event": "applying_changeset",
                "id": cs["id"], "author": cs["author"], "risk": cs["risk"],
            }))
            try:
                execute_script(conn, sql_text)
            except Exception as exc:
                logger.error(json.dumps({
                    "event": "changeset_failed",
                    "id": cs["id"], "error": str(exc),
                }))
                raise RuntimeError(
                    f"Changeset '{cs['id']}' failed: {exc}"
                ) from exc

            order = _next_order(conn)
            execute(conn, """
                INSERT INTO DATABASECHANGELOG
                    (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED,
                     EXECTYPE, MD5SUM, LABELS, CONTEXTS)
                VALUES (%s, %s, %s, NOW(), %s, 'EXECUTED', %s, %s, %s)
            """, (
                cs["id"], cs["author"], cs["sqlFile"], order,
                cs_checksum,
                ",".join(cs["labels"]),
                ",".join(cs["contexts"]),
            ))
            applied_count += 1
            logger.info(json.dumps({
                "event": "changeset_applied", "id": cs["id"],
            }))

        # Success -------------------------------------------------------------
        execute(conn, """
            UPDATE ops_migration_runs
            SET status = 'succeeded', finished_at = NOW()
            WHERE run_id = %s
        """, (run_id,))
        logger.info(json.dumps({
            "event": "update_complete",
            "applied": applied_count, "run_id": run_id,
        }))

    except Exception as exc:
        try:
            execute(conn, """
                UPDATE ops_migration_runs
                SET status = 'failed', finished_at = NOW(), error_message = %s
                WHERE run_id = %s
            """, (str(exc), run_id))
        except Exception:
            pass  # best-effort audit
        raise
    finally:
        _release_lock(conn)
        conn.close()

    return applied_count


def verify_cmd(changelog_path: str = "changelog/changelog.yml",
               base_dir: str = ".") -> None:
    """Verify that all applied changesets still match their on-disk SQL."""
    changesets = load_changelog(changelog_path)
    conn = get_conn()
    try:
        _bootstrap_tables(conn)
        applied = _get_applied(conn)
    finally:
        conn.close()

    mismatches: list[dict] = []
    for cs in changesets:
        key = (cs["id"], cs["author"])
        if key not in applied:
            continue
        try:
            sql_text = resolve_sql(cs, base_dir)
            cs_checksum = checksum(sql_text)
            if applied[key]["checksum"] != cs_checksum:
                mismatches.append({
                    "id": cs["id"], "author": cs["author"],
                    "expected": applied[key]["checksum"],
                    "actual": cs_checksum,
                })
        except FileNotFoundError:
            mismatches.append({
                "id": cs["id"], "author": cs["author"],
                "error": "file_missing",
            })

    if mismatches:
        for m in mismatches:
            logger.error(json.dumps({"event": "checksum_mismatch", **m}))
        raise RuntimeError(f"Verification failed: {len(mismatches)} mismatch(es)")

    logger.info(json.dumps({"event": "verify_ok", "checked": len(applied)}))


def rollback_cmd(target_version: str, backup_file: str) -> None:
    """
    Rollback to a specific migration version by restoring from backup.
    
    This is a destructive operation that replaces the entire database
    with the backup, then removes migration records newer than target_version.
    """
    import subprocess
    
    logger.warning(json.dumps({
        "event": "rollback_start", 
        "target": target_version, 
        "backup": backup_file
    }))
    
    # Restore from backup
    env = dict(os.environ)
    cmd = [
        "mysql", 
        "-h", env["DB_HOST"], 
        "-P", env["DB_PORT"],
        "-u", env["DB_USER"], 
        f"-p{env['DB_PASSWORD']}", 
        env["DB_NAME"]
    ]
    
    with open(backup_file, 'r') as f:
        result = subprocess.run(cmd, stdin=f, capture_output=True, text=True)
    
    if result.returncode != 0:
        raise RuntimeError(f"Backup restore failed: {result.stderr}")
    
    # Clean up migration records newer than target
    conn = get_conn()
    try:
        execute(conn, """
            DELETE FROM DATABASECHANGELOG 
            WHERE ORDEREXECUTED > (
                SELECT ORDEREXECUTED FROM (
                    SELECT ORDEREXECUTED FROM DATABASECHANGELOG 
                    WHERE ID = %s LIMIT 1
                ) tmp
            )
        """, (target_version,))
        
        logger.info(json.dumps({
            "event": "rollback_complete", 
            "target": target_version
        }))
    finally:
        conn.close()
