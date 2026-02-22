"""
SQL policy / safety checks applied before executing a changeset.

Destructive patterns are blocked unless BOTH:
  1. The changeset YAML sets  allowDestructive: true
  2. The workflow / env sets  ALLOW_DESTRUCTIVE=true

Risky patterns (e.g. ALTER TABLE on potentially large tables) produce a
warning log but do not block execution.
"""

import json
import logging
import os
import re

logger = logging.getLogger("migrate")

# ---------------------------------------------------------------------------
# Pattern registries
# ---------------------------------------------------------------------------

DESTRUCTIVE_PATTERNS: list[tuple[re.Pattern, str]] = [
    (re.compile(r"\bDROP\s+DATABASE\b", re.IGNORECASE),  "DROP DATABASE"),
    (re.compile(r"\bTRUNCATE\s+TABLE\b", re.IGNORECASE), "TRUNCATE TABLE"),
    (re.compile(r"\bDROP\s+TABLE\b", re.IGNORECASE),     "DROP TABLE"),
]

RISKY_PATTERNS: list[tuple[re.Pattern, str]] = [
    (re.compile(r"\bALTER\s+TABLE\b", re.IGNORECASE),
     "ALTER TABLE detected — may hold metadata lock on large tables; "
     "consider gh-ost or pt-online-schema-change in production."),
]


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def check_policy(sql_text: str, changeset: dict) -> None:
    """
    Scan *sql_text* for destructive / risky patterns.

    Raises ``RuntimeError`` if a destructive pattern is found and the
    required overrides are not set.
    """
    allow_env = os.getenv("ALLOW_DESTRUCTIVE", "false").lower() == "true"
    allow_cs = changeset.get("allowDestructive", False)

    for pattern, name in DESTRUCTIVE_PATTERNS:
        if pattern.search(sql_text):
            if not (allow_env and allow_cs):
                raise RuntimeError(
                    f"Policy violation: '{name}' detected in changeset "
                    f"'{changeset['id']}'. To proceed, set "
                    f"allowDestructive: true in the changeset YAML AND "
                    f"export ALLOW_DESTRUCTIVE=true in the workflow."
                )
            logger.warning(json.dumps({
                "event": "destructive_allowed",
                "changeset": changeset["id"],
                "pattern": name,
            }))

    for pattern, warning_msg in RISKY_PATTERNS:
        if pattern.search(sql_text):
            logger.warning(json.dumps({
                "event": "risky_operation",
                "changeset": changeset["id"],
                "warning": warning_msg,
            }))
