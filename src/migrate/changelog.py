"""
Parse and validate the Liquibase-like YAML changelog.
Supports both manual YAML changelog and auto-generated from migration files.
"""

import hashlib
import re
from pathlib import Path

import yaml


def auto_generate_changelog(migrations_dir: str = "migrations") -> list[dict]:
    """
    Auto-generate changelog by scanning migration files for metadata headers.
    
    Expected header format in SQL files:
    -- id: 004
    -- author: data-team  
    -- risk: low
    -- allowDestructive: false
    -- labels: feature,segmentation
    -- contexts: dev,prod
    """
    migrations_path = Path(migrations_dir)
    if not migrations_path.exists():
        return []
    
    changesets = []
    migration_pattern = re.compile(r"^(\d+)_(.+)\.up\.sql$")
    
    for sql_file in sorted(migrations_path.glob("*.up.sql")):
        match = migration_pattern.match(sql_file.name)
        if not match:
            continue
            
        version = match.group(1)
        content = sql_file.read_text(encoding="utf-8")
        
        # Parse header metadata
        metadata = _parse_sql_headers(content)
        
        changeset = {
            "id": metadata.get("id", version),
            "author": metadata.get("author", "unknown"),
            "sqlFile": str(sql_file.relative_to(".")),
            "risk": metadata.get("risk", "medium"),
            "allowDestructive": metadata.get("allowDestructive", "false").lower() == "true",
            "labels": [l.strip() for l in metadata.get("labels", "").split(",") if l.strip()],
            "contexts": [c.strip() for c in metadata.get("contexts", "dev,prod").split(",") if c.strip()],
            "preconditions": [],  # Could be extended to parse preconditions from SQL comments
        }
        changesets.append(changeset)
    
    return changesets


def _parse_sql_headers(sql_content: str) -> dict:
    """Parse metadata from SQL comment headers."""
    headers = {}
    header_pattern = re.compile(r"^--\s*(\w+):\s*(.+)$", re.MULTILINE)
    
    for match in header_pattern.finditer(sql_content):
        key = match.group(1).lower()
        value = match.group(2).strip()
        headers[key] = value
    
    return headers


def load_changelog(changelog_path: str = "changelog/changelog.yml") -> list[dict]:
    """
    Load and validate the changelog. 
    
    If changelog_path exists, use it (manual mode).
    Otherwise, auto-generate from migrations/ folder (auto mode).
    """
    changelog_file = Path(changelog_path)
    
    # Auto-generate mode: scan migrations folder
    if not changelog_file.exists():
        return auto_generate_changelog()
    
    # Manual mode: load YAML changelog
    with open(changelog_path, "r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh)

    if not data or "databaseChangeLog" not in data:
        raise ValueError(
            f"Invalid changelog: missing 'databaseChangeLog' key in {changelog_path}"
        )

    changesets: list[dict] = []
    seen_ids: set[str] = set()

    for entry in data["databaseChangeLog"]:
        cs = entry.get("changeSet")
        if not cs:
            raise ValueError("Each entry in databaseChangeLog must contain a 'changeSet' key")

        # --- required fields ---------------------------------------------------
        for field in ("id", "author", "sqlFile"):
            if field not in cs:
                raise ValueError(f"Changeset missing required field '{field}'")

        cs_id = str(cs["id"])
        if cs_id in seen_ids:
            raise ValueError(f"Duplicate changeset id: {cs_id}")
        seen_ids.add(cs_id)

        # --- normalise optional fields -----------------------------------------
        raw_labels = cs.get("labels", "")
        raw_contexts = cs.get("contexts", "")

        changesets.append({
            "id":               cs_id,
            "author":           cs["author"],
            "sqlFile":          cs["sqlFile"],
            "risk":             cs.get("risk", "low"),
            "allowDestructive": bool(cs.get("allowDestructive", False)),
            "labels":           [l.strip() for l in str(raw_labels).split(",") if l.strip()],
            "contexts":         [c.strip() for c in str(raw_contexts).split(",") if c.strip()],
            "preconditions":    cs.get("preconditions", []),
        })

    return changesets


def resolve_sql(changeset: dict, base_dir: str = ".") -> str:
    """Read and return the SQL text for a changeset, relative to *base_dir*."""
    sql_path = Path(base_dir) / changeset["sqlFile"]
    if not sql_path.exists():
        raise FileNotFoundError(f"SQL file not found: {sql_path}")
    return sql_path.read_text(encoding="utf-8")


def checksum(sql_text: str) -> str:
    """Return a SHA-256 hex digest for the given SQL text."""
    return hashlib.sha256(sql_text.encode("utf-8")).hexdigest()
